---
name: write-a-skill
description: Create, evaluate, revise, or retire reusable agent skills. Use for repeatable capabilities, routing or behavior fixes, resources, and stale-skill cleanup.
---

# Write A Skill

Build the smallest reusable capability that measurably improves agent behavior
on its intended tasks without stealing neighboring work or consuming unnecessary
context.

Weak skills encode guesses, vague triggers, and checklists. Strong skills begin
with observed failure, prove their value against a baseline, and keep only
load-bearing guidance.

## Prove The Need Before Prose

Start with recurring evidence. Ask whether an existing skill, project
instruction, workflow, agent, or deterministic mechanic already owns the need.
A useful one-off does not earn global retrieval cost.

Before editing, define at least three realistic cases:

- a positive trigger that should select the skill;
- a near-neighbor that should not select it, or should select another skill;
- a behavior challenge that exposes the recurring failure the skill must correct.

For each case, name the expected behavior and observable evidence. Run the cases
without the candidate skill or change and preserve the baseline observations.
Use [evaluation-cases.md](references/evaluation-cases.md) when a reusable worksheet
helps.

For retirement or cleanup, add the required negative case: the stale skill must
not remain selected or retained. Its success evidence proves the intended
replacement or non-selection and that stale triggers, install mappings, retired
paths, and Compass-owned live copies are absent.

## Establish The Smallest Contract

The first screen should make these immediately legible:

- what the capability does and when to select it;
- the intended result;
- the preferred default route;
- the recurring failure it corrects;
- the evidence standard and observable success condition;
- the authority boundary.

Every Compass skill must state its recurring failure, evidence standard, and
authority boundary in its first screen. State them plainly and proportionately;
simple operational skills should not imitate the rhetoric of judgment-heavy or
high-authority skills.

Frontmatter uses a kebab-case `name`. Its description states both what the skill
does and when to use it, using concrete task, input, or outcome terms that
distinguish neighboring skills.

Give one preferred route. Name an alternative only when an observable condition
makes the default unsuitable.

## Calibrate Freedom

Match instruction shape to the decision:

- principles and boundaries for contextual judgment;
- compact examples or templates for a preferred shape;
- ordered steps when sequence is real;
- scripts or deterministic checks when mechanics are fragile or exact.

Do not replace judgment with an exhaustive flowchart. Do not ask the model to
reconstruct a deterministic operation that code can complete and verify.

## Disclose Progressively

Keep the runtime surface lean:

```text
skill-name/
  SKILL.md
  references/
  scripts/
  assets/
  agents/openai.yaml
```

Use only needed folders.

- `SKILL.md` carries the contract, default route, and action-critical guidance.
- `references/` carries optional depth loaded only when needed.
- `scripts/` carries deterministic or fragile mechanics.
- `assets/` carries output resources.
- `agents/openai.yaml` carries discovery metadata when required.

Link optional resources directly from `SKILL.md`. Avoid reference-to-reference
chains and duplicate quick references. Keep discovery history, changelogs,
installation notes, provenance, and maintenance debate outside normal runtime
text.

## Engineer Executable Mechanics

A bundled script should solve the operation rather than hand the hard part back
to the model. It should:

- verify required dependencies and assumptions;
- validate critical outputs;
- return compact useful results and actionable failures;
- justify non-obvious constants and parameters;
- use paths and commands valid for every supported runtime, or isolate the
  runtime-specific route explicitly.

Quality-critical operations need a feedback or verification loop.

## Preserve One Lifecycle And Trust Boundary

Maintain one canonical source and derive copies mechanically. Do not hand-edit
installed or generated copies.

Before adopting an external skill, inspect its instructions, code, dependencies,
tool use, network and filesystem access, and permission assumptions. Preserve its
source, immutable version, license, and reviewed changes outside normal runtime
guidance. Provenance alone is not approval.

A rename is retirement plus a new skill. Remove stale names, triggers, install
entries, and owned live copies without touching unrelated user material.

## Evaluate, Then Prune

Run the defined cases on every materially different model or runtime the skill
supports. Observe behavior rather than self-reported confidence:

- Was the right skill selected?
- Did the near-neighbor avoid the skill or route correctly?
- Did the agent follow the preferred route?
- Which references and scripts did it actually use?
- Did the output and verification satisfy the case?
- Did failure handling preserve a useful next action?
- For retirement or cleanup, did the evidence prove the replacement or
  non-selection and removal of stale routing, install, retirement, and owned
  live artifacts?

Compare candidate behavior with the baseline. Keep additions only when they
produce a meaningful improvement or protect a necessary boundary. Turn recurring
failures into evaluation cases before adding another warning. Remove any
paragraph, branch, resource, or script that does not earn its context and
maintenance cost.

Static validation proves structure and wiring. It does not prove behavior.

## Output

Return the skill, needed resources, trigger rationale, evaluation cases, baseline
and candidate evidence, known boundaries, lifecycle changes, and the durable
surface that owns it.
