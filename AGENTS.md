# Repository Guidance

Compass is reviewed maintenance source for an intentionally blank portable
Codex and Claude Code global bundle. It is not a raw runtime-home backup.

## Source Boundaries

- `manifests/portable-files.toml` is the authority for the empty active bundle.
- `manifests/portable-retirements.json` is the authority for former global
  targets and prior reviewed config values.
- Portable opt-in domain packs live under `carried/` and stay out of global
  install lists.
- Compass-only maintenance belongs in this file, `workflows/`, `local-docs/`,
  `manifests/`, or `scripts/`.
- Project-specific capability belongs in the target project.

Keep the global route blank until a separately reviewed change proves that a
new cross-project runtime artifact earns global scope. Put deterministic truth
in a script, manifest, schema, or test.

## Maintenance Posture

Read [philosophy.md](philosophy.md), [glossary.md](glossary.md),
[local-docs/maintenance-learnings.md](local-docs/maintenance-learnings.md), and
the workflow nearest the change before a nontrivial edit.

Understand first. Reduce second. Preserve behavior while reducing repeated
context, duplicate sources, mutable states, weak choices, and maintenance cost.

Lead documentation with the desired role and state. Use a prohibition when the
forbidden boundary is crisp or when a recurring failure has an unmistakable
shape. Pair judgment-heavy prohibitions with the positive replacement.

For long-running work, preserve one logical principal across contexts. The
principal or user authors the goal, plan, catalog, assignments, and checkpoints.
Delegates execute reviewed assignments and return artifacts plus evidence. Do
not distribute control authorship across worker-written ledgers.

Material plans and assignments should be reviewable before dispatch unless the
user has already granted or explicitly waived that review boundary.

## Exact Repository Rules

- Treat every manifest collection, including an empty collection, as exact.
- Fix Compass-owned wiring in source, transforms, manifests, policy contracts,
  and tests. Avoid alternate-path prose where Compass can make the route exact.
- Update source, install maps, retirement maps, required-file checks, policy
  contracts, MCP catalog expectations, and tests together when ownership moves.
- Preserve external provenance and license evidence in carried packs.
- Keep `AGENTS.override.md`, auth, sessions, logs, caches, browser state,
  database files, generated plugin state, and machine-only values untracked.
- Respect `CODEX_HOME`, `-AgentsHome`, and `-ClaudeHome` instead of hardcoding
  default runtime paths.
- Retire only receipt-owned targets whose current fingerprints still match.
  Preserve unrelated live files, config keys, and comments.
- Use a focused pull request as the review unit.
- Run `git diff --check` and the narrow tests for every changed mechanism.
- Run `.\scripts\doctor.ps1` before committing.
- Run `.\scripts\verify-live.ps1 -SkipCodexCommand` when install or retirement
  drift matters.

## Review Focus

Flag:

- accidental expansion of the portable boundary;
- project-specific material promoted globally;
- accidental recreation of a retired global source;
- soft language around required behavior;
- negative-only guidance with no desired replacement;
- distributed control authorship in long-running work;
- premature implementation while authority remains in planning;
- worker claims accepted without current evidence;
- model routing that conflicts with the dated current profile;
- stale skill names, install maps, retirement paths, policy strings, or tests;
- generated mechanics expressed only as remembered prose.
