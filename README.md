# Compass

Compass is reviewed source for portable Codex and Claude Code configuration.
It keeps the mechanism for predefined global instructions, skills, agents, and
configuration while leaving the active bundle empty until those definitions
are intentionally rebuilt.

The repository is an allowlist, not a backup of runtime homes. Authentication,
sessions, logs, caches, databases, browser state, generated plugin state, and
machine-only values stay local.

## Portable Sources

`manifests/portable-files.toml` is the source-of-truth allowlist:

- `codex.files` installs files from `codex/`, including `AGENTS.md`.
- `codex.dirs` installs directories such as `codex/agents/`.
- `agents.skills` installs `codex/skills/<name>/` into the user skill home.
- `claude.files` installs files from `claude/`, including `CLAUDE.md`.
- `claude.skills` and `claude.agents` install direct Claude definitions.
- `claude.derived_skills` and `claude.derived_agents` reuse reviewed Codex
  definitions when the formats can be derived safely.
- `config.review_files` accepts at most one Codex TOML overlay. Reviewed keys
  merge into live `config.toml` without replacing unrelated machine settings.

The arrays are currently empty. Adding a source file alone does not install it.
The matching manifest entry is the explicit global-scope decision.

## Commands

Preview an installation:

```powershell
.\scripts\install.ps1
```

Apply the reviewed bundle:

```powershell
.\scripts\install.ps1 -Apply
```

Verify live targets:

```powershell
.\scripts\verify-live.ps1 -RequireInSync
```

Inspect exact file differences or refresh allowlisted source from live targets:

```powershell
.\scripts\diff-live.ps1
.\scripts\snapshot.ps1
.\scripts\snapshot.ps1 -Apply
```

Run the complete portable test suite:

```powershell
.\scripts\test-all.ps1
```

## Ownership And Removal

Install previews by default. Applied changes are backed up and recorded in a
receipt. Compass replaces or removes a live target only when the current
receipt owns its exact fingerprint. A changed or foreign target is preserved
unless `-Adopt` explicitly authorizes Compass to take ownership.

`manifests/portable-retirements.json` and
`manifests/retired-plugins.json` remain as migration inputs for the prior
Compass reset. They do not prevent new reviewed definitions from being added,
but a reintroduced target must also leave the retirement list.

## Deliberately Excluded

Compass no longer contains hosted applications, frozen third-party source
copies, optional domain packs, project templates, orchestration ledgers,
restart recovery, or generic agent-workflow documentation. Those are separate
products or project concerns, not portable configuration infrastructure.
