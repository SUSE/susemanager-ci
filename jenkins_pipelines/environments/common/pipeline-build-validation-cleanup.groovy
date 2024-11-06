def run(params) {
    timestamps {
        //Capybara configuration
        String api_program = "./susemanager-ci/jenkins_pipelines/scripts/SUSEManager_cleaner/suse_manager_cleaner_program/SUSEManagerCleaner.py"

        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        // The junit plugin doesn't affect full paths
        junit_resultdir = "results/${BUILD_NUMBER}/results_junit"
        env.exports = "export BUILD_NUMBER=${BUILD_NUMBER}; export BUILD_VALIDATION=true; "
        def tf_file = "/home/jenkins/workspace/${params.targeted_project}/results/sumaform/main.tf"
        def container_repository = params.container_repository ?: null
        def product_version = null

        // Construct the --tf-resources-to-delete argument dynamically
        ArrayList defaultResourcesToDelete = []
        if (params.clean_proxy) {
            defaultResourcesToDelete.add('proxy')
        }
        if (params.clean_monitoring_server) {
            defaultResourcesToDelete.add('monitoring-server')
        }
        if (params.clean_retail) {
            defaultResourcesToDelete.add('retail')
        }

        String defaultResourcesToDeleteArgs = defaultResourcesToDelete.isEmpty() ? '' : "--default-resources-to-delete ${defaultResourcesToDelete.join(' ')}"

        env.common_params = "--outputdir ${resultdir} --tf ${tf_file} --gitfolder ${resultdir}/sumaform"

        if (params.terraform_parallelism) {
            env.common_params = "${env.common_params} --parallelism ${params.terraform_parallelism}"
        }

        try {
            stage('Clone terracumber, susemanager-ci and sumaform') {

                // Prevent rebuild option
                if (currentBuild.getBuildCauses().toString().contains("RebuildCause")) {
                    error "Rebuild is blocked for this job."
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

                // Set product version
                if (params.targeted_project.contains("5.0")) {
                    product_version = '5.0'
                } else if (params.targeted_project.contains("4.3")) {
                    product_version = '4.3'
                } else if (params.targeted_project.contains("uyuni")) {
                    product_version = 'uyuni'
                }
                else {
                    // Use the `error` step instead of `throw`
                    error("Error: targeted_project must contain either '5.0', '4.3' or uyuni.")
                }
            }

            stage('Confirm Environment Cleanup') {
                // Ask the user if they are sure they want to clean the environment
                def userConfirmed = input(
                        message: 'Are you sure you want to clean this environment?',
                        parameters: [
                                choice(name: 'Confirm_Cleanup', description: 'Are you sure to clean this environment? (yes/no)')
                        ]
                )

                // Check if the user confirmed
                if (userConfirmed != 'yes') {
                    error('User did not confirm cleanup. Aborting pipeline.')
                }

                // Ask the user what environment they are cleaning, ensuring the answer matches params.targeted_project
                def environmentChoice = input(
                        message: 'What environment are you cleaning?',
                        parameters: [
                                string(name: 'Environment_Name', description: 'Enter the name of the environment you are cleaning.')
                        ]
                )

                // Validate that the user entered the correct environment
                if (environmentChoice != params.targeted_project) {
                    error("The environment name entered does not match the targeted project. Aborting pipeline.")
                }
            }

            stage('Delete the systems') {
                sh(script: "${api_program} --url ${params.manager_hostname} --mode delete_systems ${defaultResourcesToDeleteArgs}")
            }
            stage('Delete config projects') {
                sh(script: "${api_program} --url ${params.manager_hostname} --mode delete_config_projects ${defaultResourcesToDeleteArgs}")
            }
            stage('Delete software channels') {
                sh(script: "${api_program} --url ${params.manager_hostname} --mode delete_software_channels ${defaultResourcesToDeleteArgs}")
            }
            stage('Delete activation keys') {
                sh(script: "${api_program} --url ${params.manager_hostname} --mode delete_activation_keys ${defaultResourcesToDeleteArgs}")
            }
            stage('Delete minion users') {
                sh(script: "${api_program} --url ${params.manager_hostname} --mode delete_users ${defaultResourcesToDeleteArgs}")
            }
            stage('Delete channel repositories') {
                sh(script: "${api_program} --url ${params.manager_hostname} --mode delete_repositories ${defaultResourcesToDeleteArgs}")
            }
            stage('Delete salt keys') {
                sh(script: "${api_program} --url ${params.manager_hostname} --mode delete_salt_keys ${defaultResourcesToDeleteArgs}")
            }

            stage('Delete ssh know hosts') {
                sh(script: "${api_program} --url ${params.manager_hostname} --mode delete_known_hosts --product_version ${product_version}")
            }

            stage('Delete distributions folders') {
                sh(script: "${api_program} --url ${params.manager_hostname} --mode delete_distributions --product_version ${product_version}")
            }

            // Define shared environment variables for terraform calls
            GString environmentVars = """
                set -x
                source /home/jenkins/.credentials
                export TF_VAR_CONTAINER_REPOSITORY=${container_repository}
                export TERRAFORM=${terraform_bin}
                export TERRAFORM_PLUGINS=${terraform_bin_plugins}
            """

            stage('Delete client VMs') {

                // Copy tfstate and terraform directory to the result directory
                sh """
                    cp ${tfStatePath} ${targetTfStateDir}terraform.tfstate
                    cp -r ${terraformDir}.terraform ${targetTfStateDir}
                """

                // Construct the --tf-resources-to-delete argument dynamically
                ArrayList tfResourcesToDelete = []
                if (params.clean_proxy) {
                    tfResourcesToDelete.add('proxy')
                }
                if (params.clean_monitoring_server) {
                    tfResourcesToDelete.add('monitoring-server')
                }
                if (params.clean_retail) {
                    tfResourcesToDelete.add('retail')
                }

                // Join the resources into a comma-separated string if there are any to delete
                String tfResourcesToDeleteArg = defaultResourcesToDelete.isEmpty() ? '' : "--tf-resources-to-delete ${defaultResourcesToDelete.join(' ')}"

                // Execute Terracumber CLI to deploy the environment without clients
                sh """
                    ${environmentVars}
                    set +x
                    ./terracumber-cli ${common_params} --logfile ${logFile} --init --sumaform-backend ${sumaform_backend} --use-tf-resource-cleaner --init --runstep provision ${tfResourcesToDeleteArg}
                """
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
                sh """
                    ${environmentVars}
                    set +x
                    ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log --init --sumaform-backend ${sumaform_backend} --runstep provision
                """
            }

            stage('Sanity check') {
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${env.exports} rake cucumber:build_validation_sanity_check'"
            }

        }
        finally {
            stage('Copy back tfstate') {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    sh "cp ${env.resultdir}/sumaform/terraform.tfstate /home/jenkins/workspace/${params.targeted_project}/results/sumaform/terraform.tfstate"
                }
            }

            stage('Rename tfstate to avoid copying it between runs') {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    sh "mv ${env.resultdir}/sumaform/terraform.tfstate ${env.resultdir}/sumaform/terraform.tfstate.old"
                }
            }
        }
    }
}

return this
