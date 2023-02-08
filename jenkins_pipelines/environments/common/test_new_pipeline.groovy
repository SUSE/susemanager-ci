pipeline{
    agent any
    stages{
        stage('CI'){
            steps{
                script {
                    doDynamicParallelSteps()
                }
            }
        }
    }
}

def doDynamicParallelSteps(){
    Set<String> envVar = new HashSet<String>()
    minions = sh(script: "source /home/maxime/.profile; printenv | grep MINION || exit 0",
            returnStdout: true)
    sshminion = sh(script: "source /home/maxime/.profile; printenv | grep SSHMINION || exit 0",
            returnStdout: true)
    client = sh(script: "source /home/maxime/.profile; printenv | grep CLIENT || exit 0",
            returnStdout: true)
    proxy = sh(script: "source /home/maxime/.profile; printenv | grep PROXY || exit 0",
            returnStdout: true)

    String[] minion_list = minions.split("\n")
    String[] sshminion_list = sshminion.split("\n")
    String[] client_list = client.split("\n")
    echo minion_list.join(", ")
    echo sshminion_list.join(", ")
    echo client_list.join(", ")

    def node_list = [minion_list, sshminion_list, client_list, proxy].flatten().findAll { it }

    // Create list ENV variable key
    echo node_list.join(", ")
    node_list.each { lane->
        def instanceList = lane.tokenize("=")
        envVar.add(instanceList[0])
    }

    node_list.each { element ->
        minionEnv = element.split("=")[0]
        temporaryList = envVar.toList() - minionEnv
        def minion = element.split("=")[0].toLowerCase()
        echo temporaryList.join(", ")
        tests["job-${minion}"] = {
            stage("${minion}") {
                echo minion
                sh(script: "source /home/maxime/.profile; printenv | grep MINION || exit 0")
            }
            stage("List without ${minion}") {
                echo minion
                sh(script: "source /home/maxime/.profile; unset ${temporaryList.join(" ")}; printenv | grep MINION || exit 0")
                sh(script: "source /home/maxime/.profile; unset ${temporaryList.join(" ")}; printenv | grep PROXY || exit 0")

            }
        }
    }
    parallel tests
}
