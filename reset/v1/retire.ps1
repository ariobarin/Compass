param(
    [switch]$Apply,
    [Alias("ReplaceForeign")]
    [switch]$Adopt,
    [string]$SourceRef,
    [string]$SourceCommit,
    [string]$CodexHome,
    [string]$AgentsHome,
    [string]$ClaudeHome,
    [switch]$SkipPluginRetirement
)

. "$PSScriptRoot\common.ps1"
. "$PSScriptRoot\receipt-common.ps1"
. "$PSScriptRoot\reviewed-config.ps1"

[char[]]$pathSeparators = @(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) | Select-Object -Unique

function Get-ItemBackupPath {
    param(
        [object]$Item,
        [string]$BackupRoot
    )

    $relative = $Item.LivePath.Substring($Item.LiveRoot.Length).TrimStart($pathSeparators)
    $backupBase = if ($Item.BackupScope) {
        Join-Path $BackupRoot $Item.BackupScope
    }
    else {
        $BackupRoot
    }
    return Join-Path $backupBase $relative
}

function Get-GitScalar {
    param([string[]]$Arguments)

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        return $null
    }

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $output = @(& git -C $repoRoot @Arguments 2>$null)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($exitCode -ne 0) {
        return $null
    }
    return $output | Select-Object -First 1
}

function Test-ReceiptTargetSetEqual {
    param(
        [AllowNull()]
        [object]$Receipt,
        [object[]]$RetiredItems
    )

    if ($null -eq $Receipt) {
        return $false
    }
    $expected = @($RetiredItems | ForEach-Object { $_.LivePath } | Sort-Object -Unique)
    $actual = @(@($Receipt.artifacts | ForEach-Object { $_.target }) | Sort-Object -Unique)
    return @(Compare-Object -ReferenceObject $expected -DifferenceObject $actual).Count -eq 0
}

$repoRoot = Get-RepoRoot
$headCommit = Get-GitScalar -Arguments @("rev-parse", "HEAD")
if ($SourceCommit) {
    if (-not $headCommit) {
        throw "cannot validate source commit without repository HEAD"
    }
    if ($SourceCommit -ne $headCommit) {
        throw "source commit does not match repository HEAD"
    }
}
$resolvedSourceCommit = if ($SourceCommit) { $SourceCommit } else { $headCommit }
$resolvedSourceRef = $SourceRef
if (-not $resolvedSourceRef) {
    $resolvedSourceRef = Get-GitScalar -Arguments @("branch", "--show-current")
    if (-not $resolvedSourceRef) {
        $resolvedSourceRef = Get-GitScalar -Arguments @("describe", "--tags", "--exact-match", "HEAD")
    }
    if (-not $resolvedSourceRef) {
        $resolvedSourceRef = "detached"
    }
}

$liveHome = Get-CodexHome -CodexHome $CodexHome
$agentsHome = Get-AgentsHome -AgentsHome $AgentsHome
$claudeHome = Get-ClaudeHome -ClaudeHome $ClaudeHome
$retiredItems = @(Get-RetiredPortableFileMap -CodexHome $liveHome -AgentsHome $agentsHome -ClaudeHome $claudeHome)
$currentReceipt = Get-PortableCurrentReceipt -CodexHome $liveHome
$reviewedConfigContract = Get-ReviewedConfigContract -RepoRoot $repoRoot -CodexHome $liveHome
$reviewConfigPath = $reviewedConfigContract.ReviewPath
$liveConfigPath = $reviewedConfigContract.LivePath
$reviewedConfigState = Get-ReviewedConfigState -ReviewPath $reviewConfigPath -RetirementPath $reviewedConfigContract.RetirementPath -LivePath $liveConfigPath

$retiredStates = @(
    foreach ($item in $retiredItems) {
        $exists = Test-Path -LiteralPath $item.LivePath
        $receiptArtifact = Get-PortableReceiptArtifact -Receipt $currentReceipt -Target $item.LivePath
        $owned = $exists -and
            $null -ne $receiptArtifact -and
            [string]$receiptArtifact.state -eq "present" -and
            (Test-PortableFingerprintMatches -Expected $receiptArtifact.fingerprint -Path $item.LivePath)
        [pscustomobject]@{
            Item = $item
            Exists = $exists
            Owned = $owned
            Foreign = ($exists -and -not $owned)
        }
    }
)

