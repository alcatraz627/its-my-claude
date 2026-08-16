#!/usr/bin/env bash
# task-table.sh — the task list, rendered so it never has to be scrolled to, and
# so a reader without the backstory can tell what each row is about.
#
# TWO OWNER RULINGS SHAPE THIS.
#
# 2026-08-13, on size: "The issue with large ones is needing to scroll all the
# way up to see the task list. It can be wider, that's fine. Also have more
# detail if needed, but the height need not exceed 1.25 times this preview."
# So width is FREE and height is capped near 44 lines. Past the cap it truncates
# LOUDLY, naming what it dropped, because a silently trimmed list reads complete.
#
# 2026-08-15, on references: every task number, proposal id, or file must carry
# a gloss, so an out-of-context reader can understand the premise of the row.
# A bare "#29 (D1)" tells a stranger nothing. That is what --refs resolves.
#
# THE SCRIPT OWNS THE DATA. THE AGENT OWNS THE PRESENTED TABLE.
# The baseline below is a guaranteed floor, not a ceiling: the agent may add
# context columns when this queue needs them (see skills/tasks/SKILL.md for the
# vocabulary and the bar each column has to clear). What the agent may NOT do is
# render from memory. Facts come from here; presentation is theirs.
#
# Usage: task-table.sh              the framed baseline table
#        task-table.sh --json       full data incl. resolved references
#        task-table.sh --compact    3-line digest, for injection
#        task-table.sh --refs       just the reference glossary
#        task-table.sh --session <sid8>
set -uo pipefail
export PATH="/opt/homebrew/bin:$PATH"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"   # ${#var} counts characters, not bytes

MODE=human; SID=""; PIN=""
while [ $# -gt 0 ]; do
  case "$1" in
    --json) MODE=json; shift ;;
    --compact) MODE=compact; shift ;;
    --refs) MODE=refs; shift ;;
    --session) SID="$2"; shift 2 ;;
    --pin) PIN="$2"; shift 2 ;;
    --candidates) MODE=candidates; shift ;;
    -h|--help) sed -n '2,26p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 64 ;;
  esac
done

# STORE RESOLUTION. This is the whole correctness story, so it is explicit.
#
# There is NO reliable mapping from a live session to its task store. The store
# is named for the session that CREATED the tasks; a task list survives /clear;
# and none of CLAUDE_CODE_SESSION_ID, CLAUDE_CODE_BRIDGE_SESSION_ID, the /private
# tmp session dir, or any marker inside the store directory names it. There are
# 231 stores on this machine and "most recently modified" is whichever session
# wrote last, which is how agents rendered each other's queues (owner report,
# 2026-08-16: multiple agents affected, cross-session contamination).
#
# So this script NO LONGER GUESSES. A guess that looks confident is worse than a
# refusal, because the reader cannot tell it happened. Resolution ladder:
#
#   1. --session <sid8>            explicit, always wins
#   2. a pinned mapping            written once per live session by --pin
#   3. a store named for the live session id   (rare, but free to check)
#   4. REFUSE, and print the candidates so the caller can identify and pin one
#
# This script is READ-ONLY: it opens task files for reading and never writes one.
# A wrong resolution misinforms; it cannot corrupt another session's store.
TASKS_ROOT="$HOME/.claude/tasks"
PIN_DIR="$TASKS_ROOT/.live-session-map"
LIVE="${CLAUDE_CODE_SESSION_ID:-}"; LIVE8="${LIVE:0:8}"
RESOLVED_BY="explicit"

