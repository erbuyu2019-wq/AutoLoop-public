param(
    [switch]$Quick,
    [string]$WorkOrderPath,
    [string]$ReportPath
)

$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    $scriptPath = $PSCommandPath
    if (-not $scriptPath) {
        $scriptPath = $MyInvocation.MyCommand.Path
    }

    return (Resolve-Path -LiteralPath (Join-Path (Split-Path -Parent $scriptPath) "..")).Path
}

function Invoke-AutoLoopStep {
    param(
        [string]$Name,
        [scriptblock]$Action
    )

    Write-Output ""
    Write-Output "== $Name =="
    & $Action
    Write-Output "PASS: $Name"
}

function Invoke-ExternalCommand {
    param(
        [string]$FilePath,
        [string[]]$Arguments
    )

    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code $LASTEXITCODE`: $FilePath $($Arguments -join ' ')"
    }
}

$repoRoot = Get-RepoRoot
Set-Location -LiteralPath $repoRoot

if ($Quick) {
    $hasWorkOrderPath = $PSBoundParameters.ContainsKey("WorkOrderPath")
    $hasReportPath = $PSBoundParameters.ContainsKey("ReportPath")

    Write-Output "AutoLoop quick verification"
    Write-Output "Root: $repoRoot"
    Write-Output "Mode: read-only coordinator preflight"
    Write-Output "Warning: quick verification does not replace full repository verification before submit, acceptance, or release."

    Invoke-AutoLoopStep -Name "Run board check" -Action {
        Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            "scripts\coordination\check-board.ps1",
            "-BoardPath",
            "docs\coordination\board.md"
        )
    }

    if ($hasWorkOrderPath) {
        Invoke-AutoLoopStep -Name "Run work order check" -Action {
            Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                "scripts\coordination\check-work-order.ps1",
                "-WorkOrderPath",
                $WorkOrderPath
            )
        }
    }

    if ($hasReportPath) {
        Invoke-AutoLoopStep -Name "Run worker report check" -Action {
            Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                "scripts\coordination\check-report.ps1",
                "-ReportPath",
                $ReportPath,
                "-Strict"
            )
        }
    }

    if ($hasWorkOrderPath -and $hasReportPath) {
        Invoke-AutoLoopStep -Name "Run work result check" -Action {
            Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                "scripts\coordination\check-work-result.ps1",
                "-WorkOrderPath",
                $WorkOrderPath,
                "-ReportPath",
                $ReportPath
            )
        }
    }

    Invoke-AutoLoopStep -Name "Run coordination state check" -Action {
        Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            "scripts\coordination\check-coordination-state.ps1",
            "-ProjectRoot",
            ".",
            "-Brownfield"
        )
    }

    Invoke-AutoLoopStep -Name "Run git diff whitespace check" -Action {
        Invoke-ExternalCommand -FilePath "git" -Arguments @("diff", "--check")
    }

    Write-Output ""
    Write-Output "AutoLoop quick verification complete"
    exit 0
}

Write-Output "AutoLoop repository verification"
Write-Output "Root: $repoRoot"

Invoke-AutoLoopStep -Name "Parse PowerShell scripts" -Action {
    $failed = $false
    Get-ChildItem -Path "scripts", "tests" -Filter *.ps1 -Recurse | ForEach-Object {
        $errors = $null
        $tokens = $null
        [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors) | Out-Null
        if ($errors.Count -gt 0) {
            $failed = $true
            Write-Output "Parse failed: $($_.FullName)"
            $errors | ForEach-Object { Write-Output "- $($_.Message)" }
        }
    }

    if ($failed) {
        throw "PowerShell parse check failed"
    }
}

Invoke-AutoLoopStep -Name "Run Pester tests" -Action {
    Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-Command",
        "Invoke-Pester -Script tests -EnableExit"
    )
}

Invoke-AutoLoopStep -Name "Run status check" -Action {
    Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "scripts\coordination\status.ps1"
    )
}

Invoke-AutoLoopStep -Name "Run status JSON check" -Action {
    Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "scripts\coordination\status.ps1",
        "-Root",
        ".",
        "-Json"
    )
}

Invoke-AutoLoopStep -Name "Run coordination state check" -Action {
    Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "scripts\coordination\check-coordination-state.ps1",
        "-ProjectRoot",
        "."
    )
}

Invoke-AutoLoopStep -Name "Run coordination state JSON check" -Action {
    Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "scripts\coordination\check-coordination-state.ps1",
        "-ProjectRoot",
        ".",
        "-Json"
    )
}

Invoke-AutoLoopStep -Name "Run coordination state summary check" -Action {
    Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "scripts\coordination\summarize-coordination-state.ps1",
        "-ProjectRoots",
        "."
    )
}

Invoke-AutoLoopStep -Name "Run coordination state summary JSON check" -Action {
    Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "scripts\coordination\summarize-coordination-state.ps1",
        "-ProjectRoots",
        ".",
        "-Json"
    )
}

Invoke-AutoLoopStep -Name "Run board check" -Action {
    Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "scripts\coordination\check-board.ps1",
        "-BoardPath",
        "docs\coordination\board.md"
    )
    Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "scripts\coordination\check-board.ps1",
        "-BoardPath",
        "docs\examples\multi-owner-smoke\board.md"
    )
}

Invoke-AutoLoopStep -Name "Run worker report check" -Action {
    Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "scripts\coordination\check-report.ps1",
        "-ReportPath",
        "docs\coordination\reports\phase6-dogfood-worker-report.md",
        "-Strict"
    )
}

Invoke-AutoLoopStep -Name "Run work order check" -Action {
    Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "scripts\coordination\check-work-order.ps1",
        "-WorkOrderPath",
        "docs\coordination\work-orders\phase6-dogfood.md"
    )
}

Invoke-AutoLoopStep -Name "Run work result check" -Action {
    Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "scripts\coordination\check-work-result.ps1",
        "-WorkOrderPath",
        "docs\coordination\work-orders\T-P22-003-work-result-paired-check.md",
        "-ReportPath",
        "docs\coordination\reports\T-P22-003-worker-report.md"
    )
}

Invoke-AutoLoopStep -Name "Run integration review check" -Action {
    Invoke-ExternalCommand -FilePath "powershell" -Arguments @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "scripts\coordination\check-integration-review.ps1",
        "-WorkOrderPath",
        "docs\examples\multi-owner-smoke\work-order.md",
        "-ReportPaths",
        "docs\examples\multi-owner-smoke\reports\app.md,docs\examples\multi-owner-smoke\reports\device.md,docs\examples\multi-owner-smoke\reports\workbench.md",
        "-ExpectedOwners",
        "app,device,workbench"
    )
}

Invoke-AutoLoopStep -Name "Run git diff whitespace checks" -Action {
    Invoke-ExternalCommand -FilePath "git" -Arguments @("diff", "--check")
    Invoke-ExternalCommand -FilePath "git" -Arguments @("diff", "--cached", "--check")
}

Invoke-AutoLoopStep -Name "Run text whitespace check" -Action {
    $failed = $false
    $extensions = @(".md", ".ps1", ".yml", ".yaml")
    $files = @(& git -c core.quotePath=false ls-files) + @(& git -c core.quotePath=false ls-files --others --exclude-standard)

    foreach ($file in $files | Sort-Object -Unique) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
            continue
        }

        if ($extensions -notcontains [System.IO.Path]::GetExtension($file)) {
            continue
        }

        $lineNumber = 0
        Get-Content -Encoding UTF8 -LiteralPath $file | ForEach-Object {
            $lineNumber++
            if ($_ -match "\s+$") {
                $failed = $true
                Write-Output "$file`:$lineNumber trailing whitespace"
            }
        }
    }

    if ($failed) {
        throw "Text whitespace check failed"
    }
}

Write-Output ""
Write-Output "AutoLoop verification complete"
