#!/usr/bin/env python3
"""Does this session already have a plan, and is it exempt from the plan gate?

The plan gate nudges a build that starts without a plan. Before it speaks it asks
this script, which reads the session transcript and prints one JSON object:

  {"plan": bool, "exempt": bool, "reasons": [...]}

`plan` is true when the session shows any plan signal: a Task list (TaskCreate,
TaskList or a task store on disk), ExitPlanMode, a planning skill, a write to a
plan, design or spec markdown file, or assistant text with a "plan" heading or a
numbered list of three steps. `exempt` is true for sessions the gate must leave
alone: headless or sidechain runs, resumed sessions (/catchup, /revive), and an
owner prompt that is itself an enumerated list of three or more items.

Usage: plan-signals.py <transcript.jsonl> <session id>
Env:   PLAN_GATE_TASKS_DIR overrides ~/.claude/tasks (tests).
       PLAN_GATE_PINS_DIR overrides ~/.claude/tasks-pins (tests).
"""
import json
import os
import re
import sys

PLAN_SKILLS = {"plan", "bloop", "blitz", "build-change", "build-ui", "gated-plan"}
RESUME_SKILLS = {"catchup", "revive"}
PLAN_FILE = re.compile(r"(plan|design|spec)[^/]*\.md$", re.I)
CMD_NAME = re.compile(r"<command-name>/?([A-Za-z0-9:_-]+)</command-name>")
LIST_LINE = re.compile(r"^\s*(\d+[.)]|[-*•])\s+\S", re.M)
INLINE_ENUM = re.compile(r"(?:^|[\s(])\d[.)]\s+\S")
PLAN_HEADING = re.compile(r"(?im)^\s*(#{1,4}\s*|\*\*)?plan(\*\*)?\s*:?\s*(\*\*)?\s*$|^\s*(\*\*)?plan:(\*\*)?")
STEPS = [re.compile(r"(?m)^\s*%d[.)]\s+\S" % n) for n in (1, 2, 3)]


def enumerated(text):
    """An owner prompt that carries three or more list items is its own plan."""
    if len(LIST_LINE.findall(text)) >= 3:
        return True
    return len(INLINE_ENUM.findall(text)) >= 3


def prompt_text(msg):
    c = msg.get("content")
    if isinstance(c, str):
        return c
    if isinstance(c, list):
        if any(isinstance(p, dict) and p.get("type") == "tool_result" for p in c):
            return ""
        return " ".join(p.get("text", "") for p in c if isinstance(p, dict) and p.get("type") == "text")
    return ""


def task_store_present(sid):
    s8 = (sid or "")[:8]
    if not s8:
        return False
    tasks = os.environ.get("PLAN_GATE_TASKS_DIR") or os.path.expanduser("~/.claude/tasks")
    pins = os.environ.get("PLAN_GATE_PINS_DIR") or os.path.expanduser("~/.claude/tasks-pins")
    cands = [os.path.join(tasks, "session-" + s8)]
    pin = os.path.join(pins, s8)
    if os.path.isfile(pin):
        try:
            cands.append(os.path.join(tasks, "session-" + open(pin).read().strip().replace("session-", "")))
        except Exception:
            pass
    for d in cands:
        if os.path.isdir(d) and any(f.endswith(".json") for f in os.listdir(d)):
            return True
    return False


def analyse(path, sid):
    reasons, exempt = [], []
    plan = False
    if task_store_present(sid):
        plan = True
        reasons.append("task-store")
    rows = []
    if path and os.path.isfile(path):
        for raw in open(path, errors="replace"):
            raw = raw.strip()
            if not raw:
                continue
            try:
                rows.append(json.loads(raw))
            except Exception:
                continue
    else:
        exempt.append("no-transcript")
    for row in rows:
        if not isinstance(row, dict):
            continue
        ep = row.get("entrypoint")
        if ep and ep != "cli":
            exempt.append("headless")
        if row.get("isSidechain") is True:
            exempt.append("sidechain")
        msg = row.get("message")
        if not isinstance(msg, dict):
            continue
        if row.get("type") == "user":
            text = prompt_text(msg)
            if text:
                for name in CMD_NAME.findall(text):
                    base = name.split(":")[-1]
                    if base in RESUME_SKILLS:
                        exempt.append("resumed")
                    if base in PLAN_SKILLS:
                        plan = True
                        reasons.append("skill:" + base)
                # A skill's expanded body is injected as a meta user row; its bullets
                # are not the owner's list.
                if enumerated(text) and not text.lstrip().startswith("<") and not row.get("isMeta"):
                    exempt.append("enumerated-prompt")
            continue
        content = msg.get("content")
        if not isinstance(content, list):
            continue
        for part in content:
            if not isinstance(part, dict):
                continue
            if part.get("type") == "text" and row.get("type") == "assistant":
                t = part.get("text", "")
                if PLAN_HEADING.search(t) or all(r.search(t) for r in STEPS):
                    plan = True
                    reasons.append("plan-text")
            elif part.get("type") == "tool_use":
                name, inp = part.get("name"), part.get("input") or {}
                if name in ("TaskCreate", "TaskList", "ExitPlanMode"):
                    plan = True
                    reasons.append(name)
                elif name == "Skill":
                    sk = str(inp.get("skill", "")).split(":")[-1]
                    if sk in PLAN_SKILLS:
                        plan = True
                        reasons.append("skill:" + sk)
                    if sk in RESUME_SKILLS:
                        exempt.append("resumed")
                elif name in ("Write", "Edit", "MultiEdit") and PLAN_FILE.search(str(inp.get("file_path", ""))):
                    plan = True
                    reasons.append("plan-file")
    ex = sorted(set(exempt))
    return {"plan": plan, "exempt": bool(ex), "reasons": sorted(set(reasons)) + ["exempt:" + e for e in ex]}


if __name__ == "__main__":
    tp = sys.argv[1] if len(sys.argv) > 1 else ""
    sid = sys.argv[2] if len(sys.argv) > 2 else ""
    print(json.dumps(analyse(tp, sid)))
