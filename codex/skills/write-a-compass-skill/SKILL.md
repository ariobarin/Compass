---
name: write-a-compass-skill
description: Add, revise, route, install, validate, or retire a skill inside the Compass reviewed source.
---

# Write A Compass Skill

Maintain a Compass skill as runtime guidance and reviewed portable source. Use
`write-a-skill` for role, language, and behavior. This skill owns repository
routing, wiring, provenance, retirement, and validation.

Read root `AGENTS.md`, `workflows/addition-intake.md`, and the workflow nearest
the change before editing.

## Select The Narrowest Surface

- reusable global capability: `codex/skills/`;
- portable opt-in domain pack: `carried/`;
- project-specific capability: the target repository;
- independent persona: `codex/agents/`;
- deterministic mechanic: scripts, hooks, manifests, or tests;
- Compass maintenance process: `workflows/`;
- maintainer evidence or history: `local-docs/`.

A global skill must provide repeated cross-project value that repays retrieval
and maintenance cost.

## Update One Ownership Route

Follow the complete update-together contract in
`workflows/addition-intake.md`. Keep one reviewed source and reconcile every
directly dependent surface:

- skill source;
- install and Claude derivation maps;
- source record and provenance;
- retired live paths when ownership or names change;
- required-file and policy checks;
- MCP catalog fixtures and other installed-set tests;
- directly related documentation.

Do not duplicate that checklist inside the skill being authored. A fallback
paragraph is not a substitute for exact wiring.

Codex and Claude global instruction files remain separately authored because
their runtime contracts differ. Derive only behavior that is truly shared.

## Preserve Provenance

An externally adapted skill records the reviewed repository, source path,
immutable ref, license, and deterministic source hash. Keep this evidence in a
reference that normal runtime work does not load.

## Retire Completely

A retirement removes the old source and install entries, preserves useful
material in its approved narrower destination, and records every live path
Compass previously owned. A rename is a retirement plus a new skill.

Never delete unrelated personal skills while cleaning retired copies.

## Validate Behavior And Wiring

Run the behavior review from `write-a-skill`, then the narrow tests and:

```powershell
.\scripts\doctor.ps1
.\scripts\verify-live.ps1 -SkipCodexCommand
git diff --check origin/main...HEAD
```

Exercise install and retirement paths when ownership changes. Forward-test
judgment with a fresh realistic invocation. Use a focused pull request as the
review unit. A green build is evidence; current-head review and named authority
determine readiness and merge.
