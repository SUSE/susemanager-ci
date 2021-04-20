def run(params) {
    timestamps {
        // Retrieve the hash commit of the last product built in OBS/IBS and previous job
        def prefix = env.JOB_BASE_NAME.split('-acceptance-tests')[0]
        if (prefix == "uyuni-master-dev") {
            prefix = "manager-Head-dev"
        }
        // The 2obs jobs are releng, not dev
        prefix = prefix.replaceAll("-dev", "-releng")
        def request = httpRequest "https://ci.suse.de/job/${prefix}-2obs/lastBuild/api/json"
        def requestJson = readJSON text: request.getContent()
        def product_commit = "${requestJson.actions.lastBuiltRevision.SHA1}"
        product_commit = product_commit.substring(product_commit.indexOf('[') + 1, product_commit.indexOf(']'));
        print "Current product commit: ${product_commit}"
        def previous_commit = currentBuild.getPreviousBuild().description
        if (previous_commit == null) {
            previous_commit = product_commit
        } else {
            previous_commit = previous_commit.substring(previous_commit.indexOf('[') + 1, previous_commit.indexOf(']'));
        }
        print "Previous product commit: ${previous_commit}"
        // Start pipeline
        deployed = false
        env.resultdir = "${WORKSPACE}/results"
        env.resultdirbuild = "${resultdir}/${BUILD_NUMBER}"
        // The junit plugin doesn't affect full paths
        junit_resultdir = "results/${BUILD_NUMBER}/results_junit"
        env.common_params = "--outputdir ${resultdir} --tf ${params.tf_file} --gitfolder ${resultdir}/sumaform"
        try {
            stage('Clone terracumber, susemanager-ci and sumaform') {
                // Rename build using product commit hash
                currentBuild.description =  "[${product_commit}]"
                
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
                sh "set +x; source /home/jenkins/.credentials set -x; export TF_VAR_CUCUMBER_GITREPO=${params.cucumber_gitrepo}; export TF_VAR_CUCUMBER_BRANCH=${params.cucumber_ref}; export TERRAFORM=${params.terraform_bin}; export TERRAFORM_PLUGINS=${params.terraform_bin_plugins}; ./terracumber-cli ${common_params} --logfile ${resultdirbuild}/sumaform.log ${env.TERRAFORM_INIT} --taint '.*(domain|main_disk).*' --runstep provision"
                deployed = true
            }
            stage('Product changes') {
                sh """
                    # Comparison between:
                    #  - the previous git revision of spacewalk (or uyuni) repository pushed in IBS (or OBS)
                    #  - the git revision of the current spacewalk (or uyuni) repository pushed in IBS (or OBS)
                    # Note: This is a trade-off, we should be comparing the git revisions of all the packages composing our product
                    #       For that extra mile, we need a new tag in the repo metadata of each built, with the git revision of the related repository.
                """
                sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/; git --no-pager log --pretty=format:\"%h %<(16,trunc)%cn  %s  %d\" ${previous_commit}..${product_commit}'", returnStatus:true
            }
            stage('Sanity Check') {
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:sanity_check'"
            }
            stage('Core - Setup') {
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export LONG_TESTS=${params.long_tests}; cd /root/spacewalk/testsuite; rake cucumber:core'"
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export LONG_TESTS=${params.long_tests}; cd /root/spacewalk/testsuite; rake cucumber:reposync'"
            }
            stage('Core - Initialize clients') {
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export LONG_TESTS=${params.long_tests}; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:init_clients'"
            }
            stage('Secondary features') {
                def statusCode1 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export LONG_TESTS=${params.long_tests}; export PROFILE=${params.functional_scope}; cd /root/spacewalk/testsuite; rake cucumber:secondary'", returnStatus:true
                def statusCode2 = sh script:"./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'export LONG_TESTS=${params.long_tests}; export PROFILE=${params.functional_scope}; cd /root/spacewalk/testsuite; rake ${params.rake_namespace}:secondary_parallelizable'", returnStatus:true
                sh "exit \$(( ${statusCode1}|${statusCode2} ))"
            }
        }
        finally {
            stage('Get results') {
                def error = 0
                if (deployed) {
                    try {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake cucumber:finishing'"
                    } catch(Exception ex) {
                        println("ERROR: rake cucumber:finishing failed")
                        error = 1
                    }
                    try {
                        sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep cucumber --cucumber-cmd 'cd /root/spacewalk/testsuite; rake utils:generate_test_report'"
                    } catch(Exception ex) {
                        println("ERROR: rake utils:generate_test_repor failed")
                        error = 1
                    }
                    sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/testsuite.log --runstep getresults"
                    publishHTML( target: [
                                allowMissing: true,
                                alwaysLinkToLastBuild: false,
                                keepAll: true,
                                reportDir: "${resultdirbuild}/cucumber_report/",
                                reportFiles: 'cucumber_report.html',
                                reportName: "TestSuite Report"]
                    )
                    junit allowEmptyResults: true, testResults: "${junit_resultdir}/*.xml"
                }
                // Send email
                sh "./terracumber-cli ${common_params} --logfile ${resultdirbuild}/mail.log --runstep mail"
                // Clean up old results
                sh "./clean-old-results -r ${resultdir}"
                sh "exit ${error}"
            }
        }
    }
}

return this
