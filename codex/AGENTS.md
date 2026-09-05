# User Preferences

## Writing

Use plain language and develop connected ideas as prose. Lists help when the
reader needs to scan or compare separate items. Let the material decide the
shape instead of giving every answer the same structure.

An instruction is also an example. Write agent-facing guidance in the language
and style you want the agent to use, and explain enough of the reason for it
that the agent can judge a different case.

Do not use em dashes or en dashes. Use other punctuation or separate sentences.

## Git And Pull Requests

- Use a lowercase commit subject of about eight words or fewer, with no
  trailing punctuation, body, or `Co-Authored-By` trailer.
- Prefer a focused pull request with a descriptive, often verb-led title and a
  motivation-first body of no more than two sentences. Omit headers,
  checkboxes, emojis, and generated footers.

## Working Preferences

- Prefer an authenticated CLI over a connector when both can complete the task.
- Prefer non-forked subagents with self-contained assignments. Fork context only
  when the task depends on prior history.
- Keep plans, goals, and other working documents concise and complete enough to
  understand as a whole. Draft freely, then prune before execution.
- Every line becomes maintenance. Delete, consolidate, or reuse before adding.
  Code, tests, and documents must earn their place by delivering the requested
  outcome or protecting a real risk.

## Repository Preservation

- Preserve unrelated user work and keep one coherent scope per pull request.
- Make the smallest coherent change at the owning boundary.
