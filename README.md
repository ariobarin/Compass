# Compass

Compass is an intentionally blank global Codex and Claude Code bundle.

The repository no longer carries agent frameworks, optional packs, frozen
sources, project templates, hosted applications, or generic machine utilities.
Git history preserves the former implementation without making it part of the
current product.

## Current State

Compass installs no global instructions, skills, agents, hooks, keybindings, or
reviewed config. New global behavior must earn that scope in a separately
reviewed change.

## Temporary Reset

`reset/v1/` safely retires files and config values installed by Compass before
the blank reset. It is a migration boundary, not the foundation of a new
framework.

Preview the reset:

```powershell
.\reset\v1\retire.ps1
```

Apply it:

```powershell
.\reset\v1\retire.ps1 -Apply
```

Verify that the former Compass targets are absent:

```powershell
.\reset\v1\verify.ps1 -RequireInSync
```

The reset preserves unrelated files, directories, config keys, comments, and
changed targets unless `-Adopt` explicitly authorizes their retirement. Runtime
state such as sessions, logs, caches, databases, browser state, and generated
plugin state remains outside Compass.

Run the focused checks with:

```powershell
.\reset\v1\test-all.ps1
```

After every relevant machine has completed and verified the reset, `reset/v1/`
can be removed.
