[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\common.ps1"

$data = Get-PortableGeneratedData
if ($data.schema_version -ne 1) {
    throw "portable manifest validation failed"
}

$scratch = Join-Path ([System.IO.Path]::GetTempPath()) "compass-source-check-$([guid]::NewGuid().ToString('N'))"
$items = @(
    Get-PortableFileMap `
        -RepoRoot (Get-RepoRoot) `
        -CodexHome (Join-Path $scratch "codex") `
        -AgentsHome (Join-Path $scratch "agents") `
        -ClaudeHome (Join-Path $scratch "claude")
)
foreach ($item in $items) {
    if (-not (Test-Path -LiteralPath $item.RepoPath)) {
        throw "missing portable source: $($item.RepoPath)"
    }
}
foreach ($sourcePath in @(
    (Join-Path (Get-RepoRoot) "codex\skills\README.md"),
    (Join-Path (Get-RepoRoot) "codex\agents\README.md")
)) {
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "missing permanent portable source surface: $sourcePath"
    }
}

$installRoot = Join-Path ([System.IO.Path]::GetTempPath()) "compass-blank-install-$([guid]::NewGuid().ToString('N'))"
try {
    $blankCodexHome = Join-Path $installRoot "codex"
    $blankAgentsHome = Join-Path $installRoot "agents"
    $blankClaudeHome = Join-Path $installRoot "claude"
    & (Join-Path $PSScriptRoot "install.ps1") `
        -Apply `
        -CodexHome $blankCodexHome `
        -AgentsHome $blankAgentsHome `
        -ClaudeHome $blankClaudeHome
    & (Join-Path $PSScriptRoot "verify-live.ps1") `
        -RequireInSync `
        -CodexHome $blankCodexHome `
        -AgentsHome $blankAgentsHome `
        -ClaudeHome $blankClaudeHome
    if (-not (Test-Path -LiteralPath (Join-Path $blankCodexHome "AGENTS.md") -PathType Leaf)) {
        throw "blank installation did not create AGENTS.md"
    }
    if (Test-Path -LiteralPath (Join-Path $blankCodexHome "config.toml")) {
        throw "blank installation created config.toml"
    }
    if (Test-Path -LiteralPath (Join-Path $blankCodexHome "agents")) {
        throw "blank installation created active Codex subagents"
    }
    if (Test-Path -LiteralPath (Join-Path $blankAgentsHome "skills")) {
        throw "blank installation created active skills"
    }
}
finally {
    if (Test-Path -LiteralPath $installRoot) {
        Remove-Item -LiteralPath $installRoot -Recurse -Force
    }
}

$powerShellPath = (Get-Process -Id $PID).Path
$arguments = @("-NoProfile")
if ($env:OS -eq "Windows_NT") {
    $arguments += @("-ExecutionPolicy", "Bypass")
}
$arguments += @("-File", (Join-Path $PSScriptRoot "test-portable-bundle.ps1"))
& $powerShellPath @arguments
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "portable tests: ok"
