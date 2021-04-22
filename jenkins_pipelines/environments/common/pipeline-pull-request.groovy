def run(params) {
    timestamps {
        // Start pipeline with default values
        built = false
        deployed = false
        sumaform_gitrepo = 'https://github.com/uyuni-project/sumaform.git'
        sumaform_ref = 'master'
        sumaform_backend = 'libvirt'
        terraform_bin = '/usr/bin/terraform_bin'
        terraform_bin_plugins = '/usr/bin'
        long_tests = true
        service_pack_migration = false
        terracumber_gitrepo = 'https://gitlab.suse.de/juliogonzalezgil/terracumber.git'
        terracumber_ref = 'master'
        terraform_init = true
        rake_namespace = 'cucumber'
        try {
            stage('Build product') {
                currentBuild.description =  "${params.builder_project}:${params.pull_request_number}<br>[${params.functional_scopes}]"
                if(params.must_build) {
                    dir("product") {
                        //TODO: When checking out spacewalk, we will need credentials in the Jenkins Slave
                        //      Inside userRemoteConfigs add credentialsId: 'github'
                        checkout([  
                                    $class: 'GitSCM', 
                                    branches: [[name: "pr/${params.pull_request_number}"]], 
                                    extensions: [[$class: 'CloneOption', depth: 1, shallow: true]],
                                    userRemoteConfigs: [[refspec: '+refs/pull/*/head:refs/remotes/origin/pr/*', url: "${params.pull_request_repo}"]]
                                ])
                        sh "python3 susemanager-utils/testing/automation/obs-project.py --prproject ${params.builder_project} --configfile $HOME/.oscrc add --repo ${params.build_repo} ${params.pull_request_number}"
                        sh "bash susemanager-utils/testing/automation/push-to-obs.sh -v -t -d \"${params.builder_api}|${params.source_project}\" -n \"${params.builder_api}|${params.builder_project}:${params.pull_request_number}\" -c $HOME/.oscrc"
                        echo "Checking ${params.builder_project}:${params.pull_request_number}"
                        sh "bash susemanager-utils/testing/automation/wait-for-builds.sh -a ${params.builder_api} -c $HOME/.oscrc -p ${params.builder_project}:${params.pull_request_number}"
                        built = true
                    }
                }
            }
            stage('Checkout CI tools') {
                if(params.must_test) {
                    git url: terracumber_gitrepo, branch: terracumber_ref
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

                    // Create a directory for  to place the directory with the build results (if it does not exist)
                    sh "mkdir -p ${resultdir}"

                    // Clone sumaform
                    sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${common_params} --gitrepo ${sumaform_gitrepo} --gitref ${sumaform_ref} --runstep gitsync"
                }
            }
            stage('Deploy') {
                if(params.must_test) {
                    // Passing the built repository by parameter using a environment variable to terraform file
                    // TODO: We will need to add a logic to replace the host, when we use IBS for spacewalk
                    env.PULL_REQUEST_REPO = "http://download.opensuse.org/repositories/${params.builder_project}:${params.pull_request_number}/openSUSE_Leap_15.2/"

                    // Provision the environment
                    if (terraform_init) {
                        env.TERRAFORM_INIT = '--init'
                    } else {
                        env.TERRAFORM_INIT = ''
                    }
                    sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_PULL_REQUEST_REPO=${PULL_REQUEST_REPO}; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${terraform_bin}; export TERRAFORM_PLUGINS=${terraform_bin_plugins}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision"
                    deployed = true
                }
            }
            stage('Sanity Check') {
                if(params.must_test) {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:sanity_check'"
                }
            }
            stage('Core - Setup') {
                if(params.must_test) {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export LONG_TESTS=${long_tests}; cd /root/spacewalk/testsuite; rake cucumber:core'"
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export LONG_TESTS=${long_tests}; export SERVICE_PACK_MIGRATION=${service_pack_migration}; cd /root/spacewalk/testsuite; rake cucumber:reposync'"
                }
            }
            stage('Core - Initialize clients') {
                if(params.must_test) {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export LONG_TESTS=${long_tests}; export SERVICE_PACK_MIGRATION=${service_pack_migration}; cd /root/spacewalk/testsuite; rake ${rake_namespace}:init_clients'"
                }
            }
            stage('Secondary features') {
                if(params.must_test) {
                    def statusCode1 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export LONG_TESTS=${long_tests}; export PROFILE=${params.functional_scopes}; cd /root/spacewalk/testsuite; rake cucumber:secondary'", returnStatus:true
                    def statusCode2 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export LONG_TESTS=${long_tests}; export PROFILE=${params.functional_scopes}; cd /root/spacewalk/testsuite; rake ${rake_namespace}:secondary_parallelizable'", returnStatus:true
                    sh "exit \$(( ${statusCode1}|${statusCode2} ))"
                }
            }
        }
        finally {
            stage('Remove build project') {
                if (params.must_remove_build) {
                    sh "osc unlock ${params.builder_project} -m 'unlock to remove'"
                    sh "python3 ${WORKSPACE}/product/susemanager-utils/testing/automation/obs-project.py --prproject ${params.builder_project} --configfile $HOME/.oscrc remove --noninteractive ${params.pull_request_number}"
                }
            }
            stage('Get test results') {
                def error = 0
                if (env.env_file) {
                    sh "rm ${env_file}"
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

return this
