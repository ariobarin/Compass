# Sources

Read this provenance when auditing or revising Test for Risk, not during normal
testing work.

Current-model evidence:

- [GPT-5.6 prompting guidance](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.6#prompting-best-practices) reports better coding results from leaner prompts and recommends removing repeated instructions.
- [Claude Opus 5 prompting guidance](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5) says the model self-verifies and legacy verification scaffolding wastes work without improving quality.
- [July 2026 reports from Codex users](https://www.reddit.com/r/codex/comments/1v8sfd7/anyone_else_feel_like_codex_hit_a_wall_recently/) describe exhaustive low-return tests and design documents for trivial changes.
- [A July 2026 GPT-5.6 Sol discussion](https://www.reddit.com/r/OpenaiCodex/comments/1varg3f/how_do_you_avoid_overengineering_with_56_sol/) describes circular gates, infinite testing, and better results from choosing the necessary proof deliberately.

Empirical and durable engineering evidence:

- [Rethinking the Value of Agent-Generated Tests](https://arxiv.org/abs/2602.07900) finds that changing test volume did not significantly change SWE-bench outcomes and often changed process cost more than success.
- [Are Coding Agents Generating Over-Mocked Tests?](https://arxiv.org/abs/2602.00409) finds that agent commits modify tests and add mocks more often than non-agent commits.
- [SlopCodeBench](https://arxiv.org/abs/2603.24755) measures rising verbosity and structural erosion as agents repeatedly extend their own code.
- [Software Engineering at Google: Testing Overview](https://abseil.io/resources/swe-book/html/ch11.html) treats tests as maintained software and warns that an unhealthy suite becomes a productivity sink.
- [Software Engineering at Google: Unit Testing](https://abseil.io/resources/swe-book/html/ch12.html) favors stable tests at public behavior boundaries.
- [Software Engineering at Google: Larger Testing](https://abseil.io/resources/swe-book/html/ch14.html) derives test strategy from risk, lifetime, fidelity, runtime, and ownership.
- [Google SRE: Simplicity](https://sre.google/sre-book/simplicity/) treats every added line as potential liability and favors deleting accidental complexity.
