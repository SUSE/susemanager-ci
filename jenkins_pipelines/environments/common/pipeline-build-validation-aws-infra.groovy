// Deploys the AWS infrastructure shared by the AWS build validation pipelines (VPC, private network, bastion and mirror),
// fills a libvirt mirror on suma-05 with the testsuite and custom repositories, then rsyncs it to the AWS mirror.
// The AWS mirror is private: every SSH connection to it goes through the bastion.
// With deploy_mirrors unset, only the VPC, private network and bastion are deployed.
def run(params) {
    ansiColor('xterm') {
        timestamps {
            env.resultdir = "${WORKSPACE}/results"
            env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
            def local_mirror_dir = "${resultdir}/sumaform-local"
            def aws_infra_dir = "${resultdir}/sumaform-aws-infra"
            def ssh_option = '-o StrictHostKeyChecking=no -o ConnectTimeout=7200 -o ServerAliveInterval=60'
            def json_generator_version = params.json_generator_version ?: ''
            def deploy_mirrors = params.deploy_mirrors as boolean

            // The new Jenkins has no /home/jenkins/.credentials on its agents: the same content is provided by
            // the sumaform-secrets credential and sourced from a temporary file. No registration codes are needed here.
            def credInit = 'set +x; credFile=$(mktemp); echo "$SECRET_CONTENT" > "${credFile}"; chmod 600 "${credFile}"; . "${credFile}"; rm -f "${credFile}"; set -x'
            def withCreds = { Closure body ->
                withCredentials([string(credentialsId: 'sumaform-secrets', variable: 'SECRET_CONTENT')]) { body() }
            }

            def local_mirror_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/local_mirror.tf --gitfolder ${local_mirror_dir} --terraform-bin ${params.bin_path}"
            def aws_infra_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/aws_mirror.tf --gitfolder ${aws_infra_dir} --terraform-bin ${params.bin_path}"
            if (params.deploy_parallelism) {
                local_mirror_params = "${local_mirror_params} --parallelism ${params.deploy_parallelism}"
                aws_infra_params = "${aws_infra_params} --parallelism ${params.deploy_parallelism}"
            }

            // Destroy what the last deployments created on this agent, using the states and tfvars they left in the workspace.
            // The server pipelines environments must be destroyed first, as they use the VPC and subnets.
            if (params.destroy_environment) {
                if (!params.confirm_destroy) {
                    error("destroy_environment requires confirm_destroy to be checked too")
                }
                stage('Destroy environment') {
                    def dirs = [local_mirror_dir, aws_infra_dir].findAll { fileExists("${it}/terraform.tfstate") }
                    if (!dirs) {
                        error("No terraform state in ${local_mirror_dir} nor ${aws_infra_dir} on this agent: nothing to destroy")
                    }
                    dirs.each { tf_dir ->
                        withCreds {
                            sh "${credInit}; cd ${tf_dir}; ${params.bin_path} init; ${params.bin_path} destroy -auto-approve"
                        }
                        sh "rm -rf ${tf_dir}"
                    }
                    currentBuild.description = "infrastructure destroyed"
                }
                return
            }

            try {
                stage('Clone terracumber, susemanager-ci and sumaform') {
                    sh "mkdir -p ${resultdir}"
                    git url: params.terracumber_gitrepo, branch: params.terracumber_ref
                    dir("susemanager-ci") {
                        checkout scm
                    }
                    if (deploy_mirrors) {
                        sh "./terracumber-cli ${local_mirror_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync --sumaform-backend libvirt"
                    }
                    sh "./terracumber-cli ${aws_infra_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync --sumaform-backend aws"
                }

                stage('Deploy infrastructure') {
                    def branches = [:]
                    if (deploy_mirrors) {
                        branches["create_local_mirror_with_mu"] = {
                            stage("Create local mirror with MU") {
                                // Generate custom_repositories.json file in the workspace from the value passed by parameter
                                if (params.custom_repositories?.trim()) {
                                    writeFile file: 'custom_repositories.json', text: params.custom_repositories, encoding: "UTF-8"
                                }
                                // Generate custom_repositories.json file in the workspace using a Python script - MI Identifiers passed by parameter
                                if (params.mi_ids?.trim()) {
                                    if (!json_generator_version) {
                                        error("json_generator_version is not set for this environment, cannot generate custom_repositories.json from mi_ids")
                                    }
                                    node('manager-jenkins-node') {
                                        checkout scm
                                        def res_python_script_ = sh(script: "python3 jenkins_pipelines/scripts/json_generator/maintenance_json_generator.py --version ${json_generator_version} --mi_ids ${params.mi_ids} --no_embargo", returnStatus: true)
                                        echo "Build Validation JSON script return code:\n ${res_python_script_}"
                                        if (res_python_script_ != 0) {
                                            error("MI IDs (${params.mi_ids}) passed by parameter are wrong, already released or all under embargo")
                                        }
                                    }
                                }
                                // Add the MU repositories to the testsuite default repositories list
                                def mu_repositories = sh(script: "cat ${WORKSPACE}/custom_repositories.json | jq -r ' to_entries[] |  \" \\(.value)\"' | jq -r ' to_entries[] |  \" \\(.value)\"'",
                                        returnStdout: true)
                                def repositories = sh(script: "cat ${local_mirror_dir}/salt/mirror/etc/minimum_repositories_testsuite.yaml",
                                        returnStdout: true)
                                if (!mu_repositories.isEmpty()) {
                                    mu_repositories.split("\n").each { item ->
                                        repositories = "${repositories}\n\n" +
                                                "  - url: ${item}\n" +
                                                "    archs: [x86_64]"
                                    }
                                }
                                writeFile file: "${local_mirror_dir}/salt/mirror/etc/minima-customize.yaml", text: repositories, encoding: "UTF-8"

                                // The local mirror is recreated at every run
                                withCreds {
                                    sh "${credInit}; export TERRAFORM=${params.bin_path}; export TERRAFORM_PLUGINS=${params.bin_plugins_path}; ./terracumber-cli ${local_mirror_params} --logfile ${resultdirbuild}/sumaform-mirror-local.log --init --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend libvirt"
                                }
                            }
                        }
                    }
                    branches["create_aws_infrastructure"] = {
                        stage("Create AWS infrastructure") {
                            // Fix issue where result folder is created at the same time by local mirror and aws mirror
                            if (deploy_mirrors) {
                                sleep(30)
                            }
                            def aws_configuration = "REGION = \"${params.aws_region}\"\n" +
                                    "MIRROR_ENABLED = ${deploy_mirrors}\n" +
                                    "AVAILABILITY_ZONE = \"${params.aws_availability_zone}\"\n" +
                                    "NAME_PREFIX = \"${params.infra_name_prefix}\"\n" +
                                    "KEY_FILE = \"${params.key_file}\"\n" +
                                    "KEY_NAME = \"${params.key_name}\"\n" +
                                    "ALLOWED_IPS = [\n"
                            params.allowed_IPS.split("\n").each { ip ->
                                if (ip.trim()) {
                                    aws_configuration += "    \"${ip.trim()}\",\n"
                                }
                            }
                            aws_configuration += "]\n"
                            writeFile file: "${aws_infra_dir}/terraform.tfvars", text: aws_configuration, encoding: "UTF-8"
                            // The AWS infrastructure is persistent: no taint, existing resources are kept and only updated
                            withCreds {
                                sh "${credInit}; export TERRAFORM=${params.bin_path}; export TERRAFORM_PLUGINS=${params.bin_plugins_path}; ./terracumber-cli ${aws_infra_params} --logfile ${resultdirbuild}/sumaform-mirror-aws.log --init --runstep provision --sumaform-backend aws"
                            }
                        }
                    }
                    parallel(branches)
                }

                def bastion_hostname = sh(script: "jq -r '.outputs.bastion_public_name.value' ${aws_infra_dir}/terraform.tfstate", returnStdout: true).trim()
                currentBuild.description = "bastion: ${bastion_hostname}"

                stage("Sync local mirror to AWS mirror") {
                    if (!deploy_mirrors) {
                        echo "Mirrors not deployed, skipping"
                        return
                    }
                    def mirror_address_local = sh(script: "jq -r '.outputs.local_mirrors_public_ip.value[0][0]' ${local_mirror_dir}/terraform.tfstate", returnStdout: true).trim()
                    def mirror_hostname_aws = sh(script: "jq -r '.outputs.aws_mirrors_private_name.value[0]' ${aws_infra_dir}/terraform.tfstate", returnStdout: true).trim()
                    currentBuild.description = "mirror: ${mirror_hostname_aws}<br>bastion: ${bastion_hostname}"

                    // The local mirror reaches the AWS mirror through the bastion: its public IP must be in allowed_IPS
                    writeFile file: 'aws_ssh_config', encoding: "UTF-8", text: """\
                        Host *
                          User ec2-user
                          IdentityFile /root/testing-suma.pem
                          StrictHostKeyChecking no
                          ServerAliveInterval 60
                        Host aws-mirror
                          HostName ${mirror_hostname_aws}
                          ProxyJump ${bastion_hostname}
                        """.stripIndent()

                    sh "ssh-keygen -R ${mirror_address_local} -f /home/jenkins/.ssh/known_hosts"
                    // Private half of the key the local mirror authorizes (SSH_KEY in local_mirror.tf): ssh refuses it unless private
                    def local_key = sh(script: "jq -r '.outputs.local_mirror_ssh_private_key.value' ${local_mirror_dir}/terraform.tfstate", returnStdout: true).trim()
                    sh "chmod 600 ${local_key}"
                    // IPv6 addresses need to be enclosed in [ ] to not be interpreted as hostnames by scp
                    def mirror_address_scp = mirror_address_local.contains(":") ? "[${mirror_address_local}]" : mirror_address_local
                    def local_ssh = "ssh ${ssh_option} -i ${local_key} root@${mirror_address_local}"
                    sh "scp ${ssh_option} -i ${local_key} ${params.key_file} root@${mirror_address_scp}:/root/testing-suma.pem"
                    sh "scp ${ssh_option} -i ${local_key} aws_ssh_config root@${mirror_address_scp}:/root/.ssh/config"
                    sh "${local_ssh} 'chmod 0400 /root/testing-suma.pem; chmod 0600 /root/.ssh/config; zypper -n in rsync'"
                    // Repositories under ibs/ and download/ibs/ are served from the root of the AWS mirror,
                    // as the server pipeline replaces download.suse.de/ibs/ by the mirror hostname in the repository URLs
                    def rsync = "rsync -a --rsync-path=\"sudo rsync\""
                    sh "${local_ssh} '${rsync} --exclude=/ibs --exclude=/download/ibs /srv/mirror/ aws-mirror:/srv/mirror/'"
                    sh "${local_ssh} '[ ! -d /srv/mirror/ibs ] || ${rsync} /srv/mirror/ibs/ aws-mirror:/srv/mirror/'"
                    sh "${local_ssh} '[ ! -d /srv/mirror/download/ibs ] || ${rsync} /srv/mirror/download/ibs/ aws-mirror:/srv/mirror/'"
                }
            }
            finally {
                stage('Save TF state') {
                    archiveArtifacts artifacts: "results/sumaform-aws-infra/terraform.tfstate, results/sumaform-aws-infra/.terraform/**/*", allowEmptyArchive: true
                }
                stage('Clean up old results') {
                    sh "./clean-old-results -r ${resultdir}"
                }
            }
        }
    }
}

return this
