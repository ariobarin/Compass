from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "context-routing.py"
SPEC = importlib.util.spec_from_file_location("context_routing", MODULE_PATH)
assert SPEC and SPEC.loader
context_routing = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(context_routing)


class ContextRoutingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = context_routing.load_manifest(ROOT / "manifests" / "guidance-routing.json")
        cls.errors, cls.records = context_routing.validate_catalog(ROOT, cls.manifest)

    def test_reviewed_catalog_covers_every_skill(self) -> None:
        self.assertEqual(self.errors, [])
        discovered = context_routing.discover_skills(ROOT)
        self.assertEqual({record["name"] for record in self.records}, set(discovered))

    def test_pr_review_trace_prefers_pr_review_loop(self) -> None:
        results = context_routing.trace_catalog(
            self.records,
            "review PR 214 for current-head merge readiness",
            "verify",
            "public",
            3,
        )
        self.assertTrue(results)
        self.assertEqual(results[0]["name"], "pr-review-loop")
        self.assertIn("merge readiness", results[0]["reason"])

    def test_prd_trace_prefers_to_prd(self) -> None:
        results = context_routing.trace_catalog(
            self.records,
            "write a product requirements document for the new export flow",
            "plan",
            "none",
            3,
        )
        self.assertTrue(results)
        self.assertEqual(results[0]["name"], "to-prd")

    def test_exclusion_prevents_frontend_marketing_skill_for_dashboard(self) -> None:
        results = context_routing.trace_catalog(
            self.records,
            "redesign the dashboard app flow",
            "plan",
            "none",
            10,
        )
        self.assertNotIn("design-taste-frontend", {result["name"] for result in results})

    def test_validation_reports_missing_skill_metadata(self) -> None:
        broken = copy.deepcopy(self.manifest)
        broken["skills"] = [entry for entry in broken["skills"] if entry["name"] != "using-goals"]
        errors, _ = context_routing.validate_catalog(ROOT, broken)
        self.assertIn("guidance-routing missing skill: using-goals", errors)

    def test_status_exposes_context_cost_and_duplicate_signals(self) -> None:
        payload = context_routing.status_payload(self.records)
        self.assertEqual(payload["skill_count"], len(self.records))
        self.assertGreater(payload["skill_core_estimated_tokens"], 0)
        self.assertIn("duplicate_signals", payload)


if __name__ == "__main__":
    unittest.main()
