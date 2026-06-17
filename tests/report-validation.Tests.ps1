$RepoRoot = Split-Path -Parent $PSScriptRoot
$ReportValidationLibrary = Join-Path $RepoRoot "scripts\lib\AutoLoop.ReportValidation.ps1"
. $ReportValidationLibrary

function New-TestReportLines {
    param(
        [string[]]$OmitSections = @(),
        [string[]]$PlaceholderSections = @(),
        [string]$Result = "done",
        [string]$EvidenceLevel = "local-readiness",
        [string]$NextStep = "review",
        [string]$VerificationResult = "passed"
    )

    $omit = @{}
    foreach ($sectionName in @($OmitSections)) {
        if ($sectionName) {
            $omit[$sectionName] = $true
        }
    }

    $placeholder = @{}
    foreach ($sectionName in @($PlaceholderSections)) {
        if ($sectionName) {
            $placeholder[$sectionName] = $true
        }
    }

    $parts = New-Object System.Collections.Generic.List[string]
    $parts.Add(@"
# Worker Report

## Summary

- Work order ID: `T-001`
- Owner: `docs`
- Result: $Result
- Branch / workspace: `feature` / `path`
- Report date: `2026-06-17`
- Evidence level: $EvidenceLevel
"@.Trim()) | Out-Null

    $sections = [ordered]@{
        "Changed Scope" = @"
| File / Area | Change | Reason |
| --- | --- | --- |
| `README.md` | changed | test |
"@.Trim()
        "Verification" = @"
| Command | Result | Evidence |
| --- | --- | --- |
| `test` | $VerificationResult | ok |
"@.Trim()
        "Contract Impact" = @"
- Public behavior changed: no
- API / data model changed: no
- Security / secret handling changed: no
- Deployment / runtime behavior changed: no
- Details: none
"@.Trim()
        "Not Verified" = "- none"
        "Risks" = "- none"
    }

    foreach ($sectionName in $sections.Keys) {
        if ($omit.ContainsKey($sectionName)) {
            continue
        }

        $body = $sections[$sectionName]
        if ($placeholder.ContainsKey($sectionName)) {
            $body = "- <$sectionName>"
        }

        $parts.Add(("## {0}`n`n{1}" -f $sectionName, $body)) | Out-Null
    }

    $parts.Add(@"
## Next Suggested Step

- $NextStep
- Reason: ready for review.
"@.Trim()) | Out-Null

    return (($parts.ToArray()) -join "`n`n").Split("`n")
}

Describe "AutoLoop.ReportValidation.ps1" {
    It "classifies complete required sections as present and non-empty" {
        $state = Get-AutoLoopWorkerReportRequiredSectionState -Lines (New-TestReportLines)

        @($state.MissingSections).Count | Should Be 0
        @($state.EmptySections).Count | Should Be 0
    }

    It "separates missing sections from placeholder-only sections" {
        $state = Get-AutoLoopWorkerReportRequiredSectionState -Lines (New-TestReportLines -OmitSections @("Risks") -PlaceholderSections @("Changed Scope"))

        @($state.MissingSections) | Should Be @("Risks")
        @($state.EmptySections) | Should Be @("Changed Scope")
    }

    It "extracts summary, next-step, and verification values" {
        $lines = New-TestReportLines -NextStep "needs coordinator decision" -VerificationResult "passed"
        $summaryLines = Get-AutoLoopSectionLines -Lines $lines -SectionName "Summary"

        (Get-AutoLoopWorkerReportSummaryValue -SummaryLines $summaryLines -Name "Result") | Should Be "done"
        (Get-AutoLoopWorkerReportSummaryValue -SummaryLines $summaryLines -Name "Evidence level") | Should Be "local-readiness"
        (Get-AutoLoopWorkerReportNextStepValue -Lines $lines) | Should Be "needs coordinator decision"
        @(Get-AutoLoopWorkerReportVerificationResults -Lines $lines) | Should Be @("passed")
    }

    It "flags strict issues for invalid values and failed done verification" {
        $lines = New-TestReportLines -Result "done" -EvidenceLevel "unverified" -NextStep "ship" -VerificationResult "failed"
        $issues = @(Get-AutoLoopWorkerReportStrictIssues -Lines $lines)

        ($issues -contains "Invalid evidence level value: unverified") | Should Be $true
        ($issues -contains "Invalid next suggested step: ship") | Should Be $true
        ($issues -contains "done report has failed or not-run verification") | Should Be $true
    }

    It "returns non-strict required-section issues before strict issues" {
        $lines = New-TestReportLines -OmitSections @("Verification") -EvidenceLevel "unverified"
        $issues = @(Get-AutoLoopWorkerReportIssues -Lines $lines)

        $issues | Should Be @("Missing section: Verification")
    }
}
