param(
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$Brownfield
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectRoot {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "ProjectRoot must be an existing directory: $Path"
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

function Get-ScriptRoot {
    $scriptPath = $PSCommandPath
    if (-not $scriptPath) {
        $scriptPath = $MyInvocation.MyCommand.Path
    }

    return Split-Path -Parent $scriptPath
}

function Invoke-ChildPowerShell {
    param([string[]]$Arguments)

    $output = @(& powershell @Arguments 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

function Invoke-JsonScript {
    param(
        [string]$Name,
        [string]$ScriptPath,
        [string[]]$Arguments
    )

    $powershellArguments = @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $ScriptPath
    ) + $Arguments

    $result = Invoke-ChildPowerShell -Arguments $powershellArguments
    try {
        $parsed = $result.Output | ConvertFrom-Json
    } catch {
        Write-Output "AutoLoop doctor"
        Write-Output "Result: FAIL"
        Write-Output "$Name JSON output could not be parsed."
        if ($result.Output) {
            Write-Output ""
            Write-Output "Raw output:"
            Write-Output $result.Output
        }
        exit 1
    }

    return [pscustomobject]@{
        ExitCode = $result.ExitCode
        Data = $parsed
    }
}

function Format-Boolean {
    param([bool]$Value)

    if ($Value) {
        return "yes"
    }

    return "no"
}

function Format-Counts {
    param([object]$Counts)

    if ($null -eq $Counts) {
        return "none"
    }

    $properties = @($Counts.PSObject.Properties)
    $preferredOrder = @("INFO", "WARN", "HOLD", "FAIL", "todo", "doing", "blocked", "review", "done")
    $orderedProperties = New-Object System.Collections.Generic.List[object]
    foreach ($name in $preferredOrder) {
        $property = @($properties | Where-Object { $_.Name -ceq $name } | Select-Object -First 1)
        if ($property.Count -gt 0) {
            $orderedProperties.Add($property[0]) | Out-Null
        }
    }

    foreach ($property in @($properties | Where-Object { $preferredOrder -cnotcontains $_.Name } | Sort-Object Name)) {
        $orderedProperties.Add($property) | Out-Null
    }

    $parts = @($orderedProperties | ForEach-Object { "$($_.Name)=$($_.Value)" })
    if ($parts.Count -eq 0) {
        return "none"
    }

    return ($parts -join ", ")
}

function Get-PropertyValue {
    param(
        [object]$Object,
        [string]$Name,
        [object]$Default = $null
    )

    if ($null -eq $Object) {
        return $Default
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $Default
    }

    return $property.Value
}

function Write-ManualCommand {
    param(
        [string]$ScriptPath,
        [string[]]$Arguments
    )

    Write-Output ("- powershell -NoProfile -ExecutionPolicy Bypass -File `"{0}`" {1}" -f $ScriptPath, ($Arguments -join " "))
}

try {
    $resolvedProjectRoot = Resolve-ProjectRoot -Path $ProjectRoot
} catch {
    Write-Output "AutoLoop doctor"
    Write-Output "Result: FAIL"
    Write-Output $_.Exception.Message
    exit 1
}

$scriptRoot = Get-ScriptRoot
$statusScript = Join-Path $scriptRoot "status.ps1"
$coordinationStateScript = Join-Path $scriptRoot "check-coordination-state.ps1"
$summaryScript = Join-Path $scriptRoot "summarize-coordination-state.ps1"
$boardScript = Join-Path $scriptRoot "check-board.ps1"

$statusResult = Invoke-JsonScript -Name "status" -ScriptPath $statusScript -Arguments @("-Root", $resolvedProjectRoot, "-Json")
if ($statusResult.ExitCode -ne 0) {
    Write-Output "AutoLoop doctor"
    Write-Output "Result: FAIL"
    Write-Output "status.ps1 failed with exit code $($statusResult.ExitCode)."
    exit 1
}

$stateArguments = @("-ProjectRoot", $resolvedProjectRoot, "-Json")
if ($Brownfield) {
    $stateArguments += "-Brownfield"
}

$stateResult = Invoke-JsonScript -Name "coordination-state" -ScriptPath $coordinationStateScript -Arguments $stateArguments
$state = $stateResult.Data
$status = $statusResult.Data
$result = $state.result
$reportValidationMode = Get-PropertyValue -Object $state -Name "reportValidationMode" -Default "strict"

Write-Output "AutoLoop doctor"
Write-Output "Project root: $resolvedProjectRoot"
Write-Output "Result: $result"
Write-Output "Report validation mode: $reportValidationMode"

Write-Output ""
Write-Output "[project]"
Write-Output ("Git available: {0}" -f (Format-Boolean -Value ([bool]$status.gitAvailable)))
$rootRepository = $status.rootRepository
if ($null -eq $rootRepository) {
    Write-Output "Root git: not checked"
} elseif (-not [bool]$rootRepository.isGitRepository) {
    Write-Output "Root git: not a git repository"
} else {
    Write-Output "Root git: yes"
    Write-Output ("Branch: {0}" -f $rootRepository.branch)
    Write-Output ("Dirty files: {0}" -f $rootRepository.dirtyFileCount)
    Write-Output ("Last commit: {0}" -f $rootRepository.lastCommit)
}

$worktrees = @($status.worktrees)
if ($worktrees.Count -eq 0) {
    Write-Output "Worktrees: none"
} else {
    Write-Output ("Worktrees: {0}" -f $worktrees.Count)
    foreach ($worktree in $worktrees) {
        Write-Output ("- {0}: git={1}, dirty={2}" -f $worktree.label, (Format-Boolean -Value ([bool]$worktree.isGitRepository)), $worktree.dirtyFileCount)
    }
}

$summary = $state.summary
Write-Output ""
Write-Output "[coordination summary]"
Write-Output ("Findings: {0}" -f (Format-Counts -Counts $summary.findingCounts))
Write-Output ("Board tasks: {0} ({1})" -f (Get-PropertyValue -Object $summary.board -Name "taskCount" -Default 0), (Format-Counts -Counts $summary.board.statusCounts))
Write-Output ("Work orders: {0} total, {1} failed" -f (Get-PropertyValue -Object $summary.workOrders -Name "total" -Default 0), (Get-PropertyValue -Object $summary.workOrders -Name "failed" -Default 0))
Write-Output ("Reports: {0} total, {1} worker, {2} failed worker" -f (Get-PropertyValue -Object $summary.reports -Name "total" -Default 0), (Get-PropertyValue -Object $summary.reports -Name "worker" -Default 0), (Get-PropertyValue -Object $summary.reports -Name "failedWorker" -Default 0))
Write-Output ("Strict worker-report shape failures: {0}" -f (Get-PropertyValue -Object $summary.reports -Name "strictFailedWorker" -Default 0))
Write-Output ("Brownfield warning-only worker reports: {0}" -f (Get-PropertyValue -Object $summary.reports -Name "warnOnlyWorker" -Default 0))
Write-Output ("Dirty repositories: {0}" -f (Get-PropertyValue -Object $summary.git -Name "dirtyRepositories" -Default 0))

Write-Output ""
Write-Output "[result semantics]"
Write-Output "INFO: informational findings only; exit 0"
Write-Output "WARN: review recommended; exit 0"
Write-Output "HOLD: manual gate or review state; exit 0"
Write-Output "FAIL: protocol or input failure; exit 1"

if ($reportValidationMode -eq "brownfield") {
    Write-Output ""
    Write-Output "[brownfield mode]"
    Write-Output "Historical worker-report strict shape failures stay visible as WARN findings."
    Write-Output "Focused check-report.ps1 -Strict remains required before accepting active or new worker reports."
}

Write-Output ""
Write-Output "[important findings]"
$importantFindings = @($state.findings | Where-Object { $_.severity -eq "FAIL" -or $_.severity -eq "HOLD" -or $_.severity -eq "WARN" })
if ($importantFindings.Count -eq 0) {
    Write-Output "- No WARN/HOLD/FAIL findings."
} else {
    foreach ($finding in $importantFindings) {
        Write-Output ("- [{0}] {1}" -f $finding.severity, $finding.message)
    }
}

Write-Output ""
Write-Output "[manual drill-down commands]"
Write-ManualCommand -ScriptPath $statusScript -Arguments @("-Root", "`"$resolvedProjectRoot`"")
$coordinationStateDrillDownArguments = @("-ProjectRoot", "`"$resolvedProjectRoot`"")
if ($reportValidationMode -eq "brownfield") {
    $coordinationStateDrillDownArguments += "-Brownfield"
}
Write-ManualCommand -ScriptPath $coordinationStateScript -Arguments $coordinationStateDrillDownArguments
Write-ManualCommand -ScriptPath $summaryScript -Arguments @("-ProjectRoots", "`"$resolvedProjectRoot`"")
$boardPath = Join-Path $resolvedProjectRoot "docs\coordination\board.md"
if (Test-Path -LiteralPath $boardPath -PathType Leaf) {
    Write-ManualCommand -ScriptPath $boardScript -Arguments @("-BoardPath", "`"$boardPath`"")
}

if ($result -eq "FAIL") {
    exit 1
}

exit 0
