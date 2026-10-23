def run(params) {
    ansiColor('xterm') {
        timestamps {
            def deployed = false
            env.resultdir = "${WORKSPACE}/results"
            env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
            // Read from getNodesHandler(), which only sees the job parameters
            env.terraform_bin = params.bin_path
            GString aws_dir = "${resultdir}/sumaform-aws"
            env.exports = "export BUILD_NUMBER=${BUILD_NUMBER}; export BUILD_VALIDATION=true; export CUCUMBER_PUBLISH_QUIET=true;"

            // Inactivity timeout: kills a cucumber run that has stopped producing output entirely.
            // Measured on full runs, the worst legitimate silence outside the product sync stays
            // under 5 minutes, while the sync itself went silent for 62 minutes in
            // manager-4.3-qe-build-validation #43, so it gets a timeout of its own.
            // Anything that is not a positive number of minutes falls back to the default.
            // No 'def': both values are read from clientTestingStages() and clientMigrationStages().
            def idleTimeoutMinutesOr = { value, int fallback ->
                def raw = value?.toString()?.trim()
                raw?.isInteger() && raw.toInteger() > 0 ? raw.toInteger() : fallback
            }
            cucumberIdleTimeoutMinutes = idleTimeoutMinutesOr(params.cucumber_idle_timeout, 60)
            productSyncIdleTimeoutMinutes = idleTimeoutMinutesOr(params.product_sync_idle_timeout, 180)
            withIdleTimeoutOf = { int minutes, Closure body ->
                timeout(activity: true, time: minutes, unit: 'MINUTES') { body() }
            }
            withIdleTimeout = { Closure body ->
                withIdleTimeoutOf(cucumberIdleTimeoutMinutes, body)
            }

            String server_ami = params.server_ami ?: ""
            String proxy_ami = params.proxy_ami ?: ""
            // Private hostname of the AWS mirror deployed by manager-5.2-qe-build-validation-AWS-mirror, empty for no mirror
            String mirror_hostname = params.mirror_hostname?.trim() ?: ""

            // The new Jenkins has no /home/jenkins/.credentials on its agents: the same
            // content is provided by the sumaform-secrets credential and sourced from a temporary file.
            def credInit = 'set +x; credFile=$(mktemp); echo "$SECRET_CONTENT" > "${credFile}"; chmod 600 "${credFile}"; . "${credFile}"; rm -f "${credFile}"; set -x'
            def withCreds = { Closure body ->
                withCredentials([string(credentialsId: 'sumaform-secrets', variable: 'SECRET_CONTENT')]) { body() }
            }

            GString tfvarsPrepareScript = "${WORKSPACE}/susemanager-ci/jenkins_pipelines/scripts/tf_vars_generator/prepare_tfvars.py"

            // Declare lock resource use during node bootstrap
            // No 'def': it is read from clientTestingStages().
            mgrCreateBootstrapRepo = 'share resource to avoid running mgr create bootstrap repo in parallel'
            // Variables to store none critical stage run status
            def monitoring_stage_result_fail = false
            def client_stage_result_fail = false
            def client_paygo_stage_result_fail = false
            def paygo_testing_stage_result_fail = false
            def products_and_salt_migration_stage_result_fail = false
            def retail_stage_result_fail = false
            // Version passed to maintenance_json_generator.py: it has no default anymore,
            // so every environment offering mi_ids has to name the version explicitly.
            def json_generator_version = params.json_generator_version ?: ''

            env.common_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/${params.tf_file} --gitfolder ${aws_dir} --bastion_ssh_key ${params.key_file} --terraform-bin ${params.bin_path}"

            //Capybara configuration
            def capybara_timeout = 30
            def default_timeout = 300

            if (params.deploy_parallelism) {
                env.common_params = "${common_params} --parallelism ${params.deploy_parallelism}"
            }

            // Destroy what the last deployment created on this agent, using the state and tfvars it left in the workspace
            if (params.destroy_environment) {
                if (!params.confirm_destroy) {
                    error("destroy_environment requires confirm_destroy to be checked too")
                }
                stage('Destroy environment') {
                    if (!fileExists("${aws_dir}/terraform.tfstate")) {
                        error("No terraform state in ${aws_dir} on this agent: nothing to destroy")
                    }
                    withCreds {
                        sh "${credInit}; cd ${aws_dir}; ${params.bin_path} init; ${params.bin_path} destroy -auto-approve"
                    }
                    sh "rm -rf ${aws_dir}"
                    currentBuild.description = "environment destroyed"
                }
                return
            }

            try {
                stage('Clone terracumber, susemanager-ci and sumaform') {
                    // Create a directory for  to place the directory with the build results (if it does not exist)
                    sh "mkdir -p ${resultdir}"
                    git url: params.terracumber_gitrepo, branch: params.terracumber_ref
                    dir("susemanager-ci") {
                        checkout scm
                    }
                    sh "./terracumber-cli ${common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync --sumaform-backend aws"
                }


                if (params.must_deploy) {
                    stage("Deploy AWS with MU") {
                        // Generate custom_repositories.json file in the workspace from the value passed by parameter
                        if (params.custom_repositories?.trim()) {
                            writeFile file: 'custom_repositories.json', text: params.custom_repositories, encoding: "UTF-8"
                        }
                        // Generate custom_repositories.json file in the workspace using a Python script - MI Identifiers passed by parameter
                        if (params.mi_ids?.trim()) {
                            if (!json_generator_version) {
                                error("json_generator_version is not set for this environment, cannot generate custom_repositories.json from mi_ids")
                            }
                            node('manager-jenkins-node') {
                                checkout scm
                                def res_python_script_ = sh(script: "python3 jenkins_pipelines/scripts/json_generator/maintenance_json_generator.py --version ${json_generator_version} --mi_ids ${params.mi_ids} --no_embargo", returnStatus: true)
                                echo "Build Validation JSON script return code:\n ${res_python_script_}"
                                if (res_python_script_ != 0) {
                                    error("MI IDs (${params.mi_ids}) passed by parameter are wrong, already released or all under embargo")
                                }
                            }
                        }
                        // Replace internal repositories by mirror repositories
                        if (mirror_hostname && fileExists('custom_repositories.json')) {
                            sh "sed -i 's/download.suse.de/${mirror_hostname}/g' ${WORKSPACE}/custom_repositories.json"
                            sh "sed -i 's/ibs\\///g' ${WORKSPACE}/custom_repositories.json"
                        }

                        // Deploy into the shared AWS infrastructure (VPC, private network, bastion) created by the mirror pipeline
                        def NAME_PREFIX = env.JOB_NAME.toLowerCase().replace('.', '-')
                        writeFile file: "${aws_dir}/terraform.tfvars", encoding: "UTF-8", text:
                                "REGION = \"${params.aws_region}\"\n" +
                                "AVAILABILITY_ZONE = \"${params.aws_availability_zone}\"\n" +
                                "NAME_PREFIX = \"${NAME_PREFIX}-\"\n" +
                                "INFRA_NAME_PREFIX = \"${params.infra_name_prefix}\"\n" +
                                "KEY_FILE = \"${params.key_file}\"\n" +
                                "KEY_NAME = \"${params.key_name}\"\n"

                        def scriptArgs = " --output ${aws_dir}/terraform.tfvars"
                        scriptArgs += " --merge-files ${aws_dir}/terraform.tfvars ${params.deployment_tfvars}"
                        scriptArgs += " --inject CUCUMBER_GITREPO=${params.cucumber_gitrepo}"
                        scriptArgs += " --inject CUCUMBER_BRANCH=${params.cucumber_ref}"
                        scriptArgs += " --inject ARCHITECTURE=${params.architecture}"
                        scriptArgs += " --inject MIRROR=${mirror_hostname}"
                        scriptArgs += " --inject SERVER_AMI=${server_ami}"
                        scriptArgs += " --inject PROXY_AMI=${proxy_ami}"
                        scriptArgs += " --clean --keep-resources ${params.minions_to_run.split(', ').join(' ')}"
                        if (fileExists('custom_repositories.json')) {
                            scriptArgs += " --custom-repositories-json ${WORKSPACE}/custom_repositories.json"
                        }

                        // Deploying AWS server using MU repositories
                        sh "python3 ${tfvarsPrepareScript} ${scriptArgs}"

                        withCreds {
                            sh "${credInit}; export TERRAFORM=${params.bin_path}; export TERRAFORM_PLUGINS=${params.bin_plugins_path}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform-aws.log --init --taint '.*(domain|main_disk).*' --custom-repositories ${WORKSPACE}/custom_repositories.json --runstep provision --sumaform-backend aws"
                        }
                        deployed = true

                    }
                }

                if (params.generate_feature) {
                    stage('Generate feature') {
                        // Generate features
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake utils:generate_build_validation_features'"
                        // Generate rake files
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake jenkins:generate_rake_files_build_validation'"
                    }
                }

                stage('Run core features') {
                    if (params.must_run_core && (deployed || !params.must_deploy)) {
                        withIdleTimeout {
                            sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_core'"
                        }
                    }
                }

                stage('Sync. products and channels') {
                    if (params.must_sync && (deployed || !params.must_deploy)) {
                        // Get minion list from terraform state list command
                        def nodesHandler = getNodesHandler()
                        def res_sync_products = 1
                        withIdleTimeoutOf(productSyncIdleTimeoutMinutes) {
                            res_sync_products = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'unset ${nodesHandler.envVariableListToDisable.join(' ')}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_reposync'", returnStatus: true)
                        }
                        echo "Custom channels and MU repositories synchronization status code: ${res_sync_products}"
                        sh "exit ${res_sync_products}"
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
                        def res_mu_repos = 1
                        withIdleTimeout {
                            res_mu_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_add_maintenance_update_repositories_proxy'", returnStatus: true)
                        }
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
                        def res_add_keys = 1
                        withIdleTimeout {
                            res_add_keys = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_add_activation_key_proxy'", returnStatus: true)
                        }
                        echo "Add Proxy Activation Key status code: ${res_add_keys}"
                        sh "exit ${res_add_keys}"
                    }
                }
                stage('Create bootstrap repository Proxy') {
                    if (params.must_create_bootstrap_repos && params.enable_proxy_stages) {
                        echo 'Create proxy bootstrap repository'
                        if (params.confirm_before_continue) {
                            input 'Press any key to start creating the proxy bootstrap repository'
                        }
                        def res_create_bootstrap_repos = 1
                        withIdleTimeout {
                            res_create_bootstrap_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_create_bootstrap_repository_proxy'", returnStatus: true)
                        }
                        echo "Create Proxy bootstrap repository status code: ${res_create_bootstrap_repos}"
                        sh "exit ${res_create_bootstrap_repos}"
                    }
                }
                stage('Bootstrap Proxy') {
                    if (params.must_boot_node && params.enable_proxy_stages) {
                        if (params.confirm_before_continue) {
                            input 'Press any key to start bootstraping the Proxy'
                        }
                        def res_init_proxy = 1
                        withIdleTimeout {
                            res_init_proxy = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_init_proxy'", returnStatus: true)
                        }
                        echo "Init Proxy status code: ${res_init_proxy}"
                        sh "exit ${res_init_proxy}"
                    }
                }

                /** Proxy stages end **/

                /** PAYGO stages begin **/
                if (params.enable_paygo_stages) {
                    // Call the minion testing.
                    try {
                        stage('Clients paygo stages') {
                            clientTestingStages(params, capybara_timeout, default_timeout, 'paygo')
                        }

                    } catch (Exception ex) {
                        println("ERROR: one or more clients have failed.\nException: ${ex}")
                        client_paygo_stage_result_fail = true
                    }
                    stage('Paygo testing') {
                        if (params.confirm_before_continue) {
                            input 'Press any key to start paygo related tests'
                        }
                        def res_paygo_testing = 1
                        withIdleTimeout {
                            res_paygo_testing = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_paygo_testing'", returnStatus: true)
                        }
                        echo "PAYGO testing status code: ${res_paygo_testing}"
                        paygo_testing_stage_result_fail = res_paygo_testing != 0
                    }
                }

                /** PAYGO stages end **/

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
                                def res_mu_repos = 1
                                withIdleTimeout {
                                    res_mu_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_add_maintenance_update_repositories_monitoring_server'", returnStatus: true)
                                }
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
                                def res_add_keys = 1
                                withIdleTimeout {
                                    res_add_keys = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_add_activation_key_monitoring_server'", returnStatus: true)
                                }
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
                                def res_create_bootstrap_repos = 1
                                withIdleTimeout {
                                    res_create_bootstrap_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_create_bootstrap_repository_monitoring_server'", returnStatus: true)
                                }
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
                                def res_init_monitoring = 1
                                withIdleTimeout {
                                    res_init_monitoring = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_init_monitoring'", returnStatus: true)
                                }
                                echo "Init Monitoring Server status code: ${res_init_monitoring}"
                                sh "exit ${res_init_monitoring}"
                            }
                        }
                    } catch (Exception ex) {
                        println("Monitoring server bootstrap failed.\nException: ${ex}")
                        monitoring_stage_result_fail = true
                    }
                }
                /** Monitoring stages end **/

                /** Clients stages begin **/
                if (params.enable_client_stages) {
                    // Call the minion testing.
                    try {
                        stage('Clients stages') {
                            clientTestingStages(params, capybara_timeout, default_timeout)
                        }

                    } catch (Exception ex) {
                        println("ERROR: one or more clients have failed\\nException: ${ex}")
                        client_stage_result_fail = true
                    }
                }
                /** Clients stages end **/

                /** Products and Salt migration stages begin **/
                try {
                    stage('Products and Salt migration stages') {
                        if (params.must_run_products_and_salt_migration_tests) {
                            clientMigrationStages()
                        }
                    }
                } catch (Exception ex) {
                    println('ERROR: one or more migrations have failed')
                    products_and_salt_migration_stage_result_fail = true
                }
                /** Products and Salt migration stages end **/

                /** Retail stages begin **/
                try {
                    stage('Prepare and run Retail') {
                        if (params.must_prepare_retail) {
                            if (params.confirm_before_continue) {
                                input 'Press any key to start running the retail tests'
                            }
                            echo 'Prepare Proxy for Retail'
                            def res_retail_proxy = 1
                            withIdleTimeout {
                                res_retail_proxy = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export CAPYBARA_TIMEOUT=${capybara_timeout}; export DEFAULT_TIMEOUT=${default_timeout}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_retail_proxy'", returnStatus: true)
                            }
                            echo "Retail proxy status code: ${res_retail_proxy}"
                            if (res_retail_proxy != 0) {
                                error("Retail proxy failed")
                            }
                            echo 'SLE 12 Retail'
                            def res_retail_sle12 = 1
                            withIdleTimeout {
                                res_retail_sle12 = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export CAPYBARA_TIMEOUT=${capybara_timeout}; export DEFAULT_TIMEOUT=${default_timeout}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_retail_sle12'", returnStatus: true)
                            }
                            echo "SLE 12 Retail status code: ${res_retail_sle12}"
                            echo 'SLE 15 Retail'
                            def res_retail_sle15 = 1
                            withIdleTimeout {
                                res_retail_sle15 = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export CAPYBARA_TIMEOUT=${capybara_timeout}; export DEFAULT_TIMEOUT=${default_timeout}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_retail_sle15'", returnStatus: true)
                            }
                            echo "SLE 15 Retail status code: ${res_retail_sle15}"
                            if (res_retail_sle15 != 0 || res_retail_sle12 != 0) {
                                error("Run retail failed")
                            }
                        }
                    }
                } catch (Exception ex) {
                    println("ERROR: Retail testing fail.\\nException: ${ex}")
                    retail_stage_result_fail = true
                }
                /** Retail stages end **/
            }
            finally {
                stage('Save TF state') {
                    archiveArtifacts artifacts: "results/sumaform-aws/terraform.tfstate, results/sumaform-aws/.terraform/**/*", allowEmptyArchive: true
                }

                stage('Get results') {
                    def result_error = 0
                    if (deployed || !params.must_deploy) {
                        try {
                            withIdleTimeout {
                                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_finishing'"
                            }
                        } catch (Exception ex) {
                            println("ERROR: rake cucumber:build_validation_finishing failed.\\nException: ${ex}")
                            result_error = 1
                        }
                        try {
                            sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake utils:generate_test_report'"
                        } catch (Exception ex) {
                            println("ERROR: rake utils:generate_test_report failed.\\nException: ${ex}")
                            result_error = 1
                        }
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep getresults"
                        publishHTML(target: [
                                allowMissing         : true,
                                alwaysLinkToLastBuild: false,
                                keepAll              : true,
                                reportDir            : "${resultdirbuild}/results/cucumber_report/",
                                reportFiles          : 'index.html',
                                reportName           : "Build Validation report"]
                        )
                    }
                    // Send email
                    try {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/mail.log --runstep mail"
                    } catch (Exception ex) {
                        println("ERROR: sending the results email failed.\\nException: ${ex}")
                        result_error = 1
                    }
                    // Clean up old results
                    sh "./clean-old-results -r ${resultdir}"
                    // Fail pipeline if paygo client stages failed
                    if (client_paygo_stage_result_fail) {
                        error("Paygo client stage failed")
                    }
                    // Fail pipeline if paygo testing failed
                    if (paygo_testing_stage_result_fail) {
                        error("Paygo testing stage failed")
                    }
                    // Fail pipeline if client stages failed
                    if (client_stage_result_fail) {
                        error("Client stage failed")
                    }
                    // Fail pipeline if monitoring stages failed
                    if (monitoring_stage_result_fail) {
                        error("Monitoring stage failed")
                    }
                    // Fail pipeline if product or Salt migration stages failed
                    if (products_and_salt_migration_stage_result_fail) {
                        error("Product or Salt migration stage failed")
                    }
                    // Fail pipeline if retail stages failed
                    if (retail_stage_result_fail) {
                        error("Retail stage failed")
                    }

                    sh "exit ${result_error}"
                }
            }
        }
    }
}

