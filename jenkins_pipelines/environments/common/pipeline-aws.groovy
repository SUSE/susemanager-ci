def run(params) {
    timestamps {
        deployed = false
        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"

        // The junit plugin doesn't affect full paths
        junit_resultdir = "results/${BUILD_NUMBER}/results_junit"
        local_mirror_dir = "${resultdir}/sumaform-local"
        aws_mirror_dir = "${resultdir}/sumaform-aws"
        awscli = '/usr/local/bin/aws'
        node_user = 'jenkins'
        ssh_option = '-o StrictHostKeyChecking=no -o ConnectTimeout=7200 -o ServerAliveInterval=60'

        server_ami = null
        proxy_ami = null

        //Deployment variables
        deployed_local = false
        deployed_aws = false

        local_mirror_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/local_mirror.tf --gitfolder ${local_mirror_dir}"
        aws_mirror_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/aws_mirror.tf --gitfolder ${aws_mirror_dir}"
        env.common_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/${params.tf_file} --gitfolder ${aws_mirror_dir} --bastion_ssh_key ${params.key_file}"
        env.exports = "export BUILD_NUMBER=${BUILD_NUMBER}; export CAPYBARA_TIMEOUT=${capybara_timeout}; export DEFAULT_TIMEOUT=${default_timeout}; "

        // Upload image variables
        security_group_id = 'sg-0778949b97990ce04'
        subnet_id = 'subnet-05b9d049f3af01c38'
        image_help_ami = 'ami-0ad2088f58aad429e'



        if (params.terraform_parallelism) {
            local_mirror_params = "${local_mirror_params} --parallelism ${params.terraform_parallelism}"
            aws_mirror_params = "${aws_mirror_params} --parallelism ${params.terraform_parallelism}"
            env.common_params = "${common_params} --parallelism ${params.terraform_parallelism}"
        }
        // Public IP for AWS ingress
        String[] ALLOWED_IPS = params.allowed_IPS.split("\n")
        if (params.bastion_ssh_key_file) {
            env.common_params = "${env.common_params} --bastion_ssh_key ${params.bastion_ssh_key_file} --bastion_user ${params.bastion_username}"
            if (params.bastion_hostname) {
                env.common_params = "${env.common_params} --bastion_hostname ${params.bastion_hostname}"
            }
        }

        def previous_commit = null
        def product_commit = null
        if (params.show_product_changes) {
            // Retrieve the hash commit of the last product built in OBS/IBS and previous job
            def prefix = env.JOB_BASE_NAME.split('-acceptance-tests')[0]
            if (prefix == "uyuni-master-dev") {
                prefix = "manager-Head-dev"
            }
            // The 2obs jobs are releng, not dev
            prefix = prefix.replaceAll("-dev", "-releng")
            def request = httpRequest "https://ci.suse.de/job/${prefix}-2obs/lastBuild/api/json"
            def requestJson = readJSON text: request.getContent()
            product_commit = "${requestJson.actions.lastBuiltRevision.SHA1}"
            product_commit = product_commit.substring(product_commit.indexOf('[') + 1, product_commit.indexOf(']'));
            print "Current product commit: ${product_commit}"
            previous_commit = currentBuild.getPreviousBuild().description
            if (previous_commit == null) {
                previous_commit = product_commit
            } else {
                previous_commit = previous_commit.substring(previous_commit.indexOf('[') + 1, previous_commit.indexOf(']'));
            }
            print "Previous product commit: ${previous_commit}"
        }
        // Start pipeline
        deployed = false

        try {
            stage('Clone terracumber, susemanager-ci and sumaform') {
                if (params.show_product_changes) {
                    // Rename build using product commit hash
                    currentBuild.description =  "[${product_commit}]"
                }

                // Create a directory for  to place the directory with the build results (if it does not exist)
                sh "mkdir -p ${resultdir}"
                git url: params.terracumber_gitrepo, branch: params.terracumber_ref
                dir("susemanager-ci") {
                    checkout scm
                }
                // Clone sumaform for aws and local repositories
                sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${local_mirror_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync"
                sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync --sumaform-backend aws --runstep gitsync"
            }
            if (params.prepare_aws_env) {
                stage("Prepare AWS environment") {
                    parallel(

                            "upload_latest_image": {
                                if (params.build_image != null) {
//                                    stage('Clean old images') {
//                                        // Get all image ami ids
//                                        image_amis = sh(script: "${awscli} ec2 describe-images --filters 'Name=name,Values=SUSE-Manager-*-BYOS*' --region ${params.aws_region} | jq -r '.Images[].ImageId'",
//                                                returnStdout: true)
//                                        // Get all snapshot ids
//                                        image_snapshots = sh(script: "${awscli} ec2 describe-images --filters 'Name=name,Values=SUSE-Manager-*-BYOS*' --region ${params.aws_region} | jq -r '.Images[].BlockDeviceMappings[0].Ebs.SnapshotId'",
//                                                returnStdout: true)
//
//                                        String[] ami_list = image_amis.split("\n")
//                                        String[] snapshot_list = image_snapshots.split("\n")
//
//                                        // Deregister all BYOS images
//                                        ami_list.each { ami ->
//                                            if (ami) {
//                                                sh(script: "${awscli} ec2 deregister-image --image-id ${ami} --region ${params.aws_region}")
//                                            }
//                                        }
//                                        // Delete all BYOS snapshot
//                                        snapshot_list.each { snapshot ->
//                                            if (snapshot) {
//                                                sh(script: "${awscli} ec2 delete-snapshot --snapshot-id ${snapshot} --region ${params.aws_region}")
//                                            }
//                                        }
//                                    }

                                    stage('Download last ami image') {
                                        sh "rm -rf ${resultdir}/images"
                                        sh "mkdir -p ${resultdir}/images"

//                                        sh(script: "curl ${build_image} > images.html")
//                                        server_image_name = sh(script: "grep -oP '(?<=href=\")Manager-Server-.*BYOS.*EC2-Build.*raw.xz(?=\")' images.html", returnStdout: true).trim()
//                                        proxy_image_name = sh(script: "grep -oP '(?<=href=\")SUSE-Manager-Proxy-BYOS.*EC2-Build.*raw.xz(?=\")' images.html", returnStdout: true).trim()
                                        def server_image_name = extractBuildName(build_image)
                                        sh(script: "cd ${resultdir}/images; wget ${build_image}")
//                                        sh(script: "cd ${resultdir}/images; wget ${suma_43_build_url}${proxy_image_name}")
                                        sh(script: "ec2uploadimg -a default --backing-store ssd --machine 'x86_64' --virt-type hvm --sriov-support --wait-count 3 --ena-support --verbose --regions '${params.aws_region}' -n '${server_image_name[0]}' -d 'build image' --ssh-key-pair 'testing-suma' --private-key-file '/home/jenkins/.ssh/testing-suma.pem' --security-group-ids '${security_group_id}' --vpc-subnet ${subnet_id} --type 't2.2xlarge' --user 'ec2-user' -e '${image_help_ami}'  '${resultdir}/images/${server_image_name[1]}'")
//                                        sh(script: "ec2uploadimg -a test --backing-store ssd --machine 'x86_64' --virt-type hvm --sriov-support --ena-support --verbose --regions '${params.aws_region}' -d 'build_suma_proxy' --wait-count 3 -n '${proxy_image_name}' '${resultdir}/images/${proxy_image_name}'")
                                        env.server_ami = sh(script: "${awscli} ec2 describe-images --filters 'Name=name,Values=${server_image_name[0]}' --region ${params.aws_region}| jq -r '.Images[0].ImageId'",
                                                returnStdout: true).trim()
                                        env.proxy_ami = sh(script: "${awscli} ec2 describe-images --filters 'Name=name,Values=${proxy_image_name}' --region ${params.aws_region} | jq -r '.Images[0].ImageId'",
                                                returnStdout: true).trim()
                                    }
                                }
                            },
                            "create_local_mirror_with_mu": {
                                stage("Create local mirror with MU") {
                                    // Copy minimum repo list to mirror
                                    sh "cp ${local_mirror_dir}/salt/mirror/etc/minimum_repositories_testsuite.yaml ${local_mirror_dir}/salt/mirror/etc/minima-customize.yaml"
                                    // Deploy local mirror
                                    sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${local_mirror_params} --logfile ${resultdirbuild}/sumaform-mirror-local.log --init --taint '.*(domain|main_disk|data_disk|database_disk).*' --runstep provision --sumaform-backend libvirt"
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
                                            "NAME_PREFIX = \"${NAME_PREFIX}\"\n" +
                                            "KEY_FILE = \"${params.key_file}\"\n" +
                                            "KEY_NAME = \"${params.key_name}\"\n" +
                                            "ALLOWED_IPS = [ \n"

                                    ALLOWED_IPS.each { ip ->
                                        env.aws_configuration = aws_configuration + "    \"${ip}\",\n"
                                    }
                                    env.aws_configuration = aws_configuration + "]\n"
                                    writeFile file: "${aws_mirror_dir}/terraform.tfvars", text: aws_configuration, encoding: "UTF-8"
                                    // Deploy empty AWS mirror
                                    sh "set +x; source /home/jenkins/.credentials set -x; source /home/jenkins/.registration set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${aws_mirror_params} --logfile ${resultdirbuild}/sumaform-mirror-aws.log --init --taint '.*(domain|main_disk|data_disk|database_disk).*' --runstep provision --sumaform-backend aws"

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
                        if (params.prepare_aws_env) {
                            user = 'root'
                            sh "ssh-keygen -R ${mirror_hostname_local} -f /home/${node_user}/.ssh/known_hosts"
                            sh "scp ${ssh_option} ${params.key_file} ${user}@${mirror_hostname_local}:/root/testing-suma.pem"
                            sh "ssh ${ssh_option} ${user}@${mirror_hostname_local} 'chmod 0400 /root/testing-suma.pem'"
                            sh "ssh ${ssh_option} ${user}@${mirror_hostname_local} 'tar -czvf mirror.tar.gz -C /srv/mirror/ .'"
                            sh "ssh ${ssh_option} ${user}@${mirror_hostname_local} 'scp ${ssh_option} -i /root/testing-suma.pem /root/mirror.tar.gz ec2-user@${mirror_hostname_aws_public}:/home/ec2-user/' "
                            sh "ssh ${ssh_option} -i ${params.key_file} ec2-user@${mirror_hostname_aws_public} 'sudo tar -xvf /home/ec2-user/mirror.tar.gz -C /srv/mirror/' "
                            sh "ssh ${ssh_option} -i ${params.key_file} ec2-user@${mirror_hostname_aws_public} 'sudo rsync -a /srv/mirror/ibs/ /srv/mirror' "
                            sh "ssh ${ssh_option} -i ${params.key_file} ec2-user@${mirror_hostname_aws_public} 'sudo rsync -a /srv/mirror/download/ibs/ /srv/mirror' "
                            sh "ssh ${ssh_option} -i ${params.key_file} ec2-user@${mirror_hostname_aws_public} 'sudo rm -rf /srv/mirror/ibs' "
                            sh "ssh ${ssh_option} -i ${params.key_file} ec2-user@${mirror_hostname_aws_public} 'sudo rm -rf /srv/mirror/download/ibs' "
                        }

                    }
                }
            }
            else {
                stage("Get mirror private IP") {
                    env.mirror_hostname_aws_private = sh(script: "cat ${aws_mirror_dir}/terraform.tfstate | jq -r '.outputs.aws_mirrors_private_name.value[0]' ",
                            returnStdout: true).trim()
                }
                stage("Get uploaded image amis") {
                    env.server_ami = sh(script: "${awscli} ec2 describe-images --filters 'Name=name,Values=${server_image_name[0]}' --region ${params.aws_region}| jq -r '.Images[0].ImageId'",
                            returnStdout: true).trim()
                    env.proxy_ami = sh(script: "${awscli} ec2 describe-images --filters 'Name=name,Values=${proxy_image_name}' --region ${params.aws_region} | jq -r '.Images[0].ImageId'",
                            returnStdout: true).trim()
                }
            }

            stage('Product changes') {
                if (params.show_product_changes) {
                    sh """
                        # Comparison between:
                        #  - the previous git revision of spacewalk (or uyuni) repository pushed in IBS (or OBS)
                        #  - the git revision of the current spacewalk (or uyuni) repository pushed in IBS (or OBS)
                        # Note: This is a trade-off, we should be comparing the git revisions of all the packages composing our product
                        #       For that extra mile, we need a new tag in the repo metadata of each built, with the git revision of the related repository.
                    """
                    sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/; git --no-pager log --pretty=format:\"%h %<(16,trunc)%cn  %s  %d\" ${previous_commit}..${product_commit}'", returnStatus:true
                } else {
                    println("Product changes disabled, checkbox 'show_product_changes' was not enabled'")
                }
            }

            if (params.must_deploy) {
                stage("Deploy AWS with MU") {
                    int count = 0
                    // Replace internal repositories by mirror repositories
                    sh "sed -i 's/download.suse.de/${mirror_hostname_aws_private}/g' ${WORKSPACE}/custom_repositories.json"
                    sh "sed -i 's/ibs\\///g' ${WORKSPACE}/custom_repositories.json"

                    // Deploying AWS server using MU repositories
                    sh "echo \"export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TF_VAR_MIRROR=${env.mirror_hostname_aws_private}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; export TF_VAR_SERVER_AMI=${env.server_ami}; export TF_VAR_PROXY_AMI=${env.proxy_ami}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform-aws.log --init --taint '.*(domain|main_disk|data_disk|database_disk).*' --runstep provision --custom-repositories ${WORKSPACE}/custom_repositories.json --sumaform-backend aws\""
                    retry(count: 3) {
                        sh "set +x; source /home/jenkins/.credentials set -x; source /home/jenkins/.registration set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TF_VAR_MIRROR=${env.mirror_hostname_aws_private}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; export TF_VAR_SERVER_AMI=${env.server_ami}; export TF_VAR_PROXY_AMI=${env.proxy_ami}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform-aws.log --init --taint '.*(domain|main_disk|data_disk|database_disk).*' --runstep provision --sumaform-backend aws"
                        deployed_aws = true
                    }
                }
            }

            stage('Sanity Check') {
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${env.exports} rake cucumber:sanity_check'"
            }
            stage('Core - Setup') {
                if (params.must_run_core && (deployed_aws || !params.must_deploy)) {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${env.exports} rake cucumber:core'"
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${env.exports} rake cucumber:reposync'"
                }
            }
            stage('Core - Initialize clients') {
                if (params.must_init_clients) {
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; ${env.exports} rake ${params.rake_namespace}:init_clients'"
                }
            }
            stage('Secondary features') {
                if (params.must_secondary) {
                    def exports = ""
                    if (params.functional_scopes) {
                        exports += "export TAGS=${params.functional_scopes}; "
                    }
                    def statusCode1 = sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${exports} cd /root/spacewalk/testsuite; ${env.exports} rake cucumber:secondary'", returnStatus: true
                    def statusCode2 = sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${exports} cd /root/spacewalk/testsuite; ${env.exports} rake ${params.rake_namespace}:secondary_parallelizable'", returnStatus: true
                    def statusCode3 = sh script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd '${exports} cd /root/spacewalk/testsuite; ${env.exports} rake ${params.rake_namespace}:secondary_finishing'", returnStatus: true
                    sh "exit \$(( ${statusCode1}|${statusCode2}|${statusCode3} ))"
                }
            }
        }
        finally {
            stage('Save TF state') {
                archiveArtifacts artifacts: "results/sumaform-aws/terraform.tfstate, results/sumaform-aws/.terraform/**/*"
            }

            stage('Get results') {
                def result_error = 0
                if (deployed_aws || !params.must_deploy) {
                    try {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_finishing'"
                    } catch(Exception ex) {
                        println("ERROR: rake cucumber:build_validation_finishing failed")
                        result_error = 1
                    }
                    try {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake utils:generate_test_report'"
                    } catch(Exception ex) {
                        println("ERROR: rake utils:generate_test_report failed")
                        result_error = 1
                    }
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep getresults"
                    publishHTML(target: [
                            allowMissing         : true,
                            alwaysLinkToLastBuild: false,
                            keepAll              : true,
                            reportDir            : "${resultdirbuild}/cucumber_report/",
                            reportFiles          : 'cucumber_report.html',
                            reportName           : "Build Validation report"]
                    )
                    // junit allowEmptyResults: true, testResults: "${junit_resultdir}/*.xml"
                }
                // Send email
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/mail.log --runstep mail"
                // Clean up old results
                sh "./clean-old-results -r ${resultdir}"
                sh "exit ${error}"
            }
        }
    }
}

def extractBuildName(String url) {
    def pattern = ~/\/([^\/]*Manager-(?:Server|Proxy)-[^\/]*)-[^\/]*BYOS[^\/]*-Build(\d+\.\d+)\.raw\.xz/
    def matcher = (url =~ pattern)
    def lastIndex = url.lastIndexOf('/')
    def fileImageName = url.substring(lastIndex + 1)

    if (matcher.find()) {
        def imageName = matcher.group(1)
        def buildNumber = matcher.group(2)
        return ["${imageName}-build${buildNumber}", fileImageName]
    } else {
        return null
    }
}

return this
