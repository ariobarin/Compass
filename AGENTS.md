# Repository Guidance

Compass is the lean source of truth for portable Codex and Claude Code
configuration. The bundle contains reviewed Codex defaults and only explicitly
selected skills or agents.

## Philosophy

Compass defines durable outcomes and true boundaries. It leaves routine
judgment, execution paths, tool use, and self-checking to current models.

Add prompts, skills, agents, or configuration only for a demonstrated
current-model gap. Re-evaluate them after material model changes, and remove
scaffolding that duplicates or distorts native behavior. Use absolute rules
only for true invariants.

## Boundaries

- `codex/AGENTS.md` is the permanent global Codex instruction source. It may be
  empty, but the source path stays in Compass.
- `codex/config.toml` contains reviewed portable keys. Install overlays those
  keys without replacing unrelated live configuration.
- Portable skills belong under `codex/skills/<name>/` and are selected by
  `agents.skills` in `manifests/portable-files.json`.
- Portable Codex subagents belong under `codex/agents/<name>.toml` and are
  selected by `codex.agents`.
- Direct Claude files, skills, and agents belong under `claude/` and are
  selected by the corresponding `claude` manifest collection.
- Project-specific behavior belongs in the project that uses it.
- Auth, sessions, logs, caches, databases, browser state, generated plugin
  state, and machine-only values stay untracked.

The manifest describes only the current desired bundle. Do not add migration,
retirement, adoption, receipt, or compatibility machinery for prior layouts.
Install may replace a selected target after backing it up. It must not change
unlisted runtime state.

Use a focused pull request as the review unit. Run `git diff --check`,
`.\scripts\test-all.ps1`, and the Windows PowerShell 5.1 form of the same suite
before committing.
