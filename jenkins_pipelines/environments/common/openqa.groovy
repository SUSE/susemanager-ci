def run(params) {
    timestamps {

        stage('Parameterize') {
            sh "ssh -o StrictHostKeyChecking=no root@openqa-executor.mgr.suse.de \"cd /root/openqa-suma-installation; jq '. + {\\\"ISO_URL\\\": \\\"${params.ISO_URL}\\\" }' params-run-installation-43-${params.Installation_Type}.json > params-run-installation-43-${params.Installation_Type}.json.tmp && mv params-run-installation-43-${params.Installation_Type}.json.tmp params-run-installation-43-${params.Installation_Type}.json; cat params-run-installation-43-${params.Installation_Type}.json;\""
            }
        }

        stage('Run') {
            sh "ssh -o StrictHostKeyChecking=no root@openqa-executor.mgr.suse.de \"cd /root/openqa-suma-installation/; /root/openqa-suma-installation/run-openqa-test.sh $BUILD_NUMBER 43 ${params.Installation_Type}\n\""
        }
    }
}


return this
