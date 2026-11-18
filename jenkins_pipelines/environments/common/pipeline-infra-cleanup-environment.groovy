// Cleans up an environment deployed with Terraform: runs clean-env.sh on the hypervisor that hosts it,
// then removes the workspace of the job that deployed it from this worker.
// Replaces the freestyle job manager-infra-clean-up-environment.
// After a cleanup, the next deployment of that environment must run with use_previous_terraform_state unchecked.
def run(params) {
    ansiColor('xterm') {
        timestamps {
            String hypervisor = (params.hypervisor ?: '').trim()
            String environment = (params.environment ?: '').trim()
            String job = (params.job ?: '').trim()
            if (job == 'none') {
                job = ''
            }
            String sshOptions = '-o StrictHostKeyChecking=no -o ConnectTimeout=60 -o ServerAliveInterval=60'

            stage('Validate parameters') {
                // The values end up in a shell command: accept only host, prefix and job name characters
                if (!(hypervisor ==~ /[A-Za-z0-9.-]+/)) {
                    error("Invalid hypervisor: '${hypervisor}'")
                }
                if (!(environment ==~ /[A-Za-z0-9._-]+/)) {
                    error("Invalid environment: '${environment}'")
                }
                if (job && (!(job ==~ /[A-Za-z0-9._-]+/) || job.contains('..'))) {
                    error("Invalid job: '${job}'")
                }
                currentBuild.description = "${environment} on ${hypervisor}"
            }

            stage('Confirm cleanup') {
                def typed = input(
                        message: "This destroys the environment ${environment} on ${hypervisor}. Type its name to confirm.",
                        parameters: [string(name: 'Environment_Name', description: 'Name of the environment to clean up')]
                )
                if (typed != environment) {
                    error('The name entered does not match the environment. Aborting.')
                }
            }

            stage("Clean ${environment} on ${hypervisor}") {
                sh "ssh ${sshOptions} root@${hypervisor} 'bash clean-env.sh ${environment}'"
            }

            stage('Delete the job workspace on the worker') {
                if (job) {
                    // Folder jobs keep their workspace under a different name: check and delete those by hand
                    sh "rm -rf '${WORKSPACE}/../${job}'"
                } else {
                    echo 'No job selected: nothing to delete on the worker'
                }
            }
        }
    }
}

return this
