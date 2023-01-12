def run(params) {

    timestamps {
        list = ["Test-1", "Test-2", "Test-3", "Test-4", "Test-5"]
        def tests = [:]
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
            echo minion_list.join(", ")
            echo sshminion_list.join(", ")
            echo client_list.join(", ")

            def node_list = [minion_list, sshminion_list, client_list].flatten().findAll{it}
            echo node_list.join(", ")
            node_list.each { element ->
                minion = element.split("=")[0]
                tests["${minion}"] = {
                    node {
                        stage("${minion}") {
                            echo "${minion}"


                        }
                    }
                }
            }
        }
        parallel tests

    }
}

return this