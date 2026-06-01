$RepoRoot = Split-Path -Parent $PSScriptRoot
$AutoLoopScript = Join-Path $RepoRoot "scripts\autoloop.ps1"

function New-AutoLoopTempDirectory {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("autoloop-test-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $path | Out-Null
    return $path
}

function Invoke-AutoLoopEntry {
    param([string[]]$Arguments)

    $verifyScript = Join-Path $RepoRoot "scripts\verify-autoloop.ps1"
    $verifyText = Get-Content -LiteralPath $verifyScript -Raw
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq "verify" -and $Arguments -contains "-Quick" -and $verifyText -notmatch '\[switch\]\s*\$Quick') {
        return [pscustomobject]@{
            ExitCode = 999
            Output = "Quick parameter missing"
        }
    }

    $output = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $AutoLoopScript @Arguments 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

Describe "scripts/autoloop.ps1" {
    It "prints help and exits zero when no subcommand is provided" {
        $result = Invoke-AutoLoopEntry -Arguments @()

        $result.ExitCode | Should Be 0
        $result.Output | Should Match "AutoLoop command entry"
        $result.Output | Should Match "check-board"
        $result.Output | Should Match "doctor"
        $result.Output | Should Match "verify"
    }

    It "prints help and exits zero for the help subcommand" {
        $result = Invoke-AutoLoopEntry -Arguments @("help")

        $result.ExitCode | Should Be 0
        $result.Output | Should Match "AutoLoop command entry"
        $result.Output | Should Match "check-coordination-state"
    }

    It "returns nonzero for an unknown subcommand" {
        $result = Invoke-AutoLoopEntry -Arguments @("unknown-command")

        $result.ExitCode | Should Not Be 0
        $result.Output | Should Match "Unknown subcommand: unknown-command"
        $result.Output | Should Match "Run: scripts\\autoloop.ps1 help"
    }

    It "delegates status arguments unchanged" {
        $root = New-AutoLoopTempDirectory
        try {
            $result = Invoke-AutoLoopEntry -Arguments @("status", "-Root", $root, "-Json")

            $result.ExitCode | Should Be 0
            $result.Output | Should Match '"tool"'
            $result.Output | Should Match '"autoloop-status"'
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "preserves delegated failure exit codes" {
        $result = Invoke-AutoLoopEntry -Arguments @("check-work-order", "-WorkOrderPath", "missing-work-order.md")

        $result.ExitCode | Should Not Be 0
        $result.Output | Should Match "WorkOrderPath must be an existing file"
    }

    It "forwards verify quick arguments unchanged" {
        $result = Invoke-AutoLoopEntry -Arguments @("verify", "-Quick")

        $result.ExitCode | Should Be 0
        $result.Output | Should Match "AutoLoop quick verification"
        $result.Output | Should Match "does not replace full repository verification"
    }
}
