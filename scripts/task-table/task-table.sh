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
    --session) SID="$2"; shift 2 ;;
    --pin) PIN="$2"; shift 2 ;;
    --candidates) MODE=candidates; shift ;;
    --group) GROUP="$2"; shift 2 ;;              # one-off: batch|domain|class|actor|auto
    --set-group) SETGROUP="$2"; shift 2 ;;       # persist for this project; the owner says it once
    # The range ends at the blank comment line after Usage, computed rather than
    # hardcoded: it was pinned at 26 while the block ran to 31, so --group,
    # --detail, --set-group and --session were invisible to --help.
    -h|--help) sed -n "2,$(rg -n '^set -uo pipefail' "$0" | head -1 | cut -d: -f1 | awk '{print $1-1}')p" "$0"; exit 0 ;;
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
elif [ -x "$RESOLVER" ] && D=$("$RESOLVER" 2>/dev/null) && [ -n "$D" ] && [ -d "$D" ]; then
  DIR="$D"; RESOLVED_BY="content-match"                # automatic, self-verifying
else
  json_refuse "could not identify your task store" "task-table.sh --session <sid8>, or --pin <sid8>" && exit 3
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

# The grouping the owner ruled for THIS project lives in a file the tool reads, not in
# a memory the agent has to remember to open. automation, 2026-08-18, after a 4th S3:
# "the gcc's own default actively teaches the shape the owner has rejected four times,
# and the only thing carrying the ruling is a project memory file". So: a project
# view file outranks the baseline, --group outranks the file for one call, and
# --set-group writes the file. Inside the gcc itself the file sits at its root.
# the project root is the git toplevel when inside a repo (a subdir cwd must still find the
# project's view file: gcp-fable rendered from contract/plans and got no lanes), else the cwd
PROOT=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null); [ -n "$PROOT" ] || PROOT="$PWD"
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
ALIAS="$ALIAS" MODEL="$MODEL" DETAIL="$DETAIL" MODE="$MODE" DIR="$DIR" GCC="$HOME/.claude" RESOLVED_BY="$RESOLVED_BY" GROUP="$GROUP" VIEW_FILE="$VIEW_FILE" python3 - <<'PY'
import json, os, re, pathlib, sys, time

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
    # An explicit lane beats prose inference. A row the agent has claimed
    # (lane gcc) is not owner-gated because its description mentions "needs
    # you": #48 on 2026-08-23 was ABOUT needs-human cards and rendered as a
    # gate, which hid its whole batch. Inference is for rows nobody labelled.
    lane = (meta(r, "lane") or "").lower()
    if lane and lane != "owner": return False
    if lane == "owner": return True
    return bool(GATE.search(desc(r)) or GATE.search(subj(r)))
def gate_declared(r): return bool(meta(r, "blocked_on"))

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
        # Set at TaskCreate time; never inferred. An inferred class would be
        # wrong in a way no reader could see.
        "class": meta(r, "class", ""), "domain": meta(r, "domain", ""),
        "blocked_on": meta(r, "blocked_on", ""), "gate_declared": gate_declared(r),
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
        "refs": refs_for(r), "_desc": desc(r),
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

if mode == "compact":
    nowtxt = f"#{now[0]['id']} {now[0]['subject'][:48]}" if now else "nothing in progress"
    # Every open row lands in a named bucket. `waiting` existed and was never
    # printed, so a 3-task store with two sequenced rows reported "3 open (0 need
    # you, 1 agent-ready)" and left two rows unaccounted for. This digest is what
    # scripts/hooks/task-table-inject.sh:84 puts into every agent's context, so an
    # unexplained remainder there is worse than in the table a human reads.
    _buckets = f"{len(blocked)} need you, {len(ready)} agent-ready"
    if waiting: _buckets += f", {len(waiting)} sequenced"
    if delegated: _buckets += f", {len(delegated)} delegated"
    _acct = len(blocked) + len(ready) + len(waiting) + len(now) + len(delegated)
    if now: _buckets += f", {len(now)} running"
    if _acct != len(openish): _buckets += f", {len(openish) - _acct} uncategorised"
    print(f"tasks: {len(openish)} open ({_buckets}), {len(done)} done")
    print(f"  now: {nowtxt}")
    if blocked: print("  needs you: " + ", ".join(f"#{x['id']}" for x in blocked))
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
if group == "auto":
    group = "goal" if has_meta("goal") else "batch" if has_meta("batch") else "domain" if has_meta("domain") else "actor"
    group_src += f" → {group}"
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

