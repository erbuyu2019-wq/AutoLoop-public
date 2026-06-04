param(
    [Parameter(Mandatory = $true)]
    [string]$WorkOrderPath,

    [Parameter(Mandatory = $true)]
    [string[]]$ReportPaths,

    [Parameter(Mandatory = $true)]
    [string[]]$ExpectedOwners
)

$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\AutoLoop.Markdown.ps1")
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\AutoLoop.Checks.ps1")

function Resolve-ExistingFile {
    param(
        [string]$Path,
        [string]$Name
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Name must be an existing file: $Path"
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

function Get-NormalizedList {
    param([string[]]$Values)

    return @(
        $Values |
            ForEach-Object { $_ -split "[,;]" } |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_.Length -gt 0 }
    )
}

function Add-ReviewIssue {
    param(
        [System.Collections.Generic.List[object]]$Issues,
        [string]$Severity,
        [string]$Message
    )

    $Issues.Add([pscustomobject]@{
        Severity = $Severity
        Message = $Message
    }) | Out-Null
}

function Get-ResultFromIssues {
    param($Issues)

    $hasUser = $false
    $hasBlocked = $false
    $hasHold = $false

    foreach ($issue in $Issues) {
        if ($issue.Severity -eq "user") {
            $hasUser = $true
        } elseif ($issue.Severity -eq "blocked") {
            $hasBlocked = $true
        } elseif ($issue.Severity -eq "hold") {
            $hasHold = $true
        }
    }

    if ($hasUser) {
        return "NEEDS USER APPROVAL"
    }

    if ($hasBlocked) {
        return "BLOCKED"
    }

    if ($hasHold) {
        return "HOLD"
    }

    return "ACCEPT"
}

function Get-ContractImpactValues {
    param([string[]]$Lines)

    $sectionLines = Get-SectionLines -Lines $Lines -SectionName "Contract Impact"
    if ($null -eq $sectionLines) {
        return @{}
    }

    $values = @{}
    foreach ($field in @(
        "Public behavior changed",
        "API / data model changed",
        "Security / secret handling changed",
        "Deployment / runtime behavior changed"
    )) {
        $values[$field] = Get-BulletValue -Lines $sectionLines -Name $field
    }

    return $values
}

try {
    $resolvedWorkOrderPath = Resolve-ExistingFile -Path $WorkOrderPath -Name "WorkOrderPath"
    $normalizedReportPaths = @(Get-NormalizedList -Values $ReportPaths)
    $resolvedReportPaths = @($normalizedReportPaths | ForEach-Object {
        Resolve-ExistingFile -Path $_ -Name "ReportPath"
    })
} catch {
    Write-Output $_.Exception.Message
    exit 1
}

$issues = New-Object System.Collections.Generic.List[object]
$expectedOwnerList = @(Get-NormalizedList -Values $ExpectedOwners)
$seenOwners = @{}
$reportSummaries = New-Object System.Collections.Generic.List[object]
$allowedResults = @(Get-AutoLoopWorkerReportResults)
$allowedNextSteps = @(Get-AutoLoopWorkerReportNextSteps)

$workOrderLines = @(Get-Content -Encoding UTF8 -LiteralPath $resolvedWorkOrderPath)
$workOrderSummary = Get-SectionLines -Lines $workOrderLines -SectionName "Summary"
$workOrderId = $null
if ($null -ne $workOrderSummary) {
    $workOrderId = Get-BulletValue -Lines $workOrderSummary -Name "ID"
}

if (-not $workOrderId) {
    Add-ReviewIssue -Issues $issues -Severity "blocked" -Message "Work order ID is missing"
}

if ($expectedOwnerList.Count -eq 0) {
    Add-ReviewIssue -Issues $issues -Severity "hold" -Message "Expected owners are empty"
}

foreach ($reportPath in $resolvedReportPaths) {
    $reportLines = @(Get-Content -Encoding UTF8 -LiteralPath $reportPath)
    $summaryLines = Get-SectionLines -Lines $reportLines -SectionName "Summary"
    if ($null -eq $summaryLines) {
        Add-ReviewIssue -Issues $issues -Severity "blocked" -Message "Report Summary section is missing: $reportPath"
        continue
    }

    $reportWorkOrderId = Get-BulletValue -Lines $summaryLines -Name "Work order ID"
    $owner = Get-BulletValue -Lines $summaryLines -Name "Owner"
    $result = Get-BulletValue -Lines $summaryLines -Name "Result"
    $nextStep = Get-NextStepValue -Lines $reportLines
    $contractValues = Get-ContractImpactValues -Lines $reportLines

    if (-not $owner) {
        Add-ReviewIssue -Issues $issues -Severity "blocked" -Message "Report owner is missing: $reportPath"
        continue
    }

    if ($seenOwners.ContainsKey($owner)) {
        Add-ReviewIssue -Issues $issues -Severity "hold" -Message "Duplicate report owner: $owner"
    } else {
        $seenOwners[$owner] = $true
    }

    if ($workOrderId -and $reportWorkOrderId -ne $workOrderId) {
        Add-ReviewIssue -Issues $issues -Severity "blocked" -Message "Work order ID mismatch for owner $owner`: $reportWorkOrderId"
    }

    if (-not $result -or $allowedResults -notcontains $result.ToLowerInvariant()) {
        Add-ReviewIssue -Issues $issues -Severity "blocked" -Message "Invalid report result for owner $owner`: $result"
    } elseif ($result.ToLowerInvariant() -eq "partial") {
        Add-ReviewIssue -Issues $issues -Severity "hold" -Message "Report is partial: $owner"
    } elseif ($result.ToLowerInvariant() -eq "blocked" -or $result.ToLowerInvariant() -eq "rejected") {
        Add-ReviewIssue -Issues $issues -Severity "blocked" -Message "Report is $($result.ToLowerInvariant()): $owner"
    }

    if (-not $nextStep -or $allowedNextSteps -notcontains $nextStep.ToLowerInvariant()) {
        Add-ReviewIssue -Issues $issues -Severity "blocked" -Message "Invalid next suggested step for owner $owner`: $nextStep"
    } elseif ($nextStep.ToLowerInvariant() -eq "needs user decision") {
        Add-ReviewIssue -Issues $issues -Severity "user" -Message "Report requests user decision: $owner"
    } elseif ($nextStep.ToLowerInvariant() -eq "needs coordinator decision") {
        Add-ReviewIssue -Issues $issues -Severity "hold" -Message "Report needs coordinator decision: $owner"
    } elseif ($nextStep.ToLowerInvariant() -eq "blocked") {
        Add-ReviewIssue -Issues $issues -Severity "blocked" -Message "Report next step is blocked: $owner"
    }

    foreach ($field in $contractValues.Keys) {
        $value = $contractValues[$field]
        if ($value -and $value.ToLowerInvariant() -eq "yes") {
            Add-ReviewIssue -Issues $issues -Severity "user" -Message "Contract impact requires user approval: $owner"
            break
        }
    }

    $reportSummaries.Add([pscustomobject]@{
        Owner = $owner
        Result = $result
        NextStep = $nextStep
        Path = $reportPath
    }) | Out-Null
}

foreach ($expectedOwner in $expectedOwnerList) {
    if (-not $seenOwners.ContainsKey($expectedOwner)) {
        Add-ReviewIssue -Issues $issues -Severity "hold" -Message "Missing report for expected owner: $expectedOwner"
    }
}

$unexpectedOwners = @($reportSummaries | Where-Object { $expectedOwnerList -notcontains $_.Owner })
foreach ($unexpectedOwner in $unexpectedOwners) {
    Add-ReviewIssue -Issues $issues -Severity "hold" -Message "Unexpected report owner: $($unexpectedOwner.Owner)"
}

$result = Get-ResultFromIssues -Issues $issues

Write-Output "AutoLoop integration review check"
Write-Output "Work order: $resolvedWorkOrderPath"
Write-Output ("Expected owners: {0}" -f ($expectedOwnerList -join ", "))
Write-Output ("Reports: {0}" -f $resolvedReportPaths.Count)
Write-Output "Result: $result"

if ($reportSummaries.Count -gt 0) {
    Write-Output "Report summary:"
    $reportSummaries | ForEach-Object {
        Write-Output ("- {0}: result={1}; next={2}" -f $_.Owner, $_.Result, $_.NextStep)
    }
}

if ($issues.Count -gt 0) {
    Write-Output "Issues:"
    $issues | ForEach-Object { Write-Output ("- {0}" -f $_.Message) }
}

if ($result -eq "ACCEPT") {
    exit 0
}

exit 1
