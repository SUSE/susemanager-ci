def run(params) {
    timestamps {
        deployed = false
        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        // The junit plugin doesn't affect full paths
        junit_resultdir = "results/${BUILD_NUMBER}/results_junit"

        env.common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${resultdir}/sumaform"

        if (params.terraform_parallelism) {
            env.common_params = "${env.common_params} --parallelism ${params.terraform_parallelism}"
        }
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
            }

            stage('Deploy') {
                if(params.must_deploy) {
                    // Provision the environment
                    if (params.terraform_init) {
                        env.TERRAFORM_INIT = '--init'
                    } else {
                        env.TERRAFORM_INIT = ''
                    }
                    // Generate json file in the workspace
                    writeFile file: 'custom_repositories.json', text: params.custom_repositories, encoding: "UTF-8"
                    // Run Terracumber to deploy the environment
                    sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} --taint '.*(domain|main_disk|data_disk|server_extra_nfs_mounts).*' --custom-repositories ${WORKSPACE}/custom_repositories.json --sumaform-backend ${params.sumaform_backend} --runstep provision"
                    // Generate features
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake utils:generate_build_validation_features'"
                    deployed = true
                }
            }

            stage('Sanity check') {
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:build_validation_sanity_check'"
            }

            stage('Run core features') {
                if(params.must_run_core && (deployed || !params.must_deploy)) {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_core'"
                }
            }

            stage('Sync. products and channels') {
                if(params.must_sync && (deployed || !params.must_deploy)) {
                    res_products = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_reposync'", returnStatus: true)
                    echo "Custom channels and MU repositories status code: ${res_products}"
                    res_sync_products = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_wait_for_product_reposync'", returnStatus: true)
                    echo "Custom channels and MU repositories synchronization status code: ${res_sync_products}"
                    sh "exit \$(( ${res_products}|${res_sync_products} ))"
                }
            }

            stage('Prepare Proxy') {
                input 'Press any key to start bootstraping the Proxy'
                if(params.must_boot_proxy) {
                    echo 'Add proxy MUs'
                    input 'Press any key to start adding Maintenance Update repositories'
                    if(params.must_add_custom_channels) {
                        echo 'Add custom channels and MU repositories'
                        res_mu_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_add_custom_repository_proxy'", returnStatus: true)
                        echo "Custom channels and MU repositories status code: ${res_mu_repos}"
                        res_sync_mu_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_wait_for_custom_reposync'", returnStatus: true)
                        echo "Custom channels and MU repositories synchronization status code: ${res_sync_mu_repos}"
                        sh "exit \$(( ${res_mu_repos}|${res_sync_mu_repos} ))"
                    }
                    echo 'Add proxy activation keys'
                    input 'Press any key to start adding activation keys'
                    if(params.must_add_keys) {
                        echo 'Add Activation Keys'
                        res_add_keys = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_add_activation_key_proxy'", returnStatus: true)
                        echo "Add Activation Keys status code: ${res_add_keys}"
                    }
                    echo 'Create proxy bootstrap repositories'
                    input 'Press any key to start creating bootstrap repositories'
                    if(params.must_create_bootstrap_repos) {
                        echo 'Create bootstrap repositories'
                        res_create_bootstrap_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_create_bootstrap_repository_proxy'", returnStatus: true)
                        echo "Create bootstrap repositories code: ${res_create_bootstrap_repos}"
                    }
                }
            }

            stage('Bootstrap Proxy') {
                input 'Press any key to start bootstraping the Proxy'
                if(params.must_boot_proxy) {
                    res_init_proxy = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_init_proxy'", returnStatus: true)
                    echo "Init Proxy status code: ${res_init_proxy}"
                }
            }

            stage('Bootstrap Monitoring Server') {
                input 'Press any key to start bootstraping the Monitoring Server'
                if(params.must_boot_monitoring) {
                    echo 'Register monitoring server as minion with gui'
                    res_init_monitoring = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_init_monitoring'", returnStatus: true)
                    echo "Init Monitoring Server status code: ${res_init_monitoring}"
                }
            }

            stage('Clients stages') {
                clientTestingStages()
            }

            stage('Prepare and run Retail') {
                input 'Press any key to start running the retail tests'
                if(params.must_prepare_retail) {
                    echo 'Prepare Proxy for Retail'
                    res_retail_proxy = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export CAPYBARA_TIMEOUT=${params.capybara_timeout}; export DEFAULT_TIMEOUT=${params.default_timeout}; export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_retail_proxy'", returnStatus: true)
                    echo "Retail proxy status code: ${res_retail_proxy}"
                    echo 'SLE 12 Retail'
                    res_retail_sle12 = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export CAPYBARA_TIMEOUT=${params.capybara_timeout}; export DEFAULT_TIMEOUT=${params.default_timeout}; export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_retail_sle12'", returnStatus: true)
                    echo "SLE 12 Retail status code: ${res_retail_sle12}"
                    echo 'SLE 15 Retail'
                    res_retail_sle15 = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export CAPYBARA_TIMEOUT=${params.capybara_timeout}; export DEFAULT_TIMEOUT=${params.default_timeout}; export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_retail_sle15'", returnStatus: true)
                    echo "SLE 15 Retail status code: ${res_retail_sle15}"
                }
            }

            stage('Containerization') {
                input 'Press any key to start running the containerization tests'
                if(params.must_run_containerization_tests) {
                    echo 'Prepare Proxy as Pod and run basic tests'
                    res_container_proxy = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export CAPYBARA_TIMEOUT=${params.capybara_timeout}; export DEFAULT_TIMEOUT=${params.default_timeout}; export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_containerization'", returnStatus: true)
                    echo "Container proxy status code: ${res_container_proxy}"
                }
            }
        }
        finally {
            stage('Save TF state') {
                archiveArtifacts artifacts: "results/sumaform/terraform.tfstate, results/sumaform/.terraform/**/*"
            }

            stage('Get results') {
                def error = 0
                if (deployed || !params.must_deploy) {
                    try {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_finishing'"
                    } catch(Exception ex) {
                        println("ERROR: rake cucumber:build_validation_finishing failed")
                        error = 1
                    }
                    try {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake utils:generate_test_report'"
                    } catch(Exception ex) {
                        println("ERROR: rake utils:generate_test_report failed")
                        error = 1
                    }
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep getresults"
                    publishHTML( target: [
                            allowMissing: true,
                            alwaysLinkToLastBuild: false,
                            keepAll: true,
                            reportDir: "${resultdirbuild}/cucumber_report/",
                            reportFiles: 'cucumber_report.html',
                            reportName: "Build Validation report"]
                    )
                    // junit allowEmptyResults: true, testResults: "${junit_resultdir}/*.xml"
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

def clientTestingStages() {
    def tests = [:]
    Set<String> nodeList = new HashSet<String>()
    modules = sh(script: "cd /home/maxime/jenkinsslave/workspace/SUSEManager-4.3-AWS-build-validation/results/sumaform-aws; terraform state list",
            returnStdout: true)
    String[] moduleList = modules.split("\n")
    moduleList.each {lane->
        def instanceList = lane.tokenize(".")
//        if (instanceList[1].contains('minion') || instanceList[1].contains('client')) {
        if (instanceList[1].contains('minion')) {
            nodeList.add(instanceList[1])
        }
    }
    echo nodeList.join(", ")

    nodeList.each { minion ->
        tests["testing-${minion}"] = {

            stage('Add MUs') {
                if (!minion.contains('ssh')) {
                    input 'Press any key to start adding Maintenance Update repositories'
                    if (params.must_add_custom_channels) {
                        echo 'Add custom channels and MU repositories'
                        res_mu_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_add_custom_repositories_${minion}'", returnStatus: true)
                        echo "Custom channels and MU repositories status code: ${res_mu_repos}"
                        res_sync_mu_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_wait_for_custom_reposync'", returnStatus: true)
                        echo "Custom channels and MU repositories synchronization status code: ${res_sync_mu_repos}"
                        sh "exit \$(( ${res_mu_repos}|${res_sync_mu_repos} ))"
                    }
                }
            }

            stage('Add Common Channels') {
                if (!minion.contains('ssh')) {
                    input 'Press any key to start adding common channels'
                    if (params.must_add_common_channels) {
                        echo 'Add common channels'
                        res_common_channels = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_add_common_channels'", returnStatus: true)
                        echo "Custom channels and MU repositories status code: ${res_common_channels}"
                        res_sync_common_channels = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_wait_for_custom_reposync'", returnStatus: true)
                        echo "Common channels synchronization status code: ${res_sync_common_channels}"
                        sh "exit \$(( ${res_common_channels}|${res_sync_common_channels} ))"
                    }
                }
            }

            stage('Add Activation Keys') {
                input 'Press any key to start adding activation keys'
                if (params.must_add_keys) {
                    echo 'Add Activation Keys'
                    res_add_keys = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_add_activation_key_${minion}'", returnStatus: true)
                    echo "Add Activation Keys status code: ${res_add_keys}"
                }
            }

            stage('Create bootstrap repositories') {
                if (!minion.contains('ssh')) {
                    input 'Press any key to start creating bootstrap repositories'
                    if (params.must_create_bootstrap_repos) {
                        echo 'Create bootstrap repositories'
                        res_create_bootstrap_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_create_bootstrap_repository_${minion}'", returnStatus: true)
                        echo "Create bootstrap repositories code: ${res_create_bootstrap_repos}"
                    }
                }
            }


            stage('Bootstrap clients') {
                input 'Press any key to start bootstraping the clients'
                if (params.must_boot_clients) {
                    echo 'Bootstrap clients'
                    res_init_clients = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export CAPYBARA_TIMEOUT=${params.capybara_timeout}; export DEFAULT_TIMEOUT=${params.default_timeout}; export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_init_client_${minion}'", returnStatus: true)
                    echo "Init clients status code: ${res_init_clients}"
                }
            }

            stage('Run Smoke Tests') {
                input 'Press any key to start running the smoke tests'
                if (params.must_run_tests) {
                    echo 'Run Smoke tests'
                    res_smoke_tests = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export CAPYBARA_TIMEOUT=${params.capybara_timeout}; export DEFAULT_TIMEOUT=${params.default_timeout}; export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_smoke_tests_${minion}'", returnStatus: true)
                    echo "Smoke tests status code: ${res_smoke_tests}"
                }
            }
        }
    }

    parallel tests
}
return this
