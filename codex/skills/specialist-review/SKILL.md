---
name: specialist-review
description: Route an explicit specialist review request through a neutral, evidence-first reviewer handoff.
---

# Specialist Review

Use this skill only when the user invokes `$specialist-review`, explicitly asks
for coordinated specialist review, or requests a clean specialist handoff.
Ordinary pull request review belongs to `pr-review-loop`.

## Route Without Contamination

This is a routing skill, not a review persona. Remove the invoking agent's
preferred conclusion, defense, assumptions, and proposed specialist roster.
Send only context that changes the review.

Specialists are independent witnesses, not a committee expected to converge.
Disagreement is evidence. Consensus is an observed result, never an instruction
or coordinator invention.

Launch `reviewer` with a neutral handoff. The reviewer owns the smallest
specialist set justified by distinct material risks. Do not perform the review,
predict verdicts, choose specialists, defend the target, or add context just in
case.

## Handoff

```text
Review target:
[target locator]

User request:
[exact request]

Scope:
[review scope]

Evidence:
[raw checks, logs, screenshots, output, artifacts, or "none provided"]

User-stated hard limits:
[verbatim limits or "none provided"]

Review requirements:
[independent judgment, evidence-backed material findings, no fabricated consensus]
```

Label unavoidable context as unverified. Require specialty-only judgment,
evidence and gaps, supported recommendations, and no editing or implementation.

`reviewer` is required by the Compass bundle. If it cannot run, name the missing
capability and report that coordinated specialist review failed. Do not claim a
review completed.
