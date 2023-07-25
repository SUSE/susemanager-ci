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
//        terracumber_gitrepo = 'https://github.com/uyuni-project/terracumber.git'
        terracumber_gitrepo = 'https://github.com/maximenoel8/terracumber.git'
        terracumber_ref = 'support_tfvars'
        terraform_init = true
        rake_namespace = 'cucumber'
        rake_parallel_namespace = 'parallel'
        jenkins_workspace = '/home/jenkins/jenkins-build/workspace/'
        pull_request_repo = 'https://github.com/uyuni-project/uyuni.git'
        builder_api = 'https://api.opensuse.org'
        build_url = 'https://build.opensuse.org'
        builder_project = 'systemsmanagement:Uyuni:Master:PR'
        source_project = 'systemsmanagement:Uyuni:Master'
        sumaform_tools_project = 'systemsmanagement:sumaform:tools'
        test_packages_project = 'systemsmanagement:Uyuni:Test-Packages:Pool'
        build_repo = 'openSUSE_Leap_15.4'
        environment_workspace = null
        url_prefix="https://ci.suse.de/view/Manager/view/Uyuni/job/${env.JOB_NAME}"
        env.common_params = ''
        fqdn_jenkins_node = sh(script: "hostname -f", returnStdout: true).trim()
        env_number = 2
        try {
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
                        env.tf_file = "susemanager-ci/terracumber_config/tf_files/PR-TEST-main.tf"
                        env.tfvariables_file  = "susemanager-ci/terracumber_config/tf_files/variables/PR-TEST-variable.tf"
                        env.tfvars_files = ["susemanager-ci/terracumber_config/tf_files/tfvars/PR-TEST-manager43.tfvars","susemanager-ci/terracumber_config/tf_files/tfvars/PR-TEST-NUE-ENVS.tfvars"]
                        env.common_params = "--outputdir ${resultdir} --tf ${tf_file} --gitfolder ${resultdir}/sumaform --tfvariables_file=${tfvariables_file} --tfvars_files=${tftfvars_files}"

                        if (params.terraform_parallelism) {
                            env.common_params = "${env.common_params} --parallelism ${params.terraform_parallelism}"
                        }

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
                        env.PULL_REQUEST_REPO= "http://download.suse.de/ibs/SUSE:/Maintenance:/29643/SUSE_Updates_SLE-Product-SLES_15-SP1-LTSS_x86_64/"
                        env.MASTER_REPO = "http://download.suse.de/ibs/SUSE:/Maintenance:/29643/SUSE_Updates_SLE-Product-SLES_15-SP1-LTSS_x86_64/"
                        env.MASTER_OTHER_REPO = "http://download.suse.de/ibs/SUSE:/Maintenance:/29643/SUSE_Updates_SLE-Product-SLES_15-SP1-LTSS_x86_64/"
                        env.MASTER_SUMAFORM_TOOLS_REPO = "http://download.suse.de/ibs/SUSE:/Maintenance:/29643/SUSE_Updates_SLE-Product-SLES_15-SP1-LTSS_x86_64/"
                        env.TEST_PACKAGES_REPO = "http://download.suse.de/ibs/SUSE:/Maintenance:/29643/SUSE_Updates_SLE-Product-SLES_15-SP1-LTSS_x86_64/"
                        env.UPDATE_REPO = "http://minima-mirror.mgr.prv.suse.net/jordi/some-updates/"
                        if (additional_repo_url == '') {
                            echo "Adding dummy repo for update repo"
                            env.ADDITIONAL_REPO_URL = "http://minima-mirror.mgr.prv.suse.net/jordi/dummy/"
                        } else {
                            echo "Adding ${additional_repo_url}"
                            env.ADDITIONAL_REPO_URL = additional_repo_url
                        }
                        env.SLE_CLIENT_REPO = "http://download.suse.de/ibs/SUSE:/Maintenance:/29643/SUSE_Updates_SLE-Product-SLES_15-SP1-LTSS_x86_64/"
                        env.RHLIKE_CLIENT_REPO = "http://download.suse.de/ibs/SUSE:/Maintenance:/29643/SUSE_Updates_SLE-Product-SLES_15-SP1-LTSS_x86_64/"
                        env.DEBLIKE_CLIENT_REPO = "http://download.suse.de/ibs/SUSE:/Maintenance:/29643/SUSE_Updates_SLE-Product-SLES_15-SP1-LTSS_x86_64/"
                        env.OPENSUSE_CLIENT_REPO = "http://download.suse.de/ibs/SUSE:/Maintenance:/29643/SUSE_Updates_SLE-Product-SLES_15-SP1-LTSS_x86_64/"

                        // Provision the environment
                        if (terraform_init) {
                            env.TERRAFORM_INIT = '--init'
                        } else {
                            env.TERRAFORM_INIT = ''
                        }
                        sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_ENVIRONMENT=${env_number}; export TF_VAR_SLE_CLIENT_REPO=${SLE_CLIENT_REPO};export TF_VAR_RHLIKE_CLIENT_REPO=${RHLIKE_CLIENT_REPO};export TF_VAR_DEBLIKE_CLIENT_REPO=${DEBLIKE_CLIENT_REPO};export TF_VAR_OPENSUSE_CLIENT_REPO=${OPENSUSE_CLIENT_REPO};export TF_VAR_PULL_REQUEST_REPO=${PULL_REQUEST_REPO}; export TF_VAR_MASTER_OTHER_REPO=${MASTER_OTHER_REPO};export TF_VAR_MASTER_SUMAFORM_TOOLS_REPO=${MASTER_SUMAFORM_TOOLS_REPO}; export TF_VAR_TEST_PACKAGES_REPO=${TEST_PACKAGES_REPO}; export TF_VAR_MASTER_REPO=${MASTER_REPO};export TF_VAR_UPDATE_REPO=${UPDATE_REPO};export TF_VAR_ADDITIONAL_REPO_URL=${ADDITIONAL_REPO_URL};export TF_VAR_CUCUMBER_GITREPO=${cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${cucumber_ref}; export TERRAFORM=${terraform_bin}; export TERRAFORM_PLUGINS=${terraform_bin_plugins}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision"
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
                if(environment_workspace && common_params != ''){
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
                            sh "./clean-old-results -r ${resultdir} -s 10"
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
