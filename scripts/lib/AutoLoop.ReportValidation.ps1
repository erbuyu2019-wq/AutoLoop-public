. (Join-Path $PSScriptRoot "AutoLoop.Markdown.ps1")
. (Join-Path $PSScriptRoot "AutoLoop.Checks.ps1")

function Get-AutoLoopWorkerReportRequiredSections {
    return @(
        "Changed Scope",
        "Verification",
        "Contract Impact",
        "Not Verified",
        "Risks"
    )
}

function Get-AutoLoopWorkerReportRequiredSectionState {
    param([string[]]$Lines)

    $missingSections = New-Object System.Collections.Generic.List[string]
    $emptySections = New-Object System.Collections.Generic.List[string]

    foreach ($sectionName in @(Get-AutoLoopWorkerReportRequiredSections)) {
        $sectionLines = Get-AutoLoopSectionLines -Lines $Lines -SectionName $sectionName
        if ($null -eq $sectionLines) {
            $missingSections.Add($sectionName) | Out-Null
            continue
        }

        if (-not (Test-AutoLoopSectionHasContent -SectionLines $sectionLines)) {
            $emptySections.Add($sectionName) | Out-Null
        }
    }

    return [pscustomobject]@{
        MissingSections = $missingSections.ToArray()
        EmptySections = $emptySections.ToArray()
    }
}

function Get-AutoLoopWorkerReportSummaryValue {
    param(
        [string[]]$SummaryLines,
        [string]$Name
    )

    $value = Get-AutoLoopBulletValue -Lines $SummaryLines -Name $Name
    if ($null -eq $value) {
        return $null
    }

    return $value.Trim().Trim([char]96)
}

function Get-AutoLoopWorkerReportNextStepValue {
    param([string[]]$Lines)

    $sectionLines = Get-AutoLoopSectionLines -Lines $Lines -SectionName "Next Suggested Step"
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

function Get-AutoLoopWorkerReportVerificationResults {
    param([string[]]$Lines)

    $sectionLines = Get-AutoLoopSectionLines -Lines $Lines -SectionName "Verification"
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
            $results.Add($columns[0].ToLowerInvariant()) | Out-Null
        }
    }

    return $results.ToArray()
}

function Get-AutoLoopWorkerReportStrictIssues {
    param([string[]]$Lines)

    $issues = New-Object System.Collections.Generic.List[string]
    $allowedResults = @(Get-AutoLoopWorkerReportResults)
    $allowedNextSteps = @(Get-AutoLoopWorkerReportNextSteps)
    $allowedEvidenceLevels = @(Get-AutoLoopWorkerReportEvidenceLevels)

    $summaryLines = Get-AutoLoopSectionLines -Lines $Lines -SectionName "Summary"
    if ($null -eq $summaryLines) {
        $issues.Add("Missing Summary section") | Out-Null
        return $issues.ToArray()
    }

    $result = Get-AutoLoopWorkerReportSummaryValue -SummaryLines $summaryLines -Name "Result"
    if (-not $result -or $allowedResults -notcontains $result.ToLowerInvariant()) {
        $issues.Add("Invalid result value: $result") | Out-Null
    }

    $evidenceLevel = Get-AutoLoopWorkerReportSummaryValue -SummaryLines $summaryLines -Name "Evidence level"
    if (-not $evidenceLevel -or $evidenceLevel -match "<[^>]+>" -or $allowedEvidenceLevels -notcontains $evidenceLevel.ToLowerInvariant()) {
        $issues.Add("Invalid evidence level value: $evidenceLevel") | Out-Null
    }

    $nextStep = Get-AutoLoopWorkerReportNextStepValue -Lines $Lines
    if (-not $nextStep -or $allowedNextSteps -notcontains $nextStep.ToLowerInvariant()) {
        $issues.Add("Invalid next suggested step: $nextStep") | Out-Null
    }

    $verificationResults = @(Get-AutoLoopWorkerReportVerificationResults -Lines $Lines)
    $badDoneResults = @($verificationResults | Where-Object {
        $_ -eq "failed" -or $_ -eq "not run" -or $_ -eq "not-run"
    })

    if ($result -and $result.ToLowerInvariant() -eq "done" -and $badDoneResults.Count -gt 0) {
        $issues.Add("done report has failed or not-run verification") | Out-Null
    }

    return $issues.ToArray()
}

function Get-AutoLoopWorkerReportIssues {
    param([string[]]$Lines)

    $issues = New-Object System.Collections.Generic.List[string]
    $sectionState = Get-AutoLoopWorkerReportRequiredSectionState -Lines $Lines

    foreach ($sectionName in @($sectionState.MissingSections)) {
        $issues.Add("Missing section: $sectionName") | Out-Null
    }

    foreach ($sectionName in @($sectionState.EmptySections)) {
        $issues.Add("Empty or placeholder-only section: $sectionName") | Out-Null
    }

    if ($issues.Count -gt 0) {
        return $issues.ToArray()
    }

    foreach ($strictIssue in @(Get-AutoLoopWorkerReportStrictIssues -Lines $Lines)) {
        $issues.Add($strictIssue) | Out-Null
    }

    return $issues.ToArray()
}
