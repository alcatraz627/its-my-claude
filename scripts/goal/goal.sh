#!/usr/bin/env bash
# goal.sh — keep a session's goal alive across /clear, when the harness cannot.
#
# `/goal <text>` in the Claude Code TUI is a BUILT-IN: it installs a session-scoped
# Stop hook whose condition is the text (the harness injects "A session-scoped Stop
# hook is now active with condition: ..."). It lives in memory only. /clear drops it,
# nothing writes it to disk, and no tool lets an agent run it. So the owner re-typed
# the goal on every resume (owner, 2026-08-18: "no one armed a /goal this time").
#
# Two sources, deliberately kept apart, because they answer different questions:
#
#   harness   what /goal is ACTUALLY armed right now, read from this session's
#             transcript (<command-name>/goal</command-name> + <command-args>). This
#             is mechanical, so core-dump records what was set rather than what the
#             agent remembers. Only the owner can change it, only in the TUI.
#   gcc       ~/.claude/goals/<sid>.json, a file the AGENT may write. This is what
#             /catchup re-arms into after /clear, and what the goal hinter injects
#             back each session so the objective is never lost even when the harness
#             hook is not armed. It carries no Stop-hook force; it is memory.
#
# The re-arm contract (owner, 2026-08-18): the agent re-arms unless told not to; the
# bare minimum is that core-dump and catchup call the goal out with a line the owner
# can copy into the TUI; losing the goal is the one unacceptable outcome.
#
# Usage:
#   goal.sh harness [--sid SID] [--cwd DIR]  the built-in goal from the transcript, JSON
#   goal.sh set  "<text>" [--by agent|owner|catchup] [--sid SID]   write the gcc goal
#   goal.sh show [--sid SID] [--json]        both sources, merged verdict (default cmd)
#   goal.sh clear [--sid SID]                retire the gcc goal (harness one is the owner's)
#   goal.sh armline [--sid SID]              the one line to paste in the TUI: /goal <text>
#   goal.sh box [--sid SID]                  the structured callout for the current state
#                                            (🎯 light when armed, heavy when only the gcc
#                                            goal holds) followed by the bare paste line
#   goal.sh survey                           every gcc goal + live-session status (for the
#                                            observation window; read-only)
# Exit codes: 0 ok · 1 no goal · 2 usage · 3 no session id.

set -uo pipefail
GOALS="$HOME/.claude/goals"; mkdir -p "$GOALS"
CMD="${1:-show}"; [ $# -gt 0 ] && shift
SID="${CLAUDE_CODE_SESSION_ID:-}"; CWD="$PWD"; BY="agent"; JSON=0; TEXT=""
while [ $# -gt 0 ]; do case "$1" in
  --sid) SID="$2"; shift 2;; --cwd) CWD="$2"; shift 2;; --by) BY="$2"; shift 2;;
  --json) JSON=1; shift;; -h|--help) sed -n '2,32p' "$0"; exit 0;;
  *) TEXT="${TEXT:+$TEXT }$1"; shift;;
esac; done
if [ "$CMD" != survey ] && [ -z "$SID" ]; then echo "goal.sh: no session id (CLAUDE_CODE_SESSION_ID unset; pass --sid)" >&2; exit 3; fi
FILE="$GOALS/$SID.json"
# Resolve the transcript by SESSION ID across every project dir, cwd-derived path
# first as a cheap fast path. A session whose working surface differs from its
# start directory used to resolve a path that does not exist, and the silent miss
# read as "harness /goal: not armed" (automation-d8ff1149, 2026-08-19; gcc-work #4).
TRANSCRIPT="$HOME/.claude/projects/$(echo "$CWD" | sed 's#[/.]#-#g')/$SID.jsonl"
if [ ! -f "$TRANSCRIPT" ]; then
  TRANSCRIPT=$(ls "$HOME/.claude/projects/"*"/$SID.jsonl" 2>/dev/null | head -1)
fi
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  TRANSCRIPT=""
  TRANSCRIPT_MISS="no transcript for session $SID under ~/.claude/projects/*/ — harness-goal state UNKNOWN, not 'not armed'"
fi

