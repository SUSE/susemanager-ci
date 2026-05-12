pipeline {
    agent {
        label 'sumaform-cucumber'
    }
    triggers {
        upstream(upstreamProjects: 'manager-5.1-ai-acceptance-tests', threshold: hudson.model.Result.FAILURE)
    }
    options {
        timestamps()
        // Prevents the job from hanging forever
        timeout(time: 45, unit: 'MINUTES')
    }

    parameters {
        string(
            name: 'MCP_SERVER_REPO',
            defaultValue: 'https://github.com/uyuni-project/mcp-server-uyuni.git',
            description: 'The repository to check out for the mcp-server-uyuni.'
        )
        string(
            name: 'MCP_SERVER_BRANCH',
            defaultValue: 'main',
            description: 'The branch to check out from the mcp-server-uyuni repository.'
        )
        string(
            name: 'OAUTH_TEST_SERVER_HOSTNAME',
            defaultValue: 'mlm-test-ai-oauth.mgr.suse.de',
            description: 'Hostname of the external Docker host (OAuth test server). This is used for SSH tunneling and cannot be localhost or'
        )
        string(
            name: 'UYUNI_SERVER',
            defaultValue: 'mlm-test-ai-server.mgr.suse.de',
            description: 'FQDN of the target Uyuni/Manager server.'
        )
        string(
            name: 'UYUNI_MCP_PUBLIC_URL',
            defaultValue: 'http://mlm-test-ai-oauth.mgr.suse.de:8000',
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
        // Sanitize JOB_NAME for use as a Docker Compose project name
        COMPOSE_PROJECT_NAME = "${env.JOB_NAME.toLowerCase().replaceAll(/[^a-z0-9_-]/, '-')}"
    }
    stages {
        stage('Prepare Test Server') {
            steps {
                echo "Ensuring jenkins user and dependencies (jq, npm, gemini-cli) are set up on ${params.OAUTH_TEST_SERVER_HOSTNAME}..."
                sh """
                    # Pinning versions for reproducible builds.
                    # Note: You may need to update the zypper package versions based on what's available in your repositories.
                    # You can check available versions on the test server with: zypper se -s <package-name>
                    set -ex
                    ssh root@${params.OAUTH_TEST_SERVER_HOSTNAME} "id -u jenkins &>/dev/null || useradd -m -s /bin/bash jenkins"
                    ssh root@${params.OAUTH_TEST_SERVER_HOSTNAME} "groups jenkins | grep -q '\\bdocker\\b' || usermod -aG docker jenkins"
                    ssh root@${params.OAUTH_TEST_SERVER_HOSTNAME} "mkdir -p /home/jenkins/workspace && chown jenkins:jenkins /home/jenkins/workspace"
                    ssh root@${params.OAUTH_TEST_SERVER_HOSTNAME} "rpm -q --quiet jq-1.7.1 || zypper in -y --oldpackage jq=1.7.1"
                    ssh root@${params.OAUTH_TEST_SERVER_HOSTNAME} "rpm -q --quiet nodejs-common-6.1 || zypper in -y --oldpackage nodejs-common-6.1"
                    ssh root@${params.OAUTH_TEST_SERVER_HOSTNAME} "npm list -g @google/gemini-cli@0.39.1 || npm install -g @google/gemini-cli@0.39.1"
                """
            }
        }
        stage('Checkout Code') {
            steps {
                echo 'Checking out mcp-server-uyuni...'
                git url: params.MCP_SERVER_REPO, branch: params.MCP_SERVER_BRANCH
            }
        }

        stage('Setup Remote Docker Tunnel') {
            steps {
                echo "Setting up SSH tunnel to remote Docker daemon at ${params.OAUTH_TEST_SERVER_HOSTNAME}..."
                // Start the SSH tunnel in the background and capture its PID
                sh """
                    ssh -fnNT -L /tmp/remote-docker.sock:/run/docker.sock jenkins@${params.OAUTH_TEST_SERVER_HOSTNAME}
                    echo \$! > ssh_tunnel.pid
                """
                script {
                    env.SSH_TUNNEL_PID = readFile('ssh_tunnel.pid').trim()
                    echo "SSH tunnel started with PID: ${env.SSH_TUNNEL_PID}. Verifying connection..."
                }
                sh "DOCKER_HOST=${env.DOCKER_HOST} docker info"
            }
        }

        stage('Prepare and Deploy MCP Server') {
            steps {
                echo 'Preparing stack.env configuration...'
                sh """
                    set -e
                    cp deploy/stack.env.example deploy/stack.env
                    sed -i "s|UYUNI_SERVER=.*|UYUNI_SERVER=${params.UYUNI_SERVER}|" deploy/stack.env
                    sed -i "s|UYUNI_MCP_PUBLIC_URL=.*|UYUNI_MCP_PUBLIC_URL=${params.UYUNI_MCP_PUBLIC_URL}|" deploy/stack.env
                    sed -i "s|UYUNI_AUTH_SERVER=.*|UYUNI_AUTH_SERVER=http://${params.OAUTH_TEST_SERVER_HOSTNAME}:8080/realms/uyuni-mcp|" deploy/stack.env
                    sed -i "s|KEYCLOAK_PUBLIC_HOSTNAME=.*|KEYCLOAK_PUBLIC_HOSTNAME=${params.OAUTH_TEST_SERVER_HOSTNAME}|" deploy/stack.env
                """

                echo "Copying Keycloak import files to ${params.OAUTH_TEST_SERVER_HOSTNAME}..."
                sh """
                    set -e
                    DOCKER_HOST=${env.DOCKER_HOST} docker volume rm ${env.COMPOSE_PROJECT_NAME}_keycloak-data || true
                    DOCKER_HOST=${env.DOCKER_HOST} docker volume create ${env.COMPOSE_PROJECT_NAME}_keycloak-data
                    DOCKER_HOST=${env.DOCKER_HOST} docker run --rm -v ${env.COMPOSE_PROJECT_NAME}_keycloak-data:/data busybox chown -R 1000:1000 /data
                    IMPORT_DIR="${WORKSPACE}/deploy/keycloak/import"
                    ssh jenkins@${params.OAUTH_TEST_SERVER_HOSTNAME} "mkdir -p \${IMPORT_DIR} && rm -f \${IMPORT_DIR}/*"
                    set +x
                    . ~/.ai_secrets
                    set -ex
                    cat deploy/keycloak/import/uyuni-mcp-realm.json | ssh jenkins@${params.OAUTH_TEST_SERVER_HOSTNAME} "sed 's/SECRET-REPLACE-ME/\${UYUNI_OAUTH_CLIENT_SECRET}/' > \${IMPORT_DIR}/uyuni-mcp-realm.json"
                    scp deploy/keycloak/import/uyuni-mcp-users-0.json jenkins@${params.OAUTH_TEST_SERVER_HOSTNAME}:\${IMPORT_DIR}/
                """
                echo 'Building and starting services with Docker Compose...'
                sh "DOCKER_HOST=${env.DOCKER_HOST} docker compose --project-name ${env.COMPOSE_PROJECT_NAME} down --remove-orphans"
                echo 'Pruning old Docker images to free up space...'
                sh "DOCKER_HOST=${env.DOCKER_HOST} docker image prune -f"
                sh "DOCKER_HOST=${env.DOCKER_HOST} docker compose --project-name ${env.COMPOSE_PROJECT_NAME} --env-file deploy/stack.env up -d --build"

                echo "Waiting for Keycloak to become available at http://${params.OAUTH_TEST_SERVER_HOSTNAME}:8080..."
                // Use a retry loop to ensure Keycloak is fully initialized before proceeding.
                retry(6) {
                    sleep(10) // Wait 10 seconds before the next attempt
                    sh """
                        # Poll the OIDC discovery endpoint until it returns a 200 OK
                        curl -sS --fail http://${params.OAUTH_TEST_SERVER_HOSTNAME}:8080/realms/uyuni-mcp/.well-known/openid-configuration > /dev/null
                    """
                }
            }
        }

        stage('Configure Uyuni Server for OIDC') {
            steps {
                echo "Configuring OIDC on ${params.UYUNI_SERVER}..."
                // Use mgrctl to execute commands inside the uyuni-server container
                // The multiline shell step will fail if any command fails
                sh """
                    set -ex
                    ssh root@${params.UYUNI_SERVER} 'mgrctl exec -- "sed -i \\"s|^web.oidc.idp.issuer =.*|web.oidc.idp.issuer = http://${params.OAUTH_TEST_SERVER_HOSTNAME}:8080/realms/uyuni-mcp|\\" /etc/rhn/rhn.conf"'
                    ssh root@${params.UYUNI_SERVER} 'mgrctl exec -- "sed -i \\"s|^web.oidc.enabled =.*|web.oidc.enabled = true|\\" /etc/rhn/rhn.conf"'
                """

                echo 'Restarting Tomcat to apply configuration...'
                sh """
                    ssh root@${params.UYUNI_SERVER} "mgrctl exec 'systemctl restart tomcat'"
                """

                echo "Waiting for Uyuni API to become available on ${params.UYUNI_SERVER}..."
                // Use a retry loop to ensure the API is responsive after the Tomcat restart
                retry(6) {
                    sleep(10) // Wait 10 seconds before the next attempt
                    sh """
                        set -ex
                        ssh root@${params.UYUNI_SERVER} "mgrctl exec -- curl -s -k --fail http://localhost/rpc/api > /dev/null"
                    """
                }
            }
        }

        stage('Create Test User in Uyuni') {
            steps {
                echo 'Creating a matching user in Uyuni for Keycloak authentication...'
                sh """
                    set -ex
                    # The UYUNI_ADMIN_PASSWORD parameter is automatically masked by Jenkins
                    ssh root@${params.UYUNI_SERVER} "mgrctl exec -- spacecmd -u admin -p \\"${params.UYUNI_ADMIN_PASSWORD}\\" user_create -- -u service-account-mcp-server-uyuni -p \${RANDOM} -e mcp-service@localhost -f MCP -l ServiceAccount"
                    ssh root@${params.UYUNI_SERVER} "mgrctl exec -- spacecmd -u admin -p \\"${params.UYUNI_ADMIN_PASSWORD}\\" user_addrole service-account-mcp-server-uyuni org_admin"
                """
            }
        }

        stage('Verify MCP Server Endpoints') {
            steps {
                echo 'Waiting for services to become available...'
                // Use a retry loop instead of a fixed sleep for more robustness
                retry(5) {
                    sleep(10) // Wait 10 seconds between retries
                    echo 'Verifying OAuth protected resource endpoint...'
                    sh "curl -sS --fail http://${params.OAUTH_TEST_SERVER_HOSTNAME}:8000/.well-known/oauth-protected-resource | jq"
                }
                retry(3) {
                    echo 'Fetching access token from Keycloak...'
                    sh """
                        # Disable command echoing to securely load secrets, then re-enable for debugging
                        set +x
                        . ~/.ai_secrets
                        set -ex
                        UYUNI_TOKEN=\$(curl -sS -X POST 'http://${params.OAUTH_TEST_SERVER_HOSTNAME}:8080/realms/uyuni-mcp/protocol/openid-connect/token' \\
                            -d "grant_type=client_credentials" \\
                            -d "client_id=mcp-server-uyuni-headless" \\
                            -d "client_secret=\${UYUNI_OAUTH_CLIENT_SECRET}" | jq -r .access_token)
                        
                        if [ -z "\$UYUNI_TOKEN" ] || [ "\$UYUNI_TOKEN" == "null" ]; then
                            echo "Failed to get access token."
                            exit 1
                        fi

                        RESPONSE=\$(curl -s -X POST 'http://${params.OAUTH_TEST_SERVER_HOSTNAME}:8000/mcp' \\
                            -H "Accept: application/json, text/event-stream" \\
                            -H "Content-Type: application/json" \\
                            -H "Authorization: Bearer \$UYUNI_TOKEN" \\
                            -d '{
                                "jsonrpc": "2.0",
                                "id": 1,
                                "method": "initialize",
                                "params": {
                                    "protocolVersion": "2024-11-05",
                                    "capabilities": {},
                                    "clientInfo": {
                                        "name": "curl-client",
                                        "version": "1.0.0"
                                    }
                                }
                            }')
                        echo "MCP server response:"
                        echo "\$RESPONSE"

                        # Use variables to hold grep patterns to avoid complex quoting issues
                        SUCCESS_PATTERN='"serverInfo":{"name":"mcp-server-uyuni"'
                        ERROR_PATTERN='invalid_token'

                        if echo "\$RESPONSE" | grep -q "\$SUCCESS_PATTERN"; then
                            echo "MCP server initialization successful."
                        elif echo "\$RESPONSE" | grep -q "\$ERROR_PATTERN"; then
                            echo "Error: Invalid token."
                            exit 1
                        else
                            echo "Error: Unexpected response from MCP server."
                            exit 1
                        fi
                    """
                }
            }
        }
        
        stage('Gemini CLI Auth') {
            steps {
                echo "Running Gemini CLI authentication test..."
                // We run the command on the remote test server via SSH.
                // A simple version check is performed to confirm the installation.
                sh """
                        # Disable command echoing to securely load secrets, then re-enable for debugging
                        set +x
                        . ~/.ai_secrets
                        set -ex
                        TOKEN=\$(curl -sS -X POST 'http://${params.OAUTH_TEST_SERVER_HOSTNAME}:8080/realms/uyuni-mcp/protocol/openid-connect/token' \\
                            -d "grant_type=client_credentials" \\
                            -d "client_id=mcp-server-uyuni-headless" \\
                            -d "client_secret=\${UYUNI_OAUTH_CLIENT_SECRET}" | jq -r .access_token)
                        
                        if [ -z "\$TOKEN" ] || [ "\$TOKEN" == "null" ]; then
                            echo "Failed to get access token."
                            exit 1
                        fi

                        echo "--- DEBUG: Got Access Token ---"
                        echo "Token starts with: \$(echo \$TOKEN | cut -c 1-10)..."
                        
                        # Create ~/.gemini directory on the remote host
                        ssh jenkins@${params.OAUTH_TEST_SERVER_HOSTNAME} "mkdir -p ~/.gemini"

                        # Use a here-document to safely construct the JSON content and pipe it to the remote host.
                        # This avoids complex quoting issues within the Jenkinsfile.
                        ssh jenkins@${params.OAUTH_TEST_SERVER_HOSTNAME} "cat > ~/.gemini/settings.json" <<EOF
                        {
                          "mcpServers": {
                            "mcp-server-uyuni": {
                              "httpUrl": "http://${params.OAUTH_TEST_SERVER_HOSTNAME}:8000/mcp",
                              "headers": {
                                "Authorization": "Bearer \$TOKEN"
                              }
                            }
                          },
                          "security": {
                            "auth": {
                              "selectedType": "gemini-api-key"
                            }
                          }
                        }
EOF

                        echo "--- DEBUG: Verifying remote gemini settings.json ---"
                        ssh jenkins@${params.OAUTH_TEST_SERVER_HOSTNAME} "cat ~/.gemini/settings.json"
                        echo "----------------------------------------------------"

                        # Run with verbose logging for better debugging
                        GEMINI_OUTPUT=\$(ssh jenkins@${params.OAUTH_TEST_SERVER_HOSTNAME} "gemini --debug mcp list 2>&1")
                        echo "Gemini CLI output:"
                        echo "\$GEMINI_OUTPUT"

                        EXPECTED_OUTPUT="✓ mcp-server-uyuni: http://${params.OAUTH_TEST_SERVER_HOSTNAME}:8000/mcp (http) - Connected"
                        if echo "\$GEMINI_OUTPUT" | grep -qF "\$EXPECTED_OUTPUT"; then
                            echo "Gemini CLI connection successful."
                        else
                            echo "Error: Gemini CLI did not connect as expected."
                            exit 1
                        fi
                """
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
                    sh "DOCKER_HOST=${env.DOCKER_HOST} docker compose --project-name ${env.COMPOSE_PROJECT_NAME} down --remove-orphans"
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
                    sh "ssh root@${params.UYUNI_SERVER} \"mgrctl exec -- sed -i 's|^web.oidc.enabled =.*|web.oidc.enabled = false|' /etc/rhn/rhn.conf\""
                    sh "ssh root@${params.UYUNI_SERVER} \"mgrctl exec 'systemctl restart tomcat'\""
                } catch (e) {
                    echo "Warning: Failed to disable OIDC on Uyuni server during cleanup. This may require manual intervention. Error: ${e.message}"
                }

                echo "Removing test user from ${params.UYUNI_SERVER}..."
                try {
                    sh '''ssh root@''' + params.UYUNI_SERVER + ''' "mgrctl exec -- spacecmd -y -u admin -p ' ''' + params.UYUNI_ADMIN_PASSWORD + ''' ' user_delete service-account-mcp-server-uyuni"'''
                } catch (e) {
                    echo "Warning: Failed to remove test user from Uyuni server during cleanup. This may require manual intervention. Error: ${e.message}"
                }

                echo 'Cleanup finished.'
            }
        }
    }
}
