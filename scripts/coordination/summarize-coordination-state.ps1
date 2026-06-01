param(
    [string[]]$ProjectRoots = @((Get-Location).Path),
    [switch]$Json,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$AdditionalProjectRoots = @()
)

$ErrorActionPreference = "Stop"

function Get-ScriptRoot {
    $scriptPath = $PSCommandPath
    if (-not $scriptPath) {
        $scriptPath = $MyInvocation.MyCommand.Path
    }

    return Split-Path -Parent $scriptPath
}

function Get-ResultSeverity {
    param([string[]]$Results)

    if (@($Results | Where-Object { $_ -eq "FAIL" }).Count -gt 0) {
        return "FAIL"
    }

    if (@($Results | Where-Object { $_ -eq "HOLD" }).Count -gt 0) {
        return "HOLD"
    }

    if (@($Results | Where-Object { $_ -eq "WARN" }).Count -gt 0) {
        return "WARN"
    }

    return "INFO"
}

function New-SeverityCounts {
    return [ordered]@{
        INFO = 0
        WARN = 0
        HOLD = 0
        FAIL = 0
    }
}

function Get-PropertyValue {
    param(
        [object]$Object,
        [string]$Name,
        [object]$DefaultValue = $null
    )

    if ($null -eq $Object) {
        return $DefaultValue
    }

    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) {
            return $Object[$Name]
        }

        return $DefaultValue
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $DefaultValue
    }

    return $property.Value
}

function Get-IntegerProperty {
    param(
        [object]$Object,
        [string]$Name
    )

    $value = Get-PropertyValue -Object $Object -Name $Name -DefaultValue 0
    if ($null -eq $value) {
        return 0
    }

    return [int]$value
}

function ConvertTo-SeverityCounts {
    param([object]$Counts)

    $normalized = New-SeverityCounts
    foreach ($severity in @("INFO", "WARN", "HOLD", "FAIL")) {
        $normalized[$severity] = Get-IntegerProperty -Object $Counts -Name $severity
    }

    return $normalized
}

function Add-SeverityCounts {
    param(
        [System.Collections.Specialized.OrderedDictionary]$Target,
        [object]$Counts
    )

    foreach ($severity in @("INFO", "WARN", "HOLD", "FAIL")) {
        $Target[$severity] += Get-IntegerProperty -Object $Counts -Name $severity
    }
}

function Format-SeverityCounts {
    param([object]$Counts)

    $normalized = ConvertTo-SeverityCounts -Counts $Counts
    return "INFO=$($normalized["INFO"]), WARN=$($normalized["WARN"]), HOLD=$($normalized["HOLD"]), FAIL=$($normalized["FAIL"])"
}

function Resolve-ProjectRoots {
    param([string[]]$Roots)

    $resolved = New-Object System.Collections.Generic.List[string]
    foreach ($root in $Roots) {
        foreach ($part in @($root -split ",")) {
            $trimmed = $part.Trim()
            if ($trimmed.Length -ne 0) {
                $resolved.Add($trimmed) | Out-Null
            }
        }
    }

    if ($resolved.Count -eq 0) {
        throw "At least one project root is required"
    }

    return $resolved.ToArray()
}

