# 2026-07-29 Pre-reset Catalog

This catalog freezes the authored portable runtime state at base
`349b94acad6175561e56304704856c5632db6b6c` before the global bundle was reset
to blank. It is retirement and rollback evidence, not an active install list.
`manifests/portable-files.toml` remains the authority for the current empty
bundle, and `manifests/portable-retirements.json` remains the mechanical
retirement authority.

## Usage Evidence Boundary

The supporting 180-day usage scan covered 1,019 files and 932,821,237 bytes and
hit its 1 GiB cap. The scan is supporting evidence only. It is truncated and
does not prove that an omitted artifact was unused. `display-dev` is excluded
because it was branch-only and absent from base `349b94a`.

## Global Files And Directories

| Removed source at base | Live target | Ownership and provenance |
| --- | --- | --- |
| `codex/AGENTS.md` | Codex home `AGENTS.md` | Compass-authored global |
| `codex/hooks.json` | Codex home `hooks.json` | Compass-authored hook config |
| `codex/keybindings.json` | Codex home `keybindings.json` | Compass-authored keybindings |
| `codex/agents/` | Codex home `agents/` | Compass-authored role directory |
| `codex/hooks/` | Codex home `hooks/` | Compass-authored hook implementation and docs |
| `claude/CLAUDE.md` | Claude home `CLAUDE.md` | Compass-authored Claude global |

## User Skills And Derived Claude Skills

Each row names the complete removed source directory. The Codex target is the
user skill home, not the Codex home. A dash means the base manifest declared no
Claude copy.

| Removed source at base | User skill target | Derived Claude target | Ownership and provenance |
| --- | --- | --- | --- |
| `codex/skills/action-items-to-prs/` | `.agents/skills/action-items-to-prs/` | `.claude/skills/action-items-to-prs/` | Compass |
| `codex/skills/behavior-validator/` | `.agents/skills/behavior-validator/` | `.claude/skills/behavior-validator/` | Compass |
| `codex/skills/compass/` | `.agents/skills/compass/` | `.claude/skills/compass/` | Compass |
| `codex/skills/design-taste-frontend/` | `.agents/skills/design-taste-frontend/` | `.claude/skills/design-taste-frontend/` | `Leonxlnx/taste-skill`, reviewed ref `b17742737e796305d829b3ad39eda3add0d79060` |
| `codex/skills/git-branch-resolver/` | `.agents/skills/git-branch-resolver/` | `.claude/skills/git-branch-resolver/` | Compass |
| `codex/skills/grill-me/` | `.agents/skills/grill-me/` | `.claude/skills/grill-me/` | Compass |
| `codex/skills/monitor-to-completion/` | `.agents/skills/monitor-to-completion/` | `.claude/skills/monitor-to-completion/` | Compass |
| `codex/skills/orchestration-controller/` | `.agents/skills/orchestration-controller/` | `.claude/skills/orchestration-controller/` | Compass |
| `codex/skills/pr-review-loop/` | `.agents/skills/pr-review-loop/` | `.claude/skills/pr-review-loop/` | Compass |
| `codex/skills/root-cause-not-symptom/` | `.agents/skills/root-cause-not-symptom/` | `.claude/skills/root-cause-not-symptom/` | Compass |
| `codex/skills/run-a-micro-experiment/` | `.agents/skills/run-a-micro-experiment/` | `.claude/skills/run-a-micro-experiment/` | Compass |
| `codex/skills/specialist-review/` | `.agents/skills/specialist-review/` | `.claude/skills/specialist-review/` | Compass |
| `codex/skills/subagent-driven-development/` | `.agents/skills/subagent-driven-development/` | `.claude/skills/subagent-driven-development/` | Compass |
| `codex/skills/to-prd/` | `.agents/skills/to-prd/` | `.claude/skills/to-prd/` | Compass |
| `codex/skills/using-goals/` | `.agents/skills/using-goals/` | `.claude/skills/using-goals/` | Compass |
| `codex/skills/which-llm/` | `.agents/skills/which-llm/` | dash | `ariobarin/which-llm`, reviewed ref `b0e9dbceedde2ecb65768b01237492382e7f07fd` |
| `codex/skills/workspace-steward/` | `.agents/skills/workspace-steward/` | `.claude/skills/workspace-steward/` | Compass |
| `codex/skills/write-a-skill/` | `.agents/skills/write-a-skill/` | `.claude/skills/write-a-skill/` | Compass |

