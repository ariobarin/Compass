Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:PortablePythonRunner = $null
$script:PortableRetirementManifest = $null

function Get-RepoRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Get-CodexHome {
    param([string]$CodexHome)

    if ($CodexHome) {
        return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($CodexHome)
    }
    if ($env:CODEX_HOME) {
        return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($env:CODEX_HOME)
    }
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
        (Join-Path $env:USERPROFILE ".codex")
    )
}

function Get-AgentsHome {
    param([string]$AgentsHome)

    if ($AgentsHome) {
        return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($AgentsHome)
    }
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
        (Join-Path $HOME ".agents")
    )
}

function Get-ClaudeHome {
    param([string]$ClaudeHome)

    if ($ClaudeHome) {
        return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ClaudeHome)
    }
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
        (Join-Path $HOME ".claude")
    )
}

function Get-PortablePythonRunner {
    if ($script:PortablePythonRunner) {
        return $script:PortablePythonRunner
    }

    $candidates = @(
        [pscustomobject]@{ Command = "py"; Prefix = @("-3") }
        [pscustomobject]@{ Command = "python"; Prefix = @() }
        [pscustomobject]@{ Command = "python3"; Prefix = @() }
    )
    foreach ($candidate in $candidates) {
        if (-not (Get-Command $candidate.Command -ErrorAction SilentlyContinue)) {
            continue
        }
        try {
            & $candidate.Command @($candidate.Prefix) -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)" *> $null
            if ($LASTEXITCODE -eq 0) {
                $script:PortablePythonRunner = $candidate
                return $candidate
            }
        }
        catch {
        }
    }
    throw "Python 3.11 or newer is required"
}

function New-DirectoryForFile {
    param([string]$Path)

    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Force $directory | Out-Null
    }
}

function Assert-PathUnderRoot {
    param(
        [string]$Path,
        [string]$Root
    )

    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd("\")
    $fullPath = [System.IO.Path]::GetFullPath($Path).TrimEnd("\")
    if ($fullPath -eq $fullRoot) {
        return
    }
    if (-not $fullPath.StartsWith("$fullRoot\", [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "refusing to write outside allowed root: $Path"
    }
}

function Get-PortableRetirementManifest {
    if ($script:PortableRetirementManifest) {
        return $script:PortableRetirementManifest
    }

    $path = Join-Path $PSScriptRoot "portable-retirements.json"
    try {
        $manifest = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
    }
    catch {
        throw "invalid portable retirement manifest: $($_.Exception.Message)"
    }
    if ($manifest.schema_version -ne 1) {
        throw "unsupported portable retirement manifest schema version"
    }
    $script:PortableRetirementManifest = $manifest
    return $manifest
}

function Get-RetiredPortableFileMap {
    param(
        [string]$CodexHome,
        [string]$AgentsHome,
        [string]$ClaudeHome
    )

    $roots = @{
        codex = $CodexHome
        agents = $AgentsHome
        claude = $ClaudeHome
    }
    $items = New-Object System.Collections.Generic.List[object]
    foreach ($entry in @((Get-PortableRetirementManifest).items)) {
        if ($entry.scope -notin @("codex", "agents", "claude")) {
            throw "unsupported portable retirement scope: $($entry.scope)"
        }
        if ($entry.type -notin @("file", "dir")) {
            throw "unsupported portable retirement type: $($entry.type)"
        }
        $root = $roots[[string]$entry.scope]
        $livePath = Join-Path $root ([string]$entry.path)
        Assert-PathUnderRoot -Path $livePath -Root $root
        $items.Add([pscustomobject]@{
            Type = [string]$entry.type
            LivePath = $livePath
            LiveRoot = $root
            BackupScope = [string]$entry.scope
        })
    }
    return $items
}

function Backup-LiveItem {
    param(
        [string]$LivePath,
        [string]$BackupRoot,
        [string]$LiveRoot,
        [string]$BackupScope,
        [string]$Type
    )

    if (-not (Test-Path -LiteralPath $LivePath)) {
        return
    }
    Assert-PathUnderRoot -Path $LivePath -Root $LiveRoot
    $relative = $LivePath.Substring($LiveRoot.Length).TrimStart("\")
    $backupPath = Join-Path (Join-Path $BackupRoot $BackupScope) $relative
    if ($Type -eq "dir") {
        New-Item -ItemType Directory -Force (Split-Path -Parent $backupPath) | Out-Null
        Copy-Item -LiteralPath $LivePath -Destination $backupPath -Recurse -Force
        return
    }
    New-DirectoryForFile -Path $backupPath
    Copy-Item -LiteralPath $LivePath -Destination $backupPath -Force
}
