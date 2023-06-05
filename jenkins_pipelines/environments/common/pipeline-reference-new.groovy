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
                            env.TERRAFORM_TAINT = " --taint '.*(domain|main_disk).*'";
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
                sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} ${env.TERRAFORM_TAINT} --sumaform-backend ${params.sumaform_backend} --runstep provision"
                deployed = true
            }
            stage('Core - Setup') {
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:core'"
            }
            stage('Core - Reposync') {
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:reference_reposync'"
            }
            stage('Core - Initialize clients') {
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:reference_init_clients'"
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
