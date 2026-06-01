$RepoRoot = Split-Path -Parent $PSScriptRoot
$CheckWorkOrderScript = Join-Path $RepoRoot "scripts\coordination\check-work-order.ps1"
$DogfoodWorkOrder = Join-Path $RepoRoot "docs\coordination\work-orders\phase6-dogfood.md"
$WorkOrderTemplate = Join-Path $RepoRoot "templates\coordination\work-order.md"

function New-AutoLoopTempDirectory {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("autoloop-test-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $path | Out-Null
    return $path
}

function Invoke-CheckWorkOrder {
    param([string]$WorkOrderPath)

    $output = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $CheckWorkOrderScript -WorkOrderPath $WorkOrderPath 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

Describe "check-work-order.ps1" {
    It "passes a complete work order" {
        $result = Invoke-CheckWorkOrder -WorkOrderPath $DogfoodWorkOrder
        $result.ExitCode | Should Be 0
        $result.Output | Should Match "Result: PASS"
    }

    It "fails an unresolved template work order" {
        $result = Invoke-CheckWorkOrder -WorkOrderPath $WorkOrderTemplate
        $result.ExitCode | Should Not Be 0
        $result.Output | Should Match "Unresolved placeholders"
    }

    It "fails when acceptance commands are empty" {
        $root = New-AutoLoopTempDirectory
        try {
            $workOrder = Join-Path $root "missing-commands.md"
            Set-Content -LiteralPath $workOrder -Encoding UTF8 -Value @'
# Work Order

## Summary

- ID: `T-001`
- Owner: `app`
- Goal: Test work order.
- Priority: `normal`
- Due / checkpoint: `next`

## Allowed Scope

- Files / modules allowed: `src/app/`
- Behavior allowed to change: docs only
- Tests / fixtures allowed: `tests/app/`

## Forbidden Scope

- Do not touch: `src/device/`
- Do not change: deployment
- Stop and report if: scope changes

## Acceptance Commands

Run the cheapest decisive checks that fit the task.

```powershell
```
'@
            $result = Invoke-CheckWorkOrder -WorkOrderPath $workOrder
            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Acceptance commands are empty"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
