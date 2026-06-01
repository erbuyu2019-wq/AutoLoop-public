[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$ProjectName = "",
    [string[]]$Owners = @(),
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Resolve-ExistingDirectory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "ProjectRoot must be an existing directory: $Path"
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

function Get-TemplateRoot {
    $scriptPath = $PSCommandPath
    if (-not $scriptPath) {
        $scriptPath = $MyInvocation.MyCommand.Path
    }

    $scriptDir = Split-Path -Parent $scriptPath
    return (Resolve-Path -LiteralPath (Join-Path $scriptDir "..\..\templates\coordination")).Path
}

function Copy-TemplateFile {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$Force,
        [switch]$DryRun
    )

    $destinationExists = Test-Path -LiteralPath $Destination
    if ($destinationExists -and -not $Force) {
        Write-Output "skip: $Destination already exists"
        return
    }

    $action = "write"
    if ($destinationExists -and $Force) {
        $action = "overwrite"
    }

    if ($DryRun) {
        Write-Output "would $action`: $Destination"
        return
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Force:$Force
    Write-Output "$action`: $Destination"
}

function New-ProjectDirectory {
    param(
        [string]$Path,
        [switch]$DryRun
    )

    if (Test-Path -LiteralPath $Path -PathType Container) {
        return
    }

    if ($DryRun) {
        Write-Output "would create: $Path"
        return
    }

    if ($PSCmdlet.ShouldProcess($Path, "Create directory")) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
        Write-Output "create: $Path"
    }
}

function New-OwnerRows {
    param([string[]]$OwnerNames)

    $cleanOwners = @(
        $OwnerNames |
            ForEach-Object { $_ -split "," } |
            Where-Object { $_ -and $_.Trim().Length -gt 0 } |
            ForEach-Object { $_.Trim() }
    )
    if ($cleanOwners.Count -eq 0) {
        return '| `<owner>` | `<module or responsibility>` | `<path or thread label>` | `<boundary notes>` |'
    }

    return ($cleanOwners | ForEach-Object {
        "| $_ | ``<scope>`` | ``<workspace or thread>`` | ``<boundary notes>`` |"
    }) -join [Environment]::NewLine
}

function New-BoardContent {
    param(
        [string]$TemplatePath,
        [string]$Name,
        [string[]]$OwnerNames
    )

    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $TemplatePath
    $content = $content.Replace('Project: `<project-name>`', "Project: $Name")

    $ownerRows = New-OwnerRows -OwnerNames $OwnerNames
    $content = $content.Replace(
        '| `<owner>` | `<module or responsibility>` | `<path or thread label>` | `<boundary notes>` |',
        $ownerRows
    )

    return $content
}

try {
    $resolvedProjectRoot = Resolve-ExistingDirectory -Path $ProjectRoot
    $templateRoot = Get-TemplateRoot
} catch {
    Write-Output $_.Exception.Message
    exit 1
}

if ($ProjectName.Trim().Length -eq 0) {
    $ProjectName = Split-Path -Leaf $resolvedProjectRoot
}

$coordinationRoot = Join-Path $resolvedProjectRoot "docs\coordination"
$simulate = $DryRun -or $WhatIfPreference

Write-Output "AutoLoop init"
Write-Output "Project root: $resolvedProjectRoot"
Write-Output "Project name: $ProjectName"
Write-Output "Coordination root: $coordinationRoot"
if ($simulate) {
    Write-Output "Mode: dry run"
}

$instanceDirectories = @(
    $coordinationRoot,
    (Join-Path $coordinationRoot "work-orders"),
    (Join-Path $coordinationRoot "reports"),
    (Join-Path $coordinationRoot "contracts"),
    (Join-Path $resolvedProjectRoot "docs\trials")
)

foreach ($directory in $instanceDirectories) {
    New-ProjectDirectory -Path $directory -DryRun:$simulate
}

$templateFiles = @(
    "README.md",
    "decision-log.md",
    "work-order.md",
    "worker-report.md",
    "stage-closeout.md",
    "gates.md"
)

foreach ($fileName in $templateFiles) {
    Copy-TemplateFile `
        -Source (Join-Path $templateRoot $fileName) `
        -Destination (Join-Path $coordinationRoot $fileName) `
        -Force:$Force `
        -DryRun:$simulate
}

$boardDestination = Join-Path $coordinationRoot "board.md"
if ((Test-Path -LiteralPath $boardDestination) -and -not $Force) {
    Write-Output "skip: $boardDestination already exists"
} else {
    $boardAction = "write"
    if ((Test-Path -LiteralPath $boardDestination) -and $Force) {
        $boardAction = "overwrite"
    }

    $boardContent = New-BoardContent `
        -TemplatePath (Join-Path $templateRoot "board.md") `
        -Name $ProjectName `
        -OwnerNames $Owners

    if ($simulate) {
        Write-Output "would $boardAction`: $boardDestination"
    } elseif ($PSCmdlet.ShouldProcess($boardDestination, "$boardAction board file")) {
        Set-Content -LiteralPath $boardDestination -Encoding UTF8 -Value $boardContent
        Write-Output "$boardAction`: $boardDestination"
    }
}
