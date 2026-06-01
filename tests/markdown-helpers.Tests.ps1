$RepoRoot = Split-Path -Parent $PSScriptRoot
$MarkdownLibrary = Join-Path $RepoRoot "scripts\lib\AutoLoop.Markdown.ps1"
. $MarkdownLibrary

Describe "AutoLoop.Markdown.ps1" {
    It "extracts level-two section lines without consuming the next section" {
        $lines = @(
            "# Document",
            "",
            "## Summary",
            '- ID: `T-001`',
            "",
            "## Verification",
            "- later"
        )

        $sectionLines = @(Get-AutoLoopSectionLines -Lines $lines -SectionName "Summary")

        $sectionLines.Count | Should Be 2
        $sectionLines[0] | Should Be '- ID: `T-001`'
        $sectionLines[1] | Should Be ""
    }

    It "extracts summary bullet values and keeps placeholder checks stable" {
        $lines = @(
            "# Worker Report",
            "",
            "## Summary",
            '- Work order ID: `T-001`',
            "- Result: <result>"
        )

        (Get-AutoLoopSummaryValue -Lines $lines -Name "Work order ID") | Should Be "T-001"
        (Test-AutoLoopMeaningfulValue -Value "<result>") | Should Be $false
    }

    It "extracts non-empty fenced commands" {
        $lines = @(
            '```powershell',
            " powershell -NoProfile -Command `"Write-Output ok`" ",
            "",
            "git diff --check",
            '```'
        )

        $commands = @(Get-AutoLoopCodeFenceLines -Lines $lines)

        $commands.Count | Should Be 2
        $commands[0] | Should Be 'powershell -NoProfile -Command "Write-Output ok"'
        $commands[1] | Should Be "git diff --check"
    }

    It "extracts verification command cells with pipeline and escaped pipe characters" {
        $pipelineLine = "| Get-ChildItem | Select-Object -First 1 | passed | ok |"
        $escapedPipeLine = "| Get-ChildItem \| Select-Object -First 1 | passed | ok |"

        (Get-AutoLoopMarkdownTableFirstCell -Line $pipelineLine) | Should Be "Get-ChildItem | Select-Object -First 1"
        (Get-AutoLoopMarkdownTableFirstCell -Line $escapedPipeLine) | Should Be "Get-ChildItem | Select-Object -First 1"
    }
}
