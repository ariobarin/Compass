---
name: test-for-risk
description: Choose evidence proportional to regression risk and maintenance cost. Use when deciding whether a change needs tests, selecting test scope or level, repairing bloated or brittle tests, designing reusable test infrastructure, or deciding what belongs in recurring CI.
---

# Test For Risk

Tests are maintained code and recurring compute. Test the risk, not the diff.

## Buy Proof

- Name the behavior or failure worth protecting. Choose the cheapest evidence
  that can expose it.
- Use a one-time check when no durable regression contract exists. Preserve a
  focused test when recurrence would matter.
- Test stable observable behavior. Treat coverage, test count, and green CI as
  signals, not goals.

## Reuse The Boundary

- Extend an existing test, fixture, or harness before creating another file,
  suite, framework, or CI job.
- Consolidate repeated cases around the behavior they share. When setup starts
  multiplying, improve the testing boundary before adding more tests.
- Prefer real behavior over mocks. Isolate only when the real boundary is
  impractical or isolation is itself the contract.

## Pay Recurring Cost Deliberately

Run proof on every change only when its regression value justifies its runtime,
maintenance, and failure cost. Move slower or broader checks to scheduled or
manual execution when that preserves the needed confidence more cheaply.

If the proof rivals the implementation in size or complexity, stop and
reconsider the risk, the product boundary, and the test architecture.

Source provenance lives in [references/sources.md](references/sources.md). Do not
load it during normal testing work.
