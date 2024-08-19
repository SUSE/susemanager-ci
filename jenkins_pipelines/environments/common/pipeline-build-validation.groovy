def run(params) {
    timestamps {
        //Capybara configuration
        def capybara_timeout = 60
        def default_timeout = 500
        env.bootstrap_timeout = 800

        deployed = false
        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        // The junit plugin doesn't affect full paths
        junit_resultdir = "results/${BUILD_NUMBER}/results_junit"
        env.exports = "export BUILD_NUMBER=${BUILD_NUMBER}; export BUILD_VALIDATION=true; export CAPYBARA_TIMEOUT=${capybara_timeout}; export DEFAULT_TIMEOUT=${default_timeout}; "

        // Declare lock resource use during node bootstrap
        mgrCreateBootstrapRepo = 'share resource to avoid running mgr create bootstrap repo in parallel'
        // Variables to store none critical stage run status
        def monitoring_stage_result_fail = false
        def client_stage_result_fail = false
        def products_and_salt_migration_stage_result_fail = false
        def retail_stage_result_fail = false
        def containerization_stage_result_fail = false

        env.common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${resultdir}/sumaform"

        // Path to JSON run set file for non MU repositories
        env.non_MU_channels_tasks_file = 'susemanager-ci/jenkins_pipelines/data/non_MU_channels_tasks.json'

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
                if (params.must_deploy) {
                    // Generate custom_repositories.json file in the workspace from the value passed by parameter
                    if (params.custom_repositories?.trim()) {
                        writeFile file: 'custom_repositories.json', text: params.custom_repositories, encoding: "UTF-8"
                    }
                    // Generate custom_repositories.json file in the workspace using a Python script - MI Identifiers passed by parameter
                    if (params.mi_ids?.trim()) {
                        node('manager-jenkins-node') {
                            checkout scm
                            res_python_script_ = sh(script: "python3 jenkins_pipelines/scripts/json_generator/maintenance_json_generator.py --mi_ids ${params.mi_ids}", returnStatus: true)
                            echo "Build Validation JSON script return code:\n ${json_content}"
                            if (res_python_script != 0) {
                                error("MI IDs (${params.mi_ids}) passed by parameter are wrong (or already released)")
                            }
                        }
                    }
                    // Run Terracumber to deploy the environment
                    sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log --init --taint '.*(domain|main_disk|data_disk|database_disk|server_extra_nfs_mounts).*' --custom-repositories ${WORKSPACE}/custom_repositories.json --sumaform-backend ${params.sumaform_backend} --runstep provision"
                    // Generate features
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake utils:generate_build_validation_features'"
                    // Generate rake files
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake jenkins:generate_rake_files_build_validation'"
                    deployed = true
                }
            }

            stage('Sanity check') {
                def nodesHandler = getNodesHandler()
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'unset ${nodesHandler.envVariableListToDisable}; cd /root/spacewalk/testsuite; ${env.exports} rake cucumber:build_validation_sanity_check'"
            }

            stage('Run core features') {
                if (params.must_run_core && (deployed || !params.must_deploy)) {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_core'"
                }
            }

            stage('Sync. products and channels') {
                if (params.must_sync && (deployed || !params.must_deploy)) {
                    // Get minion list from terraform state list command
                    def nodesHandler = getNodesHandler()
                    res_products = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'unset ${nodesHandler.envVariableListToDisable}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_reposync'", returnStatus: true)
                    echo "Custom channels and MU repositories status code: ${res_products}"
                    sh "exit ${res_products}"
                }
            }

            /** Proxy stages begin **/
            stage('Add MUs Proxy') {
                if (params.must_add_MU_repositories && params.enable_proxy_stages) {
                    echo 'Add proxy MUs'
                    if (params.confirm_before_continue) {
                        input 'Press any key to start adding Maintenance Update repositories'
                    }
                    echo 'Add custom channels and MU repositories'
                    res_mu_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_add_maintenance_update_repositories_proxy'", returnStatus: true)
                    echo "Custom channels and MU repositories status code: ${res_mu_repos}"
                    sh "exit ${res_mu_repos}"
                }
            }
            stage('Add Activation Keys Proxy') {
                if (params.must_add_keys && params.enable_proxy_stages) {
                    echo 'Add proxy activation key'
                    if (params.confirm_before_continue) {
                        input 'Press any key to start adding activation keys'
                    }
                    res_add_keys = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_add_activation_key_proxy'", returnStatus: true)
                    echo "Add Proxy Activation Key status code: ${res_add_keys}"
                    sh "exit ${res_add_keys}"
                }
            }
            stage('Create bootstrap repository Proxy') {
                if (params.must_create_bootstrap_repos && params.enable_proxy_stages) {
                    echo 'Create bootstrap repository ${node}'
                    if (params.confirm_before_continue) {
                        input 'Press any key to start creating the proxy bootstrap repository'
                    }
                    res_create_bootstrap_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_create_bootstrap_repository_proxy'", returnStatus: true)
                    echo "Create Proxy bootstrap repository status code: ${res_create_bootstrap_repos}"
                    sh "exit ${res_create_bootstrap_repos}"
                }
            }
            stage('Bootstrap Proxy') {
                if (params.must_boot_node && params.enable_proxy_stages) {
                    if (params.confirm_before_continue) {
                        input 'Press any key to start bootstraping the Proxy'
                    }
                    res_init_proxy = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_init_proxy'", returnStatus: true)
                    echo "Init Proxy status code: ${res_init_proxy}"
                    sh "exit ${res_init_proxy}"
                }
            }
            /** Proxy stages end **/

            /** Monitoring stages begin **/
            // Hide monitoring for qe update pipeline
            if (params.enable_monitoring_stages) {
                try {
                    stage('Add MUs Monitoring') {
                        if (params.must_add_MU_repositories && params.enable_monitoring_stages) {
                            if (params.confirm_before_continue) {
                                input 'Press any key to start adding Maintenance Update repositories'
                            }
                            echo 'Add custom channels and MU repositories'
                            res_mu_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_add_maintenance_update_repositories_monitoring_server'", returnStatus: true)
                            echo "Custom channels and MU repositories status code: ${res_mu_repos}"
                            sh "exit ${res_mu_repos}"
                        }
                    }
                    stage('Add Activation Keys Monitoring') {
                        if (params.must_add_keys && params.enable_monitoring_stages) {
                            echo 'Add server monitoring activation key'
                            if (params.confirm_before_continue) {
                                input 'Press any key to start adding activation keys'
                            }
                            res_add_keys = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_add_activation_key_monitoring_server'", returnStatus: true)
                            echo "Add Server Monitoring Activation Key status code: ${res_add_keys}"
                            sh "exit ${res_add_keys}"
                        }
                    }
                    stage('Create bootstrap repository Monitoring') {
                        if (params.must_create_bootstrap_repos && params.enable_monitoring_stages) {
                            echo 'Create server monitoring bootstrap repository'
                            if (params.confirm_before_continue) {
                                input 'Press any key to start creating the Server Monitoring bootstrap repository'
                            }
                            res_create_bootstrap_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_create_bootstrap_repository_monitoring_server'", returnStatus: true)
                            echo "Create Server Monitoring bootstrap repository status code: ${res_create_bootstrap_repos}"
                            sh "exit ${res_create_bootstrap_repos}"
                        }
                    }
                    stage('Bootstrap Monitoring Server') {
                        if (params.must_boot_node && params.enable_monitoring_stages) {
                            if (params.confirm_before_continue) {
                                input 'Press any key to start bootstraping the Monitoring Server'
                            }
                            echo 'Register monitoring server as minion with gui'
                            res_init_monitoring = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_init_monitoring'", returnStatus: true)
                            echo "Init Monitoring Server status code: ${res_init_monitoring}"
                            sh "exit ${res_init_monitoring}"
                        }
                    }
                } catch (Exception ex) {
                    println('Monitoring server bootstrap failed ')
                    monitoring_stage_result_fail = true
                }
            }
            /** Monitoring stages end **/

            /** Clients stages begin **/
            if (params.enable_client_stages) {
                // Call the minion testing.
                try {
                    stage('Clients stages') {
                        clientTestingStages()
                    }
                } catch (Exception ex) {
                    println('ERROR: one or more clients have failed')
                    client_stage_result_fail = true
                }
            }
            /** Clients stages end **/

            /** Products and Salt migration stages begin **/
            try {
                stage('Products and Salt migration stages') {
                    if(params.must_run_products_and_salt_migration_tests){
                        clientMigrationStages()
                    }                   
                } 
            } catch (Exception ex) {
                println('ERROR: one or more migrations have failed')
                products_and_salt_migration_stage_result_fail = true
            }
            /** Products and Salt migration stages stages end **/

            /** Retail stages begin **/
            try {
                stage('Prepare and run Retail') {
                    if (params.must_prepare_retail) {
                        if (params.confirm_before_continue) {
                            input 'Press any key to start running the retail tests'
                        }
                        echo 'Prepare Proxy for Retail'
                        res_retail_proxy = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_retail_proxy'", returnStatus: true)
                        echo "Retail proxy status code: ${res_retail_proxy}"
                        if (res_retail_proxy != 0) {
                            error("Retail proxy failed")
                        }
                        echo 'SLE 12 Retail'
                        res_retail_sle12 = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_retail_sle12'", returnStatus: true)
                        echo "SLE 12 Retail status code: ${res_retail_sle12}"
                        echo 'SLE 15 Retail'
                        res_retail_sle15 = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_retail_sle15'", returnStatus: true)
                        echo "SLE 15 Retail status code: ${res_retail_sle15}"
                        if (res_retail_sle15 != 0 || res_retail_sle12 != 0) {
                            error("Run retail failed")
                        }
                    }
                }
            } catch (Exception ex) {
                println('ERROR: Retail testing fail')
                retail_stage_result_fail = true
            }
            /** Retail stages end **/

            /** Containerization stages start **/
            try {
                stage('Containerization') {
                    if (params.must_run_containerization_tests ?: false) {
                        if (params.confirm_before_continue) {
                            input 'Press any key to start running the containerization tests'
                        }
                        echo 'Prepare Proxy as Pod and run basic tests'
                        res_container_proxy = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_containerization'", returnStatus: true)
                        echo "Container proxy status code: ${res_container_proxy}"
                        if (res_container_proxy != 0) {
                            error("Containerization test failed with status code: ${res_non_MU_repositories}")
                        }
                    }
                }
            } catch (Exception ex) {
                println('ERROR: Containerization failed')
                containerization_stage_result_fail = true
            }
            /** Containerization stages end **/
        }
        finally {
            stage('Save TF state') {
                archiveArtifacts artifacts: "results/sumaform/terraform.tfstate, results/sumaform/.terraform/**/*"
            }

            stage('Get results') {
                def result_error = 0
                if (deployed || !params.must_deploy) {
                    try {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_finishing'"
                    } catch(Exception ex) {
                        println("ERROR: rake cucumber:build_validation_finishing failed")
                        result_error = 1
                    }
                    try {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake utils:generate_test_report'"
                    } catch(Exception ex) {
                        println("ERROR: rake utils:generate_test_report failed")
                        result_error = 1
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
                // Fail pipeline if client stages failed
                if (client_stage_result_fail) {
                    error("Client stage failed")
                }
                // Fail pipeline if monitoring stages failed
                if (monitoring_stage_result_fail) {
                    error("Monitoring stage failed")
                }
                // Fail pipeline if products or Salt migration stages failed
                if (products_and_salt_migration_stage_result_fail) {
                    error("Product or Salt migration stage failed")
                }
                // Fail pipeline if retail stages failed
                if (retail_stage_result_fail) {
                    error("Retail stage failed")
                }
                // Fail pipeline if containerization stage failed
                if (containerization_stage_result_fail) {
                    error("Containerization stage failed")
                }
                sh "exit ${result_error}"
            }
        }
    }
}

