# Repository Guidance

Compass is the lean source of truth for portable Codex and Claude Code
configuration. An empty active allowlist means no global definitions are
currently approved. It does not make the installer, verifier, ownership
receipts, or source layout disposable.

## Boundaries

- Global instructions, skills, agents, and reviewed configuration belong in
  the source paths named by `manifests/portable-files.toml`.
- Project-specific behavior belongs in the project that uses it.
- Hosted apps, optional packs, generic utilities, templates, and source
  archives belong in separate repositories.
- Keep auth, sessions, logs, caches, databases, browser state, generated plugin
  state, and machine-only values untracked.

Treat every manifest collection, including an empty collection, as exact.
Adding or removing a portable target updates its source, manifest entry,
retirement entry when applicable, and round-trip coverage together.

Retire or replace only receipt-owned targets whose current fingerprints still
match. Preserve unrelated files, config keys, comments, and changed targets
unless the user explicitly authorizes adoption.

Use a focused pull request as the review unit. Run `git diff --check`,
`.\scripts\test-all.ps1`, and the Windows PowerShell 5.1 form of the same suite
before committing.
