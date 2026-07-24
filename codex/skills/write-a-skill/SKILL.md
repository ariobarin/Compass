---
name: write-a-skill
description: Create, revise, or retire a reusable agent skill that strongly orients judgment, stays lean, and preserves a clean lifecycle.
---

# Write A Skill

Create a reusable direction vector that changes how a capable model judges new
cases. Weak skills become trigger phrases plus checklists. Bloated skills
consume context without establishing a role.

The result is the smallest complete skill whose trigger, stance, evidence, and
authority are clear before its procedure.

## Establish The Contract

The first screen should establish:

- role;
- desired result;
- recurring failure the role corrects;
- evidence that proves success;
- authority boundary.

Give only enough rationale to orient action. Put discovery history, model
anecdotes, provenance, and maintenance debate outside installed runtime text.

## Choose The Narrowest Surface

- reusable cross-project judgment: global skill;
- project-specific capability: project skill;
- skeptical or independent persona: agent;
- recurring human maintenance process: workflow;
- deterministic guard or fragile mechanic: script, hook, manifest, or test;
- portable opt-in domain capability: carried resource.

A useful one-off does not earn global retrieval cost.

## Distill, Then Prune

Each paragraph must do at least one job: shape judgment, protect a boundary,
name evidence, or route action. Delete it or move it to a reference otherwise.

Prefer one strong principle over a branching catalog of cases. Keep the runtime
surface lean:

```text
skill-name/
  SKILL.md
  references/
  scripts/
  assets/
  agents/openai.yaml
```

Use only needed folders.

- `SKILL.md` carries the role and action-critical guidance.
- `references/` carries optional depth.
- `scripts/` carries deterministic or fragile mechanics.
- `assets/` carries output resources.
- `agents/openai.yaml` carries discovery metadata when required.

Frontmatter uses a kebab-case `name` and a concise capability plus trigger
description. Do not add changelogs, installation notes, duplicate quick
references, or maintainer rationale to the installed skill.

## Shape Judgment Before Procedure

Lead with the behavior and state to create. Use prohibitions for crisp,
observable boundaries. Pair judgment-heavy prohibitions with the desired
replacement.

Use principles, boundaries, and compact examples for contextual decisions. Use
ordered steps only when sequence is real, mechanics are fragile, or a handoff
contract must stay exact.

Write decisively. Succinct and pithy language helps only when the role remains
complete.

## Preserve One Lifecycle

Maintain one canonical source and derive copies mechanically. Do not hand-edit
installed or generated copies.

When adapting an external skill, preserve its source, immutable version, license,
and reviewed changes outside normal runtime guidance.

A rename is retirement plus a new skill. Remove stale names, triggers, install
entries, and owned live copies without touching unrelated user material.

## Prove The Skill

Review behavior, not prose alone:

- Can its trigger be distinguished from neighboring skills?
- Does the first screen establish result, failure, evidence, and authority?
- Does a fresh agent behave differently on a realistic task?
- Can detail move to a reference or deterministic mechanic?
- Does any rule decide something that should remain contextual?
- Can any paragraph disappear without losing behavior?
- Do source, derived copies, discovery metadata, and retirement state agree?

Forward-test fragile judgment with realistic prompts. Repair the cause of weak
behavior instead of appending another warning.

## Output

Return the skill, needed resources, trigger rationale, behavior evidence, known
boundaries, lifecycle changes, and the durable surface that owns it.
