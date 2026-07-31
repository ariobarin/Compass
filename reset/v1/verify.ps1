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
$retiredItems = Get-RetiredPortableFileMap -CodexHome $liveHome -AgentsHome $agentsHome -ClaudeHome $claudeHome
$retired = New-Object System.Collections.Generic.List[string]
$configProblems = New-Object System.Collections.Generic.List[string]
$pluginProblems = New-Object System.Collections.Generic.List[string]

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
if ($retired.Count -eq 0 -and $configProblems.Count -eq 0 -and $pluginProblems.Count -eq 0) {
    Write-Host "former Compass targets are absent"
}

if ($RequireInSync -and ($retired.Count -gt 0 -or $configProblems.Count -gt 0 -or $pluginProblems.Count -gt 0)) {
    exit 1
}
