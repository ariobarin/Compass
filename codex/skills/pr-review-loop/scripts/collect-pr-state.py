#!/usr/bin/env python3
"""Collect one normalized, head-bound GitHub pull request state snapshot."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

GRAPHQL_QUERY = r"""
query($owner:String!, $name:String!, $number:Int!) {
  repository(owner:$owner, name:$name) {
    pullRequest(number:$number) {
      number
      url
      title
      state
      isDraft
      baseRefName
      headRefName
      headRefOid
      mergeStateStatus
      mergeable
      reviewDecision
      comments(first:100) {
        pageInfo { hasNextPage endCursor }
        nodes { id author { login } body createdAt updatedAt url }
      }
      reviews(first:100) {
        pageInfo { hasNextPage endCursor }
        nodes { id author { login } state body submittedAt commit { oid } url }
      }
      reviewThreads(first:100) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          originalLine
          comments(first:100) {
            pageInfo { hasNextPage endCursor }
            nodes { id author { login } body createdAt updatedAt url commit { oid } }
          }
        }
      }
      commits(last:1) {
        nodes {
          commit {
            oid
            statusCheckRollup {
              state
              contexts(first:100) {
                pageInfo { hasNextPage endCursor }
                nodes {
                  __typename
                  ... on CheckRun {
                    name
                    status
                    conclusion
                    detailsUrl
                    startedAt
                    completedAt
                    checkSuite { workflowRun { workflow { name } } }
                  }
                  ... on StatusContext {
                    context
                    state
                    targetUrl
                    description
                    createdAt
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
"""

Runner = Callable[[list[str]], str]


class PrStateError(RuntimeError):
    pass


def run_gh(arguments: list[str]) -> str:
    try:
        result = subprocess.run(
            ["gh", *arguments],
            check=True,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
    except FileNotFoundError as error:
        raise PrStateError("GitHub CLI is required") from error
    except subprocess.CalledProcessError as error:
        detail = (error.stderr or error.stdout or "gh command failed").strip()
        raise PrStateError(detail) from error
    return result.stdout.strip()


def split_repository(value: str) -> tuple[str, str]:
    match = re.fullmatch(r"([^/\s]+)/([^/\s]+)", value.strip())
    if not match:
        raise PrStateError("repository must use owner/name")
    return match.group(1), match.group(2)


def resolve_repository(explicit: str | None, runner: Runner = run_gh) -> str:
    if explicit:
        split_repository(explicit)
        return explicit
    value = runner(["repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"])
    split_repository(value)
    return value


def graphql_payload(repository: str, number: int, runner: Runner = run_gh) -> dict[str, Any]:
    owner, name = split_repository(repository)
    raw = runner([
        "api",
        "graphql",
        "-F",
        f"owner={owner}",
        "-F",
        f"name={name}",
        "-F",
        f"number={number}",
        "-f",
        f"query={GRAPHQL_QUERY}",
    ])
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as error:
        raise PrStateError("GitHub returned invalid JSON") from error
    errors = payload.get("errors")
    if errors:
        messages = [item.get("message", "unknown GraphQL error") for item in errors if isinstance(item, dict)]
        raise PrStateError("; ".join(messages) or "GitHub GraphQL query failed")
    repository_payload = payload.get("data", {}).get("repository")
    if repository_payload is None:
        raise PrStateError(f"repository not found: {repository}")
    pull_request = repository_payload.get("pullRequest")
    if pull_request is None:
        raise PrStateError(f"pull request not found: {repository}#{number}")
    return pull_request


def author_login(node: dict[str, Any]) -> str | None:
    author = node.get("author")
    return author.get("login") if isinstance(author, dict) else None


def body_fields(body: str | None, include_bodies: bool, excerpt_chars: int) -> dict[str, Any]:
    value = body or ""
    if include_bodies:
        return {"body": value, "body_truncated": False}
    compact = " ".join(value.split())
    truncated = len(compact) > excerpt_chars
    excerpt = compact[:excerpt_chars].rstrip()
    if truncated:
        excerpt += "..."
    return {"body_excerpt": excerpt, "body_truncated": truncated}


def page_is_truncated(connection: dict[str, Any] | None) -> bool:
    if not isinstance(connection, dict):
        return False
    page_info = connection.get("pageInfo")
    return bool(isinstance(page_info, dict) and page_info.get("hasNextPage"))


def normalize_checks(pull_request: dict[str, Any]) -> dict[str, Any]:
    commits = pull_request.get("commits", {}).get("nodes") or []
    commit = commits[-1].get("commit", {}) if commits else {}
    rollup = commit.get("statusCheckRollup") or {}
    contexts = rollup.get("contexts") or {}
    items: list[dict[str, Any]] = []
    for node in contexts.get("nodes") or []:
        kind = node.get("__typename")
        if kind == "CheckRun":
            workflow = (
                ((node.get("checkSuite") or {}).get("workflowRun") or {}).get("workflow") or {}
            ).get("name")
            items.append({
                "kind": "check_run",
                "workflow": workflow,
                "name": node.get("name"),
                "status": node.get("status"),
                "conclusion": node.get("conclusion"),
                "url": node.get("detailsUrl"),
                "started_at": node.get("startedAt"),
                "completed_at": node.get("completedAt"),
            })
        elif kind == "StatusContext":
            items.append({
                "kind": "status_context",
                "workflow": None,
                "name": node.get("context"),
                "status": node.get("state"),
                "conclusion": node.get("state"),
                "url": node.get("targetUrl"),
                "description": node.get("description"),
                "created_at": node.get("createdAt"),
            })
    items.sort(key=lambda item: ((item.get("workflow") or ""), (item.get("name") or "")))
    return {
        "target_sha": commit.get("oid"),
        "overall_state": rollup.get("state"),
        "items": items,
        "truncated": page_is_truncated(contexts),
    }


def normalize_comment(
    node: dict[str, Any],
    head_sha: str,
    include_bodies: bool,
    excerpt_chars: int,
) -> dict[str, Any]:
    commit = node.get("commit")
    commit_sha = commit.get("oid") if isinstance(commit, dict) else None
    result = {
        "id": node.get("id"),
        "author": author_login(node),
        "created_at": node.get("createdAt"),
        "updated_at": node.get("updatedAt"),
        "url": node.get("url"),
        "commit_sha": commit_sha,
        "targets_current_head": commit_sha == head_sha if commit_sha else None,
    }
    result.update(body_fields(node.get("body"), include_bodies, excerpt_chars))
    return result


def normalize_state(
    repository: str,
    pull_request: dict[str, Any],
    include_bodies: bool = False,
    excerpt_chars: int = 240,
    fetched_at: str | None = None,
) -> dict[str, Any]:
    head_sha = pull_request.get("headRefOid")
    if not isinstance(head_sha, str) or not head_sha:
        raise PrStateError("pull request is missing a head SHA")

    comments_connection = pull_request.get("comments") or {}
    reviews_connection = pull_request.get("reviews") or {}
    threads_connection = pull_request.get("reviewThreads") or {}

    comments = [
        normalize_comment(node, head_sha, include_bodies, excerpt_chars)
        for node in comments_connection.get("nodes") or []
    ]

    reviews: list[dict[str, Any]] = []
    for node in reviews_connection.get("nodes") or []:
        commit = node.get("commit")
        commit_sha = commit.get("oid") if isinstance(commit, dict) else None
        review = {
            "id": node.get("id"),
            "author": author_login(node),
            "state": node.get("state"),
            "submitted_at": node.get("submittedAt"),
            "url": node.get("url"),
            "commit_sha": commit_sha,
            "targets_current_head": commit_sha == head_sha if commit_sha else None,
        }
        review.update(body_fields(node.get("body"), include_bodies, excerpt_chars))
        reviews.append(review)

    review_threads: list[dict[str, Any]] = []
    thread_comment_truncation = False
    for thread in threads_connection.get("nodes") or []:
        thread_comments = thread.get("comments") or {}
        thread_comment_truncation = thread_comment_truncation or page_is_truncated(thread_comments)
        normalized_comments = [
            normalize_comment(node, head_sha, include_bodies, excerpt_chars)
            for node in thread_comments.get("nodes") or []
        ]
        review_threads.append({
            "id": thread.get("id"),
            "resolved": bool(thread.get("isResolved")),
            "outdated": bool(thread.get("isOutdated")),
            "path": thread.get("path"),
            "line": thread.get("line"),
            "original_line": thread.get("originalLine"),
            "comments": normalized_comments,
            "comments_truncated": page_is_truncated(thread_comments),
        })

    checks = normalize_checks(pull_request)
    pagination = {
        "top_level_comments": page_is_truncated(comments_connection),
        "reviews": page_is_truncated(reviews_connection),
        "review_threads": page_is_truncated(threads_connection),
        "review_thread_comments": thread_comment_truncation,
        "checks": checks["truncated"],
    }
    stale_reviews = [
        {
            "id": review["id"],
            "author": review["author"],
            "state": review["state"],
            "commit_sha": review["commit_sha"],
            "url": review["url"],
        }
        for review in reviews
        if review["targets_current_head"] is False
    ]
    stale_inline_comments = [
        {
            "thread_id": thread["id"],
            "comment_id": comment["id"],
            "author": comment["author"],
            "commit_sha": comment["commit_sha"],
            "url": comment["url"],
        }
        for thread in review_threads
        for comment in thread["comments"]
        if comment["targets_current_head"] is False
    ]
    unresolved_threads = [thread for thread in review_threads if not thread["resolved"]]

    return {
        "schema_version": 1,
        "fetched_at": fetched_at or datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "repository": repository,
        "body_mode": "full" if include_bodies else "excerpt",
        "complete": not any(pagination.values()),
        "pagination_truncated": pagination,
        "pull_request": {
            "number": pull_request.get("number"),
            "url": pull_request.get("url"),
            "title": pull_request.get("title"),
            "state": pull_request.get("state"),
            "draft": bool(pull_request.get("isDraft")),
            "base_branch": pull_request.get("baseRefName"),
            "head_branch": pull_request.get("headRefName"),
            "head_sha": head_sha,
            "merge_state_status": pull_request.get("mergeStateStatus"),
            "mergeable": pull_request.get("mergeable"),
            "review_decision": pull_request.get("reviewDecision"),
        },
        "checks": checks,
        "reviews": reviews,
        "top_level_comments": comments,
        "review_threads": review_threads,
        "summary": {
            "check_count": len(checks["items"]),
            "review_count": len(reviews),
            "current_head_review_count": sum(review["targets_current_head"] is True for review in reviews),
            "stale_review_count": len(stale_reviews),
            "top_level_comment_count": len(comments),
            "review_thread_count": len(review_threads),
            "unresolved_review_thread_count": len(unresolved_threads),
            "stale_inline_comment_count": len(stale_inline_comments),
        },
        "stale_evidence": {
            "reviews": stale_reviews,
            "inline_comments": stale_inline_comments,
        },
    }


def collect_state(
    repository: str,
    number: int,
    include_bodies: bool = False,
    excerpt_chars: int = 240,
    runner: Runner = run_gh,
) -> dict[str, Any]:
    return normalize_state(
        repository,
        graphql_payload(repository, number, runner),
        include_bodies=include_bodies,
        excerpt_chars=excerpt_chars,
    )


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", help="GitHub repository as owner/name; defaults to the current checkout")
    parser.add_argument("--pr", type=int, required=True, help="pull request number")
    parser.add_argument("--include-bodies", action="store_true", help="include full review and comment bodies")
    parser.add_argument("--excerpt-chars", type=int, default=240, help="body excerpt size when full bodies are omitted")
    parser.add_argument("--output", type=Path, help="write JSON to this file instead of stdout")
    parser.add_argument("--compact", action="store_true", help="emit compact JSON")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    if args.pr < 1:
        print("--pr must be positive", file=sys.stderr)
        return 2
    if args.excerpt_chars < 40 or args.excerpt_chars > 4000:
        print("--excerpt-chars must be between 40 and 4000", file=sys.stderr)
        return 2
    try:
        repository = resolve_repository(args.repo)
        state = collect_state(
            repository,
            args.pr,
            include_bodies=args.include_bodies,
            excerpt_chars=args.excerpt_chars,
        )
    except PrStateError as error:
        print(str(error), file=sys.stderr)
        return 1

    text = json.dumps(
        state,
        ensure_ascii=True,
        indent=None if args.compact else 2,
        separators=(",", ":") if args.compact else None,
    ) + "\n"
    if args.output:
        args.output.write_text(text, encoding="utf-8")
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
