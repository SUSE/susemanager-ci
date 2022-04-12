def run(params) {

    timestamps {

        // Environment variables
        resultdir = "${WORKSPACE}/results"
        resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        // The junit plugin doesn't affect full paths
        junit_resultdir = "results/${BUILD_NUMBER}/results_junit"
        local_mirror_dir = "${resultdir}/sumaform-local"
        aws_mirror_dir = "${resultdir}/sumaform-aws"
        awscli = '/usr/local/bin/aws'

        server_ami = null
        proxy_ami = null


        //Deployment variables
        deployed_local = false
        deployed_aws = false
        local_mirror_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/local_mirror.tf --gitfolder ${local_mirror_dir}"
        aws_mirror_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/aws_mirror.tf --gitfolder ${aws_mirror_dir}"
        aws_common_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/${env.JOB_NAME}.tf --gitfolder ${aws_mirror_dir}"
        if (params.terraform_init) {
            TERRAFORM_INIT = '--init'
        } else {
            TERRAFORM_INIT = ''
        }

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

        if (params.use_latest_ami_image) {
            stage('Clean old images') {
                // Get all image ami ids
                image_amis = sh(script: "${awscli} ec2 describe-images --filters 'Name=name,Values=SUSE-Manager-*-BYOS*' --region ${params.aws_region} | jq -r '.Images[].ImageId'",
                        returnStdout: true)
                // Get all snapshot ids
                image_snapshots = sh(script: "${awscli} ec2 describe-images --filters 'Name=name,Values=SUSE-Manager-*-BYOS*' --region ${params.aws_region} | jq -r '.Images[].BlockDeviceMappings[0].SnapshotId'",
                        returnStdout: true)

                String[] AMI_LIST = image_amis.split("\n")
                String[] SNAPSHOT_LIST = image_snapshots.split("\n")

                // Deregister all BYOS images
                AMI_LIST.each { ami ->
                    sh(script: "${awscli} ec2 deregister-image --image-id ${ami} --region ${params.aws_region}")
                }
                // Delete all BYOS snapshot
                SNAPSHOT_LIST.each { snapshot ->
                    sh(script: "${awscli} ec2 delete-snapshot --snapshot-id ${snapshot} --region ${params.aws_region}")
                }
            }

            stage('Download last ami image') {
                sh "rm -rf ${resultdir}/images"
                sh "mkdir -p ${resultdir}/images"
                server_image_name = sh(script: "curl https://dist.suse.de/ibs/SUSE:/SLE-15-SP4:/Update:/Products:/Manager43/images/ | grep -oP '<a href=\".+?\">\\K.+?(?=<)' | grep 'SUSE-Manager-Server-BYOS.*raw.xz\$'",
                        returnStdout: true).trim()
                proxy_image_name = sh(script: "curl https://dist.suse.de/ibs/SUSE:/SLE-15-SP4:/Update:/Products:/Manager43/images/ | grep -oP '<a href=\".+?\">\\K.+?(?=<)' | grep 'SUSE-Manager-Proxy-BYOS.*raw.xz\$'",
                        returnStdout: true).trim()
                sh(script: "cd ${resultdir}/images; wget https://dist.suse.de/ibs/SUSE:/SLE-15-SP4:/Update:/Products:/Manager43/images/${server_image_name}")
                sh(script: "cd ${resultdir}/images; wget https://dist.suse.de/ibs/SUSE:/SLE-15-SP4:/Update:/Products:/Manager43/images/${proxy_image_name}")
                sh(script: "ec2uploadimg -f /home/jenkins/.ec2utils.conf -a test --backing-store ssd --machine 'x86_64' --virt-type hvm --sriov-support --ena-support --verbose --regions '${params.aws_region}' -d 'build_suma_server' --wait-count 3 -n '${server_image_name}' '${resultdir}/images/${server_image_name}'")
                sh(script: "ec2uploadimg -f /home/jenkins/.ec2utils.conf -a test --backing-store ssd --machine 'x86_64' --virt-type hvm --sriov-support --ena-support --verbose --regions '${params.aws_region}' -d 'build_suma_proxy' --wait-count 3 -n '${proxy_image_name}' '${resultdir}/images/${proxy_image_name}'")
                env.server_ami = sh(script: "${awscli} ec2 describe-images --filters 'Name=name,Values=${server_image_name}' --region ${params.aws_region}| jq -r '.Images[0].ImageId'",
                        returnStdout: true).trim()
                env.proxy_ami = sh(script: "${awscli} ec2 describe-images --filters 'Name=name,Values=${proxy_image_name}' --region ${params.aws_region} | jq -r '.Images[0].ImageId'",
                        returnStdout: true).trim()
            }
        }


        parallel(
                "create_local_mirror_with_mu": {
                    stage("Create local mirror with MU") {
                        writeFile file: "custom_repositories.json", text: params.custom_repositories, encoding: "UTF-8"
                        mu_repositories = sh(script: "cat ${WORKSPACE}/custom_repositories.json | jq -r ' to_entries[] |  \" \\(.value)\"' | jq -r ' to_entries[] |  \" \\(.value)\"'",
                                returnStdout: true)
                        String[] REPOSITORIES_LIST = mu_repositories.split("\n")
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
                        writeFile file: "${local_mirror_dir}/salt/mirror/etc/minima-customize.yaml", text: repositories, encoding: "UTF-8"

                        // Deploy local mirror
                        sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${local_mirror_params} --logfile ${resultdirbuild}/sumaform-local.log ${TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend libvirt"
                        deployed_local = true

                    }
                },
                "create_empty_aws_mirror": {
                    stage("Create empty AWS mirror") {
                        env.aws_configuration = "REGION = \"${params.aws_region}\"\n" +
                                "AVAILABILITY_ZONE = \"${params.aws_availability_zone}\"\n" +
                                "NAME_PREFIX = \"${env.JOB_NAME}-\"\n" +
                                "ALLOWED_IPS = [ \n"

                        ALLOWED_IPS.each { ip ->
                            env.aws_configuration = aws_configuration + "    \"${ip}\",\n"
                        }

                        env.aws_configuration = aws_configuration + "]\n"
                        writeFile file: "${aws_mirror_dir}/terraform.tfvars", text: aws_configuration, encoding: "UTF-8"

                        // Deploy empty AWS mirror
                        sh "set +x; source /home/jenkins/.credentials set -x; source /home/jenkins/.aws/.aws set -x;source /home/jenkins/.registration set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${aws_mirror_params} --logfile ${resultdirbuild}/sumaform-aws.log ${TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend aws"
                        deployed_aws = true

                    }
                }
        )


        stage("Upload local mirror data to AWS mirror") {

            // Get local and aws hostname
            mirror_hostname_local = sh(script: "cat ${local_mirror_dir}/terraform.tfstate | jq -r '.outputs.local_mirrors_public_ip.value[0][0]' ",
                    returnStdout: true).trim()
            mirror_hostname_aws_public = sh(script: "cat ${aws_mirror_dir}/terraform.tfstate | jq -r '.outputs.aws_mirrors_public_name.value[0]' ",
                    returnStdout: true).trim()
            env.mirror_hostname_aws_private = sh(script: "cat ${aws_mirror_dir}/terraform.tfstate | jq -r '.outputs.aws_mirrors_private_name.value[0]' ",
                    returnStdout: true).trim()

            user = 'root'
            sh "ssh-keygen -R ${mirror_hostname_local} -f /home/jenkins/.ssh/known_hosts"
            sh "scp -o StrictHostKeyChecking=no /home/jenkins/.ssh/testing-suma.pem ${user}@${mirror_hostname_local}:/root/"
            sh "ssh -o StrictHostKeyChecking=no ${user}@${mirror_hostname_local} 'chmod 0400 /root/testing-suma.pem'"
            sh "ssh -o StrictHostKeyChecking=no ${user}@${mirror_hostname_local} 'tar -czvf mirror.tar.gz -C /srv/mirror/ .'"
            sh "ssh -o StrictHostKeyChecking=no ${user}@${mirror_hostname_local} 'scp -o StrictHostKeyChecking=no -i /root/testing-suma.pem /root/mirror.tar.gz ec2-user@${mirror_hostname_aws_public}:/home/ec2-user/' "
            sh "ssh -o StrictHostKeyChecking=no -i /home/jenkins/.ssh/testing-suma.pem ec2-user@${mirror_hostname_aws_public} 'sudo tar -xvf /home/ec2-user/mirror.tar.gz -C /srv/mirror/' "
            sh "ssh -o StrictHostKeyChecking=no -i /home/jenkins/.ssh/testing-suma.pem ec2-user@${mirror_hostname_aws_public} 'sudo mv /srv/mirror/ibs/* /srv/mirror/' "
            sh "ssh -o StrictHostKeyChecking=no -i /home/jenkins/.ssh/testing-suma.pem ec2-user@${mirror_hostname_aws_public} 'sudo rm -rf /srv/mirror/ibs' "

        }

        stage("Deploy AWS with MU") {
            int count = 0
            // Replace internal repositories by mirror repositories
            sh "sed -i 's/download.suse.de/${mirror_hostname_aws_private}/g' ${WORKSPACE}/custom_repositories.json"
            sh "sed -r 's/ibs\\///g' ${WORKSPACE}/custom_repositories.json"

            // Deploying AWS server using MU repositories
            sh "set +x; source /home/jenkins/.credentials set -x; source /home/jenkins/.aws/.aws set -x; source /home/jenkins/.registration set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TF_VAR_MIRROR=${env.mirror_hostname_aws_private}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; export TF_VAR_SERVER_AMI=${env.server_ami}; export TF_VAR_PROXY_AMI=${env.proxy_ami}; ./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/sumaform-aws.log ${TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend aws --bastion_ssh_key /home/jenkins/.ssh/testing-suma.pem"
        }
    }
}

return this
