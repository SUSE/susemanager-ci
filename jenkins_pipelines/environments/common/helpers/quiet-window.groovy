// Weekly CI freeze (SUSE/spacewalk#31517): no run from Sunday 11:00 to Monday 05:00 (Europe/Berlin),
// so Jenkins and the infrastructure hosts can be updated on Monday morning.
//
// Usage, first statement of run() in a pipeline:
//     if (load('jenkins_pipelines/environments/common/helpers/quiet-window.groovy').skipIfQuiet()) { return }
//
// Options (all optional):
//     window:     "DAY HH:MM-DAY HH:MM" (MON..SUN), may wrap past Sunday. Empty disables the gate.
//     timezone:   timezone the window is evaluated in.
//     gateManual: also gate builds started by hand or by the hub. Default false: timer builds only.
//
// Returns true (and marks the build NOT_BUILT) when the run must be skipped.
// A malformed window fails open: it warns and the run proceeds.
import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException

def skipIfQuiet(Map opts = [:]) {
    String window = opts.containsKey('window') ? opts.window : 'SUN 11:00-MON 05:00'
    String tz = opts.timezone ?: 'Europe/Berlin'
    boolean gateManual = opts.gateManual ?: false
    if (!window?.trim()) {
        return false
    }
    def timerBuild = !currentBuild.getBuildCauses('hudson.triggers.TimerTrigger$TimerTriggerCause').isEmpty()
    if (!timerBuild && !gateManual) {
        return false
    }
    boolean inQuiet = false
    try {
        def days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
        def toMin = { String s ->
            def p = s.trim().split(' ')
            def hm = p[1].split(':')
            def d = days.indexOf(p[0].toUpperCase())
            if (d < 0) { error "bad day '${p[0]}'" }
            int h = hm[0].toInteger()
            int m = hm[1].toInteger()
            if (h < 0 || h > 23 || m < 0 || m > 59) { error "bad time '${p[1]}'" }
            d * 1440 + h * 60 + m
        }
        def parts = window.split('-')
        // date, not java.time/Calendar: stays inside the Pipeline sandbox whitelist
        def now = sh(script: "TZ=${tz} date +'%u %H %M'", returnStdout: true).trim().split(' ')
        int n = (now[0].toInteger() - 1) * 1440 + now[1].toInteger() * 60 + now[2].toInteger()
        int s = toMin(parts[0])
        int e = toMin(parts[1])
        inQuiet = s <= e ? (n >= s && n < e) : (n >= s || n < e)
    } catch (FlowInterruptedException err) {
        throw err  // aborted or timed out: never fail open into the deployment
    } catch (err) {
        println("WARNING: invalid quiet window '${window}' (${err}); running anyway")
    }
    if (inQuiet) {
        currentBuild.result = 'NOT_BUILT'
        currentBuild.description = "Skipped: quiet window ${window} (${tz})"
        println("Quiet window ${window} (${tz}) is active, skipping the run")
    }
    return inQuiet
}

return this
