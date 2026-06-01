param(
    [Parameter(Position = 0)]
    [string]$Subcommand,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArguments
)

$ErrorActionPreference = "Stop"

function Show-AutoLoopHelp {
    Write-Output "AutoLoop command entry"
    Write-Output "Usage: powershell -NoProfile -ExecutionPolicy Bypass -File scripts\autoloop.ps1 <subcommand> [args]"
    Write-Output ""
    Write-Output "Subcommands:"
    Write-Output "  status                       -> scripts\coordination\status.ps1"
    Write-Output "  check-board                  -> scripts\coordination\check-board.ps1"
    Write-Output "  check-work-order             -> scripts\coordination\check-work-order.ps1"
    Write-Output "  check-report                 -> scripts\coordination\check-report.ps1"
    Write-Output "  check-work-result            -> scripts\coordination\check-work-result.ps1"
    Write-Output "  check-integration-review     -> scripts\coordination\check-integration-review.ps1"
    Write-Output "  check-coordination-state     -> scripts\coordination\check-coordination-state.ps1"
    Write-Output "  summarize-coordination-state -> scripts\coordination\summarize-coordination-state.ps1"
    Write-Output "  doctor                       -> scripts\coordination\doctor.ps1"
    Write-Output "  verify                       -> scripts\verify-autoloop.ps1"
    Write-Output "  help                         -> show this help"
}

$commandMap = @{
    "status" = Join-Path $PSScriptRoot "coordination\status.ps1"
    "check-board" = Join-Path $PSScriptRoot "coordination\check-board.ps1"
    "check-work-order" = Join-Path $PSScriptRoot "coordination\check-work-order.ps1"
    "check-report" = Join-Path $PSScriptRoot "coordination\check-report.ps1"
    "check-work-result" = Join-Path $PSScriptRoot "coordination\check-work-result.ps1"
    "check-integration-review" = Join-Path $PSScriptRoot "coordination\check-integration-review.ps1"
    "check-coordination-state" = Join-Path $PSScriptRoot "coordination\check-coordination-state.ps1"
    "summarize-coordination-state" = Join-Path $PSScriptRoot "coordination\summarize-coordination-state.ps1"
    "doctor" = Join-Path $PSScriptRoot "coordination\doctor.ps1"
    "verify" = Join-Path $PSScriptRoot "verify-autoloop.ps1"
}

if (-not $Subcommand -or $Subcommand -eq "help") {
    Show-AutoLoopHelp
    exit 0
}

$normalizedSubcommand = $Subcommand.ToLowerInvariant()
if (-not $commandMap.ContainsKey($normalizedSubcommand)) {
    Write-Output "Unknown subcommand: $Subcommand"
    Write-Output "Run: scripts\autoloop.ps1 help"
    exit 1
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $commandMap[$normalizedSubcommand] @RemainingArguments
exit $LASTEXITCODE
