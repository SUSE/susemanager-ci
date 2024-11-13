def run(params) {
    timestamps {
        // Define paths and environment variables for reusability
        String SUSEManagerCleanerProgram = "./susemanager-ci/jenkins_pipelines/scripts/SUSEManager_cleaner/suse_manager_cleaner_program/SUSEManagerCleaner.py"
        GString resultdir = "${WORKSPACE}/results"
        GString resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        GString exports = "export BUILD_NUMBER=${BUILD_NUMBER}; export BUILD_VALIDATION=true; "
        String container_repository = params.container_repository ?: null
        String product_version = null
        String controllerHostname = null
        String serverHostname = null
        GString targetedTfFile = "/home/jenkins/workspace/${params.targeted_project}/results/sumaform/main.tf"
        GString targetedTfStateFile = "/home/jenkins/workspace/${params.targeted_project}/results/sumaform/terraform.tfstate"
        GString targetedTerraformDirPath = "/home/jenkins/workspace/${params.targeted_project}/results/sumaform/"
        GString localSumaformDirPath = "${resultdir}/sumaform/"
        GString localTfStateFile = "${localSumaformDirPath}/terraform.tfstate"
        GString logFile = "${resultdirbuild}/sumaform.log"

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

        GString commonParams = "--outputdir ${resultdir} --tf ${targetedTfFile} --gitfolder ${resultdir}/sumaform"

        if (params.terraform_parallelism) {
            commonParams = "${commonParams} --parallelism ${params.terraform_parallelism}"
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
                sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${commonParams} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync"

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

            stage("Copy terraform files from ${params.targeted_project}"){
                // Copy tfstate and terraform directory to the result directory
                sh """
                    cp ${targetedTfStateFile} ${localTfStateFile}
                    cp -r ${targetedTerraformDirPath}.terraform ${localSumaformDirPath}
                """

            }

            stage("Extract the controller and server hostname") {
                try {
                    controllerHostname = sh(
                            script: """
                            set -e
                            cd ${localSumaformDirPath}
                            terraform output -json configuration | jq -r '.controller.hostname'
                        """,
                            returnStdout: true
                    ).trim()

                    serverHostname = sh(
                            script: """
                            set -e
                            cd ${localSumaformDirPath}
                            terraform output -json configuration | jq -r '.server.hostname'
                        """,
                            returnStdout: true
                    ).trim()

                    // Print the values for confirmation
                    echo "Extracted controller hostname: ${controllerHostname}"
                    echo "Extracted server hostname: ${serverHostname}"

                } catch (Exception e) {
                    error("Failed to extract hostnames: ${e.message}")
                }
            }

            stage('Delete the systems') {
                sh(script: "${SUSEManagerCleanerProgram} --url ${serverHostname} --product_version ${product_version} ${defaultResourcesToDeleteArgs} --mode delete_systems")
            }
            stage('Delete config projects') {
                sh(script: "${SUSEManagerCleanerProgram} --url ${serverHostname} --product_version ${product_version} ${defaultResourcesToDeleteArgs} --mode delete_config_projects")
            }

            stage('Delete software channels') {
                sh(script: "${SUSEManagerCleanerProgram} --url ${serverHostname} --product_version ${product_version} ${defaultResourcesToDeleteArgs} --mode delete_software_channels")
            }

            stage('Delete activation keys') {
                sh(script: "${SUSEManagerCleanerProgram} --url ${serverHostname} --product_version ${product_version} ${defaultResourcesToDeleteArgs} --mode delete_activation_keys")
            }
            stage('Delete minion users') {
                sh(script: "${SUSEManagerCleanerProgram} --url ${serverHostname} --product_version ${product_version} ${defaultResourcesToDeleteArgs} --mode delete_users")
            }
            stage('Delete channel repositories') {
                sh(script: "${SUSEManagerCleanerProgram} --url ${serverHostname} --product_version ${product_version} ${defaultResourcesToDeleteArgs} --mode delete_repositories")
            }
            stage('Delete salt keys') {
                sh(script: "${SUSEManagerCleanerProgram} --url ${serverHostname} --product_version ${product_version} ${defaultResourcesToDeleteArgs} --mode delete_salt_keys")
            }

            stage('Delete ssh know hosts') {
                sh(script: "${SUSEManagerCleanerProgram} --url ${serverHostname} --product_version ${product_version} --mode delete_known_hosts")
            }

            stage('Delete distributions folders') {
                sh(script: "${SUSEManagerCleanerProgram} --url ${serverHostname} --product_version ${product_version} --mode delete_distributions")
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
                    ./terracumber-cli ${commonParams} --logfile ${logFile} --init --sumaform-backend ${sumaform_backend} --use-tf-resource-cleaner --init --runstep provision ${tfResourcesToDeleteArg}
                """
            }

            stage('Redeploy the environment with new client VMs') {

                // Run Terracumber to deploy the environment
                sh """
                    ${environmentVars}
                    set +x
                    ./terracumber-cli ${commonParams} --logfile ${resultdirbuild}/sumaform.log --init --sumaform-backend ${sumaform_backend} --runstep provision
                """
            }

            stage('Copy the new custom repository json file to controller') {
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
                sh(script: "${SUSEManagerCleanerProgram} --url ${controllerHostname} --product_version ${product_version} --mode update_custom_repositories")

            }

            stage('Sanity check') {
                sh "./terracumber-cli ${commonParams} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:build_validation_sanity_check'"
            }

        }
        finally {
            stage('Copy back tfstate') {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    sh "cp ${localTfStateFile} ${targetedTfStateFile}"
                }
            }

            stage('Rename tfstate to avoid copying it between runs') {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    sh "mv ${localTfStateFile} ${localTfStateFile}.old"
                    sh "cp ${localTfStateFile}.old ${resultdirbuild}"
                }
            }
        }
    }
}

return this
