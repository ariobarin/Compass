# Compass

Compass is reviewed source for portable Codex and Claude Code instructions,
skills, and agents. The current bundle is intentionally blank.

It is an allowlist, not a runtime-home backup. Auth, sessions, logs, caches,
databases, browser state, generated plugins, and machine-only values stay local.

## Portable Sources

`manifests/portable-files.toml` selects the current bundle:

- `codex.files` installs files from `codex/` into the Codex home.
- `codex.dirs` installs directories such as `codex/agents/`.
- `agents.skills` installs `codex/skills/<name>/` into `$HOME/.agents/skills`.
- `claude.files`, `claude.skills`, and `claude.agents` install direct Claude
  definitions.
- `claude.derived_skills` and `claude.derived_agents` reuse compatible Codex
  definitions.

`codex/AGENTS.md` remains as the permanent global instruction source, with no
active instructions. Skill and agent collections are empty until a reviewed
change adds a source and its manifest entry.

## Commands

Preview the current bundle:

```powershell
.\scripts\install.ps1
```

Install it:

```powershell
.\scripts\install.ps1 -Apply
```

Verify installed targets:

```powershell
.\scripts\verify-live.ps1 -RequireInSync
```

Run the portable test suite:

```powershell
.\scripts\test-all.ps1
```

Install backs up a selected target before replacing it. It does not remove or
inspect unlisted runtime state. Git contains the configuration history, so
Compass carries no retirement or backwards-compatibility database.
