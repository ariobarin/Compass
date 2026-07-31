# Dynamic Codex Workflows

Use the Compass workflow command when one reviewed local program should
dynamically coordinate multiple Codex CLI agents. The workflow is ordinary
Python. Its own control flow decides which agents to start, what runs in
parallel, when to branch or loop, and when enough evidence exists to stop.

This is a CLI mechanism, not a plugin, installed skill, agent roster, or catalog
of named workflow shapes.

## Write A Workflow

A workflow file exports `run(context)`. It may be synchronous or asynchronous.
Agent calls return text, optional structured data, routing metadata, duration,
and the path to their local artifacts.

```python
async def run(context):
    schema = {
        "type": "object",
        "properties": {
            "finding": {"type": "string"},
            "needs_followup": {"type": "boolean"},
        },
        "required": ["finding", "needs_followup"],
        "additionalProperties": False,
    }

    probes = await context.parallel(
        context.agent("Inspect the parser boundary.", schema=schema),
        context.agent("Inspect the process boundary.", schema=schema),
    )

    findings = [probe.data["finding"] for probe in probes]
    while any(probe.data["needs_followup"] for probe in probes):
        followup = await context.agent(
            "Resolve the remaining uncertainty:\n" + "\n".join(findings),
            schema=schema,
        )
        findings.append(followup.data["finding"])
        if not followup.data["needs_followup"]:
            break

    return {"findings": findings}
```

This example demonstrates control flow. It does not define the workflow. A
workflow may use normal Python functions, collections, conditions, loops,
recursion, exception handling, and `asyncio` primitives.

## Run It

The command requires Python 3.11 or newer and an authenticated Codex CLI.

```powershell
.\scripts\compass.ps1 workflow `
  -WorkflowFile .\tmp\investigate.py `
  -WorkingDirectory . `
  -WorkflowArgument issue-123
```

Workers default to `gpt-5.6-luna`, high reasoning, a read-only sandbox, three
concurrent processes, and 32 total agent calls. Override the bounded execution
envelope from the CLI:

```powershell
.\scripts\compass.ps1 workflow `
  -WorkflowFile .\tmp\implement.py `
  -Sandbox workspace-write `
  -MaxConcurrency 3 `
  -MaxAgents 12 `
  -TimeoutSeconds 1800
```

The CLI sandbox is both the default and the ceiling. A workflow may request a
less permissive sandbox for one agent but cannot raise itself above the
operator-selected ceiling. The runtime invokes `codex exec --ephemeral --json`
with approval policy `never`, passes prompts over standard input, and captures
the final response separately.

Use `context.args` for repeated `-WorkflowArgument` values. Each
`context.agent()` call may override `model`, `effort`, `sandbox`, `cwd`,
`timeout_seconds`, and `label`. Pass a JSON Schema object through `schema` when
later control flow needs reliable structured data. Structured results are
available as `result.data`; the original final response remains in
`result.text`.

## Evidence And Trust

Each run writes under `.local/workflow-runs/` unless `-RunRoot` selects another
location. The run directory contains:

- run state and final JSON result;
- an append-only event journal;
- prompts, Codex JSONL events, stderr, final responses, and metadata for each
  agent call;
- a traceback when the workflow fails.

`.local/` is ignored because prompts and responses may contain source code,
private context, or secrets.

The workflow file itself is executable Python with the permissions of the
calling process. Review it as code before running it. Codex worker sandboxes do
not sandbox the Python workflow. Keep untrusted generated workflows out of this
command.

The runtime kills a timed-out or cancelled child process and preserves the
available artifacts. It does not retry, select reviewers, invent phases, or
decide success. Those choices remain in the workflow so the mechanism stays
general.
