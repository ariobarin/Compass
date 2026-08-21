# Sources

Read this provenance when auditing or revising Create Verification Skill, not during normal use.

The skill is substantially derived from Lauren Tan's pstack `create-verification-skill`:

- Source: https://github.com/cursor/plugins/blob/46125561306434d8a1d7745d540d8932ab0cd2a2/pstack/skills/create-verification-skill/SKILL.md
- Feature-map examples: https://github.com/cursor/plugins/tree/46125561306434d8a1d7745d540d8932ab0cd2a2/pstack/skills/create-verification-skill/references/feature-map-example
- Repository license: MIT
- Upstream copyright: Copyright (c) 2026 Lauren Tan

Compass keeps the upstream repository interview, launch/doctor/drive/evidence/cleanup contract, user-facing feature map, and requirement to execute the generated skill before handing it over. Platform translation changes the generated project-local skill root from `.cursor/skills` to the standard `.agents/skills` location and uses `agents/openai.yaml` for explicit invocation.

## Upstream license

MIT License

Copyright (c) 2026 Lauren Tan

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