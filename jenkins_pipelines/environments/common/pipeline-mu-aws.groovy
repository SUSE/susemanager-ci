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
        node_user = 'jenkins'
        build_validation = true
        ssh_option = '-o StrictHostKeyChecking=no -o ConnectTimeout=7200 -o ServerAliveInterval=60'

        server_ami = null
        proxy_ami = null


        //Deployment variables
        deployed_local = false
        deployed_aws = false

        local_mirror_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/local_mirror.tf --gitfolder ${local_mirror_dir}"
        aws_mirror_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/aws_mirror.tf --gitfolder ${aws_mirror_dir}"
        aws_common_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/${params.tf_file} --gitfolder ${aws_mirror_dir} --bastion_ssh_key ${params.key_file}"

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
//        withCredentials([usernamePassword(credentialsId: 'git_credential', passwordVariable: 'git_password', usernameVariable: 'git_user')]) {
//            env.TF_VAR_GIT_USER = env.git_user
//            env.TF_VAR_GIT_PASSWORD = env.git_password
//        }
//
//        withCredentials([usernamePassword(credentialsId: 'scc_credential', passwordVariable: 'scc_password', usernameVariable: 'scc_user')]) {
//            env.TF_VAR_SCC_USER = env.scc_user
//            env.TF_VAR_SCC_PASSWORD = env.scc_password
//        }
//
//        withCredentials([usernamePassword(credentialsId: 'aws_connection', passwordVariable: 'secret_key', usernameVariable: 'access_key')]) {
//            env.TF_VAR_ACCESS_KEY = env.access_key
//            env.TF_VAR_SECRET_KEY = env.secret_key
//        }
//
//        withCredentials([string(credentialsId: 'proxy_registration_code', variable: 'proxy_registration_code'), string(credentialsId: 'sles_registration_code', variable: 'sles_registration_code'), string(credentialsId: 'server_registration_code', variable: 'server_registration_code'), string(credentialsId: 'token_aws', variable: 'token_aws')]) {
//            env.TF_VAR_PROXY_REGISTRATION_CODE = env.proxy_registration_code
//            env.TF_VAR_SLES_REGISTRATION_CODE = env.sles_registration_code
//            env.TF_VAR_SERVER_REGISTRATION_CODE = env.server_registration_code
//            env.TF_VAR_TOKEN_AWS = env.token_aws
//        }

        stage('Clone terracumber, susemanager-ci and sumaform') {
            // Create the directory for the build results
            sh "mkdir -p ${resultdir}"
            git url: params.terracumber_gitrepo, branch: params.terracumber_ref
            dir("susemanager-ci") {
                checkout scm
            }
            // Clone sumaform for aws and local repositories
            sh "./terracumber-cli ${local_mirror_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync --sumaform-backend libvirt"
            sh "./terracumber-cli ${aws_common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync --sumaform-backend aws"
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
                        repositories = sh(script: "cat ${local_mirror_dir}/salt/mirror/etc/minimum_repositories_testsuite.yaml",
                                returnStdout: true)
                        if (!mu_repositories.isEmpty()) {
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
                        sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${local_mirror_params} --logfile ${resultdirbuild}/sumaform-mirror-local.log ${TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend libvirt"
                        deployed_local = true

                    }
                },
                "create_empty_aws_mirror": {
                    stage("Create empty AWS mirror") {
                        // Fix issue where result folder is created at the same time by local mirror and aws mirror
                        sleep(30)
                        NAME_PREFIX = env.JOB_NAME.toLowerCase().replace('.', '-')
                        env.aws_configuration = "REGION = \"${params.aws_region}\"\n" +
                                "AVAILABILITY_ZONE = \"${params.aws_availability_zone}\"\n" +
                                "NAME_PREFIX = \"${NAME_PREFIX}-\"\n" +
                                "KEY_FILE = \"${params.key_file}\"\n" +
                                "KEY_NAME = \"${params.key_name}\"\n" +
                                "ALLOWED_IPS = [ \n"

                        ALLOWED_IPS.each { ip ->
                            env.aws_configuration = aws_configuration + "    \"${ip}\",\n"
                        }
                        env.aws_configuration = aws_configuration + "]\n"
                        writeFile file: "${aws_mirror_dir}/terraform.tfvars", text: aws_configuration, encoding: "UTF-8"
                        // Deploy empty AWS mirror
                        sh "set +x; source /home/jenkins/.credentials set -x; source /home/jenkins/.registration set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${aws_mirror_params} --logfile ${resultdirbuild}/sumaform-mirror-aws.log ${TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend aws"
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
            sh "ssh-keygen -R ${mirror_hostname_local} -f /home/${node_user}/.ssh/known_hosts"
            sh "scp ${ssh_option} ${params.key_file} ${user}@${mirror_hostname_local}:/root/testing-suma.pem"
            sh "ssh ${ssh_option} ${user}@${mirror_hostname_local} 'chmod 0400 /root/testing-suma.pem'"
            sh "ssh ${ssh_option} ${user}@${mirror_hostname_local} 'tar -czvf mirror.tar.gz -C /srv/mirror/ .'"
            sh "ssh ${ssh_option} ${user}@${mirror_hostname_local} 'scp ${ssh_option} -i /root/testing-suma.pem /root/mirror.tar.gz ec2-user@${mirror_hostname_aws_public}:/home/ec2-user/' "
            sh "ssh ${ssh_option} -i ${params.key_file} ec2-user@${mirror_hostname_aws_public} 'sudo tar -xvf /home/ec2-user/mirror.tar.gz -C /srv/mirror/' "
            sh "ssh ${ssh_option} -i ${params.key_file} ec2-user@${mirror_hostname_aws_public} 'sudo rsync -a /srv/mirror/ibs/ /srv/mirror' "
            sh "ssh ${ssh_option} -i ${params.key_file} ec2-user@${mirror_hostname_aws_public} 'sudo rm -rf /srv/mirror/ibs' "

        }

        stage("Deploy AWS with MU") {
            int count = 0
            // Replace internal repositories by mirror repositories
            sh "sed -i 's/download.suse.de/${mirror_hostname_aws_private}/g' ${WORKSPACE}/custom_repositories.json"
            sh "sed -i 's/ibs\\///g' ${WORKSPACE}/custom_repositories.json"

            // Deploying AWS server using MU repositories
            sh "echo \"export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TF_VAR_MIRROR=${env.mirror_hostname_aws_private}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; export TF_VAR_SERVER_AMI=${env.server_ami}; export TF_VAR_PROXY_AMI=${env.proxy_ami}; ./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/sumaform-aws.log ${TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --custom-repositories ${WORKSPACE}/custom_repositories.json --sumaform-backend aws\""
            sh "set +x; source /home/jenkins/.credentials set -x; source /home/jenkins/.registration set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TF_VAR_MIRROR=${env.mirror_hostname_aws_private}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; export TF_VAR_SERVER_AMI=${env.server_ami}; export TF_VAR_PROXY_AMI=${env.proxy_ami}; ./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/sumaform-aws.log ${TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --custom-repositories ${WORKSPACE}/custom_repositories.json --runstep provision --sumaform-backend aws"
        }
        if (build_validation) {
            stage('Generate build validation feature') {
                sh "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake utils:generate_build_validation_features'"
                deployed = true
            }

            stage('Sanity check') {
                sh "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:build_validation_sanity_check'"
            }

            stage('Run core features') {
                sh "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_core'"
            }

            stage('Sync. products and channels') {
                res_products = sh(script: "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_reposync'", returnStatus: true)
                echo "Custom channels and MU repositories status code: ${res_products}"
                res_sync_products = sh(script: "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_wait_for_product_reposync'", returnStatus: true)
                echo "Custom channels and MU repositories synchronization status code: ${res_sync_products}"
                sh "exit \$(( ${res_products}|${res_sync_products} ))"
            }

            stage('Add Common Channels') {
                echo 'Add common channels'
                res_common_channels = sh(script: "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_add_common_channels'", returnStatus: true)
                echo "Custom channels and MU repositories status code: ${res_common_channels}"
                res_sync_common_channels = sh(script: "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_wait_for_custom_reposync'", returnStatus: true)
                echo "Common channels synchronization status code: ${res_sync_common_channels}"
                sh "exit \$(( ${res_common_channels}|${res_sync_common_channels} ))"
            }

            stage('Add MUs') {
                echo 'Add custom channels and MU repositories'
                res_mu_repos = sh(script: "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_add_custom_repositories'", returnStatus: true)
                echo "Custom channels and MU repositories status code: ${res_mu_repos}"
                res_sync_mu_repos = sh(script: "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_wait_for_custom_reposync'", returnStatus: true)
                echo "Custom channels and MU repositories synchronization status code: ${res_sync_mu_repos}"
                sh "exit \$(( ${res_mu_repos}|${res_sync_mu_repos} ))"
            }

            stage('Add Activation Keys') {
                echo 'Add Activation Keys'
                res_add_keys = sh(script: "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_add_activation_keys'", returnStatus: true)
                echo "Add Activation Keys status code: ${res_add_keys}"
            }

            stage('Create bootstrap repositories') {
                echo 'Create bootstrap repositories'
                res_create_bootstrap_repos = sh(script: "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_create_bootstrap_repositories'", returnStatus: true)
                echo "Create bootstrap repositories code: ${res_create_bootstrap_repos}"
            }

            stage('Bootstrap Proxy') {
                echo 'Proxy register as minion with gui'
                res_init_proxy = sh(script: "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_init_proxy'", returnStatus: true)
                echo "Init Proxy status code: ${res_init_proxy}"
            }

            stage('Bootstrap clients') {
                echo 'Bootstrap clients'
                res_init_clients = sh(script: "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export CAPYBARA_TIMEOUT=${params.capybara_timeout}; export DEFAULT_TIMEOUT=${params.default_timeout}; export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_init_clients'", returnStatus: true)
                echo "Init clients status code: ${res_init_clients}"

            }

            stage('Run Smoke Tests') {
                echo 'Run Smoke tests'
                res_smoke_tests = sh(script: "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export CAPYBARA_TIMEOUT=${params.capybara_timeout}; export DEFAULT_TIMEOUT=${params.default_timeout}; export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_smoke_tests'", returnStatus: true)
                echo "Smoke tests status code: ${res_smoke_tests}"
            }
            stage('Get results') {
                def error = 0
                if (deployed || !params.must_deploy) {
                    try {
                        sh "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_finishing'"
                    } catch(Exception ex) {
                        println("ERROR: rake cucumber:build_validation_finishing failed")
                        error = 1
                    }
                    try {
                        sh "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake utils:generate_test_report'"
                    } catch(Exception ex) {
                        println("ERROR: rake utils:generate_test_report failed")
                        error = 1
                    }
                    sh "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/testsuite.log --runstep getresults"
                    publishHTML( target: [
                            allowMissing: true,
                            alwaysLinkToLastBuild: false,
                            keepAll: true,
                            reportDir: "${resultdirbuild}/cucumber_report/",
                            reportFiles: 'cucumber_report.html',
                            reportName: "Build Validation report"]
                    )
                    // junit allowEmptyResults: true, testResults: "${junit_resultdir}/*.xml"
                }
                // Send email
                sh "./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/mail.log --runstep mail"
                // Clean up old results
                sh "./clean-old-results -r ${resultdir}"
                sh "exit ${error}"
            }
        }
    }
}

return this
