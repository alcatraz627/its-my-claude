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
# Usage: task-table.sh              the baseline table
#        task-table.sh --json       full data incl. resolved references
#        task-table.sh --compact    3-line digest, for injection
#        task-table.sh --refs       just the reference glossary
#        task-table.sh --unfiled    open rows carrying no goal or no milestone
#        task-table.sh --group <goal|batch|domain|class|planning|tier|actor|auto>   one-off grouping
#        task-table.sh --detail      every row with its description and full glossary
#        task-table.sh --set-group <…>   persist the grouping for THIS project (owner says it once)
#        task-table.sh --session <sid8>   read one store; refuses if it names none
#        task-table.sh --pin <sid8>       map this live session to a store, then exit
#        task-table.sh --candidates       list the stores that could be yours
set -uo pipefail
export PATH="/opt/homebrew/bin:$PATH"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"   # ${#var} counts characters, not bytes

MODE=human; SID=""; PIN=""; GROUP=""; SETGROUP=""; DETAIL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --json) MODE=json; shift ;;
    --detail) DETAIL=1; shift ;;
    --compact) MODE=compact; shift ;;
    --refs) MODE=refs; shift ;;
    --unfiled) MODE=unfiled; shift ;;
    --session) SID="$2"; shift 2 ;;
    --pin) PIN="$2"; shift 2 ;;
    --candidates) MODE=candidates; shift ;;
    --group) GROUP="$2"; shift 2 ;;              # one-off: batch|domain|class|actor|auto
    --set-group) SETGROUP="$2"; shift 2 ;;       # persist for this project; the owner says it once
    # The range ends at the blank comment line after Usage, computed rather than
    # hardcoded: it was pinned at 26 while the block ran to 31, so --group,
    # --detail, --set-group and --session were invisible to --help.
    # Help is the header comment with the comment markers stripped, so it reads
    # as help rather than as source (adv-tasks F12).
    -h|--help) sed -n "2,$(rg -n '^set -uo pipefail' "$0" | head -1 | cut -d: -f1 | awk '{print $1-1}')p" "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
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
#   1. --session <sid8>            explicit; wins, or REFUSES with candidates.
#                                  It never falls through to a lower rung.
#   2. a pinned mapping            written once per live session by --pin
#   3. resolve-store.sh            content-matches task subjects to the transcript
#   4. REFUSE, and print the candidates so the caller can identify and pin one
#
# This script never writes a TASK file: it opens them for reading only, so a wrong
# resolution misinforms and cannot corrupt another session's queue. It does write
# two things, both outside the store: the project view file (--set-group) and the
# live-session pin (--pin).
# A wrong resolution misinforms; it cannot corrupt another session's store.
TASKS_ROOT="$HOME/.claude/tasks"
# THE PIN LIVES OUTSIDE ~/.claude/tasks, and that is the whole point.
#
# It used to live at tasks/.live-session-map/<live8>, and the live session's own
# entry kept disappearing: pinned, confirmed on disk by cat, read back correctly
# by the next wake's header, then gone by the wake after. Measured across four
# fleet wakes on 2026-09-04. Nothing in this repo removes it: all four
# task-table scripts were read, every registered hook was checked, and a
# full-tree grep finds only these scripts naming the directory. Running each
# task-table command in turn against a fresh pin removed none of them.
#
# What the evidence does show is a difference by LOCATION. Sixty pins for dead
# sessions have sat in that directory since August, and tasks-view.json, which
# lives outside tasks/, has been untouched since 19 August. Only the entry named
# for the LIVE session vanishes. ~/.claude/tasks is the harness's own Task-tool
# storage, and a file in it named exactly the live session id reads as harness
# session state to anything cleaning up after a session.
#
# So the fix does not depend on naming the culprit, which was not findable with
# the instruments here. It moves the pin somewhere nothing else claims. The old
# location is still READ so an existing pin keeps working; nothing writes there.
PIN_DIR="$HOME/.claude/tasks-pins"
PIN_DIR_LEGACY="$TASKS_ROOT/.live-session-map"
LIVE="${CLAUDE_CODE_SESSION_ID:-}"; LIVE8="${LIVE:0:8}"
RESOLVED_BY="explicit"

candidates() {   # newest stores, with a fingerprint the caller can recognise
  ls -dt "$TASKS_ROOT"/session-*/ 2>/dev/null | head -8 | while read -r d; do
    n=$(ls "$d"*.json 2>/dev/null | wc -l | tr -d ' '); [ "${n:-0}" -gt 0 ] || continue
    sid=$(basename "$d"); sid=${sid#session-}
    newest=$(ls -t "$d"*.json 2>/dev/null | head -1)
    subj=$(python3 -c "import json,sys;s=(json.load(open(sys.argv[1])).get('subject') or '');print(s if len(s)<=58 else s[:57].rsplit(' ',1)[0]+'…')" "$newest" 2>/dev/null)
    printf '    %-10s %3s tasks   %s\n' "$sid" "$n" "$subj"
  done
}

# A refusal must arrive in the format the caller asked for. --json callers were
# getting the human refusal on stdout, so `task-table.sh --json | jq` died with a
# parse error instead of reading a reason it could act on (gcp-fable, 2026-08-20).
json_refuse() {  # json_refuse <reason> <hint>
  [ "${MODE:-}" = "json" ] || return 1
  python3 - "$1" "$2" "${LIVE8:-}" "$TASKS_ROOT" <<'PYR'
import json, os, sys, glob
reason, hint, live, root = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
cands = []
for d in sorted(glob.glob(os.path.join(root, "session-*/")), key=os.path.getmtime, reverse=True)[:8]:
    n = len(glob.glob(os.path.join(d, "*.json")))
    if n: cands.append({"sid": os.path.basename(d.rstrip("/"))[len("session-"):], "tasks": n})
json.dump({"error": reason, "hint": hint, "live_session": live or None, "candidates": cands}, sys.stdout, indent=2)
print()
PYR
  return 0
}

# --candidates was parsed since the flag existed and handled nowhere, so it fell
# through and rendered an ordinary table (or a refusal) while the empty-store
# message told readers to run it. Wire it to the function that already exists.
if [ "${MODE:-}" = "candidates" ]; then
  echo "task stores on this machine, newest first:"
  candidates
  echo
  echo "  read one:  task-table.sh --session <sid8>"
  echo "  pin one:   task-table.sh --pin <sid8>"
  exit 0
fi

if [ -n "$PIN" ]; then                       # --pin writes the mapping and exits
  if [ ! -d "$TASKS_ROOT/session-$PIN" ]; then
    # the third refusal path; --json callers get JSON here too (second seat, 2026-08-20)
    json_refuse "no store session-$PIN to pin" "run --candidates to see the stores that exist" && exit 3
    echo "task-table: no store session-$PIN" >&2; exit 3
  fi
  [ -n "$LIVE8" ] || { echo "task-table: no live session id to pin against" >&2; exit 3; }
  mkdir -p "$PIN_DIR" && printf '%s' "$PIN" > "$PIN_DIR/$LIVE8"
  # a pin is the one moment a live session vouches for a store, so record the project then too
  if [ ! -s "$TASKS_ROOT/session-$PIN/.project" ]; then
    PR=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null); [ -n "$PR" ] || PR="$PWD"
    printf '%s' "$PR" > "$TASKS_ROOT/session-$PIN/.project"
  fi
  echo "pinned: live session $LIVE8 -> store session-$PIN"; exit 0
fi

DIR=""
RESOLVER="$HOME/.claude/scripts/task-table/resolve-store.sh"
if [ -n "$SID" ]; then
  # Explicit always wins, and winning includes losing LOUDLY. A --session that
  # named no store used to fail this test and fall through to the pin, rendering
  # a DIFFERENT store under a header that correctly named it: right about itself,
  # wrong about the question asked (#104, observed 2026-08-19). Derive first,
  # then refuse with evidence, per rules/refusal-is-not-a-fix.md.
  if [ -d "$TASKS_ROOT/session-$SID" ]; then
    DIR="$TASKS_ROOT/session-$SID"
  else
    # A full uuid or a unique prefix still identifies a store; stores are named
    # for the first 8 chars, so try that before giving up.
    if [ "${#SID}" -lt 4 ]; then
      {
        echo "task-table: --session needs at least 4 characters of the id, got \"$SID\"."
        echo "  A shorter prefix matches too much to be an answer, and the refusal"
        echo "  below would then claim things about \"the first 8 characters\" of an"
        echo "  id that has fewer than that."
        echo "  Candidates, newest first:"
        candidates
      } >&2
      json_refuse "--session needs at least 4 characters, got \"$SID\"" "run --candidates to see the stores that exist" && exit 3
      exit 3
    fi
    match=$(ls -d "$TASKS_ROOT"/session-"${SID:0:8}"*/ 2>/dev/null)
    n=$(printf '%s\n' "$match" | sed '/^$/d' | wc -l | tr -d ' ')
    if [ "${n:-0}" = 1 ]; then
      DIR="${match%/}"; RESOLVED_BY="explicit (matched by prefix)"
    else
      {
        echo "task-table: --session $SID names no store."
        [ "${n:-0}" -gt 1 ] && echo "  Its first ${#SID} character(s) match $n stores; give more of the id."
        echo "  Not falling back to the pin: you asked for a specific store, and"
        echo "  quietly rendering another one is the failure this refusal prevents."
        echo "  Candidates, newest first:"
        candidates
        echo "  Or drop --session to use the pin or the resolver."
      } >&2
      json_refuse "no store named session-$SID" "pass an existing --session, or drop it to use the pin" && exit 3
      exit 3
    fi
  fi
elif [ -n "$LIVE8" ] && [ -f "$PIN_DIR/$LIVE8" ] && [ -d "$TASKS_ROOT/session-$(cat "$PIN_DIR/$LIVE8")" ]; then
  DIR="$TASKS_ROOT/session-$(cat "$PIN_DIR/$LIVE8")"; RESOLVED_BY="pin"   # the mapping --pin wrote for this live session
elif [ -n "$LIVE8" ] && [ -f "$PIN_DIR_LEGACY/$LIVE8" ] && [ -d "$TASKS_ROOT/session-$(cat "$PIN_DIR_LEGACY/$LIVE8")" ]; then
  DIR="$TASKS_ROOT/session-$(cat "$PIN_DIR_LEGACY/$LIVE8")"; RESOLVED_BY="pin (legacy location)"
elif [ -x "$RESOLVER" ] && RESOLVER_ERR=$(mktemp "${TMPDIR:-/tmp}/tt-resolver.XXXXXX") && D=$("$RESOLVER" 2>"$RESOLVER_ERR") && [ -n "$D" ] && [ -d "$D" ]; then
  DIR="$D"
  # The resolver's first rung returns the store literally NAMED for this
  # session, which a resumed session has and which is usually empty. That is
  # not a content match, and a header that called it one sent a peer to the
  # wrong queue under a confident label (task #54).
  if [ "$(basename "$D")" = "session-$LIVE8" ]; then RESOLVED_BY="session-name"
  elif [ -s "$PIN_DIR/$LIVE8.by" ]; then RESOLVED_BY="$(cat "$PIN_DIR/$LIVE8.by")"   # the resolver says how it decided
  else RESOLVED_BY="content-match"; fi                  # automatic, self-verifying
else
  json_refuse "could not identify your task store" "task-table.sh --session <sid8>, or --pin <sid8>" && exit 3
  {
    echo "task-table: could not identify your task store."
    echo
    # the resolver's own reason first: it names the project-stamped stores when
    # the session's own store is empty and the real rows are inherited
    [ -s "${RESOLVER_ERR:-}" ] && sed 's/^/  /' "$RESOLVER_ERR" && echo
    echo "  Content-matching against this session's transcript found no decisive"
    echo "  store, so nothing is guessed: a confident wrong table is the defect"
    echo "  this refusal exists to prevent. Live session: ${LIVE8:-unknown}"
    echo
    echo "  Candidates, newest first:"
    candidates
    echo
    echo "  Read one directly:  bash ~/.claude/scripts/task-table/task-table.sh --session <sid8>"
    echo "  Or pin it:          bash ~/.claude/scripts/task-table/task-table.sh --pin <sid8>"
  } >&2
  exit 4
fi
export RESOLVED_BY

