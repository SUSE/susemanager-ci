pipeline {
    agent {
        label 'sumaform-cucumber'
    }

    options {
        timestamps()
        // Prevents the job from hanging forever
        timeout(time: 45, unit: 'MINUTES')
    }

    parameters {
        string(
            name: 'MCP_SERVER_BRANCH',
            defaultValue: 'main',
            description: 'The branch to check out from the mcp-server-uyuni repository.'
        )
        string(
            name: 'OAUTH_TEST_SERVER_IP',
            defaultValue: '10.145.211.227',
            description: 'IP address of the external Docker host (OAuth test server).'
        )
        string(
            name: 'OAUTH_TEST_SERVER_IPV6',
            defaultValue: '2a07:de40:b208:1:f4cd:ad31:dbb7:f127',
            description: 'IPv6 address of the external Docker host. It cannot be inferred from the IPv4.'
        )
        string(
            name: 'UYUNI_SERVER',
            defaultValue: 'mlm-test-ai-server.mgr.suse.de',
            description: 'FQDN of the target Uyuni/Manager server.'
        )
        string(
            name: 'UYUNI_MCP_PUBLIC_URL',
            defaultValue: 'http://uyuni-mcp-server:8000',
            description: 'Public URL for the MCP server.'
        )
        password(
            name: 'UYUNI_ADMIN_PASSWORD',
            defaultValue: 'admin',
            description: 'Password for the "admin" user on the Uyuni server.'
        )
    }

    environment {
        // Define DOCKER_HOST for remote connection
        DOCKER_HOST = "unix:///tmp/remote-docker.sock"
        // Store the SSH process ID for precise cleanup
        SSH_TUNNEL_PID = ''
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Checking out mcp-server-uyuni...'
                git url: 'https://github.com/uyuni-project/mcp-server-uyuni.git', branch: params.MCP_SERVER_BRANCH
            }
        }

        stage('Setup Remote Docker Tunnel') {
            steps {
                echo "Setting up SSH tunnel to remote Docker daemon at ${params.OAUTH_TEST_SERVER_IP}..."
                // Start the SSH tunnel in the background and capture its PID
                sh '''
                    ssh -fnNT -L /tmp/remote-docker.sock:/run/docker.sock root@${params.OAUTH_TEST_SERVER_IP}
                    echo $! > ssh_tunnel.pid
                '''
                env.SSH_TUNNEL_PID = readFile('ssh_tunnel.pid').trim()
                echo "SSH tunnel started with PID: ${env.SSH_TUNNEL_PID}. Verifying connection..."
                sh "DOCKER_HOST=${env.DOCKER_HOST} docker info"
            }
        }

        stage('Prepare and Deploy MCP Server') {
            steps {
                echo 'Preparing stack.env configuration...'
                sh '''
                    set -e
                    cp deploy/stack.env.example deploy/stack.env
                    sed -i "s|UYUNI_SERVER=.*|UYUNI_SERVER=${params.UYUNI_SERVER}|" deploy/stack.env
                    sed -i "s|UYUNI_MCP_PUBLIC_URL=.*|UYUNI_MCP_PUBLIC_URL=${params.UYUNI_MCP_PUBLIC_URL}|" deploy/stack.env
                '''

                echo "Copying Keycloak import files to ${params.OAUTH_TEST_SERVER_IP}..."
                sh """
                    set -e
                    ssh root@${params.OAUTH_TEST_SERVER_IP} 'mkdir -p /root/mcp-server-uyuni/deploy/keycloak/import/'
                    scp deploy/keycloak/import/* root@${params.OAUTH_TEST_SERVER_IP}:/root/mcp-server-uyuni/deploy/keycloak/import/
                """

                echo 'Building and starting services with Docker Compose...'
                sh "DOCKER_HOST=${env.DOCKER_HOST} docker compose --env-file deploy/stack.env up -d --build"
            }
        }

        stage('Verify MCP Server Endpoints') {
            steps {
                echo 'Waiting for services to become available...'
                // Use a retry loop instead of a fixed sleep for more robustness
                retry(5) {
                    sleep(10) // Wait 10 seconds between retries
                    echo 'Verifying OAuth protected resource endpoint...'
                    sh 'curl -sS --fail http://uyuni-mcp-server:8000/.well-known/oauth-protected-resource | jq'
                }
                retry(3) {
                    sleep(5)
                    echo 'Verifying MCP endpoint...'
                    sh 'curl -sS --fail http://uyuni-mcp-server:8000/mcp'
                }
            }
        }

        stage('Configure Uyuni Server for OIDC') {
            steps {
                echo "Configuring OIDC on ${params.UYUNI_SERVER}..."
                // Use mgrctl to execute commands inside the uyuni-server container
                // The multiline shell step will fail if any command fails
                sh """
                    mgrctl exec 'mgr-conf --set-option web.oidc.idp.issuer http://keycloak:8080/realms/uyuni-mcp'
                    mgrctl exec 'mgr-conf --set-option web.oidc.enabled true'
                    mgrctl exec 'mgr-conf --set-option server.satellite.no_proxy keycloak,${params.OAUTH_TEST_SERVER_IP},${params.OAUTH_TEST_SERVER_IPV6}'
                """

                echo 'Restarting Tomcat to apply configuration...'
                sh "mgrctl exec 'systemctl restart tomcat'"
            }
        }

        stage('Create Test User in Uyuni') {
            steps {
                echo 'Creating a matching user in Uyuni for Keycloak authentication...'
                withCredentials([string(credentialsId: 'UYUNI_ADMIN_PASSWORD', variable: 'UYUNI_PASS')]) {
                    sh """
                        mgrctl exec 'spacecmd -u admin -p "${UYUNI_PASS}" user_create -- -u mcp-tester -p mcp-tester-pass -e mcp-tester@localhost -f MCP -l Tester'
                        mgrctl exec 'spacecmd -u admin -p "${UYUNI_PASS}" user_addrole mcp-tester org_admin'
                    """
                }
            }
        }

        stage('Manual Verification: Gemini CLI Auth') {
            steps {
                script {
                    def vnc_instructions = """
                    Please perform the following manual test:
                    1. Open a VNC connection to the OAuth test server: ${params.OAUTH_TEST_SERVER_IP}
                    2. Inside the VNC session, open a terminal.
                    3. Run the Gemini CLI authentication command: /mcp auth
                    4. A browser window should open for you to log in via Keycloak. Use the user 'mcp-tester' with password 'mcp-tester-pass'.
                    5. After successful login, the CLI should confirm authentication.
                    """
                    echo vnc_instructions

                    def result = input(
                        id: 'geminiAuthResult',
                        message: 'Did the Gemini CLI authentication test pass?',
                        parameters: [
                            choice(name: 'Result', choices: ['Pass', 'Fail', 'Skip'], description: 'Select the outcome of the manual test.')
                        ]
                    )

                    if (result == 'Fail') {
                        error("Manual test 'Gemini CLI Auth' was marked as failed.")
                    } else {
                        echo "Gemini CLI Auth test result: ${result}"
                    }
                }
            }
        }

        stage('Manual Verification: Gemini CLI Tool Use') {
            steps {
                script {
                    def tool_use_instructions = """
                    Please perform a second manual test in the same VNC session:
                    1. Use the Gemini CLI to interact with Uyuni.
                    2. Enter the prompt: 'list the systems in uyuni'
                    3. The CLI should use the OAuth token to connect to Uyuni and list the registered systems.
                    """
                    echo tool_use_instructions

                    def result = input(
                        id: 'geminiToolUseResult',
                        message: 'Did the Gemini CLI tool use test pass?',
                        parameters: [
                            choice(name: 'Result', choices: ['Pass', 'Fail', 'Skip'], description: 'Select the outcome of the manual test.')
                        ]
                    )

                    if (result == 'Fail') {
                        error("Manual test 'Gemini CLI Tool Use' was marked as failed.")
                    } else {
                        echo "Gemini CLI Tool Use test result: ${result}"
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo 'Starting cleanup...'
                
                echo 'Stopping and removing Docker Compose services...'
                // Use a try-catch to ensure cleanup continues even if this fails
                try {
                    sh "DOCKER_HOST=${env.DOCKER_HOST} docker compose down --remove-orphans"
                } catch (e) {
                    echo "Warning: Could not stop docker-compose services. Error: ${e.message}"
                }

                echo 'Closing SSH tunnel...'
                // Precisely kill the tunnel using its PID and clean up artifacts
                sh "if [ -n \"${env.SSH_TUNNEL_PID}\" ]; then kill ${env.SSH_TUNNEL_PID} || echo 'Tunnel process not found.'; fi"
                sh 'rm -f /tmp/remote-docker.sock || true'
                sh 'rm -f ssh_tunnel.pid || true'

                echo "Disabling OIDC on ${params.UYUNI_SERVER}..."
                // Use a try-catch block to prevent cleanup failure from failing the build
                try {
                    sh "mgrctl exec 'mgr-conf --set-option web.oidc.enabled false'"
                    sh "mgrctl exec 'systemctl restart tomcat'"
                } catch (e) {
                    echo "Warning: Failed to disable OIDC on Uyuni server during cleanup. This may require manual intervention. Error: ${e.message}"
                }

                echo 'Cleanup finished.'
            }
        }
    }
}