# The last /goal the owner ran in this session, or nothing. Four shapes carry it,
# and only the first was known on day one (gcp-fable found the miss within hours):
#   1. a local-command block  <command-name>/goal</command-name> … <command-args>X</command-args>
#      (typed at a prompt boundary; args "clear" or empty = cleared)
#   2. the harness injection "A session-scoped Stop hook is now active with condition: \"X\""
#      (fires for BOTH boundary and mid-turn sets; the most reliable set signal)
#   3. a queue-operation enqueue whose content is "Goal set: X" (typed MID-TURN,
#      while the agent was working; no command block is written for that case)
#   4. <local-command-stdout>Goal set: X</local-command-stdout> / Goal cleared
# Reads only those shapes, in file order, last one wins; an agent QUOTING "/goal foo"
# in prose or in a tool result never counts. Auto-clear on completion leaves no
# transcript marker, so "armed" means "armed as of its ts, unless met since".
harness_json() {
  if [ -n "${TRANSCRIPT_MISS:-}" ]; then
    jq -n --arg r "$TRANSCRIPT_MISS" '{armed: null, reason: $r}'
    return 0
  fi
  [ -f "$TRANSCRIPT" ] || { echo '{"armed":false,"reason":"no transcript at '"$TRANSCRIPT"'"}'; return 1; }
  python3 - "$TRANSCRIPT" <<'PY'
import json, re, sys
last = None
def note(args, ts, how):
    global last
    last = {"args": args, "ts": ts, "how": how}
for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    if "/goal" not in line and "Goal set:" not in line and "Goal cleared" not in line and "session-scoped Stop hook" not in line:
        continue
    try: o = json.loads(line)
    except Exception: continue
    ts = o.get("timestamp"); t = o.get("type")
    if t == "queue-operation" and o.get("operation") == "enqueue":
        c = o.get("content") or ""
        if c.startswith("Goal set: "): note(c[len("Goal set: "):].strip(), ts, "queue")
        elif c.startswith("Goal cleared"): note("clear", ts, "queue")
        continue
    if t != "user": continue
    c = o.get("message", {}).get("content")
    if isinstance(c, list): c = " ".join(x.get("text", "") for x in c if isinstance(x, dict) and x.get("type") == "text")
    if not isinstance(c, str): continue
    if "<command-name>/goal</command-name>" in c:
        m = re.search(r"<command-args>(.*?)</command-args>", c, re.S)
        note((m.group(1).strip() if m else ""), ts, "command"); continue
    m = re.search(r'A session-scoped Stop hook is now active with condition: "(.*?)"\.', c, re.S)
    if m: note(m.group(1).strip(), ts, "active"); continue
    m = re.search(r"<local-command-stdout>Goal set: (.*?)</local-command-stdout>", c, re.S)
    if m: note(m.group(1).strip(), ts, "stdout"); continue
    if "<local-command-stdout>Goal cleared" in c: note("clear", ts, "stdout"); continue
if last is None:
    print(json.dumps({"armed": False, "reason": "no /goal in transcript"})); sys.exit(1)
if last["args"] in ("", "clear"):
    print(json.dumps({"armed": False, "reason": "last /goal was clear", "ts": last["ts"]})); sys.exit(1)
print(json.dumps({"armed": True, "text": last["args"], "ts": last["ts"], "source": "harness", "via": last["how"]}))
PY
}

