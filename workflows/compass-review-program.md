# Compass Review Program

Use this workflow to audit Compass maintainer documentation, carried packs,
repository-only source snapshots and templates, manifests, scripts, and blank
install behavior.

The authored portable global route is intentionally blank. No Codex or Claude
global, skill, agent, hook, or reviewed config entry may be restored from this
workflow. Any add-back requires explicit user approval and a separate reviewed
change.

Review one coherent surface family per pull request. Preserve capability while
reducing recurring context, state, routes, dependencies, and maintenance.

## Reduction Lens

An incisive review identifies the decision a surface must improve. A
parsimonious result keeps the fewest truthful concepts, states, and sources.
Lean and economical guidance earns its context cost. Selective, surgical edits
touch the narrowest owning boundary. Prune what does not change behavior, then
distill what remains.

Succinct or pithy wording is useful only when it stays complete. Raw brevity is
not the target.

## Audit Sequence

| Move | Question |
| --- | --- |
| Distill | Who reads this, what behavior must change, what evidence proves it, and what authority belongs here? |
| Prune | What can disappear because it is stale, duplicated, non-actionable, or aimed at the wrong audience? |
| Select | What is the narrowest durable surface and the smallest evidence set needed? |
| Simplify | Can concepts, states, routes, wrappers, or sources of truth collapse without weakening behavior? |
| Verify | Does the surviving surface create the intended behavior and remain wired correctly? |

Stop when the smallest coherent surface preserves the required role, boundary,
and evidence standard. Do not continue polishing after the behavioral gain is
proved.

## Inventory The Surface

Classify each item before editing:

- blank global install authority: `manifests/portable-files.toml`;
- safe retirement authority: `manifests/portable-retirements.json`;
- carried capability: `carried/`, adopted only by a target project;
- frozen external source: `external-sources/`, with provenance preserved but no
  install route;
- copyable project starter: `project-templates/`;
- maintainer context: root `AGENTS.md`, `workflows/`, or `local-docs/`;
- mechanical truth: `scripts/` and `manifests/`;
- stale or removal candidate.

Record only facts that change a decision:

```text
Path:
Audience:
Required behavior:
Evidence:
Authority:
Recurring cost:
Overlap or stale route:
Reduction move:
Verification:
```

## Review Runtime Guidance

The first screen should establish the role, desired result, recurring failure,
evidence standard, and authority boundary. Lead with the desired state. Keep a
prohibition when its forbidden shape is crisp and important, and pair
judgment-heavy prohibitions with the positive replacement.

Move dated observations, author history, packaging rationale, and maintainer
debate out of runtime context. Keep ordered procedures only when sequence
protects a fragile mechanic, isolation boundary, public mutation, or handoff.

For long-running guidance, verify that one logical principal authors control
state, delegates receive reviewed assignments and return evidence, and a fresh
context can resume from anchors plus a checkpoint.

## Review Capability Candidates

The active authored global roster is empty. For carried packs, frozen source
snapshots, or a proposed add-back, ask:

- Is the behavior reusable across repositories and ordinary work?
- Is the description specific enough for natural invocation?
- Does the surface shape judgment instead of enumerating every thought?
- Does it overlap another role, or merely compose with it?
- Would a project or carried route preserve value at lower global cost?
- Does model and effort routing match the current dated profile?
- Do install maps, source records, retirements, policy checks, and catalogs
  agree that the current global route stays blank?

Do not convert a carried pack or frozen source snapshot into an installed global
capability during an audit. Prepare the decision and evidence for explicit user
approval instead.

## Review Control Surfaces

Control documents preserve one principal intention. Verify principal-only
authorship of goals, plans, catalogs, assignments, and checkpoints; evidence
provenance for delegated returns; compact mutable state; absolute timestamps;
revision protection for mechanical ledgers; changed evidence before equivalent
recovery attempts; and a fresh-context resume path.

A ledger supports the work. It never becomes the product.

## Review Mechanics

For each script, identify its trigger, exact property, failure behavior, and
proving test. Move deterministic truth out of prose. Keep broad judgment out of
code. Authored global hooks are retired and have no active source route.

## Common Reduction Targets

Prune duplicate doctrine, alternate sources of truth, audience mismatch,
project lore in global context, dated model routes preserved by habit, soft
language around required behavior, checklist sprawl that protects no fragile
operation, and obsolete wrappers, branches, fallbacks, or compatibility paths.

Measure maintained concepts, states, dependencies, routes, and sources of truth.
Line reduction is supporting evidence, not the goal.

## Review And Verification

Use a focused pull request as the review unit. State the behavior preserved or
changed, what moved or disappeared, the recurring cost reduced, verification,
and remaining risk or dated assumptions.

Run narrow checks first, then the repository doctor and install round trip when
portability changes. Forward-test judgment changes with a fresh agent. Inspect
current-head checks, reviews, threads, and behavior proof before calling the pull
request ready.

A green build is evidence. Readiness and public mutation still require their
named authority.

## Taste Boundary

Bring the user a prepared decision when a change alters Compass philosophy,
removes a valued capability, materially narrows ordinary behavior, or chooses
between plausible value systems. Apply routine stale-guidance repair and exact
mechanical reconciliation without turning every cleanup into a taste question.
