param(
    [Parameter(Mandatory = $true)]
    [string]$WorkOrderPath,

    [Parameter(Mandatory = $true)]
    [string]$ReportPath
)

$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\AutoLoop.Markdown.ps1")

function Resolve-RequiredFile {
    param(
        [string]$Path,
        [string]$ParameterName
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$ParameterName must be an existing file: $Path"
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

function Invoke-CheckScript {
    param(
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

    return Invoke-ChildPowerShell -Arguments $powershellArguments
}

function Get-SectionLines {
    param(
        [string[]]$Lines,
        [string]$SectionName
    )

    return Get-AutoLoopSectionLines -Lines $Lines -SectionName $SectionName
}

function Get-BulletValue {
    param(
        [string[]]$Lines,
        [string]$Name
    )

    $value = Get-AutoLoopBulletValue -Lines $Lines -Name $Name
    if ($null -eq $value) {
        return $null
    }

    return $value.Trim().Trim([char]96)
}

function Get-SummaryValue {
    param(
        [string[]]$Lines,
        [string]$Name
    )

    $summaryLines = Get-SectionLines -Lines $Lines -SectionName "Summary"
    if ($null -eq $summaryLines) {
        return $null
    }

    return Get-BulletValue -Lines $summaryLines -Name $Name
}

function Get-CodeFenceLines {
    param([string[]]$Lines)

    return Get-AutoLoopCodeFenceLines -Lines $Lines
}

function Get-AcceptanceCommands {
    param([string[]]$Lines)

    $sectionLines = Get-SectionLines -Lines $Lines -SectionName "Acceptance Commands"
    if ($null -eq $sectionLines) {
        return @()
    }

    return @(Get-CodeFenceLines -Lines $sectionLines)
}

function Get-UnescapedPipeIndexes {
    param([string]$Value)

    return Get-AutoLoopUnescapedPipeIndexes -Value $Value
}

function Get-MarkdownTableFirstCell {
    param([string]$Line)

    return Get-AutoLoopMarkdownTableFirstCell -Line $Line
}

function Get-VerificationCommands {
    param([string[]]$Lines)

    $sectionLines = Get-SectionLines -Lines $Lines -SectionName "Verification"
    if ($null -eq $sectionLines) {
        return @()
    }

    $commands = New-Object System.Collections.Generic.List[string]
    foreach ($line in $sectionLines) {
        $trimmed = $line.Trim()
        if ($trimmed -notmatch "^\|") {
            continue
        }

        if ($trimmed -match "^\|\s*Command\s*\|") {
            continue
        }

        if ($trimmed -match "^\|\s*[-:\s|]+\|?$") {
            continue
        }

        $command = Get-MarkdownTableFirstCell -Line $trimmed
        if ($command -and $command.Length -gt 0) {
            $commands.Add($command) | Out-Null
        }
    }

    return $commands.ToArray()
}

$issues = New-Object System.Collections.Generic.List[string]

try {
    $resolvedWorkOrderPath = Resolve-RequiredFile -Path $WorkOrderPath -ParameterName "WorkOrderPath"
    $resolvedReportPath = Resolve-RequiredFile -Path $ReportPath -ParameterName "ReportPath"
} catch {
    Write-Output $_.Exception.Message
    exit 1
}

$scriptRoot = Get-ScriptRoot
$checkWorkOrderScript = Join-Path $scriptRoot "check-work-order.ps1"
$checkReportScript = Join-Path $scriptRoot "check-report.ps1"

$workOrderCheck = Invoke-CheckScript -ScriptPath $checkWorkOrderScript -Arguments @("-WorkOrderPath", $resolvedWorkOrderPath)
if ($workOrderCheck.ExitCode -ne 0) {
    $issues.Add("Work order check failed") | Out-Null
}

$reportCheck = Invoke-CheckScript -ScriptPath $checkReportScript -Arguments @("-ReportPath", $resolvedReportPath, "-Strict")
if ($reportCheck.ExitCode -ne 0) {
    $issues.Add("Worker report check failed") | Out-Null
}

$workOrderLines = @(Get-Content -Encoding UTF8 -LiteralPath $resolvedWorkOrderPath)
$reportLines = @(Get-Content -Encoding UTF8 -LiteralPath $resolvedReportPath)

$workOrderId = Get-SummaryValue -Lines $workOrderLines -Name "ID"
$reportWorkOrderId = Get-SummaryValue -Lines $reportLines -Name "Work order ID"

if (-not $workOrderId) {
    $issues.Add("Missing work order ID") | Out-Null
}

if (-not $reportWorkOrderId) {
    $issues.Add("Missing report work order ID") | Out-Null
}

if ($workOrderId -and $reportWorkOrderId -and $workOrderId -cne $reportWorkOrderId) {
    $issues.Add("Work order ID mismatch: work-order=$workOrderId report=$reportWorkOrderId") | Out-Null
}

$acceptanceCommands = @(Get-AcceptanceCommands -Lines $workOrderLines)
$verificationCommands = @(Get-VerificationCommands -Lines $reportLines)

foreach ($command in $acceptanceCommands) {
    if ($verificationCommands -cnotcontains $command) {
        $issues.Add("Missing acceptance command in report verification: $command") | Out-Null
    }
}

Write-Output "AutoLoop work result check"
Write-Output "Work order: $resolvedWorkOrderPath"
Write-Output "Report: $resolvedReportPath"

if ($issues.Count -eq 0) {
    Write-Output "Result: PASS"
    exit 0
}

Write-Output "Result: FAIL"
Write-Output "Issues:"
$issues | ForEach-Object { Write-Output "- $_" }
exit 1
