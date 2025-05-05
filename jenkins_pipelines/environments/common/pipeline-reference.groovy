def run(params) {
    timestamps {
        deployed = false
        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        env.common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${resultdir}/sumaform --terraform-bin ${params.terraform_bin}"

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
            
                // Attempt to restore Terraform states from artifacts
                if (params.use_previous_terraform_state) {
                    def terraformDir = "${env.WORKSPACE}/sumaform/terraform"
                    def terraformTmpDir = "${terraformDir}/temp/"
                    def filters = 'results/sumaform/terraform.tfstate, results/sumaform/.terraform/**/*'
                    def terraformStatePath = "results/sumaform/terraform.tfstate"
                    def previousBuild = currentBuild.previousBuild
                    def found = false

                    // Loop through previous builds until we find one for which a terraform state was stored
                    while (previousBuild != null) {
                        found = fileExists("${WORKSPACE}/${previousBuild.getArtifactsDir()}/${terraformStatePath}")
                        if (found){
                            echo "Found previous Terraform state in build ${previousBuild.number}."

                            // Copy just the necessary files (state and Terraform config) from the previous build to a temporary directory
                            sh "mkdir -p ${terraformTmpDir}"
                            copyArtifacts projectName: currentBuild.projectName, selector: specific("${previousBuild.number}"), filter: "${filters}" , target: "${terraformDir}"
                            // Copy the Terraform configuration files (like main.tf, variables.tf, etc) from the current workspace to the temp dir
                            sh "cp ${terraformDir}/*.tf ${terraformTmpDir}"

                            // Validate the restored Terraform state
                            dir(terraformTmpDir) {
                                sh "terraform init"
                                def planOutput = sh(script: "terraform plan -refresh=true", returnStatus: true)

                                if (planOutput == 0) {
                                    echo "Terraform state from build ${previousBuild.number} is valid."
                                    copyArtifacts projectName: currentBuild.projectName, selector: specific("${previousBuild.number}"
                                    break
                                } else {
                                    echo "Terraform state from build ${previousBuild.number} is invalid. Searching for another build."
                                    foundState = false
                                }
                            }
                        }
                        previousBuild = previousBuild.previousBuild
                    }
                    // Clean up the temp directory 
                    sh "rm -rf ${terraformTmpDir}"

                    if (!found) {
                        echo "No previous Terraform state to restore. Starting from scratch."
                    }
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
                            env.TERRAFORM_TAINT = "--taint '.*(domain|main_disk|data_disk|database_disk|standalone_provisioning).*'";
                            break;
                        case "aws":
                            env.TERRAFORM_TAINT = "--taint '.*(host).*'";
                            break;
                        default:
                            println("ERROR: Unknown backend ${params.sumaform_backend}");
                            sh "exit 1";
                            break;
                    }
                }
                sh "set +x; source /home/jenkins/.credentials set -x; TERRAFORM=${params.terraform_bin} TERRAFORM_PLUGINS=${params.terraform_bin_plugins} ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} ${env.TERRAFORM_TAINT} --sumaform-backend ${params.sumaform_backend} --runstep provision"
                deployed = true
            }
        }
        finally {
            stage('Save TF state') {
                    archiveArtifacts artifacts: "results/sumaform/terraform.tfstate, results/sumaform/.terraform/**/*"
            }
            stage('Get results') {
                if (!deployed) {
                  // Send email
                  sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/mail.log --runstep mail"
                }
                // Clean up old results
                sh "./clean-old-results -r ${resultdir}"
            }
        }
    }
}

return this
