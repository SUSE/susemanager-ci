def run(params) {
    timestamps {
        // Init path env variables
        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"

        // The junit plugin doesn't affect full paths
        junit_resultdir = "results/${BUILD_NUMBER}/results_junit"
        env.common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${resultdir}/sumaform --terraform-bin ${params.terraform_bin}"
        env.exports = "export BUILD_NUMBER=${BUILD_NUMBER}; export CAPYBARA_TIMEOUT=${capybara_timeout}; export DEFAULT_TIMEOUT=${default_timeout}; "

        if (params.terraform_parallelism) {
            env.common_params = "${env.common_params} --parallelism ${params.terraform_parallelism}"
        }
        if (params.bastion_ssh_key_file) {
            env.common_params = "${env.common_params} --bastion_ssh_key ${params.bastion_ssh_key_file} --bastion_user ${params.bastion_username}"
            if (params.bastion_hostname) {
                env.common_params = "${env.common_params} --bastion_hostname ${params.bastion_hostname}"
            }
        }

        def previous_commit = null
        def product_commit = null
        def mirror_scope = null
        if (params.show_product_changes) {
            // Retrieve the hash commit of the last product built in OBS/IBS and previous job
            def prefix = env.JOB_BASE_NAME.split('-acceptance-tests')[0]
            mirror_scope = prefix.replaceAll("-dev", "")
            if (prefix == "uyuni-master-dev") {
                prefix = "manager-Head-dev"
            }
            // The 2obs jobs are releng, not dev
            prefix = prefix.replaceAll("-dev", "-releng")
            def request = httpRequest "https://ci.suse.de/job/${prefix}-2obs/lastBuild/api/json"
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
                if (params.show_product_changes) {
                    // Rename build using product commit hash
                    currentBuild.description =  "[${product_commit}]"
                }
                
                // Create a directory for  to place the directory with the build results (if it does not exist)
                sh "mkdir -p ${resultdir}"
                git url: params.terracumber_gitrepo, branch: params.terracumber_ref
                dir("susemanager-ci") {
                    checkout scm
                }
                // Clone sumaform
                sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync"
            
                // Restore Terraform states from artifacts
                if (params.use_previous_terraform_state) {
                    copyArtifacts projectName: currentBuild.projectName, selector: specific("${currentBuild.previousBuild.number}")
                }

                // run minima sync on mirror
                if (mirror_scope != null) {
                    sh "ssh root@minima-mirror-ci-bv.`hostname -d` -t \"test -x /usr/local/bin/minima-${mirror_scope}.sh && /usr/local/bin/minima-${mirror_scope}.sh\""
                }
            }
            stage('Deploy') {
                // Provision the environment
                if (params.terraform_init) {
                    env.TERRAFORM_INIT = '--init'
                } else {
                    env.TERRAFORM_INIT = ''
                }
                env.TERRAFORM_TAINT = ''
                if (params.terraform_taint) {
                    switch(params.sumaform_backend) {
                        case "libvirt":
                            env.TERRAFORM_TAINT = " --taint '.*(domain|main_disk|data_disk|database_disk|standalone_provisioning).*'";
                            break;
                        case "aws":
                            env.TERRAFORM_TAINT = " --taint '.*(host).*'";
                            break;
                        default:
                            println("ERROR: Unknown backend ${params.sumaform_backend}");
                            sh "exit 1";
                            break;
                    }
                }
                sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} ${env.TERRAFORM_TAINT} --sumaform-backend ${params.sumaform_backend} --runstep provision"
                deployed = true
                // Collect and tag Flaky tests from the GitHub Board
                def statusCode = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${env.exports} rake utils:collect_and_tag_flaky_tests'", returnStatus:true
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
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${env.exports} rake cucumber:sanity_check'"
            }
            stage('Core - Setup') {
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${env.exports} rake cucumber:core'"
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${env.exports} rake cucumber:reposync'"
            }
            stage('Core - Initialize clients') {
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${env.exports} rake ${params.rake_namespace}:init_clients'"
            }
            stage('Secondary features') {
                def exports = ""
                if (params.functional_scopes){
                  exports += "export TAGS=${params.functional_scopes}; "
                }
                def statusCode1 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${exports} cd /root/spacewalk/testsuite; ${env.exports} rake cucumber:secondary'", returnStatus:true
                def statusCode2 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${exports} cd /root/spacewalk/testsuite; ${env.exports} rake ${params.rake_namespace}:secondary_parallelizable'", returnStatus:true
                def statusCode3 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${exports} cd /root/spacewalk/testsuite; ${env.exports} rake ${params.rake_namespace}:secondary_finishing'", returnStatus:true
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
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${env.exports} rake cucumber:finishing'"
                    } catch(Exception ex) {
                        println("ERROR: rake cucumber:finishing failed")
                        error = 1
                    }
                    try {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${env.exports} rake utils:generate_test_report'"
                    } catch(Exception ex) {
                        println("ERROR: rake utils:generate_test_repor failed")
                        error = 1
                    }
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep getresults"
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
