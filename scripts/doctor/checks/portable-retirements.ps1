$manifestPath = Join-Path $repoRoot "manifests\portable-retirements.json"
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    $problems.Add("missing portable retirement manifest")
}
else {
    try {
        $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
        if ($manifest.schema_version -ne 1) {
            $problems.Add("unsupported portable retirement manifest schema")
        }
        if ($manifest.base_commit -ne "349b94acad6175561e56304704856c5632db6b6c") {
            $problems.Add("portable retirement manifest base commit changed")
        }

        $identities = New-Object System.Collections.Generic.List[string]
        foreach ($entry in @($manifest.items)) {
            if ($entry.scope -notin @("codex", "agents", "claude")) {
                $problems.Add("portable retirement has invalid scope: $($entry.scope)")
            }
            if ($entry.type -notin @("file", "dir")) {
                $problems.Add("portable retirement has invalid type: $($entry.type)")
            }
            if (-not $entry.path -or $entry.path -match '(^|[\\/])\.\.([\\/]|$)' -or [System.IO.Path]::IsPathRooted([string]$entry.path)) {
                $problems.Add("portable retirement has unsafe path: $($entry.path)")
            }
            $identities.Add("$($entry.scope):$($entry.path)")
        }
        if ($identities.Count -eq 0) {
            $problems.Add("portable retirement manifest requires items")
        }
        if (@($identities | Sort-Object -Unique).Count -ne $identities.Count) {
            $problems.Add("portable retirement manifest contains duplicate targets")
        }

        foreach ($required in @(
            "codex:AGENTS.md",
            "codex:hooks.json",
            "codex:keybindings.json",
            "codex:agents",
            "codex:hooks",
            "agents:skills/compass",
            "agents:skills/which-llm",
            "claude:CLAUDE.md",
            "claude:skills/compass",
            "claude:agents/reviewer.md"
        )) {
            if ($identities -notcontains $required) {
                $problems.Add("portable retirement manifest is missing base target: $required")
            }
        }

        $configPaths = @($manifest.config_entries | ForEach-Object { $_.path })
        if ($configPaths.Count -ne 16) {
            $problems.Add("portable retirement manifest requires 16 reviewed config entries")
        }
        if (@($configPaths | Sort-Object -Unique).Count -ne $configPaths.Count) {
            $problems.Add("portable retirement manifest contains duplicate config entries")
        }
    }
    catch {
        $problems.Add("invalid portable retirement manifest: $($_.Exception.Message)")
    }
}