# The grouping the owner ruled for THIS project lives in a file the tool reads, not in
# a memory the agent has to remember to open. automation, 2026-08-18, after a 4th S3:
# "the gcc's own default actively teaches the shape the owner has rejected four times,
# and the only thing carrying the ruling is a project memory file". So: a project
# view file outranks the baseline, --group outranks the file for one call, and
# --set-group writes the file. Inside the gcc itself the file sits at its root.
# the project root is the git toplevel when inside a repo (a subdir cwd must still find the
# project's view file: gcp-fable rendered from contract/plans and got no lanes), else the cwd
# The store knows its own project (task.sh and --pin write it to <store>/.project);
# the shell's directory is only the fallback. On 2026-09-07 the forge-console
# ruling was lost because the shell sat in a sibling repo when /tasks ran.
if [ -n "$DIR" ] && [ -s "$DIR/.project" ] && [ -d "$(cat "$DIR/.project")" ]; then PROOT=$(cat "$DIR/.project")
else PROOT=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null); [ -n "$PROOT" ] || PROOT="$PWD"; fi
VIEW_DIR="$PROOT/.claude"; case "$PROOT" in "$HOME/.claude"|"$HOME/.claude/"*) VIEW_DIR="$HOME/.claude";; esac
VIEW_FILE="$VIEW_DIR/tasks-view.json"
if [ -n "$SETGROUP" ]; then
  mkdir -p "$VIEW_DIR"
  if [ -f "$VIEW_FILE" ]; then jq --arg g "$SETGROUP" '.group=$g' "$VIEW_FILE" > "$VIEW_FILE.tmp" && mv -f "$VIEW_FILE.tmp" "$VIEW_FILE"
  else jq -n --arg g "$SETGROUP" '{group:$g, order:[], labels:{}, "_edit":"order: list the group keys in the order you want; labels: {key: display name}"}' > "$VIEW_FILE"; fi
  echo "tasks view for this project: group=$SETGROUP  ($VIEW_FILE)"; exit 0
fi
# Who is rendering: the ipc alias (from the roster, by session id) and the model (from
# the transcript's last assistant line). Both are best-effort; a miss prints "?".
ALIAS=$(claude-ipc peers 2>/dev/null | jq -r --arg s "${CLAUDE_CODE_SESSION_ID:-}" '[.peers[] | select(.sessionId==$s) | .sessionAliases[]?] | map(select(startswith("claude-")|not)) | last // empty' 2>/dev/null)
MODEL=""
for cand in "$PWD" "$PROOT" "$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)"; do
  [ -n "$cand" ] || continue
  TR="$HOME/.claude/projects/$(echo "$cand" | sed 's#[/.]#-#g')/${CLAUDE_CODE_SESSION_ID:-none}.jsonl"
  [ -f "$TR" ] && { MODEL=$(tail -n 80 "$TR" 2>/dev/null | rg -o '"model":"[^"]+"' | tail -1 | cut -d'"' -f4); [ -n "$MODEL" ] && break; }
done
[ -n "$MODEL" ] || MODEL=$(jq -r '.model // empty' "$VIEW_DIR/tasks-view.json" 2>/dev/null)
# The armed /goal in the owner's words rides line 1 (Q7a, ruled 2026-09-05), so
# the reader can tell his goal from the goal TAGS the count below is made of.
ARMED_GOAL=""
[ -n "$LIVE" ] && ARMED_GOAL=$(bash "$HOME/.claude/scripts/goal/goal.sh" harness --sid "$LIVE" 2>/dev/null | jq -r 'select(.armed==true) | .text // empty' 2>/dev/null)
# Test seam: the suites run with no live harness goal, and the /goal line is a
# ruled surface (D2b) that has to be exercised.
[ -n "${TASKS_ARMED_GOAL:-}" ] && ARMED_GOAL="$TASKS_ARMED_GOAL"
ALIAS="$ALIAS" MODEL="$MODEL" DETAIL="$DETAIL" MODE="$MODE" DIR="$DIR" GCC="$HOME/.claude" RESOLVED_BY="$RESOLVED_BY" GROUP="$GROUP" VIEW_FILE="$VIEW_FILE" PROOT="$PROOT" ARMED_GOAL="$ARMED_GOAL" python3 - <<'PY'
import calendar, json, os, re, pathlib, sys, time

mode = os.environ["MODE"]; d = pathlib.Path(os.environ["DIR"]); G = pathlib.Path(os.environ["GCC"])
resolved_by = os.environ.get("RESOLVED_BY", "explicit")
HEIGHT = 44

rows = []
for f in d.glob("*.json"):
    # A task file carries no timestamp of its own, so mtime is the only age
    # signal there is. Keeping it is what lets the header say whether these
    # rows have moved recently or are an accumulated store rendered as today.
    try:
        r = json.load(open(f))
        r["_mtime"] = f.stat().st_mtime
        rows.append(r)
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

def _wcut(s, n):
    """Cut at a word and say so. refs_for runs before ellip() is defined, and a
    bare [:88] here reached the screen through --refs and --detail mid-word
    ("the mid-e"); the second seat on #59 caught it on this row's own subject."""
    return s if len(s) <= n else s[:n - 1].rsplit(" ", 1)[0] + "…"
def refs_for(r):
    """Every reference in a task, with a gloss a stranger could use."""
    text = subj(r) + " " + desc(r); out = []
    seen = set()
    def add(kind, key, gloss):
        if key in seen: return
        seen.add(key); out.append({"kind": kind, "ref": key, "gloss": gloss})
    for m in RE_PROP.findall(text):
        p = props.get(m)
        add("proposal", m, (_wcut(p.get("title", ""), 88) + f"  [{p.get('status','?')}]") if p
            else "not in the ledger (dropped or rejected)")
    for m in RE_TASK.findall(text):
        t = by_id.get(int(m))
        if t: add("task", f"#{m}", f"{_wcut(subj(t), 88)}  [{t.get('status','?')}]")
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
# blocked_on is free text by design, and the convention prefixes it with who is
# blocked: "USER: needs your ruling" versus "AGENT: mine to build". The table
# painted ANY non-empty value as owner-gated, so a row saying AGENT rendered
# under GATES (you) in the owner's colour. gcp-fable reported three such rows on
# 2026-08-26 and gcc-kanban reproduced it on its own queue the same day, in the
# list it was about to hand the owner.
#
# The imprecision of the field is deliberate and stays: it is what let gcp-fable
# discover eleven "owner gates" that were its own sequencing notes. The fix is to
# READ the prefix the convention already writes, not to make the field an enum.
# Three states, not two (prop 2026-08-27, gcp rows #5 and #168): USER: is an owner gate
# the owner can act on today; AGENT:/ME:/SELF: is the agent's own wait; BLOCKED-BY:,
# AFTER:, EXTERNAL:, WAITING: name other work or another actor and are neither
# agent-ready nor the owner's to act on. Only the first band reaches GATES (you).
# The keyword ends at a WORD BOUNDARY, and the colon is optional, because that is
# how the convention is actually written. Requiring a colon immediately after the
# keyword meant "blocked-by #404: gcp-watcher gates the board" did not match, since
# its colon sits after the task number. Measured on session f04ae843 on 2026-09-04:
# 14 of 14 rows carrying blocked_on were painted as owner gates, and only 2 of them
# began with USER:. The owner read a 16-row GATES band that had 2 real rows in it,
# and every other row in the queue was pushed off screen by the height cap.
AGENT_BLOCKED = re.compile(
    r"^\s*(AGENT|ME|SELF|BLOCKED[-_ ]?BY|BLOCKED|AFTER|DEPENDS[-_ ]?ON|"
    r"EXTERNAL|WAITING|SEQUENCED|PLAN)\b", re.I)
def gated(r):
    # One definition of "gate". The ruled state, when a row carries one, decides
    # first: `owner-gate` is a gate and every other declared state is not. Before
    # this, gated() never read metadata.state while row_state() did, so a row
    # written `--state owner-gate` painted 🔴 and was invisible to CLEAR NOW, the
    # steer count, the staleness check and gated-first ordering (adv-tasks F4).
    st = (meta(r, "state") or "").lower()
    if st == "owner-gate": return True
    if st in ("blocked", "active", "review", "deferred", "done", "unassigned"): return False
    b = meta(r, "blocked_on")
    if b: return not AGENT_BLOCKED.match(str(b))
    # An explicit lane beats prose inference. A row the agent has claimed
    # (lane gcc) is not owner-gated because its description mentions "needs
    # you": #48 on 2026-08-23 was ABOUT needs-human cards and rendered as a
    # gate, which hid its whole batch. Inference is for rows nobody labelled.
    lane = (meta(r, "lane") or "").lower()
    if lane and lane != "owner": return False
    if lane == "owner": return True
    return bool(GATE.search(desc(r)) or GATE.search(subj(r)))
def gate_declared(r):
    if (meta(r, "state") or "").lower() == "owner-gate": return True
    return bool(meta(r, "blocked_on")) and not AGENT_BLOCKED.match(str(meta(r, "blocked_on")))

# The store carries real dependency edges in blockedBy, and the table used to
# ignore them entirely: a row sequenced behind an in-progress task rendered as
# AGENT-READY. That is the one direction this table must not get wrong, because
# AGENT-READY is the section an agent picks work from. Peer gcc-fable hit it on a
# 20-task store, 2026-08-18; my own store could not expose it, because its only
# two edges pointed at a task that had already completed.
# Task files in the wild carry status "done" as well as "completed": 7 rows across
# this machine, all in one peer's store, and the renderer counted every one as
# "other" and dropped it from the done line, so finished work went invisible
# (vb-fable, 2026-08-20). Read both; write only "completed".
def _is_done(x): return (x.get("status") or "") in ("completed", "done")

_OPEN_IDS = {num(r) for r in rows if r.get("status") not in ("completed", "done", "deleted")}
def waits_on(r):
    """Blockers that are still open. A closed blocker is not a blocker."""
    out = []
    for b in (r.get("blockedBy") or []):
        try: bi = int(re.sub(r"\D", "", str(b)) or 0)
        except Exception: continue
        if bi in _OPEN_IDS: out.append(bi)
    return out
def backlog(r): return bool(RE_PROP.search(desc(r)))

def enrich(r):
    return {
        "id": num(r), "subject": subj(r), "status": r.get("status", "pending"),
        "gated": gated(r), "source": "backlog" if backlog(r) else "session",
        # Carried through because the GATES band flags an ask nobody has touched
        # in a day: a gate goes false by being satisfied, and recency is the only
        # signal for that. Dropping it here made the check a silent no-op.
        "_mtime": r.get("_mtime"),
        # Set at TaskCreate time; never inferred. An inferred class would be
        # wrong in a way no reader could see.
        "class": meta(r, "class", ""), "domain": meta(r, "domain", ""),
        "blocked_on": meta(r, "blocked_on", ""), "gate_declared": gate_declared(r),
        "blocked_on_at": meta(r, "blocked_on_at", ""), "batch_at": meta(r, "batch_at", ""),
        "board_card": meta(r, "board_card", ""),
        "waits_on": waits_on(r),
        # The glyph column reads these two. They were never produced, so the
        # ⏳ and ✅ branches were dead and every inferred-gate row rendered as
        # ○ "nothing blocking it" (independent review 2026-08-18, C2).
        "blocked": gated(r) and not gate_declared(r),
        "verified": meta(r, "verified", None),
        # --json dropped these, so any batch or sequence view had to be rebuilt
        # by hand from the store files (gcc-fable, 2026-08-18). They are cheap.
        "blockedBy": r.get("blockedBy") or [], "blocks": r.get("blocks") or [],
        "metadata": r.get("metadata") or {},
        # A checker reads "description" first; the text sat under "_desc" only,
        # so every row read as empty (forge-console, ledger 47, 2026-09-08).
        "refs": refs_for(r), "description": desc(r), "_desc": desc(r),
        "desc_chars": len(desc(r)),
    }

