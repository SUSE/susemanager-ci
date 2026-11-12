// Abort-safe steps for the `finally` of a pipeline (results, reports, cleanup).
//
// When a build is cancelled, the finally block still runs, but a second interrupt (or a hung ssh)
// makes the current step throw. One uncaught throw skips every step after it, so the results are
// never fetched or published. Wrap each finally step so the next one still runs.
//
// Usage, first statement of run() in a pipeline:
//     def safe = load('jenkins_pipelines/environments/common/helpers/safe-step.groovy')
// then, in the finally block:
//     safe.run('getresults') { sh "./terracumber-cli ... --runstep getresults" }
//
// Returns true when the body succeeded, false when it failed or was interrupted.
// Never rethrows. A failure marks the build FAILURE and an interrupt marks it ABORTED, so swallowing
// either cannot turn the build green; the finally block carries on with the next step.
import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException

def run(String label, Closure body) {
    try {
        body()
        return true
    } catch (FlowInterruptedException e) {
        println("ABORTED during '${label}': ${e.causes*.shortDescription.join(', ') ?: 'interrupted'}")
        currentBuild.result = 'ABORTED'
    } catch (Exception e) {
        println("ERROR: '${label}' failed: ${e}")
        // Same outcome as before the wrapper: a failed step fails the build, but the next steps still run.
        currentBuild.result = 'FAILURE'
    }
    return false
}

return this