# bands: gated rows and deferred rows leave their goal and get their own band, as ruled
core = [x for x in live if not x["gated"] and not deferred(x)]
gates = [x for x in live if x["gated"] and not _deleg(x)]
later = [x for x in live if deferred(x) and not x["gated"]]
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
sub = "batch" if group != "batch" and has_meta("batch") else None   # goal › batch when both exist

if mode == "json":
    print(json.dumps({"store": str(d), "group": group, "sub": sub, "group_source": group_src,
        "groups": {k: [x["id"] for x in seq_sort(v)] for k, v in groups.items()},
        "gates": [x["id"] for x in gates], "later": [x["id"] for x in later],
        "counts": {"total": len(data), "in_progress": len(now), "open": len(openish),
        "done": len(done), "blocked": len(blocked), "ready": len(ready)},
        "tasks": data}, indent=2)); sys.exit()

import unicodedata
def dwidth(s):
    n = 0
    for ch in s:
        # East-Asian W/F and emoji-presentation symbols are two columns; "A" (ambiguous,
        # e.g. ▶ ○ ⛓) is one column on every non-CJK terminal, which is what broke the
        # old grid when it was guessed as two.
        if unicodedata.east_asian_width(ch) in ("W", "F") or 0x1F300 <= ord(ch) <= 0x1FAFF: n += 2
        else: n += 1
    return n
def dljust(s, w): return s + " " * max(0, w - dwidth(s))
def wrap(text, width):
    words, lines, cur = text.split(), [], ""
    for wd in words:
        if cur and dwidth(cur) + 1 + dwidth(wd) > width: lines.append(cur); cur = wd
        else: cur = (cur + " " + wd) if cur else wd
    if cur: lines.append(cur)
    return lines or [""]

W = 132
IDW = max(3, max((len(str(x["id"])) for x in data), default=1) + 1)
TAGW = 30; LANEW = max(9, min(16, max((dwidth(lane_tag(x)) for x in live), default=9)))
TASKW = W - (2 + 1 + IDW + 2 + LANEW + 2 + TAGW + 2)
RULE = "─" * W

out = []
def w(s=""): out.append(s)

_open_all = len(now) + len(openish); _other = len(data) - _open_all - len(done)
_counts = f"{_open_all} open" + (f" ({len(now)} running)" if now else "") + f", {len(done)} done" + (f", {_other} other" if _other else "")
if not data:
    w(f"!! EMPTY STORE: {d.name} holds no task files. A resumed session's tasks live in the store")
    w(f"   that CREATED them: task-table.sh --candidates, then --session <sid8>")
def _age(sec):
    m = sec / 60
    return f"{int(m)}m" if m < 60 else (f"{m/60:.0f}h" if m < 48*60 else f"{m/1440:.0f}d")
_open_m = [r.get("_mtime", 0) for r in rows if not _is_done(r) and r.get("_mtime")]
_last_any = _age(time.time() - max((r.get("_mtime", 0) for r in rows), default=time.time()))
# With nothing open there is no "open rows written N ago" to report, and the old
# fallback put the word "never" into a slot whose suffix is always " ago",
# printing "written never ago" at the owner. Say the true thing instead.
_last_open = _age(time.time() - max(_open_m)) if _open_m else ""
_when = (f"open rows written {_last_open} ago (any row {_last_any})"
         if _open_m else f"nothing open · last activity {_last_any} ago")
w(f"TASKS  ·  {d.name}  ·  {alias} ({model})  ·  {_counts}  ·  {_when}")
w(f"  grouped: {group}" + (f" › {sub}" if sub else "") + f" ({group_src})  ·  resolved by {resolved_by}" +
  (f"  ·  needs you: " + " ".join(f"#{x['id']}" for x in gates) if gates else "") +
  (f"  ·  running: " + " ".join(f"#{x['id']}" for x in now) if now else ""))
# owner-lane and deferred rows are not this agent's to run, so a missing tier there is not a gap
notier = sum(1 for x in live if not (meta_of(x, "tier") or meta_of(x, "model"))
             and (meta_of(x, "lane") or "").lower() != "owner" and not deferred(x))
if notier: w(f"  {notier} open row(s) carry no tier (rendered '?'); set with task.sh update <id> --tier <fable|opus|sonnet|haiku|lm>")
if view.get("_broken"): w(f"  !! view file did not parse, ignored: {view['_broken']}")
if resolved_by.startswith("guess"):
    w(f"  !! STORE NOT CONFIRMED ({resolved_by}). This may be another session's queue. Pin: task-table.sh --session <sid8>")
