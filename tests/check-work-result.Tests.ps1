$RepoRoot = Split-Path -Parent $PSScriptRoot
$CheckWorkResultScript = Join-Path $RepoRoot "scripts\coordination\check-work-result.ps1"

function New-AutoLoopTempDirectory {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("autoloop-test-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $path | Out-Null
    return $path
}

function New-TestWorkOrder {
    param(
        [string]$Root,
        [string]$Id = "T-001",
        [string[]]$AcceptanceCommands = @(
            'powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Output ok"',
            'git diff --check'
        )
    )

    $workOrderPath = Join-Path $Root "work-order.md"
    $lines = @(
        "# Work Order",
        "",
        "## Summary",
        "",
        "- ID: $Id",
        "- Owner: tools",
        "- Goal: Test paired checker.",
        "- Priority: high",
        "",
        "## Allowed Scope",
        "",
        "- Files / modules allowed: scripts/",
        "- Behavior allowed to change: read-only check",
        "- Tests / fixtures allowed: tests/",
        "",
        "## Forbidden Scope",
        "",
        "- Do not touch: docs/coordination/board.md",
        "- Do not change: task state",
        "- Stop and report if: scope changes",
        "",
        "## Acceptance Commands",
        "",
        "Run from the project root:",
        "",
        '```powershell'
    ) + $AcceptanceCommands + @(
        '```'
    )
    Set-Content -LiteralPath $workOrderPath -Encoding UTF8 -Value $lines

    return $workOrderPath
}

function New-TestWorkerReport {
    param(
        [string]$Root,
        [string]$WorkOrderId = "T-001",
        [string[]]$VerificationCommands = @(
            'powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Output ok"',
            'git diff --check'
        ),
        [string]$Result = "done",
        [string]$EvidenceLevel = "local-readiness"
    )

    $reportPath = Join-Path $Root "worker-report.md"
    $lines = @(
        "# Worker Report",
        "",
        "## Summary",
        "",
        "- Work order ID: $WorkOrderId",
        "- Owner: tools",
        "- Result: $Result",
        "- Branch / workspace: feature / path",
        "- Report date: 2026-05-28"
    )

    if ($null -ne $EvidenceLevel) {
        $lines += "- Evidence level: $EvidenceLevel"
    }

    $lines += @(
        "",
        "## Changed Scope",
        "",
        "| File / Area | Change | Reason |",
        "| --- | --- | --- |",
        "| scripts/tool.ps1 | changed | test |",
        "",
        "## Verification",
        "",
        "| Command | Result | Evidence |",
        "| --- | --- | --- |"
    )
    $lines += @($VerificationCommands | ForEach-Object { "| $_ | passed | ok |" })
    $lines += @(
        "",
        "## Contract Impact",
        "",
        "- Public behavior changed: no",
        "- API / data model changed: no",
        "- Security / secret handling changed: no",
        "- Deployment / runtime behavior changed: no",
        "- Details: none",
        "",
        "## Not Verified",
        "",
        "- none",
        "",
        "## Risks",
        "",
        "- none",
        "",
        "## Next Suggested Step",
        "",
        "- review",
        "- Reason: ready for review."
    )
    Set-Content -LiteralPath $reportPath -Encoding UTF8 -Value $lines

    return $reportPath
}

function Invoke-CheckWorkResult {
    param(
        [string]$WorkOrderPath,
        [string]$ReportPath
    )

    $output = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $CheckWorkResultScript -WorkOrderPath $WorkOrderPath -ReportPath $ReportPath 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

Describe "check-work-result.ps1" {
    It "passes a matching work-order and worker-report pair" {
        $root = New-AutoLoopTempDirectory
        try {
            $workOrder = New-TestWorkOrder -Root $root
            $report = New-TestWorkerReport -Root $root

            $result = Invoke-CheckWorkResult -WorkOrderPath $workOrder -ReportPath $report

            $result.ExitCode | Should Be 0
            $result.Output | Should Match "AutoLoop work result check"
            $result.Output | Should Match "Result: PASS"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "passes when a verification command contains a PowerShell pipeline" {
        $root = New-AutoLoopTempDirectory
        try {
            $pipelineCommand = 'Get-ChildItem | Select-Object -First 1'
            $workOrder = New-TestWorkOrder -Root $root -AcceptanceCommands @($pipelineCommand)
            $report = New-TestWorkerReport -Root $root -VerificationCommands @($pipelineCommand)

            $result = Invoke-CheckWorkResult -WorkOrderPath $workOrder -ReportPath $report

            $result.ExitCode | Should Be 0
            $result.Output | Should Match "Result: PASS"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "passes when a verification command escapes a table pipe" {
        $root = New-AutoLoopTempDirectory
        try {
            $pipelineCommand = 'Get-ChildItem | Select-Object -First 1'
            $escapedPipelineCommand = 'Get-ChildItem \| Select-Object -First 1'
            $workOrder = New-TestWorkOrder -Root $root -AcceptanceCommands @($pipelineCommand)
            $report = New-TestWorkerReport -Root $root -VerificationCommands @($escapedPipelineCommand)

            $result = Invoke-CheckWorkResult -WorkOrderPath $workOrder -ReportPath $report

            $result.ExitCode | Should Be 0
            $result.Output | Should Match "Result: PASS"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "fails when work-order and report IDs do not match" {
        $root = New-AutoLoopTempDirectory
        try {
            $workOrder = New-TestWorkOrder -Root $root -Id "T-001"
            $report = New-TestWorkerReport -Root $root -WorkOrderId "T-002"

            $result = Invoke-CheckWorkResult -WorkOrderPath $workOrder -ReportPath $report

            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Result: FAIL"
            $result.Output | Should Match "Work order ID mismatch"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "fails when report verification does not cover an acceptance command" {
        $root = New-AutoLoopTempDirectory
        try {
            $acceptanceCommands = @(
                'powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Output ok"',
                'git diff --check'
            )
            $workOrder = New-TestWorkOrder -Root $root -AcceptanceCommands $acceptanceCommands
            $report = New-TestWorkerReport -Root $root -VerificationCommands @($acceptanceCommands[0])

            $result = Invoke-CheckWorkResult -WorkOrderPath $workOrder -ReportPath $report

            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Missing acceptance command in report verification: git diff --check"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "fails when the underlying strict report check fails" {
        $root = New-AutoLoopTempDirectory
        try {
            $workOrder = New-TestWorkOrder -Root $root
            $report = New-TestWorkerReport -Root $root -EvidenceLevel $null

            $result = Invoke-CheckWorkResult -WorkOrderPath $workOrder -ReportPath $report

            $result.ExitCode | Should Not Be 0
            $result.Output | Should Match "Worker report check failed"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
