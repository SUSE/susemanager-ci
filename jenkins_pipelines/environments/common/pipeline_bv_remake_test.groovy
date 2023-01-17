def run(params) {

    timestamps {
        list = ["Test-1", "Test-2", "Test-3", "Test-4", "Test-5"]
//        def minion
//        stage('Dynamic parallel') {
//            minions = sh(script: "source /home/maxime/.profile; printenv | grep MINION || exit 0",
//                    returnStdout: true)
//            sshminion = sh(script: "source /home/maxime/.profile; printenv | grep SSHMINION || exit 0",
//                    returnStdout: true)
//            client = sh(script: "source /home/maxime/.profile; printenv | grep CLIENT || exit 0",
//                    returnStdout: true)
//            String[] minion_list = minions.split("\n")
//            String[] sshminion_list = sshminion.split("\n")
//            String[] client_list = client.split("\n")
//            echo minion_list.join(", ")
//            echo sshminion_list.join(", ")
//            echo client_list.join(", ")
//
//            def node_list = [minion_list, sshminion_list, client_list].flatten().findAll { it }
//            echo node_list.join(", ")
//
//            node_list.each { element ->
//                minion = element.split("=")[0].toLowerCase()
//                tests["job-${minion}"] = {
//                    stage("${minion}") {
//                        echo minion
//                        sh "echo ${minion}"
//                    }
//                }
////                        parallel(
////                    dynamic: {
////                        for (element in node_list) {
////                            minion = element.split("=")[0].toLowerCase()
////                            echo minion
////                            stage("job-${minion}") {
////                                echo minion
////                                sh "echo ${minion}"
////
////
////                            }
////                        }
////                    }
////                        )
//                parallel tests
//
//            }
//
//        }
        stage('CI')
                {
                    doDynamicParallelSteps()
                }
    }

}

def doDynamicParallelSteps(){
    def tests = [:]
    Set<String> nodeList = new HashSet<String>()
    modules = sh(script: "cd /home/maxime/jenkinsslave/workspace/SUSEManager-4.3-AWS-build-validation/results/sumaform-aws; terraform state list",
            returnStdout: true)
    String[] moduleList = modules.split("\n")
    echo moduleList.join(", ")
    moduleList.each {lane->
        String[] instanceList = lane.split(".")
        echo instanceList.join(", ")
        echo instanceList[0]

        if (instanceList.contain(minion) || instanceList.contain(client)) {
            nodeList.add(instance)
        }
    }
    echo nodeList.join(", ")
//    minions = sh(script: "source /home/maxime/.profile; printenv | grep minion || exit 0",
//            returnStdout: true)
//    sshminion = sh(script: "source /home/maxime/.profile; printenv | grep sshminion || exit 0",
//            returnStdout: true)
//    client = sh(script: "source /home/maxime/.profile; printenv | grep client || exit 0",
//            returnStdout: true)
//    String[] minion_list = minions.split("\n")
//    String[] sshminion_list = sshminion.split("\n")
//    String[] client_list = client.split("\n")

//    def node_list = [minion_list, sshminion_list, client_list].flatten().findAll { it }
//    echo node_list.join(", ")
    nodeList.each { element ->
        def minion = element.split("=")[0].toLowerCase()
        tests["job-${minion}"] = {
            stage("Show ${minion}") {
                echo minion
                sh "echo ${minion}"
            }
            stage("Bootstrap ${minion}"){
                sh "hostname -f"
                sh "echo 'hostname for ${minion}'"
            }
        }
    }
    parallel tests
}

def realDoDynamicParallelSteps() {
    def tests = [:]

    minions = sh(script: "source /home/maxime/.profile; printenv | grep MINION || exit 0",
            returnStdout: true)
    sshminion = sh(script: "source /home/maxime/.profile; printenv | grep SSHMINION || exit 0",
            returnStdout: true)
    client = sh(script: "source /home/maxime/.profile; printenv | grep CLIENT || exit 0",
            returnStdout: true)
    String[] minion_list = minions.split("\n")
    String[] sshminion_list = sshminion.split("\n")
    String[] client_list = client.split("\n")

    def node_list = [minion_list, sshminion_list, client_list].flatten().findAll { it }
    echo node_list.join(", ")
    node_list.each { element ->
        def minion = element.split("=")[0].toLowerCase()
        tests["job-${minion}"] = {

            stage('Add MUs') {
                input 'Press any key to start adding Maintenance Update repositories'
                if (params.must_add_custom_channels) {
                    echo 'Add custom channels and MU repositories'
                    res_mu_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_add_custom_repositories'", returnStatus: true)
                    echo "Custom channels and MU repositories status code: ${res_mu_repos}"
                    res_sync_mu_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_wait_for_custom_reposync'", returnStatus: true)
                    echo "Custom channels and MU repositories synchronization status code: ${res_sync_mu_repos}"
                    sh "exit \$(( ${res_mu_repos}|${res_sync_mu_repos} ))"
                }
            }

            stage('Add Common Channels') {
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

            stage('Add Activation Keys') {
                input 'Press any key to start adding activation keys'
                if (params.must_add_keys) {
                    echo 'Add Activation Keys'
                    res_add_keys = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_add_activation_keys'", returnStatus: true)
                    echo "Add Activation Keys status code: ${res_add_keys}"
                }
            }

            stage('Create bootstrap repositories') {
                input 'Press any key to start creating bootstrap repositories'
                if (params.must_create_bootstrap_repos) {
                    echo 'Create bootstrap repositories'
                    res_create_bootstrap_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_create_bootstrap_repositories'", returnStatus: true)
                    echo "Create bootstrap repositories code: ${res_create_bootstrap_repos}"
                }
            }

            stage('Bootstrap Proxy') {
                input 'Press any key to start bootstraping the Proxy'
                if (params.must_boot_proxy) {
                    echo 'Proxy register as minion with gui'
                    res_init_proxy = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_init_proxy'", returnStatus: true)
                    echo "Init Proxy status code: ${res_init_proxy}"
                }
            }

            stage('Bootstrap Monitoring Server') {
                input 'Press any key to start bootstraping the Monitoring Server'
                if (params.must_boot_monitoring) {
                    echo 'Register monitoring server as minion with gui'
                    res_init_monitoring = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_init_monitoring'", returnStatus: true)
                    echo "Init Monitoring Server status code: ${res_init_monitoring}"
                }
            }

            stage('Bootstrap clients') {
                input 'Press any key to start bootstraping the clients'
                if (params.must_boot_clients) {
                    echo 'Bootstrap clients'
                    res_init_clients = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export CAPYBARA_TIMEOUT=${params.capybara_timeout}; export DEFAULT_TIMEOUT=${params.default_timeout}; export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_init_clients'", returnStatus: true)
                    echo "Init clients status code: ${res_init_clients}"
                }
            }

            stage('Run Smoke Tests') {
                input 'Press any key to start running the smoke tests'
                if (params.must_run_tests) {
                    echo 'Run Smoke tests'
                    res_smoke_tests = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export CAPYBARA_TIMEOUT=${params.capybara_timeout}; export DEFAULT_TIMEOUT=${params.default_timeout}; export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_smoke_tests'", returnStatus: true)
                    echo "Smoke tests status code: ${res_smoke_tests}"
                }
            }
        }
    }

    parallel tests
}

return this