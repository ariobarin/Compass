---
name: monitor
description: Supervise long-running processes, downloads, updates, benchmarks, scripts, agents, and external waits without burning model turns on repetitive polling. Use when work outlives a quick tool call and needs continued health checks, recovery, or intervention before terminal evidence arrives.
---

# Monitor

Monitoring is recoverable supervision, not repeated observation. Keep the clock
and unchanged output outside model context. Wake to decide or act.

## Establish The Watch

Write a compact watch contract before waiting:

- objective and terminal evidence;
- target identity, invariants, and output locations;
- progress and health signals;
- stall and failure thresholds;
- cadence, heartbeat, and deadline;
- authorized recovery actions and escalation boundary;
- last known good state.

Keep this anchor short. Carry it across compaction and delegation. Update it on
meaningful transitions, not every observation.

Do not arm a watch without a real target and observable evidence surface. If
either is absent, return the contract instead of pretending to monitor.

## Choose The Watcher

### Scripted Watcher

Prefer a native wait, callback, notification, or one bounded watcher command.
Otherwise write the smallest surface-specific loop. Let it sleep, sample, and
retain bounded state outside the conversation. Return only on:

- terminal evidence;
- an actionable anomaly;
- a heartbeat;
- explicit cancellation;
- a deadline, which returns judgment rather than imply completion.

Prefer events over timers. Have the caller or a separate watchdog treat a missed
heartbeat as watcher failure. At a heartbeat, reopen the contract and reassess
cadence. Never send unchanged polls or full logs back through the model.

### Delegated Watcher

Use a fresh non-forked agent when checks need interpretation, the surface is
large, or principal attention is expensive. Spend the cheapest model capable of
the judgment. Give it the watch contract, relevant evidence surfaces, recovery
authority, and a compact return channel. It may run the scripted watcher itself.

The delegate owns the loop, including authorized repair and resumption. The
principal owns the objective. Split delegates across distinct failure surfaces.
When monitors overlap, name one repair owner and one shared anchor; the rest
observe and deduplicate. Add redundancy only when a missed failure justifies it.

## Supervise To Completion

At each wake:

1. Reopen the contract and inspect the smallest useful delta.
2. Distinguish healthy progress, a stall, failure, and terminal evidence.
3. If healthy, adjust cadence when risk or progress changed, then wait again.
4. If recoverable within authority, diagnose, repair, restart or resume, update
   the anchor, and keep watching. A repaired failure is not completion or a
   blocker.
5. Escalate only when recovery exceeds authority, needs a material decision, or
   has exhausted credible in-scope repairs.

Silence is not health. Require positive liveness or progress evidence suited to
the surface. Completion requires terminal evidence, not elapsed time or the
absence of errors.

Explicit cancellation ends the watch. A deadline returns control for a fresh
decision; it never proves completion or failure.

Source provenance lives in [references/sources.md](references/sources.md). Do not
load it during normal monitoring.