data = [enrich(r) for r in rows]
now     = [x for x in data if x["status"] == "in_progress"]
openish = [x for x in data if x["status"] == "pending"]
done    = [x for x in data if _is_done(x)]
def _deleg(x): return (x.get("metadata") or {}).get("delegated_to") or ""
# A delegated row is neither the owner's to decide nor this agent's to pick up.
# Counting it as either makes the queue dishonest, which is what made a peer's
# 42-gate render unreadable: five of those rows were merely FILED in their store.
delegated = [x for x in openish if _deleg(x)]
blocked = [x for x in openish if x["gated"] and not _deleg(x)]
# Sequenced behind another open task: not owner-gated, but not pickable either.
waiting = [x for x in openish if not x["gated"] and x["waits_on"] and not _deleg(x)]
ready   = [x for x in openish if not x["gated"] and not x["waits_on"] and not _deleg(x)]

if mode == "refs":
    seen = {}
    for x in data:
        if _is_done(x): continue
        for rf in x["refs"]: seen.setdefault(rf["ref"], rf)
    for k in sorted(seen):
        rf = seen[k]; print(f"  {rf['kind']:<12} {k:<28} {rf['gloss']}")
    sys.exit()

if mode == "unfiled":
    # Containment, measured rather than enforced. Whether a goal-less row is
    # malformed, and whether a milestone is mandatory at all, are OWNER rulings
    # (decision page tasks-redesign-0904, D3 and D6). So this reports and does
    # not warn: wiring it into the footer would answer those questions by
    # rendering, which is how a ruling gets made by momentum instead of by the
    # owner. Measured on the largest store the day it was written: 103 of 178
    # open rows were unfiled, 59 of them carrying neither.
    # meta_of is defined further down (line 475), after the early-exit modes.
    _mt = lambda x, k: (x.get("metadata") or {}).get(k) or ""
    _open = [x for x in data if not _is_done(x)]
    _nog = [x for x in _open if not _mt(x, "goal")]
    _noms = [x for x in _open if not _mt(x, "batch")]
    _neither = [x for x in _open if not _mt(x, "goal") and not _mt(x, "batch")]
    _filed = len(_open) - len({id(x) for x in _nog} | {id(x) for x in _noms})
    print(f"open rows: {len(_open)}")
    print(f"  filed under a goal AND a milestone : {_filed}")
    print(f"  no goal                            : {len(_nog)}")
    print(f"  no milestone                       : {len(_noms)}")
    print(f"  neither                            : {len(_neither)}")
    for _label, _rows in (("no goal", _nog), ("no milestone", _noms), ("neither", _neither)):
        if not _rows: continue
        _ids = " ".join(f"#{x['id']}" for x in _rows[:40])
        _more = "" if len(_rows) <= 40 else f" … +{len(_rows)-40} more"
        print(f"\n{_label} ({len(_rows)}): {_ids}{_more}")
    sys.exit()

if mode == "compact":
    # A cut names itself: a hard slice ended subjects mid-word with no mark, which
    # reads as corrupt output (visual audit V4, V5; #59). ellip() is defined
    # further down, so the digest carries its own word-boundary cut.
    _s = now[0]["subject"] if now else ""
    _s = _s if len(_s) <= 48 else _s[:47].rsplit(" ", 1)[0] + "…"
    nowtxt = f"#{now[0]['id']} {_s}" if now else "nothing in progress"
    # Every open row lands in a named bucket. `waiting` existed and was never
    # printed, so a 3-task store with two sequenced rows reported "3 open (0 need
    # you, 1 agent-ready)" and left two rows unaccounted for. This digest is what
    # scripts/hooks/task-table-inject.sh:84 puts into every agent's context, so an
    # unexplained remainder there is worse than in the table a human reads.
    _buckets = f"{len(blocked)} need you, {len(ready)} agent-ready"
    if waiting: _buckets += f", {len(waiting)} sequenced"
    if delegated: _buckets += f", {len(delegated)} delegated"
    # The buckets partition `openish`, which is pending-only (line 387), while
    # `now` is in_progress. Summing them made the remainder negative on every
    # store with a running row: 177 open reported "-3 uncategorised".
    _acct = len(blocked) + len(ready) + len(waiting) + len(delegated)
    if now: _buckets += f", {len(now)} running"
    if _acct != len(openish): _buckets += f", {len(openish) - _acct} uncategorised"
    print(f"tasks: {len(openish)} open ({_buckets}), {len(done)} done")
    print(f"  now: {nowtxt}")
    if blocked: print("  needs you: " + ", ".join(f"#{x['id']}" for x in blocked))
    # The digest is the documented fallback for a capped render, and a fallback
    # that prints counts and bare ids cannot answer "what is left" (sys-monitor,
    # 2026-09-08). Twelve open rows with a subject each, the rest counted.
    def _c(t):
        t = t.get("subject", ""); return t if len(t) <= 64 else t[:63].rsplit(" ", 1)[0] + "…"
    _rest = [x for x in openish if x not in blocked]
    for x in (blocked + _rest)[:12]:
        print(f"  {'!' if x in blocked else '○'} #{x['id']} {_c(x)}")
    if len(openish) > 12: print(f"  … +{len(openish) - 12} more open; the full table or --json names them")
    sys.exit()

# ---- the batched-sequence view (owner-ratified 2026-08-19) -----------------------
# The owner's words: "grouped by GOAL, then BATCH (a sequence), one row per task with a
# lane·model tag and a state glyph (done, in progress, sequenced-behind #x, needs-you),
# gates and deferred and after-V1 as their own bands, a legend naming the lanes"
# (memory feedback_tasks-view-batched-sequences.md, relayed by gcp-fable; bundle and
# rulings in assets/reports/20260819-tasks-audit/plan.md). No vertical box borders: the
# previous grid broke whenever a glyph's terminal width differed from the guess, and a
# ruled layout cannot break, only jitter one row. Every stored field prints somewhere.
view = {}
vf = os.environ.get("VIEW_FILE", "")
if vf and os.path.exists(vf):
    try: view = json.load(open(vf))
    except Exception: view = {"_broken": vf}
detail = os.environ.get("DETAIL", "0") == "1"
alias = os.environ.get("ALIAS", "") or "?"; model = os.environ.get("MODEL", "") or "?"
group_flag = os.environ.get("GROUP", "") or ""
group_src = "flag" if group_flag else ("project view file" if view.get("group") else "auto")
group = group_flag or view.get("group") or "auto"
live = now + openish
def meta_of(x, k): return (x.get("metadata") or {}).get(k) or ""
# Probe the rows that will actually be BANDED. With nothing open that is the done
# rows, and reading `live` there returned empty for every key, so auto-grouping
# fell through to "actor" and grouped a finished store by a field none of it had.
_probe = live if live else [x for x in rows if _is_done(x)]
def has_meta(k): return any(meta_of(x, k) for x in _probe)
def coverage(k):
    return (sum(1 for x in _probe if meta_of(x, k)) / len(_probe)) if _probe else 0.0
if group == "auto":
    # Group by a key MOST rows actually carry. The old test was any(), so a single
    # row bearing a goal made goal the grouping key for the whole store: on
    # 2026-09-04 the owner's queue had goal on 82 of 180 open rows and the other
    # 98 landed in one band titled "GOAL (no goal)", which is the largest band on
    # screen and names nothing. Domain covered 161 of 180 and would have grouped
    # the same queue usefully.
    #
    # Preference order still favours goal, because a goal is what the owner
    # thinks in; the bar just stops a sparse key from winning on a technicality.
    BAR = 0.70
    ladder = ["goal", "batch", "domain", "class"]
    group = next((k for k in ladder if coverage(k) >= BAR), "")
    if not group:
        # Nothing is well covered. Take the best of a bad set rather than falling
        # to actor, which splits by a field the rows may not carry either.
        best = max(ladder, key=coverage)
        group = best if coverage(best) > 0 else "actor"
    group_src += f" → {group} ({coverage(group):.0%} of open rows carry it)"
# a lane·model tag: metadata.lane + metadata.tier (or model); "?" marks an unset tier loudly
def lane_tag(x):
    lane = meta_of(x, "lane") or meta_of(x, "owner"); tier = meta_of(x, "tier") or meta_of(x, "model")
    if lane and tier: return lane if lane == tier else f"{lane}·{tier}"
    return (lane or "") + ("·?" if lane and not tier else ("?" if not lane and not tier else tier))
# A deferral marker LEADS a label ("after V1", "later", "backlog"); it is not any
# occurrence of those words inside prose. Searching the whole string silently
# banished a lane whose goal read "... after the console handover", and any batch
# whose label mentioned deploy (vb-fable 2026-08-20, and the 2026-08-20 review).
# "deploy" is dropped outright: deploying is active work, never deferred work.
# Deferral is a declaration, not a word-sighting: metadata.defer wins, and a batch
# or goal defers only when its WHOLE value is a defer word ("later", "parked"), never
# because prose happens to start with one ("after V1 polish" moved a whole lane to
# LATER on 2026-08-19, vb-fable). Prefix-matching prose was the bug.
DEFER = re.compile(r"^\s*(after v1|later|parked|someday|backlog|deferred)\s*$", re.I)
def deferred(x):
    if meta_of(x, "deferred"): return True          # the declared form always wins
    if str(meta_of(x, "defer")).lower() in ("true", "1", "yes"): return True
    return any(DEFER.match(str(meta_of(x, k))) for k in ("batch", "goal"))
def actor_bucket(x):
    if x["status"] == "in_progress": return "NOW"
    if x["gated"]: return "NEEDS YOU"
    if x.get("waits_on"): return "WAITING ON ANOTHER TASK"
    return "AGENT-READY"
def key_of(x, k=None):
    k = k or group
    if k == "actor": return actor_bucket(x)
    v = meta_of(x, k)
    return str(v) if v else "(no %s)" % k
def natkey(k):
    late = 1 if re.search(r"\b(after|later|parked|someday|backlog|deferred)\b", str(k), re.I) else 0
    return [late] + [int(t) if t.isdigit() else t.lower() for t in re.split(r"(\d+)", str(k))]
labels = view.get("labels") or {}
lanes_legend = view.get("lanes") or {}

# The sequence inside a batch is the blockedBy chain: roots first, then what waits on
# them, ties by id. That is where "sequenced-behind #x" comes from, not a seq column.
def seq_sort(items):
    ids = {x["id"] for x in items}; placed, out = set(), []
    pool = sorted(items, key=lambda x: (0 if x["status"] == "in_progress" else 1, x["id"]))
    while pool:
        progressed = False
        for x in list(pool):
            deps = [d for d in x.get("waits_on") or [] if d in ids and d not in placed]
            if not deps:
                out.append(x); placed.add(x["id"]); pool.remove(x); progressed = True
        if not progressed:  # a cycle or a dependency outside the batch: emit by id
            x = pool.pop(0); out.append(x); placed.add(x["id"])
    return out

# A gated row STAYS in its goal. The old layout moved it to a separate GATES
# band, which is why the owner met a screen of work he could not act on with the
# rest of the queue pushed off it. The ruled layout surfaces the clearable gates
# in CLEAR NOW at the top and still draws each one under the goal it belongs to,
# so the goal's own ball can report that it needs him.
# Deferred rows are not this agent's to run and are not part of any goal's
# forward path, so those still leave. A row that is both deferred and gated is
# kept, because a gate is a thing the owner can act on today.
core = [x for x in live if not _deleg(x) and (x["gated"] or not deferred(x))]
gates = [x for x in live if x["gated"] and not _deleg(x)]
later = [x for x in live if deferred(x) and not x["gated"] and not _deleg(x)]
ordered_keys = []
for k in (view.get("order") or []):
    if k not in ordered_keys: ordered_keys.append(k)
if group == "actor":
    for k in ["NOW", "NEEDS YOU", "WAITING ON ANOTHER TASK", "AGENT-READY"]:
        if k not in ordered_keys: ordered_keys.append(k)
for k in sorted({key_of(x) for x in core}, key=natkey):
    if k not in ordered_keys: ordered_keys.append(k)
groups = {k: [x for x in core if key_of(x) == k] for k in ordered_keys}
groups = {k: v for k, v in groups.items() if v}
# THE UNFILED BAND, ruled D3b 2026-09-04. Owner note, verbatim: "We should allow
# it, but nudge the agent to assign it to a goal if possible".
#
# The bucket already existed and was the problem. A row with no goal landed in a
# band titled "GOAL (no goal)", which sorted alphabetically among the real goals
# and named nothing. On the owner's queue that band held 98 of 180 rows and was
# the largest thing on screen, sitting between two real outcomes as though it
# were a third.
#
# D3b keeps the rows and changes where they sit and what they say. Last, so real
# goals are read first, and labelled for what it is rather than for a field that
# is absent. The nudge carries the flags, because "assign it to a goal" without
# the command is a chore rather than an instruction.
UNFILED_KEY = "(no goal)" if group == "goal" else None
if UNFILED_KEY and UNFILED_KEY in groups:
    _unfiled_rows = groups.pop(UNFILED_KEY)
    groups[UNFILED_KEY] = _unfiled_rows      # re-inserted last; dicts keep order
