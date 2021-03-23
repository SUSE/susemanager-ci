def run(params) {
    timestamps {
        node {
            currentBuild.description =  "${params.builder_project}:${params.pull_request_number}"
        }
        // Start pipeline
        built = false
        deployed = false
        try {
            node('manager-jenkins-node') {
                stage('Build product') {
                    if(params.must_build) {
                        dir("product") {
                            //TODO: When checking out spacewalk, we will need credentials in the Jenkins Slave
                            //      Inside userRemoteConfigs add credentialsId: 'github'
                            checkout([  
                                        $class: 'GitSCM', 
                                        branches: [[name: "pr/${params.pull_request_number}"]], 
                                        userRemoteConfigs: [[refspec: '+refs/pull/*/head:refs/remotes/origin/pr/*', url: "${params.pull_request_repo}"]]
                                    ])
                            sh "python3 susemanager-utils/testing/automation/obs-project.py --prproject ${params.builder_project} --configfile $HOME/.oscrc add ${params.pull_request_number}"
                            sh "bash susemanager-utils/testing/automation/push-to-obs.sh -v -t -d \"${params.builder_api}|${params.builder_project}:${params.pull_request_number}\" -c $HOME/.oscrc"
                            def list = sh(returnStdout: true, script: "osc -A ${params.builder_api} -c $HOME/.oscrc ls ${params.builder_project}:${params.pull_request_number}").trim()
                            for (i in list) {
                               println "Checking ${params.builder_project}:${params.pull_request_number} > $i"
                               sh "osc -A ${params.builder_api} -c $HOME/.oscrc results ${params.builder_project}:${params.pull_request_number} $i -w"
                            }
                            built = true
                        }
                    }
                }
            }
            node('sumaform-cucumber'){
                stage('Checkout CI tools') {

                    // Create a directory for  to place the directory with the build results (if it does not exist)
                    sh "mkdir -p ${resultdir}"
                    git url: params.terracumber_gitrepo, branch: params.terracumber_ref
                    dir("susemanager-ci") {
                        checkout scm
                    }

                    // Pick a free environment
                    for (env_number = 1; env_number <= 6; env_number++) {
                        env.env_file="/tmp/suma-pr${env_number}.lock"
                        env_status = sh(script: "test -f ${env_file} && echo 'locked' || echo 'free' ", returnStdout: true).trim()
                        if(env_status == 'free'){
                            echo "Using environment suma-pr${env_number}"
                            sh "touch ${env_file}"
                            break;
                        } 
                        if(env_number == 6){
                            error('Aborting the build. All our environments are busy.')
                        } 
                    }

                    // Define test environment parameters
                    env.resultdir = "${WORKSPACE}/results"
                    env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
                    env.tf_file = "susemanager-ci/terracumber_config/tf_files/Uyuni-PR-tests-env${env_number}.tf" //TODO: Make it possible to use environments for SUMA
                    env.common_params = "--outputdir ${resultdir} --tf ${tf_file} --gitfolder ${resultdir}/sumaform"

                    // Clone sumaform
                    sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync"
                }
                stage('Deploy') {
                    // Provision the environment
                    if (params.terraform_init) {
                        env.TERRAFORM_INIT = '--init'
                    } else {
                        env.TERRAFORM_INIT = ''
                    }
                    sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision"
                    deployed = true
                }
                stage('Sanity Check') {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:sanity_check'"
                }
                stage('Core - Setup') {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export LONG_TESTS=${params.long_tests}; cd /root/spacewalk/testsuite; rake cucumber:core'"
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export LONG_TESTS=${params.long_tests}; export SERVICE_PACK_MIGRATION=${params.service_pack_migration}; cd /root/spacewalk/testsuite; rake cucumber:reposync'"
                }
                stage('Core - Initialize clients') {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export LONG_TESTS=${params.long_tests}; export SERVICE_PACK_MIGRATION=${params.service_pack_migration}; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:init_clients'"
                }
                stage('Secondary features') {
                    def statusCode1 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export LONG_TESTS=${params.long_tests}; export PROFILE=${params.functional_scope}; cd /root/spacewalk/testsuite; rake cucumber:secondary'", returnStatus:true
                    def statusCode2 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export LONG_TESTS=${params.long_tests}; export PROFILE=${params.functional_scope}; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:secondary_parallelizable'", returnStatus:true
                    sh "exit \$(( ${statusCode1}|${statusCode2} ))"
                }
            }
        }
        finally {
            stage('Get results') {
                def error = 0
                if (built  || !params.must_build) {
                    sh "python3 susemanager-utils/testing/automation/obs-project.py --prproject ${params.builder_project} --configfile $HOME/.oscrc remove --noninteractive ${params.pull_request_number}"
                }
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
                                reportName: "TestSuite Report for Pull Request ${params.builder_project}:${params.pull_request_number}"]
                    )
                    junit allowEmptyResults: true, testResults: "results/${BUILD_NUMBER}/results_junit/*.xml"
                }
                // Send email
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/mail.log --runstep mail"
                // Clean up old results
                sh "./clean-old-results -r ${resultdir}"
                sh "exit ${error}"
            }
        }
    }
}

return this
