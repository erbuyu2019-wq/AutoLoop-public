param(
    [Parameter(Mandatory = $true)]
    [string]$WorkOrderPath
)

$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\AutoLoop.Markdown.ps1")

function Resolve-WorkOrderPath {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "WorkOrderPath must be an existing file: $Path"
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

function Get-SectionLines {
    param(
        [string[]]$Lines,
        [string]$SectionName
    )

    return Get-AutoLoopSectionLines -Lines $Lines -SectionName $SectionName
}

function Test-MeaningfulValue {
    param([string]$Value)

    return Test-AutoLoopMeaningfulValue -Value $Value
}

function Get-BulletValue {
    param(
        [string[]]$Lines,
        [string]$Name
    )

    return Get-AutoLoopBulletValue -Lines $Lines -Name $Name
}

function Get-CodeFenceLines {
    param([string[]]$Lines)

    return Get-AutoLoopCodeFenceLines -Lines $Lines
}

try {
    $resolvedWorkOrderPath = Resolve-WorkOrderPath -Path $WorkOrderPath
} catch {
    Write-Output $_.Exception.Message
    exit 1
}

$lines = @(Get-Content -Encoding UTF8 -LiteralPath $resolvedWorkOrderPath)
$issues = New-Object System.Collections.Generic.List[string]

if (($lines -join "`n") -match "<[^>]+>") {
    $issues.Add("Unresolved placeholders")
}

$summaryLines = Get-SectionLines -Lines $lines -SectionName "Summary"
if ($null -eq $summaryLines) {
    $issues.Add("Missing Summary section")
} else {
    foreach ($field in @("ID", "Owner", "Priority")) {
        if (-not (Test-MeaningfulValue -Value (Get-BulletValue -Lines $summaryLines -Name $field))) {
            $issues.Add("Missing or placeholder Summary field: $field")
        }
    }
}

$allowedLines = Get-SectionLines -Lines $lines -SectionName "Allowed Scope"
if ($null -eq $allowedLines) {
    $issues.Add("Missing Allowed Scope section")
} else {
    foreach ($field in @("Files / modules allowed", "Behavior allowed to change", "Tests / fixtures allowed")) {
        if (-not (Test-MeaningfulValue -Value (Get-BulletValue -Lines $allowedLines -Name $field))) {
            $issues.Add("Missing or placeholder Allowed Scope field: $field")
        }
    }
}

$forbiddenLines = Get-SectionLines -Lines $lines -SectionName "Forbidden Scope"
if ($null -eq $forbiddenLines) {
    $issues.Add("Missing Forbidden Scope section")
} else {
    foreach ($field in @("Do not touch", "Do not change", "Stop and report if")) {
        if (-not (Test-MeaningfulValue -Value (Get-BulletValue -Lines $forbiddenLines -Name $field))) {
            $issues.Add("Missing or placeholder Forbidden Scope field: $field")
        }
    }
}

$acceptanceLines = Get-SectionLines -Lines $lines -SectionName "Acceptance Commands"
if ($null -eq $acceptanceLines) {
    $issues.Add("Missing Acceptance Commands section")
} else {
    $commands = @(Get-CodeFenceLines -Lines $acceptanceLines)
    if ($commands.Count -eq 0) {
        $issues.Add("Acceptance commands are empty")
    }
}

Write-Output "AutoLoop work order check"
Write-Output "Work order: $resolvedWorkOrderPath"

if ($issues.Count -eq 0) {
    Write-Output "Result: PASS"
    exit 0
}

Write-Output "Result: FAIL"
Write-Output "Issues:"
$issues | ForEach-Object { Write-Output "- $_" }
exit 1
