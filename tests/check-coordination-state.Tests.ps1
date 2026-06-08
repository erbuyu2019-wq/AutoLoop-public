$RepoRoot = Split-Path -Parent $PSScriptRoot
$CheckCoordinationStateScript = Join-Path $RepoRoot "scripts\coordination\check-coordination-state.ps1"
$CheckReportScript = Join-Path $RepoRoot "scripts\coordination\check-report.ps1"
$CheckWorkOrderScript = Join-Path $RepoRoot "scripts\coordination\check-work-order.ps1"

function New-AutoLoopTempDirectory {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("autoloop-test-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $path | Out-Null
    return $path
}

function New-TestCoordinationProject {
    param(
        [string]$Root,
        [string]$Rows
    )

    $coordinationRoot = Join-Path $Root "docs\coordination"
    New-Item -ItemType Directory -Path $coordinationRoot -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $coordinationRoot "work-orders") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $coordinationRoot "reports") -Force | Out-Null

    $board = Join-Path $coordinationRoot "board.md"
    Set-Content -LiteralPath $board -Encoding UTF8 -Value @"
# Coordination Board

Project: Test
Stage Goal: Check coordination state.
Last Updated: `2026-05-25`

## Owners

| Owner | Scope | Workspace / Thread | Notes |
| --- | --- | --- | --- |
| tools | scripts | local | test |

## Tasks

Use only these statuses: `todo`, `doing`, `blocked`, `review`, `done`.

| ID | Status | Owner | Task | Allowed Scope | Blocker / Risk | Next Step |
| --- | --- | --- | --- | --- | --- | --- |
$Rows

## Integration Notes

- Test board.
"@

    return $Root
}

function Add-TestReport {
    param(
        [string]$Root,
        [string]$Name,
        [string]$Content
    )

    $reportPath = Join-Path (Join-Path $Root "docs\coordination\reports") $Name
    Set-Content -LiteralPath $reportPath -Encoding UTF8 -Value $Content
    return $reportPath
}

function Add-TestWorkOrder {
    param(
        [string]$Root,
        [string]$Name,
        [string]$Content
    )

    $workOrderPath = Join-Path (Join-Path $Root "docs\coordination\work-orders") $Name
    Set-Content -LiteralPath $workOrderPath -Encoding UTF8 -Value $Content
    return $workOrderPath
}