candidates() {   # newest stores, with a fingerprint the caller can recognise
  ls -dt "$TASKS_ROOT"/session-*/ 2>/dev/null | head -8 | while read -r d; do
    n=$(ls "$d"*.json 2>/dev/null | wc -l | tr -d ' '); [ "${n:-0}" -gt 0 ] || continue
    sid=$(basename "$d"); sid=${sid#session-}
    newest=$(ls -t "$d"*.json 2>/dev/null | head -1)
    subj=$(python3 -c "import json,sys;print((json.load(open(sys.argv[1])).get('subject') or '')[:58])" "$newest" 2>/dev/null)
    printf '    %-10s %3s tasks   %s\n' "$sid" "$n" "$subj"
  done
}

if [ -n "$PIN" ]; then                       # --pin writes the mapping and exits
  [ -d "$TASKS_ROOT/session-$PIN" ] || { echo "task-table: no store session-$PIN" >&2; exit 3; }
  [ -n "$LIVE8" ] || { echo "task-table: no live session id to pin against" >&2; exit 3; }
  mkdir -p "$PIN_DIR" && printf '%s' "$PIN" > "$PIN_DIR/$LIVE8"
  echo "pinned: live session $LIVE8 -> store session-$PIN"; exit 0
fi

DIR=""
RESOLVER="$HOME/.claude/scripts/task-table/resolve-store.sh"
if [ -n "$SID" ] && [ -d "$TASKS_ROOT/session-$SID" ]; then
  DIR="$TASKS_ROOT/session-$SID"                       # explicit always wins
elif [ -x "$RESOLVER" ] && D=$("$RESOLVER" 2>/dev/null) && [ -n "$D" ] && [ -d "$D" ]; then
  DIR="$D"; RESOLVED_BY="content-match"                # automatic, self-verifying
else
  {
    echo "task-table: could not identify your task store."
    echo
    echo "  Content-matching against this session's transcript found no decisive"
    echo "  store, so nothing is guessed: a confident wrong table is the defect"
    echo "  this refusal exists to prevent. Live session: ${LIVE8:-unknown}"
    echo
    echo "  Candidates, newest first:"
    candidates
    echo
    echo "  Read one directly:  task-table.sh --session <sid8>"
    echo "  Or pin it:          task-table.sh --pin <sid8>"
  } >&2
  exit 4
fi
export RESOLVED_BY

MODE="$MODE" DIR="$DIR" GCC="$HOME/.claude" RESOLVED_BY="$RESOLVED_BY" python3 - <<'PY'
import json, os, re, pathlib, sys

mode = os.environ["MODE"]; d = pathlib.Path(os.environ["DIR"]); G = pathlib.Path(os.environ["GCC"])
resolved_by = os.environ.get("RESOLVED_BY", "explicit")
HEIGHT = 44

rows = []
for f in d.glob("*.json"):
    try: rows.append(json.load(open(f)))
    except Exception: pass
def num(r): return int(re.sub(r"\D", "", str(r.get("id", "0"))) or 0)
rows.sort(key=num)
by_id = {num(r): r for r in rows}

def desc(r): return r.get("description") or ""
def subj(r): return r.get("subject") or ""
def meta(r, k, dflt=""): return (r.get("metadata") or {}).get(k, dflt)

# ---- reference resolution -------------------------------------------------
# Bulk-load the proposal ledger once. Resolving ids one subprocess at a time
# would cost ~40 spawns on this queue for data that lives in one file.
props = {}
pj = G / "proposals.jsonl"
if pj.exists():
    for ln in pj.read_text(errors="replace").splitlines():
        try:
            o = json.loads(ln)
            if o.get("id"): props[o["id"]] = o
        except Exception: pass

RE_PROP = re.compile(r"\bprop-\d{8}-\d{6}-[0-9a-z]{2}\b")
RE_TASK = re.compile(r"#(\d{1,3})\b")
RE_MIST = re.compile(r"\bmist-\d{8}-\d{6}-[0-9a-z]{2}\b")
RE_DISP = re.compile(r"\((D\d{1,2})\)")
RE_FILE = re.compile(r"\b((?:scripts|skills|rules|features|conventions|assets)/[\w./-]+\.\w+)")

def refs_for(r):
    """Every reference in a task, with a gloss a stranger could use."""
    text = subj(r) + " " + desc(r); out = []
    seen = set()
    def add(kind, key, gloss):
        if key in seen: return
        seen.add(key); out.append({"kind": kind, "ref": key, "gloss": gloss})
    for m in RE_PROP.findall(text):
        p = props.get(m)
        add("proposal", m, (p.get("title", "")[:88] + f"  [{p.get('status','?')}]") if p
            else "not in the ledger (dropped or rejected)")
    for m in RE_TASK.findall(text):
        t = by_id.get(int(m))
        if t: add("task", f"#{m}", f"{subj(t)[:88]}  [{t.get('status','?')}]")
    for m in RE_MIST.findall(text):
        add("atone", m, "recorded mistake; bash ~/.claude/scripts/atone.sh show " + m)
    for m in RE_DISP.findall(text):
        add("disposition", m, "triage disposition; see ~/.claude/topics/backlog-triage-*.md")
    for m in RE_FILE.findall(text):
        p = G / m
        add("file", m, str(p) + ("" if p.exists() else "   MISSING"))
    return out

GATE = re.compile(r"USER-GATED|Blocked on the owner|owner reviews|needs you|"
                  r"owner present|phrase-gated|dedicated session", re.I)
def gated(r):
    if meta(r, "blocked_on"): return True
    return bool(GATE.search(desc(r)) or GATE.search(subj(r)))
def gate_declared(r): return bool(meta(r, "blocked_on"))
def backlog(r): return bool(RE_PROP.search(desc(r)))

def enrich(r):
    return {
        "id": num(r), "subject": subj(r), "status": r.get("status", "pending"),
        "gated": gated(r), "source": "backlog" if backlog(r) else "session",
        # Set at TaskCreate time; never inferred. An inferred class would be
        # wrong in a way no reader could see.
        "class": meta(r, "class", ""), "domain": meta(r, "domain", ""),
        "blocked_on": meta(r, "blocked_on", ""), "gate_declared": gate_declared(r),
        "board_card": meta(r, "board_card", ""),
        "refs": refs_for(r),
        "desc_chars": len(desc(r)),
    }

data = [enrich(r) for r in rows]
now     = [x for x in data if x["status"] == "in_progress"]
openish = [x for x in data if x["status"] == "pending"]
done    = [x for x in data if x["status"] == "completed"]
blocked = [x for x in openish if x["gated"]]
ready   = [x for x in openish if not x["gated"]]

if mode == "json":
    print(json.dumps({"store": str(d), "counts": {
        "total": len(data), "in_progress": len(now), "open": len(openish),
        "done": len(done), "blocked": len(blocked), "ready": len(ready)},
        "tasks": data}, indent=2)); sys.exit()

if mode == "refs":
    seen = {}
    for x in data:
        if x["status"] == "completed": continue
        for rf in x["refs"]: seen.setdefault(rf["ref"], rf)
    for k in sorted(seen):
        rf = seen[k]; print(f"  {rf['kind']:<12} {k:<28} {rf['gloss']}")
    sys.exit()

if mode == "compact":
    nowtxt = f"#{now[0]['id']} {now[0]['subject'][:48]}" if now else "nothing in progress"
    print(f"tasks: {len(openish)} open ({len(blocked)} need you, {len(ready)} agent-ready), {len(done)} done")
    print(f"  now: {nowtxt}")
    if blocked: print("  needs you: " + ", ".join(f"#{x['id']}" for x in blocked))
    sys.exit()

# ---- framed baseline ------------------------------------------------------
# Box-drawing for the frame, ASCII inside the cells. An emoji is one character
# but two terminal columns, so putting one in a cell breaks every border below it.
COLS = [("#", 5), ("task", 68), ("src", 8), ("refs", 6)]
W = sum(c[1] for c in COLS) + len(COLS) * 3 + 1

def rule(l, m, r): return l + m.join("─" * (c[1] + 2) for c in COLS) + r
def cells(vals):
    return "│ " + " │ ".join(str(v)[:c[1]].ljust(c[1]) for v, c in zip(vals, COLS)) + " │"
# A section header spans the whole table. Putting it in the first cell truncated
# it to the width of the id column, which turned "NEEDS YOU" into "── NE".
INNER = sum(c[1] for c in COLS) + (len(COLS) - 1) * 3
def span(text):  return "│ " + text[:INNER].ljust(INNER) + " │"

out = []
def w(s=""): out.append(s)

w(f"TASKS  ·  {len(openish)} open, {len(done)} done, {len(data)} total  ·  {d.name}")
if resolved_by.startswith("guess"):
    w(f"  !! STORE NOT CONFIRMED ({resolved_by}). This may be another session's queue.")
    w(f"     Pin it: task-table.sh --session <sid8>   ·  stores: ls ~/.claude/tasks/")
w(rule("┌", "┬", "┐")); w(cells([c[0] for c in COLS])); w(rule("├", "┼", "┤"))

def section(title, items, budget=None):
    if not items: return 0
    w(span(f"── {title} " + "─" * max(0, INNER - len(title) - 4)))
    shown = items if budget is None else items[:max(budget, 0)]
    for x in shown:
        w(cells([x["id"], x["subject"], x["source"], len(x["refs"]) or ""]))
    return len(items) - len(shown)

section("NOW", now)
section("NEEDS YOU  (the only rows you can act on)", blocked)
drop = section("AGENT-READY", ready, budget=HEIGHT - len(out) - 9)
if drop > 0:
    w(span(f"   … +{drop} more agent-ready, held back by the height cap"))
    w(span("   full list: bash ~/.claude/scripts/task-table/task-table.sh --json"))
w(rule("└", "┴", "┘"))
ids = [f"#{x['id']}" for x in done]
line = f"done ({len(done)}): "
shown = []
for i in ids:
    if len(line + ", ".join(shown + [i])) > W - 24: break
    shown.append(i)
tail = "" if len(shown) == len(ids) else f"  … +{len(ids)-len(shown)} more"
w(line + ", ".join(shown) + tail)
nrefs = len({rf['ref'] for x in data if x['status'] != 'completed' for rf in x['refs']})
derived = sum(1 for x in blocked if not x["gate_declared"])
if derived or openish:
    w(f"gating: {len(blocked)-derived} declared, {derived} inferred from wording. An unset metadata.blocked_on can hide a gated row in AGENT-READY.")
w(f"height {len(out)+1}/{HEIGHT}  ·  {nrefs} refs resolvable: task-table.sh --refs  ·  detail: /tasks")
print("\n".join(out))
PY
