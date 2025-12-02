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
        deployed = false
        try {

            stage('Clone terracumber, susemanager-ci and sumaform') {
                if (params.show_product_changes) {
                    // Rename build using product commit hash
                    currentBuild.description = "[${params.tf_file}]"
                }
                if (params.run_deployment) {
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
                    sh "set +x; source /home/jenkins/.credentials set -x; set -o pipefail; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.bin_path}; export TERRAFORM_PLUGINS=${params.bin_plugins_path}; export ENVIRONMENT=${params.environment}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${TERRAFORM_INIT} ${TERRAFORM_TAINT} --sumaform-backend ${params.sumaform_backend} --runstep provision | sed -E 's/([^.]+)module\\.([^.]+)\\.module\\.([^.]+)(\\.module\\.[^.]+)?(\\[[0-9]+\\])?(\\.module\\.[^.]+)?(\\.[^.]+)?(.*)/\\1\\2.\\3\\8/'"
                    // Temporary fix until we change sumaform to support the playwright test framework
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'wget -q -O- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash && . ~/.bashrc && nvm install node'"
                    deployed = true
                }
            }
            stage('Core - Setup') {
                if (params.run_core) {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/; ${exports} npm run cucumber:core'"
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/; ${exports} npm run cucumber:reposync'"
                }
            }
            stage('Core - Proxy') {
                if (params.run_core) {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/; ${exports} npm run cucumber:proxy'"
                }
            }
            stage('Core - Initialize clients') {
                if (params.run_core) {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/; ${exports} npm run cucumber:init_clients'"
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
                    publishHTML( target: [
                            allowMissing: true,
                            alwaysLinkToLastBuild: false,
                            keepAll: true,
                            reportDir: "${resultdirbuild}/reports/cucumber-report.html",
                            reportFiles: 'cucumber-report.html',
                            reportName: "TestSuite Report"]
                    )
                }
                // Clean up old results
                sh "./clean-old-results -r ${resultdir}"
                sh "exit ${error}"
            }
        }
    }
}

return this
