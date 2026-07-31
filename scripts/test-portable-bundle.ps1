[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "compass-portable-$([guid]::NewGuid().ToString('N'))"
$sourceRoot = Join-Path $testRoot "source"
$codexHome = Join-Path $testRoot "codex-home"
$agentsHome = Join-Path $testRoot "agents-home"
$claudeHome = Join-Path $testRoot "claude-home"
$powerShellPath = (Get-Process -Id $PID).Path

function Write-Utf8Text {
    param(
        [string]$Path,
        [string]$Text
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force $parent | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-TestScript {
    param(
        [string]$Path,
        [string[]]$Arguments,
        [int]$ExpectedExitCode = 0
    )

    $processArguments = @("-NoProfile")
    if ($env:OS -eq "Windows_NT") {
        $processArguments += @("-ExecutionPolicy", "Bypass")
    }
    $processArguments += @("-File", $Path) + $Arguments
    $oldPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $output = @(& $powerShellPath @processArguments 2>&1 | ForEach-Object { $_.ToString() })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    if ($exitCode -ne $ExpectedExitCode) {
        throw "expected exit code $ExpectedExitCode from $Path, got $exitCode`n$($output -join "`n")"
    }
    return $output
}

function Assert-FileContains {
    param(
        [string]$Path,
        [string]$Expected
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "expected file: $Path"
    }
    if (-not (Get-Content -Raw -LiteralPath $Path).Contains($Expected)) {
        throw "expected $Path to contain: $Expected"
    }
}

function Remove-TestLink {
    param([string]$Path)

    if ($env:OS -eq "Windows_NT") {
        [System.IO.Directory]::Delete($Path)
        return
    }
    Remove-Item -LiteralPath $Path -Force
}

try {
    New-Item -ItemType Directory -Force $sourceRoot, $codexHome, $agentsHome, $claudeHome | Out-Null
    New-Item -ItemType Directory -Force (Join-Path $sourceRoot "scripts") | Out-Null
    foreach ($name in @("common.ps1", "install.ps1", "verify-live.ps1")) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $sourceRoot "scripts\$name")
    }

    $manifestText = @'
{
  "codex": {"files": ["AGENTS.md"], "agents": ["sample"]},
  "agents": {"skills": ["sample-skill"]},
  "claude": {
    "files": ["CLAUDE.md"],
    "skills": ["sample-skill"],
    "agents": ["sample"]
  }
}
'@
    $manifestPath = Join-Path $sourceRoot "manifests\portable-files.json"
    Write-Utf8Text -Path $manifestPath -Text $manifestText
    Write-Utf8Text -Path (Join-Path $sourceRoot "codex\AGENTS.md") -Text "# Portable Codex instructions`n"
    Write-Utf8Text -Path (Join-Path $sourceRoot "codex\agents\sample.toml") -Text @'
name = "sample"
description = "Validate portable agent installation."
developer_instructions = """
Return portable agent evidence.
"""
'@
    Write-Utf8Text -Path (Join-Path $sourceRoot "codex\skills\sample-skill\SKILL.md") -Text @'
---
name: sample-skill
description: Validate portable skill installation.
---

# Sample skill
'@
    Write-Utf8Text -Path (Join-Path $sourceRoot "claude\CLAUDE.md") -Text "# Portable Claude instructions`n"
    Write-Utf8Text -Path (Join-Path $sourceRoot "claude\skills\sample-skill\SKILL.md") -Text "# Claude sample skill`n"
    Write-Utf8Text -Path (Join-Path $sourceRoot "claude\agents\sample.md") -Text "# Claude sample agent`n"
    Write-Utf8Text -Path (Join-Path $codexHome "auth.json") -Text "unrelated`n"
    Write-Utf8Text -Path (Join-Path $agentsHome "skills\foreign\SKILL.md") -Text "foreign`n"

    $homeArguments = @(
        "-CodexHome", $codexHome,
        "-AgentsHome", $agentsHome,
        "-ClaudeHome", $claudeHome
    )
    $installPath = Join-Path $sourceRoot "scripts\install.ps1"
    $verifyPath = Join-Path $sourceRoot "scripts\verify-live.ps1"

    $preview = @(Invoke-TestScript -Path $installPath -Arguments $homeArguments)
    if ($preview -notcontains "review mode: no files will be changed") {
        throw "preview did not identify review mode"
    }
    if (Test-Path -LiteralPath (Join-Path $codexHome "AGENTS.md")) {
        throw "preview changed the Codex home"
    }

    $mismatchedTarget = Join-Path $codexHome "AGENTS.md"
    Write-Utf8Text -Path (Join-Path $mismatchedTarget "local.txt") -Text "local directory content`n"
    [void](Invoke-TestScript -Path $installPath -Arguments (@("-Apply") + $homeArguments))
    [void](Invoke-TestScript -Path $verifyPath -Arguments (@("-RequireInSync") + $homeArguments))

    if (-not (Test-Path -LiteralPath $mismatchedTarget -PathType Leaf)) {
        throw "file target did not replace an existing directory"
    }
    Assert-FileContains -Path (Join-Path $codexHome "AGENTS.md") -Expected "Portable Codex instructions"
    Assert-FileContains -Path (Join-Path $codexHome "agents\sample.toml") -Expected 'name = "sample"'
    Assert-FileContains -Path (Join-Path $agentsHome "skills\sample-skill\SKILL.md") -Expected "# Sample skill"
    Assert-FileContains -Path (Join-Path $claudeHome "CLAUDE.md") -Expected "Portable Claude instructions"
    Assert-FileContains -Path (Join-Path $claudeHome "skills\sample-skill\SKILL.md") -Expected "# Claude sample skill"
    Assert-FileContains -Path (Join-Path $claudeHome "agents\sample.md") -Expected "# Claude sample agent"
    Assert-FileContains -Path (Join-Path $codexHome "auth.json") -Expected "unrelated"
    Assert-FileContains -Path (Join-Path $agentsHome "skills\foreign\SKILL.md") -Expected "foreign"
    $directoryBackup = @(
        Get-ChildItem -LiteralPath (Join-Path $codexHome "portable-backups") `
            -Recurse -Filter "local.txt" -File
    )
    if ($directoryBackup.Count -ne 1) {
        throw "expected one directory mismatch backup, found $($directoryBackup.Count)"
    }
    Assert-FileContains -Path $directoryBackup[0].FullName -Expected "local directory content"

    Add-Content -LiteralPath (Join-Path $codexHome "AGENTS.md") -Value "# local change"
    $replace = @(Invoke-TestScript -Path $installPath -Arguments (@("-Apply") + $homeArguments))
    [void](Invoke-TestScript -Path $verifyPath -Arguments (@("-RequireInSync") + $homeArguments))
    $backup = @(Get-ChildItem -LiteralPath (Join-Path $codexHome "portable-backups") -Recurse -Filter "AGENTS.md" -File)
    if ($backup.Count -ne 1) {
        throw "expected one AGENTS.md backup, found $($backup.Count)"
    }
    Assert-FileContains -Path $backup[0].FullName -Expected "local change"
    if (@($replace | Where-Object { $_ -like "backups: *" }).Count -eq 0) {
        throw "apply did not report its backup"
    }

    $secondApply = @(Invoke-TestScript -Path $installPath -Arguments (@("-Apply") + $homeArguments))
    if ($secondApply -notcontains "backups: none") {
        throw "unchanged apply created a backup"
    }
    if (Test-Path -LiteralPath (Join-Path $codexHome "portable-receipts")) {
        throw "direct installer created legacy receipts"
    }

    Write-Utf8Text -Path $manifestPath -Text $manifestText.Replace(
        '"files": ["AGENTS.md"]',
        '"files": ["AGENTS.md", "../outside.md"]'
    )
    [void](Invoke-TestScript -Path $installPath -Arguments $homeArguments -ExpectedExitCode 1)
    Write-Utf8Text -Path $manifestPath -Text $manifestText.Replace(
        '"files": ["AGENTS.md"]',
        '"files": ["AGENTS.md", "agents/sample.toml"]'
    )
    [void](Invoke-TestScript -Path $installPath -Arguments $homeArguments -ExpectedExitCode 1)
    Write-Utf8Text -Path $manifestPath -Text $manifestText.Replace(
        '"agents": ["sample"]',
        '"agents": ["missing"]'
    )
    [void](Invoke-TestScript -Path $installPath -Arguments $homeArguments -ExpectedExitCode 1)
    Write-Utf8Text -Path $manifestPath -Text $manifestText.Replace(
        '"agents": ["sample"]',
        '"agents": ["sample"], "dirs": []'
    )
    [void](Invoke-TestScript -Path $installPath -Arguments $homeArguments -ExpectedExitCode 1)
    Write-Utf8Text -Path $manifestPath -Text $manifestText.Replace(
        '"files": ["AGENTS.md"]',
        '"files": "AGENTS.md"'
    )
    [void](Invoke-TestScript -Path $installPath -Arguments $homeArguments -ExpectedExitCode 1)

    Write-Utf8Text -Path $manifestPath -Text $manifestText
    $backupBase = Join-Path $codexHome "portable-backups"
    Remove-Item -LiteralPath $backupBase -Recurse -Force
    $outsideBackupRoot = Join-Path $testRoot "outside-backups"
    New-Item -ItemType Directory -Force $outsideBackupRoot | Out-Null
    $linkType = if ($env:OS -eq "Windows_NT") { "Junction" } else { "SymbolicLink" }
    New-Item -ItemType $linkType -Path $backupBase -Target $outsideBackupRoot | Out-Null
    try {
        Add-Content -LiteralPath (Join-Path $codexHome "AGENTS.md") -Value "# another local change"
        [void](Invoke-TestScript -Path $installPath -Arguments (@("-Apply") + $homeArguments) -ExpectedExitCode 1)
        if (@(Get-ChildItem -LiteralPath $outsideBackupRoot -Recurse -Force).Count -ne 0) {
            throw "backup escaped through a link"
        }
    }
    finally {
        Remove-TestLink -Path $backupBase
    }

    $outsideSourceRoot = Join-Path $testRoot "outside-source"
    Write-Utf8Text -Path (Join-Path $outsideSourceRoot "secret.txt") -Text "outside source content`n"
    $sourceLink = Join-Path $sourceRoot "codex\skills\sample-skill\link"
    New-Item -ItemType $linkType -Path $sourceLink -Target $outsideSourceRoot | Out-Null
    try {
        [void](Invoke-TestScript -Path $installPath -Arguments (@("-Apply") + $homeArguments) -ExpectedExitCode 1)
        if (Test-Path -LiteralPath (Join-Path $agentsHome "skills\sample-skill\link\secret.txt")) {
            throw "install followed a linked portable source"
        }
    }
    finally {
        Remove-TestLink -Path $sourceLink
    }

    Write-Host "portable bundle test: ok"
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
