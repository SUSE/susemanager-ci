def run(params) {
    timestamps {
        deployed_local = false
        deployed_aws = false
        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        // The junit plugin doesn't affect full paths
        junit_resultdir = "results/${BUILD_NUMBER}/results_junit"
        env.local_common_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/local_mirror.tf --gitfolder ${resultdir}/sumaform-local"
        env.aws_common_params = "--outputdir ${resultdir} --tf susemanager-ci/terracumber_config/tf_files/aws_mirror.tf --gitfolder ${resultdir}/sumaform-aws"
        env.ssh_key = "-----BEGIN RSA PRIVATE KEY-----\n" +
                "MIIEowIBAAKCAQEAgIlqypvO51HIfsFSyjqYMJihRXk2HRS+W9ilNfhWtnE/RBvg\n" +
                "flxMIz5r9eLtScdVDhJY5QqlnQ9P3jmJNOO42NJY4Wu3SifK/MI/E9NLwwgziLQi\n" +
                "keAzDR6hGcZOqeptY8voqoy73vYFyeGyrEWK9sjwaBYCYZ6dgn7Nc95UUN+DTMu1\n" +
                "3DsKB7I6aczjKjbVkm3I9umVUHirzcm69otJ/F/RjSP8lGe1oYZYf1OFD5OdpZBS\n" +
                "8+xo+MtsSHVdF/mBVACC1xz7Cbm7ZpH5pxXmdiA03uBhxf50sw0vHEE97lm5JwCv\n" +
                "Bi9Id6YzVtL2DhYXW46TIqYgu0rUXSN42xpk/QIDAQABAoIBACQDXHJr+SqClYQ+\n" +
                "Mi4LAL0M5pKKhYjcWQFuz8sxS0pOrIUuslV1ErgFM0ZvUECNot0QcuupcgFxWtVO\n" +
                "lYzGCPJm7RQrk+0o/QyYeAfb+awpThcNMWphwKv6WvTXxQ6Caie95/BxAepUUAbi\n" +
                "P6dYzLicUA85q20ifcskL/g44LLPpE35XfaQ0YdDdCdyZ93a1EDfGejqTi3hS19y\n" +
                "IM7ITr1B/ph0FQozdGutwgE0MiwywOCxSV/cXYtdK86sFwg6uQHC9RgC4UTs28Of\n" +
                "P4GohLsiYQSkm0VhHN9ps94EpaJLwxQrntyfY5mreP+sh183FSvoBDPfbWeYfXUJ\n" +
                "JSZtsdkCgYEA55QDLAnGjVpT0rwdUrlq4XsWKdMgOqOI05CEmdRPP0cm3gf1LWJg\n" +
                "GQzh92l2BU+gok/ZWr+7GyfZs9UoW+i86hlDrUna5V0K+O98e0sZuuVjXoHzvFRc\n" +
                "i0aI61Ygbz5B3SwpmjQ9D6QVJSHnWzXrl/N3tEgxnvkdUL4/56feDMsCgYEAjheQ\n" +
                "hVyUcL3rAKnixKnA2rF+Aa4ythp/ymYSIGyHawYvuUr67MarssnCDUgUt6ascu+E\n" +
                "zk59kviyRNGpG8f1f35iSLKmiByiQhUAwqJAZWalTSk7ub5Opcx008Tk4+Tpzd8k\n" +
                "VSTzzujTsCq/1z53AU2HC4ZHimNf8OdEPL8WpFcCgYEAp+rydd9MwrhpqZfP52kd\n" +
                "cAxRYNh/OSXVlBrpm6WQJQER1NOOW29G4UMvIris5GL9xlQB9kSqhqFZwYVhs2tK\n" +
                "eLEDGsc/2yqhRypYaApnyNaGPEQcmUXOqQrnQ0X7VM6e8aIRNIiGci33SyqPWNr7\n" +
                "Tv4yoV3r5Ssbr62UJwTZBQsCgYB9e/gInqMFEeP4+Q8oKNYFDJzANSvZwHs8rnmx\n" +
                "osbQ0GzTEZGaCzXUtfMmsZKCQbKn6jj5zT1+zxz4Q8Q5oZSAHIgFtaf2KnttKok6\n" +
                "WfnO0yCGjTSOq69fIrnFz2toi1+jjT3T58dc4icYvBghqauFPgdWOSby4yH2aPbN\n" +
                "QuBnDwKBgDqO1qBv/UaGdmR7fDQxIrg3U2+TVvZ9jA+7UWwJjHkgENOj+QPeiGx9\n" +
                "pk0MGrfcPk55l17Ntr/Ql/oo6QBSuuADsB3k/ssqlrhwX3CdKnhsNvpA51tsztGo\n" +
                "W4j4gwTswc1SO4+1uE/qIS+dRNJOR10vfN4ixeLgel11Amotcqnj\n" +
                "-----END RSA PRIVATE KEY-----\n"
        stage('Clone terracumber, susemanager-ci and sumaform') {
            // Create a directory for  to place the directory with the build results (if it does not exist)
            sh "mkdir -p ${resultdir}"
            git url: params.terracumber_gitrepo, branch: params.terracumber_ref
            dir("susemanager-ci") {
                checkout scm
            }
            // Clone sumaform
            sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${env.local_common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync --sumaform-backend libvirt"
            sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${env.aws_common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync --sumaform-backend aws"
        }

        stage('Create mirrors') {
            parallel(
                    "create_local_mirror_with_mu": {
                        stage("Create local mirror with MU") {
                            // Provision the environment
                            if (params.terraform_init) {
                                env.TERRAFORM_INIT = '--init'
                            } else {
                                env.TERRAFORM_INIT = ''
                            }
                            String[] repositories_split = params.mu_repositories.split("\n")
                            env.repositories = "storage:\n" +
                                    "  type: file\n" +
                                    "  path: /srv/mirror\n" +
                                    "\n" +
                                    "http:"
                            repositories_split.each { item ->
                                env.repositories = "${env.repositories}\n\n" +
                                        "  - url: ${item}\n" +
                                        "    archs: [x86_64]"
                            }
                            writeFile file: "${env.resultdir}/sumaform-local/salt/mirror/etc/minima-customize.yaml", text: env.repositories, encoding: "UTF-8"
                            sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${local_common_params} --logfile ${resultdirbuild}/sumaform-local.log ${env.TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend libvirt"
                            deployed_local = true

                        }
                    },
                    "create_empty_aws_mirror": {
                        stage("Create empty AWS mirror") {
                            // Provision the environment
                            if (params.terraform_init) {
                                env.TERRAFORM_INIT = '--init'
                            } else {
                                env.TERRAFORM_INIT = ''
                            }
                            sh "set +x; source /home/jenkins/.credentials set -x; source /home/jenkins/.aws set -x;export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${aws_common_params} --logfile ${resultdirbuild}/sumaform-aws.log ${env.TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision --sumaform-backend aws"
                            deployed_aws = true

                        }
                    }
            )

        }
        
        stage("Upload ssh key to local mirror") {
            mirror_hostname_local = sh(script: "cat /home/jenkins/jenkins-build/workspace/uyuni-manager-mu-cloud/results/sumaform-local/terraform.tfstate | jq -r ''.resources[3].instances[0].attributes.network_interface[0].addresses[0]'' ",
                    returnStdout: true)
            mirror_hostname_aws = sh(script: "cat /home/jenkins/jenkins-build/workspace/uyuni-manager-mu-cloud/results/sumaform-aws/terraform.tfstate | jq -r '.outputs.aws_mirrors_public_name.value[0]' ",
                    returnStdout: true)

            def remote = [:]
            remote.name = 'local_mirror'
            remote.host = ${mirror_hostname_local}
            remote.user = 'root'
            remote.password = 'linux'
            sh "ssh -o StrictHostKeyChecking=no ${remote.user}@${remote.host} echo ${env.ssh_key} > /root/.ssh/testing-suma.pem"
            sh "ssh -o StrictHostKeyChecking=no ${remote.user}@${remote.host} chmod 0400 /root/.ssh/testing-suma.pem"
            sh "ssh -o StrictHostKeyChecking=no ${remote.user}@${remote.host} scp -R -i /root/.ssh/testing-suma.pem /srv/mirror ec2-user@${mirror_hostname_aws}:/srv/mirror"
    }
}


//            stage('Add MUs') {
//                if(params.must_add_channels) {
//                    echo 'Add custom channels and MU repositories'
//                    res_mu_repos = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_add_custom_repositories'", returnStatus: true)
//                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake cucumber:build_validation_wait_for_custom_reposync'"
//                    echo "Custom channels and MU repositories status code: ${res_mu_repos}"
//                }
//            }

//            stage('Add Activation Keys') {
//                if(params.must_add_keys) {
//                    echo 'Add Activation Keys'
//                    res_add_keys = sh(script: "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export BUILD_VALIDATION=true; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:build_validation_add_activation_keys'", returnStatus: true)
//                    echo "Add Activation Keys status code: ${res_add_keys}"
//                }
//            }


return this