// Develop a function that outlines the various stages of a minion.
// These stages will be executed concurrently.
def clientTestingStages() {

    // Implement a hash map to store the various stages of nodes.
    def tests = [:]

    // Load JSON matching non MU repositories data
    def json_matching_non_MU_data = readJSON(file: env.non_MU_channels_tasks_file)

    //Get minion list from terraform state list command
    def nodesHandler = getNodesHandler()
    def bootstrap_repository_status = nodesHandler.BootstrapRepositoryStatus
    def required_custom_channel_status = nodesHandler.CustomChannelStatus
    // Construct a stage list for each node.
    nodesHandler.nodeList.each { node ->
        tests["${node}"] = {
            // Generate a temporary list that comprises of all the minions except the one currently undergoing testing.
            // This list is utilized to establish an SSH session exclusively with the minion undergoing testing.
            def temporaryList = nodesHandler.envVariableList.toList() - node.replaceAll("ssh_minion", "sshminion").toUpperCase()
            stage("${node}") {
                echo "Testing ${node}"
            }
            stage("Add MUs ${node}") {
                if (params.must_add_MU_repositories) {
                    if (!node.contains('ssh')) {
                        if (params.confirm_before_continue) {
                            input 'Press any key to start adding Maintenance Update repositories'
                        }
                        echo 'Add custom channels and MU repositories'
                        res_mu_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'unset ${temporaryList.join(' ')}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_add_maintenance_update_repositories_${node}'", returnStatus: true)
                        if (res_mu_repos != 0) {
                            required_custom_channel_status[node] = 'FAIL'
                            error("Add custom channels and MU repositories failed with status code: ${res_mu_repos}")
                        }
                        echo "Custom channels and MU repositories status code: ${res_mu_repos}"
                    }
                }
                // Don't update required_custom_channel_status for minion who needs non MU repositories
                if (!json_matching_non_MU_data.containsKey(node)) {
                    required_custom_channel_status[node] = 'CREATED'
                }
            }
            stage("Add non MU Repositories ${node}") {
                if (params.must_add_non_MU_repositories) {
                    if (!node.contains('ssh')) {
                        // We have this condition inside the stage to see in Jenkins which minion is skipped
                        if (json_matching_non_MU_data.containsKey(node)) {
                            def build_validation_non_MU_script = json_matching_non_MU_data["${node}"]
                            if (params.confirm_before_continue) {
                                input 'Press any key to start adding common channels'
                            }
                            echo 'Add non MU Repositories'
                            res_non_MU_repositories = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'unset ${temporaryList.join(' ')}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:${build_validation_non_MU_script}'", returnStatus: true)
                            echo "Non MU Repositories status code: ${res_non_MU_repositories}"
                            if (res_non_MU_repositories != 0) {
                                required_custom_channel_status[node] = 'FAIL'
                                error("Add common channels failed with status code: ${res_non_MU_repositories}")
                            }
                        }
                    }
                }
                // Don't overwrite required_custom_channel_status variable for minions who don't need non MU repositories ( protect overwrite of add MU fails )
                if (json_matching_non_MU_data.containsKey(node)) {
                    required_custom_channel_status[node] = 'CREATED'
                }
            }
            stage("Add Activation Keys ${node}") {
                 // skip this stage for Salt migration minion
                if (params.must_add_keys && !node.contains('salt_migration_minion')) {
                    if (node.contains('ssh_minion')) {
                        // SSH minion need mandatory custom channel repository. The channel is created during minion stage.
                        // This section wait until minion creates custom channel.
                        def minion_name_without_ssh = node.replaceAll('ssh_minion', 'minion')
                        println "Waiting for mandatory custom channel for ${node} to be created by ${minion_name_without_ssh}."
                        waitUntil {
                            required_custom_channel_status[minion_name_without_ssh] != 'NOT_CREATED'
                        }
                        if (required_custom_channel_status[minion_name_without_ssh] == 'FAIL') {
                            error("${minion_name_without_ssh} creates bootstrap repository failed")
                        }
                    }
                    if (params.confirm_before_continue) {
                        input 'Press any key to start adding activation keys'
                    }
                    echo 'Add Activation Keys'
                    res_add_keys = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'unset ${temporaryList.join(' ')}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_add_activation_key_${node}'", returnStatus: true)
                    echo "Add Activation Keys status code: ${res_add_keys}"
                    if (res_add_keys != 0) {
                        bootstrap_repository_status[node] = 'FAIL'
                        error("Add Activation Keys failed with status code: ${res_add_keys}")
                    }
                }
            }
            stage("Create bootstrap repository ${node}") {
                if (params.must_create_bootstrap_repos) {
                    if (node.contains('ssh_minion')) {
                        // SSH minion need bootstrap repository. The bootstrap repository is created during minion stage.
                        // This section wait until minion creates bootstrap repository
                        def minion_name_without_ssh = node.replaceAll('ssh_minion', 'minion')
                        println "Waiting for bootstrap repository creation by ${minion_name_without_ssh} for ${node}."
                        waitUntil {
                            bootstrap_repository_status[minion_name_without_ssh] != 'NOT_CREATED'
                        }
                        if (bootstrap_repository_status[minion_name_without_ssh] == 'FAIL') {
                            error("${minion_name_without_ssh} creates bootstrap repository failed")
                        } else {
                            println "Bootstrap repository available for ${node} "
                        }
                    } else {
                        if (params.confirm_before_continue) {
                            input 'Press any key to start creating bootstrap repositories'
                        }
                        // Make sure s390 minions create their bootstrap repositories after the x86_64 equivalents to avoid flushing the repository folders.
                        if (node.contains('s390')){
                            def minion_name_without_s390 = node.replaceAll('s390', '')
                            waitUntil {
                                bootstrap_repository_status[minion_name_without_s390] != 'NOT_CREATED'
                            }
                        }
                        // Employ a lock resource to prevent concurrent calls to create the bootstrap repository in the manager.
                        // Utilize a try-catch mechanism to release the resource for other nodes in the event of a failed bootstrap.
                        lock(resource: mgrCreateBootstrapRepo, timeout: 320) {
                            try {
                                echo 'Create bootstrap repository'
                                res_create_bootstrap_repository = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'unset ${temporaryList.join(' ')}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_create_bootstrap_repository_${node}'", returnStatus: true)
                                echo "Create bootstrap repository status code: ${res_create_bootstrap_repository}"
                                if (res_create_bootstrap_repository != 0) {
                                    bootstrap_repository_status[node] = 'FAIL'
                                    error("Create bootstrap repository failed with status code: ${res_create_bootstrap_repository}")
                                }
                            } finally {
                                echo 'Release resource mgrCreateBootstrapRepo'
                            }
                        }
                    }
                }
                bootstrap_repository_status[node] = 'CREATED'
            }
            stage("Bootstrap client ${node}") {
                if (params.must_boot_node) {
                    if (params.confirm_before_continue) {
                        input 'Press any key to start bootstraping the clients'
                    }
                    randomWait()
                    echo 'Bootstrap clients'
                    res_init_clients = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'unset ${temporaryList.join(' ')}; ${env.exports} export DEFAULT_TIMEOUT=${env.bootstrap_timeout}; cd /root/spacewalk/testsuite; rake cucumber:build_validation_init_client_${node}'", returnStatus: true)
                    echo "Init clients status code: ${res_init_clients}"
                    if (res_init_clients != 0) {
                        error("Bootstrap clients failed with status code: ${res_init_clients}")
                    }
                }
            }
            stage("Run Smoke Tests ${node}") {
                if (params.must_run_tests) {
                    if (params.confirm_before_continue) {
                        input 'Press any key to start running the smoke tests'
                    }
                    randomWait()
                    echo 'Run Smoke tests'
                    res_smoke_tests = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'unset ${temporaryList.join(' ')}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_smoke_tests_${node}'", returnStatus: true)
                    echo "Smoke tests status code: ${res_smoke_tests}"
                    if (res_smoke_tests != 0) {
                        error("Run Smoke tests failed with status code: ${res_smoke_tests}")
                    }
                }
            }
        }
    }
    // Once all the stages have been correctly configured, run in parallel
    parallel tests
}

