param(
    [Parameter(Mandatory = $true)]
    [string]$BoardPath
)

$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\AutoLoop.Markdown.ps1")
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\AutoLoop.Checks.ps1")

$allowedStatuses = @(Get-AutoLoopBoardStatuses)

function Resolve-BoardPath {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "BoardPath must be an existing file: $Path"
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

function Test-ConcreteBlocker {
    param([string]$Value)

    if (-not (Test-MeaningfulValue -Value $Value)) {
        return $false
    }

    $normalized = $Value.Trim().Trim([char]96).ToLowerInvariant()
    if ($normalized -eq "none" -or $normalized -eq "n/a" -or $normalized -eq "na" -or $normalized -eq "-") {
        return $false
    }

    return $true
}

function Get-TaskRows {
    param([string[]]$Lines)

    $rows = New-Object System.Collections.Generic.List[object]

    foreach ($line in $Lines) {
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
        $rows.Add([pscustomobject]@{
            Raw = $line
            Columns = $columns
        }) | Out-Null
    }

    return $rows.ToArray()
}

try {
    $resolvedBoardPath = Resolve-BoardPath -Path $BoardPath
} catch {
    Write-Output $_.Exception.Message
    exit 1
}

$lines = @(Get-Content -Encoding UTF8 -LiteralPath $resolvedBoardPath)
$issues = New-Object System.Collections.Generic.List[string]

if (($lines -join "`n") -match "<[^>]+>") {
    $issues.Add("Unresolved placeholders")
}

$taskSection = Get-SectionLines -Lines $lines -SectionName "Tasks"
if ($null -eq $taskSection) {
    $issues.Add("Missing Tasks section")
} else {
    $rows = @(Get-TaskRows -Lines $taskSection)
    if ($rows.Count -eq 0) {
        $issues.Add("No task rows found")
    }

    foreach ($row in $rows) {
        if ($row.Columns.Count -lt 7) {
            $issues.Add("Malformed task row: $($row.Raw)")
            continue
        }

        $id = $row.Columns[0]
        $status = $row.Columns[1]
        $owner = $row.Columns[2]
        $task = $row.Columns[3]
        $allowedScope = $row.Columns[4]
        $blocker = $row.Columns[5]
        $nextStep = $row.Columns[6]
        $rowLabel = $id
        if (-not (Test-MeaningfulValue -Value $rowLabel)) {
            $rowLabel = "<unknown task>"
        }

        if (-not (Test-MeaningfulValue -Value $id)) {
            $issues.Add("Missing task ID")
        }

        if (-not (Test-MeaningfulValue -Value $status) -or $allowedStatuses -notcontains $status.ToLowerInvariant()) {
            $issues.Add("Invalid status for $rowLabel`: $status")
        }

        if (-not (Test-MeaningfulValue -Value $owner)) {
            $issues.Add("Missing owner for $rowLabel")
        }

        if (-not (Test-MeaningfulValue -Value $task)) {
            $issues.Add("Missing task description for $rowLabel")
        }

        if (-not (Test-MeaningfulValue -Value $allowedScope)) {
            $issues.Add("Missing allowed scope for $rowLabel")
        }

        if (-not (Test-MeaningfulValue -Value $nextStep)) {
            $issues.Add("Missing next step for $rowLabel")
        }

        if ((Test-MeaningfulValue -Value $status) -and $status.ToLowerInvariant() -eq "blocked" -and -not (Test-ConcreteBlocker -Value $blocker)) {
            $issues.Add("Blocked task needs concrete blocker for $rowLabel")
        }
    }
}

Write-Output "AutoLoop board check"
Write-Output "Board: $resolvedBoardPath"

if ($issues.Count -eq 0) {
    Write-Output "Result: PASS"
    exit 0
}

Write-Output "Result: FAIL"
Write-Output "Issues:"
$issues | ForEach-Object { Write-Output "- $_" }
exit 1
