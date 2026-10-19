#!/usr/bin/env python3
"""Tab-title status for the turn that just ended, read from the transcript.

Prints one of ok, warning, error, blocked, or nothing. The Stop hook uses it so
the tab shows whether the turn ended well without the agent saying so.

Rules, over the tool calls since the last real user prompt:
  blocked  the turn's last tool call was AskUserQuestion
  error    the last test/build command failed (nothing passed after it)
  ok       the last test/build command passed
  warning  some other tool call failed and no test/build passed afterwards
  (empty)  nothing failed and no test/build ran

Usage: derive-status.py <transcript.jsonl>
"""
import json
import re
import sys

TESTBUILD = re.compile(
    r"npm test|npm run test|pytest|go test|cargo test|vitest|jest|tests\.sh|\.test\.|"
    r"npm run build|\bmake\b|cargo build|go build|\btsc\b|webpack|vite build|bun test"
)


def is_real_user_prompt(msg):
    content = msg.get("content")
    if isinstance(content, str):
        return bool(content.strip())
    if isinstance(content, list):
        has_text = any(p.get("type") == "text" and p.get("text", "").strip() for p in content if isinstance(p, dict))
        has_result = any(p.get("type") == "tool_result" for p in content if isinstance(p, dict))
        return has_text and not has_result
    return False


def result_failed(part):
    if part.get("is_error"):
        return True
    c = part.get("content")
    if isinstance(c, list):
        c = " ".join(x.get("text", "") for x in c if isinstance(x, dict))
    return isinstance(c, str) and c.startswith("Exit code ") and not c.startswith("Exit code 0")


def derive(path):
    try:
        lines = open(path, errors="replace").read().splitlines()
    except Exception:
        return ""
    events = []  # one dict per tool call of the current turn, in order
    by_id = {}
    for raw in lines:
        try:
            row = json.loads(raw)
        except Exception:
            continue
        msg = row.get("message") if isinstance(row, dict) else None
        if not isinstance(msg, dict):
            continue
        if row.get("type") == "user" and is_real_user_prompt(msg):
            events, by_id = [], {}
            continue
        content = msg.get("content")
        if not isinstance(content, list):
            continue
        for part in content:
            if not isinstance(part, dict):
                continue
            if part.get("type") == "tool_use":
                inp = part.get("input") or {}
                ev = {
                    "name": part.get("name"),
                    "tb": part.get("name") == "Bash" and bool(TESTBUILD.search(inp.get("command", "") or "")),
                    "failed": False,
                }
                events.append(ev)
                by_id[part.get("id")] = ev
            elif part.get("type") == "tool_result":
                ev = by_id.get(part.get("tool_use_id"))
                if ev is not None:
                    ev["failed"] = result_failed(part)
    if not events:
        return ""
    if events[-1]["name"] == "AskUserQuestion":
        return "blocked"
    last_tb = next((e for e in reversed(events) if e["tb"]), None)
    if last_tb is not None:
        if last_tb["failed"]:
            return "error"
        # Passing build/test wins unless a later non-test tool call failed.
        after = events[events.index(last_tb) + 1:]
        return "warning" if any(e["failed"] for e in after) else "ok"
    return "warning" if any(e["failed"] for e in events) else ""


if __name__ == "__main__":
    if len(sys.argv) > 1:
        print(derive(sys.argv[1]))
