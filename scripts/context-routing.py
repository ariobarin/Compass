#!/usr/bin/env python3
"""Validate and trace Compass skill routing without loading skill bodies."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

STOP_WORDS = {
    "a", "an", "and", "as", "at", "be", "before", "by", "for", "from",
    "in", "into", "is", "it", "of", "on", "one", "or", "the", "then",
    "this", "through", "to", "when", "with",
}


def normalize(value: str) -> str:
    return " ".join(re.findall(r"[a-z0-9]+", value.lower()))


def frontmatter_value(text: str, key: str) -> str | None:
    match = re.match(r"^---\r?\n(.*?)\r?\n---(?:\r?\n|$)", text, re.DOTALL)
    if not match:
        return None
    field = re.search(rf"^{re.escape(key)}:\s*(.+)$", match.group(1), re.MULTILINE)
    if not field:
        return None
    value = field.group(1).strip()
    if value.startswith('"') and value.endswith('"'):
        try:
            return str(json.loads(value))
        except json.JSONDecodeError:
            return value[1:-1]
    return value


def discover_skills(root: Path) -> dict[str, dict[str, Any]]:
    skills_root = root / "codex" / "skills"
    discovered: dict[str, dict[str, Any]] = {}
    if not skills_root.is_dir():
        return discovered
    for skill_dir in sorted(path for path in skills_root.iterdir() if path.is_dir()):
        skill_path = skill_dir / "SKILL.md"
        if not skill_path.is_file():
            continue
        text = skill_path.read_text(encoding="utf-8")
        name = frontmatter_value(text, "name") or skill_dir.name
        description = frontmatter_value(text, "description") or ""
        discovered[name] = {
            "name": name,
            "description": description,
            "path": skill_path.relative_to(root).as_posix(),
            "bytes": len(text.encode("utf-8")),
            "estimated_tokens": (len(text) + 3) // 4,
        }
    return discovered


def load_manifest(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def validate_catalog(root: Path, manifest: dict[str, Any]) -> tuple[list[str], list[dict[str, Any]]]:
    errors: list[str] = []
    if manifest.get("schema_version") != 1:
        errors.append("unsupported guidance-routing manifest schema")

    phases = manifest.get("phases")
    mutations = manifest.get("mutation_levels")
    if not isinstance(phases, list) or not phases or not all(isinstance(item, str) for item in phases):
        errors.append("guidance-routing phases must be a non-empty string list")
        phases = []
    if not isinstance(mutations, list) or not mutations or not all(isinstance(item, str) for item in mutations):
        errors.append("guidance-routing mutation_levels must be a non-empty string list")
        mutations = []

    entries = manifest.get("skills")
    if not isinstance(entries, list):
        errors.append("guidance-routing skills must be a list")
        entries = []

    discovered = discover_skills(root)
    records: list[dict[str, Any]] = []
    seen: set[str] = set()

    for index, entry in enumerate(entries):
        label = f"guidance-routing skills[{index}]"
        if not isinstance(entry, dict):
            errors.append(f"{label} must be an object")
            continue
        name = entry.get("name")
        if not isinstance(name, str) or not name:
            errors.append(f"{label} missing name")
            continue
        if name in seen:
            errors.append(f"guidance-routing has duplicate skill: {name}")
            continue
        seen.add(name)
        if name not in discovered:
            errors.append(f"guidance-routing references unknown skill: {name}")
            continue

        entry_phases = entry.get("phases")
        entry_mutations = entry.get("mutation_levels")
        signals = entry.get("signals")
        exclusions = entry.get("exclusions")
        if not isinstance(entry_phases, list) or not entry_phases:
            errors.append(f"guidance-routing skill {name} needs at least one phase")
            entry_phases = []
        if not isinstance(entry_mutations, list) or not entry_mutations:
            errors.append(f"guidance-routing skill {name} needs at least one mutation level")
            entry_mutations = []
        if not isinstance(signals, list) or len(signals) < 2 or not all(isinstance(item, str) and item.strip() for item in signals):
            errors.append(f"guidance-routing skill {name} needs at least two string signals")
            signals = []
        if not isinstance(exclusions, list) or not all(isinstance(item, str) and item.strip() for item in exclusions):
            errors.append(f"guidance-routing skill {name} exclusions must be a string list")
            exclusions = []

        unknown_phases = sorted(set(entry_phases) - set(phases))
        unknown_mutations = sorted(set(entry_mutations) - set(mutations))
        if unknown_phases:
            errors.append(f"guidance-routing skill {name} has unknown phases: {', '.join(unknown_phases)}")
        if unknown_mutations:
            errors.append(f"guidance-routing skill {name} has unknown mutation levels: {', '.join(unknown_mutations)}")
        if len({normalize(item) for item in signals}) != len(signals):
            errors.append(f"guidance-routing skill {name} has duplicate signals")
        if len({normalize(item) for item in exclusions}) != len(exclusions):
            errors.append(f"guidance-routing skill {name} has duplicate exclusions")

        records.append({**discovered[name], **entry})

    missing = sorted(set(discovered) - seen)
    for name in missing:
        errors.append(f"guidance-routing missing skill: {name}")

    return errors, records


def duplicate_signals(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    owners: dict[str, list[str]] = defaultdict(list)
    labels: dict[str, str] = {}
    for record in records:
        for signal in record["signals"]:
            key = normalize(signal)
            labels.setdefault(key, signal)
            owners[key].append(record["name"])
    return [
        {"signal": labels[key], "skills": sorted(names)}
        for key, names in sorted(owners.items())
        if len(set(names)) > 1
    ]


def score_record(record: dict[str, Any], task: str) -> tuple[int, list[str], list[str]] | None:
    task_normalized = normalize(task)
    task_tokens = set(task_normalized.split())
    for exclusion in record["exclusions"]:
        if normalize(exclusion) in task_normalized:
            return None

    score = 0
    matched_signals: list[str] = []
    for signal in record["signals"]:
        normalized_signal = normalize(signal)
        signal_tokens = normalized_signal.split()
        if normalized_signal in task_normalized:
            score += 12 + len(signal_tokens)
            matched_signals.append(signal)
            continue
        overlap = sum(1 for token in signal_tokens if token in task_tokens)
        if overlap == len(signal_tokens) and overlap:
            score += 8 + overlap
            matched_signals.append(signal)
        elif overlap >= 2:
            score += overlap * 2

    name_terms = [token for token in normalize(record["name"]).split() if token not in STOP_WORDS]
    matched_name_terms = sorted(set(name_terms) & task_tokens)
    score += len(matched_name_terms) * 4

    description_terms = [
        token for token in normalize(record["description"]).split()
        if token not in STOP_WORDS and len(token) > 2
    ]
    matched_description_terms = sorted(set(description_terms) & task_tokens)
    score += min(len(matched_description_terms), 5)

    if score < 3:
        return None
    return score, matched_signals, matched_name_terms + matched_description_terms[:5]


def trace_catalog(
    records: list[dict[str, Any]],
    task: str,
    phase: str | None,
    mutation: str | None,
    limit: int,
) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    for record in records:
        if phase and phase not in record["phases"]:
            continue
        if mutation and mutation not in record["mutation_levels"]:
            continue
        scored = score_record(record, task)
        if scored is None:
            continue
        score, matched_signals, matched_terms = scored
        reasons: list[str] = []
        if matched_signals:
            reasons.append("signals=" + ", ".join(matched_signals))
        if matched_terms:
            reasons.append("terms=" + ", ".join(sorted(set(matched_terms))))
        if phase:
            reasons.append(f"phase={phase}")
        if mutation:
            reasons.append(f"mutation={mutation}")
        results.append({
            "name": record["name"],
            "description": record["description"],
            "path": record["path"],
            "score": score,
            "estimated_tokens": record["estimated_tokens"],
            "reason": "; ".join(reasons) or "catalog match",
        })
    return sorted(results, key=lambda item: (-item["score"], item["estimated_tokens"], item["name"]))[:limit]


def status_payload(records: list[dict[str, Any]]) -> dict[str, Any]:
    largest = sorted(records, key=lambda item: (-item["estimated_tokens"], item["name"]))[:5]
    return {
        "schema_version": 1,
        "skill_count": len(records),
        "skill_core_bytes": sum(item["bytes"] for item in records),
        "skill_core_estimated_tokens": sum(item["estimated_tokens"] for item in records),
        "largest_skill_cores": [
            {
                "name": item["name"],
                "estimated_tokens": item["estimated_tokens"],
                "path": item["path"],
            }
            for item in largest
        ],
        "duplicate_signals": duplicate_signals(records),
    }


def print_status(payload: dict[str, Any], plain: bool) -> None:
    if plain:
        print(f"skill_count={payload['skill_count']}")
        print(f"skill_core_bytes={payload['skill_core_bytes']}")
        print(f"skill_core_estimated_tokens={payload['skill_core_estimated_tokens']}")
        print(f"duplicate_signal_count={len(payload['duplicate_signals'])}")
        return
    print(f"skills: {payload['skill_count']}")
    print(f"skill core bytes: {payload['skill_core_bytes']}")
    print(f"skill core estimated tokens: {payload['skill_core_estimated_tokens']}")
    print("largest skill cores:")
    for item in payload["largest_skill_cores"]:
        print(f"  {item['name']}: ~{item['estimated_tokens']} tokens ({item['path']})")
    duplicates = payload["duplicate_signals"]
    print("duplicate routing signals: " + (str(len(duplicates)) if duplicates else "none"))
    for item in duplicates:
        print(f"  {item['signal']}: {', '.join(item['skills'])}")


def print_trace(payload: dict[str, Any], plain: bool) -> None:
    if plain:
        print(f"task={payload['task']}")
        print(f"phase={payload['phase'] or ''}")
        print(f"mutation={payload['mutation'] or ''}")
        for index, item in enumerate(payload["results"], start=1):
            print(f"selection_{index}={item['name']}|{item['score']}|{item['estimated_tokens']}|{item['reason']}")
        return
    print(f"task: {payload['task']}")
    if payload["phase"]:
        print(f"phase: {payload['phase']}")
    if payload["mutation"]:
        print(f"mutation: {payload['mutation']}")
    print("selected guidance:")
    if not payload["results"]:
        print("  none")
    for item in payload["results"]:
        print(f"  {item['name']}: score {item['score']}, ~{item['estimated_tokens']} tokens")
        print(f"    {item['reason']}")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("check", "status", "trace"))
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--task")
    parser.add_argument("--phase")
    parser.add_argument("--mutation")
    parser.add_argument("--limit", type=int, default=3)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--plain", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    root = args.root.resolve()
    manifest_path = (args.manifest or root / "manifests" / "guidance-routing.json").resolve()
    if args.json and args.plain:
        print("choose either --json or --plain", file=sys.stderr)
        return 2
    if args.limit < 1 or args.limit > 10:
        print("--limit must be between 1 and 10", file=sys.stderr)
        return 2
    try:
        manifest = load_manifest(manifest_path)
    except (OSError, json.JSONDecodeError) as error:
        print(f"invalid guidance-routing manifest: {error}")
        return 1

    errors, records = validate_catalog(root, manifest)
    if errors:
        for error in errors:
            print(error)
        return 1

    if args.action == "check":
        if args.json:
            print(json.dumps({"ok": True, "skill_count": len(records)}, indent=2))
        elif args.plain:
            print("ok=true")
            print(f"skill_count={len(records)}")
        else:
            print("guidance routing: ok")
        return 0

    if args.action == "status":
        payload = status_payload(records)
        if args.json:
            print(json.dumps(payload, indent=2))
        else:
            print_status(payload, args.plain)
        return 0

    if not args.task:
        print("trace requires --task", file=sys.stderr)
        return 2
    phases = set(manifest["phases"])
    mutations = set(manifest["mutation_levels"])
    if args.phase and args.phase not in phases:
        print(f"unknown phase: {args.phase}", file=sys.stderr)
        return 2
    if args.mutation and args.mutation not in mutations:
        print(f"unknown mutation level: {args.mutation}", file=sys.stderr)
        return 2

    payload = {
        "schema_version": 1,
        "task": args.task,
        "phase": args.phase,
        "mutation": args.mutation,
        "results": trace_catalog(records, args.task, args.phase, args.mutation, args.limit),
    }
    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        print_trace(payload, args.plain)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
