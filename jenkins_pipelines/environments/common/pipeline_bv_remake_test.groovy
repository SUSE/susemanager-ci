def run(params) {

    timestamps {
        list = ["Test-1", "Test-2", "Test-3", "Test-4", "Test-5"]

        stage('1') {
            minions = sh(script: "source /home/maxime/.profile; printenv | grep MINION || exit 0",
                    returnStdout: true)
            sshminion = sh(script: "source /home/maxime/.profile; printenv | grep SSHMINION || exit 0",
                    returnStdout: true)
            client = sh(script: "source /home/maxime/.profile; printenv | grep CLIENT || exit 0",
                    returnStdout: true)
            String[] minion_list = minions.split("\n")
            String[] sshminion_list = sshminion.split("\n")
            String[] client_list = client.split("\n")
            echo minion_list
            echo sshminion_list
            echo client_list

            def node_list = []
            def tests = [:]
            node_list.addAll(minion_list,sshminion_list,client_list)
            node_list.each{ element ->
                tests["${element}"] = {
                    node {
                        stage("${element}") {
                            echo "${element}"


                        }
                    }
                }
            }
            parallel tests
        }
    }
}

return this