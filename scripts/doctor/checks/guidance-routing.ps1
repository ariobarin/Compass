$manifestPath = Join-Path $repoRoot "manifests\guidance-routing.json"
$validatorPath = Join-Path $repoRoot "scripts\context-routing.py"
$pythonRunner = @(Get-DoctorPythonRunner)

if ($pythonRunner.Count -eq 0) {
    $problems.Add("no runnable Python found for guidance routing validation")
}
elseif (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    $problems.Add("missing guidance routing manifest: $manifestPath")
}
elseif (-not (Test-Path -LiteralPath $validatorPath -PathType Leaf)) {
    $problems.Add("missing guidance routing validator: $validatorPath")
}
else {
    $result = Invoke-DoctorPythonScript `
        -Runner $pythonRunner `
        -ScriptPath $validatorPath `
        -InputText "" `
        -Arguments @("check", "--root", $repoRoot, "--manifest", $manifestPath)

    if ($result.ExitCode -ne 0) {
        $messages = @($result.Output -split "`r?`n" | Where-Object { $_.Trim() })
        if ($messages.Count -eq 0) {
            $problems.Add("guidance routing validation failed without output")
        }
        else {
            foreach ($message in $messages) {
                $problems.Add($message)
            }
        }
    }
}