if _open_m and time.time() - max(_open_m) > 24 * 3600:
    w(f"  !! NOT TODAY'S QUEUE: no open row has moved in {_last_open}; carried-over or umbrella items?")

_glyphs_used = set()
def glyph(x):
    g = _glyph(x); _glyphs_used.add(g); return g
def _glyph(x):
    if _is_done(x):                            return "✅"
    if x.get("status") == "in_progress":       return "▶"
    if _deleg(x):                              return "🤝"
    if x.get("gate_declared"):                 return "🔴"
    if x.get("blocked"):                       return "⏳"
    if x.get("waits_on"):                      return "⛓"
    return "○"
_uniform = set()
_ubase = live if live else done
for _k in ("class", "domain", "batch", "goal", "planning"):
    _vals = [meta_of(x, _k) for x in _ubase if meta_of(x, _k)]
    # Share is measured against the rows that CARRY the key, not the whole store:
    # mixing the denominators meant a key present on 79 of 100 rows with one value
    # was kept while one on 85 was dropped, for no reason a reader could see.
    if len(_vals) >= 5 and max(_vals.count(v) for v in set(_vals)) > 0.8 * len(_vals): _uniform.add(_k)
def tags(x):
    shown = {"class", "domain", "batch", "goal", "lane", "owner", "tier", "model", "blocked_on", "verified", "note", "board_card", "deferred", "planning", "priority"}
    t = []
    for k in ("class", "domain", "batch", "goal", "planning"):
        v = meta_of(x, k)
        if v and k != group and k != sub and k not in _uniform: t.append(str(v))
    for k, v in (x.get("metadata") or {}).items():
        if k not in shown and v not in ("", None, [], {}): t.append(f"{k}:{v}")
    v = meta_of(x, "verified")
    if v not in ("", None, False): t.append("verified" if v is True else f"verified:{v}")
    return " · ".join(t)
def prio(x):
    v = meta_of(x, "priority"); return f"{v} " if v else ""
def state_note(x):
    if x.get("waits_on"): return "after #" + " #".join(str(i) for i in x["waits_on"])
    return ""
def fit_tags(x):
    """The tag cell, cut on tag boundaries rather than mid-word.

    A hard slice produced cells like 'gate-adherence · forge · deplo' and
    'feature · console · V1 showabl', where the reader cannot tell a truncated
    string from a real tag value (gcp-fable, 2026-08-20). Drop whole tags and
    say so with an ellipsis.
    """
    parts = [p for p in tags(x).split(" · ") if p]
    if not parts: return ""
    kept, used = [], 0
    for p in parts:
        add = len(p) + (3 if kept else 0)
        if used + add > TAGW - (2 if len(kept) < len(parts) - 1 else 0): break
        kept.append(p); used += add
    if not kept:                      # one tag too wide for the cell on its own
        return parts[0][:max(1, TAGW - 1)] + "…"   # trailing … = THIS tag is cut
    out_s = " · ".join(kept)
    if len(kept) < len(parts):
        out_s += f" +{len(parts) - len(kept)}"     # "+N" = N whole tags dropped
    return out_s[:TAGW]

