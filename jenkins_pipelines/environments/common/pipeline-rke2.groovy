def run(params) {
    ansiColor('xterm') {
        timestamps {
            // Init path env variables
            env.resultdir = "${WORKSPACE}/results"
            env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"

            // The junit plugin doesn't affect full paths
            env.common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${resultdir}/sumaform --terraform-bin ${params.bin_path}"
            env.exports = "export BUILD_NUMBER=${BUILD_NUMBER}; export CAPYBARA_TIMEOUT=${capybara_timeout}; export DEFAULT_TIMEOUT=${default_timeout}; export CUCUMBER_PUBLISH_QUIET=true;"

            if (params.deploy_parallelism) {
                env.common_params = "${env.common_params} --parallelism ${params.deploy_parallelism}"
            }

            def previous_commit = null
            def product_commit = null
            def mirror_scope = env.JOB_BASE_NAME.split('-acceptance-tests')[0]
            mirror_scope = mirror_scope.replaceAll("-dev", "")
            // Inactivity timeout: kills a cucumber run that has stopped producing output entirely.
            def cucumber_idle_timeout = (params.cucumber_idle_timeout ?: 60).toString().toInteger()
            def withIdleTimeout = { Closure body ->
                timeout(activity: true, time: cucumber_idle_timeout, unit: 'MINUTES') { body() }
            }
            // Start pipeline
            deployed = false
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

                    // run minima sync on mirror
                    if (mirror_scope != null) {
                        sh "ssh root@minima-mirror-ci-bv.`hostname -d` -t \"test -x /usr/local/bin/minima-${mirror_scope}.sh && /usr/local/bin/minima-${mirror_scope}.sh || echo 'no mirror script for this scope'\""
                    }
                }
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
                            default:
                                println("ERROR: Unknown backend ${params.sumaform_backend}");
                                sh "exit 1";
                                break;
                        }
                    }
                    sh "set +x; source /home/jenkins/.credentials set -x; set -o pipefail; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.bin_path}; export TERRAFORM_PLUGINS=${params.bin_plugins_path}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} ${env.TERRAFORM_TAINT} --sumaform-backend ${params.sumaform_backend} --runstep provision | sed -E 's/([^.]+)module\\.([^.]+)\\.module\\.([^.]+)(\\.module\\.[^.]+)?(\\[[0-9]+\\])?(\\.module\\.[^.]+)?(\\.[^.]+)?(.*)/\\1\\2.\\3\\8/'"
                    deployed = true
                    // Collect and tag Flaky tests from the GitHub Board
                    def statusCode = sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${env.exports} rake utils:collect_and_tag_flaky_tests'", returnStatus: true
                }
                stage('Sanity Check') {
                    withIdleTimeout {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${env.exports} rake cucumber:sanity_check'"
                    }
                }
                stage('Kubernetes sanity checks') {
                    withIdleTimeout {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:kubernetes_sanity_checks'"
                    }
                }
                stage('Kubernetes tests') {
                    withIdleTimeout {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:kubernetes_tests'"
                    }
                }
                stage('Core - Setup') {
                    if (runCore) {
                        withIdleTimeout {
                            sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:core'"
                            sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:reposync'"
                        }
                    }
                }
                stage('Core - Proxy') {
                    if (runCore) {
                        withIdleTimeout {
                            sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake cucumber:proxy'"
                        }
                    }
                }
                stage('Core - Initialize clients') {
                    if (runCore) {
                        withIdleTimeout {
                            sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${exports} rake parallel:init_clients'"
                        }
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
                            // --cucumber-cmd below is single-quoted, and rake re-splits TAGS through a
                            // shell, so the value carries its own quotes rather than nesting single ones.
                            tags_list = "export TAGS=\"\\\"${transformed_scopes}\\\"\"; "
                        }

                        def statusCode1 = 1
                        def statusCode2 = 1
                        def statusCode3 = 1
                        withIdleTimeout { statusCode1 = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${tags_list}cd /root/spacewalk/testsuite; ${exports} rake cucumber:secondary'", returnStatus: true) }
                        withIdleTimeout { statusCode2 = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${tags_list}cd /root/spacewalk/testsuite; ${exports} rake ${params.rake_namespace}:secondary_parallelizable'", returnStatus: true) }
                        withIdleTimeout { statusCode3 = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${tags_list}cd /root/spacewalk/testsuite; ${exports} rake ${params.rake_namespace}:secondary_finishing'", returnStatus: true) }
                        sh "exit \$(( ${statusCode1}|${statusCode2}|${statusCode3} ))"
                    }
                }
            }
            finally {
                stage('Save TF state') {
                    archiveArtifacts artifacts: "results/sumaform/terraform.tfstate, results/sumaform/.terraform/**/*"
                }
            }
        }
    }
}

return this
