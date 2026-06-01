param(
    [string]$Root = (Get-Location).Path,
    [switch]$Json
)

$ErrorActionPreference = "Stop"

function Resolve-RootPath {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Root path does not exist: $Path"
    }

    return (Resolve-Path -LiteralPath $Path).Path
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

function Get-GitBranch {
    param([string]$Path)

    $branchResult = Invoke-GitQuiet -Path $Path -Arguments @("branch", "--show-current")
    $branch = $branchResult.Output -join ""
    $branch = $branch.Trim()
    if ($branchResult.ExitCode -eq 0 -and $branch.Length -gt 0) {
        return $branch
    }

    $headResult = Invoke-GitQuiet -Path $Path -Arguments @("rev-parse", "--short", "HEAD")
    $head = $headResult.Output -join ""
    $head = $head.Trim()
    if ($headResult.ExitCode -eq 0 -and $head.Length -gt 0) {
        return "detached@$head"
    }

    return "unknown"
}

function Get-GitDirtyCount {
    param([string]$Path)

    $statusResult = Invoke-GitQuiet -Path $Path -Arguments @("status", "--porcelain")
    if ($statusResult.ExitCode -ne 0) {
        return $null
    }

    return $statusResult.Output.Count
}

function Get-GitLastCommit {
    param([string]$Path)

    $commitResult = Invoke-GitQuiet -Path $Path -Arguments @("log", "-1", "--pretty=format:%h %s")
    $commit = $commitResult.Output -join ""
    $commit = $commit.Trim()
    if ($commitResult.ExitCode -eq 0 -and $commit.Length -gt 0) {
        return $commit
    }

    return "no commits"
}

function Get-RepoStatusObject {
    param(
        [string]$Label,
        [string]$Kind,
        [string]$Path
    )

    $repo = [ordered]@{
        label = $Label
        kind = $Kind
        path = $Path
        isGitRepository = $false
        status = "not-a-git-repo"
        branch = $null
        dirtyFileCount = $null
        lastCommit = $null
    }

    if (-not (Test-GitRepository -Path $Path)) {
        return [pscustomobject]$repo
    }

    $repo.isGitRepository = $true
    $repo.status = "ok"
    $repo.branch = Get-GitBranch -Path $Path
    $repo.dirtyFileCount = Get-GitDirtyCount -Path $Path
    $repo.lastCommit = Get-GitLastCommit -Path $Path

    return [pscustomobject]$repo
}

function Write-RepoStatus {
    param(
        [string]$Label,
        [string]$Path
    )

    Write-Output ""
    Write-Output "[$Label]"
    Write-Output "Path: $Path"

    if (-not (Test-GitRepository -Path $Path)) {
        Write-Output "Git: not a git repo"
        return
    }

    Write-Output "Git: yes"
    Write-Output ("Branch: {0}" -f (Get-GitBranch -Path $Path))
    $dirtyCount = Get-GitDirtyCount -Path $Path
    if ($null -eq $dirtyCount) {
        $dirtyCount = "unknown"
    }
    Write-Output ("Dirty files: {0}" -f $dirtyCount)
    Write-Output ("Last commit: {0}" -f (Get-GitLastCommit -Path $Path))
}

try {
    $resolvedRoot = Resolve-RootPath -Path $Root
} catch {
    Write-Output $_.Exception.Message
    exit 1
}

if (-not (Test-GitAvailable)) {
    if ($Json) {
        [pscustomobject]@{
            tool = "autoloop-status"
            root = $resolvedRoot
            gitAvailable = $false
            rootRepository = $null
            worktreesRoot = Join-Path $resolvedRoot ".worktrees"
            worktrees = @()
        } | ConvertTo-Json -Depth 6
        exit 0
    }

    Write-Output "AutoLoop status"
    Write-Output "Root: $resolvedRoot"
    Write-Output "Git: not available on PATH"
    exit 0
}

if ($Json) {
    $worktreesRoot = Join-Path $resolvedRoot ".worktrees"
    $worktreeStatuses = @()

    if (Test-Path -LiteralPath $worktreesRoot) {
        $worktrees = @(Get-ChildItem -LiteralPath $worktreesRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
        foreach ($worktree in $worktrees) {
            $worktreeStatuses += Get-RepoStatusObject -Label ("worktree: {0}" -f $worktree.Name) -Kind "worktree" -Path $worktree.FullName
        }
    }

    [pscustomobject]@{
        tool = "autoloop-status"
        root = $resolvedRoot
        gitAvailable = $true
        rootRepository = Get-RepoStatusObject -Label "root" -Kind "root" -Path $resolvedRoot
        worktreesRoot = $worktreesRoot
        worktrees = @($worktreeStatuses)
    } | ConvertTo-Json -Depth 6
    exit 0
}

Write-Output "AutoLoop status"
Write-Output "Root: $resolvedRoot"

Write-RepoStatus -Label "root" -Path $resolvedRoot

$worktreesRoot = Join-Path $resolvedRoot ".worktrees"
if (-not (Test-Path -LiteralPath $worktreesRoot)) {
    Write-Output ""
    Write-Output "[worktrees]"
    Write-Output "None: .worktrees directory not found"
    exit 0
}

$worktrees = @(Get-ChildItem -LiteralPath $worktreesRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
Write-Output ""
Write-Output "[worktrees]"

if ($worktrees.Count -eq 0) {
    Write-Output "None: .worktrees has no direct child directories"
    exit 0
}

foreach ($worktree in $worktrees) {
    Write-RepoStatus -Label ("worktree: {0}" -f $worktree.Name) -Path $worktree.FullName
}
