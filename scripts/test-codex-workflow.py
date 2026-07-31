#!/usr/bin/env python3
from __future__ import annotations

import asyncio
import json
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path
from unittest.mock import patch

from codex_workflow import (
    AgentExecutionError,
    WorkflowContext,
    WorkflowError,
    _parser,
    _resolve_codex_command,
    _run,
)


FAKE_CODEX = r"""
import json
import pathlib
import sys
import time

arguments = sys.argv[1:]
prompt = sys.stdin.read()

def option(name):
    index = arguments.index(name)
    return arguments[index + 1]

final_path = pathlib.Path(option("--output-last-message"))
schema_path = pathlib.Path(option("--output-schema")) if "--output-schema" in arguments else None
if "fail" in prompt:
    print("requested failure", file=sys.stderr)
    raise SystemExit(7)
if prompt.startswith("sleep:"):
    time.sleep(float(prompt.split(":", 1)[1]))

payload = {"prompt": prompt} if schema_path else f"answer:{prompt}"
final_path.write_text(
    json.dumps(payload) if schema_path else payload,
    encoding="utf-8",
)
print(json.dumps({"type": "item.completed", "prompt": prompt}))
"""


class WorkflowContextTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.fake = self.root / "fake_codex.py"
        self.fake.write_text(textwrap.dedent(FAKE_CODEX), encoding="utf-8")

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def context(
        self,
        *,
        max_concurrency: int = 3,
        max_agents: int = 8,
        sandbox: str = "read-only",
        timeout_seconds: float | None = None,
    ) -> WorkflowContext:
        run_dir = self.root / f"run-{len(list(self.root.glob('run-*')))}"
        run_dir.mkdir()
        return WorkflowContext(
            args=("one", "two"),
            codex_command=(sys.executable, str(self.fake)),
            cwd=self.root,
            run_dir=run_dir,
            model="gpt-5.6-luna",
            effort="high",
            sandbox=sandbox,
            max_concurrency=max_concurrency,
            max_agents=max_agents,
            timeout_seconds=timeout_seconds,
        )

    async def test_agent_returns_text_and_preserves_artifacts(self) -> None:
        context = self.context()
        result = await context.agent("inspect this", label="probe")

        self.assertEqual(result.text, "answer:inspect this")
        self.assertIsNone(result.data)
        self.assertEqual(result.model, "gpt-5.6-luna")
        call_dir = Path(result.artifacts)
        self.assertEqual((call_dir / "prompt.txt").read_text(), "inspect this")
        metadata = json.loads((call_dir / "metadata.json").read_text())
        self.assertEqual(metadata["sandbox"], "read-only")
        self.assertIn("--ephemeral", metadata["command"])

    async def test_structured_output_is_available_to_dynamic_control_flow(self) -> None:
        context = self.context()
        schema = {
            "type": "object",
            "properties": {"prompt": {"type": "string"}},
            "required": ["prompt"],
            "additionalProperties": False,
        }

        first = await context.agent("branch-value", schema=schema)
        if first.data["prompt"] == "branch-value":
            second = await context.agent("chosen-branch")
        else:
            self.fail("workflow did not take the expected dynamic branch")

        self.assertEqual(second.text, "answer:chosen-branch")
        self.assertEqual(context.calls_started, 2)

    async def test_parallel_respects_the_shared_concurrency_limit(self) -> None:
        context = self.context(max_concurrency=2)
        started = asyncio.get_running_loop().time()
        results = await context.parallel(
            *(context.agent("sleep:0.2") for _ in range(3))
        )
        elapsed = asyncio.get_running_loop().time() - started

        self.assertEqual(len(results), 3)
        self.assertGreaterEqual(elapsed, 0.35)

    async def test_agent_limit_stops_dynamic_runaway(self) -> None:
        context = self.context(max_agents=1)
        await context.agent("first")

        with self.assertRaisesRegex(WorkflowError, "agent call limit"):
            await context.agent("second")

    async def test_parallel_cancels_siblings_when_one_agent_fails(self) -> None:
        context = self.context(max_concurrency=2)
        started = asyncio.get_running_loop().time()

        with self.assertRaises(AgentExecutionError):
            await context.parallel(
                context.agent("fail-now"),
                context.agent("sleep:1"),
            )

        elapsed = asyncio.get_running_loop().time() - started
        self.assertLess(elapsed, 0.8)
        journal = (context.run_dir / "events.jsonl").read_text(encoding="utf-8")
        self.assertIn('"event": "agent_cancelled"', journal)

    async def test_workflow_cannot_raise_its_sandbox_ceiling(self) -> None:
        context = self.context(sandbox="read-only")

        with self.assertRaisesRegex(WorkflowError, "above the read-only"):
            await context.agent("write", sandbox="workspace-write")

    async def test_timeout_and_nonzero_exit_are_reported(self) -> None:
        timeout_context = self.context(timeout_seconds=0.05)
        with self.assertRaisesRegex(AgentExecutionError, "timeout"):
            await timeout_context.agent("sleep:0.5")

        failure_context = self.context()
        with self.assertRaisesRegex(AgentExecutionError, "code 7"):
            await failure_context.agent("fail")

    async def test_loaded_workflow_owns_dynamic_control_flow_and_final_state(self) -> None:
        workflow = self.root / "workflow.py"
        workflow.write_text(
            textwrap.dedent(
                """
                async def run(context):
                    first = await context.agent(context.args[0])
                    if first.text == "answer:branch":
                        second = await context.agent("selected")
                        return {"selected": second.text}
                    return {"selected": None}
                """
            ),
            encoding="utf-8",
        )
        arguments = _parser().parse_args(
            [
                str(workflow),
                "--arg",
                "branch",
                "--cwd",
                str(self.root),
                "--run-root",
                str(self.root / "runs"),
                "--max-agents",
                "2",
            ]
        )

        with patch(
            "codex_workflow._resolve_codex_command",
            return_value=(sys.executable, str(self.fake)),
        ):
            result, run_dir = await _run(arguments)

        self.assertEqual(result, {"selected": "answer:selected"})
        state = json.loads((run_dir / "run.json").read_text(encoding="utf-8"))
        self.assertEqual(state["state"], "completed")
        self.assertEqual(state["calls_started"], 2)


class LauncherTests(unittest.TestCase):
    def test_explicit_executable_is_preserved(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            executable = Path(temporary) / "codex-test"
            executable.write_text("", encoding="utf-8")

            command = _resolve_codex_command(str(executable))

        self.assertEqual(command, (str(executable.resolve()),))

    @unittest.skipUnless(sys.platform == "win32", "Windows launcher behavior")
    def test_explicit_batch_launcher_uses_cmd(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            launcher = Path(temporary) / "codex-test.cmd"
            launcher.write_text("@exit /b 0\n", encoding="utf-8")

            command = _resolve_codex_command(str(launcher))

        self.assertEqual(command[-1], str(launcher.resolve()))
        self.assertEqual(command[1:4], ("/d", "/s", "/c"))


if __name__ == "__main__":
    unittest.main()