# The callout the owner asked for (2026-08-18): whenever a goal is armed, by hand or by
# catchup, one structured box (conventions/callout-boxes.md, kind goal); when the
# harness /goal is NOT armed and only the gcc goal holds, the same box with the heavy
# rail as the warning. The paste line sits OUTSIDE the box between two double rules,
# on a line of its own with no rail character, so a terminal selection of that one
# line copies clean text. Owner: "make sure the selection wrap copy does not have any
# structure characters".
box_state() {
  local h g ha gs text why rail seal action
  h=$(harness_json); g=$(gcc_json 2>/dev/null || echo '{"set":false}')
  ha=$(echo "$h" | jq -r '.armed'); gs=$(echo "$g" | jq -r '.set')
  if [ "$ha" = true ]; then
    text=$(echo "$h" | jq -r .text); rail="--light"; seal="armed"
    why="harness /goal ARMED since $(echo "$h" | jq -r '.ts // "?"' | cut -c1-16)"
    [ "$gs" = true ] || why="$why · not yet in the gcc store (goal.sh set keeps it across /clear)"
    action="nothing to do now; the line between the double rules re-arms it after a /clear"
  elif [ "$gs" = true ]; then
    text=$(echo "$g" | jq -r .text); rail="--block"; seal=""
    why="gcc goal set by $(echo "$g" | jq -r .by) at $(echo "$g" | jq -r .set_at | cut -c1-16) · harness /goal NOT armed (only you can arm the Stop hook, in the TUI)"
    action="paste the line between the double rules (select that line only)"
  else
    echo "no goal to box" >&2; return 1
  fi
  # The box ends with WORK, never with a bare goal restatement: a check-in that
  # only restates the goal legitimised waiting (REMEDY-PLAN P3, 93% dead windows).
  local js nxt
  js=$(bash "$HOME/.claude/scripts/task-table/task-table.sh" --json 2>/dev/null)
  nxt=$(printf '%s' "$js" | jq -r -f "$HOME/.claude/scripts/task-table/agent-ready.jq" 2>/dev/null | jq -r 'first | select(.!=null) | "next agent-ready row: #\(.id) \(.subject)"' 2>/dev/null)
  [ -n "$nxt" ] || nxt="no agent-ready row; state your state: session-state.sh set blocked|finished --reason <why>"
  why="$why"$'\n'"$nxt"
  local B="$HOME/.claude/scripts/box/box.sh"
  if [ -x "$B" ]; then
    bash "$B" goal "${SID:0:8}" --body "$text"$'\n'"$why" --action "$action" $rail ${seal:+--seal "$seal"} 2>/dev/null || true
  else
    printf '┌─ 🎯 goal · %s ─\n│ %s\n│ %s\n└─\n' "${SID:0:8}" "$text" "$why"
  fi
  printf '═══════════════════════════════════════════════════════════════════════\n'
  printf '/goal %s\n' "$text"
  printf '═══════════════════════════════════════════════════════════════════════\n'
}

gcc_json() { [ -f "$FILE" ] && cat "$FILE" || { echo '{"set":false}'; return 1; }; }

# An armed goal is a Stop condition, so a clause the AGENT cannot finish jams the
# session: the hook keeps blocking, and the agent cannot clear a harness /goal
# (only the owner can). vb-fable lost six consecutive stop rounds to a proposed
# goal whose first clause was "Take the owner's board review of rounds 6 and 7",
# reported by catch-r7-a3 on 2026-08-19. Warn tier per ruling D2a: this names the
# clause and proceeds, because a goal can legitimately mention the owner in
# passing and refusing to set one would be worse than the jam.
owner_actor_warn() {
  # The signal is not "mentions the owner", it is "this clause's ACTOR is not me".
  # Two shapes cover the realistic phrasings: a WAIT construct (blocked until they
  # act) and a POSSESSIVE/VERB construct (the act is theirs). A fixed glob list was
  # tried first and measured badly, 13 misses in 20 real phrasings and a false fire
  # on "after the owner-actor warning ships", because a glob cannot tell the noun
  # "owner-actor" from the actor "owner". Warn tier per D2a: this names the clause
  # and proceeds, since a goal may mention the owner in passing.
  local t; t=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  local ACT='review|reviews|approv|sign[ -]?off|signs? off|rul(e|es|ing)|decid|verdict|go[ -]ahead|blessing|confirm(s|ation)?|answer|respond|weigh in|pick|choose'
  local WAIT="(await|awaiting|wait for|waiting (on|for)|pending|blocked (on|by)|once|after|until|when) +(the +)?(owner|you|they)"
  local POSS="(the +owner|you|your|owner)('s)? +($ACT)"
  local IMPER="(take|have|get|obtain|collect|secure) +((the +)?(owner|your|you)|[a-z ]{0,20}(from|by) +(the +)?(owner|you))"
  if [[ "$t" =~ $WAIT[^.]{0,30}($ACT) ]] || [[ "$t" =~ $POSS ]] || [[ "$t" =~ $IMPER ]]; then
    {
      echo "goal.sh: WARNING, this goal names an OWNER action as a clause."
      echo "  A Stop-hook goal is only satisfiable by clauses the agent can finish."
      echo "  An owner clause blocks every stop until the owner disarms it by hand."
      echo "  Reword so the agent's half is the goal, e.g. 'draft X and put it to"
      echo "  the owner' rather than 'take the owner's review of X'."
    } >&2
  fi
}

