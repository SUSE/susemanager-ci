def run(params) {

    timestamps {

        //Deployment variable
        deployed_local = false
        deployed_aws = false
        env.local_common_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/local_mirror.tf --gitfolder ${resultdir}/sumaform-local"
        env.aws_common_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/aws_mirror.tf --gitfolder ${resultdir}/sumaform-aws"
        if (params.terraform_init) {
            TERRAFORM_INIT = '--init'
        } else {
            TERRAFORM_INIT = ''
        }

        // Environment variable
        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        // The junit plugin doesn't affect full paths
        junit_resultdir = "results/${BUILD_NUMBER}/results_junit"
        env.local_common_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/local_mirror.tf --gitfolder ${resultdir}/sumaform-local"
        env.aws_common_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/aws_mirror.tf --gitfolder ${resultdir}/sumaform-aws"

        // MU repositories list
        String[] REPOSITORIES_LIST = params.mu_repositories.split("\n")

        stage('Clone terracumber, susemanager-ci and sumaform') {
            // Create a directory for  to place the directory with the build results (if it does not exist)
            sh "mkdir -p ${resultdir}"
            git url: params.terracumber_gitrepo, branch: params.terracumber_ref
            dir("susemanager-ci") {
                checkout scm
            }
            // Clone sumaform
            sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${env.local_common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync --sumaform-backend libvirt"
            sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${env.aws_common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync --sumaform-backend aws"
        }

        stage('Create mirrors') {
            sh "echo ${deployed_local}"
            sh "echo ${TERRAFORM_INIT}"
            sh "echo ${REPOSITORIES_LIST}"
            parallel(
                    "create_local_mirror_with_mu": {
                        stage("Create local mirror with MU") {
                            env.repositories = "storage:\n" +
                                    "  type: file\n" +
                                    "  path: /srv/mirror\n" +
                                    "\n" +
                                    "http:"
                            REPOSITORIES_LIST.each { item ->
                                env.repositories = "${env.repositories}\n\n" +
                                        "  - url: ${item}\n" +
                                        "    archs: [x86_64]"
                            }
                            writeFile file: "${env.resultdir}/sumaform-local/salt/mirror/etc/minima-customize.yaml", text: env.repositories, encoding: "UTF-8"
//                            sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${local_common_params} --logfile ${resultdirbuild}/sumaform-local.log ${env.TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend libvirt"
//                            deployed_local = true

                        }
                    },
                    "create_empty_aws_mirror": {
                        stage("Create empty AWS mirror") {
                            // Provision the environment
//                            sh "set +x; source /home/jenkins/.credentials set -x; source /home/jenkins/.aws set -x;export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/sumaform-aws.log ${env.TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend aws"
                            deployed_aws = true

                        }
                    }
            )

        }

        stage("Upload ssh key to local mirror") {
            mirror_hostname_local = sh(script: "cat /home/jenkins/jenkins-build/workspace/uyuni-manager-mu-cloud/results/sumaform-local/terraform.tfstate | jq -r ''.resources[3].instances[0].attributes.network_interface[0].addresses[0]'' ",
                    returnStdout: true).trim()
            mirror_hostname_aws_public = sh(script: "cat /home/jenkins/jenkins-build/workspace/uyuni-manager-mu-cloud/results/sumaform-aws/terraform.tfstate | jq -r '.outputs.aws_mirrors_public_name.value[0]' ",
                    returnStdout: true).trim()
            env.mirror_hostname_aws_private = sh(script: "cat /home/jenkins/jenkins-build/workspace/uyuni-manager-mu-cloud/results/sumaform-aws/terraform.tfstate | jq -r '.outputs.aws_mirrors_private_name.value[0]' ",
                    returnStdout: true).trim()
            def remote = [:]
            remote.name = 'local_mirror'
            remote.user = 'root'
            remote.password = 'linux'
//            sh "scp -o StrictHostKeyChecking=no /home/jenkins/.ssh/testing-suma.pem ${remote.user}@${mirror_hostname_local}:/root/"
//            sh "ssh -o StrictHostKeyChecking=no ${remote.user}@${mirror_hostname_local} 'chmod 0400 /root/testing-suma.pem'"
//            sh "ssh -o StrictHostKeyChecking=no ${remote.user}@${mirror_hostname_local} 'scp -o StrictHostKeyChecking=no -r -i /root/testing-suma.pem /srv/mirror ec2-user@${mirror_hostname_aws_public}:/home/ec2-user/' "
//            sh "ssh -o StrictHostKeyChecking=no -i /home/jenkins/.ssh/testing-suma.pem ec2-user@${mirror_hostname_aws_public} 'sudo cp -R /home/ec2-user/repositories /srv/mirror' "
        }

        stage("Deploy") {
//            env.repositories_split = params.mu_repositories.split("\n")
            aws_repositories = "additional_repos = {\n"
            REPOSITORIES_LIST.each { item ->
                aws_repositories = aws_repositories + item.replaceAll('http://download.suse.de', "${mirror_hostname_aws_private}") + ",\n"
            }
        }
        aws_repositories = aws_repositories + "}\n"
        writeFile file: "${env.resultdir}/sumaform-aws/terraform.tvars", text: aws_repositories, encoding: "UTF-8"
    }
}


//            stage('Add MUs') {
//                if(params.must_add_channels) {
//                    echo 'Add custom channels and MU repositories'
//                    res_mu_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_add_custom_repositories'", returnStatus: true)
//                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_wait_for_custom_reposync'"
//                    echo "Custom channels and MU repositories status code: ${res_mu_repos}"
//                }
//            }

//            stage('Add Activation Keys') {
//                if(params.must_add_keys) {
//                    echo 'Add Activation Keys'
//                    res_add_keys = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_add_activation_keys'", returnStatus: true)
//                    echo "Add Activation Keys status code: ${res_add_keys}"
//                }
//            }


return this
