# Repository Guidance

Compass is the blank baseline for global Codex and Claude Code configuration.
Keep it empty until an explicitly approved capability independently earns
global scope.

## Boundaries

- `reset/v1/` is a temporary migration for former Compass-owned targets.
- Project behavior belongs in the project that uses it.
- Hosted apps, reusable utilities, templates, source archives, and optional
  packs belong in separate repositories.
- Git history preserves retired implementation. Do not copy it back into main
  as an archive.
- Keep auth, sessions, logs, caches, databases, browser state, generated plugin
  state, and machine-only values untracked.

Retire only receipt-owned targets whose current fingerprints still match.
Preserve unrelated files, config keys, comments, and changed targets unless the
user explicitly authorizes adoption.

Use a focused pull request as the review unit. Run `git diff --check` and
`.\reset\v1\test-all.ps1` before committing.
