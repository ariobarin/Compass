# Tool Surfaces

This manifest documents tools that may affect portability, host state, network
access, browser state, or external systems. Keep generated config, credentials,
and cache paths out of this repo.

| Surface | Capability | Portable | Risk | Review note |
| --- | --- | --- | --- | --- |
| Shell | Read, write, run commands, start processes | No | High | Controlled by live sandbox and approval policy. Keep command habits in workflows, not hardcoded runtime paths. |
| GitHub CLI | Create repos, push branches, open PRs, inspect checks | Partial | High | Portable docs are fine. Auth state and tokens stay local. |
| Browser plugin | Uses the in-app browser for localhost, file previews, screenshots, DOM inspection, and public web pages | Partial | Medium | Prefer first for localhost and unauthenticated pages. Website allowlists, blocked sites, and any deeper developer-mode or CDP state stay local. |
| Chrome plugin | Uses logged-in Chrome state and browser tabs | Partial | High | Prefer when session state, cookies, extensions, or the regular browser profile matter. Do not commit profile paths or cookies. |
| Computer Use plugin | Controls Windows desktop apps | Partial | High | Useful fallback for visual desktop tasks. Keep runtime paths local. |
| Documents plugin | Creates and edits document artifacts | Partial | Medium | Portable skill knowledge is fine. Generated files belong in task outputs, not config. |
| which-llm source snapshot | Preserves reviewed model-selection source and provenance | No | Medium | Frozen repository-only source lives in `external-sources/which-llm`. It has no install or refresh route. Any global add-back requires explicit user approval and a separate reviewed change. |
| Compass MCP app | Serves the reviewed profile and skills to regular ChatGPT.com chat mode over read-only HTTP tools | Partial | Medium | Source lives in `apps/compass-mcp`. ChatGPT work mode and Codex are out of scope. Keep tunnels, auth, logs, dependencies, and runtime state outside the portable bundle. |
| Third-party MCP servers | Connect to external tools or context over STDIO or HTTP | Partial | High | Keep transport commands, server URLs, OAuth callback settings, env vars, tokens, and per-server tool policy local or project-scoped unless a generic shared default is clearly justified. |
| node_repl MCP | Runs JavaScript and browser automation helpers | No | High | Binary paths, pipes, env vars, and trusted client hashes are machine-local. |
| Web search | Reads current web sources | No | Medium | Use for unstable facts and source attribution. Do not encode search results as permanent rules without review. |
| Skills | Load task-specific instructions, references, scripts, and assets | No active global route | Medium | The authored global roster is empty. Carried packs and frozen external snapshots remain repository-only. Any global add-back requires explicit user approval and a separate reviewed change. |
| Agents | Spawn focused Codex sessions with custom instructions | No active global route | Medium | The authored global roster is empty. Carried agent packs remain project opt-in and are never promoted by the portable installer. |
| Hooks | Run trusted commands around Codex tool use and turn closeout | No active global route | High | Authored global hooks are retired. Restoring one requires explicit user approval and a separate reviewed change with an exact failure contract and proving test. |
| Orchestration ledger | Writes compact controller state through an exclusive lock and atomic file replacement | Partial | Medium | The scripts are portable; live ledgers stay local under `.local/`. Gate state records coordination and never grants push, merge, release, deployment, or publication authority. |
| Dynamic Codex workflow CLI | Executes a reviewed Python workflow and bounded `codex exec` child processes | Partial | High | Workflow code runs with host permissions. Worker sandboxes do not sandbox it. Runs stay local under `.local/`; review workflow code, keep the CLI sandbox ceiling narrow, and inspect captured prompts and outputs before sharing artifacts. |
| Restart recovery script | Registers a Windows logon task and can resume saved Codex sessions once per boot | Partial | High | Keep scheduled-task instances, logs, and session state local. Review the script and workflow here, cap resumed sessions, and avoid recurring polling. |

## Review Checklist

- Does this tool read or write outside the workspace?
- Does it depend on logged-in state, cookies, tokens, local pipes, or runtime
  cache paths?
- Can it mutate GitHub, browser state, files, processes, containers, or cloud
  resources?
- Does a locally authenticated CLI already provide equivalent coverage? Keep a
  redundant connector disabled or uninstalled unless its distinct capability is
  required.
- Is the capability needed for the task, or would source reads and scripts be
  enough?
- Should the durable artifact be a workflow, skill, script, manifest entry, or
  local-only config note?
