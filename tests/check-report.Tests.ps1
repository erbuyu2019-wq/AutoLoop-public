$RepoRoot = Split-Path -Parent $PSScriptRoot
$CheckReportScript = Join-Path $RepoRoot "scripts\coordination\check-report.ps1"
$ChecksLibrary = Join-Path $RepoRoot "scripts\lib\AutoLoop.Checks.ps1"
$DogfoodReport = Join-Path $RepoRoot "docs\coordination\reports\phase6-dogfood-worker-report.md"
$ReportTemplate = Join-Path $RepoRoot "templates\coordination\worker-report.md"
. $ChecksLibrary

function New-AutoLoopTempDirectory {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("autoloop-test-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $path | Out-Null
    return $path
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

Describe "check-report.ps1" {
    It "pins the shared strict worker-report values" {
        @(Get-AutoLoopWorkerReportResults) | Should Be @("done", "partial", "blocked", "rejected")
        @(Get-AutoLoopWorkerReportEvidenceLevels) | Should Be @("local-readiness", "hardware-deferred", "live-smoke-required", "live-smoke-complete", "not applicable")
        @(Get-AutoLoopWorkerReportNextSteps) | Should Be @("continue", "review", "needs coordinator decision", "needs user decision", "blocked")
    }

    It "passes a complete report" {
        $result = Invoke-CheckReport -ReportPath $DogfoodReport
        $result.ExitCode | Should Be 0
        $result.Output | Should Match "Result: PASS"
    }

    It "fails a report with missing required sections" {
        $root = New-AutoLoopTempDirectory
        try {
            $report = Join-Path $root "missing.md"
            Set-Content -LiteralPath $report -Encoding UTF8 -Value @'
# Worker Report

## Summary

- Work order ID: `T-001`
'@
            $result = Invoke-CheckReport -ReportPath $report
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Missing sections:"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "fails a placeholder-only template report" {
        $result = Invoke-CheckReport -ReportPath $ReportTemplate
        $result.ExitCode | Should Not Be 0
        $result.Output | Should Match "Empty or placeholder-only sections:"
    }

    It "passes strict checks for the dogfood report" {
        $result = Invoke-CheckReport -ReportPath $DogfoodReport -Strict
        $result.ExitCode | Should Be 0
        $result.Output | Should Match "Result: PASS"
    }

    It "fails strict checks for an invalid result value" {
        $root = New-AutoLoopTempDirectory
        try {
            $report = Join-Path $root "invalid-result.md"
            Set-Content -LiteralPath $report -Encoding UTF8 -Value @'
# Worker Report

## Summary

- Work order ID: `T-001`
- Owner: `app`
- Result: `success`
- Branch / workspace: `feature` / `path`
- Report date: `2026-05-11`
- Evidence level: `local-readiness`

## Changed Scope

| File / Area | Change | Reason |
| --- | --- | --- |
| `src/app/file.py` | changed | test |

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
            $result = Invoke-CheckReport -ReportPath $report -Strict
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Invalid result value"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "fails strict checks when evidence level is missing" {
        $root = New-AutoLoopTempDirectory
        try {
            $report = Join-Path $root "missing-evidence-level.md"
            Set-Content -LiteralPath $report -Encoding UTF8 -Value @'
# Worker Report

## Summary

- Work order ID: `T-001`
- Owner: `app`
- Result: `done`
- Branch / workspace: `feature` / `path`
- Report date: `2026-05-11`

## Changed Scope

| File / Area | Change | Reason |
| --- | --- | --- |
| `src/app/file.py` | changed | test |

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
            $result = Invoke-CheckReport -ReportPath $report -Strict
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Invalid evidence level value"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "fails strict checks for an invalid evidence level" {
        $root = New-AutoLoopTempDirectory
        try {
            $report = Join-Path $root "invalid-evidence-level.md"
            Set-Content -LiteralPath $report -Encoding UTF8 -Value @'
# Worker Report

## Summary

- Work order ID: `T-001`
- Owner: `app`
- Result: `done`
- Branch / workspace: `feature` / `path`
- Report date: `2026-05-11`
- Evidence level: `unverified`

## Changed Scope

| File / Area | Change | Reason |
| --- | --- | --- |
| `src/app/file.py` | changed | test |

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
            $result = Invoke-CheckReport -ReportPath $report -Strict
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Invalid evidence level value: unverified"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "fails strict checks for a placeholder evidence level" {
        $root = New-AutoLoopTempDirectory
        try {
            $report = Join-Path $root "placeholder-evidence-level.md"
            Set-Content -LiteralPath $report -Encoding UTF8 -Value @'
# Worker Report

## Summary

- Work order ID: `T-001`
- Owner: `app`
- Result: `done`
- Branch / workspace: `feature` / `path`
- Report date: `2026-05-11`
- Evidence level: `<local-readiness | hardware-deferred | live-smoke-required | live-smoke-complete | not applicable>`

## Changed Scope

| File / Area | Change | Reason |
| --- | --- | --- |
| `src/app/file.py` | changed | test |

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
            $result = Invoke-CheckReport -ReportPath $report -Strict
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Invalid evidence level value"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "fails strict checks when done has failed verification" {
        $root = New-AutoLoopTempDirectory
        try {
            $report = Join-Path $root "failed-done.md"
            Set-Content -LiteralPath $report -Encoding UTF8 -Value @'
# Worker Report

## Summary

- Work order ID: `T-001`
- Owner: `app`
- Result: `done`
- Branch / workspace: `feature` / `path`
- Report date: `2026-05-11`
- Evidence level: `local-readiness`

## Changed Scope

| File / Area | Change | Reason |
| --- | --- | --- |
| `src/app/file.py` | changed | test |

## Verification

| Command | Result | Evidence |
| --- | --- | --- |
| `test` | failed | failed output |

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
            $result = Invoke-CheckReport -ReportPath $report -Strict
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "done report has failed or not-run verification"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "fails strict checks when done has failed verification and the command contains a pipeline" {
        $root = New-AutoLoopTempDirectory
        try {
            $report = Join-Path $root "failed-done-pipeline.md"
            Set-Content -LiteralPath $report -Encoding UTF8 -Value @'
# Worker Report

## Summary

- Work order ID: `T-001`
- Owner: `app`
- Result: `done`
- Branch / workspace: `feature` / `path`
- Report date: `2026-05-11`
- Evidence level: `local-readiness`

## Changed Scope

| File / Area | Change | Reason |
| --- | --- | --- |
| `src/app/file.py` | changed | test |

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
            $result = Invoke-CheckReport -ReportPath $report -Strict
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "done report has failed or not-run verification"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
