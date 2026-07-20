def run(params) {
    timestamps {
        // Null-safe defaults for optional stage-control parameters (backward compat with env files that don't declare them)
        def runDeploy    = params.deploy    == null ? true : params.deploy
        def runCore      = params.core      == null ? true : params.core
        def runSecondary = params.secondary == null ? true : params.secondary

        // Init path env variables
        GString resultdir = "${env.WORKSPACE}/results"
        GString resultdirbuild = "${resultdir}/${env.BUILD_NUMBER}"

        // The junit plugin doesn't affect full paths
        GString junit_resultdir = "results/${env.BUILD_NUMBER}/results_junit"
        // Mutable: the AWS backend appends PUBLISH_CUCUMBER_REPORT below
        def exports = "export BUILD_NUMBER=${env.BUILD_NUMBER}; export CAPYBARA_TIMEOUT=${capybara_timeout}; export DEFAULT_TIMEOUT=${default_timeout}; export CUCUMBER_PUBLISH_QUIET=true;"
        GString common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${resultdir}/sumaform --terraform-bin ${params.bin_path}"


        if (params.deploy_parallelism) {
            common_params = "${common_params} --parallelism ${params.deploy_parallelism}"
        }
        // Bastion support (from pipeline.groovy)
        if (params.bastion_ssh_key_file) {
            common_params = "${common_params} --bastion_ssh_key ${params.bastion_ssh_key_file} --bastion_user ${params.bastion_username}"
            if (params.bastion_hostname) {
                common_params = "${common_params} --bastion_hostname ${params.bastion_hostname}"
            }
        }

        def previous_commit = null
        def product_commit = null
        // CI-job detection: acceptance-tests jobs get mirror sync, flaky-test labels,
        // RRTG ingest and OBS/IBS product-commit tracking. Personal jobs skip them.
        def isAcceptanceJob = env.JOB_BASE_NAME.contains('-acceptance-tests')
        def mirror_scope = isAcceptanceJob ? env.JOB_BASE_NAME.split('-acceptance-tests')[0].replaceAll("-dev", "") : null
        def ci_label_map = [
                '4.3' : '4.3_ci',
                '5.0' : '5.0_ci',
                '5.1' : '5.1_ci',
                'Head': 'head_ci',
                'uyuni': 'uyuni_podman_ci'
        ]
        def ci_label = isAcceptanceJob ? (ci_label_map.find { k, v -> env.JOB_BASE_NAME.contains(k) }?.value ?: '') : ''
        def rrtg_version = isAcceptanceJob ? env.JOB_BASE_NAME.find(/4\.3|5\.0|5\.1|Head/)?.toLowerCase() : null
        if (!rrtg_version && env.JOB_BASE_NAME == 'uyuni-master-dev-acceptance-tests-podman') {
            rrtg_version = 'uyuni'
        }
        if (params.show_product_changes && isAcceptanceJob) {
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
            product_commit = product_commit.substring(product_commit.indexOf('[') + 1, product_commit.indexOf(']'));
            print "Current product commit: ${product_commit}"
            previous_commit = currentBuild.getPreviousBuild()?.description
            if (previous_commit == null) {
                previous_commit = product_commit
            } else {
                previous_commit = previous_commit.substring(previous_commit.indexOf('[') + 1, previous_commit.indexOf(']'));
            }
            print "Previous product commit: ${previous_commit}"
        }
        // Start pipeline
        def deployed = false
        def isNewJenkins = env.JENKINS_URL?.contains('jenkins.mgr.suse.de')
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
        try {
            withCreds {
                stage('Clone terracumber, susemanager-ci and sumaform') {
                    if (params.show_product_changes) {
                        // Rename build using product commit hash (fall back to tf_file for personal jobs)
                        currentBuild.description = product_commit ? "[${product_commit}]" : "[${params.tf_file}]"
                    }
                    // Create a directory for  to place the directory with the build results (if it does not exist)
                    sh "mkdir -p ${resultdir}"
                    git url: params.terracumber_gitrepo, branch: params.terracumber_ref
                    dir("susemanager-ci") {
                        checkout scm
                    }
                    // Always sync sumaform — the deploy stage needs the checkout regardless
                    sh """
                        #!/bin/bash
                        ${credInit}
                        ./terracumber-cli ${common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync
                    """
                    // Restore Terraform states from artifacts
                    if (params.use_previous_terraform_state && currentBuild.previousBuild != null) {
                        copyArtifacts projectName: currentBuild.projectName, selector: specific("${currentBuild.previousBuild.number}")
                    }

                    // run minima sync on mirror
                    if (mirror_scope != null) {
                        def domain = sh(script: "grep -oP 'domain\\s*=\\s*\"\\K[^\"]+' ${params.tf_file}", returnStdout: true).trim()
                        sh "ssh root@minima-mirror-ci-bv.${domain} -t \"test -x /usr/local/bin/minima-${mirror_scope}.sh && /usr/local/bin/minima-${mirror_scope}.sh || echo 'no mirror script for this scope'\""
                    }
                }
                if (runDeploy) {
                    stage('Deploy') {
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
                                    exports = "${exports} export PUBLISH_CUCUMBER_REPORT=true;";
                                    break;
                                default:
                                    println("ERROR: Unknown backend ${params.sumaform_backend}");
                                    sh "exit 1";
                                    break;
                            }
                        }
                        if (isNewJenkins) {
                            sh """
                                sed -i '/HYPERVISOR_PRIVATE_SSH_KEY_PATH/d' ${resultdir}/sumaform/terraform.tfvars 2>/dev/null || true
                                sed -i '/CONTROLLER_PUBLIC_SSH_KEY_PATH/d' ${resultdir}/sumaform/terraform.tfvars 2>/dev/null || true
                                echo 'HYPERVISOR_PRIVATE_SSH_KEY_PATH="/home/jenkins/.ssh/id_ed25519.worker"' >> ${resultdir}/sumaform/terraform.tfvars
                                echo 'CONTROLLER_PUBLIC_SSH_KEY_PATH="/home/jenkins/.ssh/id_ed25519.pub.controller"' >> ${resultdir}/sumaform/terraform.tfvars
                            """
                        }
                        sh """
                            #!/bin/bash
                            ${credInit}
                            set -o pipefail
                            export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}
                            export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}
                            export TERRAFORM=${params.bin_path}
                            export TERRAFORM_PLUGINS=${params.bin_plugins_path}
                            ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} ${env.TERRAFORM_TAINT} --sumaform-backend ${params.sumaform_backend} --runstep provision | sed -E 's/([^.]+)module\\.([^.]+)\\.module\\.([^.]+)(\\.module\\.[^.]+)?(\\[[0-9]+\\])?(\\.module\\.[^.]+)?(\\.[^.]+)?(.*)/\\1\\2.\\3\\8/'
                        """
                        deployed = true
                        // Collect and tag Flaky tests from the GitHub Board
                        def rakeTarget = ci_label ? "utils:collect_and_tag_flaky_tests[${ci_label}]" : "utils:collect_and_tag_flaky_tests"
                        def statusCode = sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake ${rakeTarget}'", returnStatus: true
                    }
                } else {
                    deployed = true
                }
                stage('Product changes') {
                    if (params.show_product_changes) {
                        sh """
                        # Comparison between:
                        #  - the previous git revision of spacewalk (or uyuni) repository pushed in IBS (or OBS)
                        #  - the git revision of the current spacewalk (or uyuni) repository pushed in IBS (or OBS)
                        # Note: This is a trade-off, we should be comparing the git revisions of all the packages composing our product
                        #       For that extra mile, we need a new tag in the repo metadata of each built, with the git revision of the related repository.
                    """
                        sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/; git --no-pager log --pretty=format:\\\"%h %<(16,trunc)%cn  %s  %d\\\" ${previous_commit}..${product_commit}'", returnStatus: true
                    } else {
                        println("Product changes disabled, checkbox 'show_product_changes' was not enabled'")
                    }
                }
                stage('Sanity Check') {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:sanity_check'"
                }
                stage('Core - Setup') {
                    if (runCore) {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:core'"
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:reposync'"
                    }
                }
                stage('Core - Proxy') {
                    if (runCore) {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:proxy'"
                    }
                }
                stage('Core - Initialize clients') {
                    if (runCore) {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake parallel:init_clients'"
                    }
                }
                stage('Secondary features') {
                    if (runSecondary) {
                        def tags_list = ""
                        if (params.functional_scopes) {
                            // Re-add the @ prefix stripped from the job parameters
                            // (Jenkins' Safe HTML markup formatter escapes @ as &#64; in Active Choices labels).
                            // startsWith guard keeps backward compatibility with jobs still passing @-prefixed scopes.
                            def transformed_scopes = params.functional_scopes.split(',')
                                    .collect { it.trim() }
                                    .collect { it.startsWith('@') ? it : "@${it}" }
                                    .join(' or ')
                            tags_list = "export TAGS='${transformed_scopes}'; "
                        }

                        def cucumberCmd1 = "${tags_list}cd /root/spacewalk/testsuite; ${exports} rake cucumber:secondary"
                        def cucumberCmd2 = "${tags_list}cd /root/spacewalk/testsuite; ${exports} rake ${params.rake_namespace}:secondary_parallelizable"
                        def cucumberCmd3 = "${tags_list}cd /root/spacewalk/testsuite; ${exports} rake ${params.rake_namespace}:secondary_finishing"

                        def encoded1 = cucumberCmd1.toString().bytes.encodeBase64().toString()
                        def encoded2 = cucumberCmd2.toString().bytes.encodeBase64().toString()
                        def encoded3 = cucumberCmd3.toString().bytes.encodeBase64().toString()

                        def statusCode1 = sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'echo ${encoded1} | base64 -d | bash'", returnStatus: true
                        def statusCode2 = sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'echo ${encoded2} | base64 -d | bash'", returnStatus: true
                        def statusCode3 = sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'echo ${encoded3} | base64 -d | bash'", returnStatus: true
                        sh "exit \$(( ${statusCode1}|${statusCode2}|${statusCode3} ))"
                    }
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
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:finishing'"
                    } catch(err) {
                        println("ERROR: rake cucumber:finishing failed: ${err}")
                        error = 1
                    }
                    try {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake utils:generate_test_report'"
                    } catch(err) {
                        println("ERROR: rake utils:generate_test_repor failed: ${err}")
                        error = 1
                    }
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep getresults"
                    // In the case of an AWS environment, we want to export the reports to a publicly accessible web server.
                    if (params.sumaform_backend == "aws") {
                        try {
                            sh """
                              ./terracumber-cli ${common_params} \\
                                --logfile ${resultdirbuild}/webserver.log \\
                                --runstep cucumber \\
                                --cucumber-cmd 'mkdir -p /mnt/www/${env.BUILD_NUMBER} && \\
                                                rsync -avz --no-owner --no-group  /root/spacewalk/testsuite/results/${env.BUILD_NUMBER}/ /mnt/www/${env.BUILD_NUMBER}/ && \\
                                                rsync -av --no-owner --no-group  /root/spacewalk/testsuite/spacewalk-debug.tar.bz2 /mnt/www/${env.BUILD_NUMBER}/ && \\
                                                rsync -av --no-owner --no-group  /root/spacewalk/testsuite/logs/ /mnt/www/${env.BUILD_NUMBER}/ && \\
                                                rsync -avz --no-owner --no-group  /root/spacewalk/testsuite/results/${env.BUILD_NUMBER}/results/cucumber_report/ /mnt/www/${env.BUILD_NUMBER}/'
                            """
                        } catch(err) {
                            println("ERROR: Exporting reports to external AWS Web Server: ${err}")
                            error = 1
                        }
                    }
                    publishHTML( target: [
                            allowMissing: true,
                            alwaysLinkToLastBuild: false,
                            keepAll: true,
                            reportDir: "${resultdirbuild}/results/cucumber_report/",
                            reportFiles: 'index.html',
                            reportName: "TestSuite Report"]
                    )
                    // skipPublishingChecks: Checks API not configured on this instance
                    catchError(buildResult: 'FAILURE', stageResult: 'SUCCESS') {
                        junit allowEmptyResults: true,
                                testResults: "${junit_resultdir}/*.xml",
                                skipPublishingChecks: true
                    }
                    // Test Report Summary
                    try {
                        sh "python3 -m venv ${env.WORKSPACE}/venv"
                        def SCRIPT_DIR = "${env.WORKSPACE}/susemanager-ci/jenkins_pipelines/scripts/test_review_summary"
                        def testSummary = sh(script: "${env.WORKSPACE}/venv/bin/python ${SCRIPT_DIR}/test_review_summary.py ${resultdirbuild}/cucumber_report/cucumber_report.html.json", returnStdout: true).trim()
                        echo testSummary
                    } catch(err) {
                        println("WARNING: test review summary failed (non-fatal): ${err}")
                    }
                }
                // Send email
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/mail.log --runstep mail"

                if (rrtg_version) {
                    withCreds {
                        sh """
                          #!/bin/bash
                          ${credInit}
                          curl -sf -k -X POST \\
                            "https://su-agent.qe-hub.mgr.suse.de/api/rrtg/ingest/${rrtg_version}?build=${env.BUILD_NUMBER}" \\
                            -u "\${RRTG_USER}:\${RRTG_PASS}" \\
                            -H "Content-Type: application/json" \\
                          || echo "RRTG ingest failed (non-fatal)"
                        """
                    }
                }

                // Clean up old results
                sh "./clean-old-results -r ${resultdir}"
                sh "exit ${error}"
            }
        }
    }
}

return this
