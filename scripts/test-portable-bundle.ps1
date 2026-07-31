[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "compass-portable-bundle-$([guid]::NewGuid().ToString('N'))"
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
    $oldErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $output = @(& $powerShellPath @processArguments 2>&1 | ForEach-Object { $_.ToString() })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldErrorActionPreference
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
    $text = Get-Content -Raw -LiteralPath $Path
    if (-not $text.Contains($Expected)) {
        throw "expected $Path to contain: $Expected"
    }
}

try {
    New-Item -ItemType Directory -Force $sourceRoot, $codexHome, $agentsHome, $claudeHome | Out-Null
    Copy-Item -LiteralPath $PSScriptRoot -Destination (Join-Path $sourceRoot "scripts") -Recurse

    Write-Utf8Text -Path (Join-Path $sourceRoot "manifests\portable-files.toml") -Text @'
[codex]
home = "fixture"
files = ["AGENTS.md"]
dirs = ["agents"]

[agents]
home = "fixture"
skills_dir = "fixture"
skills = ["sample-skill"]
stateful_skills = []

[claude]
home = "fixture"
skills_dir = "fixture"
agents_dir = "fixture"
files = ["CLAUDE.md"]
skills = ["direct-skill"]
derived_skills = ["sample-skill"]
agents = ["direct"]
derived_agents = ["sample"]

[config]
review_files = ["config.review.toml"]
reason = "fixture"

[repo_only]
files = []
dirs = ["manifests", "scripts"]
reason = "fixture"

[local_only]
files = []
dirs = []
patterns = []
'@
    Write-Utf8Text -Path (Join-Path $sourceRoot "manifests\portable-retirements.json") -Text @'
{
  "schema_version": 1,
  "base_commit": "fixture",
  "items": [],
  "config_entries": []
}
'@
    Write-Utf8Text -Path (Join-Path $sourceRoot "manifests\retired-plugins.json") -Text @'
{
  "schema_version": 1,
  "plugins": [],
  "marketplaces": []
}
'@

    Write-Utf8Text -Path (Join-Path $sourceRoot "codex\AGENTS.md") -Text "# Portable Codex instructions`n"
    Write-Utf8Text -Path (Join-Path $sourceRoot "codex\config.review.toml") -Text @'
model = "gpt-5.6-sol"

[agents]
max_depth = 2
'@
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
    Write-Utf8Text -Path (Join-Path $sourceRoot "codex\skills\sample-skill\agents\openai.yaml") -Text "interface:`n  display_name: Sample`n"
    Write-Utf8Text -Path (Join-Path $sourceRoot "codex\skills\sample-skill\references\evidence.md") -Text "# Evidence`n"
    Write-Utf8Text -Path (Join-Path $sourceRoot "claude\CLAUDE.md") -Text "# Portable Claude instructions`n"
    Write-Utf8Text -Path (Join-Path $sourceRoot "claude\skills\direct-skill\SKILL.md") -Text @'
---
name: direct-skill
description: Validate direct Claude skill installation.
---

# Direct skill
'@
    Write-Utf8Text -Path (Join-Path $sourceRoot "claude\agents\direct.md") -Text "# Direct Claude agent`n"
    Write-Utf8Text -Path (Join-Path $codexHome "config.toml") -Text "machine_local = true`n"

    $homeArguments = @(
        "-CodexHome", $codexHome,
        "-AgentsHome", $agentsHome,
        "-ClaudeHome", $claudeHome
    )
    $installPath = Join-Path $sourceRoot "scripts\install.ps1"
    $verifyPath = Join-Path $sourceRoot "scripts\verify-live.ps1"

    $preview = @(Invoke-TestScript -Path $installPath -Arguments (@("-SkipPluginRetirement") + $homeArguments))
    if ($preview -notcontains "review mode: no files will be changed") {
        throw "portable preview did not identify review mode"
    }
    if (Test-Path -LiteralPath (Join-Path $codexHome "AGENTS.md")) {
        throw "portable preview changed the Codex home"
    }

    [void](Invoke-TestScript -Path $installPath -Arguments (@("-Apply", "-SkipPluginRetirement") + $homeArguments))
    [void](Invoke-TestScript -Path $verifyPath -Arguments (@(
        "-SkipPluginCheck",
        "-RequireInSync"
    ) + $homeArguments))

    Assert-FileContains -Path (Join-Path $codexHome "AGENTS.md") -Expected "Portable Codex instructions"
    Assert-FileContains -Path (Join-Path $codexHome "agents\sample.toml") -Expected 'name = "sample"'
    Assert-FileContains -Path (Join-Path $agentsHome "skills\sample-skill\SKILL.md") -Expected "# Sample skill"
    Assert-FileContains -Path (Join-Path $claudeHome "CLAUDE.md") -Expected "Portable Claude instructions"
    Assert-FileContains -Path (Join-Path $claudeHome "skills\direct-skill\SKILL.md") -Expected "# Direct skill"
    Assert-FileContains -Path (Join-Path $claudeHome "skills\sample-skill\SKILL.md") -Expected "# Sample skill"
    Assert-FileContains -Path (Join-Path $claudeHome "agents\direct.md") -Expected "Direct Claude agent"
    Assert-FileContains -Path (Join-Path $claudeHome "agents\sample.md") -Expected "Return portable agent evidence"
    Assert-FileContains -Path (Join-Path $codexHome "config.toml") -Expected "machine_local = true"
    Assert-FileContains -Path (Join-Path $codexHome "config.toml") -Expected 'model = "gpt-5.6-sol"'
    if (Test-Path -LiteralPath (Join-Path $claudeHome "skills\sample-skill\agents\openai.yaml")) {
        throw "derived Claude skill retained Codex-only interface metadata"
    }

    Write-Utf8Text -Path (Join-Path $sourceRoot "manifests\portable-retirements.json") -Text @'
{
  "schema_version": 1,
  "base_commit": "fixture",
  "items": [
    {"scope": "codex", "type": "file", "path": "AGENTS.md"}
  ],
  "config_entries": []
}
'@
    [void](Invoke-TestScript -Path $installPath -Arguments (@("-Apply", "-SkipPluginRetirement") + $homeArguments) -ExpectedExitCode 1)
    Assert-FileContains -Path (Join-Path $codexHome "AGENTS.md") -Expected "Portable Codex instructions"
    Write-Utf8Text -Path (Join-Path $sourceRoot "manifests\portable-retirements.json") -Text @'
{
  "schema_version": 1,
  "base_commit": "fixture",
  "items": [],
  "config_entries": []
}
'@

    Add-Content -LiteralPath (Join-Path $codexHome "AGENTS.md") -Value "# foreign change"
    [void](Invoke-TestScript -Path $installPath -Arguments (@("-Apply", "-SkipPluginRetirement") + $homeArguments) -ExpectedExitCode 1)
    Assert-FileContains -Path (Join-Path $codexHome "AGENTS.md") -Expected "foreign change"

    Write-Host "portable bundle test: ok"
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
