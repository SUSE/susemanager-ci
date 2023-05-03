def run(params) {
    timestamps {

        stage('Parameterize') {
            script {
              if (params.Installation_Type == 'online') {
                    sh "ssh -o StrictHostKeyChecking=no root@openqa-executor.mgr.suse.de \"cd /root/openqa-suma-installation; jq '. + {\\\"ISO_URL\\\": \\\"${params.ISO_URL}\\\" }' params-run-installation-43-online.json > params-run-installation-43-online.json.tmp && mv params-run-installation-43-online.json.tmp params-run-installation-43-online.json; cat params-run-installation-43-online.json;\""
                    sh 'ssh -o StrictHostKeyChecking=no root@openqa-executor.mgr.suse.de "cd /root/openqa-suma-installation/; /root/openqa-suma-installation/run-openqa-test.sh $BUILD_NUMBER 43 online\n"'
              }
              else {
                    sh "ssh -o StrictHostKeyChecking=no root@openqa-executor.mgr.suse.de \"cd /root/openqa-suma-installation; jq '. + {\\\"ISO_URL\\\": \\\"${params.ISO_URL}\\\" }' params-run-installation-43-offline.json > params-run-installation-43-offline.json.tmp && mv params-run-installation-43-offline.json.tmp params-run-installation-43-offline.json; cat params-run-installation-43-offline.json;\""
                    sh 'ssh -o StrictHostKeyChecking=no root@openqa-executor.mgr.suse.de "cd /root/openqa-suma-installation/; /root/openqa-suma-installation/run-openqa-test.sh $BUILD_NUMBER 43 offline\n"'
              }
            }
        }

        stage('Run') {
            sh "ssh -o StrictHostKeyChecking=no root@openqa-executor.mgr.suse.de \"cd /root/openqa-suma-installation/; /root/openqa-suma-installation/run-openqa-test.sh $BUILD_NUMBER 43 ${params.Installation_Type}\n\""
        }
    }
}


return this
