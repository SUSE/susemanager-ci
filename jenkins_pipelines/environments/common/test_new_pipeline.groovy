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
    list = ["Test-1", "Test-2", "Test-3", "Test-4", "Test-5"]
    tests = [:]
    for (element in list) {
        tests["${element}"] = {
            node {
                stage("${element}") {
                    echo '${element}'
                }
            }
        }
    }
    parallel tests
}
