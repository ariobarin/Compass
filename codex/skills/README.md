# Portable Skills

Add each portable skill under `codex/skills/<name>/`, then add its name to
`agents.skills` in `manifests/portable-files.toml`.

Compass installs selected skills into `$HOME/.agents/skills`. A skill may also
be listed under `claude.derived_skills` when its runtime behavior is shared.