The nested
`codex/skills/workspace-steward/references/project-template/` subtree was not
retired as project-local material. Its base contents moved to
`project-templates/workspace/`, which is repository-only and has no live global
target.

The two third-party source snapshots were also preserved outside the blank
install route:

- `codex/skills/design-taste-frontend/` moved to
  `external-sources/design-taste-frontend/`. Provenance remains
  `Leonxlnx/taste-skill` at
  `b17742737e796305d829b3ad39eda3add0d79060`, with reviewed source hash
  `b07d0b09af568cb70a43242351d23f1a904d0b27b166246dba35333148614e6c`.
- `codex/skills/which-llm/` moved to `external-sources/which-llm/`.
  Provenance remains `ariobarin/which-llm` at
  `b0e9dbceedde2ecb65768b01237492382e7f07fd`, with reviewed source hash
  `2e173dca72c45a27760d38a09b6b7349962651796ff48744b55a75ed88e67b48`.

All 48 migrated files are content-equivalent to their base blobs. Forty-seven
retain the exact base blob hash. The patch writer added one terminal LF to
`design-taste-frontend/references/upstream.md`, which previously lacked it. No
other text differs.

## Derived Claude Agents

Each Claude file was derived from the named Compass-authored Codex source.

| Removed source at base | Derived Claude target |
| --- | --- |
| `codex/agents/algorithm-critic.toml` | `.claude/agents/algorithm-critic.md` |
| `codex/agents/behavior-validator.toml` | `.claude/agents/behavior-validator.md` |
| `codex/agents/neutral-critic.toml` | `.claude/agents/neutral-critic.md` |
| `codex/agents/progress-monitor.toml` | `.claude/agents/progress-monitor.md` |
| `codex/agents/repo-explorer.toml` | `.claude/agents/repo-explorer.md` |
| `codex/agents/research-critic.toml` | `.claude/agents/research-critic.md` |
| `codex/agents/reuse-critic.toml` | `.claude/agents/reuse-critic.md` |
| `codex/agents/reviewer.toml` | `.claude/agents/reviewer.md` |
| `codex/agents/verifier.toml` | `.claude/agents/verifier.md` |

## Reviewed Config

The removed source was `codex/config.review.toml`. Its live target was the
matching dotted entry in Codex home `config.toml`. Retirement removes an entry
only when the live value still equals the prior expected value below.

| Dotted target | Prior expected value |
| --- | --- |
| `model` | `"gpt-5.6-sol"` |
| `model_reasoning_effort` | `"high"` |
| `model_context_window` | `272000` |
| `model_auto_compact_token_limit` | `233000` |
| `model_auto_compact_token_limit_scope` | `"total"` |
| `personality` | `"pragmatic"` |
| `sandbox_mode` | `"danger-full-access"` |
| `approval_policy` | `"never"` |
| `agents.max_depth` | `2` |
| `windows.sandbox` | `"elevated"` |
| `notice.hide_full_access_warning` | `true` |
| `features.memories` | `true` |
| `features.goals` | `true` |
| `features.prevent_idle_sleep` | `true` |
| `features.multi_agent_v2.hide_spawn_agent_metadata` | `false` |
| `features.multi_agent_v2.tool_namespace` | `"agents"` |

## Earlier Explicit Retirements

The general retirement manifest also preserves the base manifest's earlier
Codex-home skill, user-skill, Claude-skill, and Claude-agent retirements. Those
targets have no active source at base and remain absence requirements. They are
listed mechanically in `manifests/portable-retirements.json`; their carried
copies, where present, remain repository-only and are not deleted.

## Reversal

The blank transition is reversible by installing the exact old source at
`349b94a` into the same scratch homes. Reset backups and receipts preserve every
owned removal. Restoration does not authorize applying either direction to a
live home.