$foreignStates = @($retiredStates | Where-Object { $_.Foreign })
$blockedForeignStates = @(
    if (-not $Adopt) {
        $foreignStates
    }
)
$blockedConfigStates = @($reviewedConfigState.blocked)
$retiredRemovalStates = @($retiredStates | Where-Object { $_.Exists -and ($Adopt -or $_.Owned) })
Write-Host "repo: $repoRoot"
Write-Host "codex: $liveHome"
Write-Host "agents: $agentsHome"
Write-Host "claude: $claudeHome"
Write-Host ""

if (-not $Apply) {
    Write-Host "review mode: no files will be changed"
    Write-Host "planned reviewed config changes:"
    if (-not [bool]$reviewedConfigState.changed) {
        Write-Host "  none"
    }
    else {
        foreach ($change in @($reviewedConfigState.changes)) {
            Write-Host "  $($change.path): $($change.actual) -> $($change.expected)"
        }
    }
    if ($blockedConfigStates.Count -gt 0) {
        Write-Host ""
        Write-Host "blocked retired config entries:"
        foreach ($change in $blockedConfigStates) {
            Write-Host "  $($change.path): $($change.actual), prior expected $($change.expected)"
        }
    }

    if ($retiredRemovalStates.Count -gt 0) {
        Write-Host ""
        Write-Host "planned retired removals:"
        foreach ($state in $retiredRemovalStates) {
            Write-Host "  $($state.Item.LivePath)"
        }
    }

    if ($foreignStates.Count -gt 0) {
        Write-Host ""
        Write-Host "foreign targets:"
        foreach ($state in $foreignStates) {
            Write-Host "  $($state.Item.LivePath)"
        }
        if (-not $Adopt) {
            Write-Host "rerun with -Adopt to authorize replacing or removing these targets"
        }
    }

    Write-Host ""
    Write-Host "reviewed config: $($reviewedConfigState.changed_count)"
    Write-Host "retired: $($retiredRemovalStates.Count)"
    Write-Host "foreign: $($foreignStates.Count)"
    Write-Host "run with -Apply to execute the reviewed reset"
    if (-not $SkipPluginRetirement) {
        Write-Host ""
        & (Join-Path $PSScriptRoot "retire-plugins.ps1") -CodexHome $liveHome
    }
    exit 0
}

if ($blockedForeignStates.Count -gt 0) {
    Write-Host "foreign targets require explicit adoption:"
    foreach ($state in $blockedForeignStates) {
        Write-Host "  $($state.Item.LivePath)"
    }
    throw "rerun with -Adopt to replace or remove foreign targets"
}
if ($blockedConfigStates.Count -gt 0) {
    Write-Host "retired config entries changed from their prior reviewed values:"
    foreach ($change in $blockedConfigStates) {
        Write-Host "  $($change.path): $($change.actual), prior expected $($change.expected)"
    }
    throw "changed retired config entries require manual resolution"
}

