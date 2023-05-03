def run(params) {
    timestamps {
        stage('Installation') {
            script {
              if (params.Installation_Type == 'online') {
                sh 'ssh -v -o StrictHostKeyChecking=no root@openqa-executor.mgr.suse.de "cd /root/openqa-suma-installation ;cp params-run-installation-43_online.json params-run-installation-43.json;"'
              } else {
                sh 'ssh -v -o StrictHostKeyChecking=no root@openqa-executor.mgr.suse.de "cd /root/openqa-suma-installation ;cp params-run-installation-43_full.json params-run-installation-43.json;"'
              }
            }
        }
        stage('Configuration of ISO_URL') {
            sh 'ssh -v -o StrictHostKeyChecking=no root@openqa-executor.mgr.suse.de "cat params-run-installation-43.json | jq '. + {\"ISO_URL\": \"${params.ISO_URL}\" }' > params-run-installation-43.json"'
        }

        stage('Run') {
            // sh 'ssh -v -o StrictHostKeyChecking=no root@openqa-executor.mgr.suse.de "cd /root/openqa-suma-installation/;/root/openqa-suma-installation/run-openqa-test.sh $BUILD_NUMBER 43\n"'
            sh 'ssh -v -o StrictHostKeyChecking=no root@openqa-executor.mgr.suse.de "cd /root/openqa-suma-installation/;  cat params-run-installation-43.json;"'
        }
    }
}


return this