def getNodesHandler() {
    // Employ the terraform state list command to generate the list of nodes.
    // Due to the disparity between the node names in the test suite and those in the environment variables of the controller, two separate lists are maintained.
    Set<String> nodeList = new HashSet<String>()
    Set<String> envVar = new HashSet<String>()
    def BootstrapRepositoryStatus = [:]
    def CustomChannelStatus       = [:]
    modules = sh(script: "cd ${resultdir}/sumaform; terraform state list",
            returnStdout: true)
    String[] moduleList = modules.split("\n")
    moduleList.each { lane ->
        def instanceList = lane.tokenize(".")
        if (instanceList[1].contains('minion') || instanceList[1].contains('client')) {
            nodeList.add(instanceList[1].replaceAll('-', '_').replaceAll('sshminion', 'ssh_minion').replaceAll('sles', 'sle'))
            envVar.add(instanceList[1].replaceAll('-', '_').replaceAll('sles', 'sle').toUpperCase())
        }
    }
    // Convert jenkins minions list parameter to list
    Set<String> nodesToRun = params.minions_to_run.split(', ')
    // Create a variable with declared nodes on Jenkins side but not deploy and print it
    def notDeployedNode = nodesToRun.findAll { !nodeList.contains(it) }
    println "This minions are declared in jenkins but not deployed ! ${notDeployedNode}"
    // Check the difference between the nodes deployed and the nodes declared in Jenkins side
    // This difference will be the nodes to disable
    def disabledNodes = nodeList.findAll { !nodesToRun.contains(it) }
    // Convert this list to cucumber compatible environment variable
    def envVarDisabledNodes = disabledNodes.collect { it.replaceAll('ssh_minion', 'sshminion').toUpperCase() }
    // Create a node list without the disabled nodes. ( use to configure the client stage )
    def nodeListWithDisabledNodes = nodeList - disabledNodes
    // Create a map storing mu synchronization state for each minion.
    // This map is to be sure ssh minions have the MU channel ready.
    for (node in nodeListWithDisabledNodes ) {
        BootstrapRepositoryStatus[node] = 'NOT_CREATED'
        CustomChannelStatus[node]       = 'NOT_CREATED'
    }
    return [nodeList:nodeListWithDisabledNodes, envVariableList:envVar, envVariableListToDisable:envVarDisabledNodes.join(' '), CustomChannelStatus:CustomChannelStatus, BootstrapRepositoryStatus:BootstrapRepositoryStatus]
}

// Creates a stage for each product or client migration feature.
// Proceeds to execute them concurrently.
def clientMigrationStages() {
    def migration_tests = [:]

    features_list = sh(script: "./terracumber-cli ${common_params} --runstep cucumber --cucumber-cmd 'ls -1 /root/spacewalk/testsuite/features/build_validation/migration/'", returnStdout: true)
    String[] migration_features = features_list.split("\n").findAll { it.contains("_migration.feature") }
    // create a stage for each migration feature
    migration_features.each{ feature ->
        def minion = feature.replace("_migration.feature", "")

        migration_tests["${minion}"] = {
            if (params.confirm_before_continue) {
                input "Press any key to start testing the migration of ${minion}"
            }
            stage("${minion} migration") {
                res_minion_migration = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_${minion}_migration'", returnStatus: true)
                echo "${minion} migration status code: ${res_minion_migration}"
                if (res_minion_migration != 0) {
                    error("Migration test for ${minion} failed with status code: ${res_minion_migration}")
                }
            }
        }
    }
    // run them in parallel
    parallel migration_tests
}

def randomWait() {
    def randomWait = new Random().nextInt(180)
    println "Waiting for ${randomWait} seconds"
    sleep randomWait
}

return this
