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
    def list_value = ["Test-1", "Test-2", "Test-3", "Test-4", "Test-5"]
    def minion
    def nodeList = []
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

    def node_list = [minion_list, sshminion_list, client_list].flatten().findAll { it }
    echo node_list.join(", ")
    node_list.each { lane->
        def instanceList = lane.tokenize("=")
        nodeList.add(instanceList[0])
    }
    echo nodeList.join(", ")
    def tests = [:]
    node_list.each { element ->
        def minionEnv = element.split("=")[0]
        minion = element.split("=")[0].toLowerCase()
        def temporaryList = nodeList.toList() - minionEnv
        echo nodeList.join(", ")
        tests["job-${minion}"] = {
            stage("${minion}") {
                echo minion
                sh(script: "source /home/maxime/.profile; printenv | grep MINION || exit 0")
            }
            stage("List without ${minion}") {
                echo minion
                sh(script: "source /home/maxime/.profile; unset ${temporaryList}; printenv | grep MINION || exit 0")
            }
        }
    }
    parallel tests
}
