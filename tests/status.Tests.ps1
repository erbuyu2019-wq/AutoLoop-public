$RepoRoot = Split-Path -Parent $PSScriptRoot
$StatusScript = Join-Path $RepoRoot "scripts\coordination\status.ps1"

function New-AutoLoopTempDirectory {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("autoloop-test-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $path | Out-Null
    return $path
}

function Invoke-Status {
    param(
        [string]$Root,
        [switch]$Json
    )

    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $StatusScript,
        "-Root",
        $Root
    )

    if ($Json) {
        $arguments += "-Json"
    }

    $output = @(& powershell @arguments 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

Describe "status.ps1" {
    It "handles a non-git directory without a noisy stack trace" {
        $root = New-AutoLoopTempDirectory
        try {
            $result = Invoke-Status -Root $root
            $result.ExitCode | Should Be 0
            $result.Output | Should Match "Git: not a git repo"
            $result.Output | Should Not Match "Exception"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "reports the current repository as a git repo" {
        $result = Invoke-Status -Root $RepoRoot
        $result.ExitCode | Should Be 0
        $result.Output | Should Match "Git: yes"
        $result.Output | Should Match "Branch:"
        $result.Output | Should Match "Dirty files:"
    }

    It "emits machine-readable JSON for the current repository" {
        $result = Invoke-Status -Root $RepoRoot -Json
        $result.ExitCode | Should Be 0
        $result.Output | Should Not Match "Git: yes"

        $status = $result.Output | ConvertFrom-Json
        $status.tool | Should Be "autoloop-status"
        $status.root | Should Be (Resolve-Path -LiteralPath $RepoRoot).Path
        $status.gitAvailable | Should Be $true
        $status.rootRepository.isGitRepository | Should Be $true
        $status.rootRepository.branch | Should Not BeNullOrEmpty
        @($status.PSObject.Properties.Name) -contains "worktrees" | Should Be $true
    }

    It "emits JSON for a non-git directory without failing" {
        $root = New-AutoLoopTempDirectory
        try {
            $result = Invoke-Status -Root $root -Json
            $result.ExitCode | Should Be 0

            $status = $result.Output | ConvertFrom-Json
            $status.rootRepository.isGitRepository | Should Be $false
            $status.rootRepository.status | Should Be "not-a-git-repo"
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "includes direct .worktrees children in JSON output" {
        $root = New-AutoLoopTempDirectory
        try {
            & git -C $root init | Out-Null
            $worktreesRoot = Join-Path $root ".worktrees"
            $workerRoot = Join-Path $worktreesRoot "worker"
            New-Item -ItemType Directory -Path $workerRoot -Force | Out-Null
            & git -C $workerRoot init | Out-Null

            $result = Invoke-Status -Root $root -Json
            $result.ExitCode | Should Be 0

            $status = $result.Output | ConvertFrom-Json
            @($status.worktrees).Count | Should Be 1
            $status.worktrees[0].label | Should Be "worktree: worker"
            $status.worktrees[0].kind | Should Be "worktree"
            $status.worktrees[0].isGitRepository | Should Be $true
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
