def run(params) {
    timestamps {
        // Init path env variables
        GString resultdir = "${env.WORKSPACE}/results"
        GString resultdirbuild = "${resultdir}/${env.BUILD_NUMBER}"

        // The junit plugin doesn't affect full paths
        GString junit_resultdir = "results/${env.BUILD_NUMBER}/results_junit"
        GString common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${resultdir}/sumaform --terraform-bin ${params.terraform_bin}"
        GString exports = "export env.BUILD_NUMBER=${env.BUILD_NUMBER}; export params.capybara_timeout=${params.capybara_timeout}; export DEFAULT_TIMEOUT=${params.default_timeout}; export CUCUMBER_PUBLISH_QUIET=true;"
        String tfvariables_file  = 'susemanager-ci/terracumber_config/tf_files/qe/variables.tf'
        String tfvars_infra_description = "susemanager-ci/terracumber_config/tf_files/qe/terraform.tfvars"

        if (params.terraform_parallelism) {
            common_params = "${common_params} --parallelism ${params.terraform_parallelism}"
        }

        def previous_commit = null
        def product_commit = null
        def mirror_scope = env.JOB_BASE_NAME.split('-acceptance-tests')[0]
        mirror_scope = mirror_scope.replaceAll("-dev", "")
        if (params.show_product_changes) {
            // Retrieve the hash commit of the last product built in OBS/IBS and previous job
            def prefix = env.JOB_BASE_NAME.split('-acceptance-tests')[0]
            if (prefix == "uyuni-master-dev") {
                prefix = "manager-Head-dev"
            }
            // The 2obs jobs are releng, not dev
            prefix = prefix.replaceAll("-dev", "-releng")
            def request = httpRequest ignoreSslErrors: true, url: "https://ci.suse.de/job/${prefix}-2obs/lastBuild/api/json"
            def requestJson = readJSON text: request.getContent()
            product_commit = "${requestJson.actions.lastBuiltRevision.SHA1}"
            product_commit = product_commit.substring(product_commit.indexOf('[') + 1, product_commit.indexOf(']'));
            print "Current product commit: ${product_commit}"
            previous_commit = currentBuild.getPreviousBuild().description
            if (previous_commit == null) {
                previous_commit = product_commit
            } else {
                previous_commit = previous_commit.substring(previous_commit.indexOf('[') + 1, previous_commit.indexOf(']'));
            }
            print "Previous product commit: ${previous_commit}"
        }
        // Start pipeline
        deployed = false
        try {
            stage('Clone terracumber, susemanager-ci and sumaform') {
                when {
                    expression { return params.run_deployment }
                }
                if (params.show_product_changes) {
                    // Rename build using product commit hash
                    currentBuild.description =  "[${product_commit}]"
                }

                // Create a directory for  to place the directory with the build results (if it does not exist)
                sh "mkdir -p ${resultdir}"
//                git url: params.terracumber_gitrepo, branch: params.terracumber_ref
                dir("susemanager-ci") {
                    checkout([
                            $class: 'GitSCM',
                            branches: [[name: params.terracumber_ref]],
                            userRemoteConfigs: [[url: params.terracumber_gitrepo]],
                            extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: "susemanager-ci"]],
                            changelog: false,   // 🔑 disables 'git whatchanged'
                            poll: false
                    ])
                }
                // Clone sumaform
                sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --tf_variables_description_file ${tfvariables_file} --tf_configuration_files ${tfvars_infra_description} --runstep gitsync"

                // Restore Terraform states from artifacts
                if (params.use_previous_terraform_state) {
                    copyArtifacts projectName: currentBuild.projectName, selector: specific("${currentBuild.previousBuild.number}")
                }

                // run minima sync on mirror
                if (mirror_scope != null) {
                    sh "ssh root@minima-mirror-ci-bv.`hostname -d` -t \"test -x /usr/local/bin/minima-${mirror_scope}.sh && /usr/local/bin/minima-${mirror_scope}.sh || echo 'no mirror script for this scope'\""
                }
            }
            stage('Deploy') {
                when {
                    expression { return params.run_deployment }
                }
                // Provision the environment
                if (params.terraform_init) {
                    env.TERRAFORM_INIT = '--init'
                } else {
                    env.TERRAFORM_INIT = ''
                }
                env.TERRAFORM_TAINT = ''
                if (params.terraform_taint) {
                    env.TERRAFORM_TAINT = " --taint '.*(domain|combustion_disk|cloudinit_disk|ignition_disk|main_disk|data_disk|database_disk|standalone_provisioning).*'"
                }
                sh "set +x; source /home/jenkins/.credentials set -x; set -o pipefail; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; export ENVIRONMENT=${params.environment}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} ${env.TERRAFORM_TAINT} --sumaform-backend ${params.sumaform_backend} --runstep provision | sed -E 's/([^.]+)module\\.([^.]+)\\.module\\.([^.]+)(\\.module\\.[^.]+)?(\\[[0-9]+\\])?(\\.module\\.[^.]+)?(\\.[^.]+)?(.*)/\\1\\2.\\3\\8/'"
                deployed = true
                // Collect and tag Flaky tests from the GitHub Board
                def statusCode = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake utils:collect_and_tag_flaky_tests'", returnStatus:true
            }
            stage('Product changes') {
                if (params.show_product_changes) {
                    sh """
                        # Comparison between:
                        #  - the previous git revision of spacewalk (or uyuni) repository pushed in IBS (or OBS)
                        #  - the git revision of the current spacewalk (or uyuni) repository pushed in IBS (or OBS)
                        # Note: This is a trade-off, we should be comparing the git revisions of all the packages composing our product
                        #       For that extra mile, we need a new tag in the repo metadata of each built, with the git revision of the related repository.
                    """
                    sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/; git --no-pager log --pretty=format:\"%h %<(16,trunc)%cn  %s  %d\" ${previous_commit}..${product_commit}'", returnStatus:true
                } else {
                    println("Product changes disabled, checkbox 'show_product_changes' was not enabled'")
                }
            }
            stage('Sanity Check') {
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:sanity_check'"
            }
            stage('Core - Setup') {
                when {
                    expression { return params.run_test }
                }
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:core'"
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:reposync'"
            }
            stage('Core - Proxy') {
                when {
                    expression { return params.run_test }
                }
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:proxy'"
            }
            stage('Core - Initialize clients') {
                when {
                    expression { return params.run_test }
                }
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake parallel:init_clients'"
            }
            stage('Secondary features') {
                when {
                    expression { return params.run_test }
                }
                def tags = ""
                if (params.functional_scopes){
                    tags += "export TAGS=${params.functional_scopes}; "
                }
                def statusCode1 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${tags} cd /root/spacewalk/testsuite; ${exports} rake cucumber:secondary'", returnStatus:true
                def statusCode2 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${tags} cd /root/spacewalk/testsuite; ${exports} rake ${params.rake_namespace}:secondary_parallelizable'", returnStatus:true
                def statusCode3 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${tags} cd /root/spacewalk/testsuite; ${exports} rake ${params.rake_namespace}:secondary_finishing'", returnStatus:true
                sh "exit \$(( ${statusCode1}|${statusCode2}|${statusCode3} ))"
            }
        }
        finally {
            stage('Save TF state') {
                    archiveArtifacts artifacts: "results/sumaform/terraform.tfstate, results/sumaform/.terraform/**/*"
            }

            stage('Get results') {
                def error = 0
                if (deployed) {
                    try {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:finishing'"
                    } catch(err) {
                        println("ERROR: rake cucumber:finishing failed: ${err}")
                        error = 1
                    }
                    try {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake utils:generate_test_report'"
                    } catch(err) {
                        println("ERROR: rake utils:generate_test_repor failed: ${err}")
                        error = 1
                    }
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep getresults"
                    // In the case of an AWS environment, we want to export the reports to a publicly accessible web server.
                    if (params.sumaform_backend == "aws") {
                        try {
                            sh """
                              ./terracumber-cli ${common_params} \
                                --logfile ${resultdirbuild}/webserver.log \
                                --runstep cucumber \
                                --cucumber-cmd 'mkdir -p /mnt/www/${env.BUILD_NUMBER} && \
                                                rsync -avz --no-owner --no-group  /root/spacewalk/testsuite/results/${env.BUILD_NUMBER}/ /mnt/www/${env.BUILD_NUMBER}/ && \
                                                rsync -av --no-owner --no-group  /root/spacewalk/testsuite/spacewalk-debug.tar.bz2 /mnt/www/${env.BUILD_NUMBER}/ && \
                                                rsync -av --no-owner --no-group  /root/spacewalk/testsuite/logs/ /mnt/www/${env.BUILD_NUMBER}/ && \
                                                rsync -avz --no-owner --no-group  /root/spacewalk/testsuite/cucumber_report/ /mnt/www/${env.BUILD_NUMBER}/'
                            """
                        } catch(err) {
                            println("ERROR: Exporting reports to external AWS Web Server: ${err}")
                            error = 1
                        }
                    }
                    publishHTML( target: [
                                allowMissing: true,
                                alwaysLinkToLastBuild: false,
                                keepAll: true,
                                reportDir: "${resultdirbuild}/cucumber_report/",
                                reportFiles: 'cucumber_report.html',
                                reportName: "TestSuite Report"]
                    )
                    junit allowEmptyResults: true, testResults: "${junit_resultdir}/*.xml"
                }
                // Send email
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/mail.log --runstep mail"
                // Clean up old results
                sh "./clean-old-results -r ${resultdir}"
                sh "exit ${error}"
            }
        }
    }
}

return this
