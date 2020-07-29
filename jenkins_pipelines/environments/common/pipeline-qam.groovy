def run(params) {
    timestamps {
        deployed = false
        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        // The junit plugin doesn't affect full paths
        junit_resultdir = "results/${BUILD_NUMBER}/results_junit"
        sumaformdir = "${resultdir}/sumaform".replace("qam", "qam-setup") // HACK: Temporary hack, as Terraform needs the tfstate file from the first pipeline workspace
        env.common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${sumaformdir}"
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
            }


            stage('Add MUs') {
                if(params.must_add_channels) {
                    echo 'Add custom channels and MU repositories'
                    res_mu_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:qam_add_custom_repositories'", returnStatus: true)
                    echo "Custom channels and MU repositories status code: ${res_mu_repos}"
                }
            }
            
            stage('Add Activation Keys') {
                if(params.must_add_keys) {
                    echo 'Add Activation Keys'
                    res_add_keys = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:qam_add_activation_keys'", returnStatus: true)
                    echo "Add Activation Keys status code: ${res_add_keys}"
                }
            }

            stage('Bootstrap Proxy') {
                if(params.must_boot_proxy) {
                    echo 'Proxy register as minion with gui'
                    res_init_proxy = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:qam_init_proxy'", returnStatus: true)
                    echo "Init Proxy status code: ${res_init_proxy}"
                }
            }
            
            stage('Bootstrap clients') {
                if(params.must_boot_clients) {
                    echo 'Bootstrap clients'
                    res_init_clients = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:qam_init_clients'", returnStatus: true)
                    echo "Init clients status code: ${res_init_clients}"
                }
            }

            stage('Run Smoke Tests') {
                if(params.must_run_tests) {
                        echo 'Run Smoke tests'
                        res_smoke_tests = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:qam_smoke_tests'", returnStatus: true)
                        echo "Smoke tests status code: ${res_smoke_tests}"
                }
            }
        }
        finally {
            stage('Get results') {
                def error = 0
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
                            reportName: "TestSuite Report"]
                )
                junit allowEmptyResults: true, testResults: "${junit_resultdir}/*.xml"
            }
            // Send email
            sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/mail.log --runstep mail"
            // Clean up old results
            sh "./clean-old-results -r ${resultdir}"
            sh "exit ${error}"
        }
    }
}

return this
