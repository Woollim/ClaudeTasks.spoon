#!/usr/bin/env python3
"""
PostToolUse hook: Detect PR creation and prompt TaskCreate for unchecked items.

Triggers on: gh pr create
Output: additionalContext if PR body contains unchecked items (- [ ])
"""

import json
import re
import subprocess
import sys


def get_pr_body(pr_url: str) -> str | None:
    """Fetch PR body using gh CLI."""
    try:
        result = subprocess.run(
            ["gh", "pr", "view", pr_url, "--json", "body", "-q", ".body"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return None


def has_unchecked_items(body: str) -> bool:
    """Check if PR body contains unchecked checklist items."""
    return bool(re.search(r"- \[ \]", body))


def main():
    try:
        hook_input = json.load(sys.stdin)
    except json.JSONDecodeError:
        return

    command = hook_input.get("tool_input", {}).get("command", "")
    if "gh pr create" not in command:
        return

    tool_response = hook_input.get("tool_response", {})
    stdout = tool_response.get("stdout", "")

    # Extract PR URL from stdout (gh pr create outputs the URL)
    pr_url_match = re.search(r"https://github\.com/[^\s]+/pull/\d+", stdout)
    if not pr_url_match:
        return

    pr_url = pr_url_match.group(0)
    pr_body = get_pr_body(pr_url)

    if not pr_body or not has_unchecked_items(pr_body):
        return

    # Output feedback for Claude
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": "PR has unchecked items. Call TaskCreate for each checklist item.",
        }
    }
    print(json.dumps(output))


if __name__ == "__main__":
    main()
