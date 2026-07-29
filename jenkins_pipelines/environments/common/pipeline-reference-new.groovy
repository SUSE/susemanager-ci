def run(params) {
    timestamps {
        deployed = false
        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        env.common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${resultdir}/sumaform --terraform-bin ${params.bin_path}"

        if (params.deploy_parallelism) {
            env.common_params = "${env.common_params} --parallelism ${params.deploy_parallelism}"
        }

        // The new Jenkins has no /home/jenkins/.credentials on its agents: the same content
        // is provided by the sumaform-secrets credential and sourced from a temporary file.
        def isNewJenkins = env.JENKINS_URL?.contains('jenkins.mgr.suse.de')
        def credInit = isNewJenkins
                ? 'set +x; credFile=$(mktemp); echo "$SECRET_CONTENT" > "${credFile}"; chmod 600 "${credFile}"; . "${credFile}"; rm -f "${credFile}"; set -x'
                : 'set +x; . /home/jenkins/.credentials; set -x'
        def withCreds = { Closure body ->
            if (isNewJenkins) {
                withCredentials([string(credentialsId: 'sumaform-secrets', variable: 'SECRET_CONTENT')]) { body() }
            } else {
                body()
            }
        }

        try {
            withCreds {
                stage('Clone terracumber, susemanager-ci and sumaform') {
                    // Create a directory for  to place the directory with the build results (if it does not exist)
                    sh "mkdir -p ${resultdir}"
                    git url: params.terracumber_gitrepo, branch: params.terracumber_ref
                    dir("susemanager-ci") {
                        checkout scm
                    }
                    // Clone sumaform
                    sh """
                        #!/bin/bash
                        ${credInit}
                        ./terracumber-cli ${common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync
                    """

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
                                env.TERRAFORM_TAINT = " --taint '.*(domain|combustion_disk|cloudinit_disk|ignition_disk|main_disk|data_disk|database_disk|standalone_provisioning).*'";
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
                    if (isNewJenkins) {
                        sh """
                            sed -i '/HYPERVISOR_PRIVATE_SSH_KEY_PATH/d' ${resultdir}/sumaform/terraform.tfvars 2>/dev/null || true
                            sed -i '/CONTROLLER_PUBLIC_SSH_KEY_PATH/d' ${resultdir}/sumaform/terraform.tfvars 2>/dev/null || true
                            echo 'HYPERVISOR_PRIVATE_SSH_KEY_PATH="/home/jenkins/.ssh/id_ed25519.worker"' >> ${resultdir}/sumaform/terraform.tfvars
                            echo 'CONTROLLER_PUBLIC_SSH_KEY_PATH="/home/jenkins/.ssh/id_ed25519.pub.controller"' >> ${resultdir}/sumaform/terraform.tfvars
                        """
                    }
                    sh """
                        #!/bin/bash
                        ${credInit}
                        export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}
                        export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}
                        export TERRAFORM=${params.bin_path}
                        export TERRAFORM_PLUGINS=${params.bin_plugins_path}
                        ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} ${env.TERRAFORM_TAINT} --sumaform-backend ${params.sumaform_backend} --runstep provision
                    """
                    deployed = true
                }
                stage('Core - Setup') {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:core'"
                }
                stage('Core - Reposync') {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:reference_reposync'"
                }
                stage('Core - Proxy') {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:proxy'"
                }
                stage('Core - Initialize clients') {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:reference_init_clients'"
                }
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