case "$CMD" in
  harness) harness_json ;;
  set)
    [ -n "$TEXT" ] || { echo "goal.sh set: need the goal text" >&2; exit 2; }
    owner_actor_warn "$TEXT"
    tmp="$FILE.tmp.$$"
    jq -n --arg t "$TEXT" --arg by "$BY" --arg sid "$SID" --arg cwd "$CWD" \
      --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      '{set:true,text:$t,by:$by,sid:$sid,cwd:$cwd,set_at:$ts}' > "$tmp" && mv -f "$tmp" "$FILE"
    echo "gcc goal set for ${SID:0:8} (by $BY)"
    box_state ;;
  clear)
    if [ -f "$FILE" ]; then mv -f "$FILE" "$FILE.cleared"; echo "gcc goal cleared for ${SID:0:8}"; else echo "no gcc goal for ${SID:0:8}"; fi ;;
  box) box_state ;;
  armline)
    t=$(gcc_json | jq -r '.text // empty'); [ -n "$t" ] || t=$(harness_json | jq -r '.text // empty')
    [ -n "$t" ] || { echo "no goal to arm" >&2; exit 1; }
    # Strip owner-actor clauses from the PASTE LINE. The harness Stop-hook
    # evaluator can never satisfy "get the owner's feedback": the owner acting is
    # not a state the agent's turn can reach, so an armed owner-actor clause
    # blocks every stop until a human intervenes (six blocked stops on
    # 2026-08-19, vb-fable; proposal src:goal-stop-loop). The stripped clause is
    # not lost: it stays verbatim in the gcc store and prints below as the
    # owner's own reminder, outside the armed text.
    stripped=$(printf '%s' "$t" | sed -E 's/(,| and| then)?[[:space:]]*(get|await|obtain|collect|secure)[[:space:]]+((the[[:space:]]+)?owner'"'"'?s?|your?)[[:space:]]+[a-z ]{0,30}(feedback|review|approval|sign[ -]?off|ruling|verdict|answer|decision)( via [a-z-]+)?//Ig')
    if [ "$stripped" != "$t" ] && [ -n "$(printf '%s' "$stripped" | tr -d '[:space:],.')" ]; then
      echo "/goal $stripped"
      echo "note: dropped an owner-actor clause from the armed text (the Stop evaluator cannot satisfy an act that is the owner's); the full goal stays in the gcc store: $t" >&2
    else
      owner_actor_warn "$t"
      echo "/goal $t"
    fi ;;
  show)
    h=$(harness_json); g=$(gcc_json)
    ha=$(echo "$h" | jq -r '.armed'); gs=$(echo "$g" | jq -r '.set')
    if [ "$JSON" = 1 ]; then jq -n --argjson h "$h" --argjson g "$g" '{harness:$h,gcc:$g}'; else
      if [ "$ha" = true ]; then echo "harness /goal ARMED: $(echo "$h" | jq -r .text)"
      elif [ "$ha" = null ]; then echo "harness /goal: UNKNOWN — $(echo "$h" | jq -r .reason)"
      else echo "harness /goal: not armed ($(echo "$h" | jq -r .reason))"; fi
      if [ "$gs" = true ]; then echo "gcc goal (${SID:0:8}, by $(echo "$g" | jq -r .by), $(echo "$g" | jq -r .set_at)): $(echo "$g" | jq -r .text)"; else echo "gcc goal: none"; fi
      if [ "$ha" != true ] && [ "$gs" = true ]; then echo "to arm in the TUI:  /goal $(echo "$g" | jq -r .text)"; fi
    fi
    [ "$ha" = true ] || [ "$gs" = true ] ;;
  survey)
    for f in "$GOALS"/*.json; do [ -f "$f" ] || continue
      jq -r '"\(.sid[0:8])  by=\(.by)  \(.set_at)  \(.cwd)  :: \(.text)"' "$f"; done ;;
  *) echo "goal.sh: unknown command $CMD" >&2; sed -n '22,30p' "$0" >&2; exit 2 ;;
esac
