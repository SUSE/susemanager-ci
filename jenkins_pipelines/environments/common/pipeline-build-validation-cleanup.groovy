def run(params) {
    timestamps {
        // Define paths and environment variables for reusability
        GString TestEnvironmentCleanerProgram = "${WORKSPACE}/susemanager-ci/jenkins_pipelines/scripts/test_environment_cleaner/test_environment_cleaner_program/TestEnvironmentCleaner.py"
        // NEW: Path to the prepare_tfvars script
        GString PrepareTfvarsScript = "${WORKSPACE}/susemanager-ci/jenkins_pipelines/scripts/tf_vars_generator/prepare_tfvars.py"

        GString resultdir = "${WORKSPACE}/results"
        GString resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        GString exports = "export BUILD_NUMBER=${BUILD_NUMBER}; export BUILD_VALIDATION=true; "
        String proxy_container_repository = params.proxy_container_repository ?: null
        String serverHostname = null
        String controllerHostname = null
        String hypervisorUrl = null
        GString targetedTfFile = "${WORKSPACE}/../${params.targeted_project}/results/sumaform/main.tf"
        GString targetedTfStateFile = "${WORKSPACE}/../${params.targeted_project}/results/sumaform/terraform.tfstate"
        GString targetedSumaformDirPath = "${WORKSPACE}/../${params.targeted_project}/results/sumaform/"
        GString localSumaformDirPath = "${resultdir}/sumaform/"
        GString localTfStateFile = "${localSumaformDirPath}terraform.tfstate"
        GString localTfVarsFile = "${localSumaformDirPath}terraform.tfvars"
        GString localTfVarsFullFile = "${localSumaformDirPath}terraform.tfvars.full"
        GString logFile = "${resultdirbuild}/sumaform.log"

        // Construct the --tf-resources-to-delete argument dynamically
        ArrayList defaultResourcesToDelete = []
        if (params.delete_all_resources) {
            defaultResourcesToDelete.add('proxy')
            defaultResourcesToDelete.add('monitoring-server')
            defaultResourcesToDelete.add('build')
            defaultResourcesToDelete.add('terminal')
        }

        String defaultResourcesToDeleteArgs = defaultResourcesToDelete.isEmpty() ? '' : "--default-resources-to-delete ${defaultResourcesToDelete.join(' ')}"

        GString commonParams = "--outputdir ${resultdir} --tf ${targetedTfFile} --gitfolder ${resultdir}/sumaform --terraform-bin ${params.bin_path}"

        // Define shared environment variables for terraform calls
        GString environmentVars = """
                set +x
                source /home/jenkins/.credentials
                export TF_VAR_SERVER_CONTAINER_REPOSITORY='unused'
                export TF_VAR_PROXY_CONTAINER_REPOSITORY=${proxy_container_repository}
                export TERRAFORM=${params.bin_path}
                export TERRAFORM_PLUGINS=${params.bin_plugins_path}
            """

        try {
            stage('Clone terracumber, susemanager-ci and sumaform') {
                // Prevent rebuild option
                if (currentBuild.getBuildCauses().toString().contains("RebuildCause")) {
                    error "Rebuild is blocked for this job."
                }

                // Create a directory to store the build results (if it does not exist). Needed for first run
                sh "mkdir -p ${resultdir}"
                git url: params.terracumber_gitrepo, branch: params.terracumber_ref
                dir("susemanager-ci") {
                    checkout scm
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
                    rm -rf ${localSumaformDirPath} 
                    cp -r ${targetedSumaformDirPath} ${localSumaformDirPath}
                """
            }

            stage("Extract server hostname") {
                try {
                    serverHostname = sh(
                            script: """
                            set -e
                            cd ${localSumaformDirPath}
                            tofu output -json configuration | jq -r '.server.hostname'
                        """,
                            returnStdout: true
                    ).trim()
                    controllerHostname = sh(
                            script: """
                            set -e
                            cd ${localSumaformDirPath}
                            tofu output -json configuration | jq -r '.controller.hostname'
                        """,
                            returnStdout: true
                    ).trim()

                    // Print the value for confirmation
                    echo "Extracted server hostname: ${serverHostname}"
                    echo "Extracted controller hostname: ${controllerHostname}"

                } catch (Exception e) {
                    error("Failed to extract hostnames: ${e.message}")
                }

            }

            GString programCall = "${TestEnvironmentCleanerProgram} --url ${serverHostname} ${defaultResourcesToDeleteArgs} --mode"

            stage('Delete the systems') {
                sh(script: "${programCall} delete_systems")
            }
            stage('Delete config projects') {
                sh(script: "${programCall} delete_config_projects")
            }
            stage('Delete software channels') {
                sh(script: "${programCall} delete_software_channels")
            }
            stage('Delete activation keys') {
                sh(script: "${programCall} delete_activation_keys")
            }
            stage('Delete minion users') {
                sh(script: "${programCall} delete_users")
            }
            stage('Delete channel repositories') {
                sh(script: "${programCall} delete_repositories")
            }
            stage('Delete salt keys') {
                sh(script: "${programCall} delete_salt_keys")
            }
            if (params.delete_all_resources) {
                stage('Delete system groups') {
                    sh(script: "${programCall} delete_system_groups")
                }
                stage('Delete retail images') {
                    sh(script: "${programCall} delete_images")
                }
                stage('Delete retail image profiles') {
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                        sh(script: "${programCall} delete_image_profiles")
                    }
                }
            }
            stage('Delete ssh know hosts') {
                sh(script: "${TestEnvironmentCleanerProgram} --url ${serverHostname} --mode delete_known_hosts")
            }

            stage('Delete distributions folders') {
                sh(script: "${TestEnvironmentCleanerProgram} --url ${serverHostname} --mode delete_distributions")
            }

            stage('Delete client VMs') {
                // Determine cleaning mode
                String cleaningFlags = "--clean"
                if (params.delete_all_resources) {
                    cleaningFlags += " --delete-all"
                }

                // Execute Terracumber CLI to deploy the environment without clients
                sh """
                    ${environmentVars}
                    set -x
                    
                    # Backup the full tfvars file
                    cp "${localTfVarsFile}" "${localTfVarsFullFile}"

                    # Generate a stripped tfvars file (removing clients/minions)
                    python3 "${PrepareTfvarsScript}" \
                        --output "${localTfVarsFile}" \
                        --merge-files "${localTfVarsFullFile}" \
                        ${cleaningFlags}

                    # Apply changes (This will destroy the removed resources)
                    ${WORKSPACE}/terracumber-cli ${commonParams} --logfile ${logFile} \
                        --init --sumaform-backend ${params.sumaform_backend} \
                        --skip-variables-check \
                        --runstep provision
                """
            }

            stage('Redeploy the environment with new client VMs') {
                // Run Terracumber to deploy the environment
                sh """
                    ${environmentVars}
                    set +x
                    
                    # Restore the full tfvars file
                    cp "${localTfVarsFullFile}" "${localTfVarsFile}"

                    # Apply changes
                    ${WORKSPACE}/terracumber-cli ${commonParams} --logfile ${resultdirbuild}/sumaform.log \
                        --init --sumaform-backend ${params.sumaform_backend} \
                        --skip-variables-check \
                        --runstep provision
                """
            }

            stage('Sanity check') {
                sh "${WORKSPACE}/terracumber-cli ${commonParams} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --skip-variables-check --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:build_validation_sanity_check'"
            }

if (params.delete_all_resources) {
                stage("Update terminal mac addresses to controller") {
                    // CHANGED: Added double backslashes \\ for sed capture groups
                    hypervisorUrl = sh(
                            script: """
                                set -e
                                sed -n 's/.*hypervisor *= *"\\([^"]*\\)".*/\\1/p' "${localTfVarsFile}" | head -n 1
                             """,
                            returnStdout: true).trim()

                    echo "Hypervisor URL: ${hypervisorUrl}"
                    sh(script: "${TestEnvironmentCleanerProgram} --url ${serverHostname}  --controller_url ${controllerHostname} --hypervisor_url ${hypervisorUrl} --mode update_terminal_mac_addresses")
                }
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
                    archiveArtifacts artifacts: "results/sumaform/terraform.tfstate"
                    archiveArtifacts artifacts: "results/sumaform/main.tf"
                    // Delete the old tfstate file after archiving
                    sh "rm -f ${localTfStateFile}"
                    sh "rm -rf ${localSumaformDirPath}main.tf ${localSumaformDirPath}./terraform"
                }
            }
        }
    }
}

return this
