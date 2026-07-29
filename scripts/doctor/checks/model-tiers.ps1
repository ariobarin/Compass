$manifestPath = Join-Path $repoRoot "manifests\model-tiers.json"
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    $problems.Add("missing model-tiers manifest")
}
else {
    try {
        $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
        if ($manifest.schema_version -ne 1) {
            $problems.Add("unsupported model-tiers manifest schema")
        }

        $allowedEfforts = @("low", "medium", "high", "xhigh", "max")
        $tiers = @($manifest.tiers)
        $seenModels = New-Object System.Collections.Generic.List[string]
        foreach ($tier in $tiers) {
            if (-not $tier.model -or -not $tier.display_name -or -not $tier.effort) {
                $problems.Add("model-tiers manifest row is incomplete")
                continue
            }
            if ($seenModels -contains $tier.model) {
                $problems.Add("model-tiers manifest has duplicate model: $($tier.model)")
            }
            $seenModels.Add($tier.model)
            if ($allowedEfforts -notcontains $tier.effort) {
                $problems.Add("model-tiers manifest has invalid effort: $($tier.effort)")
            }
        }

        # The calibration doc must carry each tier row verbatim.
        $calibrationPath = Join-Path $repoRoot "local-docs\model-calibration.md"
        $calibration = Get-Content -Raw -LiteralPath $calibrationPath
        foreach ($tier in $tiers) {
            $row = "| $($tier.display_name) | ``$($tier.effort)`` |"
            if (-not $calibration.Contains($row)) {
                $problems.Add("model-calibration.md missing tier row: $row")
            }
        }

        # The blank portable route has no active reviewed model selection.
        $activeReviewFiles = @(Get-PortableManifestArray -Section "config" -Key "review_files")
        if ($activeReviewFiles.Count -ne 0) {
            $problems.Add("blank portable config must not select an active model tier")
        }
    }
    catch {
        $problems.Add("invalid model-tiers manifest: $($_.Exception.Message)")
    }
}
