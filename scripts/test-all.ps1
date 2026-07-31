[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\common.ps1"

function Invoke-PowerShellTest {
    param([string]$Path)

    $powerShellPath = (Get-Process -Id $PID).Path
    $arguments = @("-NoProfile")
    if ($env:OS -eq "Windows_NT") {
        $arguments += @("-ExecutionPolicy", "Bypass")
    }
    $arguments += @("-File", $Path)
    & $powerShellPath @arguments
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$runner = Get-PortablePythonRunner
& $runner.Command @($runner.Prefix) "$PSScriptRoot\test-reviewed-config.py"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Invoke-PowerShellTest -Path "$PSScriptRoot\test-retire-plugins.ps1"
Invoke-PowerShellTest -Path "$PSScriptRoot\test-portable-bundle.ps1"
Invoke-PowerShellTest -Path "$PSScriptRoot\test-install-roundtrip.ps1"

Write-Host "portable tests: ok"
