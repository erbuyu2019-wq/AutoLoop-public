param(
    [Parameter(Mandatory = $true)]
    [string]$ReportPath,
    [switch]$Strict
)

$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\AutoLoop.Markdown.ps1")
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\AutoLoop.Checks.ps1")

$requiredSections = @(
    "Changed Scope",
    "Verification",
    "Contract Impact",
    "Not Verified",
    "Risks"
)

function Resolve-ReportPath {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "ReportPath must be an existing file: $Path"
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

function Test-MeaningfulLine {
    param([string]$Line)

    return Test-AutoLoopMeaningfulLine -Line $Line
}

function Test-SectionHasContent {
    param([string[]]$SectionLines)

    return Test-AutoLoopSectionHasContent -SectionLines $SectionLines
}

function Get-SummaryValue {
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

function Get-NextStepValue {
    param([string[]]$Lines)

    $sectionLines = Get-SectionLines -Lines $Lines -SectionName "Next Suggested Step"
    if ($null -eq $sectionLines) {
        return $null
    }

    foreach ($line in $sectionLines) {
        if ($line -match "^\s*-\s+(.+?)\s*$") {
            return $matches[1].Trim().Trim([char]96)
        }
    }

    return $null
}

function Get-VerificationResults {
    param([string[]]$Lines)

    $sectionLines = Get-SectionLines -Lines $Lines -SectionName "Verification"
    if ($null -eq $sectionLines) {
        return @()
    }

    $results = New-Object System.Collections.Generic.List[string]
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

        $columns = @(Get-AutoLoopMarkdownTableTrailingCells -Line $trimmed -CellCount 2)
        if ($columns.Count -ge 2 -and $columns[0].Length -gt 0) {
            $results.Add($columns[0].ToLowerInvariant())
        }
    }

    return $results.ToArray()
}

function Get-StrictIssues {
    param([string[]]$Lines)

    $issues = New-Object System.Collections.Generic.List[string]
    $allowedResults = @(Get-AutoLoopWorkerReportResults)
    $allowedNextSteps = @(Get-AutoLoopWorkerReportNextSteps)
    $allowedEvidenceLevels = @(Get-AutoLoopWorkerReportEvidenceLevels)

    $summaryLines = Get-SectionLines -Lines $Lines -SectionName "Summary"
    if ($null -eq $summaryLines) {
        $issues.Add("Missing Summary section")
        return $issues.ToArray()
    }

    $result = Get-SummaryValue -Lines $summaryLines -Name "Result"
    if (-not $result -or $allowedResults -notcontains $result.ToLowerInvariant()) {
        $issues.Add("Invalid result value: $result")
    }

    $evidenceLevel = Get-SummaryValue -Lines $summaryLines -Name "Evidence level"
    if (-not $evidenceLevel -or $evidenceLevel -match "<[^>]+>" -or $allowedEvidenceLevels -notcontains $evidenceLevel.ToLowerInvariant()) {
        $issues.Add("Invalid evidence level value: $evidenceLevel")
    }

    $nextStep = Get-NextStepValue -Lines $Lines
    if (-not $nextStep -or $allowedNextSteps -notcontains $nextStep.ToLowerInvariant()) {
        $issues.Add("Invalid next suggested step: $nextStep")
    }

    $verificationResults = @(Get-VerificationResults -Lines $Lines)
    $badDoneResults = @($verificationResults | Where-Object {
        $_ -eq "failed" -or $_ -eq "not run" -or $_ -eq "not-run"
    })

    if ($result -and $result.ToLowerInvariant() -eq "done" -and $badDoneResults.Count -gt 0) {
        $issues.Add("done report has failed or not-run verification")
    }

    return $issues.ToArray()
}

try {
    $resolvedReportPath = Resolve-ReportPath -Path $ReportPath
} catch {
    Write-Output $_.Exception.Message
    exit 1
}

$lines = @(Get-Content -Encoding UTF8 -LiteralPath $resolvedReportPath)
$missingSections = New-Object System.Collections.Generic.List[string]
$emptySections = New-Object System.Collections.Generic.List[string]
$strictIssues = @()

foreach ($sectionName in $requiredSections) {
    $sectionLines = Get-SectionLines -Lines $lines -SectionName $sectionName
    if ($null -eq $sectionLines) {
        $missingSections.Add($sectionName)
        continue
    }

    if (-not (Test-SectionHasContent -SectionLines $sectionLines)) {
        $emptySections.Add($sectionName)
    }
}

if ($Strict -and $missingSections.Count -eq 0 -and $emptySections.Count -eq 0) {
    $strictIssues = @(Get-StrictIssues -Lines $lines)
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
