#!/usr/bin/env python3
from __future__ import annotations

import argparse
import asyncio
import importlib.util
import inspect
import json
import os
import shutil
import sys
import time
import traceback
import uuid
from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from pathlib import Path
from types import ModuleType
from typing import Any, Awaitable, Iterable, Sequence


EFFORTS = {"low", "medium", "high", "xhigh"}
SANDBOX_RANK = {
    "read-only": 0,
    "workspace-write": 1,
    "danger-full-access": 2,
}


class WorkflowError(RuntimeError):
    pass


class AgentExecutionError(WorkflowError):
    def __init__(self, message: str, *, call_id: str, call_dir: Path) -> None:
        super().__init__(message)
        self.call_id = call_id
        self.call_dir = call_dir


@dataclass(frozen=True)
class AgentResult:
    call_id: str
    text: str
    data: Any
    model: str
    effort: str
    sandbox: str
    duration_seconds: float
    artifacts: str


def _utc_now() -> str:
    return datetime.now(UTC).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def _write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f"{path.name}.{uuid.uuid4().hex}.tmp")
    temporary.write_text(
        json.dumps(value, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    os.replace(temporary, path)


def _json_value(value: Any) -> Any:
    try:
        json.dumps(value)
    except TypeError as error:
        raise WorkflowError("workflow result must be JSON serializable") from error
    return value


def _tail(text: str, limit: int = 2000) -> str:
    if len(text) <= limit:
        return text
    return text[-limit:]


def _resolve_codex_command(executable: str) -> tuple[str, ...]:
    candidate = Path(executable)
    if candidate.parent != Path("."):
        resolved = str(candidate.resolve())
        if os.name == "nt" and candidate.suffix.casefold() in {".cmd", ".bat"}:
            return (os.environ.get("COMSPEC", "cmd.exe"), "/d", "/s", "/c", resolved)
        if os.name == "nt" and candidate.suffix.casefold() == ".ps1":
            raise WorkflowError(
                "PowerShell Codex launchers are not supported; select codex.exe "
                "or codex.cmd"
            )
        return (resolved,)

    if os.name == "nt":
        suffix = candidate.suffix.casefold()
        if suffix in {".cmd", ".bat"}:
            batch = shutil.which(executable)
            if batch:
                return (
                    os.environ.get("COMSPEC", "cmd.exe"),
                    "/d",
                    "/s",
                    "/c",
                    batch,
                )
        if suffix == ".ps1":
            raise WorkflowError(
                "PowerShell Codex launchers are not supported; select codex.exe "
                "or codex.cmd"
            )
        if suffix == ".exe":
            native = shutil.which(executable)
            if native:
                return (native,)

        batch = shutil.which(f"{executable}.cmd") or shutil.which(f"{executable}.bat")
        if batch:
            return (
                os.environ.get("COMSPEC", "cmd.exe"),
                "/d",
                "/s",
                "/c",
                batch,
            )
        native = shutil.which(f"{executable}.exe")
        if native:
            return (native,)

    resolved = shutil.which(executable)
    if resolved:
        return (resolved,)
    raise WorkflowError(f"could not find Codex executable: {executable}")


async def _terminate_process(
    process: asyncio.subprocess.Process,
) -> tuple[bytes, bytes]:
    if process.returncode is None and os.name == "nt":
        system_root = os.environ.get("SystemRoot", r"C:\Windows")
        taskkill = str(Path(system_root) / "System32" / "taskkill.exe")
        try:
            killer = await asyncio.create_subprocess_exec(
                taskkill,
                "/PID",
                str(process.pid),
                "/T",
                "/F",
                stdout=asyncio.subprocess.DEVNULL,
                stderr=asyncio.subprocess.DEVNULL,
            )
            await killer.wait()
        except OSError:
            pass

    if process.returncode is None:
        try:
            process.kill()
        except ProcessLookupError:
            pass
    return await process.communicate()


class WorkflowContext:
    def __init__(
        self,
        *,
        args: Sequence[str],
        codex_command: Sequence[str],
        cwd: Path,
        run_dir: Path,
        model: str,
        effort: str,
        sandbox: str,
        max_concurrency: int,
        max_agents: int,
        timeout_seconds: float | None,
    ) -> None:
        if not codex_command:
            raise WorkflowError("codex command cannot be empty")
        if effort not in EFFORTS:
            raise WorkflowError(f"unsupported reasoning effort: {effort}")
        if sandbox not in SANDBOX_RANK:
            raise WorkflowError(f"unsupported sandbox: {sandbox}")
        if max_concurrency < 1:
            raise WorkflowError("max concurrency must be at least 1")
        if max_agents < 1:
            raise WorkflowError("max agents must be at least 1")
        if timeout_seconds is not None and timeout_seconds <= 0:
            raise WorkflowError("timeout must be greater than zero")

        self.args = tuple(args)
        self.cwd = cwd
        self.run_dir = run_dir
        self.default_model = model
        self.default_effort = effort
        self.max_sandbox = sandbox
        self.max_agents = max_agents
        self.timeout_seconds = timeout_seconds
        self._codex_command = tuple(codex_command)
        self._semaphore = asyncio.Semaphore(max_concurrency)
        self._state_lock = asyncio.Lock()
        self._journal_lock = asyncio.Lock()
        self._calls_started = 0

    @property
    def calls_started(self) -> int:
        return self._calls_started

    async def parallel(
        self,
        *calls: Awaitable[AgentResult] | Iterable[Awaitable[AgentResult]],
    ) -> list[AgentResult]:
        if len(calls) == 1 and not inspect.isawaitable(calls[0]):
            selected = list(calls[0])
        else:
            selected = list(calls)
        tasks = [asyncio.ensure_future(call) for call in selected]
        try:
            return list(await asyncio.gather(*tasks))
        except BaseException:
            for task in tasks:
                if not task.done():
                    task.cancel()
            await asyncio.gather(*tasks, return_exceptions=True)
            raise

    async def agent(
        self,
        prompt: str,
        *,
        model: str | None = None,
        effort: str | None = None,
        sandbox: str | None = None,
        cwd: str | Path | None = None,
        schema: dict[str, Any] | None = None,
        timeout_seconds: float | None = None,
        label: str | None = None,
    ) -> AgentResult:
        if not isinstance(prompt, str) or not prompt.strip():
            raise WorkflowError("agent prompt must be a non-empty string")

        selected_model = model or self.default_model
        selected_effort = effort or self.default_effort
        selected_sandbox = sandbox or self.max_sandbox
        selected_cwd = Path(cwd).resolve() if cwd is not None else self.cwd
        selected_timeout = (
            timeout_seconds if timeout_seconds is not None else self.timeout_seconds
        )

        if not selected_model.strip():
            raise WorkflowError("agent model cannot be empty")
        if selected_effort not in EFFORTS:
            raise WorkflowError(f"unsupported reasoning effort: {selected_effort}")
        if selected_sandbox not in SANDBOX_RANK:
            raise WorkflowError(f"unsupported sandbox: {selected_sandbox}")
        if SANDBOX_RANK[selected_sandbox] > SANDBOX_RANK[self.max_sandbox]:
            raise WorkflowError(
                f"agent requested {selected_sandbox}, above the "
                f"{self.max_sandbox} workflow ceiling"
            )
        if selected_timeout is not None and selected_timeout <= 0:
            raise WorkflowError("timeout must be greater than zero")
        if not selected_cwd.is_dir():
            raise WorkflowError(f"agent working directory does not exist: {selected_cwd}")
        if schema is not None and not isinstance(schema, dict):
            raise WorkflowError("agent schema must be a JSON object")

        async with self._state_lock:
            if self._calls_started >= self.max_agents:
                raise WorkflowError(
                    f"workflow exceeded its {self.max_agents} agent call limit"
                )
            self._calls_started += 1
            call_number = self._calls_started

        call_id = f"agent-{call_number:04d}"
        call_dir = self.run_dir / "agents" / call_id
        call_dir.mkdir(parents=True, exist_ok=False)
        (call_dir / "prompt.txt").write_text(prompt, encoding="utf-8")
        if schema is not None:
            _write_json(call_dir / "schema.json", schema)

        await self._record(
            "agent_scheduled",
            call_id=call_id,
            label=label,
            model=selected_model,
            effort=selected_effort,
            sandbox=selected_sandbox,
            cwd=str(selected_cwd),
        )

        async with self._semaphore:
            return await self._execute_agent(
                call_id=call_id,
                call_dir=call_dir,
                prompt=prompt,
                model=selected_model,
                effort=selected_effort,
                sandbox=selected_sandbox,
                cwd=selected_cwd,
                schema=schema,
                timeout_seconds=selected_timeout,
                label=label,
            )

    async def _execute_agent(
        self,
        *,
        call_id: str,
        call_dir: Path,
        prompt: str,
        model: str,
        effort: str,
        sandbox: str,
        cwd: Path,
        schema: dict[str, Any] | None,
        timeout_seconds: float | None,
        label: str | None,
    ) -> AgentResult:
        final_path = call_dir / "final.txt"
        events_path = call_dir / "events.jsonl"
        stderr_path = call_dir / "stderr.txt"
        metadata_path = call_dir / "metadata.json"

        command = [
            *self._codex_command,
            "exec",
            "--json",
            "--ephemeral",
            "--color",
            "never",
            "--model",
            model,
            "--sandbox",
            sandbox,
            "--cd",
            str(cwd),
            "--config",
            f'model_reasoning_effort="{effort}"',
            "--config",
            'approval_policy="never"',
            "--output-last-message",
            str(final_path),
        ]
        if schema is not None:
            command.extend(["--output-schema", str(call_dir / "schema.json")])
        command.append("-")

        started_at = _utc_now()
        started_clock = time.perf_counter()
        await self._record(
            "agent_started",
            call_id=call_id,
            label=label,
            started_at=started_at,
        )

        try:
            process = await asyncio.create_subprocess_exec(
                *command,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
        except OSError as error:
            await self._record(
                "agent_failed",
                call_id=call_id,
                error=f"could not start Codex: {error}",
            )
            raise AgentExecutionError(
                f"could not start Codex for {call_id}: {error}",
                call_id=call_id,
                call_dir=call_dir,
            ) from error

        try:
            communication = process.communicate(prompt.encode("utf-8"))
            if timeout_seconds is None:
                stdout, stderr = await communication
            else:
                stdout, stderr = await asyncio.wait_for(
                    communication,
                    timeout=timeout_seconds,
                )
        except asyncio.TimeoutError as error:
            stdout, stderr = await _terminate_process(process)
            events_path.write_bytes(stdout)
            stderr_path.write_bytes(stderr)
            duration = time.perf_counter() - started_clock
            await self._record(
                "agent_failed",
                call_id=call_id,
                error="timeout",
                duration_seconds=round(duration, 3),
            )
            raise AgentExecutionError(
                f"{call_id} exceeded its {timeout_seconds:g} second timeout",
                call_id=call_id,
                call_dir=call_dir,
            ) from error
        except asyncio.CancelledError:
            stdout, stderr = await _terminate_process(process)
            events_path.write_bytes(stdout)
            stderr_path.write_bytes(stderr)
            await self._record("agent_cancelled", call_id=call_id)
            raise

        events_path.write_bytes(stdout)
        stderr_path.write_bytes(stderr)
        duration = time.perf_counter() - started_clock
        metadata = {
            "schema_version": 1,
            "call_id": call_id,
            "label": label,
            "model": model,
            "effort": effort,
            "sandbox": sandbox,
            "cwd": str(cwd),
            "started_at": started_at,
            "finished_at": _utc_now(),
            "duration_seconds": round(duration, 3),
            "exit_code": process.returncode,
            "command": command,
        }
        _write_json(metadata_path, metadata)

        if process.returncode != 0:
            detail = _tail(stderr.decode("utf-8", errors="replace")).strip()
            await self._record(
                "agent_failed",
                call_id=call_id,
                exit_code=process.returncode,
                duration_seconds=round(duration, 3),
            )
            suffix = f": {detail}" if detail else ""
            raise AgentExecutionError(
                f"{call_id} exited with code {process.returncode}{suffix}",
                call_id=call_id,
                call_dir=call_dir,
            )

        if not final_path.is_file():
            await self._record(
                "agent_failed",
                call_id=call_id,
                error="missing final response",
                duration_seconds=round(duration, 3),
            )
            raise AgentExecutionError(
                f"{call_id} completed without a final response",
                call_id=call_id,
                call_dir=call_dir,
            )

        text = final_path.read_text(encoding="utf-8")
        data: Any = None
        if schema is not None:
            try:
                data = json.loads(text)
            except json.JSONDecodeError as error:
                await self._record(
                    "agent_failed",
                    call_id=call_id,
                    error="invalid structured output",
                    duration_seconds=round(duration, 3),
                )
                raise AgentExecutionError(
                    f"{call_id} returned invalid JSON for its schema",
                    call_id=call_id,
                    call_dir=call_dir,
                ) from error

        result = AgentResult(
            call_id=call_id,
            text=text,
            data=data,
            model=model,
            effort=effort,
            sandbox=sandbox,
            duration_seconds=round(duration, 3),
            artifacts=str(call_dir),
        )
        _write_json(call_dir / "result.json", asdict(result))
        await self._record(
            "agent_completed",
            call_id=call_id,
            duration_seconds=result.duration_seconds,
        )
        return result

    async def _record(self, event: str, **fields: Any) -> None:
        record = {
            "schema_version": 1,
            "time": _utc_now(),
            "event": event,
            **fields,
        }
        line = json.dumps(record, ensure_ascii=False) + "\n"
        async with self._journal_lock:
            with (self.run_dir / "events.jsonl").open("a", encoding="utf-8") as handle:
                handle.write(line)


def _load_workflow(path: Path) -> ModuleType:
    name = f"compass_workflow_{uuid.uuid4().hex}"
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise WorkflowError(f"could not load workflow: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _run_id(workflow: Path) -> str:
    timestamp = datetime.now(UTC).strftime("%Y%m%dT%H%M%SZ")
    stem = "".join(character if character.isalnum() else "-" for character in workflow.stem)
    stem = stem.strip("-").lower() or "workflow"
    return f"{timestamp}-{stem}-{uuid.uuid4().hex[:8]}"


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run a dynamic Python workflow over bounded Codex CLI agents."
    )
    parser.add_argument("workflow", help="Python file exporting run(context)")
    parser.add_argument(
        "--arg",
        action="append",
        default=[],
        help="Workflow argument exposed through context.args. Repeat as needed.",
    )
    parser.add_argument("--model", default="gpt-5.6-luna")
    parser.add_argument("--effort", choices=sorted(EFFORTS), default="high")
    parser.add_argument(
        "--sandbox",
        choices=tuple(SANDBOX_RANK),
        default="read-only",
        help="Default and maximum sandbox available to workflow agents.",
    )
    parser.add_argument("--max-concurrency", type=int, default=3)
    parser.add_argument("--max-agents", type=int, default=32)
    parser.add_argument("--timeout-seconds", type=float)
    parser.add_argument("--cwd", default=".")
    parser.add_argument("--run-root")
    parser.add_argument("--codex", default="codex", help=argparse.SUPPRESS)
    return parser


async def _run(args: argparse.Namespace) -> tuple[Any, Path]:
    workflow_path = Path(args.workflow).resolve()
    if not workflow_path.is_file():
        raise WorkflowError(f"workflow file does not exist: {workflow_path}")
    cwd = Path(args.cwd).resolve()
    if not cwd.is_dir():
        raise WorkflowError(f"working directory does not exist: {cwd}")

    run_root = (
        Path(args.run_root).resolve()
        if args.run_root
        else cwd / ".local" / "workflow-runs"
    )
    run_dir = run_root / _run_id(workflow_path)
    run_dir.mkdir(parents=True, exist_ok=False)

    state_path = run_dir / "run.json"
    state = {
        "schema_version": 1,
        "state": "running",
        "workflow": str(workflow_path),
        "args": args.arg,
        "cwd": str(cwd),
        "run_dir": str(run_dir),
        "model": args.model,
        "effort": args.effort,
        "sandbox": args.sandbox,
        "max_concurrency": args.max_concurrency,
        "max_agents": args.max_agents,
        "timeout_seconds": args.timeout_seconds,
        "started_at": _utc_now(),
    }
    _write_json(state_path, state)

    context = WorkflowContext(
        args=args.arg,
        codex_command=_resolve_codex_command(args.codex),
        cwd=cwd,
        run_dir=run_dir,
        model=args.model,
        effort=args.effort,
        sandbox=args.sandbox,
        max_concurrency=args.max_concurrency,
        max_agents=args.max_agents,
        timeout_seconds=args.timeout_seconds,
    )

    try:
        module = _load_workflow(workflow_path)
        entrypoint = getattr(module, "run", None)
        if entrypoint is None or not callable(entrypoint):
            raise WorkflowError("workflow must export a callable run(context)")
        result = entrypoint(context)
        if inspect.isawaitable(result):
            result = await result
        result = _json_value(result)
    except BaseException as error:
        state.update(
            {
                "state": "cancelled"
                if isinstance(error, (KeyboardInterrupt, asyncio.CancelledError))
                else "failed",
                "finished_at": _utc_now(),
                "calls_started": context.calls_started,
                "error": f"{type(error).__name__}: {error}",
            }
        )
        _write_json(state_path, state)
        (run_dir / "error.txt").write_text(traceback.format_exc(), encoding="utf-8")
        raise

    _write_json(run_dir / "result.json", result)
    state.update(
        {
            "state": "completed",
            "finished_at": _utc_now(),
            "calls_started": context.calls_started,
        }
    )
    _write_json(state_path, state)
    return result, run_dir


def main(argv: Sequence[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        result, run_dir = asyncio.run(_run(args))
    except KeyboardInterrupt:
        print("workflow cancelled", file=sys.stderr)
        return 130
    except Exception as error:
        print(f"workflow failed: {error}", file=sys.stderr)
        if isinstance(error, AgentExecutionError):
            print(f"artifacts: {error.call_dir}", file=sys.stderr)
        return 1

    print(json.dumps(result, indent=2, ensure_ascii=False))
    print(f"artifacts: {run_dir}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