if (-not $SkipPluginRetirement) {
    & (Join-Path $PSScriptRoot "retire-plugins.ps1") -CodexHome $liveHome -Apply -RequireAbsent
    if ($LASTEXITCODE -ne 0) {
        throw "retired plugin cleanup failed"
    }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoots = @{}
$changes = New-Object System.Collections.Generic.List[object]

function Get-ItemBackupRoot {
    param([string]$LiveRoot)

    if ($backupRoots.ContainsKey($LiveRoot)) {
        return $backupRoots[$LiveRoot]
    }

    $root = Join-Path $LiveRoot "portable-backups\$stamp"
    New-Item -ItemType Directory -Force $root | Out-Null
    $backupRoots[$LiveRoot] = $root
    return $root
}

foreach ($state in $retiredRemovalStates) {
    $item = $state.Item
    $itemBackupRoot = Get-ItemBackupRoot -LiveRoot $item.LiveRoot
    $backupPath = Get-ItemBackupPath -Item $item -BackupRoot $itemBackupRoot
    Backup-LiveItem -LivePath $item.LivePath -BackupRoot $itemBackupRoot -LiveRoot $item.LiveRoot -BackupScope $item.BackupScope -Type $item.Type
    Remove-Item -LiteralPath $item.LivePath -Recurse -Force
    $changes.Add([pscustomobject]@{
        operation = "retire"
        target = $item.LivePath
        type = $item.Type
        live_root = $item.LiveRoot
        previous_state = "backup"
        backup_path = $backupPath
        after = Get-PortablePathFingerprint -Path $item.LivePath
    })
    Write-Host "removed retired: $($item.LivePath)"
}

if ([bool]$reviewedConfigState.changed) {
    $configItem = [pscustomobject]@{
        LivePath = $liveConfigPath
        LiveRoot = $liveHome
        BackupScope = "codex"
        Type = "file"
    }
    $previousState = "missing"
    $backupPath = $null
    if ([bool]$reviewedConfigState.live_exists) {
        $configBackupRoot = Get-ItemBackupRoot -LiveRoot $liveHome
        $backupPath = Get-ItemBackupPath -Item $configItem -BackupRoot $configBackupRoot
        Backup-LiveItem -LivePath $liveConfigPath -BackupRoot $configBackupRoot -LiveRoot $liveHome -BackupScope "codex" -Type "file"
        $previousState = "backup"
    }
    Write-ReviewedConfigAtomically -Path $liveConfigPath -Text ([string]$reviewedConfigState.merged_text)
    $changes.Add([pscustomobject]@{
        operation = "config-overlay"
        target = $liveConfigPath
        type = "config-overlay"
        live_root = $liveHome
        previous_state = $previousState
        backup_path = $backupPath
        after = Get-PortablePathFingerprint -Path $liveConfigPath
    })
    Write-Host "reviewed config updated: $liveConfigPath ($($reviewedConfigState.changed_count) settings)"
}
else {
    Write-Host "portable config unchanged: $liveConfigPath"
}

$targetSetChanged = -not (Test-ReceiptTargetSetEqual -Receipt $currentReceipt -RetiredItems $retiredItems)
$provenanceChanged = $null -eq $currentReceipt -or
    [string]$currentReceipt.source_ref -ne [string]$resolvedSourceRef -or
    [string]$currentReceipt.source_commit -ne [string]$resolvedSourceCommit
$receiptNeeded = $changes.Count -gt 0 -or $targetSetChanged -or $provenanceChanged
$receiptPath = $null

if ($receiptNeeded) {
    $artifacts = @(
        foreach ($item in $retiredItems) {
            [ordered]@{
                source = $null
                target = $item.LivePath
                type = $item.Type
                state = "retired"
                ownership = "compass"
                fingerprint = Get-PortablePathFingerprint -Path $item.LivePath
            }
        }
    )
    $backupRootRecords = @(
        foreach ($entry in $backupRoots.GetEnumerator() | Sort-Object Name) {
            [ordered]@{
                live_root = $entry.Key
                backup_root = $entry.Value
            }
        }
    )
    $receipt = [ordered]@{
        schema_version = 1
        id = "install-$((Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ'))"
        installed_at = (Get-Date).ToUniversalTime().ToString("o")
        source_ref = $resolvedSourceRef
        source_commit = $resolvedSourceCommit
        previous_receipt_id = if ($currentReceipt) { $currentReceipt.id } else { $null }
        targets = [ordered]@{
            codex_home = $liveHome
            agents_home = $agentsHome
            claude_home = $claudeHome
        }
        backup_roots = $backupRootRecords
        changes = @($changes.ToArray())
        artifacts = $artifacts
    }
    $receiptPath = Write-PortableReceipt -CodexHome $liveHome -Receipt $receipt
}

Write-Host ""
Write-Host "reviewed config: $($reviewedConfigState.changed_count)"
Write-Host "retired: $($retiredRemovalStates.Count)"
Write-Host "foreign: $($foreignStates.Count)"
if ($backupRoots.Count -gt 0) {
    Write-Host "backups: $($backupRoots.Values -join ', ')"
}
else {
    Write-Host "backups: none"
}
if ($receiptPath) {
    Write-Host "receipt: $receiptPath"
}
else {
    Write-Host "receipt: unchanged"
}
