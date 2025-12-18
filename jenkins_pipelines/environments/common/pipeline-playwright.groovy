def run(params) {
    timestamps {
        // Init path env variables
        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"

        // The junit plugin doesn't affect full paths
        junit_resultdir = "results/${BUILD_NUMBER}/results_junit"
        env.common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${resultdir}/sumaform --terraform-bin ${params.bin_path}"
        env.exports = "export BUILD_NUMBER=${BUILD_NUMBER}; export CUCUMBER_PUBLISH_QUIET=true;"

        if (params.deploy_parallelism) {
            common_params = "${common_params} --parallelism ${params.deploy_parallelism}"
        }

        def previous_commit = null
        def product_commit = null
        // Start pipeline
        deployed = false
        try {
            stage('Clone terracumber, susemanager-ci and sumaform') {
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
            }
            stage('Deploy') {
                if (params.run_deployment) {
                    // Provision the environment
                    if (params.terraform_init) {
                        env.TERRAFORM_INIT = '--init'
                    } else {
                        env.TERRAFORM_INIT = ''
                    }
                    env.TERRAFORM_TAINT = ''
                    if (params.terraform_taint) {
                        switch (params.sumaform_backend) {
                            case "libvirt":
                                env.TERRAFORM_TAINT = " --taint '.*(domain|combustion_disk|cloudinit_disk|ignition_disk|main_disk|data_disk|database_disk|standalone_provisioning).*'";
                                break;
                            case "aws":
                                env.TERRAFORM_TAINT = " --taint '.*(host).*'";
                                env.exports = "${env.exports} export PUBLISH_CUCUMBER_REPORT=true;";
                                break;
                            default:
                                println("ERROR: Unknown backend ${params.sumaform_backend}");
                                sh "exit 1";
                                break;
                        }
                    }
                    sh "set +x; source /home/jenkins/.credentials set -x; set -o pipefail; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.bin_path}; export TERRAFORM_PLUGINS=${params.bin_plugins_path}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} ${env.TERRAFORM_TAINT} --sumaform-backend ${params.sumaform_backend} --runstep provision | sed -E 's/([^.]+)module\\.([^.]+)\\.module\\.([^.]+)(\\.module\\.[^.]+)?(\\[[0-9]+\\])?(\\.module\\.[^.]+)?(\\.[^.]+)?(.*)/\\1\\2.\\3\\8/'"
                    deployed = true
                }
            }
            stage('Core') {
                if (params.run_core) {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/; ${env.exports} npm run cucumber:sanity_check'"
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/; ${env.exports} npm run cucumber:core'"
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/; ${env.exports} npm run cucumber:reposync'"
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/; ${env.exports} npm run cucumber:proxy'"
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/; ${env.exports} npm run cucumber:init_clients'"
                }
            }
            stage('Acceptance Tests') {
                if (params.run_secondary) {
                    def tags_list = ""
                    if (params.functional_scopes) {
                        def transformed_scopes = params.functional_scopes.replaceAll(',', ' or ')
                        tags_list += "export TAGS=${transformed_scopes}; "
                    }
                    def statusCode1 = sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${tags_list} cd /root/spacewalk/; ${env.exports} npm run cucumber:secondary'", returnStatus: true
                    def statusCode2 = sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${tags_list} cd /root/spacewalk/; ${env.exports} npm run cucumber:secondary_parallelizable'", returnStatus: true
                    def statusCode3 = sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${tags_list} cd /root/spacewalk/; ${env.exports} npm run cucumber:secondary_finishing'", returnStatus: true
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
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/; ${env.exports} npm run cucumber:finishing'"
                    } catch(err) {
                        println("ERROR: rake cucumber:finishing failed: ${err}")
                        error = 1
                    }
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep getresults"
                    publishHTML( target: [
                            allowMissing: true,
                            alwaysLinkToLastBuild: false,
                            keepAll: true,
                            reportDir: "${resultdirbuild}/reports/cucumber-report.html",
                            reportFiles: 'cucumber-report.html',
                            reportName: "TestSuite Report"]
                    )
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