function Invoke-CoordinationStateCheck {
    param(
        [string]$CheckScript,
        [string]$ProjectRoot
    )

    $output = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $CheckScript -ProjectRoot $ProjectRoot -Json 2>&1)
    $exitCode = $LASTEXITCODE
    $rawOutput = $output -join "`n"

    try {
        $state = $rawOutput | ConvertFrom-Json
    } catch {
        $fallbackFindingCounts = New-SeverityCounts
        $fallbackFindingCounts["FAIL"] = 1

        return [pscustomobject][ordered]@{
            projectRoot = $ProjectRoot
            result = "FAIL"
            checkerExitCode = $exitCode
            findingCounts = [pscustomobject]$fallbackFindingCounts
            board = [pscustomobject][ordered]@{
                taskCount = 0
                statusCounts = [pscustomobject][ordered]@{}
            }
            workOrders = [pscustomobject][ordered]@{
                total = 0
                failed = 0
            }
            reports = [pscustomobject][ordered]@{
                total = 0
                worker = 0
                nonWorker = 0
                invalid = 0
                failedWorker = 0
            }
            git = [pscustomobject][ordered]@{
                dirtyRepositories = 0
            }
        }
    }

    $summary = Get-PropertyValue -Object $state -Name "summary"
    $board = Get-PropertyValue -Object $summary -Name "board"
    $workOrders = Get-PropertyValue -Object $summary -Name "workOrders"
    $reports = Get-PropertyValue -Object $summary -Name "reports"
    $git = Get-PropertyValue -Object $summary -Name "git"

    return [pscustomobject][ordered]@{
        projectRoot = (Get-PropertyValue -Object $state -Name "projectRoot" -DefaultValue $ProjectRoot)
        result = (Get-PropertyValue -Object $state -Name "result" -DefaultValue "FAIL")
        checkerExitCode = $exitCode
        findingCounts = [pscustomobject](ConvertTo-SeverityCounts -Counts (Get-PropertyValue -Object $summary -Name "findingCounts"))
        board = [pscustomobject][ordered]@{
            taskCount = Get-IntegerProperty -Object $board -Name "taskCount"
            statusCounts = [pscustomobject](Get-PropertyValue -Object $board -Name "statusCounts" -DefaultValue ([ordered]@{}))
        }
        workOrders = [pscustomobject][ordered]@{
            total = Get-IntegerProperty -Object $workOrders -Name "total"
            failed = Get-IntegerProperty -Object $workOrders -Name "failed"
        }
        reports = [pscustomobject][ordered]@{
            total = Get-IntegerProperty -Object $reports -Name "total"
            worker = Get-IntegerProperty -Object $reports -Name "worker"
            nonWorker = Get-IntegerProperty -Object $reports -Name "nonWorker"
            invalid = Get-IntegerProperty -Object $reports -Name "invalid"
            failedWorker = Get-IntegerProperty -Object $reports -Name "failedWorker"
        }
        git = [pscustomobject][ordered]@{
            dirtyRepositories = Get-IntegerProperty -Object $git -Name "dirtyRepositories"
        }
    }
}

$scriptRoot = Get-ScriptRoot
$checkScript = Join-Path $scriptRoot "check-coordination-state.ps1"
$requestedRoots = Resolve-ProjectRoots -Roots (@($ProjectRoots) + @($AdditionalProjectRoots))

$projects = New-Object System.Collections.Generic.List[object]
foreach ($projectRoot in $requestedRoots) {
    $projects.Add((Invoke-CoordinationStateCheck -CheckScript $checkScript -ProjectRoot $projectRoot)) | Out-Null
}

$aggregateResult = Get-ResultSeverity -Results @($projects | ForEach-Object { $_.result })
$resultCounts = New-SeverityCounts
$findingCounts = New-SeverityCounts
$boardTaskCount = 0
$dirtyRepositories = 0

foreach ($project in $projects) {
    if ($resultCounts.Contains([string]$project.result)) {
        $resultCounts[$project.result]++
    }

    Add-SeverityCounts -Target $findingCounts -Counts $project.findingCounts
    $boardTaskCount += [int]$project.board.taskCount
    $dirtyRepositories += [int]$project.git.dirtyRepositories
}

$summary = [pscustomobject][ordered]@{
    projectCount = $projects.Count
    resultCounts = [pscustomobject]$resultCounts
    findingCounts = [pscustomobject]$findingCounts
    boardTaskCount = $boardTaskCount
    dirtyRepositories = $dirtyRepositories
}

if ($Json) {
    [pscustomobject][ordered]@{
        tool = "autoloop-coordination-state-summary"
        schemaVersion = "1.0"
        generatedAt = ([DateTime]::UtcNow.ToString("o"))
        result = $aggregateResult
        projects = @($projects.ToArray())
        summary = $summary
    } | ConvertTo-Json -Depth 8

    if ($aggregateResult -eq "FAIL") {
        exit 1
    }

    exit 0
}

Write-Output "AutoLoop coordination state summary"
Write-Output ("Generated: {0}" -f ([DateTime]::UtcNow.ToString("o")))
Write-Output "Result: $aggregateResult"
Write-Output ("Projects: {0}" -f $projects.Count)

foreach ($project in $projects) {
    Write-Output ""
    Write-Output ("Project: {0}" -f $project.projectRoot)
    Write-Output ("Result: {0}" -f $project.result)
    Write-Output ("Findings: {0}" -f (Format-SeverityCounts -Counts $project.findingCounts))
    Write-Output ("Tasks: {0}" -f $project.board.taskCount)
    Write-Output ("Dirty repositories: {0}" -f $project.git.dirtyRepositories)
}

Write-Output ""
Write-Output "Aggregate:"
Write-Output ("Results: {0}" -f (Format-SeverityCounts -Counts $resultCounts))
Write-Output ("Findings: {0}" -f (Format-SeverityCounts -Counts $findingCounts))
Write-Output ("Tasks: {0}" -f $boardTaskCount)
Write-Output ("Dirty repositories: {0}" -f $dirtyRepositories)

if ($aggregateResult -eq "FAIL") {
    exit 1
}

exit 0
