$RepoRoot = Split-Path -Parent $PSScriptRoot
$SummaryScript = Join-Path $RepoRoot "scripts\coordination\summarize-coordination-state.ps1"

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
Last Updated: `2026-05-26`

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

function Invoke-Summary {
    param(
        [string[]]$ProjectRoots,
        [switch]$Brownfield,
        [switch]$Json
    )

    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $SummaryScript,
        "-ProjectRoots"
    ) + $ProjectRoots

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

Describe "summarize-coordination-state.ps1" {
    It "prints a compact read-only human summary for each project" {
        $root = New-AutoLoopTempDirectory
        try {
            $boardPath = Join-Path $root "docs\coordination\board.md"
            New-TestCoordinationProject -Root $root -Rows "| T-001 | todo | tools | Prepare slice | scripts | none | Start work |" | Out-Null
            $before = Get-Content -Raw -Encoding UTF8 -LiteralPath $boardPath

            $result = Invoke-Summary -ProjectRoots @($root)

            $after = Get-Content -Raw -Encoding UTF8 -LiteralPath $boardPath
            $result.ExitCode | Should Be 0
            $result.Output | Should Match "AutoLoop coordination state summary"
            $result.Output | Should Match ([regex]::Escape((Resolve-Path -LiteralPath $root).Path))
            $result.Output | Should Match "Result: WARN"
            $result.Output | Should Match "Findings: INFO=6, WARN=1, HOLD=0, FAIL=0"
            $result.Output | Should Match "Tasks: 1"
            $result.Output | Should Match "Dirty repositories: 0"
            $result.Output | Should Not Match "dispatch"
            $after | Should Be $before
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "emits parseable aggregate JSON for multiple projects" {
        $rootOne = New-AutoLoopTempDirectory
        $rootTwo = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $rootOne -Rows "| T-001 | todo | tools | Prepare slice | scripts | none | Start work |" | Out-Null
            New-TestCoordinationProject -Root $rootTwo -Rows "| T-002 | blocked | tools | Wait | scripts | user approval needed | Ask user |" | Out-Null

            $result = Invoke-Summary -ProjectRoots @($rootOne, $rootTwo) -Json
            $summary = $result.Output | ConvertFrom-Json

            $result.ExitCode | Should Be 0
            $summary.tool | Should Be "autoloop-coordination-state-summary"
            $summary.schemaVersion | Should Be "1.0"
            $summary.generatedAt | Should Not BeNullOrEmpty
            $summary.result | Should Be "HOLD"
            @($summary.projects).Count | Should Be 2
            $summary.summary.projectCount | Should Be 2
            $summary.summary.resultCounts.WARN | Should Be 1
            $summary.summary.resultCounts.HOLD | Should Be 1
            $summary.summary.boardTaskCount | Should Be 2
        } finally {
            Remove-Item -LiteralPath $rootOne -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $rootTwo -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "returns exit code 0 for aggregate HOLD" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | review | tools | Review slice | scripts | none | Review report |" | Out-Null

            $result = Invoke-Summary -ProjectRoots @($root) -Json
            $summary = $result.Output | ConvertFrom-Json

            $result.ExitCode | Should Be 0
            $summary.result | Should Be "HOLD"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "returns exit code 1 for aggregate FAIL" {
        $root = New-AutoLoopTempDirectory
        try {
            New-TestCoordinationProject -Root $root -Rows "| T-001 | started |  |  |  | none |  |" | Out-Null

            $result = Invoke-Summary -ProjectRoots @($root) -Json
            $summary = $result.Output | ConvertFrom-Json

            $result.ExitCode | Should Be 1
            $summary.result | Should Be "FAIL"
            $summary.summary.resultCounts.FAIL | Should Be 1
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "passes Brownfield through to child coordination state checks" {
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

            $strictResult = Invoke-Summary -ProjectRoots @($root) -Json
            $strictSummary = $strictResult.Output | ConvertFrom-Json
            $brownfieldResult = Invoke-Summary -ProjectRoots @($root) -Brownfield -Json
            $brownfieldSummary = $brownfieldResult.Output | ConvertFrom-Json

            $strictResult.ExitCode | Should Be 1
            $strictSummary.result | Should Be "FAIL"
            $strictSummary.reportValidationMode | Should Be "strict"
            $brownfieldResult.ExitCode | Should Be 0
            $brownfieldSummary.result | Should Be "WARN"
            $brownfieldSummary.reportValidationMode | Should Be "brownfield"
            $brownfieldSummary.projects[0].result | Should Be "WARN"
            $brownfieldSummary.projects[0].findingCounts.WARN | Should Be 2
            $brownfieldSummary.projects[0].findingCounts.FAIL | Should Be 0
            $brownfieldSummary.summary.resultCounts.WARN | Should Be 1
            $brownfieldSummary.summary.findingCounts.WARN | Should Be 2
            $brownfieldSummary.summary.findingCounts.FAIL | Should Be 0
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "counts unparseable child checker output as a FAIL finding" {
        $missingRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("autoloop-missing-" + [guid]::NewGuid().ToString("N"))

        $result = Invoke-Summary -ProjectRoots @($missingRoot) -Json
        $summary = $result.Output | ConvertFrom-Json

        $result.ExitCode | Should Be 1
        $summary.result | Should Be "FAIL"
        @($summary.projects).Count | Should Be 1
        $summary.projects[0].result | Should Be "FAIL"
        $summary.projects[0].findingCounts.FAIL | Should Be 1
        $summary.summary.resultCounts.FAIL | Should Be 1
        $summary.summary.findingCounts.FAIL | Should Be 1
    }
}
