pipeline {
    agent {
        label 'sumaform-cucumber'
    }

    triggers {
        // Run once a day (H means a random minute within the hour for load balancing)
        cron('H 0 * * *')
    }

    options {
        timestamps()
        // Prevents the job from hanging forever
        timeout(time: 15, unit: 'MINUTES')
    }

    parameters {
        string(
            name: 'OBS_API',
            defaultValue: 'https://build.opensuse.org',
            description: 'The API URL of the Open Build Service instance.'
        )
        string(
            name: 'OBS_PROJECT',
            defaultValue: 'systemsmanagement:Uyuni:AI',
            description: 'The OBS project to check for build results.'
        )
    }

    stages {
        stage('Check Build Results') {
            steps {
                script {
                    echo "Checking for failed packages in project '${params.OBS_PROJECT}' on API '${params.OBS_API}'..."
                    // The awk command prints the output and exits with an error code if there is any output (more than 1 line including header)
                    try {
                        sh "osc -A ${params.OBS_API} pr ${params.OBS_PROJECT} -s failed | awk '{print}END{exit NR>1}'"
                        echo "No 'failed' packages found."
                    } catch (e) {
                        error("Found packages with 'failed' build status in project ${params.OBS_PROJECT}.")
                    }

                    echo "Checking for unresolvable packages in project '${params.OBS_PROJECT}'..."
                    try {
                        sh "osc -A ${params.OBS_API} pr ${params.OBS_PROJECT} -s unresolvable | awk '{print}END{exit NR>1}'"
                        echo "No 'unresolvable' packages found."
                    } catch (e) {
                        error("Found packages with 'unresolvable' build status in project ${params.OBS_PROJECT}.")
                    }
                }
            }
        }
    }

    post {
        // Send an email only on failure
        failure {
            emailext (
                to: 'discuss-mlm-ai-test-r-aaaatphnhqm7cvlkd7xpw7vlh4@suse.slack.com',
                subject: "Build Failed: OBS Build Check for ${params.OBS_PROJECT}",
                body: """<p>The daily build check for OBS project <b>${params.OBS_PROJECT}</b> failed.</p>
                       <p>One or more packages have a 'failed' or 'unresolvable' build status.</p>
                       <p>Please check the Jenkins log for details: ${env.BUILD_URL}</p>
                       <p>Or view the project status directly on OBS: ${params.OBS_API}/project/show/${params.OBS_PROJECT}</p>""",
                mimeType: 'text/html'
            )
        }
        // Always clean up workspace
        always {
            cleanWs()
        }
    }
}