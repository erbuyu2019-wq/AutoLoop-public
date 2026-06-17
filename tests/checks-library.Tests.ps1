$RepoRoot = Split-Path -Parent $PSScriptRoot
$ChecksLibrary = Join-Path $RepoRoot "scripts\lib\AutoLoop.Checks.ps1"
. $ChecksLibrary

Describe "AutoLoop.Checks.ps1" {
    It "pins board status values" {
        @(Get-AutoLoopBoardStatuses) | Should Be @("todo", "doing", "blocked", "review", "done")
    }

    It "pins worker report result values" {
        @(Get-AutoLoopWorkerReportResults) | Should Be @("done", "partial", "blocked", "rejected")
    }

    It "pins worker report next-step values" {
        @(Get-AutoLoopWorkerReportNextSteps) | Should Be @("continue", "review", "needs coordinator decision", "needs user decision", "blocked")
    }

    It "pins worker report evidence-level values" {
        @(Get-AutoLoopWorkerReportEvidenceLevels) | Should Be @("local-readiness", "hardware-deferred", "live-smoke-required", "live-smoke-complete", "not applicable")
    }
}
