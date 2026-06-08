param(
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$Brownfield,
    [switch]$Json
)

$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\AutoLoop.Markdown.ps1")
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\AutoLoop.Checks.ps1")
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\AutoLoop.ReportValidation.ps1")

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

function New-FindingList {
    return New-Object System.Collections.Generic.List[object]
}

function Add-Finding {
    param(
        [System.Collections.Generic.List[object]]$Findings,
        [string]$Severity,
        [string]$Message
    )

    $Findings.Add([pscustomobject]@{
        Severity = $Severity
        Message = $Message
    }) | Out-Null
}

function Get-ResultSeverity {
    param([object[]]$Findings)

    if (@($Findings | Where-Object { $_.Severity -eq "FAIL" }).Count -gt 0) {
        return "FAIL"
    }

    if (@($Findings | Where-Object { $_.Severity -eq "HOLD" }).Count -gt 0) {
        return "HOLD"
    }

    if (@($Findings | Where-Object { $_.Severity -eq "WARN" }).Count -gt 0) {
        return "WARN"
    }

    return "INFO"
}

function Get-FindingCounts {
    param([object[]]$Findings)

    $counts = [ordered]@{
        INFO = 0
        WARN = 0
        HOLD = 0
        FAIL = 0
    }

    foreach ($finding in $Findings) {
        if ($counts.Contains($finding.Severity)) {
            $counts[$finding.Severity]++
        }
    }

    return $counts
}

