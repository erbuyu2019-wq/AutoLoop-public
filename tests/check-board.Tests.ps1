$RepoRoot = Split-Path -Parent $PSScriptRoot
$CheckBoardScript = Join-Path $RepoRoot "scripts\coordination\check-board.ps1"
$DogfoodBoard = Join-Path $RepoRoot "docs\coordination\board.md"
$BoardTemplate = Join-Path $RepoRoot "templates\coordination\board.md"
$MultiOwnerExampleBoard = Join-Path $RepoRoot "docs\examples\multi-owner-smoke\board.md"

function New-AutoLoopTempDirectory {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("autoloop-test-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $path | Out-Null
    return $path
}

function New-TestBoard {
    param(
        [string]$Root,
        [string]$Rows
    )

    $path = Join-Path $Root "board.md"
    $content = @"
# Coordination Board

Project: Test
Stage Goal: Check board lint.
Last Updated: `2026-05-19`

## Owners

| Owner | Scope | Workspace / Thread | Notes |
| --- | --- | --- | --- |
| app | app scope | app thread | app notes |

## Tasks

Use only these statuses: `todo`, `doing`, `blocked`, `review`, `done`.

| ID | Status | Owner | Task | Allowed Scope | Blocker / Risk | Next Step |
| --- | --- | --- | --- | --- | --- | --- |
$Rows

## Integration Notes

- Current integration order: app -> review.
"@
    Set-Content -LiteralPath $path -Encoding UTF8 -Value $content
    return $path
}

function Invoke-CheckBoard {
    param([string]$BoardPath)

    $output = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $CheckBoardScript -BoardPath $BoardPath 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

Describe "check-board.ps1" {
    It "passes the dogfood board" {
        $result = Invoke-CheckBoard -BoardPath $DogfoodBoard
        $result.ExitCode | Should Be 0
        $result.Output | Should Match "Result: PASS"
    }

    It "passes the multi-owner smoke example board" {
        $result = Invoke-CheckBoard -BoardPath $MultiOwnerExampleBoard
        $result.ExitCode | Should Be 0
        $result.Output | Should Match "Result: PASS"
    }

    It "fails an unresolved template board" {
        $result = Invoke-CheckBoard -BoardPath $BoardTemplate
        $result.ExitCode | Should Not Be 0
        $result.Output | Should Match "Unresolved placeholders"
    }

    It "fails an invalid status value" {
        $root = New-AutoLoopTempDirectory
        try {
            $board = New-TestBoard -Root $root -Rows "| T-001 | started | app | Do work | src/app | none | Review |"
            $result = Invoke-CheckBoard -BoardPath $board
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Invalid status for T-001"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "fails when a blocked item has no concrete blocker" {
        $root = New-AutoLoopTempDirectory
        try {
            $board = New-TestBoard -Root $root -Rows "| T-001 | blocked | app | Do work | src/app | none | Wait |"
            $result = Invoke-CheckBoard -BoardPath $board
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Blocked task needs concrete blocker"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "fails when owner or next step is missing" {
        $root = New-AutoLoopTempDirectory
        try {
            $board = New-TestBoard -Root $root -Rows "| T-001 | todo |  | Do work | src/app | none |  |"
            $result = Invoke-CheckBoard -BoardPath $board
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Missing owner for T-001"
            $result.Output | Should Match "Missing next step for T-001"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
