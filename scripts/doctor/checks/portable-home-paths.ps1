$manifest = (Get-PortableGeneratedData).manifest

function Get-PortableManifestString {
    param($Manifest, $Section, $Key)
    $sectionValue = Get-PortableJsonProperty -Object $Manifest -Name $Section
    return Get-PortableJsonProperty -Object $sectionValue -Name $Key
}

$expected = @{
    "codex.home" = '$CODEX_HOME or %USERPROFILE%\.codex'
    "agents.home" = '$HOME\.agents'
    "agents.skills_dir" = '$HOME\.agents\skills'
    "claude.home" = '$HOME\.claude'
    "claude.skills_dir" = '$HOME\.claude\skills'
    "claude.agents_dir" = '$HOME\.claude\agents'
}

foreach ($entry in $expected.GetEnumerator()) {
    $parts = $entry.Key.Split(".")
    $actual = Get-PortableManifestString $manifest $parts[0] $parts[1]
    if ($actual -cne $entry.Value) {
        $problems.Add("portable manifest $($entry.Key) documents '$actual' but expected '$($entry.Value)'")
    }
}

$portableWorkflow = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "workflows\portable-config.md")
$readme = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "README.md")
foreach ($text in @(
    '- `-CodexHome`, then `$env:CODEX_HOME`, then `%USERPROFILE%\.codex`;',
    '- `-AgentsHome`, then `$HOME\.agents`;',
    '- `-ClaudeHome`, then `$HOME\.claude`.'
)) {
    if (-not $portableWorkflow.Contains($text)) {
        $problems.Add("portable-config home resolution is missing or stale: $text")
    }
}
foreach ($text in @('`-CodexHome`', '`-AgentsHome`', '`-ClaudeHome`')) {
    if (-not $readme.Contains($text)) {
        $problems.Add("README home resolution is missing: $text")
    }
}
