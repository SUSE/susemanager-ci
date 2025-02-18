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
        jenkins_workspace = '/home/jenkins/workspace'
        environment_workspace = null
        env.common_params = ''
        tfvariables_file  = 'susemanager-ci/terracumber_config/tf_files/variables/PR-testing-variables.tf'
        tfvars_product_version = "susemanager-ci/terracumber_config/tf_files/tfvars/PR-testing-${product_version}.tfvars"
        tfvars_platform_localisation = "susemanager-ci/terracumber_config/tf_files/tfvars/PR-testing-${platform_localisation}-environments.tfvars"
        tf_local_variables = 'susemanager-ci/terracumber_config/tf_files/tfvars/PR-testing-additionnal-repos.tf'
        try {
            stage('Get environment') {
                  checkout scm
                  echo "DEBUG: first environment: ${first_env}"
                  echo "DEBUG: last environment: ${last_env}"
                  env.suma_pr_lockfile = "/tmp/${short_product_name}-pr${pull_request_number}"
                  if(params.force_pr_lock_cleanup) {
                    sh "rm -rf ${env.suma_pr_lockfile}"
                  }
                  if(params.remove_previous_environment) {
                    if(email_to!='' && pull_request_number!='') {
                        sh "bash ${WORKSPACE}/jenkins_pipelines/scripts/cleanup-lock.sh -u ${email_to} -p ${pull_request_number} -x ${short_product_name}"
                    }
                  }
                  env.running_same_pr = sh(script: "lockfile -001 -r1 -! ${env.suma_pr_lockfile} 2>/dev/null && echo 'yes' || echo 'no'", returnStdout: true).trim()
                  if(env.running_same_pr == "yes") {
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
                          environment_workspace = "${jenkins_workspace}/${short_product_name}-pr${env_number}"
                          sh "echo user:${email_to} >> ${env_file}.info"
                          sh "echo PR:${pull_request_number} >> ${env_file}.info"
                          sh "echo started:\$(date) >> ${env_file}.info"
                          sh "echo product:${short_product_name} >> ${env_file}.info"
                          break;
                      }
                      if(env_number == last_env){
                          error('Aborting the build. All our environments are busy.')
                      }
                  }

            }
            stage('Checkout project') {
                ws(environment_workspace){
                    if(params.must_build) {
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
                        if (pull_request_number == "master" || pull_request_number == "Manager-4.3") {
                            checkout([
                                    $class: 'GitSCM',
                                    branches: [[name: "${pull_request_number}"]],
                                    extensions: [[$class: 'CloneOption', depth: 1, timeout: 30, shallow: true, noTags: true, honorRefspec: true]],
                                    userRemoteConfigs: [[refspec: "+refs/heads/${pull_request_number}:refs/remotes/origin/${pull_request_number}", url: "${pull_request_repo}"]],
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
                    if (build_packages) {
                      currentBuild.description =  "${builder_project}:${pull_request_number}<br>${email_to}<br>environment: ${env_number}<br>"
                      if (run_all_scopes) {
                          currentBuild.description = "${currentBuild.description} Run all scopes<br>"
                      } else {
                          currentBuild.description = "${currentBuild.description}${params.functional_scopes}<br>"
                      }
                      currentBuild.description = "${currentBuild.description}<b>Server</b>:<a href=\"https://suma-pr${env_number}-server.mgr.prv.suse.net\">suma-pr${env_number}-server.mgr.prv.suse.net</a>"
                      dir("product") {
                          if(must_build) {
                              sh "[ -L ${environment_workspace}/repos ] || ln -s /storage/jenkins/repos/${product_name}/${env_number}/ ${environment_workspace}/repos"
                             if(!params.skip_package_build_check) {

                                // fail if packages are not building correctly
                                echo "Checking packages build successfully in ${build_url}/project/show/${source_project}"
                                echo "If packages fail to build, check the url above for more details"
                                sh "osc -A ${builder_api} pr -r ${build_repo} -a ${arch} ${source_project} -s 'F' | awk '{print}END{exit NR>1}'"
                                // fail if packages are unresolvable
                                sh "osc -A ${builder_api} pr -r ${build_repo} -a ${arch} ${source_project} -s 'U' | awk '{print}END{exit NR>1}'"
                              }
                              // force remove, to clean up previous build
                              sh "osc -A ${builder_api} unlock ${builder_project}:${pull_request_number} -m 'unlock to remove' 2> /dev/null|| true"

                              sh "python3 ${WORKSPACE}/product/susemanager-utils/testing/automation/obs-project.py --api ${builder_api} --prproject ${builder_project} --configfile $HOME/.oscrc remove --noninteractive ${pull_request_number} || true"

                              sh "osc -A ${builder_api} rdelete -rf -m 'removing project before creating it again' ${builder_project}:${pull_request_number} || true"
                              sh "python3 susemanager-utils/testing/automation/obs-project.py --api ${builder_api} --prproject ${builder_project} --configfile $HOME/.oscrc add --project ${source_project} --repo ${build_repo} ${pull_request_number} --disablepublish --setmaintainer zypp-team"
                              // Autocleanup in 3 days from obs
                              sh "osc -A ${builder_api} dr --accept-in-hours=\$(( 24 * 7 )) --all -m 'Autocleanup' ${builder_project}:${pull_request_number}"                          
                              sh "osc -A ${builder_api} linkpac ${rn_project} ${rn_package} ${builder_project}:${pull_request_number}"
                              sh "bash susemanager-utils/testing/automation/push-to-obs.sh -t -d \"${builder_api}|${source_project}\" -n \"${builder_project}:${pull_request_number}\" -c $HOME/.oscrc -e -s $HOME/.ssh/id_rsa"
                              echo "Checking ${builder_project}:${pull_request_number}"
                              sh "bash susemanager-utils/testing/automation/wait-for-builds.sh -u -a ${builder_api} -c $HOME/.oscrc -p ${builder_project}:${pull_request_number}"
                              // fail if packages are not building correctly
                              echo "Checking packages build successfully in ${build_url}/project/show/${builder_project}:${pull_request_number}"
                              echo "If packages fail to build, check the url above for more details"
                              sh "osc -A ${builder_api} pr ${builder_project}:${pull_request_number} -s 'F' | awk '{print}END{exit NR>1}'"
                              // fail if packages are unresolvable
                              sh "osc -A ${builder_api} pr ${builder_project}:${pull_request_number} -s 'U' | awk '{print}END{exit NR>1}'"
                              built = true
                          } // params.must_buid
                          sh "[ -L ${environment_workspace}/repos ] || ln -s /storage/jenkins/repos/${product_name}/${env_number}/ ${environment_workspace}/repos"

                          echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${builder_project}:${pull_request_number}/${build_repo}/${arch}"
                          // Clean up previous errors
                          sh "bash -c \"rm -rf ${environment_workspace}/repos/publish_logs\""
                          sh "bash -c \"mkdir ${environment_workspace}/repos/publish_logs\""
                          // We clean up the previous repo because the pull request repo gets recreated each time, so we have no control on the build numbers.
                          sh "bash -c \"rm -rf ${environment_workspace}/repos/${builder_project}:${pull_request_number}/${build_repo}/${arch}\""
                          sh "bash susemanager-utils/testing/automation/publish-rpms.sh -A ${builder_api} -p \"${builder_project}:${pull_request_number}\" -r ${build_repo} -a ${arch} -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${builder_project}_${pull_request_number} 2>&1 || touch ${environment_workspace}/repos/publish_logs/${builder_project}_${pull_request_number}.error"
                          echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${source_project}/${build_repo}/${arch}"
                          // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                          sh "bash susemanager-utils/testing/automation/publish-rpms.sh -A ${builder_api} -p \"${source_project}\" -r ${build_repo} -a ${arch} -d \"${environment_workspace}/repos\" -q ${server_release_package} -q ${proxy_release_package} > ${environment_workspace}/repos/publish_logs/${source_project} 2>&1 || touch ${environment_workspace}/repos/publish_logs/${source_project}.error"
                          
                          echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${other_project}/${other_build_repo}/${arch}"
                          // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                          sh "bash susemanager-utils/testing/automation/publish-rpms.sh -A ${builder_api} -p \"${other_project}\" -r ${other_build_repo} -a ${arch} -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${source_project}_Other 2>&1 || touch ${environment_workspace}/repos/publish_logs/${source_project}_Other.error"
                          
                          echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${sumaform_tools_project}/${build_repo}/x86_64"
                          // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                          sh "bash susemanager-utils/testing/automation/publish-rpms.sh -A ${builder_api} -p \"${sumaform_tools_project}\" -r ${build_repo} -a x86_64 -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${sumaform_tools_project} 2>&1 || touch ${environment_workspace}/repos/publish_logs/${sumaform_tools_project}.error"

                          echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${test_packages_project}/rpm"
                          // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                          sh "bash susemanager-utils/testing/automation/publish-rpms.sh -A ${builder_api} -p \"${test_packages_project}\" -r rpm -a x86_64 -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${test_packages_project} 2>&1 || touch ${environment_workspace}/repos/publish_logs/${test_packages_project}.error"

                          echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${el_client_repo}/${EL}/x86_64"
                          // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                          sh "bash susemanager-utils/testing/automation/publish-rpms.sh -A ${builder_api} -p \"${el_client_repo}\" -r ${EL} -a ${arch} -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${el_client_repo} 2>&1 || touch ${environment_workspace}/repos/publish_logs/${el_client_repo}.error"

                          echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${sles_client_repo}/SLE_15/${arch}"
                          // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                          sh "bash susemanager-utils/testing/automation/publish-rpms.sh -A ${builder_api} -p \"${sles_client_repo}\" -r SLE_15 -a ${arch} -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${sles_client_repo} 2>&1 || touch ${environment_workspace}/repos/publish_logs/${sles_client_repo}.error"

                          echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${openSUSE_client_repo}/openSUSE_Leap_15.0/${arch}"
                          // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                          sh "bash susemanager-utils/testing/automation/publish-rpms.sh -A ${builder_api} -p \"${openSUSE_client_repo}\" -r openSUSE_Leap_15.0 -a ${arch} -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${openSUSE_client_repo} 2>&1 || touch ${environment_workspace}/repos/publish_logs/${openSUSE_client_repo}.error"

                          echo "Publishing packages into http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${ubuntu_client_repo}/xUbuntu_22.04/${arch}"
                          // We do not clean up the previous packages. This speeds up the checkout. We are assuming this project won't ever get deleted, so new builds should always have new release numbers.
                          // Clean up previous Packages.gz
                          sh "rm -f ${environment_workspace}/repos/${ubuntu_client_repo}/xUbuntu_22.04/${arch}/Packages.gz"
                          sh "bash susemanager-utils/testing/automation/publish-rpms.sh -A ${builder_api} -p \"${ubuntu_client_repo}\" -r xUbuntu_22.04 -a ${arch} -d \"${environment_workspace}/repos\" > ${environment_workspace}/repos/publish_logs/${ubuntu_client_repo} 2>&1 || touch ${environment_workspace}/repos/publish_logs/${ubuntu_client_repo}.error"

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
                        env.tf_file = "susemanager-ci/terracumber_config/tf_files/PR-testing-template.tf"
                        env.common_params = "--outputdir ${resultdir} --tf ${tf_file} --gitfolder ${resultdir}/sumaform --tf_variables_description_file=${tfvariables_file}"

                        if (params.terraform_parallelism) {
                            env.common_params = "${env.common_params} --parallelism ${params.terraform_parallelism}"
                        }

                        // Clean up old results
                        sh "if [ -d ${resultdir} ];then ./clean-old-results -r ${resultdir};fi"

                        // Create a directory for  to place the directory with the build results (if it does not exist)
                        sh "mkdir -p ${resultdir}"

                        // Clone sumaform
                        sh "set +x;set +e; source /home/jenkins/.credentials set -x; ./terracumber-cli ${common_params} --gitrepo ${sumaform_gitrepo} --gitref ${sumaform_ref} --runstep gitsync"
                        echo "DEBUG: end of clone ci"
                    }
                }
            }
            stage('Deploy') {
                echo "DEBUG: Deploy 1"
                ws(environment_workspace){
                    if(must_test) {
                        // Delete old terraform.tfvars
                        sh "rm -f ${env.resultdir}/sumaform/terraform.tfvars"
                        // Merge product en platform variables into terraform.tfvars
                        sh "cat ${tfvars_product_version} ${tfvars_platform_localisation} >> ${env.resultdir}/sumaform/terraform.tfvars"
                        // Add environment to use in tfvars
                        sh "echo 'ENVIRONMENT = \'${env_number}\'' >> ${env.resultdir}/sumaform/terraform.tfvars"
                        // Copy the variable declaration file
                        sh "cp ${tf_local_variables} ${env.resultdir}/sumaform/"

                        // Add all repositories variables
                        // Passing the built repository by parameter using a environment variable to terraform file
                        // TODO: We will need to add a logic to replace the host, when we use IBS for spacewalk
                        sh "echo \"############ Repositories variables ############\" >> ${env.resultdir}/sumaform/terraform.tfvars"
                        sh "echo PULL_REQUEST_REPO = \\\"http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${builder_project}:${pull_request_number}/${build_repo}/${arch}\\\" >> ${env.resultdir}/sumaform/terraform.tfvars"
                        sh "echo MASTER_REPO = \\\"http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${source_project}/${build_repo}/${arch}\\\" >> ${env.resultdir}/sumaform/terraform.tfvars"
                        sh "echo MASTER_OTHER_REPO = \\\"http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${other_project}/${other_build_repo}/${arch}\\\" >> ${env.resultdir}/sumaform/terraform.tfvars"
                        sh "echo MASTER_SUMAFORM_TOOLS_REPO = \\\"http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${sumaform_tools_project}/${build_repo}/${arch}\\\" >> ${env.resultdir}/sumaform/terraform.tfvars"
                        sh "echo TEST_PACKAGES_REPO = \\\"http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${test_packages_project}/rpm/${arch}\\\" >> ${env.resultdir}/sumaform/terraform.tfvars"
                        sh "echo UPDATE_REPO = \\\"${update_repo}\\\" >> ${env.resultdir}/sumaform/terraform.tfvars"

                        if (additional_repo_url == '') {
                            echo "Adding dummy repo for update repo"
                            sh "echo ADDITIONAL_REPO_URL = \\\"${additional_repo}\\\" >> ${env.resultdir}/sumaform/terraform.tfvars"
                        } else {
                            echo "Adding ${additional_repo_url}"
                            sh "echo ADDITIONAL_REPO_URL = \\\"${additional_repo_url}\\\" >> ${env.resultdir}/sumaform/terraform.tfvars"
                        }

                        sh "echo SLE_CLIENT_REPO = \\\"http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${sles_client_repo}/SLE_15/${arch}\\\" >> ${env.resultdir}/sumaform/terraform.tfvars"
                        sh "echo RHLIKE_CLIENT_REPO = \\\"http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${el_client_repo}/${EL}/${arch}\\\" >> ${env.resultdir}/sumaform/terraform.tfvars"
                        sh "echo DEBLIKE_CLIENT_REPO = \\\"http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${ubuntu_client_repo}/xUbuntu_22.04/${arch}\\\" >> ${env.resultdir}/sumaform/terraform.tfvars"
                        sh "echo OPENSUSE_CLIENT_REPO = \\\"http://${fqdn_jenkins_node}/workspace/${short_product_name}-pr${env_number}/repos/${openSUSE_client_repo}/openSUSE_Leap_15.0/${arch}\\\" >> ${env.resultdir}/sumaform/terraform.tfvars"

                        // Provision the environment
                        if (terraform_init) {
                            env.TERRAFORM_INIT = '--init'
                        } else {
                            env.TERRAFORM_INIT = ''
                        }
                        sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${cucumber_ref}; export TERRAFORM=${terraform_bin}; export TERRAFORM_PLUGINS=${terraform_bin_plugins}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} --taint '.*(domain|main_disk|data_disk|database_disk|standalone_provisioning).*' --runstep provision"
                        deployed = true
  
                        // Collect and tag Flaky tests from the GitHub Board
                        def statusCode = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; export BUILD_NUMBER=${BUILD_NUMBER}; rake utils:collect_and_tag_flaky_tests'", returnStatus:true
                        sh "exit 0"
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
            stage('Core - Proxy') {
                ws(environment_workspace){
                    if(must_test) {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake ${namespace}:proxy'"
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
                    if(must_test && ( params.functional_scopes || run_all_scopes) ) {
                        def statusCode1 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${secondary_exports} cd /root/spacewalk/testsuite; rake cucumber:secondary'", returnStatus:true
                        def statusCode2 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${secondary_exports} cd /root/spacewalk/testsuite; rake ${rake_namespace}:secondary_parallelizable'", returnStatus:true
                        sh "exit \$(( ${statusCode1}|${statusCode2} ))"
                    }
                }
            tests_passed = true
            }
        }
        finally {
            stage('Clean up lockfiles') {
                if(env.running_same_pr == "no"){
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
                                if (short_product_name.contains("43")) {
                                    sh "python3 ${WORKSPACE}/product/susemanager-utils/testing/automation/run-command-in-server.py --command=\"chmod 755 /tmp/set_custom_header.sh;/tmp/set_custom_header.sh -e ${env_number} -m ${email_to} -t 24\" --username=\"root\" --password=\"linux\" -v -i suma-pr${env_number}-server.mgr.prv.suse.net"
                                }else{
                                    sh "python3 ${WORKSPACE}/product/susemanager-utils/testing/automation/run-command-in-server.py --command=\"mgrctl cp /tmp/set_custom_header.sh server:/tmp/ ; mgrctl exec 'chmod 755 /tmp/set_custom_header.sh;/tmp/set_custom_header.sh -e ${env_number} -m ${email_to} -t 24\" --username=\"root\" --password=\"linux\" -v -i suma-pr${env_number}-server.mgr.prv.suse.net'"
                                }
                            }
                        }
                    }
                }
            }
            stage('Get test results') {
                if(environment_workspace && common_params != ''){
                    ws(environment_workspace){
                        def error = 0
                        if(must_test) {
                            if (deployed) {
                                try {
                                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:finishing'"
                                } catch(Exception ex) {
                                    println("ERROR: rake cucumber:finishing failed")
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
                                sh " export TF_VAR_MAIL_TO=${email_to};export TF_VAR_URL_PREFIX=${url_prefix}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/mail.log --tf_variables_product_file ${tfvars_product_version} --runstep mail"
                            }
                            // Clean up old results
                            sh "./clean-old-results -r ${resultdir} -s 10"
                            sh "exit ${error}"
                        }
                    }
                }
            }
            stage('Remove build project') {
                if(environment_workspace){
                    if (tests_passed){
                        ws(environment_workspace){
                            sh "rm -rf ${environment_workspace}/repos/${builder_project}:${pull_request_number}/${build_repo}/${arch}"
                            sh "rm -rf ${builder_project}:${pull_request_number}" 
                         }
                    }
                }
            }
        }
    }
}

return this
