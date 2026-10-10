#!/usr/bin/env bash
# hand-rendered-tasks-stop.sh — Stop hook: catch a task list the agent painted
# by hand instead of running the tool that owns the shape.
#
# THE FAILURE. Asked "what's pending" or "show me the tasks", an agent builds a
# markdown table from memory or from raw store reads and prints it: rows like
# "| #11 | audit … |". Every value may be right, and the render is still wrong,
# because it is not the ratified /tasks shape (goal boxes, milestone bands, the
# gate-first order, the height law) and it is not checked against the store the
# way task-table.sh checks it. This is plane 2 of the /tasks failure: of the 17
# atone events that name /tasks, 12 are the agent around the tool, not the
# renderer. Slugs: substituted-own-format-for-the-ruled-one, trust-the-tool-
# not-blind-to-it, dense-briefing-instead-of-a-direct-answer. Owner ruled D1a,
# 2026-09-18, from the fourth-pass audit (20260918-tasks-audit-4th).
#
# WHY A GATE. bare-id-cluster-stop.sh is the working model for plane 2: same
# family of failure, and it runs 36 heeded to 1. This is its sibling for the
# hand-rendered table, the shape the id-cluster gate does not catch.
#
# WARN, NOT BLOCK, per ruling D2a: every new gate ships warn-tier and is promoted
# on evidence. Dry-run two weeks (the warn tier IS the dry-run: it advises and
# warn-log.sh tracks heed), same readout as dense-briefing-shapes.
#
# WHAT IT DOES NOT TRIGGER ON. Code fences are stripped first, so the REAL /tasks
# output (always a fenced block) is never the trigger. And a turn that actually
# ran task-table.sh or task.sh, or used the Task/TaskList tool, is exempt however
# it presents the result: the tool was consulted, which is the whole ask.
#
# Mute: touch ~/.claude/.no-hand-tasks-gate (machine-wide until removed).

set -uo pipefail
[ -f "$HOME/.claude/.no-hand-tasks-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v rg >/dev/null 2>&1 || exit 0

HOOK_COMMON="$HOME/.claude/scripts/hooks/hook-common.sh"
[ -r "$HOOK_COMMON" ] || exit 0
. "$HOOK_COMMON"

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tp" ] && [ -f "$tp" ] || exit 0
sid8=$(hook_sid8 "$sid")

# EXEMPT: did this turn (since the last user message) consult the task tool at
# all? A Bash call to task-table.sh / task.sh, or the Task / TaskList tool. If so,
# nothing to warn about, however the result was then presented.
consulted=$(python3 - "$tp" <<'PY' 2>/dev/null
import json, sys
rows = [l for l in open(sys.argv[1], errors="replace")]
# Walk back to the last user turn; scan tool_use from there to the end.
start = 0
for i in range(len(rows) - 1, -1, -1):
    try: d = json.loads(rows[i])
    except Exception: continue
    if d.get("type") == "user":
        start = i; break
hit = False
for l in rows[start:]:
    try: d = json.loads(l)
    except Exception: continue
    if d.get("type") != "assistant": continue
    for b in (d.get("message") or {}).get("content") or []:
        if not isinstance(b, dict) or b.get("type") != "tool_use": continue
        name = b.get("name") or ""
        if name in ("Task", "TaskList", "TaskCreate", "TaskUpdate"): hit = True
        if name == "Bash":
            cmd = (b.get("input") or {}).get("command") or ""
            if "task-table.sh" in cmd or "task.sh" in cmd: hit = True
            if "scripts/goals/" in cmd or "/gs " in cmd or cmd.startswith("gs "): hit = True
print("yes" if hit else "no")
PY
)
[ "$consulted" = "yes" ] && exit 0

# The final assistant message, fenced and inline code removed (a fenced /tasks
# render is the ruled shape, never the defect).
prose=$(python3 - "$tp" <<'PY' 2>/dev/null
import json, re, sys
last = ""
for line in open(sys.argv[1], errors="replace"):
    try: d = json.loads(line)
    except Exception: continue
    if d.get("type") != "assistant": continue
    c = (d.get("message") or {}).get("content") or []
    t = "".join(b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text")
    if t.strip(): last = t
bt = chr(96)
last = re.sub(bt * 3 + ".*?" + bt * 3, " ", last, flags=re.S)
last = re.sub(bt + "[^" + bt + "]*" + bt, " ", last)
print(last)
PY
)
[ -n "${prose//[[:space:]]/}" ] || exit 0

# THE SHAPE. A hand-rendered task table is either:
#  (a) a markdown table whose first column is an id: two or more lines matching
#      `| #<n> | …`, or
#  (b) a loose list of three or more lines that each START with `#<n> ` and go on
#      with words: a task list typed as prose rather than run through the tool.
tbl=$(printf '%s\n' "$prose" | rg -c '^\s*\|?\s*#[0-9]{1,4}\s*\|' 2>/dev/null || true)
lst=$(printf '%s\n' "$prose" | rg -c '^\s*[-*]?\s*#[0-9]{1,4}\s+\S' 2>/dev/null || true)
tbl=${tbl:-0}; lst=${lst:-0}

if [ "$tbl" -lt 2 ] && [ "$lst" -lt 3 ]; then
  # No hand-rendered table this turn: clear any prior mark and log a heed.
  MARK="/tmp/claude-handtasks-${sid8}"
  if [ -f "$MARK" ]; then
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook hand-rendered-tasks \
      --heed-of "hand-tasks:$sid8" --heeded true >/dev/null 2>&1 || true
    rm -f "$MARK" 2>/dev/null || true
  fi
  exit 0
fi

MARK="/tmp/claude-handtasks-${sid8}"
if ! hook_loop_check "$MARK" "$prose"; then
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook hand-rendered-tasks \
    --heed-of "hand-tasks:$sid8" --heeded false >/dev/null 2>&1 || true
  exit 0
fi

msg="⚠ hand-rendered task table — a task list painted by hand, not run through /tasks.

This turn presents task rows (a #N-first-column table, or a #N list) and never
called task-table.sh, task.sh, or the Task tool. A hand-built table is not the
ratified /tasks shape (goal boxes, milestone bands, gate-first order, the height
law) and it is not checked against the store the way the tool checks it. This is
plane 2 of the /tasks failure: showing the owner a table you invented.

Run the view and show its output in a fenced block: python3 ~/.claude/scripts/goals/views/path.py
(a fenced /tasks render is never flagged, its shape is the ruled one). If you
truly need a bespoke view, say so in one line and cite the store you read.

Owner ruling D1a, 2026-09-18 (audit: ~/.claude/assets/reports/20260918-tasks-audit-4th).
Mute: touch ~/.claude/.no-hand-tasks-gate"

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook hand-rendered-tasks --action nudge \
  --heeded unknown >/dev/null 2>&1 || true
jq -cn --arg m "$msg" '{systemMessage:$m}' 2>/dev/null || true
exit 0