function Format-NameSample {
    param(
        [string[]]$Names,
        [int]$Limit = 5
    )

    $items = @($Names)
    if ($items.Count -eq 0) {
        return "none"
    }

    $sample = @($items | Select-Object -First $Limit) -join ", "
    if ($items.Count -gt $Limit) {
        return ("{0}, ... (+{1} more)" -f $sample, ($items.Count - $Limit))
    }

    return $sample
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

function Get-BoardTaskRows {
    param([string]$BoardPath)

    $lines = @(Get-Content -Encoding UTF8 -LiteralPath $BoardPath)
    $taskSection = Get-SectionLines -Lines $lines -SectionName "Tasks"
    if ($null -eq $taskSection) {
        return @()
    }

    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($line in $taskSection) {
        $trimmed = $line.Trim()
        if (-not $trimmed.StartsWith("|")) {
            continue
        }

        if ($trimmed -match "^\|\s*[-:\s|]+\|?$") {
            continue
        }

        if ($trimmed -match "^\|\s*ID\s*\|\s*Status\s*\|") {
            continue
        }

        $columns = @($trimmed.Trim("|").Split("|") | ForEach-Object { $_.Trim().Trim([char]96) })
        if ($columns.Count -lt 7) {
            continue
        }

        $rows.Add([pscustomobject]@{
            Id = $columns[0]
            Status = $columns[1].ToLowerInvariant()
            Owner = $columns[2]
            Task = $columns[3]
            Blocker = $columns[5]
            NextStep = $columns[6]
        }) | Out-Null
    }

    return $rows.ToArray()
}

function Read-MarkdownLines {
    param([string]$Path)

    return @(Get-Content -Encoding UTF8 -LiteralPath $Path)
}

function Test-MeaningfulValue {
    param([string]$Value)

    return Test-AutoLoopMeaningfulValue -Value $Value
}

function Test-MeaningfulLine {
    param([string]$Line)

    return Test-AutoLoopMeaningfulLine -Line $Line
}

function Test-SectionHasContent {
    param([string[]]$SectionLines)

    return Test-AutoLoopSectionHasContent -SectionLines $SectionLines
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

function Get-WorkOrderIssues {
    param([string]$Path)

    # Keep this logic aligned with check-work-order.ps1. The aggregate checker
    # runs it in-process to avoid one PowerShell startup per file in large repos.
    $lines = Read-MarkdownLines -Path $Path
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

    return $issues.ToArray()
}

function Test-WorkerReport {
    param(
        [string]$Path,
        [string[]]$Lines
    )

    $name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    if ($name -match "(?i)(^|[-_])worker[-_]report($|[-_])") {
        return $true
    }

    foreach ($line in $Lines) {
        if ($line -match "^#\s+Worker Report\s*$") {
            return $true
        }
    }

    return $false
}

function Get-WorkerReportIssues {
    param(
        [string]$Path,
        [string[]]$Lines
    )

    # Keep worker-report validation in-process while sharing the strict path
    # with check-report.ps1 -Strict.
    return Get-AutoLoopWorkerReportIssues -Lines $Lines
}

function Test-GitAvailable {
    return $null -ne (Get-Command git -ErrorAction SilentlyContinue)
}

function Invoke-GitQuiet {
    param(
        [string]$Path,
        [string[]]$Arguments
    )

    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"

    try {
        $output = @(& git -C $Path @Arguments 2>$null)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldErrorActionPreference
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = $output
    }
}

function Test-GitRepository {
    param([string]$Path)

    $result = Invoke-GitQuiet -Path $Path -Arguments @("rev-parse", "--is-inside-work-tree")
    return ($result.ExitCode -eq 0 -and (($result.Output -join "").Trim() -eq "true"))
}

function Get-GitDirtyCount {
    param([string]$Path)

    $statusResult = Invoke-GitQuiet -Path $Path -Arguments @("status", "--porcelain")
    if ($statusResult.ExitCode -ne 0) {
        return $null
    }

    return $statusResult.Output.Count
}

function Add-GitFindings {
    param(
        [System.Collections.Generic.List[object]]$Findings,
        [string]$Label,
        [string]$Path
    )

    if (-not (Test-GitRepository -Path $Path)) {
        Add-Finding -Findings $Findings -Severity "WARN" -Message "$Label is not a git repository: $Path"
        return [pscustomobject]@{
            IsGitRepository = $false
            IsDirty = $false
            DirtyCount = $null
        }
    }

    $dirtyCount = Get-GitDirtyCount -Path $Path
    if ($null -eq $dirtyCount) {
        Add-Finding -Findings $Findings -Severity "WARN" -Message "$Label git status could not be read: $Path"
        return [pscustomobject]@{
            IsGitRepository = $true
            IsDirty = $false
            DirtyCount = $null
        }
    }

    if ($dirtyCount -gt 0) {
        Add-Finding -Findings $Findings -Severity "WARN" -Message "$Label has dirty files: $dirtyCount"
        return [pscustomobject]@{
            IsGitRepository = $true
            IsDirty = $true
            DirtyCount = $dirtyCount
        }
    }

    Add-Finding -Findings $Findings -Severity "INFO" -Message "$Label git working tree is clean"
    return [pscustomobject]@{
        IsGitRepository = $true
        IsDirty = $false
        DirtyCount = 0
    }
}

try {
    $resolvedProjectRoot = Resolve-ProjectRoot -Path $ProjectRoot
} catch {
    Write-Output $_.Exception.Message
    exit 1
}

$scriptRoot = Get-ScriptRoot
$checkBoardScript = Join-Path $scriptRoot "check-board.ps1"

$coordinationRoot = Join-Path $resolvedProjectRoot "docs\coordination"
$boardPath = Join-Path $coordinationRoot "board.md"
$workOrdersRoot = Join-Path $coordinationRoot "work-orders"
$reportsRoot = Join-Path $coordinationRoot "reports"
$reportValidationMode = "strict"
if ($Brownfield) {
    $reportValidationMode = "brownfield"
}

$findings = New-FindingList
$boardTaskCount = 0
$boardStatusCounts = [ordered]@{}
$workOrderTotal = 0
$workOrderFailed = 0
$reportTotal = 0
$workerReportCount = 0
$nonWorkerReportCount = 0
$invalidReportCount = 0
$failedWorkerReportCount = 0
$strictFailedWorkerReportCount = 0
$warnOnlyWorkerReportCount = 0
$gitAvailable = $false
$gitRootChecked = 0
$gitWorktreesChecked = 0
$gitDirtyRepositoryCount = 0

if (-not (Test-Path -LiteralPath $coordinationRoot -PathType Container)) {
    Add-Finding -Findings $findings -Severity "FAIL" -Message "Missing coordination directory: $coordinationRoot"
} else {
    Add-Finding -Findings $findings -Severity "INFO" -Message "Coordination directory exists: $coordinationRoot"
}

if (-not (Test-Path -LiteralPath $boardPath -PathType Leaf)) {
    Add-Finding -Findings $findings -Severity "FAIL" -Message "Missing board: $boardPath"
} else {
    $boardCheck = Invoke-CheckScript -ScriptPath $checkBoardScript -Arguments @("-BoardPath", $boardPath)
    if ($boardCheck.ExitCode -eq 0) {
        Add-Finding -Findings $findings -Severity "INFO" -Message "Board protocol check passed: $boardPath"

        $taskRows = @(Get-BoardTaskRows -BoardPath $boardPath)
        $boardTaskCount = $taskRows.Count
        foreach ($row in $taskRows) {
            if (-not $boardStatusCounts.Contains($row.Status)) {
                $boardStatusCounts[$row.Status] = 0
            }
            $boardStatusCounts[$row.Status]++

            if ($row.Status -eq "blocked") {
                Add-Finding -Findings $findings -Severity "HOLD" -Message "Board task blocked: $($row.Id)"
            } elseif ($row.Status -eq "review") {
                Add-Finding -Findings $findings -Severity "HOLD" -Message "Board task waiting for review: $($row.Id)"
            }
        }

        if ($taskRows.Count -eq 0) {
            Add-Finding -Findings $findings -Severity "WARN" -Message "Board has no parsed task rows"
        } else {
            $summary = @($boardStatusCounts.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ", "
            Add-Finding -Findings $findings -Severity "INFO" -Message "Board task summary: $summary"
        }
    } else {
        Add-Finding -Findings $findings -Severity "FAIL" -Message "Board protocol check failed: $boardPath"
    }
}

if (Test-Path -LiteralPath $workOrdersRoot -PathType Container) {
    $workOrderFiles = @(Get-ChildItem -LiteralPath $workOrdersRoot -Filter *.md -File -ErrorAction SilentlyContinue | Sort-Object Name)
    $workOrderTotal = $workOrderFiles.Count
    if ($workOrderFiles.Count -eq 0) {
        Add-Finding -Findings $findings -Severity "INFO" -Message "No filled work orders found under work-orders"
    } else {
        $failedWorkOrders = New-Object System.Collections.Generic.List[string]
        foreach ($workOrder in $workOrderFiles) {
            $workOrderIssues = @(Get-WorkOrderIssues -Path $workOrder.FullName)
            if ($workOrderIssues.Count -ne 0) {
                $failedWorkOrders.Add($workOrder.Name) | Out-Null
            }
        }

        $workOrderFailed = $failedWorkOrders.Count
        if ($failedWorkOrders.Count -eq 0) {
            Add-Finding -Findings $findings -Severity "INFO" -Message "Work order checks passed: $($workOrderFiles.Count)"
        } else {
            Add-Finding -Findings $findings -Severity "FAIL" -Message ("Work order checks failed: {0}" -f ($failedWorkOrders -join ", "))
        }
    }
} else {
    Add-Finding -Findings $findings -Severity "WARN" -Message "Missing work-orders directory: $workOrdersRoot"
}

if (Test-Path -LiteralPath $reportsRoot -PathType Container) {
    $reportFiles = @(Get-ChildItem -LiteralPath $reportsRoot -Filter *.md -File -ErrorAction SilentlyContinue | Sort-Object Name)
    $reportTotal = $reportFiles.Count
    if ($reportFiles.Count -eq 0) {
        Add-Finding -Findings $findings -Severity "INFO" -Message "No report files found under reports"
    } else {
        $strictFailedWorkerReports = New-Object System.Collections.Generic.List[string]
        $invalidReports = New-Object System.Collections.Generic.List[string]

        foreach ($report in $reportFiles) {
            try {
                $reportLines = Read-MarkdownLines -Path $report.FullName
            } catch {
                $invalidReports.Add($report.Name) | Out-Null
                continue
            }

            if (Test-WorkerReport -Path $report.FullName -Lines $reportLines) {
                $workerReportCount++
                $reportIssues = @(Get-WorkerReportIssues -Path $report.FullName -Lines $reportLines)
                if ($reportIssues.Count -ne 0) {
                    $strictFailedWorkerReports.Add($report.Name) | Out-Null
                }
            } else {
                $nonWorkerReportCount++
            }
        }

        $invalidReportCount = $invalidReports.Count
        $strictFailedWorkerReportCount = $strictFailedWorkerReports.Count
        if ($Brownfield) {
            $warnOnlyWorkerReportCount = $strictFailedWorkerReports.Count
            $failedWorkerReportCount = 0
        } else {
            $warnOnlyWorkerReportCount = 0
            $failedWorkerReportCount = $strictFailedWorkerReports.Count
        }
        Add-Finding -Findings $findings -Severity "INFO" -Message ("Report scan: total={0}, worker={1}, non-worker={2}, invalid={3}" -f $reportFiles.Count, $workerReportCount, $nonWorkerReportCount, $invalidReports.Count)

        if ($invalidReports.Count -ne 0) {
            Add-Finding -Findings $findings -Severity "FAIL" -Message ("Report files could not be read: {0}" -f ($invalidReports -join ", "))
        }

        if ($strictFailedWorkerReports.Count -eq 0) {
            Add-Finding -Findings $findings -Severity "INFO" -Message "Worker report checks passed: $workerReportCount"
        } elseif ($Brownfield) {
            Add-Finding -Findings $findings -Severity "WARN" -Message ("Worker report strict shape warnings in brownfield mode: count={0}; sample={1}" -f $strictFailedWorkerReports.Count, (Format-NameSample -Names $strictFailedWorkerReports.ToArray()))
        } else {
            Add-Finding -Findings $findings -Severity "FAIL" -Message ("Worker report checks failed: {0}" -f ($strictFailedWorkerReports -join ", "))
        }
    }
} else {
    Add-Finding -Findings $findings -Severity "WARN" -Message "Missing reports directory: $reportsRoot"
}

if (-not (Test-GitAvailable)) {
    Add-Finding -Findings $findings -Severity "WARN" -Message "Git is not available on PATH"
} else {
    $gitAvailable = $true
    $gitRootChecked = 1
    $rootGitState = Add-GitFindings -Findings $findings -Label "Root" -Path $resolvedProjectRoot
    if ($rootGitState.IsDirty) {
        $gitDirtyRepositoryCount++
    }

    $worktreesRoot = Join-Path $resolvedProjectRoot ".worktrees"
    if (Test-Path -LiteralPath $worktreesRoot -PathType Container) {
        $worktrees = @(Get-ChildItem -LiteralPath $worktreesRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
        $gitWorktreesChecked = $worktrees.Count
        if ($worktrees.Count -eq 0) {
            Add-Finding -Findings $findings -Severity "INFO" -Message ".worktrees has no direct child directories"
        } else {
            foreach ($worktree in $worktrees) {
                $worktreeGitState = Add-GitFindings -Findings $findings -Label ("Worktree {0}" -f $worktree.Name) -Path $worktree.FullName
                if ($worktreeGitState.IsDirty) {
                    $gitDirtyRepositoryCount++
                }
            }
        }
    } else {
        Add-Finding -Findings $findings -Severity "INFO" -Message ".worktrees directory not found"
    }
}

$result = Get-ResultSeverity -Findings $findings.ToArray()

if ($Json) {
    $jsonFindings = @($findings | ForEach-Object {
        [pscustomobject][ordered]@{
            severity = $_.Severity
            message = $_.Message
        }
    })

    [pscustomobject][ordered]@{
        tool = "autoloop-check-coordination-state"
        schemaVersion = "1.0"
        projectRoot = $resolvedProjectRoot
        reportValidationMode = $reportValidationMode
        result = $result
        findings = $jsonFindings
        summary = [pscustomobject][ordered]@{
            findingCounts = [pscustomobject](Get-FindingCounts -Findings $findings.ToArray())
            board = [pscustomobject][ordered]@{
                taskCount = $boardTaskCount
                statusCounts = [pscustomobject]$boardStatusCounts
            }
            workOrders = [pscustomobject][ordered]@{
                total = $workOrderTotal
                failed = $workOrderFailed
            }
            reports = [pscustomobject][ordered]@{
                total = $reportTotal
                worker = $workerReportCount
                nonWorker = $nonWorkerReportCount
                invalid = $invalidReportCount
                failedWorker = $failedWorkerReportCount
                strictFailedWorker = $strictFailedWorkerReportCount
                warnOnlyWorker = $warnOnlyWorkerReportCount
            }
            git = [pscustomobject][ordered]@{
                gitAvailable = $gitAvailable
                rootChecked = $gitRootChecked
                worktreesChecked = $gitWorktreesChecked
                dirtyRepositories = $gitDirtyRepositoryCount
            }
        }
    } | ConvertTo-Json -Depth 8

    if ($result -eq "FAIL") {
        exit 1
    }

    exit 0
}

Write-Output "AutoLoop coordination state check"
Write-Output "Project root: $resolvedProjectRoot"
Write-Output "Result: $result"
Write-Output "Report validation mode: $reportValidationMode"
Write-Output "Findings:"

$findings | ForEach-Object {
    Write-Output ("- [{0}] {1}" -f $_.Severity, $_.Message)
}

if ($result -eq "FAIL") {
    exit 1
}

exit 0
