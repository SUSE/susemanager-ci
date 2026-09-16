import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

// Standalone CI pipeline: clone -> deploy (BV mechanism) -> CI rake states ->
// hub_testing -> results. Self-contained on purpose: a load-ed Groovy script
// cannot see helpers defined in the caller, and the spec accepts duplication
// over sharing so BV/CI stay independent.
def run(params) {
    ansiColor('xterm') {
        timestamps {
            // Capybara configuration
            def capybara_timeout = 60
            def default_timeout = 500

            env.resultdir = "${WORKSPACE}/results"
            env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
            GString localSumaformDirPath = "${resultdir}/sumaform/"
            // The junit plugin doesn't affect full paths
            GString junit_resultdir = "results/${BUILD_NUMBER}/results_junit"
            GString tfvarsPrepareScript = "${WORKSPACE}/susemanager-ci/jenkins_pipelines/scripts/tf_vars_generator/prepare_tfvars.py"
            String tfVariablesFile = 'susemanager-ci/terracumber_config/tf_files/variables/build-validation-variables.tf'

            env.exports = "export BUILD_NUMBER=${BUILD_NUMBER}; export CAPYBARA_TIMEOUT=${capybara_timeout}; export DEFAULT_TIMEOUT=${default_timeout}; export CUCUMBER_PUBLISH_QUIET=true;"

            def deployed = false
            // Null-safe stage gates (default on) so callers can skip stages —
            // e.g. must_run_secondary=false + must_run_hub=true runs hub alone.
            def runCore = params.must_run_core == null ? true : params.must_run_core
            def runSecondary = params.must_run_secondary == null ? true : params.must_run_secondary
            def runHub = params.must_run_hub == null ? true : params.must_run_hub
            def server_container_registry = params.server_container_registry ?: ''
            def proxy_container_registry = params.proxy_container_registry ?: ''
            def server_container_image = params.server_container_image ?: ''
            def product_version = params.product_version ?: ''
            def base_os = params.base_os ?: ''
            def json_generator_version = params.json_generator_version ?: ''

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

            env.common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${resultdir}/sumaform --tf_variables_description_file=${tfVariablesFile} --terraform-bin ${params.bin_path}"
            if (params.deploy_parallelism) {
                env.common_params = "${env.common_params} --parallelism ${params.deploy_parallelism}"
            }

            // Inactivity timeout: kills a cucumber run that has stopped producing output entirely.
            def rawIdleTimeout = params.cucumber_idle_timeout?.toString()?.trim()
            def cucumberIdleTimeoutMinutes = rawIdleTimeout?.isInteger() && rawIdleTimeout.toInteger() > 0 ? rawIdleTimeout.toInteger() : 60
            def withIdleTimeout = { Closure body ->
                timeout(activity: true, time: cucumberIdleTimeoutMinutes, unit: 'MINUTES') { body() }
            }

            // Build a terracumber cucumber invocation for a rake target.
            // prefix carries per-run env exports (e.g. TAGS) that must precede the cd.
            def cucumberCmd = { String rake_target, String prefix = '' ->
                "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${prefix}cd /root/spacewalk/testsuite; ${env.exports} rake ${rake_target}'"
            }

            try {
                stage('Clone terracumber, susemanager-ci') {
                    sh "mkdir -p ${resultdir}"
                    git url: params.terracumber_gitrepo, branch: params.terracumber_ref
                    dir("susemanager-ci") {
                        checkout scm
                    }
                }

                // --- Deploy (mechanism copied from pipeline-build-validation.groovy,
                //     proven against mlm52_ci.tfvars) ---
                stage('Build containers') {
                    if (params.container_project && params.mi_project && params.must_deploy) {
                        def SCRIPT_DIR = "${WORKSPACE}/susemanager-ci/jenkins_pipelines/scripts/edit_bci_project"
                        sh """
                        set -e
                        python3 -m venv ${WORKSPACE}/venv || true
                        if [ ! -x ${WORKSPACE}/venv/bin/python3 ]; then
                            echo "venv creation incomplete/failed (missing bin/python3) - likely no working ensurepip bundled with this image's python3-venv package. Recreating without pip and bootstrapping it manually."
                            rm -rf ${WORKSPACE}/venv
                            python3 -m venv --without-pip ${WORKSPACE}/venv
                            curl -sS https://bootstrap.pypa.io/get-pip.py | ${WORKSPACE}/venv/bin/python3
                        fi
                    """
                        sh "${WORKSPACE}/venv/bin/pip install -r ${SCRIPT_DIR}/requirements.txt"
                        sh(script: "${WORKSPACE}/venv/bin/python ${SCRIPT_DIR}/edit.py --container-project ${params.container_project} --mi-project ${params.mi_project}", returnStdout: true)
                        def custom_project_path = "registry.suse.de/${params.container_project.toLowerCase().replaceAll(':', '/')}/containerfile"
                        server_container_registry = custom_project_path
                        proxy_container_registry = custom_project_path
                    } else if (isNewJenkins) {
                        Utils.markStageSkippedForConditional(STAGE_NAME)
                    }
                }

                stage('Deploy') {
                    if (params.use_previous_terraform_state && currentBuild.previousBuild != null) {
                        copyArtifacts(
                                projectName: env.JOB_NAME,
                                selector: [$class: 'SpecificBuildSelector', buildNumber: "${currentBuild.previousBuild.number}"],
                                optional: true
                        )
                    }

                    if (params.must_deploy) {
                        withCreds {
                            // Clone sumaform
                            sh """
                            #!/bin/bash
                            set -e -o pipefail
                            ${credInit}
                            ./terracumber-cli ${common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync
                        """

                            // custom_repositories.json from parameter (self-skips when unset)
                            if (params.custom_repositories?.trim()) {
                                writeFile file: 'custom_repositories.json', text: params.custom_repositories, encoding: "UTF-8"
                            }
                            // custom_repositories.json from MI Identifiers (self-skips when unset)
                            if (params.mi_ids?.trim()) {
                                if (!json_generator_version) {
                                    error("json_generator_version is not set for this environment, cannot generate custom_repositories.json from mi_ids")
                                }
                                node('manager-jenkins-node') {
                                    checkout scm
                                    def res_python_script_ = sh(script: "python3 jenkins_pipelines/scripts/json_generator/maintenance_json_generator.py --version ${json_generator_version} --mi_ids ${params.mi_ids}", returnStatus: true)
                                    echo "CI JSON script return code:\n ${res_python_script_}"
                                    if (res_python_script_ != 0) {
                                        error("MI IDs (${params.mi_ids}) passed by parameter are wrong (or already released)")
                                    }
                                }
                            }

                            def locationFile = "susemanager-ci/terracumber_config/tf_files/tfvars/location.tfvars"
                            def outputFile = "${localSumaformDirPath}terraform.tfvars"

                            def s390LocalUser
                            if (env.JENKINS_URL?.contains('jenkins.mgr.suse.de'))
                                s390LocalUser = 'jenkins@jenkins-node.mgr.suse.de'
                            else if (env.JENKINS_URL?.contains('jenkins.mgr.slc1.suse.org'))
                                s390LocalUser = 'jenkins@jenkins-node.mgr.slc1.suse.org'
                            else
                                s390LocalUser = 'jenkins@jenkins-worker.mgr.suse.de'
                            def commonArgs = " --output \"${outputFile}\""
                            commonArgs += " --inject SERVER_CONTAINER_REGISTRY=${server_container_registry}"
                            commonArgs += " --inject PROXY_CONTAINER_REGISTRY=${proxy_container_registry}"
                            commonArgs += " --inject SERVER_CONTAINER_IMAGE=${server_container_image}"
                            commonArgs += " --inject CUCUMBER_GITREPO=${params.cucumber_gitrepo}"
                            commonArgs += " --inject CUCUMBER_BRANCH=${params.cucumber_ref}"
                            if (isNewJenkins) {
                                commonArgs += " --inject HYPERVISOR_PRIVATE_SSH_KEY_PATH=\"/home/jenkins/.ssh/id_ed25519.worker\""
                                commonArgs += " --inject CONTROLLER_PUBLIC_SSH_KEY_PATH=\"/home/jenkins/.ssh/id_ed25519.pub.controller\""
                                commonArgs += " --inject S390_LOCAL_USER=\"${s390LocalUser}\""
                            }
                            if (product_version) {
                                commonArgs += " --inject PRODUCT_VERSION=${product_version}"
                            }
                            if (base_os) {
                                commonArgs += " --inject BASE_OS=${base_os}"
                            }
                            if (fileExists('custom_repositories.json')) {
                                commonArgs += " --custom-repositories-json ${WORKSPACE}/custom_repositories.json"
                            }

                            // CI deploys from a static tfvars file, cleaned to the minions_to_run list.
                            def scenarioArgs = ""
                            if (params.get('deployment_tfvars')) {
                                def minionsToKeep = params.minions_to_run.split(/,\s*/).join(' ')
                                scenarioArgs += " --merge-files \"${params.deployment_tfvars}\" \"${locationFile}\""
                                scenarioArgs += " --clean --keep-resources ${minionsToKeep}"
                            } else {
                                error "No deployment_tfvars specified"
                            }

                            // Generate the tfvars
                            sh "python3 ${tfvarsPrepareScript} ${commonArgs} ${scenarioArgs}"

                            // Deploy the environment. mode='ci' drops --custom-repositories.
                            sh """
                            #!/bin/bash
                            set -e -o pipefail
                            ${credInit}
                            export TERRAFORM=${params.bin_path}
                            export TERRAFORM_PLUGINS=${params.bin_plugins_path}

                        ./terracumber-cli ${common_params} \
                            --logfile ${resultdirbuild}/sumaform.log \
                            --init \
                            --taint '.*(domain|combustion_disk|cloudinit_disk|ignition_disk|main_disk|data_disk|database_disk|standalone_provisioning|server_extra_nfs_mounts).*' \
                            ${(!params.mode || params.mode == 'BV') ? "--custom-repositories ${WORKSPACE}/custom_repositories.json \\" : ''} \
                            --sumaform-backend ${params.sumaform_backend} \
                            --skip-variables-check \
                            --tf_configuration_files "${outputFile}" \
                            --runstep provision
                    """
                            deployed = true
                        }
                    } else if (isNewJenkins) {
                        Utils.markStageSkippedForConditional(STAGE_NAME)
                    }
                }

                // --- CI rake states (copied from pipeline.groovy) ---
                stage('Core - Setup') {
                    if (runCore) {
                        withIdleTimeout {
                            sh cucumberCmd('cucumber:core')
                            sh cucumberCmd('cucumber:reposync')
                        }
                    } else if (isNewJenkins) {
                        Utils.markStageSkippedForConditional(STAGE_NAME)
                    }
                }
                stage('Core - Proxy') {
                    if (runCore) {
                        withIdleTimeout {
                            sh cucumberCmd('cucumber:proxy')
                        }
                    } else if (isNewJenkins) {
                        Utils.markStageSkippedForConditional(STAGE_NAME)
                    }
                }
                stage('Core - Initialize clients') {
                    if (runCore) {
                        withIdleTimeout {
                            sh cucumberCmd('parallel:init_clients')
                        }
                    } else if (isNewJenkins) {
                        Utils.markStageSkippedForConditional(STAGE_NAME)
                    }
                }
                stage('Secondary features') {
                    if (!runSecondary) {
                        if (isNewJenkins) {
                            Utils.markStageSkippedForConditional(STAGE_NAME)
                        }
                        return
                    }
                    def tags_list = ""
                    if (params.functional_scopes) {
                        // Re-add the @ prefix stripped from the job parameters, then join as an OR expression.
                        def transformed_scopes = params.functional_scopes.split(',')
                                .collect { it.trim() }
                                .collect { it.startsWith('@') ? it : "@${it}" }
                                .join(' or ')
                        // --cucumber-cmd is single-quoted and rake re-splits TAGS through a shell,
                        // so the value carries its own quotes rather than nesting single ones.
                        tags_list = "export TAGS=\"\\\"${transformed_scopes}\\\"\"; "
                    }
                    def statusCode1 = 1
                    def statusCode2 = 1
                    def statusCode3 = 1
                    withIdleTimeout { statusCode1 = sh(script: cucumberCmd('cucumber:secondary', tags_list), returnStatus: true) }
                    withIdleTimeout { statusCode2 = sh(script: cucumberCmd("${params.rake_namespace}:secondary_parallelizable", tags_list), returnStatus: true) }
                    withIdleTimeout { statusCode3 = sh(script: cucumberCmd("${params.rake_namespace}:secondary_finishing", tags_list), returnStatus: true) }
                    sh "exit \$(( ${statusCode1}|${statusCode2}|${statusCode3} ))"
                }

                // --- New hub_testing stage. cucumber:hub_full_topology is a placeholder
                //     rake task to be authored later; a non-zero result fails the build. ---
                stage('hub_testing') {
                    if (runHub) {
                        withIdleTimeout {
                            sh cucumberCmd('cucumber:hub_full_topology')
                        }
                    } else if (isNewJenkins) {
                        Utils.markStageSkippedForConditional(STAGE_NAME)
                    }
                }
            }
            finally {
                stage('Save TF state') {
                    archiveArtifacts artifacts: "results/sumaform/terraform.tfstate, results/sumaform/.terraform/**/*"
                }

                stage('Get results') {
                    def result_error = 0
                    try {
                        if (deployed || !params.must_deploy) {
                            try {
                                sh cucumberCmd('cucumber:finishing')
                            } catch (err) {
                                println("ERROR: rake cucumber:finishing failed: ${err}")
                                result_error = 1
                            }
                            try {
                                sh cucumberCmd('utils:generate_test_report')
                            } catch (err) {
                                println("ERROR: rake utils:generate_test_report failed: ${err}")
                                result_error = 1
                            }
                            sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep getresults"
                            publishHTML(target: [
                                    allowMissing         : true,
                                    alwaysLinkToLastBuild: false,
                                    keepAll              : true,
                                    reportDir            : "${resultdirbuild}/results/cucumber_report/",
                                    reportFiles          : 'index.html',
                                    reportName           : "TestSuite Report"]
                            )
                            catchError(buildResult: 'FAILURE', stageResult: 'SUCCESS') {
                                junit allowEmptyResults: true,
                                        testResults: "${junit_resultdir}/*.xml",
                                        skipPublishingChecks: true
                            }
                        }
                        // Send email (subject comes from MAIL_SUBJECT in the tfvars via terracumber)
                        try {
                            sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/mail.log --runstep mail"
                        } catch (err) {
                            println("ERROR: sending the results email failed: ${err}")
                            result_error = 1
                        }
                        sh "exit ${result_error}"
                    } finally {
                        // Clean up old results — in finally so it runs even when getresults/mail fail
                        sh "./clean-old-results -r ${resultdir}"
                    }
                }
            }
        }
    }
}

return this
