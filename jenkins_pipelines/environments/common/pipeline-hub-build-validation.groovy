import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

def run(params) {
    ansiColor('xterm') {
        timestamps {
            def capybara_timeout = 60
            def default_timeout = 500
            env.bootstrap_timeout = 800

            def isNewJenkins = env.JENKINS_URL?.contains('jenkins.mgr.suse.de') || env.JENKINS_URL?.contains('jenkins.mgr.slc1.suse.org')
            def credInit = isNewJenkins
                    ? 'set +x; credFile=$(mktemp); echo "$SECRET_CONTENT" > "${credFile}"; chmod 600 "${credFile}"; . "${credFile}"; rm -f "${credFile}"; set -x'
                    : 'set +x; . /home/jenkins/.credentials; set -x'
            def withCreds = { Closure body ->
                if (isNewJenkins) {
                    withCredentials([string(credentialsId: 'sumaform-secrets', variable: 'SECRET_CONTENT')]) { body() }
                } else {
                    body()
                }
            }

            env.resultdir = "${WORKSPACE}/results"
            env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
            GString localSumaformDirPath = "${resultdir}/sumaform/"
            env.exports = "export BUILD_NUMBER=${BUILD_NUMBER}; export BUILD_VALIDATION=true; export CAPYBARA_TIMEOUT=${capybara_timeout}; export DEFAULT_TIMEOUT=${default_timeout}; export CUCUMBER_PUBLISH_QUIET=true;"
            String tfVariablesFile = 'susemanager-ci/terracumber_config/tf_files/variables/build-validation-variables.tf'
            GString tfvarsPrepareScript = "${WORKSPACE}/susemanager-ci/jenkins_pipelines/scripts/tf_vars_generator/prepare_tfvars.py"

            env.common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${resultdir}/sumaform --tf_variables_description_file=${tfVariablesFile} --terraform-bin ${params.bin_path}"
            if (params.deploy_parallelism) {
                env.common_params = "${env.common_params} --parallelism ${params.deploy_parallelism}"
            }

            deployed = false
            def proxy_stage_result_fail = false
            def monitoring_stage_result_fail = false
            def peripheral_stage_result_fail = false

            def server_container_registry = params.server_container_registry ?: ''
            def proxy_container_registry = params.proxy_container_registry ?: ''
            def server_container_image = params.server_container_image ?: ''
            def json_generator_version = params.json_generator_version ?: ''
            def product_version = params.product_version ?: ''

            try {
                stage('Clone terracumber, susemanager-ci') {
                    sh "mkdir -p ${resultdir}"
                    git url: params.terracumber_gitrepo, branch: params.terracumber_ref
                    dir("susemanager-ci") {
                        checkout scm
                    }
                }

                stage('Name run') {
                    currentBuild.description = nameDisplay(params)
                }

                stage('Deploy') {
                    if (params.must_deploy_hub) {
                        withCreds {
                            sh """
                            #!/bin/bash
                            set -e -o pipefail
                            ${credInit}
                            ./terracumber-cli ${common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync
                            """

                            if (params.custom_repositories?.trim()) {
                                writeFile file: 'custom_repositories.json', text: params.custom_repositories, encoding: "UTF-8"
                            }
                            if (params.mi_ids?.trim()) {
                                if (!json_generator_version) {
                                    error("json_generator_version is not set for this environment, cannot generate custom_repositories.json from mi_ids")
                                }
                                node('manager-jenkins-node') {
                                    checkout scm
                                    def res_python_script_ = sh(script: "python3 jenkins_pipelines/scripts/json_generator/maintenance_json_generator.py --version ${json_generator_version} --mi_ids ${params.mi_ids}", returnStatus: true)
                                    echo "Build Validation JSON script return code:\n ${res_python_script_}"
                                    if (res_python_script_ != 0) {
                                        error("MI IDs (${params.mi_ids}) passed by parameter are wrong (or already released)")
                                    }
                                }
                            }

                            def locationFile = "susemanager-ci/terracumber_config/tf_files/tfvars/location.tfvars"
                            def outputFile = "${localSumaformDirPath}terraform.tfvars"

                            def commonArgs = " --output \"${outputFile}\""
                            commonArgs += " --inject SERVER_CONTAINER_REGISTRY=${server_container_registry}"
                            commonArgs += " --inject PROXY_CONTAINER_REGISTRY=${proxy_container_registry}"
                            commonArgs += " --inject SERVER_CONTAINER_IMAGE=${server_container_image}"
                            commonArgs += " --inject CUCUMBER_GITREPO=${params.cucumber_gitrepo}"
                            commonArgs += " --inject CUCUMBER_BRANCH=${params.cucumber_ref}"
                            if (isNewJenkins) {
                                commonArgs += " --inject HYPERVISOR_PRIVATE_SSH_KEY_PATH=\"/home/jenkins/.ssh/id_ed25519.worker\""
                                commonArgs += " --inject CONTROLLER_PUBLIC_SSH_KEY_PATH=\"/home/jenkins/.ssh/id_ed25519.pub.controller\""
                                commonArgs += " --inject S390_LOCAL_USER=\"jenkins@jenkins.mgr.suse.de\""
                            }
                            if (product_version) {
                                commonArgs += " --inject PRODUCT_VERSION=${product_version}"
                            }
                            if (fileExists('custom_repositories.json')) {
                                commonArgs += " --custom-repositories-json ${WORKSPACE}/custom_repositories.json"
                            }

                            def scenarioArgs = " --merge-files \"${params.deployment_tfvars}\" \"${locationFile}\""

                            sh "python3 ${tfvarsPrepareScript} ${commonArgs} ${scenarioArgs}"

                            sh """
                            #!/bin/bash
                            set -e -o pipefail
                            ${credInit}
                            export TERRAFORM=${params.bin_path}
                            export TERRAFORM_PLUGINS=${params.bin_plugins_path}

                            ./terracumber-cli ${common_params} \\
                                --logfile ${resultdirbuild}/sumaform.log \\
                                --init \\
                                --taint '.*(domain|combustion_disk|cloudinit_disk|ignition_disk|main_disk|data_disk|database_disk|standalone_provisioning|server_extra_nfs_mounts).*' \\
                                --custom-repositories ${WORKSPACE}/custom_repositories.json \\
                                --sumaform-backend ${params.sumaform_backend} \\
                                --skip-variables-check \\
                                --tf_configuration_files "${outputFile}" \\
                                --runstep provision
                            """

                            runCucumberRakeTarget('utils:generate_build_validation_features')
                            runCucumberRakeTarget('jenkins:generate_rake_files_build_validation')
                            deployed = true
                        }
                    } else if (isNewJenkins) {
                        Utils.markStageSkippedForConditional(STAGE_NAME)
                    }
                }

                stage('Run core features') {
                    if (params.must_run_hub_core && (deployed || !params.must_deploy_hub)) {
                        runCucumberRakeTarget('cucumber:build_validation_core')
                    } else if (isNewJenkins) {
                        Utils.markStageSkippedForConditional(STAGE_NAME)
                    }
                }

                stage('Sync. products and channels') {
                    if (params.must_sync_hub && (deployed || !params.must_deploy_hub)) {
                        def res_products = runCucumberRakeTarget('cucumber:build_validation_reposync', true)
                        echo "Reposync status code: ${res_products}"
                        sh "exit ${res_products}"
                    } else if (isNewJenkins) {
                        Utils.markStageSkippedForConditional(STAGE_NAME)
                    }
                }

                /** Proxy stages begin **/
                if (params.enable_hub_proxy_stages) {
                    try {
                        stage('Add MUs Proxy') {
                            def res = runCucumberRakeTarget('cucumber:build_validation_add_maintenance_update_repositories_proxy', true)
                            echo "Add MUs Proxy status code: ${res}"
                            sh "exit ${res}"
                        }
                        stage('Add Activation Keys Proxy') {
                            def res = runCucumberRakeTarget('cucumber:build_validation_add_activation_key_proxy', true)
                            echo "Add Activation Keys Proxy status code: ${res}"
                            sh "exit ${res}"
                        }
                        stage('Create bootstrap repository Proxy') {
                            def res = runCucumberRakeTarget('cucumber:build_validation_create_bootstrap_repository_proxy', true)
                            echo "Create bootstrap repository Proxy status code: ${res}"
                            sh "exit ${res}"
                        }
                        stage('Bootstrap Proxy') {
                            def res = runCucumberRakeTarget('cucumber:build_validation_init_proxy', true)
                            echo "Bootstrap Proxy status code: ${res}"
                            sh "exit ${res}"
                        }
                    } catch (Exception ex) {
                        println('Proxy stage failed')
                        proxy_stage_result_fail = true
                    }
                }
                /** Proxy stages end **/

                /** Monitoring stages begin **/
                if (params.enable_hub_monitoring_stages) {
                    try {
                        stage('Add MUs Monitoring') {
                            def res = runCucumberRakeTarget('cucumber:build_validation_add_maintenance_update_repositories_monitoring_server', true)
                            echo "Add MUs Monitoring status code: ${res}"
                            sh "exit ${res}"
                        }
                        stage('Add Activation Keys Monitoring') {
                            def res = runCucumberRakeTarget('cucumber:build_validation_add_activation_key_monitoring_server', true)
                            echo "Add Activation Keys Monitoring status code: ${res}"
                            sh "exit ${res}"
                        }
                        stage('Create bootstrap repository Monitoring') {
                            def res = runCucumberRakeTarget('cucumber:build_validation_create_bootstrap_repository_monitoring_server', true)
                            echo "Create bootstrap repository Monitoring status code: ${res}"
                            sh "exit ${res}"
                        }
                        stage('Bootstrap Monitoring Server') {
                            def res = runCucumberRakeTarget('cucumber:build_validation_init_monitoring', true)
                            echo "Bootstrap Monitoring Server status code: ${res}"
                            sh "exit ${res}"
                        }
                    } catch (Exception ex) {
                        println('Monitoring stage failed')
                        monitoring_stage_result_fail = true
                    }
                }
                /** Monitoring stages end **/

                /** Peripheral stages begin **/
                if (params.enable_hub_peripheral_stages) {
                    try {
                        stage('Hub peripheral stages') {
                            hubPeripheralStages()
                        }
                    } catch (Exception ex) {
                        println('ERROR: one or more hub peripheral stages have failed')
                        peripheral_stage_result_fail = true
                    }
                }
                /** Peripheral stages end **/

            } finally {
                stage('Save TF state') {
                    archiveArtifacts artifacts: "results/sumaform/terraform.tfstate, results/sumaform/.terraform/**/*"
                }

                stage('Get results') {
                    def result_error = 0
                    if (deployed || !params.must_deploy_hub) {
                        try {
                            runCucumberRakeTarget('cucumber:build_validation_finishing')
                        } catch (Exception ex) {
                            println("ERROR: rake cucumber:build_validation_finishing failed")
                            result_error = 1
                        }
                        try {
                            runCucumberRakeTarget('utils:generate_test_report')
                        } catch (Exception ex) {
                            println("ERROR: rake utils:generate_test_report failed")
                            result_error = 1
                        }
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep getresults"
                        publishHTML(target: [
                                allowMissing         : true,
                                alwaysLinkToLastBuild: false,
                                keepAll              : true,
                                reportDir            : "${resultdirbuild}/results/cucumber_report/",
                                reportFiles          : 'index.html',
                                reportName           : "Hub Build Validation report"]
                        )
                    }
                    sh "./clean-old-results -r ${resultdir}"
                    if (proxy_stage_result_fail) {
                        error("Proxy stage failed")
                    }
                    if (monitoring_stage_result_fail) {
                        error("Monitoring stage failed")
                    }
                    if (peripheral_stage_result_fail) {
                        error("Hub peripheral stage failed")
                    }
                    sh "exit ${result_error}"
                }
            }
        }
    }
}

