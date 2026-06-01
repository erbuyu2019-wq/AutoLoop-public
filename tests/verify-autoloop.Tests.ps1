$RepoRoot = Split-Path -Parent $PSScriptRoot
$VerifyScript = Join-Path $RepoRoot "scripts\verify-autoloop.ps1"

function New-AutoLoopTempDirectory {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("autoloop-test-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $path | Out-Null
    return $path
}

function New-TestWorkOrder {
    param([string]$Root)

    $path = Join-Path $Root "work-order.md"
    Set-Content -LiteralPath $path -Encoding UTF8 -Value @'
# Work Order

## Summary

- ID: `T-QUICK-001`
- Owner: `tools`
- Goal: Exercise quick verification.
- Priority: `normal`

## Allowed Scope

- Files / modules allowed: `scripts/verify-autoloop.ps1`
- Behavior allowed to change: quick preflight only
- Tests / fixtures allowed: `tests/verify-autoloop.Tests.ps1`

## Forbidden Scope

- Do not touch: target projects
- Do not change: full verification behavior
- Stop and report if: scope changes

## Acceptance Commands

Run from the project root:

```powershell
git diff --check
```
'@
    return $path
}

function New-TestWorkerReport {
    param([string]$Root)

    $path = Join-Path $Root "worker-report.md"
    Set-Content -LiteralPath $path -Encoding UTF8 -Value @'
# Worker Report

## Summary

- Work order ID: `T-QUICK-001`
- Owner: `tools`
- Result: `done`
- Branch / workspace: `test` / `temp`
- Report date: `2026-05-31`
- Evidence level: `local-readiness`

## Changed Scope

| File / Area | Change | Reason |
| --- | --- | --- |
| `scripts/verify-autoloop.ps1` | changed | test |

## Verification

| Command | Result | Evidence |
| --- | --- | --- |
| `git diff --check` | passed | test |

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
    return $path
}

function Invoke-VerifyAutoLoop {
    param([string[]]$Arguments)

    $scriptText = Get-Content -LiteralPath $VerifyScript -Raw
    if ($Arguments -contains "-Quick" -and $scriptText -notmatch '\[switch\]\s*\$Quick') {
        return [pscustomobject]@{
            ExitCode = 999
            Output = "Quick parameter missing"
        }
    }

    $output = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $VerifyScript @Arguments 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

function Invoke-VerifyAutoLoopWithEmptyFocusedPath {
    param([string]$ParameterName)

    $root = New-AutoLoopTempDirectory
    try {
        $caller = Join-Path $root "invoke-empty-path.ps1"
        Set-Content -LiteralPath $caller -Encoding UTF8 -Value @"
`$empty = ''
& '$VerifyScript' -Quick -$ParameterName `$empty
exit `$LASTEXITCODE
"@

        $output = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $caller 2>&1)
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output = ($output -join "`n")
        }
    } finally {
        Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "verify-autoloop.ps1 quick mode" {
    It "runs quick coordinator preflight without running full verification steps" {
        $root = New-AutoLoopTempDirectory
        try {
            $workOrder = New-TestWorkOrder -Root $root
            $report = New-TestWorkerReport -Root $root

            $result = Invoke-VerifyAutoLoop -Arguments @(
                "-Quick",
                "-WorkOrderPath",
                $workOrder,
                "-ReportPath",
                $report
            )

            $result.ExitCode | Should Be 0
            $result.Output | Should Match "AutoLoop quick verification"
            $result.Output | Should Match "read-only coordinator preflight"
            $result.Output | Should Match "does not replace full repository verification"
            $result.Output | Should Match "Run board check"
            $result.Output | Should Match "Run work order check"
            $result.Output | Should Match "Run worker report check"
            $result.Output | Should Match "Run work result check"
            $result.Output | Should Match "Run coordination state check"
            $result.Output | Should Match "Run git diff whitespace check"
            $result.Output | Should Not Match "Run Pester tests"
            $result.Output | Should Not Match "Parse PowerShell scripts"
            $result.Output | Should Not Match "Run text whitespace check"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "does not infer focused work-order or report paths" {
        $result = Invoke-VerifyAutoLoop -Arguments @("-Quick")

        $result.ExitCode | Should Be 0
        $result.Output | Should Match "AutoLoop quick verification"
        $result.Output | Should Match "Run board check"
        $result.Output | Should Match "Run coordination state check"
        $result.Output | Should Match "Run git diff whitespace check"
        $result.Output | Should Not Match "Run work order check"
        $result.Output | Should Not Match "Run worker report check"
        $result.Output | Should Not Match "Run work result check"
    }

    It "fails when focused paths are explicitly empty" {
        $workOrderResult = Invoke-VerifyAutoLoopWithEmptyFocusedPath -ParameterName "WorkOrderPath"

        $workOrderResult.ExitCode | Should Not Be 0
        $workOrderResult.Output | Should Match "WorkOrderPath"

        $reportResult = Invoke-VerifyAutoLoopWithEmptyFocusedPath -ParameterName "ReportPath"

        $reportResult.ExitCode | Should Not Be 0
        $reportResult.Output | Should Match "ReportPath"
    }

    It "propagates delegated checker failures" {
        $result = Invoke-VerifyAutoLoop -Arguments @(
            "-Quick",
            "-WorkOrderPath",
            "missing-work-order.md"
        )

        $result.ExitCode | Should Not Be 0
        $result.Output | Should Match "WorkOrderPath must be an existing file"
    }
}