def row(x, indent="  "):
    head = f"{indent}{glyph(x)} #{x['id']}"
    head = dljust(head, len(indent) + 2 + 1 + IDW + 1)
    sn = state_note(x)
    task = prio(x) + (f"[{sn}] " if sn else "") + x["subject"]
    tag = dljust(lane_tag(x), LANEW)
    if compact:
        one = task if dwidth(task) <= TASKW else task[:TASKW-1] + "…"
        w(f"{head}{dljust(one, TASKW)}  {tag}  {fit_tags(x)}")
        # even compact keeps the two fields the owner reads first when they are set
        keep = []
        if _deleg(x):
            _c = meta_of(x, "delegated_confirmed")
            keep.append(f"delegated to {_deleg(x)}" + (" · CONFIRMED" if _c == "true" else " · unconfirmed"))
        if x.get("blocked_on"): keep.append(f"blocked: {x['blocked_on']}")
        if meta_of(x, "note"): keep.append(f"note: {meta_of(x, 'note')}")
        if keep: w(" " * (len(indent) + 2 + 1 + IDW + 1) + ("↳ " + " · ".join(keep))[:W - 12])
        return
    lines = wrap(task, TASKW)
    w(f"{head}{dljust(lines[0], TASKW)}  {tag}  {fit_tags(x)}")
    for ln in lines[1:]: w(" " * (len(indent) + 2 + 1 + IDW + 1) + ln)
    # the detail line: what the old grid dropped
    bits = []
    if _deleg(x):
        _c = meta_of(x, "delegated_confirmed")
        bits.append(f"delegated to {_deleg(x)}" + (" · CONFIRMED" if _c == "true" else " · unconfirmed"))
    if x.get("blocked_on"): bits.append(f"blocked: {x['blocked_on']}")
    if group != "goal" and meta_of(x, "goal"): bits.append(f"goal: {meta_of(x, 'goal')}")
    if meta_of(x, "note"): bits.append(f"note: {meta_of(x, 'note')}")
    if x.get("blocks"): bits.append("blocks #" + " #".join(str(i) for i in x["blocks"]))
    if x.get("board_card"): bits.append(f"board: {x['board_card']}")
    # glosses for ids a stranger cannot parse (task numbers, proposals, atone ids); a
    # file path already says what it is, so paths are left to --detail
    idrefs = [r for r in x.get("refs") or [] if r["kind"] not in ("file",) and not r["ref"].startswith(("/", "~", "scripts/", "rules/", "assets/", "conventions/", "skills/"))]
    if idrefs: bits.append("refs: " + " · ".join(f"{r['ref']} ({r['gloss'][:34]})" for r in idrefs[:2]) + (f" +{len(idrefs)-2}" if len(idrefs) > 2 else ""))
    if bits:
        for ln in wrap("↳ " + " · ".join(bits), W - (len(indent) + 2 + 1 + IDW + 1)):
            w(" " * (len(indent) + 2 + 1 + IDW + 1) + ln)
    if detail and (x.get("_desc") or x.get("refs")):
        for ln in wrap((x.get("_desc") or "").replace("\n", " ")[:600], W - (len(indent) + 2 + 1 + IDW + 1)):
            w(" " * (len(indent) + 2 + 1 + IDW + 1) + ln)
        for r in x.get("refs") or []: w(" " * (len(indent) + 2 + 1 + IDW + 1) + f"{r['kind']} {r['ref']}: {r['gloss']}")

# height law: 44 lines unless --detail; truncate loudly naming ids
LINE_CAP = HEIGHT - 9   # rules + hidden-id lines + legend + done + footer
compact = False
def render_rows(compact_mode):
    """Emit bands. compact_mode: one line per row, no detail, so more rows fit under the cap."""
    global compact, hidden
    compact = compact_mode; hidden = []
    def fits(n): return detail or len(out) + n <= LINE_CAP
    def row_cost(x):
        # A compact row is TWO lines when it carries blocked_on or a note: row()
        # emits the continuation. Asking room-for-one and then emitting two is how
        # the table still rendered 45/44 after the band fix (adversarial review,
        # 2026-08-20). The uncapped full path re-renders compact when it overruns,
        # so 2 is the true worst case here.
        return 2 if (compact and (x.get("blocked_on") or meta_of(x, "note"))) else 1
    def room_for(x): return fits(row_cost(x))
    def hide_all(items): hidden.extend(f"#{x['id']}" for x in items)
    def band(title, items, indent="  "):
        if not items: return
        # A band header costs two lines (rule + title) and used to be written
        # unconditionally, which caused both halves of #103: past the cap every
        # row was hidden and the header stayed, so the band rendered EMPTY, and
        # those two lines per band pushed the total over the 44-line law (47/44
        # observed 2026-08-19). A band earns its header only if a row can follow.
        if not fits(3): hide_all(items); return
        w(RULE); w(title)
        for x in items:
            if not room_for(x): hidden.append(f"#{x['id']}"); continue
            row(x, indent)
    # the owner reads the gates first, so they come first and are never the rows the cap eats
    band("GATES (you)   " + f"({len(gates)})", seq_sort(gates))
    for k, items in groups.items():
        label = labels.get(k, k)
        n_run = sum(1 for x in items if x["status"] == "in_progress"); n_wait = sum(1 for x in items if x.get("waits_on"))
        summ = f"{len(items)} open" + (f", {n_run} running" if n_run else "") + (f", {n_wait} sequenced" if n_wait else "")
        if sub:
            # same rule one level deeper: a group needs rule + title + subtitle +
            # one row, and each subgroup needs its subtitle + one row
            if not fits(4): hide_all(items); continue
            w(RULE); w(f"{group.upper()} {label}   ({summ})")
            subs = {}
            for x in items: subs.setdefault(key_of(x, sub), []).append(x)
            for sk in sorted(subs, key=natkey):
                rows_here = seq_sort(subs[sk])
                if not fits(2): hide_all(rows_here); continue
                w(f"  {sub.upper()} {labels.get(sk, sk)}")
                for x in rows_here:
                    if not room_for(x): hidden.append(f"#{x['id']}"); continue
                    row(x, "    ")
        else:
            band(f"{group.upper()} {label}   ({summ})", seq_sort(items))
    if delegated:
        _unc = sum(1 for x in delegated if meta_of(x, "delegated_confirmed") != "true")
        band(f"DELEGATED · someone else has these   ({len(delegated)}"
             + (f", {_unc} unconfirmed)" if _unc else ")"), seq_sort(delegated))
    band("LATER · deferred / after V1   " + f"({len(later)})", seq_sort(later))
    # THE ALL-DONE TERMINAL STATE. Collapsing done rows to a line of bare ids is
    # the ruled shape, but it was ruled for tables that still show open work. With
    # nothing open it degenerates into a table whose entire content is a row of
    # numbers, which is the owner's own gloss rule violated by its own renderer.
    # So when there is no live work, the done rows ARE the table.
    if not live and done:
        # Only band by a key the done rows actually carry. When they carry none,
        # `group` has fallen through to "actor" and the bands come out titled
        # "DONE · AGENT-READY", which is an actor bucket asserted over finished
        # work that never had one (second seat, 2026-08-20). One honest band then.
        if any(meta_of(x, group) for x in done):
            by = {}
            for x in seq_sort(done): by.setdefault(key_of(x, group), []).append(x)
            for k in sorted(by, key=natkey):
                band(f"DONE · {labels.get(k, k)}   ({len(by[k])})", by[k])
        else:
            band(f"DONE   ({len(done)})", seq_sort(done))
    w(RULE)
    if hidden:
        # every hidden id is named (owner: a silently trimmed list reads complete), up to
        # three lines; past that --json carries the rest
        chunks = [hidden[i:i+26] for i in range(0, len(hidden), 26)]
        w(f"… +{len(hidden)} rows held by the height cap (--detail or --json shows all): {' '.join(chunks[0])}")
        for c in chunks[1:3]: w("      " + " ".join(c))
        if len(chunks) > 3: w(f"      … +{sum(len(c) for c in chunks[3:])} more ids in --json")

