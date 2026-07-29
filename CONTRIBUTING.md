# Contributing

Compass is reviewed source for a portable Codex setup. It is not a raw backup
of a live Codex home or user skill home, and contributions should preserve that
boundary.

Good changes make the setup easier to review, reinstall, explain, or verify.
They do not add private machine state, generated runtime state, or broad agent
behavior just because it happened to be useful once.

## Before A PR

- Read `README.md`, `philosophy.md`, `AGENTS.md`, and
  `local-docs/maintenance-learnings.md`.
- Keep the change narrow enough that a reviewer can see the portable boundary.
- Run `.\scripts\doctor.ps1`.
- If the change affects live install behavior, also run
  `.\scripts\verify-live.ps1 -SkipCodexCommand`.
- Use `.\scripts\committer.ps1 <subject> <paths>` to preview an exact-scope
  commit, then rerun it with `-Apply` before the subject after reviewing the
  selected paths.
- Leave auth, sessions, logs, caches, browser state, SQLite files, generated
  plugin caches, and local override files out of the PR.

## Scope

The authored Codex, user-skill, Claude, hook, and reviewed-config install route
is intentionally blank. Repo-maintainer guidance belongs in `AGENTS.md`,
`workflows/`, `local-docs/`, `manifests/`, or `scripts/`. Carried packs,
project templates, and frozen external sources stay repository-only.

Any global add-back requires explicit user approval and a separate reviewed
change. Do not recreate retired source paths as part of routine maintenance.

Use the narrowest surface that fits the change. A skill should teach a durable
role or capability. A workflow should capture a recurring repo process. A script
should handle a mechanical check. A manifest should define a boundary.

## Review Expectations

Prefer small PRs with clear motivation. In the title and body, name the
boundary, behavior, or risk the change improves. State what the change prunes,
distills, narrows, derives, or mechanizes. A net-new surface should name the
recurring cost it repays.

When in doubt, explain why a file belongs in this portable repo instead of in a
target project, local Codex home, user skill home, plugin cache, or ignored
machine-local file.
