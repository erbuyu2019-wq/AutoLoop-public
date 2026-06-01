$RepoRoot = Split-Path -Parent $PSScriptRoot
$DoctorScript = Join-Path $RepoRoot "scripts\coordination\doctor.ps1"
$AutoLoopScript = Join-Path $RepoRoot "scripts\autoloop.ps1"

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
Stage Goal: Check doctor diagnostics.
Last Updated: `2026-05-29`

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

function Invoke-Doctor {
    param(
        [string]$ProjectRoot,
        [switch]$Brownfield,
        [switch]$UseWrapper
    )

    $doctorArguments = @("-ProjectRoot", $ProjectRoot)
    if ($Brownfield) {
        $doctorArguments += "-Brownfield"
    }

    if ($UseWrapper) {
        $output = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $AutoLoopScript doctor @doctorArguments 2>&1)
    } else {
        $output = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $DoctorScript @doctorArguments 2>&1)
    }

    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

Describe "doctor.ps1" {
    It "prints a human read-only diagnostic for the current repository" {
        $result = Invoke-Doctor -ProjectRoot $RepoRoot

        $result.ExitCode | Should Be 0
        $result.Output | Should Match "AutoLoop doctor"
        $result.Output | Should Match "Result:"
        $result.Output | Should Match "\[coordination summary\]"
        $result.Output | Should Match "\[manual drill-down commands\]"
        $result.Output | Should Not Match "schemaVersion"
    }

    It "returns zero for HOLD and preserves severity wording" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | blocked | tools | Wait for gate | scripts | user approval needed | Ask user |" | Out-Null

            $result = Invoke-Doctor -ProjectRoot $root

            $result.ExitCode | Should Be 0
            $result.Output | Should Match "Result: HOLD"
            $result.Output | Should Match "\[HOLD\] Board task blocked: T-001"
            $result.Output | Should Match "HOLD: manual gate or review state; exit 0"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "passes brownfield mode through and explains historical report debt" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | todo | tools | Prepare slice | scripts | none | Start work |" | Out-Null
            $reportPath = Join-Path (Join-Path $root "docs\coordination\reports") "T-001-worker-report.md"
            Set-Content -LiteralPath $reportPath -Encoding UTF8 -Value @'
# Worker Report

## Summary

- Work order ID: `T-001`
- Owner: `tools`
- Result: `done`
'@

            $result = Invoke-Doctor -ProjectRoot $root -Brownfield

            $result.ExitCode | Should Be 0
            $result.Output | Should Match "Result: WARN"
            $result.Output | Should Match "Report validation mode: brownfield"
            $result.Output | Should Match "Historical worker-report strict shape failures stay visible as WARN findings"
            $result.Output | Should Match "Focused check-report.ps1 -Strict remains required"
            $result.Output | Should Match "Brownfield warning-only worker reports: 1"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "returns nonzero for FAIL without repairing state" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | started |  |  |  | none |  |" | Out-Null

            $result = Invoke-Doctor -ProjectRoot $root

            $result.ExitCode | Should Be 1
            $result.Output | Should Match "Result: FAIL"
            $result.Output | Should Match "\[FAIL\] Board protocol check failed"
            $result.Output | Should Match "FAIL: protocol or input failure; exit 1"
            $result.Output | Should Match "\[manual drill-down commands\]"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "is delegated by scripts/autoloop.ps1" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | todo | tools | Prepare slice | scripts | none | Start work |" | Out-Null

            $result = Invoke-Doctor -ProjectRoot $root -Brownfield -UseWrapper

            $result.ExitCode | Should Be 0
            $result.Output | Should Match "AutoLoop doctor"
            $result.Output | Should Match "Report validation mode: brownfield"
            $result.Output | Should Match "\[manual drill-down commands\]"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
