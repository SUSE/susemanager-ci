def run(params) {
    timestamps {
        //Capybara configuration
        def api_program = "./api_program/main.py"

        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        // The junit plugin doesn't affect full paths
        junit_resultdir = "results/${BUILD_NUMBER}/results_junit"
        env.exports = "export BUILD_NUMBER=${BUILD_NUMBER}; export BUILD_VALIDATION=true; "
        def tf_file = "/home/jenkins/workspace/${params.targeted_project}/results/sumaform/main.tf"

        // Variables to store none critical stage run status

        env.common_params = "--outputdir ${resultdir} --tf ${tf_file} --gitfolder ${resultdir}/sumaform"

        if (params.terraform_parallelism) {
            env.common_params = "${env.common_params} --parallelism ${params.terraform_parallelism}"
        }
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

            stage('Delete the systems') {
                sh(script: "${api_program} ${params.manager_hostname} delete_systems")
            }
            stage('Delete config projects') {
                sh(script: "${api_program} ${params.manager_hostname} delete_config_projects")
            }
            stage('Delete software channels') {
                sh(script: "${api_program} ${params.manager_hostname} delete_software_channels")
            }
            stage('Delete activation keys') {
                sh(script: "${api_program} ${params.manager_hostname} delete_activation_keys")
            }
            stage('Delete minion users') {
                sh(script: "${api_program} ${params.manager_hostname} delete_users")
            }
            stage('Delete channel repositories') {
                sh(script: "${api_program} ${params.manager_hostname} delete_repositories")
            }
            stage('Delete salt keys') {
                sh(script: "${api_program} ${params.manager_hostname} delete_salt_keys")
            }
            stage('Delete ssh know hosts') {
                sh(script: "${api_program} ${params.manager_hostname} delete_known_hosts")
            }

            stage('Delete client VMs') {
                // Copy tfstate from project
                sh "cp /home/jenkins/workspace/${params.targeted_project}/results/sumaform/terraform.tfstate ${env.resultdir}/sumaform/terraform.tfstate"
                sh "cp -r /home/jenkins/workspace/${params.targeted_project}/results/sumaform/.terraform ${env.resultdir}/sumaform/"
                // Run Terracumber to deploy the environment without clients
                sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log --init --sumaform-backend ${params.sumaform_backend} --use-tf-resource-cleaner --tf-resources-to-delete proxy retail monitoring-server --runstep provision"
            }

            stage('Redeploy the environment with new client VMs and update custom repositories into cucumber') {
                // Generate custom_repositories.json file in the workspace from the value passed by parameter
                if (params.custom_repositories?.trim()) {
                    writeFile file: 'custom_repositories.json', text: params.custom_repositories, encoding: "UTF-8"
                }
                // Generate custom_repositories.json file in the workspace using a Python script - MI Identifiers passed by parameter
                if (params.mi_ids?.trim()) {
                    node('manager-jenkins-node') {
                        checkout scm
                        res_python_script_ = sh(script: "python3 jenkins_pipelines/scripts/json_generator/maintenance_json_generator.py --mi_ids ${params.mi_ids}", returnStatus: true)
                        echo "Build Validation JSON script return code:\n ${json_content}"
                        if (res_python_script != 0) {
                            error("MI IDs (${params.mi_ids}) passed by parameter are wrong (or already released)")
                        }
                    }
                }
                // Run Terracumber to deploy the environment
                sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log --init --sumaform-backend ${params.sumaform_backend} --runstep provision"
                // Copy  back the tftstate to targeted project
                sh "cp ${env.resultdir}/sumaform/terraform.tfstate /home/jenkins/workspace/${params.targeted_project}/results/sumaform/terraform.tfstate"
            }

            stage('Sanity check') {
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${env.exports} rake cucumber:build_validation_sanity_check'"
            }

        }
        finally {
            stage('Save TF state') {
                archiveArtifacts artifacts: "results/sumaform/terraform.tfstate, results/sumaform/.terraform/**/*"
            }

        }
    }
}

return this
