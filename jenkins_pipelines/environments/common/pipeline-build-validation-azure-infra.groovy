// Deploys the Azure infrastructure shared by the Azure build validation pipelines:
// resource group, virtual network with public, private and additional subnets, NAT gateway and bastion.
// Hosts in the private subnets are reachable through the bastion only.
def run(params) {
    if (load('jenkins_pipelines/environments/common/helpers/quiet-window.groovy').skipIfQuiet(manualWindow: 'MON 00:00-MON 05:00')) { return }
    def safe = load('jenkins_pipelines/environments/common/helpers/safe-step.groovy')
    ansiColor('xterm') {
        timestamps {
            env.resultdir = "${WORKSPACE}/results"
            env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
            def azure_infra_dir = "${resultdir}/sumaform-azure-infra"
            // Exports the ARM_* variables of the azure-secrets credential without echoing them
            def azInit = 'set +x; . "${AZURE_SECRETS_FILE}"; set -x'

            def azure_infra_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/azure_infra.tf --gitfolder ${azure_infra_dir} --terraform-bin ${params.bin_path}"
            if (params.deploy_parallelism) {
                azure_infra_params = "${azure_infra_params} --parallelism ${params.deploy_parallelism}"
            }

            // Destroy what the last deployment created on this agent, using the state and tfvars it left in the workspace.
            // The server pipelines environments must be destroyed first, as they use the virtual network and subnets.
            if (params.destroy_environment) {
                if (!params.confirm_destroy) {
                    error("destroy_environment requires confirm_destroy to be checked too")
                }
                stage('Destroy environment') {
                    if (!fileExists("${azure_infra_dir}/terraform.tfstate")) {
                        error("No terraform state in ${azure_infra_dir} on this agent: nothing to destroy")
                    }
                    sh "${azInit}; cd ${azure_infra_dir}; ${params.bin_path} init; ${params.bin_path} destroy -auto-approve"
                    sh "rm -rf ${azure_infra_dir}"
                    currentBuild.description = "infrastructure destroyed"
                }
                return
            }

            if (!params.allowed_IPS?.trim()) {
                error("allowed_IPS must not be empty: Azure rejects an SSH rule without source addresses")
            }

            try {
                stage('Clone terracumber, susemanager-ci and sumaform') {
                    sh "mkdir -p ${resultdir}"
                    git url: params.terracumber_gitrepo, branch: params.terracumber_ref
                    dir("susemanager-ci") {
                        checkout scm
                    }
                    sh "./terracumber-cli ${azure_infra_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync --sumaform-backend azure"
                }

                stage('Create Azure infrastructure') {
                    // Azure installs the public half of key_file on the instances
                    def public_key_file = "${azure_infra_dir}/key_file.pub"
                    sh "ssh-keygen -y -f ${params.key_file} > ${public_key_file}"
                    def azure_configuration = "LOCATION = \"${params.azure_location}\"\n" +
                            "NAME_PREFIX = \"${params.infra_name_prefix}\"\n" +
                            "KEY_FILE = \"${params.key_file}\"\n" +
                            "PUBLIC_KEY_FILE = \"${public_key_file}\"\n" +
                            "ALLOWED_IPS = [\n"
                    params.allowed_IPS.split("\n").each { ip ->
                        if (ip.trim()) {
                            azure_configuration += "    \"${ip.trim()}\",\n"
                        }
                    }
                    azure_configuration += "]\n"
                    writeFile file: "${azure_infra_dir}/terraform.tfvars", text: azure_configuration, encoding: "UTF-8"
                    // The Azure infrastructure is persistent: no taint, existing resources are kept and only updated
                    sh "${azInit}; export TERRAFORM=${params.bin_path}; export TERRAFORM_PLUGINS=${params.bin_plugins_path}; ./terracumber-cli ${azure_infra_params} --logfile ${resultdirbuild}/sumaform-azure-infra.log --init --runstep provision --sumaform-backend azure"
                }

                def bastion_hostname = sh(script: "jq -r '.outputs.bastion_public_name.value' ${azure_infra_dir}/terraform.tfstate", returnStdout: true).trim()
                currentBuild.description = "bastion: ${bastion_hostname}"
            }
            finally {
                stage('Save TF state') {
                    archiveArtifacts artifacts: "results/sumaform-azure-infra/terraform.tfstate, results/sumaform-azure-infra/.terraform/**/*", allowEmptyArchive: true
                }
                stage('Clean up old results') {
                    safe.run('clean-old-results') { sh "./clean-old-results -r ${resultdir}" }
                }
            }
        }
    }
}

return this
