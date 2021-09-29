def run(params) {
    timestamps {
        deployed = false
        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        // The junit plugin doesn't affect full paths
        junit_resultdir = "results/${BUILD_NUMBER}/results_junit"
        env.common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${resultdir}/sumaform"
        stage('Clone terracumber, susemanager-ci and sumaform') {
            // Create a directory for  to place the directory with the build results (if it does not exist)
            sh "mkdir -p ${resultdir}"
            git url: params.terracumber_gitrepo, branch: params.terracumber_ref
            dir("susemanager-ci") {
                checkout scm
            }
            // Clone sumaform
            sh "set +x; source /home/jenkins/.credentials set -x; ./terracumber-cli ${common_params} --gitrepo ${params.sumaform_gitrepo} --gitref ${params.sumaform_ref} --runstep gitsync"
        }
        stage('Deploy') {
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
            writeFile file: "${env.resultdir}/sumaform/salt/mirror/etc/minima-customize.yaml", text: env.repositories, encoding: "UTF-8"
            sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision"
            deployed = true

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


    }
}

return this
