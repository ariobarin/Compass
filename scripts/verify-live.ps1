param(
    [string]$CodexHome,
    [string]$AgentsHome,
    [string]$ClaudeHome,
    [switch]$SkipPluginCheck,
    [switch]$RequireInSync
)

. "$PSScriptRoot\common.ps1"
. "$PSScriptRoot\reviewed-config.ps1"

$repoRoot = Get-RepoRoot
$liveHome = Get-CodexHome -CodexHome $CodexHome
$agentsHome = Get-AgentsHome -AgentsHome $AgentsHome
$claudeHome = Get-ClaudeHome -ClaudeHome $ClaudeHome
$items = Get-PortableFileMap -RepoRoot $repoRoot -CodexHome $liveHome -AgentsHome $agentsHome -ClaudeHome $claudeHome
$retiredItems = Get-RetiredPortableFileMap -CodexHome $liveHome -AgentsHome $agentsHome -ClaudeHome $claudeHome
Assert-PortableTargetSetsDisjoint -ActiveItems $items -RetiredItems $retiredItems
$drift = New-Object System.Collections.Generic.List[string]
$missing = New-Object System.Collections.Generic.List[string]
$retired = New-Object System.Collections.Generic.List[string]
$configProblems = New-Object System.Collections.Generic.List[string]
$pluginProblems = New-Object System.Collections.Generic.List[string]

foreach ($item in $items) {
    if (-not (Test-Path $item.LivePath)) {
        $missing.Add($item.LivePath)
        continue
    }

    if (-not (Test-Path $item.RepoPath)) {
        $missing.Add($item.RepoPath)
        continue
    }

    if ($item.Type -eq "file") {
        $repoHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $item.RepoPath).Hash
        $liveHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $item.LivePath).Hash
        if ($repoHash -ne $liveHash) {
            $drift.Add($item.LivePath)
        }
        continue
    }

    if ($item.Type -eq "derived-agent") {
        $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) ("compass-derived-agent-" + [guid]::NewGuid().ToString("N") + ".md")
        Copy-PortableItem -Source $item.RepoPath -Destination $tempFile -Type $item.Type -AllowedRoot (Split-Path -Parent $tempFile)
        $repoHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $tempFile).Hash
        $liveHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $item.LivePath).Hash
        Remove-Item -LiteralPath $tempFile -Force
        if ($repoHash -ne $liveHash) {
            $drift.Add($item.LivePath)
        }
        continue
    }

    $repoMap = Get-PortableDirectoryFileMap -Root $item.RepoPath -DerivedSkill:($item.Type -eq "derived-skill") -Stateful:($item.Type -eq "stateful-dir")
    $liveMap = Get-PortableDirectoryFileMap -Root $item.LivePath -Stateful:($item.Type -eq "stateful-dir")
    $allKeys = @(@($repoMap.Keys) + @($liveMap.Keys) | Sort-Object -Unique)
    foreach ($key in $allKeys) {
        if (-not $repoMap.ContainsKey($key) -or -not $liveMap.ContainsKey($key) -or $repoMap[$key] -ne $liveMap[$key]) {
            $drift.Add((Join-Path $item.LivePath $key))
        }
    }
}

foreach ($item in $retiredItems) {
    if (Test-Path $item.LivePath) {
        $retired.Add($item.LivePath)
    }
}

$reviewedConfigContract = Get-ReviewedConfigContract -RepoRoot $repoRoot -CodexHome $liveHome
$reviewConfigPath = $reviewedConfigContract.ReviewPath
$liveConfigPath = $reviewedConfigContract.LivePath
try {
    $reviewedConfigState = Get-ReviewedConfigState -ReviewPath $reviewConfigPath -RetirementPath $reviewedConfigContract.RetirementPath -LivePath $liveConfigPath
    foreach ($problem in @(Get-ReviewedConfigProblemStrings -State $reviewedConfigState)) {
        $configProblems.Add($problem)
    }
}
catch {
    $configProblems.Add($_.Exception.Message)
}

if (-not $SkipPluginCheck) {
    $pluginOutput = @(& (Join-Path $PSScriptRoot "retire-plugins.ps1") -CodexHome $liveHome -RequireAbsent *>&1 | ForEach-Object { $_.ToString() })
    if ($LASTEXITCODE -ne 0) {
        if ($pluginOutput.Count -eq 0) {
            $pluginProblems.Add("retired plugin verification failed")
        }
        else {
            foreach ($line in $pluginOutput) {
                $pluginProblems.Add($line)
            }
        }
    }
}

Write-Host "repo: $repoRoot"
Write-Host "codex: $liveHome"
Write-Host "agents: $agentsHome"
Write-Host "claude: $claudeHome"

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "missing:"
    foreach ($path in $missing) {
        Write-Host "  $path"
    }
}

if ($drift.Count -gt 0) {
    Write-Host ""
    Write-Host "drift:"
    foreach ($path in $drift) {
        Write-Host "  $path"
    }
}
if ($retired.Count -gt 0) {
    Write-Host ""
    Write-Host "retired portable copies:"
    foreach ($path in $retired) {
        Write-Host "  $path"
    }
}
if ($configProblems.Count -gt 0) {
    Write-Host ""
    Write-Host "config problems:"
    foreach ($problem in $configProblems) {
        Write-Host "  $problem"
    }
}
if ($pluginProblems.Count -gt 0) {
    Write-Host ""
    Write-Host "plugin problems:"
    foreach ($problem in $pluginProblems) {
        Write-Host "  $problem"
    }
}
if ($missing.Count -eq 0 -and $drift.Count -eq 0 -and $retired.Count -eq 0 -and $configProblems.Count -eq 0 -and $pluginProblems.Count -eq 0) {
    Write-Host "portable files match live allowlist"
}

if ($RequireInSync -and ($missing.Count -gt 0 -or $drift.Count -gt 0 -or $retired.Count -gt 0 -or $configProblems.Count -gt 0 -or $pluginProblems.Count -gt 0)) {
    exit 1
}
