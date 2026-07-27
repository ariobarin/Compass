<#
.SYNOPSIS
Reports or traces the reviewed Compass guidance routing catalog.
#>
[CmdletBinding()]
param(
    [string]$Task,
    [string]$Phase,
    [string]$Mutation,
    [ValidateRange(1, 10)]
    [int]$Limit = 3,
    [switch]$Json,
    [switch]$Plain,
    [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
. "$PSScriptRoot\doctor\common.ps1"

if ($Json -and $Plain) {
    throw "choose either -Json or -Plain"
}
if ($Check -and ($Task -or $Phase -or $Mutation)) {
    throw "-Check does not accept task filters"
}
if (($Phase -or $Mutation) -and -not $Task) {
    throw "-Phase and -Mutation require -Task"
}

$runner = @(Get-DoctorPythonRunner)
if ($runner.Count -eq 0) {
    throw "no runnable Python found for context routing"
}

$action = if ($Check) { "check" } elseif ($Task) { "trace" } else { "status" }
$arguments = @($action, "--root", $repoRoot, "--limit", $Limit)
if ($Task) {
    $arguments += @("--task", $Task)
}
if ($Phase) {
    $arguments += @("--phase", $Phase)
}
if ($Mutation) {
    $arguments += @("--mutation", $Mutation)
}
if ($Json) {
    $arguments += "--json"
}
if ($Plain) {
    $arguments += "--plain"
}

$result = Invoke-DoctorPythonScript `
    -Runner $runner `
    -ScriptPath (Join-Path $PSScriptRoot "context-routing.py") `
    -InputText "" `
    -Arguments @($arguments | ForEach-Object { $_.ToString() })

if ($result.Output) {
    Write-Output $result.Output
}
exit $result.ExitCode
