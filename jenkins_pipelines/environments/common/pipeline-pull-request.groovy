def run(params) {
    timestamps {
        // Start pipeline with default values
        arch= 'x86_64'
        built = false
        deployed = false
        tests_passed = false
        sumaform_backend = 'libvirt'
        terraform_bin = '/usr/bin/terraform'
        terraform_bin_plugins = '/usr/bin'
        service_pack_migration = false
        terracumber_gitrepo = 'https://github.com/uyuni-project/terracumber.git'
        terracumber_ref = 'master'
        terraform_init = true
        rake_namespace = 'cucumber'
        rake_parallel_namespace = 'parallel'
        jenkins_workspace = '/home/jenkins/jenkins-build/workspace/'
        pull_request_repo = 'https://github.com/uyuni-project/uyuni.git'
        builder_api = 'https://api.opensuse.org'
        builder_project = 'systemsmanagement:Uyuni:Master:PR'
        source_project = 'systemsmanagement:Uyuni:Master'
        sumaform_tools_project = 'systemsmanagement:sumaform:tools'
        test_packages_project = 'systemsmanagement:Uyuni:Test-Packages:Pool'
        build_repo = 'openSUSE_Leap_15.4'
        environment_workspace = null
        url_prefix="https://ci.suse.de/view/Manager/view/Uyuni/job/${env.JOB_NAME}"
        try {
            stage('Get environment') {
                  echo "DEBUG: first environment: ${first_env}"
                  echo "DEBUG: last environment: ${last_env}"
                  env.suma_pr_lockfile = "/tmp/suma-pr${pull_request_number}"
                  if(params.force_pr_lock_cleanup) {
                    sh "rm -rf ${env.suma_pr_lockfile}"
                  }
                  if(params.remove_previous_environment) {
                    if(email_to!='' && pull_request_number!='') {
                        sh "bash jenkins_pipelines/scripts/cleanup-lock.sh -u ${email_to} -p ${pull_request_number}"
                    }
                  }
                  running_same_pr = sh(script: "lockfile -001 -r1 -! ${env.suma_pr_lockfile} 2>/dev/null && echo 'yes' || echo 'no'", returnStdout: true).trim()
                  if(running_same_pr == "yes") {
                      error("Aborting the build. Already running a test for Pull Request ${pull_request_number}")
                  }
                  if(pull_request_number == '') {
                      error('Aborting the build. Pull Request number can\'t be empty')
                  }

                  fqdn_jenkins_node = sh(script: "hostname -f", returnStdout: true).trim()
                  echo "DEBUG: fqdn_jenkins_node: ${fqdn_jenkins_node}"
                  // Pick a free environment
                  for (env_number = first_env; env_number <= last_env; env_number++) {
                      env.env_file="/tmp/env-suma-pr-${env_number}.lock"
                      env_status = sh(script: "lockfile -001 -r1 -! ${env_file} 2>/dev/null && echo 'locked' || echo 'free' ", returnStdout: true).trim()
                      if(env_status == 'free'){
                          echo "Using environment suma-pr${env_number}"
                          environment_workspace = "${jenkins_workspace}suma-pr${env_number}"
                          sh "echo user:${email_to} >> ${env_file}.info"
                          sh "echo PR:${pull_request_number} >> ${env_file}.info"
                          sh "echo started:\$(date) >> ${env_file}.info"
                          break;
                      }
                      if(env_number == last_env){
                          error('Aborting the build. All our environments are busy.')
                      }
                  }

            }
            stage('Checkout project') {
                ws(environment_workspace){
                    if(must_build) {
                        // Make sure files are owned by jenkins user.
                        // We need to do it with a container because it was built within a docker container and some files would be owned by root if the built was canceled.
                        sh "docker run --rm -v ${WORKSPACE}:/manager registry.opensuse.org/systemsmanagement/uyuni/master/docker/containers/uyuni-push-to-obs chown -R 1000 /manager/product || true"
                    }
                    sh 'rm -rf product'
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
                        if (pull_request_number == "master") {
                            checkout([
                                    $class: 'GitSCM',
                                    branches: [[name: "master"]],
                                    extensions: [[$class: 'CloneOption', depth: 1, timeout: 30, shallow: true, noTags: true, honorRefspec: true]],
                                    userRemoteConfigs: [[refspec: '+refs/heads/master:refs/remotes/origin/master', url: "${pull_request_repo}"]],
                                   ])
                        } else {
                            checkout([
                                    $class: 'GitSCM',
                                    branches: [[name: "pr/${pull_request_number}"]], 
                                    extensions: [[$class: 'CloneOption', depth: 1, timeout: 30, shallow: true, noTags: true, honorRefspec: true]],
                                    userRemoteConfigs: [[refspec: '+refs/pull/*/head:refs/remotes/origin/pr/*', url: "${pull_request_repo}"]],
                                   ])
                        }
                    }
                    
                }
            }
            stage('Build product') {
                ws(environment_workspace){
                    currentBuild.description =  "${builder_project}:${pull_request_number}<br>${email_to}<br>environment: ${env_number}<br>"
                    if (params.run_all_scopes) {
                        currentBuild.description = "${currentBuild.description} Run all scopes<br>"
                    } else {
                        currentBuild.description = "${currentBuild.description}${params.functional_scopes}<br>"
                    }
                    currentBuild.description = "${currentBuild.description}<b>Server</b>:<a href=\"https://suma-pr${env_number}-srv.mgr.prv.suse.net\">suma-pr${env_number}-srv.mgr.prv.suse.net</a>"
                    dir("product") {
                        if(must_build) {
                            sh "[ -L /home/jenkins/jenkins-build/workspace/suma-pr${env_number}/repos ] || ln -s /storage/jenkins/repos/${env_number}/ /home/jenkins/jenkins-build/workspace/suma-pr${env_number}/repos"
                           if(!params.skip_package_build_check) {

                              // fail if packages are not building correctly
                              sh "osc pr -r ${build_repo} -a ${arch} ${source_project} -s 'F' | awk '{print}END{exit NR>1}'"
                              // fail if packages are unresolvable
                              sh "osc pr -r ${build_repo} -a ${arch} ${source_project} -s 'U' | awk '{print}END{exit NR>1}'"
                            }
                            // force remove, to clean up previous build
                            sh "osc unlock ${builder_project}:${pull_request_number} -m 'unlock to remove' 2> /dev/null|| true"

                            sh "python3 ${WORKSPACE}/product/susemanager-utils/testing/automation/obs-project.py --prproject ${builder_project} --configfile $HOME/.oscrc remove --noninteractive ${pull_request_number} || true"

                            sh "osc rdelete -rf -m 'removing project before creating it again' ${builder_project}:${pull_request_number} || true"
                            sh "python3 susemanager-utils/testing/automation/obs-project.py --prproject ${builder_project} --configfile $HOME/.oscrc add --repo ${build_repo} ${pull_request_number} --disablepublish --setmaintainer zypp-team"
                            // Autocleanup in 3 days from obs
                            sh "osc dr --accept-in-hours=\$(( 24 * 7 )) --all -m 'Autocleanup' ${builder_project}:${pull_request_number}"                          
                            sh "osc linkpac ${source_project} release-notes-uyuni ${builder_project}:${pull_request_number}"
                            sh "bash susemanager-utils/testing/automation/push-to-obs.sh -t -d \"${builder_api}|${source_project}\" -n \"${builder_project}:${pull_request_number}\" -c $HOME/.oscrc -e"
                            echo "Checking ${builder_project}:${pull_request_number}"
                            sh "bash susemanager-utils/testing/automation/wait-for-builds.sh -u -a ${builder_api} -c $HOME/.oscrc -p ${builder_project}:${pull_request_number}"
                            // fail if packages are not building correctly
                            sh "osc pr ${builder_project}:${pull_request_number} -s 'F' | awk '{print}END{exit NR>1}'"
                            // fail if packages are unresolvable
                            sh "osc pr ${builder_project}:${pull_request_number} -s 'U' | awk '{print}END{exit NR>1}'"
                            built = true
                        } // params.must_buid
                        sh "[ -L ${environment_workspace}/repos ] || ln -s /storage/jenkins/repos/${env_number}/ ${environment_workspace}/repos"

                        echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${builder_project}:${pull_request_number}/${build_repo}/${arch}"
                        // Clean up previous errors
                        sh "bash -c \"rm -rf ${environment_workspace}/repos/publish_logs\""
                        sh "bash -c \"mkdir ${environment_workspace}/repos/publish_logs\""
                        // We clean up the previous repo because the pull request repo gets recreated each time, so we have no control on the build numbers.
                        sh "bash -c \"rm -rf ${environment_workspace}/repos/${builder_project}:${pull_request_number}/${build_repo}/${arch}\""
                        sh "bash susemanager-utils/testing/automation/publish-rpms.sh -p \"${builder_project}:${pull_request_number}\" -r ${build_repo} -a ${arch} -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${builder_project}_${pull_request_number} 2>&1 || touch ${environment_workspace}/repos/publish_logs/${builder_project}_${pull_request_number}.error"
                        echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${source_project}/${build_repo}/${arch}"
                        // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                        sh "bash susemanager-utils/testing/automation/publish-rpms.sh -p \"${source_project}\" -r ${build_repo} -a ${arch} -d \"${environment_workspace}/repos\" -q 000product:Uyuni-Server-release -q 000product:Uyuni-Proxy-release > ${environment_workspace}/repos/publish_logs/${source_project} 2>&1 || touch ${environment_workspace}/repos/publish_logs/${source_project}.error"
                        
                        echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${source_project}:Other/${build_repo}/${arch}"
                        // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                        sh "bash susemanager-utils/testing/automation/publish-rpms.sh -p \"${source_project}:Other\" -r ${build_repo} -a ${arch} -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${source_project}_Other 2>&1 || touch ${environment_workspace}/repos/publish_logs/${source_project}_Other.error"
                        
                        echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${sumaform_tools_project}/${build_repo}/x86_64"
                        // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                        sh "bash susemanager-utils/testing/automation/publish-rpms.sh -p \"${sumaform_tools_project}\" -r ${build_repo} -a x86_64 -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${sumaform_tools_project} 2>&1 || touch ${environment_workspace}/repos/publish_logs/${sumaform_tools_project}.error"

                        echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${test_packages_project}/rpm"
                        // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                        sh "bash susemanager-utils/testing/automation/publish-rpms.sh -p \"${test_packages_project}\" -r rpm -a x86_64 -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${test_packages_project} 2>&1 || touch ${environment_workspace}/repos/publish_logs/${test_packages_project}.error"

                        echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${source_project}:CentOS7-Uyuni-Client-Tools/CentOS_7/x86_64"
                        // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                        sh "bash susemanager-utils/testing/automation/publish-rpms.sh -p \"${source_project}:CentOS7-Uyuni-Client-Tools\" -r CentOS_7 -a ${arch} -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${source_project}_CentOS7-Uyuni-Client-Tools 2>&1 || touch ${environment_workspace}/repos/publish_logs/${source_project}_CentOS7-Uyuni-Client-Tools.error"

                        echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${source_project}:SLE15-Uyuni-Client-Tools/SLE_15/${arch}"
                        // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                        sh "bash susemanager-utils/testing/automation/publish-rpms.sh -p \"${source_project}:SLE15-Uyuni-Client-Tools\" -r SLE_15 -a ${arch} -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${source_project}_SLE15-Uyuni-Client-Tools 2>&1 || touch ${environment_workspace}/repos/publish_logs/${source_project}_SLE15-Uyuni-Client-Tools.error"

                        echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${source_project}:openSUSE_Leap_15-Uyuni-Client-Tools/openSUSE_Leap_15.0/${arch}"
                        // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                        sh "bash susemanager-utils/testing/automation/publish-rpms.sh -p \"${source_project}:openSUSE_Leap_15-Uyuni-Client-Tools\" -r openSUSE_Leap_15.0 -a ${arch} -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${source_project}_openSUSE_Leap_15-Uyuni-Client-Tools 2>&1 || touch ${environment_workspace}/repos/publish_logs/${source_project}_openSUSE_Leap_15-Uyuni-Client-Tools.error"

                        echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${source_project}:Ubuntu2004-Uyuni-Client-Tools/xUbuntu_20.04/${arch}"
                        // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                        // Clean up previous Packages.gz
                        sh "rm -f ${environment_workspace}/repos/systemsmanagement:Uyuni:Master:Ubuntu2004-Uyuni-Client-Tools/xUbuntu_20.04/${arch}/Packages.gz"
                        sh "bash susemanager-utils/testing/automation/publish-rpms.sh -p \"${source_project}:Ubuntu2004-Uyuni-Client-Tools\" -r xUbuntu_20.04 -a ${arch} -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${source_project}_Ubuntu2004-Uyuni-Client-Tools 2>&1 || touch ${environment_workspace}/repos/publish_logs/${source_project}_Ubuntu2004-Uyuni-Client-Tools.error"

                        echo "Wait for all publishers to finish...This could take a while ..."
                        sh "bash -c \"while ( ps -C publish-rpms.sh > /dev/null 2>/dev/null );do sleep 1; done\" "

                        echo "DEBUG"
                        sh "pwd"
                        sh "ls"
                        echo "Check for publishing failures"
                        sh "bash -c \"if ls ${environment_workspace}/repos/publish_logs/*.error 1>/dev/null 2>&1;then echo 'There was an error publishing';cat ${environment_workspace}/repos/publish_logs/*;exit -1;fi \""
                    }
                }
            }
            stage('Checkout CI tools') {
                ws(environment_workspace){
                    if(must_test) {
                        git url: terracumber_gitrepo, branch: terracumber_ref
                        dir("susemanager-ci") {
                            checkout scm
                        }

                        // Define test environment parameters
                        env.resultdir = "${WORKSPACE}/results"
                        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
                        env.tf_file = "susemanager-ci/terracumber_config/tf_files/Uyuni-PR-tests-env${env_number}.tf" //TODO: Make it possible to use environments for SUMA
                        env.common_params = "--outputdir ${resultdir} --tf ${tf_file} --gitfolder ${resultdir}/sumaform"

                        // Clean up old results
                        sh "if [ -d ${resultdir} ];then ./clean-old-results -r ${resultdir};fi"

                        // Create a directory for  to place the directory with the build results (if it does not exist)
                        sh "mkdir -p ${resultdir}"

                        // Clone sumaform
                        sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${common_params} --gitrepo ${sumaform_gitrepo} --gitref ${sumaform_ref} --runstep gitsync"
                    }
                }
            }
            stage('Deploy') {
                ws(environment_workspace){
                    if(must_test) {
                        // Passing the built repository by parameter using a environment variable to terraform file
                        // TODO: We will need to add a logic to replace the host, when we use IBS for spacewalk
                        env.PULL_REQUEST_REPO= "http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${builder_project}:${pull_request_number}/${build_repo}/${arch}"
                        env.MASTER_REPO = "http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${source_project}/${build_repo}/${arch}"
                        env.MASTER_OTHER_REPO = "http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${source_project}:Other/${build_repo}/${arch}"
                        env.MASTER_SUMAFORM_TOOLS_REPO = "http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${sumaform_tools_project}/${build_repo}/${arch}"
                        env.TEST_PACKAGES_REPO = "http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${test_packages_project}/rpm/${arch}"
                        env.UPDATE_REPO = "http://minima-mirror.mgr.prv.suse.net/jordi/some-updates/"
                        if (additional_repo_url == '') {
                            echo "Adding dummy repo for update repo"
                            env.ADDITIONAL_REPO_URL = "http://minima-mirror.mgr.prv.suse.net/jordi/dummy/"
                        } else {
                            echo "Adding ${additional_repo_url}"
                            env.ADDITIONAL_REPO_URL = additional_repo_url
                        }
                        env.SLE_CLIENT_REPO = "http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${source_project}:SLE15-Uyuni-Client-Tools/SLE_15/${arch}"
                        env.CENTOS_CLIENT_REPO = "http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${source_project}:CentOS7-Uyuni-Client-Tools/CentOS_7/${arch}"
                        env.UBUNTU_CLIENT_REPO = "http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${source_project}:Ubuntu2004-Uyuni-Client-Tools/xUbuntu_20.04/${arch}"
                        env.OPENSUSE_CLIENT_REPO = "http://${fqdn_jenkins_node}/workspace/suma-pr${env_number}/repos/${source_project}:openSUSE_Leap_15-Uyuni-Client-Tools/openSUSE_Leap_15.0/${arch}"

                        // Provision the environment
                        if (terraform_init) {
                            env.TERRAFORM_INIT = '--init'
                        } else {
                            env.TERRAFORM_INIT = ''
                        }
                        sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_SLE_CLIENT_REPO=${SLE_CLIENT_REPO};export TF_VAR_CENTOS_CLIENT_REPO=${CENTOS_CLIENT_REPO};export TF_VAR_UBUNTU_CLIENT_REPO=${UBUNTU_CLIENT_REPO};export TF_VAR_OPENSUSE_CLIENT_REPO=${OPENSUSE_CLIENT_REPO};export TF_VAR_PULL_REQUEST_REPO=${PULL_REQUEST_REPO}; export TF_VAR_MASTER_OTHER_REPO=${MASTER_OTHER_REPO};export TF_VAR_MASTER_SUMAFORM_TOOLS_REPO=${MASTER_SUMAFORM_TOOLS_REPO}; export TF_VAR_TEST_PACKAGES_REPO=${TEST_PACKAGES_REPO}; export TF_VAR_MASTER_REPO=${MASTER_REPO};export TF_VAR_UPDATE_REPO=${UPDATE_REPO};export TF_VAR_ADDITIONAL_REPO_URL=${ADDITIONAL_REPO_URL};export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${terraform_bin}; export TERRAFORM_PLUGINS=${terraform_bin_plugins}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision"
                        deployed = true
                    }
                }
            }
            stage('Sanity Check') {
                ws(environment_workspace){
                    if(must_test) {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:sanity_check'"
                    }
                }
            }
            stage('Core - Setup') {
                ws(environment_workspace){
                    if(must_test) {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:core'"
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:reposync'"
                    }
                }
            }
            stage('Core - Initialize clients') {
                ws(environment_workspace){
                    if(must_test) {
                        namespace = rake_namespace
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake ${namespace}:init_clients'"
                    }
                }
            }
            stage('Secondary features') {
                ws(environment_workspace){
                    if(must_test && ( params.functional_scopes || params.run_all_scopes) ) {
                        def exports = ""
                        if (params.functional_scopes){
                          exports += "export TAGS=\"${params.functional_scopes}\"; "
                        }
                        def statusCode1 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${exports} cd /root/spacewalk/testsuite; rake cucumber:secondary'", returnStatus:true
                        def statusCode2 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${exports} cd /root/spacewalk/testsuite; rake ${rake_namespace}:secondary_parallelizable'", returnStatus:true
                        sh "exit \$(( ${statusCode1}|${statusCode2} ))"
                    }
                }
            tests_passed = true
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
                            if (tests_passed || !deployed){
                                println("Unlock environment")
                                sh "rm -f ${env_file}*"
                            } else {
                                println("Keep the environment locked for 24 hours so you can debug")
                                sh "echo \"rm -f ${env_file}*\" | at now +24 hour"
                                sh "echo keep:24h >> ${env_file}.info"
                                sh "python3 ${WORKSPACE}/product/susemanager-utils/testing/automation/run-command-in-server.py --command=\"chmod 755 /tmp/set_custom_header.sh;/tmp/set_custom_header.sh -e ${env_number} -m ${email_to} -t 24\" --username=\"root\" --password=\"linux\" -v -i suma-pr${env_number}-srv.mgr.prv.suse.net"
                            }
                        }
                    }
                }
            }
            stage('Get test results') {
                if(environment_workspace){
                    ws(environment_workspace){
                        def error = 0
                        if(must_test) {
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
                                            reportName: "TestSuite Report for Pull Request ${builder_project}:${pull_request_number}"]
                                )
                                junit allowEmptyResults: true, testResults: "results/${BUILD_NUMBER}/results_junit/*.xml"
                            }
                            if (fileExists("results/${BUILD_NUMBER}")) {
                                archiveArtifacts artifacts: "results/${BUILD_NUMBER}/**/*"
                            }
                            if (email_to != '') {
                                sh " export TF_VAR_MAIL_TO=${email_to};export TF_VAR_URL_PREFIX=${url_prefix}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/mail.log --runstep mail"
                            }
                            // Clean up old results
                            sh "./clean-old-results -r ${resultdir}"
                            sh "exit ${error}"
                        }
                    }
                }
            }
            stage('Remove build project') {
                if(environment_workspace){
                  ws(environment_workspace){
                      sh "rm -rf ${environment_workspace}/repos/${builder_project}:${pull_request_number}/${build_repo}/${arch}"
                      sh "rm -rf ${builder_project}:${pull_request_number}" 
                  }
                }
            }
        }
    }
}

return this