def hubPeripheralStages() {
    parallel(
        'prh1': {
            stage('prh1: Server setup') {
                def res = runCucumberRakeTarget('cucumber:hub_bv_prh1_server_setup', true)
                echo "prh1 server setup status code: ${res}"
                sh "exit ${res}"
            }
            stage('prh1: Channel synchronization') {
                def res = runCucumberRakeTarget('cucumber:hub_bv_prh1_channel_synchronization', true)
                echo "prh1 channel sync status code: ${res}"
                sh "exit ${res}"
            }
            stage('prh1: Proxy2') {
                def res = runCucumberRakeTarget('cucumber:hub_bv_prh1_proxy2', true)
                echo "prh1 proxy2 status code: ${res}"
                sh "exit ${res}"
            }
            stage('prh1: Add Activation Key') {
                def res = runCucumberRakeTarget('cucumber:hub_bv_prh1_add_activation_key', true)
                echo "prh1 add activation key status code: ${res}"
                sh "exit ${res}"
            }
            stage('prh1: Create bootstrap repository') {
                def res = runCucumberRakeTarget('cucumber:hub_bv_prh1_create_bootstrap_repository', true)
                echo "prh1 create bootstrap repository status code: ${res}"
                sh "exit ${res}"
            }
            stage('prh1: Minions') {
                parallel(
                    'ubuntu2404_minion': {
                        stage('prh1: ubuntu2404 minion') {
                            def res = runCucumberRakeTarget('cucumber:hub_bv_prh1_ubuntu2404_minion', true)
                            sh "exit ${res}"
                        }
                    },
                    'sles15sp7_minion': {
                        stage('prh1: sles15sp7 minion') {
                            def res = runCucumberRakeTarget('cucumber:hub_bv_prh1_sles15sp7_minion', true)
                            sh "exit ${res}"
                        }
                    }
                )
            }
        },
        'prh2': {
            stage('prh2: Server setup') {
                def res = runCucumberRakeTarget('cucumber:hub_bv_prh2_server_setup', true)
                echo "prh2 server setup status code: ${res}"
                sh "exit ${res}"
            }
            stage('prh2: Channel synchronization') {
                def res = runCucumberRakeTarget('cucumber:hub_bv_prh2_channel_synchronization', true)
                echo "prh2 channel sync status code: ${res}"
                sh "exit ${res}"
            }
            stage('prh2: Proxy3') {
                def res = runCucumberRakeTarget('cucumber:hub_bv_prh2_proxy3', true)
                echo "prh2 proxy3 status code: ${res}"
                sh "exit ${res}"
            }
            stage('prh2: Add Activation Key') {
                def res = runCucumberRakeTarget('cucumber:hub_bv_prh2_add_activation_key', true)
                echo "prh2 add activation key status code: ${res}"
                sh "exit ${res}"
            }
            stage('prh2: Create bootstrap repository') {
                def res = runCucumberRakeTarget('cucumber:hub_bv_prh2_create_bootstrap_repository', true)
                echo "prh2 create bootstrap repository status code: ${res}"
                sh "exit ${res}"
            }
            stage('prh2: Minions') {
                parallel(
                    'slmicro62_minion': {
                        stage('prh2: slmicro62 minion') {
                            def res = runCucumberRakeTarget('cucumber:hub_bv_prh2_slmicro62_minion', true)
                            sh "exit ${res}"
                        }
                    },
                    'rocky10_minion': {
                        stage('prh2: rocky10 minion') {
                            def res = runCucumberRakeTarget('cucumber:hub_bv_prh2_rocky10_minion', true)
                            sh "exit ${res}"
                        }
                    }
                )
            }
        }
    )
}