sub = "batch" if group != "batch" and has_meta("batch") else None   # goal › batch when both exist

if mode == "json":
    print(json.dumps({"store": str(d), "group": group, "sub": sub, "group_source": group_src,
        "groups": {k: [x["id"] for x in seq_sort(v)] for k, v in groups.items()},
        "gates": [x["id"] for x in gates], "later": [x["id"] for x in later],
        # The ids the footer stopped printing (Q8a): rows whose file moved in the
        # recency window, newest first.
        "moved_recently": [x["id"] for x in sorted(
            (x for x in rows if (time.time() - (x.get("_mtime") or 0)) < 6 * 3600
             and (_is_done(x) or x["status"] == "in_progress")),
            key=lambda x: -(x.get("_mtime") or 0))],
        "counts": {"total": len(data), "in_progress": len(now), "open": len(openish),
        "done": len(done), "blocked": len(blocked), "ready": len(ready)},
        "tasks": data}, indent=2)); sys.exit()

import unicodedata, hashlib, collections

# Display width.
# Emoji are two columns and box-drawing characters are one, so every column in
# this layout is computed rather than counted with len(). The subtle half is the
# variation selector: the gear on its own is one column (East-Asian "ambiguous")
# and the same character followed by U+FE0F is two, because the selector asks for
# the emoji picture rather than the text glyph. Counting the selector as its own
# character happens to give the right total and would drift the moment a glyph
# carried a skin tone or a ZWJ join, so the scan is written properly instead.
VS16, VS15, ZWJ = "️", "︎", "‍"
def _base_w(ch):
    if unicodedata.east_asian_width(ch) in ("W", "F"): return 2
    if 0x1F300 <= ord(ch) <= 0x1FAFF: return 2
    return 1
def dwidth(s):
    n, i, L = 0, 0, len(s)
    while i < L:
        ch = s[i]
        if ch in (VS16, VS15) or unicodedata.category(ch) in ("Mn", "Me", "Cf"):
            i += 1; continue
        wch = _base_w(ch)
        if i + 1 < L and s[i+1] == VS16: wch = 2
        elif i + 1 < L and s[i+1] == VS15: wch = 1
        n += wch; i += 1
        # everything hanging off the base character adds no columns of its own
        while i < L:
            c = s[i]
            if c in (VS16, VS15) or unicodedata.category(c) in ("Mn", "Me"): i += 1; continue
            if 0x1F3FB <= ord(c) <= 0x1F3FF: i += 1; continue
            if c == ZWJ: i += 2 if i + 1 < L else 1; continue
            break
    return n
