def run(params) {
    timestamps {
        // Define paths and environment variables for reusability
        GString TestEnvironmentCleanerProgram = "${WORKSPACE}/susemanager-ci/jenkins_pipelines/scripts/test_environment_cleaner/test_environment_cleaner_program/TestEnvironmentCleaner.py"
        GString resultdir = "${WORKSPACE}/results"
        GString resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        GString exports = "export BUILD_NUMBER=${BUILD_NUMBER}; export BUILD_VALIDATION=true; "
        String container_repository = params.container_repository ?: null
        String serverHostname = null
        GString targetedTfFile = "${WORKSPACE}/../${params.targeted_project}/results/sumaform/main.tf"
        GString targetedTfStateFile = "${WORKSPACE}/../${params.targeted_project}/results/sumaform/terraform.tfstate"
        GString targetedTerraformDirPath = "${WORKSPACE}/../${params.targeted_project}/results/sumaform/"
        GString localSumaformDirPath = "${resultdir}/sumaform/"
        GString localTfStateFile = "${localSumaformDirPath}terraform.tfstate"
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

        // Define shared environment variables for terraform calls
        GString environmentVars = """
                set -x
                source /home/jenkins/.credentials
                export TF_VAR_CONTAINER_REPOSITORY=${container_repository}
                export TERRAFORM=${terraform_bin}
                export TERRAFORM_PLUGINS=${terraform_bin_plugins}
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

                // Clone sumaform
                sh "set +x; source /home/jenkins/.credentials set -x; ${WORKSPACE}/terracumber-cli ${commonParams} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync"

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

            stage("Extract server hostname") {
                try {

                    serverHostname = sh(
                            script: """
                            set -e
                            cd ${localSumaformDirPath}
                            terraform output -json configuration | jq -r '.server.hostname'
                        """,
                            returnStdout: true
                    ).trim()

                    // Print the value for confirmation
                    echo "Extracted server hostname: ${serverHostname}"

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

            stage('Delete ssh know hosts') {
                sh(script: "${TestEnvironmentCleanerProgram} --url ${serverHostname} --mode delete_known_hosts")
            }

            stage('Delete distributions folders') {
                sh(script: "${TestEnvironmentCleanerProgram} --url ${serverHostname} --mode delete_distributions")
            }

            stage('Delete client VMs') {
                // Join the resources into a comma-separated string if there are any to delete
                String tfResourcesToDeleteArg = params.tfResourcesToDelete ? '' : "--tf-resources-delete-all"

                // Execute Terracumber CLI to deploy the environment without clients
                sh """
                    ${environmentVars}
                    set +x
                    ${WORKSPACE}/terracumber-cli ${commonParams} --logfile ${logFile} --init --sumaform-backend ${sumaform_backend} --use-tf-resource-cleaner --init --runstep provision ${tfResourcesToDeleteArg}
                """
            }

            stage('Redeploy the environment with new client VMs') {

                // Run Terracumber to deploy the environment
                sh """
                    ${environmentVars}
                    set +x
                    ${WORKSPACE}/terracumber-cli ${commonParams} --logfile ${resultdirbuild}/sumaform.log --init --sumaform-backend ${sumaform_backend} --runstep provision
                """
            }

            stage('Sanity check') {
                sh "${WORKSPACE}/terracumber-cli ${commonParams} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:build_validation_sanity_check'"
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
                    // Delete the old tfstate file after archiving
                    sh "rm -f ${localTfStateFile}"
                }
            }
        }
    }
}

return this
