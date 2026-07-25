# Skill Evaluation Cases

Define these cases before writing or materially revising a skill. Preserve the
baseline so the skill must prove that it changes behavior rather than merely
sounding better.

## Candidate

```text
Skill:
Recurring task or failure:
Existing neighboring skill or owning surface:
Supported models and runtimes:
Change hypothesis:
```

## Case 1: Positive Trigger

```text
Prompt:
Why this skill should be selected:
Expected default route:
Observable success evidence:
```

## Case 2: Near-Neighbor

```text
Prompt:
Expected routing or non-selection:
Misrouting to prevent:
Observable success evidence:
```

## Case 3: Behavior Challenge

```text
Prompt:
Recurring failure exposed:
Expected judgment or action:
Observable success evidence:
```

## Case 4: Retirement Or Cleanup Negative Case

Required negative case when retiring, renaming, or cleaning up a skill.

```text
Prompt:
Stale skill or route that must not remain selected or retained:
Expected replacement or non-selection:
Stale artifacts checked: triggers, install mappings, retired paths, and Compass-owned live copies
Observable success evidence:
```

Add cases only for materially distinct risks. A fragile script or public action
usually needs a failure or recovery case. A skill shared across materially
different models or runtimes needs coverage for each meaningful difference.

## Run Record

| Case | Baseline observation | Candidate observation | Result | Evidence locator |
| --- | --- | --- | --- | --- |
| Positive trigger | | | | |
| Near-neighbor | | | | |
| Behavior challenge | | | | |
| Retirement or cleanup negative case | | | | |

## Grade Observable Behavior

Inspect what happened, not what the agent says happened:

- whether the skill was selected;
- whether neighboring routing remained correct;
- which instructions, references, tools, and scripts were used;
- whether the output satisfied the case;
- whether critical results were verified;
- whether failures produced a useful next action;
- whether authority and safety boundaries held.
- for retirement or cleanup, whether the intended replacement or non-selection
  occurred and stale triggers, install mappings, retired paths, and
  Compass-owned live copies were removed.

A file read, command result, artifact, tool trace, or environment state can be
evidence. Confidence and self-reported compliance are claims.

## Iterate Surgically

Change one causal part when practical, rerun the affected cases, and check for
neighboring regressions. Turn a new recurring failure into a case before adding
another warning. Stop when the cases pass, the trigger remains selective, and no
remaining instruction or resource can disappear without weakening behavior.
