# Sources

Read this provenance when auditing or revising To Tickets, not during normal use.

The skill is substantially derived from Matt Pocock's `to-tickets` skill:

- Source: https://github.com/mattpocock/skills/blob/0ab1b63a410a03d3627979a109c8695de27af954/skills/engineering/to-tickets/SKILL.md
- Repository license: MIT
- Upstream copyright: Copyright (c) 2026 Matt Pocock

Compass keeps the upstream tracer-bullet slicing rules, blocking-edge model, wide-refactor expand-contract exception, approval round, publication templates, and stale-path warning. It removes the dependency on Matt's setup skill and hard-coded local `.scratch` issue location so the same workflow can use whatever tracker, local issue directory, and triage vocabulary the repository or user has actually configured.

## Upstream license

MIT License

Copyright (c) 2026 Matt Pocock

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