// Develop a function that outlines the various stages of a minion.
// These stages will be executed concurrently.
def clientTestingStages(params, capybara_timeout, default_timeout, minion_type = 'default') {

    // Implement a hash map to store the various stages of nodes.
    def tests = [:]

    // Load JSON matching non MU repositories data (non_MU_channels_tasks_file variable declared at the pipeline description level)
    def json_matching_non_MU_data = readJSON(file: params.non_MU_channels_tasks_file)
    //Get minion list from terraform state list command
    def nodesHandler = getNodesHandler(minion_type)
    def mu_sync_status = nodesHandler.MUSyncStatus
    def nodesToTest = nodesHandler.nodeList
    // Paygo nodes are left to the paygo stages when those run, so they are not tested twice
    if (minion_type == 'default' && params.enable_paygo_stages) {
        nodesToTest = nodesToTest.findAll { !it.contains('paygo') && !it.contains('byos') }
    }

    // Construct a stage list for each node.
    nodesToTest.each { node ->
        tests["${node}"] = {
            // Generate a temporary list that comprises of all the minions except the one currently undergoing testing.
            // This list is utilized to establish an SSH session exclusively with the minion undergoing testing.
            def temporaryList = nodesHandler.envVariableList.toList() - node.toUpperCase()
            stage("${node}") {
                echo "Testing ${node}"
            }
            stage("Add MUs ${node}") {
                if (params.must_add_MU_repositories) {
                    if (node.contains('sshminion')) {
                        // SSH minion need minion MU channel. This section wait until minion finish creating MU channel
                        def minion_name_without_ssh = node.replaceAll('sshminion', 'minion')
                        println "Waiting for the MU channel creation by ${minion_name_without_ssh} for ${node}."
                        waitUntil {
                            mu_sync_status[minion_name_without_ssh] != 'UNSYNC'
                        }
                        if (mu_sync_status[minion_name_without_ssh] == 'FAIL') {
                            error("${minion_name_without_ssh} MU synchronization failed")
                        } else {
                            println "MU channel available for ${node} "
                        }
                    } else {
                        if (params.confirm_before_continue) {
                            input 'Press any key to start adding Maintenance Update repositories'
                        }
                        echo 'Add custom channels and MU repositories'
                        def res_mu_repos = 1
                        withIdleTimeout {
                            res_mu_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'unset ${temporaryList.join(' ')}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_add_maintenance_update_repositories_${node}'", returnStatus: true)
                        }
                        if (res_mu_repos != 0) {
                            mu_sync_status[node] = 'FAIL'
                            error("Add custom channels and MU repositories failed with status code: ${res_mu_repos}")
                        }
                        echo "Custom channels and MU repositories status code: ${res_mu_repos}"

                        // Update minion repo sync status variable once the MU channel is synchronized
                        mu_sync_status[node] = 'SYNC'
                    }
                }
            }
            stage("Add non MU Repositories ${node}") {
                if (params.must_add_non_MU_repositories) {
                    // We have this condition inside the stage to see in Jenkins which minion is skipped
                    if (json_matching_non_MU_data.containsKey(node)) {
                        def build_validation_non_MU_script = json_matching_non_MU_data["${node}"]
                        if (params.confirm_before_continue) {
                            input 'Press any key to start adding common channels'
                        }
                        echo 'Add non MU Repositories'
                        def res_non_MU_repositories = 1
                        withIdleTimeout {
                            res_non_MU_repositories = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'unset ${temporaryList.join(' ')}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:${build_validation_non_MU_script}'", returnStatus: true)
                        }
                        echo "Non MU Repositories status code: ${res_non_MU_repositories}"
                        if (res_non_MU_repositories != 0) {
                            error("Add common channels failed with status code: ${res_non_MU_repositories}")
                        }
                    }
                }
            }
            stage("Add Activation Keys ${node}") {
                // skip this stage for Salt migration minion
                if (params.must_add_keys && !node.contains('salt_migration_minion')) {
                    if (params.confirm_before_continue) {
                        input 'Press any key to start adding activation keys'
                    }
                    echo 'Add Activation Keys'
                    def res_add_keys = 1
                    withIdleTimeout {
                        res_add_keys = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'unset ${temporaryList.join(' ')}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_add_activation_key_${node}'", returnStatus: true)
                    }
                    echo "Add Activation Keys status code: ${res_add_keys}"
                    if (res_add_keys != 0) {
                        error("Add Activation Keys failed with status code: ${res_add_keys}")
                    }
                }
            }
            stage("Create bootstrap repository ${node}") {
                if (params.must_create_bootstrap_repos) {
                    if (!node.contains('ssh')) {
                        if (params.confirm_before_continue) {
                            input 'Press any key to start creating bootstrap repositories'
                        }
                        // Employ a lock resource to prevent concurrent calls to create the bootstrap repository in the manager.
                        // Utilize a try-catch mechanism to release the resource for other nodes in the event of a failed bootstrap.
                        lock(resource: mgrCreateBootstrapRepo, timeout: 320) {
                            try {
                                echo 'Create bootstrap repository'
                                def res_create_bootstrap_repository = 1
                                withIdleTimeout {
                                    res_create_bootstrap_repository = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'unset ${temporaryList.join(' ')}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_create_bootstrap_repository_${node}'", returnStatus: true)
                                }
                                echo "Create bootstrap repository status code: ${res_create_bootstrap_repository}"
                                if (res_create_bootstrap_repository != 0) {
                                    error("Create bootstrap repository failed with status code: ${res_create_bootstrap_repository}")
                                }
                            } finally {
                                echo 'Release resource mgrCreateBootstrapRepo'
                            }
                        }
                    }
                }
            }
            stage("Bootstrap client ${node}") {
                if (params.must_boot_node) {
                    if (params.confirm_before_continue) {
                        input 'Press any key to start bootstraping the clients'
                    }
                    randomWait()
                    echo 'Bootstrap clients'
                    def res_init_clients = 1
                    withIdleTimeout {
                        res_init_clients = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'unset ${temporaryList.join(' ')}; export CAPYBARA_TIMEOUT=${capybara_timeout}; export DEFAULT_TIMEOUT=${default_timeout}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_init_client_${node}'", returnStatus: true)
                    }
                    echo "Init clients status code: ${res_init_clients}"
                    if (res_init_clients != 0) {
                        error("Bootstrap clients failed with status code: ${res_init_clients}")
                    }
                }
            }
            stage("Run Smoke Tests ${node}") {
                if (params.must_run_tests && !node.contains('byos')) {
                    if (params.confirm_before_continue) {
                        input 'Press any key to start running the smoke tests'
                    }
                    randomWait()
                    echo 'Run Smoke tests'
                    def res_smoke_tests = 1
                    withIdleTimeout {
                        res_smoke_tests = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'unset ${temporaryList.join(' ')}; export CAPYBARA_TIMEOUT=${capybara_timeout}; export DEFAULT_TIMEOUT=${default_timeout}; ${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_smoke_tests_${node}'", returnStatus: true)
                    }
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

def getNodesHandler(minionType = 'default') {
    // Employ the terraform state list command to generate the list of nodes.
    // Due to the disparity between the node names in the test suite and those in the environment variables of the controller, two separate lists are maintained.
    Set<String> nodeList = new HashSet<String>()
    Set<String> envVar = new HashSet<String>()
    def MUSyncStatus = [:]
    def modules = sh(script: "cd ${resultdir}/sumaform-aws; ${terraform_bin} state list",
            returnStdout: true)
    String[] moduleList = modules.split("\n")
    moduleList.each { lane ->
        def nodeName = lane.tokenize(".")[1]
        // Nodes come with [0] in there names now because of the count introduction
        def cleanNodeName = nodeName.replaceAll(/\[\d+\]/, "")
        if ( minionType == 'default' && (cleanNodeName.contains('minion') || nodeName.contains('client'))) {
            nodeList.add(cleanNodeName.replaceAll('-', '_'))
            envVar.add(cleanNodeName.replaceAll('-', '_').toUpperCase())
        }
        else if (( minionType == 'paygo' && (cleanNodeName.contains('paygo') || nodeName.contains('byos')))) {
            nodeList.add(cleanNodeName.replaceAll('-', '_'))
            envVar.add(cleanNodeName.replaceAll('-', '_').toUpperCase())
        }
    }
    // Convert jenkins minions list parameter to list
    Set<String> nodesToRun = params.minions_to_run.split(', ').findAll { it }
    // Create a variable with declared nodes on Jenkins side but not deploy and print it
    def notDeployedNode = nodesToRun.findAll { !nodeList.contains(it) }
    println "These minions are declared in jenkins but not deployed! ${notDeployedNode}"
    // Check the difference between the nodes deployed and the nodes declared in Jenkins side
    // This difference will be the nodes to disable
    def disabledNodes = nodeList.findAll { !nodesToRun.contains(it) }
    // Convert this list to cucumber compatible environment variable
    def envVarDisabledNodes = disabledNodes.collect { it.toUpperCase() }
    // Create a node list without the disabled nodes. ( use to configure the client stage )
    def nodeListWithDisabledNodes = nodeList - disabledNodes
    // Create a map storing mu synchronization state for each minion.
    // This map is to be sure ssh minions have the MU channel ready.
    for (node in nodeListWithDisabledNodes ) {
        MUSyncStatus[node] = 'UNSYNC'
    }
    return [nodeList:nodeListWithDisabledNodes, envVariableList:envVar, envVariableListToDisable:envVarDisabledNodes, MUSyncStatus:MUSyncStatus]
}

// Creates a stage for each product or client migration feature.
// Proceeds to execute them concurrently.
def clientMigrationStages() {
    def migration_tests = [:]

    def features_list = sh(script: "./terracumber-cli ${common_params} --runstep cucumber --cucumber-cmd 'ls -1 /root/spacewalk/testsuite/features/build_validation/migration/'", returnStdout: true)
    String[] migration_features = features_list.split("\n").findAll { it.contains("_migration.feature") }
    // create a stage for each migration feature
    migration_features.each{ feature ->
        def minion = feature.replace("_migration.feature", "")

        migration_tests["${minion}"] = {
            if (params.confirm_before_continue) {
                input "Press any key to start testing the migration of ${minion}"
            }
            stage("${minion} migration") {
                def res_minion_migration = 1
                withIdleTimeout {
                    res_minion_migration = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${env.exports} cd /root/spacewalk/testsuite; rake cucumber:build_validation_${minion}_migration'", returnStatus: true)
                }
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
