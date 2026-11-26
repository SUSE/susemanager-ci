// One place that builds and runs a terracumber cucumber step, with the idle timeout applied.
//
// Usage, in run() of a pipeline, once common_params, resultdirbuild and exports are final:
//     def idle = load('jenkins_pipelines/environments/common/helpers/idle-timeout.groovy')
//     def cuc  = load('jenkins_pipelines/environments/common/helpers/cucumber.groovy')
//     def cx   = cuc.context(commonParams: common_params, resultdirbuild: resultdirbuild,
//                            exports: exports, idleMinutes: idleMinutes, idle: idle)
// then, per rake target:
//     cuc.rake(cx, 'cucumber:core')                                     // throws when the step fails
//     def st = cuc.rake(cx, 'cucumber:x', [returnStatus: true])         // returns the exit status
//
// The context is a plain map and the helper keeps no state, so a later change of exports is just
// `cx.exports = ...`. A pipeline that calls rake() from methods outside run() must keep `cx` as a
// script binding (assigned without `def`), like cucumberIdleTimeoutMinutes in the BV pipelines.
//
// Options (all optional) of rake():
//     returnStatus: true     return the exit status instead of throwing
//     idleMinutes:  N        idle timeout for this call; 0 disables it (default: the context value)
//     wallSeconds:  N        wall-clock limit enforced by coreutils timeout (exit 124, or 137 if it had to
//                            be killed). Do not use Jenkins timeout() for this: stopping one sh step kills
//                            every sh step of the same workspace (durable-task kills by a workspace-wide
//                            cookie), i.e. all parallel branches.
//     unset:      list or space-separated string of environment variables to unset first
//     prefix:     shell fragment inserted before the exports, e.g. 'export TAGS=...; '
//     exports:    replaces the context exports for this call

def context(Map cfg) {
    return [
        commonParams  : cfg.commonParams.toString(),
        resultdirbuild: cfg.resultdirbuild.toString(),
        exports       : cfg.exports.toString(),
        idleMinutes   : cfg.idleMinutes as int,
        idle          : cfg.idle,
    ]
}

// Pure string building, no pipeline steps: kept apart so it can be checked outside Jenkins.
def command(Map cx, String target, Map o = [:]) {
    String unset = ''
    if (o.unset) {
        def vars = o.unset instanceof CharSequence ? o.unset.toString().trim().split(/\s+/) : o.unset
        unset = "unset ${vars.join(' ')}; "
    }
    String prefix = o.prefix ?: ''
    String exports = o.containsKey('exports') ? o.exports : cx.exports
    String wall = o.wallSeconds ? "timeout -k 30 -s TERM ${o.wallSeconds}s " : ''
    return "${wall}./terracumber-cli ${cx.commonParams} \\\n" +
           "    --logfile ${cx.resultdirbuild}/testsuite.log \\\n" +
           "    --runstep cucumber \\\n" +
           "    --cucumber-cmd '${unset}${prefix}${exports} cd /root/spacewalk/testsuite; rake ${target}'"
}

def rake(Map cx, String target, Map o = [:]) {
    String cmd = command(cx, target, o)
    boolean returnStatus = o.returnStatus ? true : false
    int minutes = o.idleMinutes == null ? cx.idleMinutes : (o.idleMinutes as int)
    def status = 0
    def step = {
        if (returnStatus) {
            status = sh(script: cmd, returnStatus: true)
        } else {
            sh(script: cmd)
        }
    }
    if (minutes > 0) {
        cx.idle.run(minutes, step)
    } else {
        step()
    }
    return returnStatus ? status : null
}

return this
