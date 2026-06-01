$RepoRoot = Split-Path -Parent $PSScriptRoot
$CheckIntegrationScript = Join-Path $RepoRoot "scripts\coordination\check-integration-review.ps1"

function New-AutoLoopTempDirectory {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("autoloop-test-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $path | Out-Null
    return $path
}

function New-TestWorkOrder {
    param(
        [string]$Root,
        [string]$Id = "T-010"
    )

    $path = Join-Path $Root "work-order.md"
    $content = @'
# Work Order

## Summary

- ID: `{ID}`
- Owner: `coordinator`
- Goal: Validate multi-owner readiness.
- Priority: `normal`
- Due / checkpoint: `next`

## Allowed Scope

- Files / modules allowed: `docs/coordination/`
- Behavior allowed to change: review only
- Tests / fixtures allowed: `tests/`

## Forbidden Scope

- Do not touch: hardware
- Do not change: deployment
- Stop and report if: live smoke is required

## Acceptance Commands

```powershell
test
```
'@
    $content = $content.Replace("{ID}", $Id)
    Set-Content -LiteralPath $path -Encoding UTF8 -Value $content
    return $path
}

function New-TestReport {
    param(
        [string]$Root,
        [string]$Owner,
        [string]$WorkOrderId = "T-010",
        [string]$Result = "done",
        [string]$NextStep = "review",
        [string]$PublicBehaviorChanged = "no",
        [string]$ApiChanged = "no",
        [string]$SecurityChanged = "no",
        [string]$DeploymentChanged = "no"
    )

    $path = Join-Path $Root ("report-$Owner.md")
    $content = @'
# Worker Report

## Summary

- Work order ID: `{WORK_ORDER_ID}`
- Owner: `{OWNER}`
- Result: `{RESULT}`
- Branch / workspace: `feature` / `.worktrees/$Owner`
- Report date: `2026-05-12`

## Changed Scope

| File / Area | Change | Reason |
| --- | --- | --- |
| `docs/coordination/{OWNER}.md` | reviewed | integration test |

## Verification

| Command | Result | Evidence |
| --- | --- | --- |
| `test` | passed | ok |

## Contract Impact

- Public behavior changed: {PUBLIC_BEHAVIOR_CHANGED}
- API / data model changed: {API_CHANGED}
- Security / secret handling changed: {SECURITY_CHANGED}
- Deployment / runtime behavior changed: {DEPLOYMENT_CHANGED}
- Details: none

## Not Verified

- none

## Risks

- none

## Next Suggested Step

- `{NEXT_STEP}`
- Reason: ready for coordinator review.
'@
    $content = $content.Replace("{WORK_ORDER_ID}", $WorkOrderId)
    $content = $content.Replace("{OWNER}", $Owner)
    $content = $content.Replace("{RESULT}", $Result)
    $content = $content.Replace("{PUBLIC_BEHAVIOR_CHANGED}", $PublicBehaviorChanged)
    $content = $content.Replace("{API_CHANGED}", $ApiChanged)
    $content = $content.Replace("{SECURITY_CHANGED}", $SecurityChanged)
    $content = $content.Replace("{DEPLOYMENT_CHANGED}", $DeploymentChanged)
    $content = $content.Replace("{NEXT_STEP}", $NextStep)
    Set-Content -LiteralPath $path -Encoding UTF8 -Value $content
    return $path
}

function Invoke-CheckIntegration {
    param(
        [string]$WorkOrderPath,
        [string[]]$ReportPaths,
        [string[]]$ExpectedOwners
    )

    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $CheckIntegrationScript,
        "-WorkOrderPath",
        $WorkOrderPath,
        "-ReportPaths",
        ($ReportPaths -join ";"),
        "-ExpectedOwners",
        ($ExpectedOwners -join ",")
    )

    $output = @(& powershell @arguments 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

Describe "check-integration-review.ps1" {
    It "accepts complete owner reports with no gates" {
        $root = New-AutoLoopTempDirectory
        try {
            $workOrder = New-TestWorkOrder -Root $root
            $appReport = New-TestReport -Root $root -Owner "app"
            $deviceReport = New-TestReport -Root $root -Owner "device"

            $result = Invoke-CheckIntegration -WorkOrderPath $workOrder -ReportPaths @($appReport, $deviceReport) -ExpectedOwners @("app", "device")
            $result.ExitCode | Should Be 0
            $result.Output | Should Match "Result: ACCEPT"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "holds when an expected owner report is missing" {
        $root = New-AutoLoopTempDirectory
        try {
            $workOrder = New-TestWorkOrder -Root $root
            $appReport = New-TestReport -Root $root -Owner "app"

            $result = Invoke-CheckIntegration -WorkOrderPath $workOrder -ReportPaths @($appReport) -ExpectedOwners @("app", "device")
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Result: HOLD"
            $result.Output | Should Match "Missing report for expected owner: device"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "holds when any report is partial" {
        $root = New-AutoLoopTempDirectory
        try {
            $workOrder = New-TestWorkOrder -Root $root
            $appReport = New-TestReport -Root $root -Owner "app"
            $deviceReport = New-TestReport -Root $root -Owner "device" -Result "partial" -NextStep "needs coordinator decision"

            $result = Invoke-CheckIntegration -WorkOrderPath $workOrder -ReportPaths @($appReport, $deviceReport) -ExpectedOwners @("app", "device")
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Result: HOLD"
            $result.Output | Should Match "Report is partial: device"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "requires user approval when a report has contract impact" {
        $root = New-AutoLoopTempDirectory
        try {
            $workOrder = New-TestWorkOrder -Root $root
            $appReport = New-TestReport -Root $root -Owner "app"
            $deviceReport = New-TestReport -Root $root -Owner "device" -ApiChanged "yes"

            $result = Invoke-CheckIntegration -WorkOrderPath $workOrder -ReportPaths @($appReport, $deviceReport) -ExpectedOwners @("app", "device")
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Result: NEEDS USER APPROVAL"
            $result.Output | Should Match "Contract impact requires user approval: device"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
