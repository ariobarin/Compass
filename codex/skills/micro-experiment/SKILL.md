---
name: micro-experiment
description: Test an uncertain product or technical idea with disposable code before integrating it. Use for proofs of concept, spikes, prototypes, novel pipelines, unfamiliar APIs, or any idea whose shape, feasibility, behavior, or value is still unknown.
---

# Micro Experiment

Learn before you integrate. Production code delivers a known idea. A
micro-experiment discovers what the idea should be.

## Isolate The Unknown

Name the decision blocked by uncertainty. Build the smallest world where
reality can answer it.

Prototype only the uncertain dimension: the role, experience, mechanism, or
integration boundary. Do not reproduce the whole product around an idea you
have not understood.

## Leave Production Behind

Start outside production code. Choose the medium that makes iteration fastest:
one script, a tiny CLI, a notebook, a static page, hard-coded data, fake
boundaries, or a disposable repository. Let the experiment find its own shape.
Do not make it conform to the current interface, architecture, or conventions.

Enter the real repository only when the uncertainty depends on its integration
boundary, state, performance, or environment. Confine that work to an
explicitly disposable branch or worktree. The experiment itself is not a
production pull request.

## Learn Fast

Spend code only on the uncertain part. Fake, hard-code, or omit everything
else. Roughness is useful when it shortens the path to evidence.

Run the cases or measurements that let the idea surprise you. Change direction
freely.

Test the claim, not the prototype. Add only the rigor needed to trust the
finding. Stop when the result changes a decision, not when the code looks
shippable.

## Carry The Learning

Return the runnable experiment, observed result, remaining uncertainty, and the
decision it supports. If it earns production work, start a separate
implementation using real requirements, architecture, tests, and review.
Rebuild from what you learned. Do not promote disposable code by inertia.

Source provenance lives in [references/sources.md](references/sources.md). Do not
load it during normal experimentation.
