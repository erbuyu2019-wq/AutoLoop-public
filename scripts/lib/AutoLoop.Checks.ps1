function Get-AutoLoopBoardStatuses {
    return @("todo", "doing", "blocked", "review", "done")
}

function Get-AutoLoopWorkerReportResults {
    return @("done", "partial", "blocked", "rejected")
}

function Get-AutoLoopWorkerReportNextSteps {
    return @("continue", "review", "needs coordinator decision", "needs user decision", "blocked")
}

function Get-AutoLoopWorkerReportEvidenceLevels {
    return @("local-readiness", "hardware-deferred", "live-smoke-required", "live-smoke-complete", "not applicable")
}
