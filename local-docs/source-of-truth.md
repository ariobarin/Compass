# Source-of-truth register

This register is the single inventory of every fact that more than one place
used to maintain. For each fact family it names exactly one canonical source,
the mechanism that binds every other copy to it, the check that enforces the
binding, and the current status. Later consolidation PRs update a row's status
from `planned` to `consolidated`, or to `canonical` when the binding already
existed before the audit.

Mechanism values:

- `generate`: a secondary copy is derived from the canonical source by a script
  under `scripts/generators/` and committed.
- `link`: a secondary copy is reduced to a pointer at the canonical source.
- `accepted`: intentional separation, documented below, no binding needed.
- `pin`: copies stay, but a policy contract or check requires a shared phrase
  or structural anchor, so drift fails doctor.
- `keep`: already single-source before the audit.

Status values:

- `canonical`: already one source before the audit.
- `consolidated`: the binding shipped.
- `planned`: the binding is designed but not yet shipped.
- `accepted`: intentional separation, no binding planned.

| ID | Fact family | Canonical source | Mechanism | Bound by | Status |
| --- | --- | --- | --- | --- | --- |
| 1 | Control-state and project starter templates | workflows/templates/*.md and project-templates/workspace | accepted | manifest-boundaries.ps1 | accepted |
| 2 | Portable retirement targets and config values | manifests/portable-retirements.json | pin | portable-retirements.ps1 and test-compass-architecture.py | consolidated |
| 3 | Empty active portable roster | manifests/portable-files.toml | pin | manifest-boundaries.ps1 and skill-sources.ps1 | consolidated |
| 4 | Required-files list | git index (tracked files) | generate | required-files.ps1 | consolidated |
| 5 | Doctor dispatch list | manifests/doctor-checks.json | generate | doctor.ps1 | consolidated |
| 6 | Carried Codex and Claude agent pairs | carried/*/agents/*.toml | generate | generated-artifacts.ps1 | consolidated |
| 7 | Worker Result enum | manifests/policy-contracts.json | pin | policy-contracts.ps1 | consolidated |
| 8 | Model-tier defaults | manifests/model-tiers.json | generate | model-tiers.ps1 | consolidated |
| 9 | Ledger schema version | scripts/_orchestration_ledger_core.py | generate | generated-artifacts.ps1 | consolidated |
| 10 | Skill-description length cap | scripts/common.ps1 MaxSkillDescriptionLength | pin | test-compass-architecture.py | consolidated |
| 11 | Routing source reference (checklist prose deferred) | workflows/addition-intake.md | pin | policy-contracts.ps1 | consolidated |
| 12 | Glossary terms | glossary.md | link | editorial convention | accepted |
| 13 | Blank portable global route | manifests/portable-files.toml | pin | policy-contracts.ps1 | consolidated |
| 14 | Portable runtime home paths | scripts/common.ps1 home resolvers | pin | portable-home-paths.ps1 | consolidated |

Third-party source snapshots are repository-only under `external-sources/`.
Their reviewed refs and hashes are frozen in
`local-docs/2026-07-29-pre-reset-catalog.md`; they are not active skill-source
records.

## Intentional separations

These duplications are deliberate and stay. They are listed here so future
audits do not re-flag them.

- `apps/compass-mcp/profile.md` remains an app-local profile. It is not part of
  the blank global Codex and Claude install route.
- `workflows/templates/*.md` are maintainer control-document templates.
  `project-templates/workspace/` is a copyable project starter. Both are
  repository-only and serve different lifecycles.
- `workflows/plan-template.md` is elaborated maintainer guidance distinct from
  the bare `workflows/templates/plan.md` template. Both stay.
- `scripts/doctor/checks/agents.ps1` allowed-models allowlist is a different
  fact from the model-tier defaults in `manifests/model-tiers.json`. Both stay.
- `project-templates/workspace/glossary.md` is a
  starter-pack glossary for adopting workspaces, distinct from the terminology
  authority at root `glossary.md`. It stays separate so a new workspace gets a
  compact self-contained reference.
- `.gitignore` governs the working tree while `manifests/portable-files.toml`
  `[local_only]` governs install boundaries. Every `[local_only].files` entry
  must also appear in `.gitignore`; unrelated repository ignore patterns remain
  independent.

## Blank Route Boundary

The 14 fact families describe the accepted repository tree after the reset.
`manifests/portable-files.toml` is the only active global install authority and
its Codex, user-skill, Claude, and reviewed-config arrays are empty.
`manifests/portable-retirements.json` is the only retirement authority.

Project templates and frozen external source snapshots are repository-only.
They cannot be promoted, imported, derived, or installed automatically. Any
global add-back requires explicit user approval and a separate reviewed change
that updates the install manifest, ownership records, retirement behavior,
doctor checks, tests, and maintainer guidance together.

The active bindings are enforced by dynamic doctor dispatch, git-derived
required files, `manifest-boundaries.ps1`, `portable-retirements.ps1`,
`generated-artifacts.ps1`, `model-tiers.ps1`, `portable-home-paths.ps1`, policy
contracts, focused Python tests, and the install round trip. Run
`pwsh scripts/doctor.ps1` to verify the complete binding.