header_len = len(out)
render_rows(False)
if not detail and (len(out) + 4 > HEIGHT or hidden):
    del out[header_len:]
    render_rows(True)
    out.insert(header_len, "  (compact rows: the full view did not fit 44 lines; --detail shows every line)")
lane_vals = sorted({(meta_of(x, "lane") or meta_of(x, "owner")) for x in live if (meta_of(x, "lane") or meta_of(x, "owner"))})
# A legend is a key to what is on screen, so it lists only what is on screen. The
# static six-glyph legend printed all six under a table with zero rows.
# From the set glyph() recorded while rendering, not a substring scan of the
# output: a ✅ or 🔴 inside a task SUBJECT would vote itself into the key
# (second seat, 2026-08-20).
_key = [("✅", "done"), ("▶", "running"), ("○", "ready"), ("⛓", "after #x"),
        ("🤝", "delegated"), ("🔴", "needs you (declared)"), ("⏳", "needs you (inferred)")]
_used = [f"{g} {n}" for g, n in _key if g in _glyphs_used]
if _used:
    legend = "legend: " + " · ".join(_used)
    if lanes_legend: legend += "   lanes: " + " · ".join(f"{k} = {v}" for k, v in lanes_legend.items())
    elif lane_vals: legend += "   lanes: " + " · ".join(lane_vals)
    w(legend)
# The id-collapse is for tables that still show open work. In the all-done view the
# subjects are already on screen above, so repeating them as ids is noise.
if done and live:
    ids = [f"#{x['id']}" for x in done]; line = f"done ({len(done)}): "; shownd = []
    for i in ids:
        if len(line + " ".join(shownd + [i])) > W - 20: break
        shownd.append(i)
    w(line + " ".join(shownd) + ("" if len(shownd) == len(ids) else f" … +{len(ids)-len(shownd)} more"))
# The footer is status, not agent help. The owner: "the footer is a CLI flag dump
# aimed at the OWNER, whose ruling was 'this is FOR MY visibility'". -h carries
# the flags; this line carries the one fact a reader wants from a footer.
w(f"height {len(out)+1}/{HEIGHT}  ·  -h for flags")
# A full-width rule under a narrow table frames nothing. Size the rules to the
# widest line they actually separate (owner: "rule width fits content").
_content = [l for l in out if not set(l.strip()) <= {"─"}]
_wide = max((dwidth(l) for l in _content), default=W)
_wide = max(20, min(W, _wide))
out = [("─" * _wide if (l and set(l.strip()) <= {"─"}) else l) for l in out]
print("\n".join(out))

PY
