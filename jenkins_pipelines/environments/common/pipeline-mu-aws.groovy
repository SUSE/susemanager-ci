def run(params) {

    timestamps {

        // Environment variables
        resultdir = "${WORKSPACE}/results"
        resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        // The junit plugin doesn't affect full paths
        junit_resultdir = "results/${BUILD_NUMBER}/results_junit"

        //Deployment variables
        deployed_local = false
        deployed_aws = false
        local_mirror_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/local_mirror.tf --gitfolder ${resultdir}/sumaform-local"
        aws_mirror_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/aws_mirror.tf --gitfolder ${resultdir}/sumaform-aws"
        aws_common_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/SUSEManager-4.1-AWS.tf --gitfolder ${resultdir}/sumaform-aws"
        if (params.terraform_init) {
            TERRAFORM_INIT = '--init'
        } else {
            TERRAFORM_INIT = ''
        }

        // MU repositories list
        String[] REPOSITORIES_LIST = params.mu_repositories.split("\n")

        // Public IP for AWS ingress
        String[] ALLOWED_IPS = params.allowed_IPS.split("\n")

        stage('Clone terracumber, susemanager-ci and sumaform') {
            // Create the directory for the build results
            sh "mkdir -p ${resultdir}"
            git url: params.terracumber_gitrepo, branch: params.terracumber_ref
            dir("susemanager-ci") {
                checkout scm
            }
            // Clone sumaform for aws and local repositories
            sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${local_mirror_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync --sumaform-backend libvirt"
            sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${aws_common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync --sumaform-backend aws"
        }

        parallel(
                "create_local_mirror_with_mu": {
                    stage("Create local mirror with MU") {
                        // Create simplify minima file to only synchronize MU
                        repositories = "storage:\n" +
                                "  type: file\n" +
                                "  path: /srv/mirror\n" +
                                "\n" +
                                "http:"
                        REPOSITORIES_LIST.each { item ->
                            repositories = "${repositories}\n\n" +
                                    "  - url: ${item}\n" +
                                    "    archs: [x86_64]"
                        }
                        writeFile file: "${resultdir}/sumaform-local/salt/mirror/etc/minima-customize.yaml", text: repositories, encoding: "UTF-8"

                        // Deploy local mirror
                        sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${local_mirror_params} --logfile ${resultdirbuild}/sumaform-local.log ${TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend libvirt"
                        deployed_local = true

                    }
                },
                "create_empty_aws_mirror": {
                    stage("Create empty AWS mirror") {
                        env.aws_configuration = "REGION = \"${params.aws_region}\"\n" +
                                "AVAILABILITY_ZONE = \"${params.aws_availability_zone}\"\n" +
                                "ALLOWED_IPS = [ \n"

                        ALLOWED_IPS.each { ip ->
                            env.aws_configuration = aws_configuration + "    \"${ip}\",\n"
                        }

                        env.aws_configuration = aws_configuration + "]\n"
                        writeFile file: "${resultdir}/sumaform-aws/terraform.tfvars", text: aws_configuration, encoding: "UTF-8"

                        // Deploy empty AWS mirror
                        sh "set +x; source /home/jenkins/.credentials set -x; source /home/jenkins/.aws set -x;source /home/jenkins/.registration set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${aws_mirror_params} --logfile ${resultdirbuild}/sumaform-aws.log ${TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend aws"
                        deployed_aws = true

                    }
                }
        )


        stage("Upload local mirror data to AWS mirror") {

            // Get local and aws hostname
            mirror_hostname_local = sh(script: "cat /home/jenkins/jenkins-build/workspace/uyuni-manager-mu-cloud/results/sumaform-local/terraform.tfstate | jq -r '.outputs.local_mirrors_public_ip.value[0][0]' ",
                    returnStdout: true).trim()
            mirror_hostname_aws_public = sh(script: "cat /home/jenkins/jenkins-build/workspace/uyuni-manager-mu-cloud/results/sumaform-aws/terraform.tfstate | jq -r '.outputs.aws_mirrors_public_name.value[0]' ",
                    returnStdout: true).trim()
            env.mirror_hostname_aws_private = sh(script: "cat /home/jenkins/jenkins-build/workspace/uyuni-manager-mu-cloud/results/sumaform-aws/terraform.tfstate | jq -r '.outputs.aws_mirrors_private_name.value[0]' ",
                    returnStdout: true).trim()

            user = 'root'
            sh "scp -o StrictHostKeyChecking=no /home/jenkins/.ssh/testing-suma.pem ${user}@${mirror_hostname_local}:/root/"
            sh "ssh -o StrictHostKeyChecking=no ${user}@${mirror_hostname_local} 'chmod 0400 /root/testing-suma.pem'"
            sh "ssh -o StrictHostKeyChecking=no ${user}@${mirror_hostname_local} 'scp -o StrictHostKeyChecking=no -r -i /root/testing-suma.pem /srv/mirror ec2-user@${mirror_hostname_aws_public}:/home/ec2-user/' "
            sh "ssh -o StrictHostKeyChecking=no -i /home/jenkins/.ssh/testing-suma.pem ec2-user@${mirror_hostname_aws_public} 'sudo cp -R /home/ec2-user/mirror/* /srv/mirror' "
        }

        stage("Deploy AWS with MU") {
            int count = 0
            // Create tfvars file with additionnal repositories using the AWS mirror
            aws_repositories = "ADDITIONAL_REPOSITORIES_LIST = {\n"
            REPOSITORIES_LIST.each { item ->
                aws_repositories = aws_repositories + "repo${count} = \"" + item.replaceAll('download.suse.de', "${mirror_hostname_aws_private}") + "\",\n"
                count = count + 1
            }

            aws_repositories = aws_repositories + "}\n" + aws_configuration
            writeFile file: "${resultdir}/sumaform-aws/terraform.tfvars", text: aws_repositories, encoding: "UTF-8"

            // Deploying AWS server using MU repositories
            sh "set +x; source /home/jenkins/.credentials set -x; source /home/jenkins/.aws set -x; source /home/jenkins/.registration set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/sumaform-aws.log ${TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend aws"
        }
    }
}

return this
