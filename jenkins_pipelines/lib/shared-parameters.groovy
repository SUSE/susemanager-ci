// shared-parameters.groovy
// Reusable parameter definitions for build validation pipelines

/**
 * Returns reactive parameters for proxy stages
 * These only appear when enable_proxy_stages is checked
 */
def getProxyStageParameters() {
    return [
        activeChoice(
            name: 'must_add_MU_repositories_proxy',
            description: 'Add MU channels for Proxy',
            choiceType: 'PT_SINGLE_SELECT',
            filterable: false,
            referencedParameters: 'enable_proxy_stages',
            script: [
                $class: 'GroovyScript',
                script: [
                    $class: 'SecureGroovyScript',
                    script: '''
                        if (enable_proxy_stages == 'true') {
                            return ['Yes', 'No']
                        }
                        return ['N/A (Proxy stages disabled)']
                    '''.stripIndent(),
                    sandbox: true
                ]
            ]
        ),
        activeChoice(
            name: 'must_add_keys_proxy',
            description: 'Add Activation Keys for Proxy',
            choiceType: 'PT_SINGLE_SELECT',
            filterable: false,
            referencedParameters: 'enable_proxy_stages',
            script: [
                $class: 'GroovyScript',
                script: [
                    $class: 'SecureGroovyScript',
                    script: '''
                        if (enable_proxy_stages == 'true') {
                            return ['Yes', 'No']
                        }
                        return ['N/A (Proxy stages disabled)']
                    '''.stripIndent(),
                    sandbox: true
                ]
            ]
        ),
        activeChoice(
            name: 'must_create_bootstrap_repos_proxy',
            description: 'Create bootstrap repositories for Proxy',
            choiceType: 'PT_SINGLE_SELECT',
            filterable: false,
            referencedParameters: 'enable_proxy_stages',
            script: [
                $class: 'GroovyScript',
                script: [
                    $class: 'SecureGroovyScript',
                    script: '''
                        if (enable_proxy_stages == 'true') {
                            return ['Yes', 'No']
                        }
                        return ['N/A (Proxy stages disabled)']
                    '''.stripIndent(),
                    sandbox: true
                ]
            ]
        ),
        activeChoice(
            name: 'must_boot_node_proxy',
            description: 'Bootstrap Proxy node',
            choiceType: 'PT_SINGLE_SELECT',
            filterable: false,
            referencedParameters: 'enable_proxy_stages',
            script: [
                $class: 'GroovyScript',
                script: [
                    $class: 'SecureGroovyScript',
                    script: '''
                        if (enable_proxy_stages == 'true') {
                            return ['Yes', 'No']
                        }
                        return ['N/A (Proxy stages disabled)']
                    '''.stripIndent(),
                    sandbox: true
                ]
            ]
        )
    ]
}

/**
 * Returns reactive parameters for monitoring stages
 */
def getMonitoringStageParameters() {
    return [
        activeChoice(
            name: 'must_add_MU_repositories_monitoring',
            description: 'Add MU channels for Monitoring',
            choiceType: 'PT_SINGLE_SELECT',
            filterable: false,
            referencedParameters: 'enable_monitoring_stages',
            script: [
                $class: 'GroovyScript',
                script: [
                    $class: 'SecureGroovyScript',
                    script: '''
                        if (enable_monitoring_stages == 'true') {
                            return ['Yes', 'No']
                        }
                        return ['N/A (Monitoring stages disabled)']
                    '''.stripIndent(),
                    sandbox: true
                ]
            ]
        ),
        activeChoice(
            name: 'must_add_keys_monitoring',
            description: 'Add Activation Keys for Monitoring',
            choiceType: 'PT_SINGLE_SELECT',
            filterable: false,
            referencedParameters: 'enable_monitoring_stages',
            script: [
                $class: 'GroovyScript',
                script: [
                    $class: 'SecureGroovyScript',
                    script: '''
                        if (enable_monitoring_stages == 'true') {
                            return ['Yes', 'No']
                        }
                        return ['N/A (Monitoring stages disabled)']
                    '''.stripIndent(),
                    sandbox: true
                ]
            ]
        ),
        activeChoice(
            name: 'must_create_bootstrap_repos_monitoring',
            description: 'Create bootstrap repositories for Monitoring',
            choiceType: 'PT_SINGLE_SELECT',
            filterable: false,
            referencedParameters: 'enable_monitoring_stages',
            script: [
                $class: 'GroovyScript',
                script: [
                    $class: 'SecureGroovyScript',
                    script: '''
                        if (enable_monitoring_stages == 'true') {
                            return ['Yes', 'No']
                        }
                        return ['N/A (Monitoring stages disabled)']
                    '''.stripIndent(),
                    sandbox: true
                ]
            ]
        ),
        activeChoice(
            name: 'must_boot_node_monitoring',
            description: 'Bootstrap Monitoring node',
            choiceType: 'PT_SINGLE_SELECT',
            filterable: false,
            referencedParameters: 'enable_monitoring_stages',
            script: [
                $class: 'GroovyScript',
                script: [
                    $class: 'SecureGroovyScript',
                    script: '''
                        if (enable_monitoring_stages == 'true') {
                            return ['Yes', 'No']
                        }
                        return ['N/A (Monitoring stages disabled)']
                    '''.stripIndent(),
                    sandbox: true
                ]
            ]
        )
    ]
}

