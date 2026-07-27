#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import sys
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parents[1] / "codex" / "skills" / "pr-review-loop" / "scripts" / "collect-pr-state.py"
SPEC = importlib.util.spec_from_file_location("collect_pr_state", MODULE_PATH)
assert SPEC and SPEC.loader
module = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = module
SPEC.loader.exec_module(module)


def connection(nodes, has_next=False):
    return {"pageInfo": {"hasNextPage": has_next, "endCursor": "cursor" if has_next else None}, "nodes": nodes}


def fixture():
    return {
        "number": 42,
        "url": "https://github.com/example/project/pull/42",
        "title": "Improve review state",
        "state": "OPEN",
        "isDraft": False,
        "baseRefName": "main",
        "headRefName": "feature",
        "headRefOid": "newsha",
        "mergeStateStatus": "BLOCKED",
        "mergeable": "MERGEABLE",
        "reviewDecision": "CHANGES_REQUESTED",
        "comments": connection([{
            "id": "comment-1", "author": {"login": "maintainer"}, "body": "A" * 300,
            "createdAt": "2026-07-27T00:00:00Z", "updatedAt": "2026-07-27T00:00:00Z",
            "url": "https://example.test/comment-1",
        }]),
        "reviews": connection([
            {
                "id": "review-old", "author": {"login": "reviewer-old"}, "state": "APPROVED",
                "body": "Approved an earlier head.", "submittedAt": "2026-07-26T00:00:00Z",
                "commit": {"oid": "oldsha"}, "url": "https://example.test/review-old",
            },
            {
                "id": "review-current", "author": {"login": "reviewer-current"}, "state": "CHANGES_REQUESTED",
                "body": "Current finding.", "submittedAt": "2026-07-27T00:00:00Z",
                "commit": {"oid": "newsha"}, "url": "https://example.test/review-current",
            },
        ], has_next=True),
        "reviewThreads": connection([
            {
                "id": "thread-open", "isResolved": False, "isOutdated": False,
                "path": "app.py", "line": 12, "originalLine": 10,
                "comments": connection([{
                    "id": "inline-old", "author": {"login": "reviewer-old"},
                    "body": "This finding targeted the old head.",
                    "createdAt": "2026-07-26T00:00:00Z", "updatedAt": "2026-07-26T00:00:00Z",
                    "url": "https://example.test/inline-old", "commit": {"oid": "oldsha"},
                }]),
            },
            {
                "id": "thread-resolved", "isResolved": True, "isOutdated": True,
                "path": "app.py", "line": None, "originalLine": 3, "comments": connection([]),
            },
        ]),
        "commits": {"nodes": [{"commit": {
            "oid": "newsha",
            "statusCheckRollup": {
                "state": "FAILURE",
                "contexts": connection([
                    {
                        "__typename": "CheckRun", "name": "tests", "status": "COMPLETED",
                        "conclusion": "FAILURE", "detailsUrl": "https://example.test/check",
                        "startedAt": "2026-07-27T00:00:00Z", "completedAt": "2026-07-27T00:01:00Z",
                        "checkSuite": {"workflowRun": {"workflow": {"name": "ci"}}},
                    },
                    {
                        "__typename": "StatusContext", "context": "license", "state": "SUCCESS",
                        "targetUrl": "https://example.test/status", "description": "license ok",
                        "createdAt": "2026-07-27T00:00:00Z",
                    },
                ]),
            },
        }}]},
    }


class PrStateTests(unittest.TestCase):
    def test_normalizes_head_bound_state_and_stale_evidence(self):
        state = module.normalize_state("example/project", fixture(), fetched_at="2026-07-27T01:00:00Z")
        self.assertEqual(state["pull_request"]["head_sha"], "newsha")
        self.assertEqual(state["checks"]["target_sha"], "newsha")
        self.assertEqual(state["summary"]["check_count"], 2)
        self.assertEqual(state["summary"]["current_head_review_count"], 1)
        self.assertEqual(state["summary"]["stale_review_count"], 1)
        self.assertEqual(state["summary"]["unresolved_review_thread_count"], 1)
        self.assertEqual(state["summary"]["stale_inline_comment_count"], 1)
        self.assertFalse(state["complete"])
        self.assertTrue(state["pagination_truncated"]["reviews"])
        self.assertTrue(state["top_level_comments"][0]["body_truncated"])
        self.assertNotIn("body", state["top_level_comments"][0])

    def test_full_body_mode_preserves_complete_text(self):
        state = module.normalize_state("example/project", fixture(), include_bodies=True)
        self.assertEqual(state["body_mode"], "full")
        self.assertEqual(state["top_level_comments"][0]["body"], "A" * 300)
        self.assertFalse(state["top_level_comments"][0]["body_truncated"])

    def test_collect_state_uses_one_graphql_query(self):
        calls = []
        def runner(arguments):
            calls.append(arguments)
            return json.dumps({"data": {"repository": {"pullRequest": fixture()}}})
        state = module.collect_state("example/project", 42, runner=runner)
        self.assertEqual(state["pull_request"]["number"], 42)
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0][:2], ["api", "graphql"])
        self.assertIn("owner=example", calls[0])
        self.assertIn("name=project", calls[0])
        self.assertIn("number=42", calls[0])

    def test_graphql_errors_are_not_silently_accepted(self):
        with self.assertRaisesRegex(module.PrStateError, "field failed"):
            module.graphql_payload(
                "example/project", 42,
                lambda _arguments: json.dumps({"errors": [{"message": "field failed"}]})
            )

    def test_repository_must_use_owner_name(self):
        with self.assertRaisesRegex(module.PrStateError, "owner/name"):
            module.split_repository("example")


if __name__ == "__main__":
    unittest.main()