def dljust(s, wd): return s + " " * max(0, wd - dwidth(s))
def ellip(s, wd):
    """Trim to width at a word boundary, marking that the text continues."""
    if wd <= 1: return ""
    if dwidth(s) <= wd: return s
    cut, acc = "", 0
    for ch in s:
        cw = dwidth(ch)
        if acc + cw > wd - 1: break
        cut += ch; acc += cw
    sp = cut.rfind(" ")
    return (cut[:sp] if sp > wd // 2 else cut) + "…"
def wrap(text, width):
    words, lines, cur = text.split(), [], ""
    for wd in words:
        if cur and dwidth(cur) + 1 + dwidth(wd) > width: lines.append(cur); cur = wd
        else: cur = (cur + " " + wd) if cur else wd
    if cur: lines.append(cur)
    return lines or [""]
def _age(sec):
    m = sec / 60
    return f"{int(m)}m" if m < 60 else (f"{m/60:.0f}h" if m < 48*60 else f"{m/1440:.0f}d")

# The subject with a redundant leading priority token removed. Many rows carry
# the priority in the subject text AND in metadata.priority, so the renderer
# printed it twice ("P2 P2 Vocabulary terms"). Strip it only when the two AGREE:
# two rows disagree, and that is a real conflict about how urgent the work is.
_PRIO_HEAD = re.compile(r"^\s*(P\d(?:\.\d)?)\s+")
def prio(x):
    v = meta_of(x, "priority")
    return f"{v} " if v else ""
def subject_of(x):
    s = x["subject"]
    v = meta_of(x, "priority")
    m = _PRIO_HEAD.match(s or "")
    if not (v and m): return s
    if m.group(1) == str(v): return s[m.end():]
    return f"(subject says {m.group(1)}) " + s[m.end():]
# Who wanted the row rides the subject as one glyph, so speculation shows without a
# fifth trait column: 🗣 the owner asked, 📏 a number or file:line backs it, 💭 an
# agent inferred it (forge-console's 180-row pilot, 2026-09-07: 49 · 73 · 58).
ORIGIN_GLYPH = {"asked": "\U0001F5E3", "measured": "\U0001F4CF", "inferred": "\U0001F4AD"}
_origins_used = set()
def titled(x):
    og = ORIGIN_GLYPH.get(str(meta_of(x, "origin") or "").lower(), "")
    if og: _origins_used.add(og)
    return (og + " " if og else "") + prio(x) + subject_of(x)

# The fixed column grid.
# Owner spec: "Every column position is fixed rather than eyeballed." Fixed per
# render and computed once from the data, so a four-digit id widens the id cell
# for every row instead of shunting one row's title out of line.
# Width is the free axis: owner 2026-08-13, "It can be wider, that's fine". 92 is
# the floor (the approved sketch), and a wider terminal gets a wider box. When
# output is piped (the injector, a hook, a peer's capture) there is no terminal
# and the fallback IS the floor, so captured renders stay byte-stable.
import shutil as _shutil
BOX_W     = max(92, min(160, _shutil.get_terminal_size(fallback=(92, 44)).columns - 2))
MS_COL    = 4           # the milestone marker
# A note folded onto the trait row has to survive the fold. Below this many
# columns it would be clipped to a stub that costs a reader more than the line
# it saved, so it drops to its own full-width line instead.
MIN_INLINE_NOTE = 28
BALL_COL  = 6           # the state ball
ID_COL    = 11          # the task number, and the trait row and note under it
XNOTE_COL = 6           # an expanded note, left of the trait indent
IDW       = max(5, max((len(str(x["id"])) + 3 for x in data), default=5))
TITLE_COL = ID_COL + IDW + 1
TITLE_W   = BOX_W - TITLE_COL + 1

# State, ball, twin.
# Five states, ruled (REDESIGN.md, "Five states"), with D7's residual
# `unassigned`. The ball carries urgency in colour and the twin carries the same
# fact in shape, so the table survives a terminal with no emoji and a reader who
# cannot separate red from green.
BALL = {"gate": "\U0001F534", "waiting": "\U0001F7E0", "running": "\U0001F535",
        "ready": "\U0001F7E2", "review": "\U0001F7E3", "unassigned": "⚪",
        "delegated": "\U0001F91D", "later": "\U0001F4A4", "done": "✅"}
TWIN = {"gate": "!", "waiting": "~", "running": "▶", "ready": "○", "review": "=",
        "unassigned": "·", "delegated": "@", "later": "z", "done": "x"}
LEGEND_NAME = {"gate": "needs you", "waiting": "after a task", "running": "running",
               "ready": "ready", "review": "in review", "unassigned": "unassigned",
               "delegated": "delegated", "later": "deferred", "done": "done"}
LEGEND_ORDER = ["gate", "waiting", "running", "ready", "review", "unassigned",
                "delegated", "later", "done"]

# The seven ruled states (task.sh TASK_STATES) onto this renderer's vocabulary.
# Without this the write path accepted --state review and --state deferred,
# stored them, and the table drew both as a green ready ball: a row parked on
# purpose read as a row waiting to be picked up.
DECLARED_STATE = {"owner-gate": "gate", "blocked": "waiting", "active": "running",
                  "review": "review", "deferred": "later", "done": "done",
                  "unassigned": "unassigned"}

def row_state(x):
    # Terminal status wins over any declared state: task.sh done writes status
    # and leaves metadata.state alone, so a row closed while blocked keeps
    # state=blocked forever and would otherwise render as still blocked.
    if _is_done(x):                   return "done"
    declared = DECLARED_STATE.get(meta_of(x, "state") or "")
    if declared:                      return declared
    if x["gated"]:                    return "gate"
    if _deleg(x):                     return "delegated"
    if x["status"] == "in_progress":  return "running"
    if x.get("waits_on"):             return "waiting"
    if deferred(x):                   return "later"
    # D7's residual. A row nobody holds, with no lane and no tier, is not
    # "ready": ready means an agent could pick it up and one glance says who.
    if not (meta_of(x, "lane") or meta_of(x, "owner") or meta_of(x, "tier") or meta_of(x, "model")):
        return "unassigned"
    return "ready"

_states_used = set()
def ball_of(x):
    s = row_state(x); _states_used.add(s); return BALL[s], TWIN[s]

# Traits: one column each, never stacked.
# D1 note, verbatim: "use column for one trait only (no stacking of lane / model
# / other tags in a single col)". The markers are shapes rather than punctuation,
# because @ ^ : / are borrowed from other grammars and the eye tries to parse
# them; diamonds are about the runner, squares about the work.
TRAIT_MARK = ["◆", "◇", "▪", "▫"]
def trait_values(x):
    """lane, tier, kind, domain: each its own cell, each value printed once.

    A row can carry a pre-joined value in a single-value field (#294 has
    domain="ui · forge" beside class="ui"), and a value already shown in a cell
    to its left spends a column saying nothing. Split, then drop what is already
    on screen: the same dedup the old single tag cell did, kept now that the
    columns are separate.
    """
    raws = (meta_of(x, "lane") or meta_of(x, "owner"),
            meta_of(x, "tier") or meta_of(x, "model"),
            meta_of(x, "class"),
            meta_of(x, "domain"))
    seen, vals = set(), []
    for raw in raws:
        parts = [p.strip() for p in re.split(r"\s*·\s*", str(raw or "")) if p.strip()]
        keep = [p for p in parts if p.casefold() not in seen]
        for p in keep: seen.add(p.casefold())
        vals.append(" · ".join(keep))
    return vals
# Each trait column is sized to ITS OWN widest value, not to the widest value
# anywhere. One shared width let a long kind like "measure-then-tune" pad the
# lane column to match, spending twelve columns on the word "hands" four times a
# row. Per-column keeps one trait per column and the vertical alignment that
# makes the columns scannable, and hands the reclaimed width to the note, which
# is what lets a note ride the trait row instead of costing a third line.
TRAITWS = []
for _i in range(len(TRAIT_MARK)):
    _w = 4
    for _x in (live or done):
        _v = trait_values(_x)[_i]
        # 12 clipped real kinds to "measure-the…" and "gate-adhere…" while the
        # capped axis had lines to spare (adv-tasks F10). Per-column sizing means
        # a long value only widens its own column.
        if _v: _w = max(_w, min(24, dwidth(_v)))
    TRAITWS.append(_w + 3)   # marker + space + value + gutter
TRAITW = max(TRAITWS)        # kept: callers that still want one nominal width

# The goal box.
# The emoji identifies the goal and the ball reports it. They answer different
# questions and neither may replace the other: the ball changes as work moves,
# the emoji is stable for the life of the goal, and a field that changes cannot
# do the job of one that does not (final.md, "The regression, recorded").
DOMAIN_EMOJI = {
    "tasks": "⚙️", "goals": "\U0001F3AF", "hooks": "\U0001FA9D",
    "ui": "\U0001F3A8", "ops": "\U0001F527", "docs": "\U0001F4C4",
    "rules": "\U0001F4D0", "skills": "\U0001F9E9", "forge": "\U0001F3ED",
    "foundry": "\U0001F52C", "runner": "\U0001F3C3", "walmart": "\U0001F6D2",
    "kit": "\U0001F9F0", "build": "\U0001F528", "contract": "\U0001F4DC",
    "architecture": "\U0001F9F1", "auth": "\U0001F511", "console": "\U0001F4BB",
    "tests": "\U0001F9EA", "memory": "\U0001F9E0", "kanban": "\U0001F4CB",
    "ipc": "\U0001F4E1", "plan": "\U0001F9ED", "synth": "\U0001F9EC",
}
FALLBACK_EMOJI = ["\U0001F300", "\U0001F537", "\U0001F536", "\U0001F7E3",
                  "\U0001F7E4", "\U0001F9FF", "\U0001FA90", "\U0001F340",
                  "\U0001F53A", "\U0001F9CA"]
def goal_emoji(key, items):
    # Derived over EVERY row of the goal, done included. Counting open rows only
    # let the glyph move when ordinary work closed (🪝 to 🎨 after three of five
    # rows finished; adv-tasks F6), which defeats the one job the emoji has:
    # identifying the same goal across sessions. `items` is the open set the
    # caller holds; the full set is read from the store here.
    _all = [x for x in rows if _g_of(x) == key] if key else []
    if _all: items = _all
    doms = [dm for x in items for dm in
            (p.strip().lower() for p in re.split(r"\s*·\s*", str(meta_of(x, "domain") or "")))
            if dm]
    if doms:
        top, n = collections.Counter(doms).most_common(1)[0]
        if top in DOMAIN_EMOJI and n * 2 >= len(doms): return DOMAIN_EMOJI[top]
    h = int(hashlib.sha1(str(key).encode("utf-8", "replace")).hexdigest()[:8], 16)
    return FALLBACK_EMOJI[h % len(FALLBACK_EMOJI)]

# Precedence, and it is deliberately not a simple worst-case: the ball answers
# "can this goal continue without him, right now". An owner gate anywhere makes
# the answer no, whatever else is pickable. Otherwise ready beats running,
# because a goal with work waiting to be taken is more continuable than one
# already mid-flight. The ball is NEVER any single task's state.
BALL_RANK = ["gate", "ready", "running", "review", "waiting", "unassigned",
             "delegated", "later", "done"]
def goal_ball(items):
    have = {row_state(x) for x in items}
    for s in BALL_RANK:
        if s in have: return BALL[s]
    return BALL["unassigned"]

def thin_flag(name):
    """Owner 2026-09-05: a milestone name may be as short as a three-letter
    acronym, 'enough to be remembered and associative'. Below that it carries
    nothing, and 'next: A' tells the reader less than a blank would. The flag is
    a read, not a gate: the row renders, the name is marked."""
    letters = re.sub(r"[^A-Za-z]", "", str(name or ""))
    if name in ("", "no milestone named yet") or len(letters) >= 3: return ""
    return "  ⚠ name too thin"

def meter(closed, total):
    # Nothing to measure draws an EMPTY bar. A full one reads as complete, and
    # "██████████  0 of 0 milestones" said finished about a goal that had not
    # named a single state yet (visual audit V8, #59).
    if not total: return "▱" * 10
    filled = 10 if closed >= total else int(closed * 10 / total)
    return "▰" * filled + "▱" * (10 - filled)

# Closers: the do-line under each CLEAR NOW row.
# Owner ruling Q1a, 2026-09-05: "Every USER: gate reaches CLEAR NOW, capped at
# three with the rest counted; the steer/errand split is dropped." The split
# that lived here (command-shaped closer = errand in the band, anything else =
# a "steer" counted in the header and prefixed "no closer" on its row) rendered
# CLEAR NOW on one of six live stores and printed "no closer" beside
# "USER: push is yours" three times on one screen (visual audit V7, #57). A
# gate's instruction is whatever the owner wrote after USER:, in his words.
CMD_HEAD = re.compile(r"^(bash|sh|zsh|python3?|node|npm|npx|pnpm|yarn|make|git|gh|gcloud|"
                      r"aws|alembic|docker|pytest|cargo|go|curl|open|pm2|claude-ipc|"
                      r"task\.sh|task-table\.sh|\./|~/|/)")
VERBW = 6
def closers_of(x):
    """The concrete steps that clear an owner gate, in the owner's three verbs.

    `run` is a script to execute, `do` is a literal instruction, `key` prints a
    credential he will need. Declared in metadata.closer; where that is absent a
    command sitting inside the blocked_on prose is read as a `do`, because the
    convention already writes them there and refusing to read one would hand him
    a gate the data could have closed (rules/refusal-is-not-a-fix.md).
    """
    found = []
    raw = meta_of(x, "closer")
    decls = raw if isinstance(raw, list) else ([raw] if raw else [])
    for it in decls:
        s = str(it).strip()
        if not s: continue
        m = re.match(r"^(run|do|key)\s*[:\-]\s*(.*)$", s, re.I)
        verb, body = (m.group(1).lower(), m.group(2).strip()) if m else ("do", s)
        cmd, hint = body, ""
        halves = re.split(r"\s+[—–]\s+|\s{3,}", body, maxsplit=1)
        if len(halves) == 2: cmd, hint = halves[0].strip(), halves[1].strip()
        found.append((verb, cmd, hint))
    if found: return found
    b = str(meta_of(x, "blocked_on") or "")
    for cand in re.findall(r"`([^`]+)`", b):
        if CMD_HEAD.match(cand.strip()): found.append(("do", cand.strip(), ""))
    if found: return found
    for seg in re.split(r"[;:]\s+|\.\s+", b):
        seg = seg.strip()
        if seg and CMD_HEAD.match(seg):
            found.append(("do", ellip(seg, 74), "")); break
    if found: return found
    # No command anywhere: the instruction is the owner's own prose after USER:.
    prose = re.sub(r"^\s*USER\s*:?\s*", "", b, flags=re.I).strip()
    if prose: found.append(("do", ellip(prose, 74), ""))
    return found

_closers = {x["id"]: closers_of(x) for x in gates}
clear_now = list(gates)           # Q1a: every owner gate, no split
CLEAR_CAP = 3

# Goal progress.
# A goal is met only when every milestone under it is closed; a milestone is
# closed only when every row under it is done. The header never rounds a goal up,
# however few of its rows remain.
_g_of = lambda r: (r.get("metadata") or {}).get("goal") or ""
_m_of = lambda r: (r.get("metadata") or {}).get("batch") or ""
_goal_ms = {}
for _r in rows:
    _gk = _g_of(_r)
    if not _gk: continue
    _goal_ms.setdefault(_gk, {}).setdefault(_m_of(_r) or "(no milestone)", []).append(_r)
_goals_met = _goals_part = _goals_parked = _ms_closed = _ms_total = 0
_per_goal = {}
for _gk, _msd in _goal_ms.items():
    _closed = _open_ms = 0
    for _name, _rin in _msd.items():
        _ms_total += 1
        if all(_is_done(r) for r in _rin): _closed += 1; _ms_closed += 1
        else: _open_ms += 1
    _per_goal[_gk] = (_closed, _closed + _open_ms)
    if _open_ms == 0: _goals_met += 1
    else:
        # A goal whose every open row is deferred draws no box (deferred rows
        # leave core) but was counted as a goal, so vb read "3 goals, 0 met"
        # over two boxes (fleet, #55). Name that state rather than hide it.
        _openrows = [r for _rin in _msd.values() for r in _rin if not _is_done(r)]
        if _openrows and all(deferred(r) for r in _openrows): _goals_parked += 1
        else: _goals_part += 1

# The board is the human's view of a project across sessions, so the footer links
# it when this project has one. No board, no link: an invented url is worse than
# a missing one.
BOARD_URL = ""
try:
    _reg = json.load(open(os.path.expanduser("~/.claude/kanban/registry.json")))
    _cwd = os.environ.get("PROOT") or os.getcwd()
    for _slug, _b in (_reg.get("boards") or {}).items():
        _root = _b.get("root") or ""
        if _root and (_cwd == _root or _cwd.startswith(_root + "/")):
            BOARD_URL = f"localhost:5106/b/{_slug}"; break
except Exception:
    BOARD_URL = ""

# The header.
out = []
def w(s=""): out.append(s)

# The header names the STORE. `alias` is the READER's ipc name, keyed on
# CLAUDE_CODE_SESSION_ID, and printing it here put the reading session's name
# over another session's rows: a hardcoded false alias survived all 444
# assertions (adv-tasks F1, 2026-09-05). The store id cannot be wrong about
# whose rows these are; the provenance line below already says how it resolved.
_head = f"TASKS  {d.name}"
# His goal and the goal tags are two objects; line 1 shows his, clipped at a
# word, and the count below names itself as tags (alignment check 3).
_armed = (os.environ.get("ARMED_GOAL") or "").strip()
if _armed:
    # The text itself rides its own line under the provenance line (unblock-0908
    # D2b, 2026-09-08); Q7a's 96-char clip on this line cut goals at their
    # second promise (cold-read-P2 Q5, #38).
    _head += "  ·  \U0001F3AF armed, on the /goal line below"
else:
    _head += "  ·  \U0001F3AF no /goal armed"
if _goal_ms:
    _ngoals = _goals_met + _goals_part + _goals_parked
    _head += (f"  ·  \U0001F7E2 {_ngoals} goal tag{'s' if _ngoals != 1 else ''}, {_goals_met} met"
              + (f", {_goals_parked} parked" if _goals_parked else "")
              + f"  ·  \U0001F3C1 {_ms_closed} of {_ms_total} milestones")  # the noun: "36 of 75" of what? (fleet, #56)
if gates:
    # A count, not a forecast ("~4 more" read as an estimate cold, fleet #56),
    # in the legend's own words so the header and the ball agree.
    _head += f"  ·  \U0001F534 {len(gates)} need you"
# in_progress is a status nobody resets when a lane dies, so it reads as live
# work and is really a tombstone (fleet, #56: two "running" rows, one in a lane
# retired four days earlier). A running row untouched for a day is named stale.
_stale = [x for x in now if (time.time() - (x.get("_mtime") or time.time())) > 86400]
_head += f"  ·  {len(now) - len(_stale)} running" + (f", {len(_stale)} stale" if _stale else "")
w(_head)

# The provenance line is not in the approved sketch and is kept anyway. Which
# store this is and how it was found is the whole correctness story of this
# script (the resolution ladder at the top of the file), and a render that does
# not say it can be confidently about another session's queue. It says it in
# words: the ladder's own labels ("pin (legacy location)", "content-match") were
# jargon in the most-read line, and one of them was false on a resumed session,
# whose resolver answer is the store NAMED for the session, usually empty, which
# no content can have matched (fleet, #54).
_HOW = {"explicit": "the --session you passed",
        "explicit (matched by prefix)": "the --session you passed (prefix match)",
        "pin": "the pin for this session",
        "pin (legacy location)": "the pin for this session (old location)",
        "content-match": "matching your transcript",
        "session-name": "the store named for this session"}
_how = _HOW.get(resolved_by, resolved_by)
if not data:
    _how = ("the store named for this session (empty)" if resolved_by == "session-name"
            else "a cached match, now empty" if resolved_by == "content-match"
            else _how + " (empty)")
_m = re.search(r"\((\d+)% of open rows carry it\)", group_src)
_src = ("from the --group flag" if group_src.startswith("flag")
        else "set in this project's view file" if group_src.startswith("project view file")
        else f"auto, {_m.group(1)}% of open rows carry it" if _m and group != "actor"
        else "auto")
w(f"  store {d.name}, found by {_how}  ·  grouped by {group}"
  + (f", then {sub}" if sub else "") + f", {_src}")
# His goal in his words, whole, as the line he can paste back. Plain text with
# continuation lines at column 0 and nothing else on them, because he copies it
# off this screen (unblock-0908 D2b and the D3 note, 2026-09-08).
if _armed:
    for _gl in wrap("/goal " + _armed, BOX_W): w(_gl)

if not data:
    # An empty table is indistinguishable from an empty QUEUE, and a peer read
    # exactly that on 2026-09-04: its twenty rows lived in the store that created
    # them while a bare run showed nothing, and it concluded the queue was done.
    # The first line is the answer in one sentence (forge-console, #55); the
    # explanation and the list follow it, and the list is labelled for what it
    # is, recency rather than evidence: two peers found none of it theirs.
    w(f"!! EMPTY STORE: you have no rows here; {d.name} holds no task files.")
    w(f"   A resumed session's rows live in the store that CREATED them, not the one named for it.")
    try:
        _cands = []
        for _sd in sorted(d.parent.glob("session-*"), key=lambda p: p.stat().st_mtime, reverse=True):
            _files = list(_sd.glob("*.json"))
            if not _files: continue
            _newest = max(_files, key=lambda p: p.stat().st_mtime)
            _subj = ellip(json.loads(_newest.read_text()).get("subject") or "", 52)
            _o = sum(1 for f in _files
                     if (json.loads(f.read_text()).get("status") or "") not in ("completed", "cancelled"))
            _cands.append((_sd.name[len("session-"):], len(_files), _o, _subj))
            if len(_cands) == 3: break
        if _cands:
            w("   Newest stores holding rows, none proven yours:")
            for _sid, _n, _o, _subj in _cands:
                w(f"     task-table.sh --session {_sid}   {_o} open of {_n}   “{_subj}”")
    except Exception:
        w("   task-table.sh --candidates lists the stores that could be yours")

_open_m = [r.get("_mtime", 0) for r in rows if not _is_done(r) and r.get("_mtime")]
_last_open = _age(time.time() - max(_open_m)) if _open_m else ""
# Header notes are RANKED and CAPPED. Outside --detail, one `!!` line at most
# (the most consequential), with a count of what --detail holds; the tidiness
# nags (tier, grouping coverage) print only under --detail. Six header lines
# stood above the first task on the store where 98% of rows did not fit, two of
# them `!!`, one ending in a question (visual audit V14, #58; automation on #54:
# "a third of the render was the tool complaining about fields it could have
# defaulted"). A header line never asks the reader a question.
_bangs, _quiet = [], []
if resolved_by.startswith("guess"):
    _bangs.append(f"  !! STORE NOT CONFIRMED ({resolved_by}). This may be another session's queue. Pin: task-table.sh --session <sid8>")
# A gate goes false by being SATISFIED, and nothing closes the row. Twice on
# 2026-09-04 the owner's queue held an ask somebody had already cleared: #599's
# sentinel was minted and #574's migration was applied twenty minutes before the
# table rendered them. Its own author called the band 50% stale. Wording cannot
# catch that, only recency can, so an untouched gate says its age. It outranks
# the whole-queue staleness note because it names rows he can re-check.
STALE_GATE_S = 24 * 3600
def _gate_since(x):
    """When the gate was believed: the row's own blocked_on_at, else the file's last write."""
    s = x.get("blocked_on_at") or ""
    try:
        return calendar.timegm(time.strptime(s, "%Y-%m-%dT%H:%M:%SZ")) if s else x.get("_mtime")
    except ValueError:
        return x.get("_mtime")
_stale = [x for x in gates if _gate_since(x) and time.time() - _gate_since(x) > STALE_GATE_S]
# A deferral is a verdict with a date too; a row written a day or more after it
# was deferred is a verdict that may have lapsed (forge-console, 2026-09-08).
def _iso(s):
    try: return calendar.timegm(time.strptime(s or "", "%Y-%m-%dT%H:%M:%SZ"))
    except ValueError: return None
_stale_def = [x for x in live if deferred(x) and _iso(x.get("batch_at")) and (x.get("_mtime") or 0) > _iso(x.get("batch_at")) + 86400]
if _stale_def:
    _bangs.append(f"  !! {len(_stale_def)} deferred row(s) written after their deferral was set, re-check the verdict: " + " ".join(f"#{x['id']}" for x in _stale_def[:6]))
# A running row in a lane no live session claims is a tombstone wearing a live
# glyph: a retired watcher lane's row drew as the one running row eight days
# after the lane was retired (ledger 15, 26, 33; 2026-09-08). The roster comes
# from the ipc broker; TASKS_PEERS_JSON points a test at a stub. Broker down or
# absent: nothing is said, because a nag needs its instrument.
def _live_aliases():
    import subprocess as _sp
    raw = ""
    _stub = os.environ.get("TASKS_PEERS_JSON")
    try:
        if _stub: raw = open(_stub).read()
        else:
            _r = _sp.run(["claude-ipc", "peers"], capture_output=True, text=True, timeout=3)
            raw = _r.stdout if _r.returncode == 0 else ""
        return {str(p.get("alias", "")).lower() for p in json.loads(raw).get("peers", []) if p.get("status") != "offline"}
    except Exception:
        return None
_HOUSE_LANES = {"main", "owner", "gcc", "hands", "brains"}
_orphan_lanes = {}
_aliases = _live_aliases() if now else None
if _aliases is not None:
    for x in now:
        _l = str(meta_of(x, "lane") or "").strip().lower()
        if not _l or _l in _HOUSE_LANES: continue
        if any(_l in a for a in _aliases): continue
        _orphan_lanes.setdefault(_l, []).append(x["id"])
if _orphan_lanes:
    _bangs.append("  !! running in a lane no live session claims: " + " · ".join(f"{l} ({' '.join('#' + str(i) for i in ids[:4])})" for l, ids in _orphan_lanes.items()))
if _stale:
    _ids = " ".join(f"#{x['id']}" for x in _stale[:6]) + (" …" if len(_stale) > 6 else "")
    _bangs.append(f"  !! {len(_stale)} gate(s) untouched >24h, re-check before acting: {_ids}")
if _open_m and time.time() - max(_open_m) > 24 * 3600:
    _bangs.append(f"  !! NOT TODAY'S QUEUE: no open row has moved in {_last_open}; carried-over or umbrella items")
if view.get("_broken"): _bangs.append(f"  !! view file did not parse, ignored: {view['_broken']}")
notier = sum(1 for x in live if not (meta_of(x, "tier") or meta_of(x, "model"))
             and (meta_of(x, "lane") or "").lower() != "owner" and not deferred(x))
if notier:
    _quiet.append(f"  {notier} open row(s) carry no tier (◇ — in the trait column); set with task.sh update <id> --tier <fable|opus|sonnet|haiku|lm>")
# A grouping key most rows do not carry produces one huge band. Auto-selection
# refuses such a key, but a flag or a project view file can still pin one, and a
# pinned ruling is not ours to override. Say what it costs instead.
if group in ("goal", "batch", "domain", "class") and _probe:
    _cov = coverage(group)
    if _cov < 0.70:
        _alt = max([k for k in ("goal", "batch", "domain", "class") if k != group], key=coverage)
        _n = sum(1 for x in _probe if not meta_of(x, group))
        _where = ("the UNFILED band, which is then the largest thing on screen"
                  if group == "goal" else "one band named for a field they do not carry")
        # Advice to regroup onto a key this line just measured at zero is a line
        # the render refutes (adv-tasks F8c). Offer the regroup only when the
        # alternative actually covers most rows; otherwise the fix is on the rows.
        _line = f"  !! only {_cov:.0%} of open rows carry '{group}', so {_n} land in {_where}."
        if coverage(_alt) >= 0.70:
            _line += f" '{_alt}' covers {coverage(_alt):.0%}   ·   regroup: task-table.sh --group {_alt}"
        else:
            _line += f" No other key covers them either; set '{group}' on the rows."
        _quiet.append(_line)
if detail:
    for _l in _bangs + _quiet: w(_l)
elif _bangs:
    _rest = len(_bangs) - 1 + len(_quiet)
    # "+2 more" beside a gate count read as two more gates (cold-read-P2.md Q2).
    w(_bangs[0] + (f"   ·   +{_rest} more nag{'s' if _rest != 1 else ''} in --detail" if _rest else ""))

# The lane invariant, computed before the budget.
# THE RULED INVARIANT: a lane holds at most one running row (REDESIGN.md:91). A
# footer line the row budget does not know about pushes the render to 45, and the
# 44-line cap is a ruling, so this is counted here and not discovered later.
_warn = []
_run_by_lane = {}
for x in now:
    _run_by_lane.setdefault(meta_of(x, "lane") or meta_of(x, "owner") or "", []).append(str(x["id"]))
_over = {k: v for k, v in _run_by_lane.items() if k and len(v) > 1}
if _over:
    _warn.append("  !! one lane, several running: "
                 + " · ".join(f"{k} has {len(v)} (#" + ", #".join(v) + ")" for k, v in sorted(_over.items()))
                 + "   ·   at most one of each is really running")
_nolane = _run_by_lane.get("", [])
if len(_nolane) > 1:
    _warn.append(f"  !! {len(_nolane)} running rows carry no lane (#" + ", #".join(_nolane)
                 + ")   ·   nothing holds them to the one-per-lane rule")

# The budget.
# Reserved, never discovered: the state legend, its rule, the trait legend, the
# loud truncation line, the lane warnings, and the collapsed done ids.
# Recency. "Where was I" is the question a returning reader arrives with, and
# a render of 445 done rows could not say which closed in the last four hours
# (fleet, #56). Rows whose file moved in the window, newest first, capped so the
# line stays a line. Rides _warn so the footer budget already pays for it.
RECENT_H = 6
_recent = sorted((x for x in rows if (time.time() - (x.get("_mtime") or 0)) < RECENT_H * 3600
                  and (_is_done(x) or x["status"] == "in_progress")),
                 key=lambda x: -(x.get("_mtime") or 0))
# Counts, never ids (owner ruling Q8a, 2026-09-05): the moved list and the done
# list were the loudest, widest text on every populated tab and carried nothing
# a person flipping tabs could use (visual audit V3). The ids live in --json
# (moved_recently, and every task with its status). The held-ids line above the
# legend is the one id list that stays, by the 2026-08-15 ruling.
_parts = []
if _recent: _parts.append(f"{len(_recent)} moved in the last {RECENT_H}h")
if done and live:
    # A done row with no instrument is counted here so the omission is on
    # screen; the rows themselves live in --json (alignment check 9).
    _unv = [x for x in done if not x.get("verified")]
    _parts.append(f"{len(done)} done" + (f", {len(_unv)} with no instrument named" if _unv else ""))
if _parts: _warn.append("  " + "   ·   ".join(_parts) + "   ·   ids in --json")
FOOTER = 3 + 1 + len(_warn)
HEADER_LEN = len(out)
LINE_CAP = HEIGHT - FOOTER
hidden = []
_unopened = []
# Inside a box, every check silently owes one more line: the closing corner is
# written unconditionally once the rows are done. Charging it here rather than at
# each of the four call sites is what stops the next reader forgetting one.
_box_owed = 0
def fits(n): return detail or len(out) + n + _box_owed <= LINE_CAP
def hidden_cost(n):
    """Lines the id list will take. It is capped at three and never elided away:
    a silently trimmed list reads complete (owner ruling)."""
    if not n: return 0
    chunks = (n + 25) // 26
    return 1 + (1 if chunks > 1 else 0) + (1 if chunks > 2 else 0)

def build_body():
    """Emit CLEAR NOW and the goal boxes into `out`, under the current cap."""
    global hidden, _unopened, _states_used
    del out[HEADER_LEN:]
    hidden = []
    _unopened = []          # boxes the cap refused: (ball, emoji, title, rows)
    _states_used = set()
    # CLEAR NOW.
    # Every row waiting on the owner (Q1a), drawn across every goal and every lane,
    # capped at three. The cap is the point: the remainder is counted rather than
    # listed, so the band reads as a sitting and not as another list.
    if clear_now:
        # A gate with no ask on it cannot be acted on from this screen, so it sits
        # below the ones that can; the gcp cold read met a maintenance command in
        # position one of the owner's own list (cold-read-P2.md, 2026-09-08).
        _cn = ([x for x in clear_now if _closers[x["id"]]]
               + [x for x in clear_now if not _closers[x["id"]]])
        shown_c = _cn[:CLEAR_CAP]
        _gn = len({meta_of(x, "goal") or "—" for x in clear_now})
        _ln = len({meta_of(x, "lane") or meta_of(x, "owner") or "—" for x in clear_now})
        if fits(2 + 2 * len(shown_c)):
            w("")
            w(f"⚡ CLEAR NOW   {len(shown_c)} of {len(clear_now)} waiting on you,"
              f" across {_gn} goal{'s' if _gn != 1 else ''} and {_ln} lane{'s' if _ln != 1 else ''}")
            _cw = 0
            for x in shown_c:
                for _v, _c, _h in _closers[x["id"]]:
                    if _h: _cw = max(_cw, min(56, dwidth(_c)))
            for i, x in enumerate(shown_c, 1):
                w(f"   {i}  " + dljust(f"#{x['id']}", IDW) + " "
                  + ellip(titled(x), BOX_W - TITLE_COL + 1))
                _cl = _closers[x["id"]] or [("do", "this row names no ask yet; the agent owes you one"
                                                   f" (task.sh update {x['id']} --blocked-on 'USER: …')", "")]
                for _v, _c, _h in _cl:
                    if not fits(1): break
                    cell = "▸ " + dljust(_v, VERBW) + (dljust(_c, _cw) + "  " + _h if _h else _c)
                    w(" " * (TITLE_COL - 1) + ellip(cell, BOX_W + 26 - TITLE_COL))
            _rest = len(clear_now) - len(shown_c)
            if _rest and fits(1):
                w(f"      +{_rest} more waiting on you, held so this reads as a sitting; --detail lists them")
                hidden.extend(f"#{x['id']}" for x in _cn[len(shown_c):])
        else:
            hidden.extend(f"#{x['id']}" for x in clear_now)

    # The goal boxes.
    RULE_IN = "─" * (BOX_W - MS_COL + 1)

    # Lines held back so a run of gates cannot swallow the box. Roughly four
    # two-line rows plus their separators: enough that the reader can see there
    # IS work under the gates, not enough to demote the gates themselves.
    WORK_FLOOR = 12

    # Priced here rather than inside emit_rows so a box or a band can claim its
    # header and its first row together: a header that fits while its row does
    # not is how a box closed on nothing and a band promised rows the cap ate
    # (visual audit V1, V2, 2026-09-05).
    def shape(x, first):
        """The note this row carries and the lines it will take."""
        note = str(meta_of(x, "note") or "")
        if not note and x.get("blocked_on"): note = str(x["blocked_on"])
        if not note and x.get("waits_on"):
            note = "after #" + " #".join(str(i) for i in x["waits_on"])
        # Who took it, and whether they have said so. A peer's queue carried
        # 42 owner gates of which five were merely FILED in their store, and
        # the unconfirmed half of that is what the reader needs to see.
        if _deleg(x):
            _dc = meta_of(x, "delegated_confirmed")
            note = (f"delegated to {_deleg(x)} · "
                    + ("CONFIRMED" if _dc == "true" else "unconfirmed")
                    + (" · " + note if note else ""))
        # Owner ruling 2026-08-15 and REDESIGN.md: references resolve by DEFAULT,
        # not behind --refs. A bare "#14" or proposal id in the SUBJECT gets a
        # short gloss on the note line, so a stranger can read the row without
        # a second command (adv-tasks F9). Subject only: description refs are
        # context, and glossing them all would spend the line on the least
        # load-bearing text.
        _gl = [f"{g['ref']} {ellip(g['gloss'].split('  [')[0], 36)}"
               for g in refs_for(x) if g["kind"] in ("task", "proposal") and g["ref"] in subj(x)]
        if _gl: note = (note + " · " if note else "") + " · ".join(_gl[:2])
        note_w = BOX_W - ID_COL + 1
        # An expanded note left-aligns to the row block rather than to the
        # trait indent, taking the remaining width. Only for a row the reader
        # must act on: a ready row's long note is context, not instruction.
        expand = bool(note) and dwidth("» " + note) > note_w \
                 and row_state(x) in ("gate", "running", "waiting")
        # Three lines is the ceiling. One verbose note took four of the 44 and
        # left two other rows off the screen, which inverts what a note is for.
        nlines = wrap("» " + note, BOX_W - XNOTE_COL + 1) if expand else []
        if len(nlines) > 3:
            nlines = nlines[:3]
            nlines[2] = ellip(nlines[2] + " …", BOX_W - XNOTE_COL + 1)
        # Owner ruling 2026-09-05: fold the note onto the trait line when it
        # fits. Three lines a row is what makes height explode, and the
        # traits leave most of that line empty anyway.
        has_traits = any(trait_values(x))
        inline = ""
        # A note can only ride a trait row that exists. Without this test a
        # traitless row with a short note was costed as one line and printed
        # as two, and store f1378236 rendered 45/44 the moment A7's gloss gave
        # its rows notes (2026-09-05).
        if note and not expand and has_traits:
            cells_w = sum(TRAITWS)
            room = BOX_W - ID_COL + 1 - cells_w - 2
            if room >= MIN_INLINE_NOTE and dwidth("» " + note) <= room:
                inline = "» " + note
        # A row is its subject line, plus a trait line only when it has any
        # trait, plus a note line only when the note could not ride along.
        # On a store where nothing carries lane/tier/kind/domain the trait
        # line was four em-dashes saying nothing, once per row.
        cost = (1 + (1 if has_traits else 0)
                + (len(nlines) if expand else (0 if inline else (1 if note else 0))))
        return note, note_w, expand, nlines, cost, inline, has_traits

    def first_row_cost(body):
        """The lines the first row emit_rows would draw from this list costs.

        emit_rows draws kept gates before the rest, and whether a gate is kept
        depends on a budget known only at draw time, so both candidates are
        priced and the larger wins: a box or band opened on that price never
        closes on nothing, at the cost of occasionally refusing one that would
        have fit by a line.
        """
        gates = [x for x in body if row_state(x) == "gate"]
        rest = [x for x in body if row_state(x) != "gate"]
        cands = ([gates[0]] if gates else []) + ([rest[0]] if rest else [])
        return max((shape(y, True)[4] for y in cands), default=1)

    def emit_rows(items):
        """Two lines per row, always, with a rail line between rows.

        Variant C, a second line only for rows that earn it, was dropped on the
        owner's own reason: it becomes a rule with a lot of exceptions, and the
        reader pays to learn the exceptions more than the density buys.

        Gates keep priority without keeping totality. Twenty gate rows in one
        goal used to take the whole screen and push all forty work rows off it,
        which is the same starvation the old GATES band had: he saw only work he
        could not act on. So while any non-gate row is still waiting, a gate row
        is drawn only if WORK_FLOOR lines survive it, and the gates that do not
        fit are named inside the box rather than dropped into the global list.
        """

        gates_here = [x for x in items if row_state(x) == "gate"]
        rest = [x for x in items if row_state(x) != "gate"]
        held_gates, keep = [], []
        # The gate prefix is sized BEFORE anything is drawn, because the "+N held"
        # line has to fit too and its own cost is only knowable once the count is.
        if gates_here and rest:
            budget = LINE_CAP - len(out) - _box_owed - WORK_FLOOR - 1
            keep, used = [], 0
            for x in gates_here:
                c = shape(x, not keep)[4]
                if used + c > budget: break
                keep.append(x); used += c
            held_gates = gates_here[len(keep):]
            items = keep + rest
        j = 0                       # rows actually drawn, which drives the separator
        for pos, x in enumerate(items):
            note, note_w, expand, nlines, cost, inline, has_traits = shape(x, j == 0)
            if not fits(cost):
                hidden.extend(f"#{y['id']}" for y in items[pos:]); break
            j += 1
            b, t = ball_of(x)
            w("│" + " " * (BALL_COL - 2) + b + " " + t + " "
              + dljust(f"#{x['id']}", IDW) + " " + ellip(titled(x), TITLE_W))
            cells = "".join(dljust(mk + " " + ellip(val or "—", cw - 3), cw)
                            for mk, val, cw in zip(TRAIT_MARK, trait_values(x), TRAITWS))
            # The note rides the trait row when it fits, so a row costs two lines
            # instead of three. The traits keep their fixed columns either way,
            # because one trait per column is the ruling and alignment is what
            # makes the columns readable down the page.
            if has_traits and inline:
                w("│" + " " * (ID_COL - 2)
                  + dljust(cells.rstrip(), sum(TRAITWS)) + "  " + inline)
            elif has_traits:
                w("│" + " " * (ID_COL - 2) + cells.rstrip())
            elif inline:
                w("│" + " " * (ID_COL - 2) + inline)
            if expand:
                w("│" + " " * (XNOTE_COL - 2) + nlines[0])
                for ln in nlines[1:]: w("│" + " " * XNOTE_COL + ln)
            elif note and not inline:
                w("│" + " " * (ID_COL - 2) + ellip("» " + note, note_w))
            # Said inside the box the moment the kept gates run out, not only in
            # the global list at the bottom. A reader who sees four gates must not
            # conclude there are four, and he must read it before the work rows
            # rather than after them.
            if held_gates and x is (items[len(keep) - 1] if keep else None):
                hidden.extend(f"#{y['id']}" for y in held_gates)
                w("│" + " " * (ID_COL - 2)
                  + f"… +{len(held_gates)} more held here so the work below stays visible ("
                  + " ".join(f"#{y['id']}" for y in held_gates[:8])
                  + (" …" if len(held_gates) > 8 else "") + ") · --detail shows all")
                held_gates = []
        if held_gates: hidden.extend(f"#{y['id']}" for y in held_gates)

    def emit_box(key, items, unfiled=False, fixed_emoji="", fixed_ball=""):
        """One goal, drawn as a closed box.

        The title as plain text, then curved corners, a rail down the left and a
        full-width rule on the opening corner. The box is what was missing when
        the owner said the distinctions were not proper. The ball rides on the rail
        and does not replace it, and the per-goal emoji sits beside the ball rather
        than under it: one says whether the goal can continue without him, the other
        says which goal this is.
        """
        global _box_owed
        items = seq_sort(items)
        # A box is drawn only when its chrome AND its first row fit together:
        # blank, corner, rule, meter, rail and the closing corner are six, then
        # a milestone header pair when bands are drawn, then the first row at
        # its real cost. A flat nine priced that row at one line, so a box whose
        # first row cost two opened onto nothing and closed (f452498c, visual
        # audit V1). A box that seats its first row IS drawn and its own row
        # loop truncates the rest; a refused box is named in one line under the
        # boxes rather than vanishing into the id list.
        _bands = None
        if not unfiled and sub:
            subs = {}
            for x in items: subs.setdefault(key_of(x, sub), []).append(x)
            # The band that moved most recently comes first, so a returning
            # reader meets tonight's rows rather than August's. Natural order
            # put a "(no batch)" band of old rows in the one slot that fit and
            # hid three rows filed that evening (forge-integration, #56). The
            # unfiled band never outranks a named milestone, whatever its age,
            # and a band whose name says it is parked stays behind the live ones.
            def _band_key(sk):
                _mt = max((y.get("_mtime") or 0) for y in subs[sk])
                _nk = natkey(sk)
                return (1 if sk == f"(no {sub})" else 0, _nk[0], -_mt, _nk)
            _bands = [(sk, seq_sort(subs[sk])) for sk in sorted(subs, key=_band_key)]
        ball = fixed_ball or ("⚪" if unfiled else goal_ball(items))
        emo  = fixed_emoji or ("\U0001F4E5" if unfiled else goal_emoji(key, items))
        title = "unfiled" if unfiled else str(labels.get(key, key))
        if unfiled:
            age = "—"
        else:
            _mt = max((x.get("_mtime") or 0) for x in items) or 0
            age = _age(time.time() - _mt) if _mt else "—"
        # The title is plain text above the rails. The owner copies his goal off
        # this screen, and a rail glyph on a wrapped continuation line came along
        # with the selection: "the box around the goal makes it hard to copy paste
        # it, no fancy characters between the terminal text flow" (unblock-0908
        # D3, 2026-09-08). The lead glyphs sit before the text, never inside it;
        # the rule and the age moved down to the corner line.
        lead = f"{ball} · {emo}  "
        tailtxt = f"  ·  {age}"
        # A one-row goal is its title and its row (D3a, #44): six lines of chrome
        # around one row read as a form with nothing in it on small stores, and
        # hid seven rows in the turn the owner asked what was left (ledger 2).
        one_row = len(items) == 1 and not unfiled
        room = BOX_W - dwidth(lead) - (dwidth(tailtxt) if one_row else 0)
        # A title is never elided from the middle. The mid-cut of the owner's own
        # goal read "tell the owner … without him decoding it", a sentence that
        # still parsed and meant something else (visual audit V6, #59). A title
        # that does not fit wraps onto one more line inside the box, priced into
        # the box below; past two lines it is clipped at the END, where the mark
        # is honest about what is missing.
        _tlines = wrap(title, room)
        if len(_tlines) > 2:
            _tlines = [_tlines[0], ellip(" ".join(_tlines[1:]), room)]
        _tlines = [ellip(t, room) for t in _tlines]
        if one_row:
            if not fits(1 + len(_tlines) + first_row_cost(items)):
                hidden.extend(f"#{x['id']}" for x in items)
                _unopened.append((ball, emo, title, len(items))); return
            _box_owed = 0
            if out and out[-1] != "": w("")
            w(lead + _tlines[0] + (tailtxt if len(_tlines) == 1 else ""))
            for _tl in _tlines[1:-1]: w(_tl)
            if len(_tlines) > 1: w(_tlines[-1] + tailtxt)
            _start = len(out)
            emit_rows(items)
            # The row keeps its shape and loses its rail: there is no box to rail.
            for _i in range(_start, len(out)):
                if out[_i].startswith("│"): out[_i] = " " + out[_i][1:]
            # The meter is gone with the chrome, but its one defect callout is not
            # chrome (cold-read-P2 Q2): a goal with no milestone still says so.
            if not meta_of(items[0], "batch") and fits(1):
                w(" " * (ID_COL - 2) + f"no milestone named yet   ·   name one: task.sh meta {items[0]['id']} batch=<the state it reaches>")
            return
        _first = (2 + first_row_cost(_bands[0][1])) if _bands else first_row_cost(items)
        if not fits(5 + len(_tlines) + _first):
            hidden.extend(f"#{x['id']}" for x in items)
            _unopened.append((ball, emo, title, len(items))); return
        _box_owed = 1
        if out and out[-1] != "": w("")
        w(lead + _tlines[0])
        for _tl in _tlines[1:]: w(_tl)
        w("╭▏" + "─" * (BOX_W - 2 - dwidth(tailtxt)) + tailtxt)
        if unfiled:
            # An empty bar, never a full one: a solid bar reads as complete on
            # every other line of the page (visual audit V8, #59).
            w("│  " + "▱" * 10 + "  no meter can be drawn   ·   "
              "file one: task.sh update <id> --goal <g>")
        else:
            cl, tot = _per_goal.get(key, (0, 0))
            nxt = ""
            for x in items:
                # A parked (deferred) row is by definition not next; vb's meter
                # read "next: sittings" for a milestone parked by design (#55).
                if row_state(x) == "later": continue
                m = meta_of(x, "batch")
                if m: nxt = str(m); break
            # The band header resolves the milestone through the view file's
            # labels; this line did not, so it printed the sort prefix ("next: A")
            # under a band that read "A · gate adherence …" (adv-tasks F7, #34).
            nxt = str(labels.get(nxt, nxt)) if nxt else ""
            if tot == 0:
                # "0 of 0" over live rows read as false to a cold reader; say what
                # is missing instead (cold-read-P2.md Q2, 2026-09-08).
                w("│  " + meter(cl, tot) + "  no milestone named yet   ·   name one: task.sh meta <id> batch=<the state it reaches>")
            else:
                w("│  " + meter(cl, tot)
                  + f"  {cl} of {tot} milestone{'s' if tot != 1 else ''}"
                  + (f"   ·   next: {ellip(nxt, 48)}{thin_flag(nxt)}" if nxt else ""))
        w("│")
        if _bands is None:
            emit_rows(items)
        else:
            first = True
            for sk, body in _bands:
                # A milestone earns its header only if its first row follows it:
                # title, rule, the row at its real cost, and the rail line that
                # separates it from the milestone above. Pricing the row at two
                # left a header with nothing under it and the box closing on it
                # (fabad34c at 92 columns, visual audit V2).
                if not fits(2 + first_row_cost(body) + (0 if first else 1)):
                    hidden.extend(f"#{y['id']}" for y in body); continue
                if not first: w("│")
                first = False
                # D6 made the milestone mandatory, so a row carrying none is a gap in
                # the data. "(no batch)" names the absent FIELD; this names the gap.
                _mtitle = str(labels.get(sk, sk))
                if _mtitle == "(no batch)": _mtitle = "no milestone named yet"
                _tf = thin_flag(_mtitle)
                w("│" + " " * (MS_COL - 2) + "▸ " + ellip(_mtitle, BOX_W - MS_COL - 1 - dwidth(_tf)) + _tf)
                w("│" + " " * MS_COL + "─" * 5)
                emit_rows(body)
        _box_owed = 0
        w("╰▏")

    # Real goals first, in the ruled order; the UNFILED band last, so the outcomes
    # are read before the holding pen (D3b). Deferred and delegated rows are not this
    # agent's to run and are not goals, so they keep their own boxes rather than
    # vanishing from a design that did not name them.
    # Ordered by the ball, so a goal that needs him is drawn first.
    #
    # This is not cosmetics. The height cap is a ruling and a large queue spends it
    # in the first few boxes, so the order IS what decides whether he ever sees the
    # gate. Rendered in the store's own order, session f04ae843 put three goals he
    # could not act on at the top and both of its owner gates off the screen, which
    # is the surface's first question ("what must the owner act on, today") going
    # unanswered by the surface built to answer it.
    _rank = {b: i for i, b in enumerate(BALL[s] for s in BALL_RANK)}
    _boxes = [(k, v, False, "", "") for k, v in groups.items() if k != UNFILED_KEY]
    _boxes.sort(key=lambda t: _rank.get(goal_ball(t[1]), 99))
    if UNFILED_KEY and UNFILED_KEY in groups:
        _boxes.append((UNFILED_KEY, groups[UNFILED_KEY], True, "", ""))
    if delegated:
        _boxes.append(("delegated · someone else has these", delegated, False,
                       "\U0001F91D", "\U0001F91D"))
    if later:
        _boxes.append(("later · deferred, or after V1", later, False,
                       "\U0001F4A4", "\U0001F4A4"))
    # THE ALL-DONE TERMINAL STATE. Collapsing done rows to a line of bare ids is the
    # ruled shape, but it was ruled for tables that still show open work. With
    # nothing open it degenerates into a table whose entire content is a row of
    # numbers, so when there is no live work the done rows ARE the table.
    if not live and done:
        _boxes.append((f"done · {len(done)} finished", seq_sort(done), False,
                       "✅", "✅"))
    for _k, _v, _u, _e, _b in _boxes: emit_box(_k, _v, _u, _e, _b)

# The id list costs lines the row budget has to know about, or the render
# walks past 44 while reporting that it did not: four real stores came out at
# 45 and 46 with the block unreserved. So rendering runs to a fixed point.
# Build, learn what was held, reserve exactly that, build again. The
# reservation only ever grows and is bounded by three, so this terminates.
_res = 0
for _ in range(5):
    LINE_CAP = HEIGHT - FOOTER - _res
    build_body()
    # The refused-goals line is reserved the same way, or it never fits on the
    # full screens that are exactly where goals get refused.
    _need = hidden_cost(len(hidden)) + (1 if _unopened else 0)
    if _need <= _res: break
    _res = _need

# The footer.
# A goal the cap refused is still named, in one line, so the reader learns it
# exists without meeting an empty box (visual audit V1). Written here, on the
# line the fixed point reserved for it, because the last box's row loop fills
# the body to the cap and a line claimed inside the body was gone half the time.
if _unopened:
    w("  no room left for: " + ellip("  ·  ".join(
        f"{b} {e} {t} ({n} row{'s' if n != 1 else ''})" for b, e, t, n in _unopened),
        BOX_W - 20))
# Every hidden id is named: a silently trimmed list reads complete (owner).
# A gate held from CLEAR NOW is held again when its box is refused, and the line
# then counted it twice ("+12 … #45 … #45", 2026-09-08). One id, once.
hidden = list(dict.fromkeys(hidden))
if hidden:
    chunks = [hidden[i:i+26] for i in range(0, len(hidden), 26)]
    w(f"… +{len(hidden)} rows held by the height cap (--detail or --json shows all): "
      + " ".join(chunks[0]))
    for c in chunks[1:2]: w("      " + " ".join(c))
    if len(chunks) > 2: w(f"      … +{sum(len(c) for c in chunks[2:])} more ids in --json")

# A legend is a key to what is on screen, so it lists only the states the render
# actually used, taken from the set ball_of() recorded rather than from a
# substring scan (a ball inside a task SUBJECT would vote itself into the key).
# Each key entry carries the ball's ASCII twin, because the twin is what sits
# beside the id on every row and a cold reader met "!" and "○" in no legend
# (cold-read-P2.md Q6).
_leg = [f"{BALL[s]} {LEGEND_NAME[s]} ({TWIN[s]})" for s in LEGEND_ORDER if s in _states_used]
# The header's "N running" points at rows the cap may have held; a cold reader
# found "2 running" with no marked row and no running state in the key
# (cold-read-P2.md Q3). So the key names them when they are off screen.
_run_held = [h for h in hidden if h in {f"#{x['id']}" for x in now}]
if _run_held and "running" not in _states_used:
    _leg.append(f"{BALL['running']} running, off screen: " + " ".join(_run_held[:4])
                + (" …" if len(_run_held) > 4 else ""))
if _leg:
    w("  " + "   ".join(_leg))
    w("  " + "─" * (BOX_W - 3))
    _okey = "".join(f"   {g} {n}" for n, g in ORIGIN_GLYPH.items() if g in _origins_used)
    w("  ◆ lane   ◇ tier   ▪ kind   ▫ domain" + _okey + "   »  note, shown only"
      " when it changes what you do   ·   the emoji beside a box's ball is that goal's badge"
      "   ·   height {H}/" + str(HEIGHT) + "   ·   -h for flags")
else:
    # Nothing was drawn, so there is nothing to key. A trait legend under
    # "nothing on screen" was a line the render refuted (adv-tasks F8d).
    w("  no rows on screen   ·   height {H}/" + str(HEIGHT) + "   ·   -h for flags")  # "to key" read as a typo cold (fleet, #54)

# A lane label is hand-written config and cannot know about a model switch.
# forge-brains reported its legend still naming Fable hours after moving to Opus
# 5, which makes the footer contradict the header.
lanes_legend = view.get("lanes") or {}
if lanes_legend:
    _MODELS = ("fable", "opus", "sonnet", "haiku", "mythos")
    _drift = []
    for _lane, _label in lanes_legend.items():
        _named = {m for m in _MODELS if m in str(_label).lower()}
        if not _named: continue
        _tiers = {(meta_of(x, "tier") or meta_of(x, "model") or "").lower()
                  for x in live if (meta_of(x, "lane") or meta_of(x, "owner")) == _lane}
        _tiers.discard("")
        if _tiers and not (_named & _tiers):
            _drift.append(f"{_lane} (label says {'/'.join(sorted(_named))}, rows run {'/'.join(sorted(_tiers))})")
    if _drift:
        w("  !! lane label out of date: " + " · ".join(_drift)
          + "   ·   fix it in 'lanes' in the project's tasks-view.json")

for _line in _warn: w(_line)

# The truncation line accuses the DATA and carries the measurement that proves
# it (REDESIGN.md, "The height ceiling is an instrument"). The old wording
# apologised for the tool; rows off screen are a finding about the queue.
if hidden:
    _q = len(openish) + len(now)
    _pct = f"{len(hidden) * 100 // max(1, _q)}%"
    _subs = sorted(len(subj(r)) for r in rows if not _is_done(r))
    _med = _subs[len(_subs) // 2] if _subs else 0
    _nog = sum(1 for x in live if not meta_of(x, "goal"))
    _bits = [f"⚠ {len(hidden)} rows not on screen, {_pct} of the queue",
             f"median subject {_med} chars, {_nog} carry no goal"]
    # A "N lines free, under the 9 a box needs" clause was tried here on
    # 2026-09-05 and removed the same night: a peer reading it cold called it
    # renderer internals with nothing to act on, which is the owner's test for
    # a line that does not earn its place. The gap is a box's own frame; the
    # dropped count above already tells the reader what they cannot see.
    if BOARD_URL: _bits.append(f"[Kanban] {BOARD_URL}")
    # The owed count already stands in the header, two screens up at most; a
    # second copy here read as a forecast to a cold reader (fleet, #56).
    w("   ·   ".join(_bits))

# Height is self-reported, so the number is substituted once every line exists.
out = [l.replace("{H}", str(len(out))) for l in out]
print("\n".join(out))

PY
