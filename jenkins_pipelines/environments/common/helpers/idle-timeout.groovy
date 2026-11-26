// Inactivity timeout for cucumber runs: aborts a step that has stopped producing output entirely.
// Shared by the common pipelines so the mechanism is defined once.
//
// Usage, next to the safe-step load at the top of run() in a pipeline:
//     def idle = load('jenkins_pipelines/environments/common/helpers/idle-timeout.groovy')
//     def idleMinutes = idle.minutesOr(params.cucumber_idle_timeout, 60)
// then around each cucumber sh:
//     idle.run(idleMinutes) { sh "./terracumber-cli ... --runstep cucumber ..." }
//
// A timeout surfaces as a FlowInterruptedException, which safe-step.groovy already handles.

// Anything that is not a positive number of minutes falls back to the default.
def minutesOr(value, int fallback) {
    def raw = value?.toString()?.trim()
    return raw?.isInteger() && raw.toInteger() > 0 ? raw.toInteger() : fallback
}

def run(int minutes, Closure body) {
    timeout(activity: true, time: minutes, unit: 'MINUTES') { body() }
}

return this
