import org.jenkinsci.plugins.pipeline.modeldefinition.Utils

// Standalone CI pipeline: clone -> deploy (BV mechanism) -> CI rake states ->
// hub_testing -> results. Self-contained on purpose: a load-ed Groovy script
// cannot see helpers defined in the caller, and the spec accepts duplication
// over sharing so BV/CI stay independent.
def run(params) {
    if (load('jenkins_pipelines/environments/common/helpers/quiet-window.groovy').skipIfQuiet()) { return }
    def safe = load('jenkins_pipelines/environments/common/helpers/safe-step.groovy')
    ansiColor('xterm') {
        timestamps {
            // Capybara configuration
            def capybara_timeout = params.capybara_timeout == null ? 60 : params.capybara_timeout
            def default_timeout = params.default_timeout == null ? 500 : params.default_timeout

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

            // Nightly extras ported from pipeline.groovy: product changes, sanity check, flaky-test tagging,
            // mirror sync and RRTG ingest. Opt-in: only jobs that set params.nightly get them.
            def isNightly = params.nightly == true
            def showProductChanges = isNightly && params.show_product_changes
            def previous_commit = null
            def product_commit = null
            def runtime = env.JOB_BASE_NAME.endsWith('-RKE2') ? 'rke2' : 'podman'
            def mirror_scope = isNightly ? env.JOB_BASE_NAME.split('-acceptance-tests')[0].replaceAll("-dev", "") : null
            def ci_label_map = [
                    '5.1'  : '5.1_ci',
                    '5.2'  : "5.2_${runtime}_ci",
                    'Head' : "head_${runtime}_ci",
                    'uyuni': "uyuni_${runtime}_ci"
            ]
            def ci_label = isNightly ? (ci_label_map.find { k, v -> env.JOB_BASE_NAME.contains(k) }?.value ?: '') : ''
            def rrtg_version = isNightly ? env.JOB_BASE_NAME.find(/5\.1|5\.2|Head/)?.toLowerCase() : null
            // 5.2 and head are reported per deployment flavour (podman / rke2)
            if (rrtg_version in ['5.2', 'head']) {
                rrtg_version += env.JOB_BASE_NAME.endsWith('-RKE2') ? '-rke2' : '-podman'
            }
            if (isNightly && !rrtg_version && env.JOB_BASE_NAME == 'uyuni-master-dev-acceptance-tests-podman') {
                rrtg_version = 'uyuni-podman'
            }
            if (showProductChanges) {
                // Retrieve the hash commit of the last product built in OBS/IBS and previous job
                def prefix = env.JOB_BASE_NAME.split('-acceptance-tests')[0]
                if (prefix == "uyuni-master-dev") {
                    prefix = "manager-Head-dev"
                }
                // The 2obs jobs are releng, not dev
                prefix = prefix.replaceAll("-dev", "-releng")
                def request = httpRequest ignoreSslErrors: true, url: "https://ci.suse.de/job/${prefix}-2obs/lastBuild/api/json"
                def requestJson = readJSON text: request.getContent()
                product_commit = "${requestJson.actions.lastBuiltRevision.SHA1}"
                product_commit = product_commit.substring(product_commit.indexOf('[') + 1, product_commit.indexOf(']'))
                print "Current product commit: ${product_commit}"
                // Walk back past builds without a "[commit]" description (e.g. quiet-window skips)
                def previousBuild = currentBuild.getPreviousBuild()
                def hasCommit = { String d -> d != null && d.indexOf('[') >= 0 && d.indexOf(']') > d.indexOf('[') }
                while (previousBuild != null && !hasCommit(previousBuild.description)) {
                    previousBuild = previousBuild.getPreviousBuild()
                }
                if (previousBuild == null) {
                    previous_commit = product_commit
                } else {
                    def desc = previousBuild.description
                    previous_commit = desc.substring(desc.indexOf('[') + 1, desc.indexOf(']'))
                }
                print "Previous product commit: ${previous_commit}"
            }

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
            // Note: Jenkins CPS-transforms this closure, which does not honor Groovy
            // default parameter values — a missing prefix arrives as null, not ''.
            def cucumberCmd = { String rake_target, String prefix = null ->
                def safePrefix = prefix ?: ''
                "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${safePrefix}cd /root/spacewalk/testsuite; ${env.exports} rake ${rake_target}'"
            }

            try {
                stage('Clone terracumber, susemanager-ci') {
                    if (showProductChanges) {
                        // Rename build using product commit hash; the next build reads it back as previous_commit
                        currentBuild.description = product_commit ? "[${product_commit}]" : "[${params.tf_file}]"
                    }
                    sh "mkdir -p ${resultdir}"
                    git url: params.terracumber_gitrepo, branch: params.terracumber_ref
                    dir("susemanager-ci") {
                        checkout scm
                    }
                    // Run minima sync on the mirror of the deployment: LOCATION comes from the deployment tfvars,
                    // the mirror host from location.tfvars (not from the Jenkins host, which may differ).
                    if (mirror_scope != null) {
                        def location = sh(script: "grep -oP '^LOCATION\\s*=\\s*\"\\K[^\"]+' ${params.deployment_tfvars}", returnStdout: true).trim()
                        def mirror = sh(script: "sed -n '/^  ${location} = {/,/}/p' susemanager-ci/terracumber_config/tf_files/tfvars/location.tfvars | grep -oP 'mirror\\s*=\\s*\"\\K[^\"]+'", returnStdout: true).trim()
                        sh "ssh root@${mirror} -t \"test -x /usr/local/bin/minima-${mirror_scope}.sh && /usr/local/bin/minima-${mirror_scope}.sh || echo 'no mirror script for this scope'\""
                    }
                }

                // --- Deploy (mechanism copied from pipeline-build-validation.groovy,
                //     proven against mlm52_personal.tfvars) ---
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

                    if (params.must_deploy) {
                        // Jenkins hands out a "@N" copy of the workspace when the base one is still leased, i.e. the
                        // previous run is not fully finished. The copy has no Terraform state, so Deploy would plan a
                        // full create against infrastructure that already exists. Stop before touching libvirt.
                        if (env.WORKSPACE ==~ /.*@\d+$/) {
                            error("Workspace ${env.WORKSPACE} is a Jenkins copy (@N): the previous build still holds the base workspace and the Terraform state is not here. Wait for it to finish, then re-run.")
                        }
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
                                    stash name: 'custom_repos_json', includes: 'custom_repositories.json'
                                }
                                unstash 'custom_repos_json'
                            }

                            def locationFile ="susemanager-ci/terracumber_config/tf_files/tfvars/location.tfvars"
                            def outputFile = "${localSumaformDirPath}terraform.tfvars"

                            def s390LocalUser
                            if (env.JENKINS_URL?.contains('jenkins.mgr.suse.de'))
                                s390LocalUser = 'jenkins@jenkins-node.mgr.suse.de'
                            else if (env.JENKINS_URL?.contains('jenkins.mgr.slc1.suse.org'))
                                s390LocalUser = 'jenkins@jenkins-node.mgr.slc1.suse.org'
                            else
                                s390LocalUser = 'jenkins@jenkins-worker.mgr.suse.de'
                            def commonArgs = " --output \"${outputFile}\""
                            // Empty means the nightly defaults of the product version: only a user override is injected
                            if (server_container_registry) {
                                commonArgs += " --inject SERVER_CONTAINER_REGISTRY=${server_container_registry}"
                            }
                            if (proxy_container_registry) {
                                commonArgs += " --inject PROXY_CONTAINER_REGISTRY=${proxy_container_registry}"
                            }
                            if (server_container_image) {
                                commonArgs += " --inject SERVER_CONTAINER_IMAGE=${server_container_image}"
                            }
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
                            ${(!params.mode || params.mode == 'BV') ? "--custom-repositories ${WORKSPACE}/custom_repositories.json" : ''} \
                            --sumaform-backend ${params.sumaform_backend} \
                            --skip-variables-check \
                            --tf_configuration_files "${outputFile}" \
                            --runstep provision
                    """
                            deployed = true
                            if (isNightly) {
                                // Collect and tag flaky tests from the GitHub Board (non-fatal)
                                def rakeTarget = ci_label ? "utils:collect_and_tag_flaky_tests[${ci_label}]" : "utils:collect_and_tag_flaky_tests"
                                sh script: cucumberCmd(rakeTarget), returnStatus: true
                            }
                        }
                    } else if (isNewJenkins) {
                        Utils.markStageSkippedForConditional(STAGE_NAME)
                    }
                }

                stage('Product changes') {
                    if (showProductChanges) {
                        // Comparison between the previous and the current git revision of the spacewalk (or uyuni)
                        // repository pushed in IBS (or OBS), run on the controller.
                        sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/; git --no-pager log --pretty=format:\"%h %<(16,trunc)%cn  %s  %d\" ${previous_commit}..${product_commit}'", returnStatus: true
                    } else if (isNewJenkins) {
                        Utils.markStageSkippedForConditional(STAGE_NAME)
                    }
                }

                stage('Sanity Check') {
                    if (isNightly) {
                        withIdleTimeout {
                            sh cucumberCmd('cucumber:sanity_check')
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
                stage('Secondary') {
                    def tags_list = ""
                    // When triggered by cron the Active Choices plugin (JENKINS-42568) always returns
                    // the first checkbox value instead of none, so ignore functional_scopes on timer builds.
                    def isTimerTriggered = currentBuild.getBuildCauses('hudson.triggers.TimerTrigger$TimerTriggerCause')
                    def effectiveScopes = isTimerTriggered ? '' : params.functional_scopes
                    if (runSecondary && effectiveScopes) {
                        // Re-add the @ prefix stripped from the job parameters, then join as an OR expression.
                        def transformed_scopes = effectiveScopes.split(',')
                                .collect { it.trim() }
                                .collect { it.startsWith('@') ? it : "@${it}" }
                                .join(' or ')
                        // --cucumber-cmd is single-quoted and rake re-splits TAGS through a shell,
                        // so the value carries its own quotes rather than nesting single ones.
                        tags_list = "export TAGS=\"\\\"${transformed_scopes}\\\"\"; "
                    }
                    // A failing sub-stage marks itself and the build FAILURE but the next one still runs,
                    // so a secondary failure no longer skips hub testing or the finalize step.
                    def runRake = { String task, boolean enabled, String tags = '' ->
                        if (enabled) {
                            // catchInterruptions: false so an abort or idle timeout still exits the stage
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE', catchInterruptions: false) {
                                withIdleTimeout { sh cucumberCmd(task, tags) }
                            }
                        } else if (isNewJenkins) {
                            Utils.markStageSkippedForConditional(STAGE_NAME)
                        }
                    }
                    // One short rake call per family (run_sets/secondary_{seq,par}_<family>.yml), in run order.
                    // Parallel families run concurrently: each parallel_cucumber uses the Capybara ports
                    // 8888+offset+N (N < 6), so every family gets its own CAPYBARA_PORT_OFFSET.
                    def sequentialFamilies = ['server', 'clients', 'onboarding', 'salt', 'actions', 'proxy',
                                              'misc', 'cobbler', 'shared_state', 'diskcheck']
                    def parallelFamilies = ['server', 'clients']
                    stage('Secondary - Sequential') {
                        sequentialFamilies.each { family ->
                            stage("Sequential - ${family}") {
                                runRake("cucumber:secondary_seq_${family}", runSecondary, tags_list)
                            }
                        }
                    }
                    stage('Secondary - Parallel') {
                        def branches = [:]
                        for (int i = 0; i < parallelFamilies.size(); i++) {
                            def family = parallelFamilies[i]
                            def portOffset = i * 10
                            branches["Parallel - ${family}"] = {
                                stage("Parallel - ${family}") {
                                    // The offset travels in the rake prefix: the command runs on the controller.
                                    runRake("${params.rake_namespace ?: 'cucumber'}:secondary_par_${family}", runSecondary,
                                            "export CAPYBARA_PORT_OFFSET=${portOffset}; ${tags_list}")
                                }
                            }
                        }
                        parallel branches
                    }
                    stage('Hub Testing') {
                        runRake('cucumber:hub_server_to_server', runHub)
                    }
                    stage('Secondary - Finalize') {
                        runRake("cucumber:secondary_finishing", runSecondary, tags_list)
                    }
                }
            }
            finally {
                stage('Save TF state') {
                    safe.run('save-tfstate') { archiveArtifacts artifacts: "results/sumaform/terraform.tfstate, results/sumaform/.terraform/**/*", allowEmptyArchive: true }
                }

                stage('Get results') {
                    def result_error = 0
                    try {
                        if (deployed || !params.must_deploy) {
                            // safe.run keeps an abort from escaping the finally block (ABORTED is recorded)
                            if (!safe.run('finishing') { sh cucumberCmd('cucumber:finishing') }) { result_error = 1 }
                            if (!safe.run('generate_test_report') { sh cucumberCmd('utils:generate_test_report') }) { result_error = 1 }
                            safe.run('getresults') { sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep getresults" }
                            safe.run('publishHTML') {
                                publishHTML(target: [
                                        allowMissing         : true,
                                        alwaysLinkToLastBuild: false,
                                        keepAll              : true,
                                        reportDir            : "${resultdirbuild}/results/cucumber_report/",
                                        reportFiles          : 'index.html',
                                        reportName           : "TestSuite Report"]
                                )
                            }
                            catchError(buildResult: 'FAILURE', stageResult: 'SUCCESS') {
                                junit allowEmptyResults: true,
                                        testResults: "${junit_resultdir}/*.xml",
                                        skipPublishingChecks: true
                            }
                        }
                        // Send email. The mail step reads the variable defaults of the BV variables file
                        // ("Set in TFVARS"), so the subject and URL are passed as TF_VAR_* overrides.
                        if (!safe.run('mail') {
                            withEnv([
                                    "TF_VAR_MAIL_SUBJECT=CI ${product_version} #${BUILD_NUMBER}",
                                    "TF_VAR_MAIL_SUBJECT_ENV_FAIL=CI ${product_version} #${BUILD_NUMBER}: environment failed",
                                    // the mail templates append /<BUILD_NUMBER>, so the job URL must not end with a slash
                                    "TF_VAR_URL_PREFIX=${env.JOB_URL.replaceAll('/+$', '')}"]) {
                                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/mail.log --runstep mail"
                            }
                        }) { result_error = 1 }

                        if (rrtg_version) {
                            safe.run('rrtg-ingest') {
                                withCreds {
                                    sh """
                                  #!/bin/bash
                                  ${credInit}
                                  set +x  # credInit re-enables tracing, which would print RRTG_USER:RRTG_PASS below
                                  curl -sf -k -X POST \\
                                    "https://su-agent.qe-hub.mgr.suse.de/api/rrtg/ingest/${rrtg_version}?build=${env.BUILD_NUMBER}" \\
                                    -u "\${RRTG_USER}:\${RRTG_PASS}" \\
                                    -H "Content-Type: application/json" \\
                                  || echo "RRTG ingest failed (non-fatal)"
                                """
                                }
                            }
                        }
                        sh "exit ${result_error}"
                    } finally {
                        // Clean up old results — in finally so it runs even when getresults/mail fail
                        safe.run('clean-old-results') { sh "./clean-old-results -r ${resultdir}" }
                    }
                }
            }
        }
    }
}

return this
