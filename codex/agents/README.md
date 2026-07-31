# Portable Subagents

Add each Codex subagent as `codex/agents/<name>.toml`, then add its name to
`codex.agents` in `manifests/portable-files.toml`.

Compass installs selected subagents into the Codex home. A subagent may also be
listed under `claude.derived_agents` when its behavior can be derived safely.
