param(
    [Parameter(Mandatory = $true)]
    [string]$ReportPath,
    [switch]$Strict
)

$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\AutoLoop.ReportValidation.ps1")

function Resolve-ReportPath {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "ReportPath must be an existing file: $Path"
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

try {
    $resolvedReportPath = Resolve-ReportPath -Path $ReportPath
} catch {
    Write-Output $_.Exception.Message
    exit 1
}

$lines = @(Get-Content -Encoding UTF8 -LiteralPath $resolvedReportPath)
$sectionState = Get-AutoLoopWorkerReportRequiredSectionState -Lines $lines
$missingSections = @($sectionState.MissingSections)
$emptySections = @($sectionState.EmptySections)
$strictIssues = @()

if ($Strict -and $missingSections.Count -eq 0 -and $emptySections.Count -eq 0) {
    $strictIssues = @(Get-AutoLoopWorkerReportStrictIssues -Lines $lines)
}

Write-Output "AutoLoop worker report check"
Write-Output "Report: $resolvedReportPath"

if ($missingSections.Count -eq 0 -and $emptySections.Count -eq 0 -and $strictIssues.Count -eq 0) {
    Write-Output "Result: PASS"
    exit 0
}

Write-Output "Result: FAIL"

if ($missingSections.Count -gt 0) {
    Write-Output "Missing sections:"
    $missingSections | ForEach-Object { Write-Output "- $_" }
}

if ($emptySections.Count -gt 0) {
    Write-Output "Empty or placeholder-only sections:"
    $emptySections | ForEach-Object { Write-Output "- $_" }
}

if ($strictIssues.Count -gt 0) {
    Write-Output "Strict issues:"
    $strictIssues | ForEach-Object { Write-Output "- $_" }
}

exit 1
