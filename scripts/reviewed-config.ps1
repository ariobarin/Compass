Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-ReviewedConfigContract {
    param(
        [Parameter(Mandatory)]
        [string]$RepoRoot,
        [Parameter(Mandatory)]
        [string]$CodexHome
    )

    $manifest = (Get-PortableGeneratedData).manifest
    $config = Get-PortableJsonProperty -Object $manifest -Name "config"
    $reviewFiles = @(Get-PortableJsonProperty -Object $config -Name "review_files")
    if ($reviewFiles.Count -gt 1) {
        throw "portable manifest supports at most one active reviewed config file"
    }

    return [pscustomobject]@{
        ReviewPath = if ($reviewFiles.Count -eq 1) {
            Join-Path (Join-Path $RepoRoot "codex") ([string]$reviewFiles[0])
        }
        else {
            $null
        }
        RetirementPath = Join-Path $RepoRoot "manifests\portable-retirements.json"
        LivePath = Join-Path $CodexHome "config.toml"
    }
}

function Get-ReviewedConfigState {
    param(
        [AllowNull()]
        [string]$ReviewPath,
        [Parameter(Mandatory)]
        [string]$RetirementPath,
        [Parameter(Mandatory)]
        [string]$LivePath
    )

    $toolPath = Join-Path $PSScriptRoot "reviewed-config.py"
    if (-not (Test-Path -LiteralPath $toolPath -PathType Leaf)) {
        throw "missing reviewed config helper: $toolPath"
    }

    $runner = Get-PortablePythonRunner
    $arguments = @($runner.Prefix) + @($toolPath)
    if ($ReviewPath) {
        $arguments += @("--reviewed-config", $ReviewPath)
    }
    $arguments += @(
        "--retirement-manifest", $RetirementPath,
        "--live-config", $LivePath
    )
    $previousPythonIoEncoding = $env:PYTHONIOENCODING
    $previousOutputEncoding = [Console]::OutputEncoding

    try {
        $env:PYTHONIOENCODING = "utf-8"
        [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
        $output = @(& $runner.Command @arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $env:PYTHONIOENCODING = $previousPythonIoEncoding
        [Console]::OutputEncoding = $previousOutputEncoding
    }

    if ($exitCode -ne 0) {
        $message = @($output | ForEach-Object { $_.ToString() }) -join "`n"
        throw "reviewed config helper failed: $message"
    }

    try {
        $state = (@($output | ForEach-Object { $_.ToString() }) -join "`n") | ConvertFrom-Json
    }
    catch {
        throw "reviewed config helper returned invalid JSON: $($_.Exception.Message)"
    }

    if ($state.schema_version -ne 1) {
        throw "unsupported reviewed config state schema version"
    }
    return $state
}

function Write-ReviewedConfigAtomically {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Text
    )

    New-DirectoryForFile -Path $Path
    $directory = Split-Path -Parent $Path
    $name = Split-Path -Leaf $Path
    $tempPath = Join-Path $directory ".$name.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        [System.IO.File]::WriteAllText($tempPath, $Text, [System.Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $tempPath -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $tempPath) {
            Remove-Item -LiteralPath $tempPath -Force
        }
    }
}

function Get-ReviewedConfigProblemStrings {
    param(
        [Parameter(Mandatory)]
        [object]$State
    )

    foreach ($change in @($State.changes)) {
        if ($change.kind -eq "retire") {
            "retired config key still present: $($change.path) = $($change.actual)"
        }
        elseif ($change.kind -eq "missing") {
            "missing reviewed config key: $($change.path), expected $($change.expected)"
        }
        else {
            "reviewed config mismatch: $($change.path) = $($change.actual), expected $($change.expected)"
        }
    }
    foreach ($change in @($State.blocked)) {
        "retired config mismatch: $($change.path) = $($change.actual), prior expected $($change.expected)"
    }
}
