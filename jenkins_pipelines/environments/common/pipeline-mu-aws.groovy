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
        suma43_build_url = "https://dist.suse.de/ibs/SUSE:/SLE-15-SP4:/Update:/Products:/Manager43/images/"
        node_user = 'maxime'

        server_ami = null
        proxy_ami = null


        //Deployment variables
        deployed_local = false
        deployed_aws = false

        local_mirror_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/local_mirror.tf --gitfolder ${local_mirror_dir}"
        aws_mirror_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/aws_mirror.tf --gitfolder ${aws_mirror_dir}"
        aws_common_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/${env.JOB_NAME}.tf --gitfolder ${aws_mirror_dir}"

        if (params.terraform_parallelism) {
            local_mirror_params = "${local_mirror_params} --parallelism ${params.terraform_parallelism}"
            aws_mirror_params = "${aws_mirror_params} --parallelism ${params.terraform_parallelism}"
            aws_common_params = "${aws_common_params} --parallelism ${params.terraform_parallelism}"
        }
        if (params.terraform_init) {
            TERRAFORM_INIT = '--init'
        } else {
            TERRAFORM_INIT = ''
        }

        // Public IP for AWS ingress
        String[] ALLOWED_IPS = params.allowed_IPS.split("\n")
        withCredentials([usernamePassword(credentialsId: 'git_credential', passwordVariable: 'git_password', usernameVariable: 'git_user')]) {
            env.TF_VAR_GIT_USER = env.git_user
            env.TF_VAR_GIT_PASSWORD = env.git_password
        }

        withCredentials([usernamePassword(credentialsId: 'scc_credential', passwordVariable: 'scc_password', usernameVariable: 'scc_user')]) {
            env.TF_VAR_SCC_USER = env.scc_user
            env.TF_VAR_SCC_PASSWORD = env.scc_password
        }

        withCredentials([usernamePassword(credentialsId: 'aws_connection', passwordVariable: 'secret_key', usernameVariable: 'access_key')]) {
            env.TF_VAR_ACCESS_KEY = env.access_key
            env.TF_VAR_SECRET_KEY = env.secret_key
        }

        withCredentials([string(credentialsId: 'proxy_registration_code', variable: 'proxy_registration_code'), string(credentialsId: 'sles_registration_code', variable: 'sles_registration_code') , string(credentialsId: 'server_registration_code', variable: 'server_registration_code')]) {
            env.TF_VAR_PROXY_REGISTRATION_CODE = env.proxy_registration_code
            env.TF_VAR_SLES_REGISTRATION_CODE = env.sles_registration_code
            env.TF_VAR_SERVER_REGISTRATION_CODE = env.server_registration_code
        }

        stage('Clone terracumber, susemanager-ci and sumaform') {
            // Create the directory for the build results
            sh "mkdir -p ${resultdir}"
            git url: params.terracumber_gitrepo, branch: params.terracumber_ref
            dir("susemanager-ci") {
                checkout scm
            }
            // Clone sumaform for aws and local repositories
//            sh "./terracumber-cli ${local_mirror_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync --sumaform-backend libvirt"
//            sh "./terracumber-cli ${aws_common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync --sumaform-backend aws"
        }


        parallel(

            "upload_latest_image": {
                if (params.use_latest_ami_image) {
                    stage('Clean old images') {
                        // Get all image ami ids
                        image_amis = sh(script: "${awscli} ec2 describe-images --filters 'Name=name,Values=SUSE-Manager-*-BYOS*' --region ${params.aws_region} | jq -r '.Images[].ImageId'",
                                returnStdout: true)
                        // Get all snapshot ids
                        image_snapshots = sh(script: "${awscli} ec2 describe-images --filters 'Name=name,Values=SUSE-Manager-*-BYOS*' --region ${params.aws_region} | jq -r '.Images[].BlockDeviceMappings[0].Ebs.SnapshotId'",
                                returnStdout: true)

                        String[] ami_list = image_amis.split("\n")
                        String[] snapshot_list = image_snapshots.split("\n")

                        // Deregister all BYOS images
                        ami_list.each { ami ->
                            if (ami) {
                                sh(script: "${awscli} ec2 deregister-image --image-id ${ami} --region ${params.aws_region}")
                            }
                        }
                        // Delete all BYOS snapshot
                        snapshot_list.each { snapshot ->
                            if (snapshot) {
                                sh(script: "${awscli} ec2 delete-snapshot --snapshot-id ${snapshot} --region ${params.aws_region}")
                            }
                        }
                    }

                    stage('Download last ami image') {
                        sh "rm -rf ${resultdir}/images"
                        sh "mkdir -p ${resultdir}/images"
                        server_image_name = sh(script: "curl ${suma43_build_url} | grep -oP '<a href=\".+?\">\\K.+?(?=<)' | grep 'SUSE-Manager-Server-BYOS.*raw.xz\$'",
                                returnStdout: true).trim()
                        proxy_image_name = sh(script: "curl ${suma43_build_url} | grep -oP '<a href=\".+?\">\\K.+?(?=<)' | grep 'SUSE-Manager-Proxy-BYOS.*raw.xz\$'",
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
            },
            "create_local_mirror_with_mu": {
                stage("Create local mirror with MU") {
                    // Save MU json into local file
                    writeFile file: "custom_repositories.json", text: params.custom_repositories, encoding: "UTF-8"
                    mu_repositories = sh(script: "cat ${WORKSPACE}/custom_repositories.json | jq -r ' to_entries[] |  \" \\(.value)\"' | jq -r ' to_entries[] |  \" \\(.value)\"'",
                            returnStdout: true)
                    // Get the testsuite defaults repositories list
                    repositories = sh(script: "cat ${local_mirror_dir}/salt/mirror/utils/minimum_repositories_testsuite.yaml",
                            returnStdout: true)
                    if ( !mu_repositories.isEmpty() ) {
                        String[] REPOSITORIES_LIST = mu_repositories.split("\n")
                        // Add MU repositories to the repository list
                        REPOSITORIES_LIST.each { item ->
                            repositories = "${repositories}\n\n" +
                                    "  - url: ${item}\n" +
                                    "    archs: [x86_64]"
                        }
                    }
                    writeFile file: "${local_mirror_dir}/salt/mirror/etc/minima-customize.yaml", text: repositories, encoding: "UTF-8"

                    // Deploy local mirror
//                    sh "export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${local_mirror_params} --logfile ${resultdirbuild}/sumaform-mirror-local.log ${TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend libvirt"
                    deployed_local = true

                }
            },
//            "create_empty_aws_mirror": {
//                stage("Create empty AWS mirror") {
//                    // Fix issue where result folder is created at the same time by local mirror and aws mirror
//                    sleep(30)
//                    NAME_PREFIX = env.JOB_NAME.toLowerCase().replace('.','-')
//                    env.aws_configuration = "REGION = \"${params.aws_region}\"\n" +
//                            "AVAILABILITY_ZONE = \"${params.aws_availability_zone}\"\n" +
//                            "NAME_PREFIX = \"${NAME_PREFIX}-\"\n" +
//                            "ALLOWED_IPS = [ \n"
//
//                    ALLOWED_IPS.each { ip ->
//                        env.aws_configuration = aws_configuration + "    \"${ip}\",\n"
//                    }
//                    env.aws_configuration = aws_configuration + "]\n"
//                    writeFile file: "${aws_mirror_dir}/terraform.tfvars", text: aws_configuration, encoding: "UTF-8"
//                    // Deploy empty AWS mirror
//                    sh "export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${aws_mirror_params} --logfile ${resultdirbuild}/sumaform-mirror-aws.log ${TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend aws"
//                    deployed_aws = true
//
//                }
//            }
        )

//        stage("Upload local mirror data to AWS mirror") {
//
//            // Get local and aws hostname
//            mirror_hostname_local = sh(script: "cat ${local_mirror_dir}/terraform.tfstate | jq -r '.outputs.local_mirrors_public_ip.value[0][0]' ",
//                    returnStdout: true).trim()
//            mirror_hostname_aws_public = sh(script: "cat ${aws_mirror_dir}/terraform.tfstate | jq -r '.outputs.aws_mirrors_public_name.value[0]' ",
//                    returnStdout: true).trim()
//            env.mirror_hostname_aws_private = sh(script: "cat ${aws_mirror_dir}/terraform.tfstate | jq -r '.outputs.aws_mirrors_private_name.value[0]' ",
//                    returnStdout: true).trim()
//
//            user = 'root'
//            sh "ssh-keygen -R ${mirror_hostname_local} -f /home/${node_user}/.ssh/known_hosts"
//            sh "scp -o StrictHostKeyChecking=no /home/${node_user}/.ssh/testing-suma.pem ${user}@${mirror_hostname_local}:/root/"
//            sh "ssh -o StrictHostKeyChecking=no ${user}@${mirror_hostname_local} 'chmod 0400 /root/testing-suma.pem'"
//            sh "ssh -o StrictHostKeyChecking=no ${user}@${mirror_hostname_local} 'tar -czvf mirror.tar.gz -C /srv/mirror/ .'"
//            sh "ssh -o StrictHostKeyChecking=no ${user}@${mirror_hostname_local} 'scp -o StrictHostKeyChecking=no -i /root/testing-suma.pem /root/mirror.tar.gz ec2-user@${mirror_hostname_aws_public}:/home/ec2-user/' "
//            sh "ssh -o StrictHostKeyChecking=no -i /home/${node_user}/.ssh/testing-suma.pem ec2-user@${mirror_hostname_aws_public} 'sudo tar -xvf /home/ec2-user/mirror.tar.gz -C /srv/mirror/' "
//            sh "ssh -o StrictHostKeyChecking=no -i /home/${node_user}/.ssh/testing-suma.pem ec2-user@${mirror_hostname_aws_public} 'sudo mv /srv/mirror/ibs/* /srv/mirror/' "
//            sh "ssh -o StrictHostKeyChecking=no -i /home/${node_user}/.ssh/testing-suma.pem ec2-user@${mirror_hostname_aws_public} 'sudo rm -rf /srv/mirror/ibs' "
//
//        }

//        stage("Deploy AWS with MU") {
//            int count = 0
//            // Replace internal repositories by mirror repositories
//            sh "sed -i 's/download.suse.de/${mirror_hostname_aws_private}/g' ${WORKSPACE}/custom_repositories.json"
//            sh "sed -r 's/ibs\\///g' ${WORKSPACE}/custom_repositories.json"
//
//            // Deploying AWS server using MU repositories
//            sh "echo \"export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TF_VAR_MIRROR=${env.mirror_hostname_aws_private}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; export TF_VAR_SERVER_AMI=${env.server_ami}; export TF_VAR_PROXY_AMI=${env.proxy_ami}; ./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/sumaform-aws.log ${TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend aws --bastion_ssh_key /home/${node_user}/.ssh/testing-suma.pem\""
//            sh "export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TF_VAR_MIRROR=${env.mirror_hostname_aws_private}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; export TF_VAR_SERVER_AMI=${env.server_ami}; export TF_VAR_PROXY_AMI=${env.proxy_ami}; ./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/sumaform-aws.log ${TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend aws --bastion_ssh_key /home/${node_user}/.ssh/testing-suma.pem"
//        }
    }
}

return this
