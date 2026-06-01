$RepoRoot = Split-Path -Parent $PSScriptRoot
$InitScript = Join-Path $RepoRoot "scripts\coordination\init-autoloop.ps1"

function New-AutoLoopTempDirectory {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("autoloop-test-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $path | Out-Null
    return $path
}

function Invoke-InitAutoLoop {
    param(
        [string]$ProjectRoot,
        [string[]]$ExtraArgs = @()
    )

    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $InitScript,
        "-ProjectRoot",
        $ProjectRoot,
        "-ProjectName",
        "TempProject",
        "-Owners",
        "app,device"
    ) + $ExtraArgs

    $output = @(& powershell @arguments 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

Describe "init-autoloop.ps1" {
    It "does not create coordination files in DryRun mode" {
        $root = New-AutoLoopTempDirectory
        try {
            $result = Invoke-InitAutoLoop -ProjectRoot $root -ExtraArgs @("-DryRun")
            $result.ExitCode | Should Be 0
            (Test-Path -LiteralPath (Join-Path $root "docs\coordination")) | Should Be $false
            $result.Output | Should Match "would create:"
            $result.Output | Should Match "would write:"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "does not create coordination files in WhatIf mode" {
        $root = New-AutoLoopTempDirectory
        try {
            $result = Invoke-InitAutoLoop -ProjectRoot $root -ExtraArgs @("-WhatIf")
            $result.ExitCode | Should Be 0
            (Test-Path -LiteralPath (Join-Path $root "docs\coordination")) | Should Be $false
            $result.Output | Should Match "Mode: dry run"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "creates coordination files and instance directories" {
        $root = New-AutoLoopTempDirectory
        try {
            $result = Invoke-InitAutoLoop -ProjectRoot $root
            $result.ExitCode | Should Be 0
            (Test-Path -LiteralPath (Join-Path $root "docs\coordination\README.md")) | Should Be $true
            (Test-Path -LiteralPath (Join-Path $root "docs\coordination\board.md")) | Should Be $true
            (Test-Path -LiteralPath (Join-Path $root "docs\coordination\stage-closeout.md")) | Should Be $true
            (Test-Path -LiteralPath (Join-Path $root "docs\coordination\work-orders")) | Should Be $true
            (Test-Path -LiteralPath (Join-Path $root "docs\coordination\reports")) | Should Be $true
            (Test-Path -LiteralPath (Join-Path $root "docs\coordination\contracts")) | Should Be $true
            (Test-Path -LiteralPath (Join-Path $root "docs\trials")) | Should Be $true
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "skips existing files by default" {
        $root = New-AutoLoopTempDirectory
        try {
            Invoke-InitAutoLoop -ProjectRoot $root | Out-Null
            $readme = Join-Path $root "docs\coordination\README.md"
            Set-Content -LiteralPath $readme -Encoding UTF8 -Value "sentinel"

            $result = Invoke-InitAutoLoop -ProjectRoot $root
            $result.ExitCode | Should Be 0
            ((Get-Content -Raw -Encoding UTF8 -LiteralPath $readme).Trim()) | Should Be "sentinel"
            $result.Output | Should Match "skip:"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "overwrites existing files only with Force" {
        $root = New-AutoLoopTempDirectory
        try {
            Invoke-InitAutoLoop -ProjectRoot $root | Out-Null
            $readme = Join-Path $root "docs\coordination\README.md"
            Set-Content -LiteralPath $readme -Encoding UTF8 -Value "sentinel"

            $result = Invoke-InitAutoLoop -ProjectRoot $root -ExtraArgs @("-Force")
            $result.ExitCode | Should Be 0
            ((Get-Content -Raw -Encoding UTF8 -LiteralPath $readme).Trim()) | Should Not Be "sentinel"
            $result.Output | Should Match "overwrite:"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
