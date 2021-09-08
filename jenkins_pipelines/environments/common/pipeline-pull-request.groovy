def run(params) {
    timestamps {
        // Start pipeline with default values
        built = false
        deployed = false
        sumaform_backend = 'libvirt'
        terraform_bin = '/usr/bin/terraform_bin'
        terraform_bin_plugins = '/usr/bin'
        long_tests = true
        service_pack_migration = false
        terracumber_gitrepo = 'https://gitlab.suse.de/juliogonzalezgil/terracumber.git'
        terracumber_ref = 'master'
        terraform_init = true
        rake_namespace = 'cucumber'
        rake_parallel_namespace = 'parallel'
        total_envs = 6
        jenkins_workspace = '/home/jenkins/jenkins-build/workspace/'
        environment_workspace = null
        try {
            stage('Get environment') {
                  env.suma_pr_lockfile = "/tmp/suma-pr${params.pull_request_number}"
                  running_same_pr = sh(script: "lockfile -001 -r1 -! ${env.suma_pr_lockfile} 2>/dev/null && echo 'yes' || echo 'no'", returnStdout: true).trim()
                  if(running_same_pr == "yes") {
                      error('Aborting the build. Already running a test for Pull Request ${params.pull_request_number}')
                  }
                  if(params.pull_request_number == '') {
                      error('Aborting the build. Pull Request number can\'t be empty')
                  }

                  fqdn_jenkins_node = sh(script: "hostname -f", returnStdout: true).trim()
                  echo "DEBUG: fqdn_jenkins_node: ${fqdn_jenkins_node}"
                  // Pick a free environment
                  for (env_number = 1; env_number <= total_envs; env_number++) {
                      env.env_file="/tmp/env-suma-pr-${env_number}.lock"
                      env_status = sh(script: "lockfile -001 -r1 -! ${env_file} 2>/dev/null && echo 'locked' || echo 'free' ", returnStdout: true).trim()
                      if(env_status == 'free'){
                          echo "Using environment suma-pr${env_number}"
                          environment_workspace = "${jenkins_workspace}suma-pr${env_number}"
                          break;
                      }
                      if(env_number == total_envs){
                          error('Aborting the build. All our environments are busy.')
                      }
                  }

            }
            stage('Checkout project') {
                ws(environment_workspace){
                    if(params.must_build || params.must_remove_build) {
                        sh "rm -rf ${WORKSPACE}/product"
                        dir("product") {
                            // We need git_commiter_name, git_author_name and git_email to perform the merge with master branch
                            env.GIT_COMMITTER_NAME = "jenkins"
                            env.GIT_AUTHOR_NAME = "jenkins"
                            env.GIT_AUTHOR_EMAIL = "jenkins@a.b"
                            env.GIT_COMMITTER_EMAIL = "jenkins@a.b"
                            sh "git config --global user.email 'galaxy-noise@suse.de'"
                            sh "git config --global user.name 'jenkins'"
                            //TODO: When checking out spacewalk, we will need credentials in the Jenkins Slave
                            //      Inside userRemoteConfigs add credentialsId: 'github'
                            checkout([  
                                        $class: 'GitSCM', 
                                        branches: [[name: "pr/${params.pull_request_number}"]], 
                                        extensions: [[$class: 'CloneOption', depth: 1, shallow: true]],
                                        userRemoteConfigs: [[refspec: '+refs/pull/*/head:refs/remotes/origin/pr/*', url: "${params.pull_request_repo}"]],
                                        extensions: [
                                        [
                                            $class: 'PreBuildMerge',
                                            options: [
                                                 fastForwardMode: 'NO_FF',
                                                 mergeRemote: 'origin',
                                                 mergeTarget: 'master'
                                           ]
                                         ]]
                                       ])
                        }
                    }
                }
            }
            stage('Build product') {
                ws(environment_workspace){
                    currentBuild.description =  "${params.builder_project}:${params.pull_request_number}<br>${params.functional_scopes}"
                    if(params.must_build) {
                        dir("product") {
                            // fail if packages are not building correctly
                            sh "osc pr ${params.source_project}:TEST:${env_number}:CR -s 'F' | awk '{print}END{exit NR>1}'"
                            // fail if packages are unresolvable
                            sh "osc pr ${params.source_project}:TEST:${env_number}:CR -s 'U' | awk '{print}END{exit NR>1}'"
                            // force remove, to clean up previous build
                            sh "osc unlock ${params.builder_project}:${params.pull_request_number} -m 'unlock to remove' 2> /dev/null|| true"
                            sh "osc unlock ${params.source_project}:TEST:${env_number}:CR -m 'unlock to rebuild' 2> /dev/null || true "
                            sh "python3 ${WORKSPACE}/product/susemanager-utils/testing/automation/obs-project.py --prproject ${params.builder_project} --configfile $HOME/.oscrc remove --noninteractive ${params.pull_request_number} || true"
                            sh "osc lock ${params.source_project}:TEST:${env_number}:CR 2> /dev/null || true"
                            sh "osc rdelete -rf -m 'removing project before creating it again' ${params.builder_project}:${params.pull_request_number} || true"
                            sh "python3 susemanager-utils/testing/automation/obs-project.py --prproject ${params.builder_project} --configfile $HOME/.oscrc add --repo ${params.build_repo} ${params.pull_request_number} --disablepublish"
                            sh "osc linkpac ${params.source_project}:TEST:${env_number}:CR release-notes-uyuni ${params.builder_project}:${params.pull_request_number}"
                            sh "bash susemanager-utils/testing/automation/push-to-obs.sh -t -d \"${params.builder_api}|${params.source_project}:TEST:${env_number}:CR\" -n \"${params.builder_project}:${params.pull_request_number}\" -c $HOME/.oscrc -e -x"
                            echo "Checking ${params.builder_project}:${params.pull_request_number}"
                            sh "bash susemanager-utils/testing/automation/wait-for-builds.sh -u -a ${params.builder_api} -c $HOME/.oscrc -p ${params.builder_project}:${params.pull_request_number}"
                            echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/${params.builder_project}:${params.pull_request_number}/${params.build_repo}/x86_64"
                            sh "bash -c \"rm -rf ${jenkins_workspace}/${params.builder_project}:${params.pull_request_number}/${params.build_repo}/x86_64\""
                            sh "bash susemanager-utils/testing/automation/publish-rpms.sh -p \"${params.builder_project}:${params.pull_request_number}\" -r ${params.build_repo} -a x86_64 -d \"${jenkins_workspace}\""
                            // fail if packages are not building correctly
                            sh "osc pr ${params.builder_project}:${params.pull_request_number} -s 'F' | awk '{print}END{exit NR>1}'"
                            // fail if packages are unresolvable
                            sh "osc pr ${params.builder_project}:${params.pull_request_number} -s 'U' | awk '{print}END{exit NR>1}'"
                            built = true
                        }
                    }
                }
            }
            stage('Checkout CI tools') {
                ws(environment_workspace){
                    if(params.must_test) {
                        git url: terracumber_gitrepo, branch: terracumber_ref
                        dir("susemanager-ci") {
                            checkout scm
                        }

                        // Define test environment parameters
                        env.resultdir = "${WORKSPACE}/results"
                        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
                        env.tf_file = "susemanager-ci/terracumber_config/tf_files/Uyuni-PR-tests-env${env_number}.tf" //TODO: Make it possible to use environments for SUMA
                        env.common_params = "--outputdir ${resultdir} --tf ${tf_file} --gitfolder ${resultdir}/sumaform"

                        // Create a directory for  to place the directory with the build results (if it does not exist)
                        sh "mkdir -p ${resultdir}"

                        // Clone sumaform
                        sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${common_params} --gitrepo ${sumaform_gitrepo} --gitref ${sumaform_ref} --runstep gitsync"
                    }
                }
            }
            stage('Deploy') {
                ws(environment_workspace){
                    if(params.must_test) {
                        // Passing the built repository by parameter using a environment variable to terraform file
                        // TODO: We will need to add a logic to replace the host, when we use IBS for spacewalk
                        env.PULL_REQUEST_REPO= "http://${fqdn_jenkins_node}/workspace/${params.builder_project}:${params.pull_request_number}/${params.build_repo}/x86_64"
                        env.MASTER_REPO = "http://download.opensuse.org/repositories/${params.source_project}:TEST:${env_number}:CR/${params.build_repo}"
                        // Provision the environment
                        if (terraform_init) {
                            env.TERRAFORM_INIT = '--init'
                        } else {
                            env.TERRAFORM_INIT = ''
                        }
                        sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_PULL_REQUEST_REPO=${PULL_REQUEST_REPO}; export TF_VAR_MASTER_REPO=${MASTER_REPO};export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${terraform_bin}; export TERRAFORM_PLUGINS=${terraform_bin_plugins}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision"
                        deployed = true
                    }
                }
            }
            stage('Sanity Check') {
                ws(environment_workspace){
                    if(params.must_test) {
                        def exports = ""
                        if (long_tests){
                          exports += "export LONG_TESTS=${long_tests}; "
                        }
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:sanity_check'"
                    }
                }
            }
            stage('Core - Setup') {
                ws(environment_workspace){
                    if(params.must_test) {
                        def exports = "";
                        if (long_tests){
                          exports += "export LONG_TESTS=${long_tests}; "
                        }
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${exports} cd /root/spacewalk/testsuite; rake cucumber:core'"
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${exports} cd /root/spacewalk/testsuite; rake cucumber:reposync'"
                    }
                }
            }
            stage('Core - Initialize clients') {
                ws(environment_workspace){
                    if(params.must_test) {
                        def exports = ""
                        if (long_tests){
                          exports += "export LONG_TESTS=${long_tests}; "
                        }
                        namespace = rake_namespace
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${exports} cd /root/spacewalk/testsuite; rake ${namespace}:init_clients'"
                    }
                }
            }
            stage('Secondary features') {
                ws(environment_workspace){
                    if(params.must_test && !params.skip_secondary_tests) {
                        def exports = ""
                        if (params.functional_scopes){
                          exports += "export TAGS=${params.functional_scopes}; "
                        }
                        if (long_tests){
                          exports += "export LONG_TESTS=${long_tests}; "
                        }
                        def statusCode1 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${exports} cd /root/spacewalk/testsuite; rake cucumber:secondary'", returnStatus:true
                        def statusCode2 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${exports} cd /root/spacewalk/testsuite; rake ${rake_namespace}:secondary_parallelizable'", returnStatus:true
                        sh "exit \$(( ${statusCode1}|${statusCode2} ))"
                    }
                }
            }
        }
        finally {
            stage('Clean up lockfiles') {
                if(running_same_pr == "no"){
                      sh(script: "rm -f ${env.suma_pr_lockfile}")
                }
                if(environment_workspace){
                    ws(environment_workspace){
                        if (env.env_file) {
                            sh "rm -f ${env_file}"
                        }
                    }
                }
            }
            stage('Remove build project') {
                if(environment_workspace){
                  ws(environment_workspace){
                      if (params.must_remove_build) {
                          sh "osc unlock ${params.builder_project}:${params.pull_request_number} -m 'unlock to remove' 2> /dev/null|| true"
                          sh "osc unlock ${params.source_project}:TEST:${env_number}:CR -m 'unlock to rebuild' 2> /dev/null || true "
                          sh "python3 ${WORKSPACE}/product/susemanager-utils/testing/automation/obs-project.py --prproject ${params.builder_project} --configfile $HOME/.oscrc remove --noninteractive ${params.pull_request_number}"
                      }
                      sh "rm -rf ${WORKSPACE}/product"
                  }
                }
            }
            stage('Get test results') {
                if(environment_workspace){
                    ws(environment_workspace){
                        def error = 0
                        if (deployed) {
                            try {
                                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:finishing_pr'"
                            } catch(Exception ex) {
                                println("ERROR: rake cucumber:finishing_pr failed")
                                error = 1
                            }
                            try {
                                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake utils:generate_test_report'"
                            } catch(Exception ex) {
                                println("ERROR: rake utils:generate_test_repor failed")
                                error = 1
                            }
                            sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep getresults"
                            publishHTML( target: [
                                        allowMissing: true,
                                        alwaysLinkToLastBuild: false,
                                        keepAll: true,
                                        reportDir: "${resultdirbuild}/cucumber_report/",
                                        reportFiles: 'cucumber_report.html',
                                        reportName: "TestSuite Report for Pull Request ${params.builder_project}:${params.pull_request_number}"]
                            )
                            junit allowEmptyResults: true, testResults: "results/${BUILD_NUMBER}/results_junit/*.xml"
                            if (params.email_to != '') {
                                // Send email
                                // TODO: We must find a way to obtain the e-mail of the PR author and set it in TF_VAR_MAIL_TO
                                sh " export TF_VAR_MAIL_TO=${params.email_to}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/mail.log --runstep mail"
                            }
                            // Clean up old results
                            sh "./clean-old-results -r ${resultdir}"
                        }
                        sh "exit ${error}"
                    }
                }
            }
        }
    }
}

return this
