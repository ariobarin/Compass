# Portable Config Workflow

Use this workflow to diff, install, snapshot, verify, or update the reviewed
Compass allowlist.

This is maintainer guidance. It is not installed into a Codex home, user-skill
home, or Claude home.

## Reviewed Sources

- Active bundle: `manifests/portable-files.toml`
- Retirement targets and prior config values:
  `manifests/portable-retirements.json`
- Active skill ownership and provenance: `manifests/skill-sources.json`
- Pre-reset inventory: `local-docs/2026-07-29-pre-reset-catalog.md`

The active bundle is intentionally blank. Carried packs, project-local files,
apps, maintenance workflows, and external runtime state remain outside the
global install route.

## Preview First

```powershell
.\scripts\diff-live.ps1
.\scripts\install.ps1
.\scripts\snapshot.ps1
```

Without `-Apply`, install and snapshot report exact planned changes. Inspect the
retirement and config-removal plan before mutation.

## Validate

```powershell
.\scripts\doctor.ps1
.\scripts\verify-live.ps1 -SkipCodexCommand
```

Use `-RequireInSync` when drift should fail the command. Doctor validates source
boundaries, manifests, the empty active bundle, retirement policy, carried
packs, and required files.

## Apply

```powershell
.\scripts\install.ps1 -Apply
```

The installer:

- copies nothing while the active bundle is empty;
- removes only receipt-owned retirement targets whose current file, directory,
  and reparse identity still matches the receipt, unless `-Adopt` is explicit;
- blocks changed or foreign retirement targets by default;
- backs up and receipts every removal;
- removes retired config entries only when they still equal their prior
  reviewed values;
- preserves unrelated live files, config keys, and comments.

## Update

```powershell
.\scripts\update-live.ps1
.\scripts\update-live.ps1 -Ref <tag-or-commit>
```

Branch refs remain fast-forward only. Tags and commit SHAs resolve to an exact
detached commit before installation.

## Snapshot

```powershell
.\scripts\snapshot.ps1 -Apply
```

Snapshot only the current allowlist. With the authored blank manifest it has no
global sources to capture. Runtime-generated state, secrets, sessions, caches,
local overrides, and plugin caches remain local.

## Path Resolution

Scripts use:

- `-CodexHome`, then `$env:CODEX_HOME`, then `%USERPROFILE%\.codex`;
- `-AgentsHome`, then `$HOME\.agents`;
- `-ClaudeHome`, then `$HOME\.claude`.

## Ownership Changes

A rename, move, or retirement updates in one reviewed change:

- source path;
- install manifest;
- skill-source catalog;
- derivation transform;
- retired live paths;
- policy contracts and required-file checks;
- install round-trip tests;
- nearby documentation and MCP catalog expectations.

The active global route remains blank. Any add-back, including a Codex or Claude
global, skill, agent, hook, or reviewed config entry, requires explicit user
approval and a separate reviewed change that updates the full ownership and
verification set above.
