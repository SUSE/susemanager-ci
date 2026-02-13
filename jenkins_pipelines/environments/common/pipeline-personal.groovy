def run(params) {
    timestamps {
        // Init path env variables
        GString resultdir = "${env.WORKSPACE}/results"
        GString resultdirbuild = "${resultdir}/${env.BUILD_NUMBER}"

        // The junit plugin doesn't affect full paths
        GString junit_resultdir = "results/${env.BUILD_NUMBER}/results_junit"
        GString exports = "export BUILD_NUMBER=${env.BUILD_NUMBER}; export CAPYBARA_TIMEOUT=${params.capybara_timeout}; export DEFAULT_TIMEOUT=${params.default_timeout}; export CUCUMBER_PUBLISH_QUIET=true;"
        String tfvariables_file  = 'susemanager-ci/terracumber_config/tf_files/personal/variables.tf'
        String tfvars_infra_description = "susemanager-ci/terracumber_config/tf_files/personal/environment.tfvars"
        GString common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --tf_variables_description_file ${tfvariables_file}  --gitfolder ${resultdir}/sumaform --terraform-bin ${params.bin_path}"


        if (params.deploy_parallelism) {
            common_params = "${common_params} --parallelism ${params.deploy_parallelism}"
        }

        def previous_commit = null
        def product_commit = null
        // Start pipeline
        def deployed = false
        try {
            withCredentials([string(credentialsId: 'sumaform-secrets', variable: 'SECRET_CONTENT')]) {
                stage('Clone terracumber, susemanager-ci and sumaform') {
                    if (params.show_product_changes) {
                        // Rename build using product commit hash
                        currentBuild.description = "[${params.tf_file}]"
                    }
                    // Create a directory for  to place the directory with the build results (if it does not exist)
                    sh "mkdir -p ${resultdir}"
                    git url: params.terracumber_gitrepo, branch: params.terracumber_ref
                    dir("susemanager-ci") {
                        checkout scm
                    }
                    if (params.run_deployment) {
                        // Use the dot operator (.) instead of source for shell compatibility
                        sh """
                            #!/bin/bash
                            # Write the secret to a temporary file
                            echo "${SECRET_CONTENT}" > /tmp/.credentials
                            # Source it
                            . /tmp/.credentials
                            ./terracumber-cli ${common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync
                        """
                    }
                    // Restore Terraform states from artifacts
                    if (params.use_previous_terraform_state) {
                        copyArtifacts projectName: currentBuild.projectName, selector: specific("${currentBuild.previousBuild.number}")
                    }
                }
                stage('Deploy') {
                    if (params.run_deployment) {
                        // Provision the environment
                        String TERRAFORM_INIT = ''
                        if (params.terraform_init) {
                            TERRAFORM_INIT = '--init'
                        }
                        String TERRAFORM_TAINT = ''
                        if (params.terraform_taint) {
                            TERRAFORM_TAINT = " --taint '.*(domain|combustion_disk|cloudinit_disk|ignition_disk|main_disk|data_disk|database_disk|standalone_provisioning).*'"
                        }
                        sh "rm -f ${resultdir}/sumaform/terraform.tfvars"
                        sh "cat ${tfvars_infra_description} >> ${resultdir}/sumaform/terraform.tfvars"
                        sh "echo 'ENVIRONMENT = \"${params.environment}\"' >> ${resultdir}/sumaform/terraform.tfvars"
                        if (params.container_repository != '') {
                            sh "echo 'CONTAINER_REPOSITORY=\"${params.container_repository}\"' >> ${resultdir}/sumaform/terraform.tfvars"
                        }
                        sh """
                            #!/bin/bash
                            set -e -o pipefail
                            echo "${SECRET_CONTENT}" > /tmp/.credentials
                            . /tmp/.credentials
                            
                            export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}
                            export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}
                            export TERRAFORM=${params.bin_path}
                            export TERRAFORM_PLUGINS=${params.bin_plugins_path}
                            export ENVIRONMENT=${params.environment}
            
                            ./terracumber-cli ${common_params} \
                                --logfile ${resultdirbuild}/sumaform.log \
                                ${TERRAFORM_INIT} ${TERRAFORM_TAINT} \
                                --sumaform-backend ${params.sumaform_backend} \
                                --runstep provision | \
                            sed -E 's/([^.]+)module\\.([^.]+)\\.module\\.([^.]+)(\\.module\\.[^.]+)?(\\[[0-9]+\\])?(\\.module\\.[^.]+)?(\\.[^.]+)?(.*)/\\1\\2.\\3\\8/'
                        """
                        deployed = true
                        // Collect and tag Flaky tests from the GitHub Board
                        def statusCode = sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake utils:collect_and_tag_flaky_tests'", returnStatus: true
                    }
                }
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
                if (params.run_core) {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:core'"
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:reposync'"
                }
            }
            stage('Core - Proxy') {
                if (params.run_core) {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:proxy'"
                }
            }
            stage('Core - Initialize clients') {
                if (params.run_core) {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake parallel:init_clients'"
                }
            }
            stage('Secondary features') {
                if (params.run_secondary) {
                    def tags_list = ""
                    if (params.functional_scopes) {
                        def transformed_scopes = params.functional_scopes.replaceAll(',', ' or ')
                        tags_list += "export TAGS='${transformed_scopes}'; "
                    }
                    def statusCode1 = sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${tags_list} cd /root/spacewalk/testsuite; ${exports} rake cucumber:secondary'", returnStatus: true
                    def statusCode2 = sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${tags_list} cd /root/spacewalk/testsuite; ${exports} rake ${params.rake_namespace}:secondary_parallelizable'", returnStatus: true
                    def statusCode3 = sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${tags_list} cd /root/spacewalk/testsuite; ${exports} rake ${params.rake_namespace}:secondary_finishing'", returnStatus: true
                    sh "exit \$(( ${statusCode1}|${statusCode2}|${statusCode3} ))"
                }
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
                // Clean up old results
                sh "./clean-old-results -r ${resultdir}"
                sh "exit ${error}"
            }
        }
    }
}

return this