/**
 * Returns reactive parameters for client stages
 */
def getClientStageParameters() {
    return [
        activeChoice(
            name: 'must_add_MU_repositories_client',
            description: 'Add MU channels for Clients',
            choiceType: 'PT_SINGLE_SELECT',
            filterable: false,
            referencedParameters: 'enable_client_stages',
            script: [
                $class: 'GroovyScript',
                script: [
                    $class: 'SecureGroovyScript',
                    script: '''
                        if (enable_client_stages == 'true') {
                            return ['Yes', 'No']
                        }
                        return ['N/A (Client stages disabled)']
                    '''.stripIndent(),
                    sandbox: true
                ]
            ]
        ),
        activeChoice(
            name: 'must_add_non_MU_repositories_client',
            description: 'Add non-MU repositories for Clients',
            choiceType: 'PT_SINGLE_SELECT',
            filterable: false,
            referencedParameters: 'enable_client_stages',
            script: [
                $class: 'GroovyScript',
                script: [
                    $class: 'SecureGroovyScript',
                    script: '''
                        if (enable_client_stages == 'true') {
                            return ['Yes', 'No']
                        }
                        return ['N/A (Client stages disabled)']
                    '''.stripIndent(),
                    sandbox: true
                ]
            ]
        ),
        activeChoice(
            name: 'must_add_keys_client',
            description: 'Add Activation Keys for Clients',
            choiceType: 'PT_SINGLE_SELECT',
            filterable: false,
            referencedParameters: 'enable_client_stages',
            script: [
                $class: 'GroovyScript',
                script: [
                    $class: 'SecureGroovyScript',
                    script: '''
                        if (enable_client_stages == 'true') {
                            return ['Yes', 'No']
                        }
                        return ['N/A (Client stages disabled)']
                    '''.stripIndent(),
                    sandbox: true
                ]
            ]
        ),
        activeChoice(
            name: 'must_create_bootstrap_repos_client',
            description: 'Create bootstrap repositories for Clients',
            choiceType: 'PT_SINGLE_SELECT',
            filterable: false,
            referencedParameters: 'enable_client_stages',
            script: [
                $class: 'GroovyScript',
                script: [
                    $class: 'SecureGroovyScript',
                    script: '''
                        if (enable_client_stages == 'true') {
                            return ['Yes', 'No']
                        }
                        return ['N/A (Client stages disabled)']
                    '''.stripIndent(),
                    sandbox: true
                ]
            ]
        ),
        activeChoice(
            name: 'must_boot_node_client',
            description: 'Bootstrap Client nodes',
            choiceType: 'PT_SINGLE_SELECT',
            filterable: false,
            referencedParameters: 'enable_client_stages',
            script: [
                $class: 'GroovyScript',
                script: [
                    $class: 'SecureGroovyScript',
                    script: '''
                        if (enable_client_stages == 'true') {
                            return ['Yes', 'No']
                        }
                        return ['N/A (Client stages disabled)']
                    '''.stripIndent(),
                    sandbox: true
                ]
            ]
        ),
        activeChoice(
            name: 'must_run_tests_client',
            description: 'Run smoke tests for Clients',
            choiceType: 'PT_SINGLE_SELECT',
            filterable: false,
            referencedParameters: 'enable_client_stages',
            script: [
                $class: 'GroovyScript',
                script: [
                    $class: 'SecureGroovyScript',
                    script: '''
                        if (enable_client_stages == 'true') {
                            return ['Yes', 'No']
                        }
                        return ['N/A (Client stages disabled)']
                    '''.stripIndent(),
                    sandbox: true
                ]
            ]
        )
    ]
}

/**
 * Helper function to check if a reactive parameter is enabled
 * Usage: isParamEnabled(params.must_add_MU_repositories_proxy)
 */
def isParamEnabled(paramValue) {
    return paramValue == 'Yes'
}

return this