function New-TestWorkerReportContent {
    param(
        [string]$Result = "done",
        [string]$EvidenceLevel = "local-readiness",
        [string]$NextStep = "review",
        [string]$VerificationResult = "passed",
        [string[]]$OmitSections = @(),
        [string[]]$PlaceholderSections = @()
    )

    $omitSectionLookup = @{}
    foreach ($sectionName in @($OmitSections)) {
        if ($sectionName) {
            $omitSectionLookup[$sectionName] = $true
        }
    }

    $placeholderSectionLookup = @{}
    foreach ($sectionName in @($PlaceholderSections)) {
        if ($sectionName) {
            $placeholderSectionLookup[$sectionName] = $true
        }
    }

    $parts = New-Object System.Collections.Generic.List[string]
    $parts.Add(@"
# Worker Report

## Summary

- Work order ID: T-001
- Owner: tools
- Result: $Result
- Branch / workspace: feature / path
- Report date: 2026-05-25
- Evidence level: $EvidenceLevel
"@.Trim()) | Out-Null

    $sectionBodies = [ordered]@{
        "Changed Scope" = @"
| File / Area | Change | Reason |
| --- | --- | --- |
| scripts/tool.ps1 | changed | test |
"@.Trim()
        "Verification" = @"
| Command | Result | Evidence |
| --- | --- | --- |
| test | $VerificationResult | evidence |
"@.Trim()
        "Contract Impact" = @"
- Public behavior changed: no
- API / data model changed: no
- Security / secret handling changed: no
- Deployment / runtime behavior changed: no
- Details: none
"@.Trim()
        "Not Verified" = @"
- none
"@.Trim()
        "Risks" = @"
- none
"@.Trim()
    }

    $placeholderBodies = [ordered]@{
        "Changed Scope" = @"
| File / Area | Change | Reason |
| --- | --- | --- |
"@.Trim()
        "Verification" = @"
| Command | Result | Evidence |
| --- | --- | --- |
"@.Trim()
        "Contract Impact" = "- <impact>"
        "Not Verified" = "- <not verified>"
        "Risks" = "- <risk>"
    }

    foreach ($sectionName in $sectionBodies.Keys) {
        if ($omitSectionLookup[$sectionName]) {
            continue
        }

        $body = $sectionBodies[$sectionName]
        if ($placeholderSectionLookup[$sectionName]) {
            $body = $placeholderBodies[$sectionName]
        }

        $parts.Add(("## {0}`r`n`r`n{1}" -f $sectionName, $body).Trim()) | Out-Null
    }

    $parts.Add(@"
## Next Suggested Step

- $NextStep
- Reason: test.
"@.Trim()) | Out-Null

    return (($parts.ToArray() -join "`r`n`r`n") + "`r`n")
}

function Invoke-CheckReport {
    param(
        [string]$ReportPath,
        [switch]$Strict
    )

    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $CheckReportScript,
        "-ReportPath",
        $ReportPath
    )

    if ($Strict) {
        $arguments += "-Strict"
    }

    $output = @(& powershell @arguments 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

function Invoke-CheckWorkOrder {
    param([string]$WorkOrderPath)

    $output = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $CheckWorkOrderScript -WorkOrderPath $WorkOrderPath 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

function Invoke-CheckCoordinationState {
    param(
        [string]$ProjectRoot,
        [switch]$Brownfield,
        [switch]$Json
    )

    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $CheckCoordinationStateScript,
        "-ProjectRoot",
        $ProjectRoot
    )

    if ($Brownfield) {
        $arguments += "-Brownfield"
    }

    if ($Json) {
        $arguments += "-Json"
    }

    $output = @(& powershell @arguments 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

Describe "check-coordination-state.ps1" {
    It "summarizes the current repository without failing" {
        $result = Invoke-CheckCoordinationState -ProjectRoot $RepoRoot
        $result.ExitCode | Should Be 0
        $result.Output | Should Match "AutoLoop coordination state check"
        $result.Output | Should Match "Result:"
        $result.Output | Should Match "\[INFO\] Board protocol check passed"
    }

    It "returns HOLD without failing when the board has blocked or review tasks" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | blocked | tools | Wait for gate | scripts | user approval needed | Ask user |" | Out-Null
            $result = Invoke-CheckCoordinationState -ProjectRoot $root
            $result.ExitCode | Should Be 0
            $result.Output | Should Match "Result: HOLD"
            $result.Output | Should Match "\[HOLD\] Board task blocked: T-001"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "returns FAIL when the board protocol is broken" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | started |  |  |  | none |  |" | Out-Null
            $result = Invoke-CheckCoordinationState -ProjectRoot $root
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Result: FAIL"
            $result.Output | Should Match "\[FAIL\] Board protocol check failed"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "does not fail coordinator reports that are not worker reports" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | todo | tools | Coordinate review | docs | none | Prepare worker order |" | Out-Null
            $reportContent = @'
# Coordinator Review

## Summary

- Work order ID: `T-001`
- Coordinator decision: `hold`

## Reviewed Reports

| Report | Result |
| --- | --- |
| `worker.md` | PASS |

## Not Verified

- Live hardware path.
'@
            Add-TestReport -Root $root -Name "T-001-coordinator-review.md" -Content $reportContent | Out-Null

            $result = Invoke-CheckCoordinationState -ProjectRoot $root
            $result.ExitCode | Should Be 0
            $result.Output | Should Not Match "Result: FAIL"
            $result.Output | Should Match "Report scan: total=1, worker=0, non-worker=1, invalid=0"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "fails incomplete worker reports without requiring external strict report processes" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | todo | tools | Implement slice | scripts | none | Dispatch worker |" | Out-Null
            $reportContent = @'
# Worker Report

## Summary

- Work order ID: `T-001`
- Owner: `tools`
- Result: `done`
'@
            Add-TestReport -Root $root -Name "T-001-worker-report.md" -Content $reportContent | Out-Null

            $result = Invoke-CheckCoordinationState -ProjectRoot $root
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Result: FAIL"
            $result.Output | Should Match "\[FAIL\] Worker report checks failed: T-001-worker-report.md"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "downgrades worker report strict shape failures in brownfield JSON" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | todo | tools | Implement slice | scripts | none | Dispatch worker |" | Out-Null
            $reportContent = @'
# Worker Report

## Summary

- Work order ID: `T-001`
- Owner: `tools`
- Result: `done`
'@
            Add-TestReport -Root $root -Name "T-001-worker-report.md" -Content $reportContent | Out-Null

            $result = Invoke-CheckCoordinationState -ProjectRoot $root -Brownfield -Json
            $state = $result.Output | ConvertFrom-Json

            $result.ExitCode | Should Be 0
            $state.result | Should Be "WARN"
            $state.reportValidationMode | Should Be "brownfield"
            $state.summary.reports.strictFailedWorker | Should Be 1
            $state.summary.reports.warnOnlyWorker | Should Be 1
            $state.summary.reports.failedWorker | Should Be 0
            @($state.findings | Where-Object { $_.severity -eq "WARN" -and $_.message -match "Worker report strict shape warnings in brownfield mode" }).Count | Should Be 1
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "keeps board protocol failures as FAIL in brownfield JSON" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | started |  |  |  | none |  |" | Out-Null

            $result = Invoke-CheckCoordinationState -ProjectRoot $root -Brownfield -Json
            $state = $result.Output | ConvertFrom-Json

            $result.ExitCode | Should Be 1
            $state.result | Should Be "FAIL"
            $state.reportValidationMode | Should Be "brownfield"
            @($state.findings | Where-Object { $_.severity -eq "FAIL" -and $_.message -match "Board protocol check failed" }).Count | Should Be 1
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "keeps work-order failures as FAIL in brownfield JSON" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | todo | tools | Implement slice | scripts | none | Dispatch worker |" | Out-Null
            $workOrderContent = @'
# Work Order

## Summary

- ID: `T-001`
- Owner: `tools`
- Goal: Test work order.
- Priority: `normal`

## Allowed Scope

- Files / modules allowed: `scripts/`
- Behavior allowed to change: docs only
- Tests / fixtures allowed: `tests/`

## Forbidden Scope

- Do not touch: `docs/coordination/board.md`
- Do not change: task state
- Stop and report if: scope changes

## Acceptance Commands

Run checks.

```powershell
```
'@
            Add-TestWorkOrder -Root $root -Name "T-001-empty-commands.md" -Content $workOrderContent | Out-Null

            $result = Invoke-CheckCoordinationState -ProjectRoot $root -Brownfield -Json
            $state = $result.Output | ConvertFrom-Json

            $result.ExitCode | Should Be 1
            $state.result | Should Be "FAIL"
            $state.reportValidationMode | Should Be "brownfield"
            @($state.findings | Where-Object { $_.severity -eq "FAIL" -and $_.message -match "Work order checks failed" }).Count | Should Be 1
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "keeps unreadable report files as FAIL in brownfield JSON" {
        $root = New-AutoLoopTempDirectory
        $stream = $null
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | todo | tools | Implement slice | scripts | none | Dispatch worker |" | Out-Null
            $reportPath = Add-TestReport -Root $root -Name "T-001-worker-report.md" -Content "# Worker Report"
            $stream = [System.IO.File]::Open($reportPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)

            $result = Invoke-CheckCoordinationState -ProjectRoot $root -Brownfield -Json
            $state = $result.Output | ConvertFrom-Json

            $result.ExitCode | Should Be 1
            $state.result | Should Be "FAIL"
            $state.reportValidationMode | Should Be "brownfield"
            $state.summary.reports.invalid | Should Be 1
            @($state.findings | Where-Object { $_.severity -eq "FAIL" -and $_.message -match "Report files could not be read" }).Count | Should Be 1
        } finally {
            if ($null -ne $stream) {
                $stream.Dispose()
            }
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "matches strict worker report failure for invalid result values" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | todo | tools | Implement slice | scripts | none | Dispatch worker |" | Out-Null
            $reportContent = @'
# Worker Report

## Summary

- Work order ID: `T-001`
- Owner: `tools`
- Result: `success`
- Branch / workspace: `feature` / `path`
- Report date: `2026-05-25`
- Evidence level: `local-readiness`

## Changed Scope

| File / Area | Change | Reason |
| --- | --- | --- |
| `scripts/tool.ps1` | changed | test |

## Verification

| Command | Result | Evidence |
| --- | --- | --- |
| `test` | passed | ok |

## Contract Impact

- Public behavior changed: no
- API / data model changed: no
- Security / secret handling changed: no
- Deployment / runtime behavior changed: no
- Details: none

## Not Verified

- none

## Risks

- none

## Next Suggested Step

- `review`
- Reason: ready for review.
'@
            $reportPath = Add-TestReport -Root $root -Name "T-001-worker-report.md" -Content $reportContent

            $strictResult = Invoke-CheckReport -ReportPath $reportPath -Strict
            $stateResult = Invoke-CheckCoordinationState -ProjectRoot $root

            $strictResult.ExitCode | Should Not Be 0
            $strictResult.Output | Should Match "Invalid result value"
            $stateResult.ExitCode | Should Not Be 0
            $stateResult.Output | Should Match "\[FAIL\] Worker report checks failed: T-001-worker-report.md"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "matches strict worker report failure for invalid evidence levels" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | todo | tools | Implement slice | scripts | none | Dispatch worker |" | Out-Null
            $reportContent = @'
# Worker Report

## Summary

- Work order ID: `T-001`
- Owner: `tools`
- Result: `done`
- Branch / workspace: `feature` / `path`
- Report date: `2026-05-25`
- Evidence level: `unverified`

## Changed Scope

| File / Area | Change | Reason |
| --- | --- | --- |
| `scripts/tool.ps1` | changed | test |

## Verification

| Command | Result | Evidence |
| --- | --- | --- |
| `test` | passed | ok |

## Contract Impact

- Public behavior changed: no
- API / data model changed: no
- Security / secret handling changed: no
- Deployment / runtime behavior changed: no
- Details: none

## Not Verified

- none

## Risks

- none

## Next Suggested Step

- `review`
- Reason: ready for review.
'@
            $reportPath = Add-TestReport -Root $root -Name "T-001-worker-report.md" -Content $reportContent

            $strictResult = Invoke-CheckReport -ReportPath $reportPath -Strict
            $stateResult = Invoke-CheckCoordinationState -ProjectRoot $root

            $strictResult.ExitCode | Should Not Be 0
            $strictResult.Output | Should Match "Invalid evidence level value: unverified"
            $stateResult.ExitCode | Should Not Be 0
            $stateResult.Output | Should Match "\[FAIL\] Worker report checks failed: T-001-worker-report.md"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "matches strict worker report failure for failed verification rows with pipeline commands" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | todo | tools | Implement slice | scripts | none | Dispatch worker |" | Out-Null
            $reportContent = @'
# Worker Report

## Summary

- Work order ID: `T-001`
- Owner: `tools`
- Result: `done`
- Branch / workspace: `feature` / `path`
- Report date: `2026-05-25`
- Evidence level: `local-readiness`

## Changed Scope

| File / Area | Change | Reason |
| --- | --- | --- |
| `scripts/tool.ps1` | changed | test |

## Verification

| Command | Result | Evidence |
| --- | --- | --- |
| `Get-ChildItem | Select-Object -First 1` | failed | failed output |

## Contract Impact

- Public behavior changed: no
- API / data model changed: no
- Security / secret handling changed: no
- Deployment / runtime behavior changed: no
- Details: none

## Not Verified

- none

## Risks

- none

## Next Suggested Step

- `continue`
- Reason: continue.
'@
            Add-TestReport -Root $root -Name "T-001-worker-report.md" -Content $reportContent | Out-Null

            $result = Invoke-CheckCoordinationState -ProjectRoot $root

            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Result: FAIL"
            $result.Output | Should Match "\[FAIL\] Worker report checks failed: T-001-worker-report.md"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "matches strict worker report failure shapes across direct and aggregate checks" {
        $cases = @(
            [pscustomobject]@{
                Name = "invalid-result"
                Content = New-TestWorkerReportContent -Result "success"
                DirectPattern = "Invalid result value"
            },
            [pscustomobject]@{
                Name = "invalid-evidence-level"
                Content = New-TestWorkerReportContent -EvidenceLevel "unverified"
                DirectPattern = "Invalid evidence level value"
            },
            [pscustomobject]@{
                Name = "invalid-next-step"
                Content = New-TestWorkerReportContent -NextStep "ship"
                DirectPattern = "Invalid next suggested step"
            },
            [pscustomobject]@{
                Name = "missing-required-section"
                Content = New-TestWorkerReportContent -OmitSections @("Contract Impact")
                DirectPattern = "Missing sections:"
            },
            [pscustomobject]@{
                Name = "placeholder-only-section"
                Content = New-TestWorkerReportContent -PlaceholderSections @("Changed Scope")
                DirectPattern = "Empty or placeholder-only sections:"
            },
            [pscustomobject]@{
                Name = "done-not-run-verification"
                Content = New-TestWorkerReportContent -VerificationResult "not run" -NextStep "continue"
                DirectPattern = "done report has failed or not-run verification"
            }
        )

        foreach ($case in $cases) {
            $root = New-AutoLoopTempDirectory
            try {
                New-TestCoordinationProject -Root $root -Rows "| T-001 | todo | tools | Implement slice | scripts | none | Dispatch worker |" | Out-Null
                $reportName = "T-001-$($case.Name)-worker-report.md"
                $reportPath = Add-TestReport -Root $root -Name $reportName -Content $case.Content

                $strictResult = Invoke-CheckReport -ReportPath $reportPath -Strict
                $stateResult = Invoke-CheckCoordinationState -ProjectRoot $root

                $strictResult.ExitCode | Should Not Be 0
                $strictResult.Output | Should Match $case.DirectPattern
                $stateResult.ExitCode | Should Not Be 0
                $stateResult.Output | Should Match "Result: FAIL"
                $stateResult.Output | Should Match "\[FAIL\] Worker report checks failed: $reportName"
            } finally {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It "matches work-order failure for empty acceptance commands" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | todo | tools | Implement slice | scripts | none | Dispatch worker |" | Out-Null
            $workOrderContent = @'
# Work Order

## Summary

- ID: `T-001`
- Owner: `tools`
- Goal: Test work order.
- Priority: `normal`
- Due / checkpoint: `next`

## Allowed Scope

- Files / modules allowed: `scripts/`
- Behavior allowed to change: docs only
- Tests / fixtures allowed: `tests/`

## Forbidden Scope

- Do not touch: `docs/coordination/board.md`
- Do not change: task state
- Stop and report if: scope changes

## Acceptance Commands

Run checks.

```powershell
```
'@
            $workOrderPath = Add-TestWorkOrder -Root $root -Name "T-001-empty-commands.md" -Content $workOrderContent

            $workOrderResult = Invoke-CheckWorkOrder -WorkOrderPath $workOrderPath
            $stateResult = Invoke-CheckCoordinationState -ProjectRoot $root

            $workOrderResult.ExitCode | Should Not Be 0
            $workOrderResult.Output | Should Match "Acceptance commands are empty"
            $stateResult.ExitCode | Should Not Be 0
            $stateResult.Output | Should Match "\[FAIL\] Work order checks failed: T-001-empty-commands.md"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "emits parseable JSON with stable result and summary fields" {
        $result = Invoke-CheckCoordinationState -ProjectRoot $RepoRoot -Json
        $result.ExitCode | Should Be 0
        $result.Output | Should Not Match "AutoLoop coordination state check"

        $state = $result.Output | ConvertFrom-Json
        $state.tool | Should Be "autoloop-check-coordination-state"
        $state.schemaVersion | Should Be "1.0"
        $state.projectRoot | Should Be (Resolve-Path -LiteralPath $RepoRoot).Path
        $state.reportValidationMode | Should Be "strict"
        @("INFO", "WARN", "HOLD", "FAIL") -contains $state.result | Should Be $true
        @($state.findings).Count | Should BeGreaterThan 0
        $state.summary.findingCounts.INFO | Should Not BeNullOrEmpty
        $state.summary.board.taskCount | Should Not BeNullOrEmpty
        $state.summary.workOrders.total | Should Not BeNullOrEmpty
        $state.summary.reports.total | Should Not BeNullOrEmpty
        $state.summary.reports.strictFailedWorker | Should Not BeNullOrEmpty
        $state.summary.reports.warnOnlyWorker | Should Not BeNullOrEmpty
    }

    It "returns HOLD JSON with exit code 0" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | blocked | tools | Wait for gate | scripts | user approval needed | Ask user |" | Out-Null
            $result = Invoke-CheckCoordinationState -ProjectRoot $root -Json
            $state = $result.Output | ConvertFrom-Json

            $result.ExitCode | Should Be 0
            $state.result | Should Be "HOLD"
            @($state.findings | Where-Object { $_.severity -eq "HOLD" }).Count | Should Be 1
            $state.summary.findingCounts.HOLD | Should Be 1
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "returns FAIL JSON with exit code 1" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | started |  |  |  | none |  |" | Out-Null
            $result = Invoke-CheckCoordinationState -ProjectRoot $root -Json
            $state = $result.Output | ConvertFrom-Json

            $result.ExitCode | Should Be 1
            $state.result | Should Be "FAIL"
            @($state.findings | Where-Object { $_.severity -eq "FAIL" }).Count | Should Be 1
            $state.summary.findingCounts.FAIL | Should Be 1
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "keeps JSON finding severity and result values stable" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | review | tools | Review slice | scripts | none | Review report |" | Out-Null
            $result = Invoke-CheckCoordinationState -ProjectRoot $root -Json
            $state = $result.Output | ConvertFrom-Json

            $result.ExitCode | Should Be 0
            $state.result | Should Be "HOLD"
            foreach ($finding in @($state.findings)) {
                @("INFO", "WARN", "HOLD", "FAIL") -contains $finding.severity | Should Be $true
                $finding.message | Should Not BeNullOrEmpty
            }
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "reports dirty git repositories in JSON summary" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | todo | tools | Prepare slice | scripts | none | Start work |" | Out-Null
            & git -C $root init | Out-Null

            $result = Invoke-CheckCoordinationState -ProjectRoot $root -Json
            $state = $result.Output | ConvertFrom-Json

            $result.ExitCode | Should Be 0
            $state.result | Should Be "WARN"
            $state.summary.git.gitAvailable | Should Be $true
            $state.summary.git.rootChecked | Should Be 1
            $state.summary.git.dirtyRepositories | Should Be 1
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
