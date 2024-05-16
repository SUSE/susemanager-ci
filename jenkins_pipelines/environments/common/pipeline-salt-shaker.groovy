def run(params) {
    timestamps {
        // Init path env variables
        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"

        // The junit plugin doesn't affect full paths
        junit_resultdir = "results/${BUILD_NUMBER}/results_junit"
        env.common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${resultdir}/sumaform --terraform-bin ${params.terraform_bin}"

        // Start pipeline
        deployed = false
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
                // Provision the environment
                if (params.terraform_init) {
                    env.TERRAFORM_INIT = '--init'
                } else {
                    env.TERRAFORM_INIT = ''
                }
                env.TERRAFORM_TAINT = ''
                if (params.terraform_taint) {
                    switch(params.sumaform_backend) {
                        case "libvirt":
                            env.TERRAFORM_TAINT = " --taint '.*(domain|main_disk|data_disk|database_disk|standalone_provisioning).*'";
                            break;
                        case "aws":
                            env.TERRAFORM_TAINT = " --taint '.*(host).*'";
                            break;
                        default:
                            println("ERROR: Unknown backend ${params.sumaform_backend}");
                            sh "exit 1";
                            break;
                    }
                }
                retry(count: 3) {
                    sh "set +x; source /home/jenkins/.credentials set -x; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} ${env.TERRAFORM_TAINT} --sumaform-backend ${params.sumaform_backend} --runstep provision"
                    deployed = true
                }
            }
            stage('Salt Shaker testsuite - Unit tests') {
	        if (!params.run_unit_tests) {
	            echo "Skipping unit tests as they were not selected for this execution"
		    return
		}
		catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
	            if (!params.testsuite_dir) {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep saltshaker --saltshaker-cmd '/usr/bin/salt-test --package-flavor ${params.salt_flavor} --skiplist ${params.skip_list_url} unit -- --core-tests --ssh-tests --slow-tests --run-expensive --run-destructive --junitxml /root/results_junit/junit-report-unit.xml -vvv --tb=native'"
		    } else {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep saltshaker --saltshaker-cmd '/usr/bin/salt-test --directory ${params.testsuite_dir} --skiplist ${params.skip_list_url} unit -- --core-tests --ssh-tests --slow-tests --run-expensive --run-destructive --junitxml /root/results_junit/junit-report-unit.xml -vvv --tb=native'"
		    }
		}
            }

            stage('Salt Shaker testsuite - Integration tests') {
	        if (!params.run_integration_tests) {
	            echo "Skipping integration tests as they were not selected for this execution"
		    return
		}
		catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
	            if (!params.testsuite_dir) {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep saltshaker --saltshaker-cmd '/usr/bin/salt-test --package-flavor ${params.salt_flavor} --skiplist ${params.skip_list_url} integration -- --core-tests --ssh-tests --slow-tests --run-expensive --run-destructive --junitxml /root/results_junit/junit-report-integration.xml -vvv --tb=native'"
		    } else {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep saltshaker --saltshaker-cmd '/usr/bin/salt-test --directory ${params.testsuite_dir} --skiplist ${params.skip_list_url} integration -- --core-tests --ssh-tests --slow-tests --run-expensive --run-destructive --junitxml /root/results_junit/junit-report-integration.xml -vvv --tb=native'"
		    }
		}
            }

            stage('Salt Shaker testsuite - Functional tests') {
	        if (!params.run_functional_tests) {
	            echo "Skipping functional tests as they were not selected for this execution"
		    return
		}
		catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
	            if (!params.testsuite_dir) {
	                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep saltshaker --saltshaker-cmd '/usr/bin/salt-test --package-flavor ${params.salt_flavor} --skiplist ${params.skip_list_url} functional -- --core-tests --ssh-tests --slow-tests --run-expensive --run-destructive --junitxml /root/results_junit/junit-report-functional.xml -vvv --tb=native'"
		    } else {
	                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep saltshaker --saltshaker-cmd '/usr/bin/salt-test --directory ${params.testsuite_dir} --skiplist ${params.skip_list_url} functional -- --core-tests --ssh-tests --slow-tests --run-expensive --run-destructive --junitxml /root/results_junit/junit-report-functional.xml -vvv --tb=native'"
		    }
		}
            }
        }
        finally {
            stage('Save TF state') {
                    archiveArtifacts artifacts: "results/sumaform/terraform.tfstate, results/sumaform/.terraform/**/*"
            }

            stage('Get results') {
                def error = 0
                if (deployed) {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep saltshaker_getresults"
                    junit allowEmptyResults: true, testResults: "${junit_resultdir}/*.xml"
                }
                // Send email
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/mail.log --runstep saltshaker_mail"
                // Clean up old results
                sh "./clean-old-results -r ${resultdir}"
                sh "exit ${error}"
            }
        }
    }
}

return this