def runCucumberRakeTarget(String rake_target, boolean return_status = false, disableMinions = null) {
    def unset_vars = ""
    if (disableMinions) {
        def list_to_join = disableMinions instanceof String ? disableMinions.split(' ') : disableMinions
        unset_vars = list_to_join ? "unset ${list_to_join.join(' ')}; " : ""
    }

    def script = """
        ./terracumber-cli ${common_params} \\
            --logfile ${resultdirbuild}/testsuite.log \\
            --runstep cucumber \\
            --cucumber-cmd '${unset_vars}${env.exports} cd /root/spacewalk/testsuite; rake ${rake_target}'
    """

    def final_script = script.stripIndent().trim()

    if (return_status) {
        return sh(script: final_script, returnStatus: true)
    } else {
        sh final_script
    }
}

def nameDisplay(params) {
    def buildLabel = []
    if (params.must_deploy_hub) buildLabel << 'deploy'
    if (params.must_run_hub_core) buildLabel << 'core'
    if (params.must_sync_hub) buildLabel << 'reposync'
    if (params.enable_hub_proxy_stages) buildLabel << 'proxy'
    if (params.enable_hub_monitoring_stages) buildLabel << 'monitoring'
    if (params.enable_hub_peripheral_stages) buildLabel << 'peripheral'

    def product_version = params.product_version_display ?: ''
    return "${product_version} - hub - ${buildLabel.join(' ')}"
}

return this
