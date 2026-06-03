#!/usr/bin/env python3
"""Reconstruct the current task list by replaying a session transcript.

The on-disk task dir (`~/.claude/tasks/<sid>/`) is a volatile runtime cache: it
lags within a turn, drops completed tasks, and is wiped on resume. The session
transcript, by contrast, is an append-only durable log of every Task tool call,
so replaying it yields the true current state — including completed tasks the
cache has already discarded.

Usage:  replay_tasks.py <transcript.jsonl>
Output: a JSON list (creation order) of live tasks:
        [{"id": "3", "subject": "...", "status": "pending|in_progress|completed"}]
        Deleted tasks are dropped. Status defaults to pending until an update
        says otherwise.

Reads `TaskCreate` results (the id is assigned server-side and only appears in
the result text) and `TaskUpdate` inputs (which carry the new status/subject).
"""

import sys
import json
import re

# Subjects are single-line; no re.DOTALL, so a multi-block tool_result can't
# bleed trailing text/newlines into the captured subject (which would poison the
# drift hash and the memory pointer, not just the cosmetically-sanitised block).
CREATED = re.compile(r"Task #(\d+) created successfully:\s*(.*)")


def _result_text(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict):
                parts.append(item.get("text", "") or "")
            else:
                parts.append(str(item))
        return "\n".join(parts)
    return str(content)


def replay(path):
    state = {}   # id -> {subject, status}
    order = []   # ids in creation order
    create_use = {}  # tool_use_id -> subject (from the create input, fallback)

    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except ValueError:
                continue
            # Sub-agent (sidechain) turns carry their own task calls; folding
            # them into the main session's list would contaminate it.
            if obj.get("isSidechain"):
                continue
            msg = obj.get("message", {})
            content = msg.get("content")
            if not isinstance(content, list):
                continue
            for c in content:
                if not isinstance(c, dict):
                    continue
                ctype = c.get("type")

                if ctype == "tool_use" and c.get("name") == "TaskCreate":
                    create_use[c.get("id")] = (c.get("input", {}) or {}).get("subject", "")

                elif ctype == "tool_use" and c.get("name") == "TaskUpdate":
                    inp = c.get("input", {}) or {}
                    tid = str(inp.get("taskId", ""))
                    if not tid:
                        continue
                    if tid not in state:
                        # An update can precede our view of the create only if the
                        # create result was unparseable; seed a placeholder.
                        state[tid] = {"subject": "", "status": "pending"}
                        order.append(tid)
                    if inp.get("status") == "deleted":
                        state[tid]["status"] = "deleted"
                    elif inp.get("status"):
                        state[tid]["status"] = inp["status"]
                    if inp.get("subject"):
                        state[tid]["subject"] = inp["subject"]

                elif ctype == "tool_result":
                    m = CREATED.search(_result_text(c.get("content")))
                    if m:
                        tid = m.group(1)
                        subject = m.group(2).strip()
                        if tid not in state:
                            state[tid] = {"subject": subject, "status": "pending"}
                            order.append(tid)
                        elif not state[tid].get("subject"):
                            state[tid]["subject"] = subject

    out = []
    for tid in order:
        t = state[tid]
        if t["status"] == "deleted":
            continue
        out.append({"id": tid, "subject": t["subject"], "status": t["status"]})
    return out


def main():
    if len(sys.argv) < 2:
        print("[]")
        return 0
    try:
        print(json.dumps(replay(sys.argv[1])))
    except FileNotFoundError:
        print("[]")
    return 0


if __name__ == "__main__":
    sys.exit(main())
