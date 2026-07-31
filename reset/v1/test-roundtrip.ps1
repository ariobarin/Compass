[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$baseCommit = "349b94acad6175561e56304704856c5632db6b6c"
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "compass-blank-roundtrip-$([guid]::NewGuid().ToString('N'))"
$codexHome = Join-Path $testRoot "codex"
$agentsHome = Join-Path $testRoot "agents"
$claudeHome = Join-Path $testRoot "claude"
$oldSourceRoot = Join-Path $testRoot "old-source"
$powerShellPath = (Get-Process -Id $PID).Path

. "$PSScriptRoot\common.ps1"
. "$PSScriptRoot\receipt-common.ps1"

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

function Write-Utf8Text {
    param([string]$Path, [string]$Text)

    New-Item -ItemType Directory -Force (Split-Path -Parent $Path) | Out-Null
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Assert-PathPresent {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "expected path: $Path"
    }
}

function Assert-PathAbsent {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        throw "expected absent path: $Path"
    }
}

function Get-RootsState {
    return @(
        Get-PortablePathFingerprint -Path $codexHome
        Get-PortablePathFingerprint -Path $agentsHome
        Get-PortablePathFingerprint -Path $claudeHome
    ) | ConvertTo-Json -Compress -Depth 12
}

try {
    New-Item -ItemType Directory -Force $codexHome, $agentsHome, $claudeHome, $oldSourceRoot | Out-Null

    $archivePath = Join-Path $testRoot "base.zip"
    & git -c "safe.directory=$repoRoot" -C $repoRoot archive --format=zip --output=$archivePath $baseCommit
    if ($LASTEXITCODE -ne 0) {
        throw "could not archive base $baseCommit"
    }
    Expand-Archive -LiteralPath $archivePath -DestinationPath $oldSourceRoot

    $homeArguments = @(
        "-CodexHome", $codexHome,
        "-AgentsHome", $agentsHome,
        "-ClaudeHome", $claudeHome
    )
    $resetArguments = @($homeArguments) + "-SkipPluginRetirement"
    $legacyInstallArguments = @($resetArguments) + "-SkipSkillRuntimeSetup"
    $blankInstall = Join-Path $PSScriptRoot "retire.ps1"
    $blankVerify = Join-Path $PSScriptRoot "verify.ps1"
    $oldInstall = Join-Path $oldSourceRoot "scripts\install.ps1"
    $oldVerify = Join-Path $oldSourceRoot "scripts\verify-live.ps1"

    $configPath = Join-Path $codexHome "config.toml"
    Write-Utf8Text -Path $configPath -Text @"
# unrelated root comment
model = "gpt-5.6-sol"
model_reasoning_effort = "high"
model_context_window = 272000
model_auto_compact_token_limit = 233000
model_auto_compact_token_limit_scope = "total"
personality = "pragmatic"
sandbox_mode = "danger-full-access"
approval_policy = "never"
custom_root_value = "keep"

[agents]
max_depth = 2
custom_agent_value = "keep"

[windows]
sandbox = "elevated"

[notice]
hide_full_access_warning = true

[features]
memories = true
goals = true
prevent_idle_sleep = true

[features.multi_agent_v2]
hide_spawn_agent_metadata = false
tool_namespace = "agents"

[mcp_servers.example]
command = "machine-local-command"
"@

    $sentinels = @(
        (Join-Path $codexHome "foreign\sentinel.txt"),
        (Join-Path $agentsHome "skills\foreign-skill\sentinel.txt"),
        (Join-Path $claudeHome "foreign\sentinel.txt")
    )
    foreach ($sentinel in $sentinels) {
        Write-Utf8Text -Path $sentinel -Text "unrelated sentinel`n"
    }

    $oldConfigTool = Join-Path $oldSourceRoot "scripts\reviewed-config.py"
    $oldReviewFile = Join-Path $oldSourceRoot "codex\config.review.toml"
    $runner = Get-PortablePythonRunner
    $oldConfigOutput = @(& $runner.Command @($runner.Prefix) $oldConfigTool --reviewed-config $oldReviewFile --live-config $configPath)
    if ($LASTEXITCODE -ne 0) {
        throw "old-source config restoration failed"
    }
    $oldConfigState = ($oldConfigOutput -join "`n") | ConvertFrom-Json
    Write-Utf8Text -Path $configPath -Text ([string]$oldConfigState.merged_text)

    [void](Invoke-TestScript -Path $oldInstall -Arguments (@(
        "-Apply",
        "-Adopt",
        "-SourceRef", "base-fixture-$baseCommit"
    ) + $legacyInstallArguments))
    [void](Invoke-TestScript -Path $oldVerify -Arguments (@(
        "-SkipCodexCommand",
        "-SkipPluginCheck",
        "-RequireInSync"
    ) + $homeArguments))

    $sentinelHashes = @{}
    foreach ($sentinel in $sentinels) {
        $sentinelHashes[$sentinel] = (Get-FileHash -Algorithm SHA256 -LiteralPath $sentinel).Hash
    }

    $foreignEmptyDirectory = Join-Path $agentsHome "skills\compass\foreign-empty"
    New-Item -ItemType Directory -Force $foreignEmptyDirectory | Out-Null
    [void](Invoke-TestScript -Path $blankInstall -Arguments (@("-Apply") + $resetArguments) -ExpectedExitCode 1)
    Assert-PathPresent -Path $foreignEmptyDirectory
    Assert-PathPresent -Path (Join-Path $agentsHome "skills\compass\SKILL.md")
    Remove-Item -LiteralPath $foreignEmptyDirectory -Force

    if ($env:OS -eq "Windows_NT") {
        $ownedDirectory = Join-Path $agentsHome "skills\compass"
        $junctionFixture = Join-Path $testRoot "junction-fixture"
        Copy-Item -LiteralPath $ownedDirectory -Destination $junctionFixture -Recurse
        $externalSkill = Join-Path $junctionFixture "SKILL.md"
        $externalSkillHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $externalSkill).Hash
        Remove-Item -LiteralPath $ownedDirectory -Recurse -Force

        try {
            try {
                New-Item -ItemType Junction -Path $ownedDirectory -Target $junctionFixture -ErrorAction Stop | Out-Null
            }
            catch {
                throw "required junction regression could not create junction: $($_.Exception.Message)"
            }

            $junctionItem = Get-Item -LiteralPath $ownedDirectory -Force
            if (($junctionItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) {
                throw "junction regression did not create a reparse point"
            }

            [void](Invoke-TestScript -Path $blankInstall -Arguments (@("-Apply") + $resetArguments) -ExpectedExitCode 1)
            Assert-PathPresent -Path $ownedDirectory
            Assert-PathPresent -Path $externalSkill
            $junctionItem = Get-Item -LiteralPath $ownedDirectory -Force
            if (($junctionItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) {
                throw "blocked blank retirement removed the junction"
            }
            if ((Get-FileHash -Algorithm SHA256 -LiteralPath $externalSkill).Hash -ne $externalSkillHash) {
                throw "blocked blank retirement changed the junction target"
            }
        }
        finally {
            if (Test-Path -LiteralPath $ownedDirectory) {
                $junctionItem = Get-Item -LiteralPath $ownedDirectory -Force
                if (($junctionItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                    [System.IO.Directory]::Delete($ownedDirectory)
                }
            }
            if (Test-Path -LiteralPath $junctionFixture) {
                Remove-Item -LiteralPath $junctionFixture -Recurse -Force
            }
        }

        [void](Invoke-TestScript -Path $oldInstall -Arguments (@("-Apply") + $legacyInstallArguments))
        Assert-PathPresent -Path (Join-Path $ownedDirectory "SKILL.md")
    }

    $ownedDrift = Join-Path $agentsHome "skills\compass\SKILL.md"
    Add-Content -LiteralPath $ownedDrift -Value "# changed after receipt"
    [void](Invoke-TestScript -Path $blankInstall -Arguments (@("-Apply") + $resetArguments) -ExpectedExitCode 1)
    Assert-PathPresent -Path $ownedDrift
    [void](Invoke-TestScript -Path $oldInstall -Arguments (@("-Apply") + $legacyInstallArguments))

    $beforePreview = Get-RootsState
    $previewOutput = @(Invoke-TestScript -Path $blankInstall -Arguments $resetArguments)
    if ($previewOutput -notcontains "review mode: no files will be changed") {
        throw "blank preview did not identify review mode"
    }
    if ((Get-RootsState) -ne $beforePreview) {
        throw "blank preview mutated scratch homes"
    }

    [void](Invoke-TestScript -Path $blankInstall -Arguments (@("-Apply") + $resetArguments))
    [void](Invoke-TestScript -Path $blankVerify -Arguments (@(
        "-SkipPluginCheck",
        "-RequireInSync"
    ) + $homeArguments))

    foreach ($retired in @(Get-RetiredPortableFileMap -CodexHome $codexHome -AgentsHome $agentsHome -ClaudeHome $claudeHome)) {
        Assert-PathAbsent -Path $retired.LivePath
    }

    foreach ($sentinel in $sentinels) {
        Assert-PathPresent -Path $sentinel
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sentinel).Hash -ne $sentinelHashes[$sentinel]) {
            throw "unrelated sentinel changed: $sentinel"
        }
    }

    $blankConfig = Get-Content -Raw -LiteralPath $configPath
    foreach ($preserved in @(
        "# unrelated root comment",
        'custom_root_value = "keep"',
        'custom_agent_value = "keep"',
        "[mcp_servers.example]",
        'command = "machine-local-command"'
    )) {
        if (-not $blankConfig.Contains($preserved)) {
            throw "blank config lost unrelated content: $preserved"
        }
    }
    foreach ($removed in @(
        'model = "gpt-5.6-sol"',
        'max_depth = 2',
        'tool_namespace = "agents"'
    )) {
        if ($blankConfig.Contains($removed)) {
            throw "blank config retained reviewed value: $removed"
        }
    }

    foreach ($root in @($codexHome, $agentsHome, $claudeHome)) {
        Assert-PathPresent -Path (Join-Path $root "portable-backups")
    }
    $currentReceiptPath = Join-Path $codexHome "portable-receipts\current.json"
    Assert-PathPresent -Path $currentReceiptPath
    $blankReceipt = Get-Content -Raw -LiteralPath $currentReceiptPath | ConvertFrom-Json
    if (@($blankReceipt.changes | Where-Object { $_.operation -eq "retire" }).Count -eq 0) {
        throw "blank receipt recorded no retirement changes"
    }
    if (@($blankReceipt.changes | Where-Object { $_.target -eq $configPath }).Count -ne 1) {
        throw "blank receipt did not record config retirement"
    }

    $receiptCountBefore = @(Get-ChildItem -LiteralPath (Join-Path $codexHome "portable-receipts") -Filter "install-*.json" -File).Count
    $secondApply = @(Invoke-TestScript -Path $blankInstall -Arguments (@("-Apply") + $resetArguments))
    if ($secondApply -notcontains "backups: none") {
        throw "second blank apply created backups"
    }
    if ($secondApply -notcontains "receipt: unchanged") {
        throw "second blank apply rewrote receipt"
    }
    $receiptCountAfter = @(Get-ChildItem -LiteralPath (Join-Path $codexHome "portable-receipts") -Filter "install-*.json" -File).Count
    if ($receiptCountAfter -ne $receiptCountBefore) {
        throw "second blank apply created a receipt"
    }

    $oldConfigOutput = @(& $runner.Command @($runner.Prefix) $oldConfigTool --reviewed-config $oldReviewFile --live-config $configPath)
    if ($LASTEXITCODE -ne 0) {
        throw "old-source config restoration failed"
    }
    $oldConfigState = ($oldConfigOutput -join "`n") | ConvertFrom-Json
    Write-Utf8Text -Path $configPath -Text ([string]$oldConfigState.merged_text)

    [void](Invoke-TestScript -Path $oldInstall -Arguments (@(
        "-Apply",
        "-SourceRef", "base-fixture-$baseCommit"
    ) + $legacyInstallArguments))
    [void](Invoke-TestScript -Path $oldVerify -Arguments (@(
        "-SkipCodexCommand",
        "-SkipPluginCheck",
        "-RequireInSync"
    ) + $homeArguments))
    Assert-PathPresent -Path (Join-Path $codexHome "AGENTS.md")
    Assert-PathPresent -Path (Join-Path $agentsHome "skills\compass\SKILL.md")
    Assert-PathPresent -Path (Join-Path $claudeHome "CLAUDE.md")
    Assert-PathPresent -Path (Join-Path $claudeHome "agents\reviewer.md")
    foreach ($sentinel in $sentinels) {
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sentinel).Hash -ne $sentinelHashes[$sentinel]) {
            throw "old-source restoration changed unrelated sentinel: $sentinel"
        }
    }

    Write-Host "blank install round trip: ok"
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
