function Get-AutoLoopSectionLines {
    param(
        [string[]]$Lines,
        [string]$SectionName
    )

    $headingPattern = "^##\s+$([regex]::Escape($SectionName))\s*$"
    $startIndex = -1

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match $headingPattern) {
            $startIndex = $i + 1
            break
        }
    }

    if ($startIndex -lt 0) {
        return $null
    }

    $sectionLines = New-Object System.Collections.Generic.List[string]
    for ($i = $startIndex; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match "^##\s+") {
            break
        }
        $sectionLines.Add($Lines[$i])
    }

    return $sectionLines.ToArray()
}

function Test-AutoLoopMeaningfulValue {
    param([string]$Value)

    if ($null -eq $Value) {
        return $false
    }

    $trimmed = $Value.Trim().Trim([char]96)
    if ($trimmed.Length -eq 0) {
        return $false
    }

    if ($trimmed -match "<[^>]+>") {
        return $false
    }

    return $true
}

function Test-AutoLoopMeaningfulLine {
    param([string]$Line)

    $trimmed = $Line.Trim()
    if ($trimmed.Length -eq 0) {
        return $false
    }

    if ($trimmed -match "^````?") {
        return $false
    }

    if ($trimmed -match "<[^>]+>") {
        return $false
    }

    if ($trimmed -match "^\|\s*[-:\s|]+\|?$") {
        return $false
    }

    if ($trimmed -match "^\|\s*(File / Area|Command)\s*\|") {
        return $false
    }

    return $true
}

function Test-AutoLoopSectionHasContent {
    param([string[]]$SectionLines)

    foreach ($line in $SectionLines) {
        if (Test-AutoLoopMeaningfulLine -Line $line) {
            return $true
        }
    }

    return $false
}

function Get-AutoLoopBulletValue {
    param(
        [string[]]$Lines,
        [string]$Name
    )

    $pattern = "^\s*-\s+$([regex]::Escape($Name)):\s+(.+?)\s*$"
    foreach ($line in $Lines) {
        if ($line -match $pattern) {
            return $matches[1].Trim()
        }
    }

    return $null
}

function Get-AutoLoopSummaryValue {
    param(
        [string[]]$Lines,
        [string]$Name
    )

    $summaryLines = Get-AutoLoopSectionLines -Lines $Lines -SectionName "Summary"
    if ($null -eq $summaryLines) {
        return $null
    }

    $value = Get-AutoLoopBulletValue -Lines $summaryLines -Name $Name
    if ($null -eq $value) {
        return $null
    }

    return $value.Trim().Trim([char]96)
}

function Get-AutoLoopCodeFenceLines {
    param([string[]]$Lines)

    $insideFence = $false
    $commands = New-Object System.Collections.Generic.List[string]

    foreach ($line in $Lines) {
        if ($line.Trim() -match '^```') {
            $insideFence = -not $insideFence
            continue
        }

        if ($insideFence -and $line.Trim().Length -gt 0) {
            $commands.Add($line.Trim())
        }
    }

    return $commands.ToArray()
}

function Get-AutoLoopUnescapedPipeIndexes {
    param([string]$Value)

    $indexes = New-Object System.Collections.Generic.List[int]
    $backslashCount = 0

    for ($i = 0; $i -lt $Value.Length; $i++) {
        $character = $Value[$i]
        if ($character -eq "\") {
            $backslashCount++
            continue
        }

        if ($character -eq "|" -and ($backslashCount % 2) -eq 0) {
            $indexes.Add($i) | Out-Null
        }

        $backslashCount = 0
    }

    return $indexes.ToArray()
}

function Get-AutoLoopMarkdownTableFirstCell {
    param([string]$Line)

    $content = $Line.Trim()
    if ($content.StartsWith("|")) {
        $content = $content.Substring(1)
    }

    if ($content.EndsWith("|")) {
        $content = $content.Substring(0, $content.Length - 1)
    }

    $pipeIndexes = @(Get-AutoLoopUnescapedPipeIndexes -Value $content)
    if ($pipeIndexes.Count -lt 2) {
        return $null
    }

    $commandCellEnd = $pipeIndexes[$pipeIndexes.Count - 2]
    return $content.Substring(0, $commandCellEnd).Trim().Trim([char]96).Replace("\|", "|")
}
