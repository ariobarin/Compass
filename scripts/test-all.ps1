[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-TestFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force $parent | Out-Null
    }
    [System.IO.File]::WriteAllText(
        $Path,
        $Content,
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Assert-TestFileContains {
    param(
        [string]$Path,
        [string]$Expected
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "missing expected file: $Path"
    }
    $encoding = [System.Text.UTF8Encoding]::new($false, $true)
    if (-not ([System.IO.File]::ReadAllText($Path, $encoding)).Contains($Expected)) {
        throw "expected $Path to contain: $Expected"
    }
}

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "compass-test-$([guid]::NewGuid().ToString('N'))"
$codexHome = Join-Path $testRoot "codex"
$agentsHome = Join-Path $testRoot "agents"
$claudeHome = Join-Path $testRoot "claude"

try {
    $machineLabel = "preserve caf$([char]0x00E9)"
    Write-TestFile -Path (Join-Path $codexHome "AGENTS.md\local.txt") -Content "preserve this backup`n"
    Write-TestFile -Path (Join-Path $codexHome "auth.json") -Content "leave unlisted state alone`n"
    Write-TestFile -Path (Join-Path $codexHome "config.toml") -Content @"
MODEL = "machine-specific"
machine_setting = "$machineLabel"

["features"]
memories = false

[projects.'C:\machine']
trust_level = "trusted"
"@

    & (Join-Path $PSScriptRoot "install.ps1") `
        -Apply `
        -CodexHome $codexHome `
        -AgentsHome $agentsHome `
        -ClaudeHome $claudeHome
    & (Join-Path $PSScriptRoot "verify-live.ps1") `
        -RequireInSync `
        -CodexHome $codexHome `
        -AgentsHome $agentsHome `
        -ClaudeHome $claudeHome

    Assert-TestFileContains -Path (Join-Path $codexHome "config.toml") -Expected 'model = "gpt-5.6-sol"'
    Assert-TestFileContains -Path (Join-Path $codexHome "config.toml") -Expected 'MODEL = "machine-specific"'
    Assert-TestFileContains -Path (Join-Path $codexHome "config.toml") -Expected '["features"]'
    Assert-TestFileContains -Path (Join-Path $codexHome "config.toml") -Expected 'memories = true'
    if ((Get-Content -Raw -LiteralPath (Join-Path $codexHome "config.toml")).Contains("[features]")) {
        throw "config overlay duplicated a quoted table"
    }
    Assert-TestFileContains `
        -Path (Join-Path $codexHome "config.toml") `
        -Expected "machine_setting = `"$machineLabel`""
    Assert-TestFileContains -Path (Join-Path $codexHome "config.toml") -Expected 'trust_level = "trusted"'
    Assert-TestFileContains -Path (Join-Path $codexHome "auth.json") -Expected "leave unlisted state alone"

    $backupRoot = Join-Path $codexHome "portable-backups"
    Assert-TestFileContains `
        -Path (@(Get-ChildItem -LiteralPath $backupRoot -Recurse -Filter "local.txt" -File)[0].FullName) `
        -Expected "preserve this backup"
    if (@(Get-ChildItem -LiteralPath $backupRoot -Recurse -Filter "config.toml" -File).Count -ne 1) {
        throw "expected one live config backup"
    }

    Write-Host "portable tests: ok"
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
