def run(params) {

    timestamps {
        list = ["Test-1", "Test-2", "Test-3", "Test-4", "Test-5"]

        stage('1') {
            def tests = [:]
            for (f in list) {
                tests["${f}"] = {
                    node {
                        stage("${f}") {
                            echo '${f}'
                        }
                    }
                }
            }
            parallel tests
        }
    }
}

return this