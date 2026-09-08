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
  --via) VIA="$2"; shift 2;;
  --json) JSON=1; shift;; -h|--help) sed -n '2,32p' "$0"; exit 0;;
  *) TEXT="${TEXT:+$TEXT }$1"; shift;;
esac; done

# WHO decided the goal, and BY WHAT MECHANISM, are two questions. `by` answered
# neither reliably because it held both plus a third: measured 2026-09-04 it
# carried 13 values over 44 records, mixing roles (owner, user, owner-ruling),
# mechanisms (catchup, core-dump) and session aliases (gcp-fable, forge-console,
# walmart, watcher). So "which goals did the owner set" needed insider knowledge
# of which of those thirteen strings meant a person.
#
# Split, both closed. `by` is the deciding party and answers that question with
# an equality test. `via` is the mechanism. The session alias is dropped entirely
# because `sid` and `sids` already carry it, and a third copy that can disagree
# is worse than none.
#
# Old values are MAPPED, not refused. catchup and core-dump call this script
# today and refusing them would break the two callers that write most records.
# Owner ruling 2026-08-20 governs the shape: map, and say so, naming the whole
# acceptable set every time.
BY_WHO="owner agent"
BY_VIA="manual catchup core-dump hinter warden"
VIA="${VIA:-}"
map_by() {  # prints "<who> <via>" for any legacy or current value
  case "$1" in
    owner|user|owner-ruling|human)      printf 'owner manual' ;;
    agent|session)                      printf 'agent manual' ;;
    catchup)                            printf 'agent catchup' ;;
    core-dump|coredump)                 printf 'agent core-dump' ;;
    hinter)                             printf 'agent hinter' ;;
    warden)                             printf 'agent warden' ;;
    # A session alias says WHICH agent, which sid already records. Treat it as an
    # agent-set goal rather than inventing a fourth axis.
    *)                                  printf 'agent manual' ;;
  esac
}
# lint reads no store and writes none, so it needs no session. Requiring one
# made the register unreachable from any shell without CLAUDE_CODE_SESSION_ID,
# which is every test sandbox and every peer calling it by hand (found 2026-09-05
# when goal.test.sh's corpus loop captured "no session id" for every case).
if [ "$CMD" != survey ] && [ "$CMD" != lint ] && [ -z "$SID" ]; then echo "goal.sh: no session id (CLAUDE_CODE_SESSION_ID unset; pass --sid)" >&2; exit 3; fi
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
    # A real /goal invocation is the name tag followed directly by its args tag.
    # The name tag ALONE appears in prose too: the core-dump skill body, injected
    # as a user turn, quotes it while documenting this parser, and a substring
    # match on it recorded "clear" on every dump (adv-goal F1, 2026-09-05; the
    # fabad34c goal was erased twice this way). So the match is the pair, and a
    # quoted name with no adjacent args is not an invocation.
    # The harness emits name, then an optional <command-message>, then args, on
    # adjacent lines. Tolerate the message tag; still require the args tag to be
    # part of the same block rather than anywhere in the turn.
    m = re.search(r"<command-name>/goal</command-name>\s*(?:<command-message>[^<]*</command-message>\s*)?<command-args>(.*?)</command-args>", c, re.S)
    if m:
        note(m.group(1).strip(), ts, "command"); continue
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
    return 1
  fi
  return 0
}

# THE REGISTER, applied to a goal before it is written or revived.
#
# rules/goal-statement-on-starting-work.md was rewritten on 2026-09-04 and its
# central finding is that LENGTH was never the test, checkability is. Two shapes
# fit on one line, read as compliant, and cannot be marked by anyone:
#
#   an unbounded quantifier   "every way stage 7 can fail shows an operator what
#                             happened" — nobody can confirm it, only fail to
#                             find a counterexample
#   a standing behaviour      "every question is answered the turn it arrives" —
#                             true over a window, never at a moment
#
# It matters most on a RE-ARM. /catchup revives a checkpoint goal marked STILL
# VALID verbatim, which is exactly how prose-shaped goals kept propagating for
# days after the rewrite landed: nothing read the goal against the register on
# the way back in. So the check runs on every write, and the re-arm path is the
# one it was built for.
#
# WARN, never refuse. The owner's own goals go through this path and a register
# that can block him is worse than one he sometimes ignores. Every finding names
# the clause and says what would fix it.
goal_lint() {  # goal_lint <text>; prints findings to stderr, always returns 0
  local t n; t=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]'); n=0
  _f(){ n=$((n+1)); printf '  %s\n' "$1" >&2; }

  # It returns 1 when it fires, so the tally below counts it. A summary saying
  # "1 finding" while two are on screen teaches the reader to distrust the count.
  owner_actor_warn "$1" || n=$((n+1))

  # Unbounded quantifier. The tell is a universal over a set nobody can
  # enumerate, which is why "every row in this store" is fine and "every way it
  # can fail" is not: the first names a finite thing on disk.
  # The noun list was closed and missed every live instance (adv-goal F2,
  # 2026-09-05: "every one of the nine checks", "every row", "every doc", "no
  # agent"). Widened, with one exemption kept from the original reasoning: a
  # set bounded to a named thing on disk ("every row in this store") is finite
  # and does not fire. ERE has no lookahead, so the exemption is a second test.
  local _qn='(way|ways|case|cases|path|paths|reason|reasons|comment|comments|file|files|thing|things|place|places|row|rows|doc|docs|store|stores|agent|agents|check|checks|render|renders|clause|clauses|session|sessions|lane|lanes)'
  # Bounded means the noun is followed by a locator: "in /tasks", "under GATES",
  # "in this store". A locator that is itself a quantifier ("in every store",
  # "anywhere") does not bound anything.
  # Word-bounded: without it "how many rows" matched on the "any" inside "many"
  # (own goal, 2026-09-08). ERE has no \b, so the boundary is a non-letter.
  local _qpre='(^|[^a-z])(every|any|all|no)[[:space:]]+(one[[:space:]]+of[[:space:]]+the[[:space:]]+[a-z]+[[:space:]]+)?([a-z]+[[:space:]]+)?'
  if [[ "$t" =~ $_qpre$_qn([[:space:]]|$) ]]; then
    _bounded=0
    if [[ "$t" =~ $_qpre$_qn[[:space:]]+(in|under|on|inside)[[:space:]]+([a-z0-9_/~.-]+) ]]; then
      case "${BASH_REMATCH[${#BASH_REMATCH[@]}-1]}" in every|all|any|each|anywhere|everywhere) ;; *) _bounded=1 ;; esac
    fi
    [[ "$t" =~ (anywhere|everywhere) ]] && _bounded=0
    [ "$_bounded" -eq 1 ] || _f "unbounded quantifier: a reader can only fail to find a counterexample. Name the two or three instead, or bound the set to a thing on disk."
  fi
  # A filename is the agent's artifact, not the reader's outcome. The owner's
  # own goals carry none; his tell for a queue wearing goal punctuation was
  # "ticket number, filename, or count", and only the first was checked.
  if [[ "$t" =~ [a-z0-9_-]+\.(md|sh|py|json|jsonl|ya?ml|tsx?|jsx?|toml|txt|html|css|svelte) ]]; then
    _f "names a file: a goal says what changes for the reader, not which artifact the agent touches. Move the filename to the task list."
  fi
  # Standing behaviour. True over a window, so nobody can mark it at the moment
  # the goal is read.
  if [[ "$t" =~ (the[[:space:]]+turn[[:space:]]+it|each[[:space:]]+time|whenever|every[[:space:]]+time|always[[:space:]]+(answer|reply|respond|hand)) ]]; then
    _f "standing behaviour, not a state: true over a window, unmarkable at a moment. Name the artifact that would show it happened."
  fi
  # A queue wearing a goal's punctuation. Ticket ranges and counts are the tell.
  # Counts spelled out ("the four renames", "all three findings") are the same
  # tell as digits and were invisible (adv-goal F2 case 2).
  if [[ "$t" =~ (h[0-9]+\.\.|([0-9]+|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)[[:space:]]+(findings|tasks|items|rows|tickets|fixes|renames|bugs|prs|commits|files|checks)|#[0-9]+[[:space:]]*,[[:space:]]*#[0-9]+) ]]; then
    _f "this reads as a checklist: it is met when the boxes are ticked, whether or not anything got better."
  fi
  # One long sentence. The owner's own ruling, verbatim: "Rephrase your goal as
  # simpler statements about the goal, not this prose."
  local words; words=$(printf '%s' "$1" | wc -w | tr -d ' ')
  local stops; stops=$(printf '%s' "$1" | tr -cd '.' | wc -c | tr -d ' ')
  if [ "$words" -gt 45 ] && [ "${stops:-0}" -lt 3 ]; then
    _f "one long sentence ($words words, $stops full stops): the tangible parts blur. Split into short statements, each true or false on its own."
  fi
  # Word salad, the other register (owner 2026-09-08, twice in one hour on the
  # same lane): three sentences that each run past twenty-five words, so no
  # single line can be marked true or false. The long-sentence check above
  # needs 45 words with under three stops and let it through.
  local _long; _long=$(printf '%s' "$1" | python3 -c '
import re, sys
t = sys.stdin.read()
sents = [s.strip() for s in re.split(r"(?<=[.!?])\s+", t) if s.strip()]
long = [s for s in sents if len(s.split()) > 25]
print(len(sents), len(long))' 2>/dev/null)
  local _ns _nl; _ns=${_long%% *}; _nl=${_long##* }
  if [ "${_nl:-0}" -gt 0 ]; then
    _f "word salad: $_nl sentence(s) run past 25 words. A reader marks one short statement true or false; cut each long one into the one or two states it names."
  fi
  if [ "${_ns:-0}" -gt 6 ]; then
    _f "$_ns sentences: past six the goal is a queue. Keep the three to six states a person would recognise; the rest belong in the task list."
  fi
  [ "$n" -gt 0 ] && printf 'goal.sh: %s register finding(s) above. The goal still stands; this is a read, not a gate.\n' "$n" >&2
  return 0
}

case "$CMD" in
  harness) harness_json ;;
  lint)
    [ -n "$TEXT" ] || { echo "goal.sh lint: need the goal text" >&2; exit 2; }
    goal_lint "$TEXT"; echo "linted." ;;
  set)
    [ -n "$TEXT" ] || { echo "goal.sh set: need the goal text" >&2; exit 2; }
    # Reads the register on EVERY write, which is what makes the re-arm path
    # safe: /catchup revives a STILL VALID goal verbatim and nothing used to
    # look at it on the way back in.
    goal_lint "$TEXT"
    # Normalise --by into the two closed fields. An explicit --via wins over the
    # one the mapping inferred, so `--by owner --via manual` and a future caller
    # that knows its own mechanism both say what they mean.
    _mapped=$(map_by "$BY"); _who=${_mapped% *}; _inferred_via=${_mapped#* }
    # Warn only on a value the table does not recognise. `catchup` and
    # `core-dump` are the documented mechanisms and between them write most
    # records, so warning on those would put two lines of noise on the healthy
    # path every time and teach the reader to skip the whole channel. A known
    # spelling mapping to its own meaning is not a mistake.
    case " owner agent user owner-ruling human session catchup core-dump coredump hinter warden " in
      *" $BY "*) ;;
      *) { printf 'goal.sh: --by "%s" is not a deciding party or a known mechanism; recorded as by=%s via=%s.\n' "$BY" "$_who" "${VIA:-$_inferred_via}"
           printf '  who: %s\n  via: %s\n' "$BY_WHO" "$BY_VIA"
           printf '  a session alias belongs in sid, which already records it.\n'; } >&2 ;;
    esac
    BY="$_who"; VIA="${VIA:-$_inferred_via}"
    # A13 (owner default, accepted 2026-09-05): provenance metadata never loses
    # a goal. An unknown --via used to exit 2 and write nothing while a WRONG
    # goal always wrote, which inverted the one outcome the owner called
    # unacceptable. Now it warns, records via=unknown, and writes.
    case " $BY_VIA " in *" $VIA "*) ;; *)
      { printf 'goal.sh: --via "%s" is not a known mechanism; recorded as via=unknown and the goal is written anyway.\n' "$VIA"
        printf '  known: %s\n' "$BY_VIA"; } >&2
      VIA="unknown" ;;
    esac
    # GOAL IDENTITY. A goal is its TEXT, not the session that happened to arm it.
    #
    # The store keys on session id, one file per sid, so it never appended to a
    # list and never looked wrong. What it did instead was lose the fact that two
    # records are the same goal. Every resume gets a fresh sid, catchup re-arms
    # the checkpoint's goal verbatim under it, and a week of resuming one piece of
    # work leaves a pile of records that no query can collapse. Measured
    # 2026-09-04: 44 goals on disk, 16 near-duplicate pairs, the top six matching
    # exactly, and one owner goal re-armed identically three times in 22 hours.
    #
    # goal_id is a content hash over the normalised text, so the same goal armed
    # in ten sessions carries one id. The FILE still lives at $GOALS/$SID.json, so
    # show, box, armline, clear and the hinter are untouched: this adds identity
    # without moving anything that reads.
    _norm=$(printf '%s' "$TEXT" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')
    GOAL_ID=$(printf '%s' "$_norm" | shasum -a 256 | cut -c1-12)
    # Inherit lineage from the newest earlier record carrying this id, so
    # first_set_at answers "when did this goal start" rather than "when did this
    # session start", and first_by survives a catchup re-arm claiming the goal.
    # Aggregate over EVERY record carrying this id rather than inheriting from
    # "the newest" one. A first version picked the newest by mtime, and records
    # written in the same second tie, so `-nt` was false and it silently kept
    # whichever file sorted first: the third arming of a goal inherited from the
    # first and reported itself as re-arm #1 with two sessions instead of three.
    # Nothing about that looked wrong in the output. Aggregating needs no
    # ordering, so there is no tie to lose.
    _now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    _agg=$(jq -s --arg gid "$GOAL_ID" '
        [ .[] | select(.goal_id == $gid) ] as $m
        | if ($m | length) == 0 then null
          else ($m | sort_by(.first_set_at // .set_at)) as $s
            | { first_set_at: ($s[0].first_set_at // $s[0].set_at),
                first_by:     ($s[0].first_by // $s[0].by),
                sids:         ([ $m[] | (.sids // [.sid])[] ] | unique),
                rearms:       ($m | length) }
          end' "$GOALS"/*.json 2>/dev/null)
    if [ -n "$_agg" ] && [ "$_agg" != "null" ]; then
      _first_at=$(printf '%s' "$_agg" | jq -r '.first_set_at')
      _first_by=$(printf '%s' "$_agg" | jq -r '.first_by')
      _sids=$(printf '%s' "$_agg" | jq -c '.sids')
      _rearms=$(printf '%s' "$_agg" | jq -r '.rearms')
      _prior=1
    else
      _first_at="$_now"; _first_by="$BY"; _sids='[]'; _rearms=0; _prior=""
    fi
    tmp="$FILE.tmp.$$"
    jq -n --arg t "$TEXT" --arg by "$BY" --arg sid "$SID" --arg cwd "$CWD" \
      --arg ts "$_now" --arg gid "$GOAL_ID" --arg fat "$_first_at" --arg fby "$_first_by" \
      --argjson sids "$_sids" --argjson rearms "$_rearms" \
      --arg via "$VIA" \
      '{set:true,text:$t,by:$by,via:$via,sid:$sid,cwd:$cwd,set_at:$ts,
        goal_id:$gid,first_set_at:$fat,first_by:$fby,rearms:$rearms,
        sids:(($sids + [$sid]) | unique)}' > "$tmp" && mv -f "$tmp" "$FILE"
    if [ -n "$_prior" ]; then
      echo "gcc goal RE-ARMED for ${SID:0:8} (by $BY) · goal $GOAL_ID, first set $_first_at by $_first_by, re-arm #$_rearms"
    else
      echo "gcc goal set for ${SID:0:8} (by $BY) · new goal $GOAL_ID"
    fi
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
    # Grouped by goal_id, so a goal armed across ten resumes is one line with a
    # re-arm count rather than ten lines that look like ten goals. Records
    # written before identity existed have no goal_id; they are hashed on read so
    # the old pile collapses too, without rewriting anyone's files.
    python3 - "$GOALS" <<'PY'
import hashlib, json, os, re, sys
d = sys.argv[1]
rows = []
for n in sorted(os.listdir(d)):
    if not n.endswith(".json"):
        continue
    try:
        o = json.load(open(os.path.join(d, n)))
    except Exception:
        continue
    t = o.get("text") or ""
    gid = o.get("goal_id") or hashlib.sha256(
        re.sub(r"\s+", " ", t.lower()).strip().encode()).hexdigest()[:12]
    rows.append((gid, o))
by = {}
for gid, o in rows:
    by.setdefault(gid, []).append(o)


# Legacy records carry the old single field. Map on read with the same table the
# writer uses, so the count below is answerable for the whole pile and not only
# for records written after the split.
def who_of(o):
    v = (o.get("by") or "").lower()
    if v in ("owner", "user", "owner-ruling", "human"):
        return "owner"
    return "agent"


_owner_goals = sum(1 for gid, os_ in by.items() if any(who_of(o) == "owner" for o in os_))
print(f"{len(by)} distinct goal(s) across {len(rows)} record(s)"
      f"  ·  {_owner_goals} the owner set, {len(by) - _owner_goals} an agent set")
for gid, os_ in sorted(by.items(), key=lambda kv: -len(kv[1])):
    newest = max(os_, key=lambda o: o.get("set_at") or "")
    first = min(os_, key=lambda o: o.get("first_set_at") or o.get("set_at") or "")
    whos = sorted({who_of(o) for o in os_})
    vias = sorted({(o.get("via") or "?") for o in os_} - {"?"})
    n = len(os_)
    mark = f"  ×{n}" if n > 1 else "    "
    _v = f" via {'/'.join(vias)}" if vias else ""
    print(f"{gid}{mark}  first {(first.get('first_set_at') or first.get('set_at') or '?')[:16]}"
          f"  by {'/'.join(whos)}{_v}  :: {(newest.get('text') or '')[:80]}")

# NEAR-duplicates are reported, never merged. The identity hash is exact on
# purpose: two goals that differ by a trailing clause are two goals, and fusing
# them would lose whichever text the owner actually meant. Measured 2026-09-04,
# one real pair differs only by " say hi to ..." on the end, which is a real
# difference in what the session was asked to do. So they are named here and the
# reader decides, rather than a similarity threshold deciding for them.
import difflib
# The representative text per goal, chosen DETERMINISTICALLY and compared on
# normalised text. Both halves were flaky before, and the flake hid a real pair
# rather than inventing one, which is the direction that goes unnoticed.
#
# set_at has one-second granularity, so several records of the same goal written
# in one second tie, and max() then keeps whichever the filesystem listed first.
# When that happened to be a variant padded with leading spaces, the shared
# prefix against its near-twin computed as zero and the pair silently vanished
# from the report. Breaking the tie on sid makes the choice stable, and
# normalising before comparison stops whitespace deciding whether two goals look
# related.
def _norm_cmp(s):
    return re.sub(r"\s+", " ", (s or "")).strip().lower()


texts = {gid: (max(o, key=lambda x: ((x.get("set_at") or ""), (x.get("sid") or ""))).get("text") or "")
         for gid, o in by.items()}
norm = {gid: _norm_cmp(t) for gid, t in texts.items()}


def shared_prefix(a, b):
    n = min(len(a), len(b))
    i = 0
    while i < n and a[i] == b[i]:
        i += 1
    return i


# TWO TESTS, because the shape that actually occurs is not the one a whole-string
# ratio is good at. The real pair on this machine reads identically for its first
# 140 characters and then one of them carries an extra clause; over the full text
# that scores 0.70, which any sane similarity threshold would drop. A first draft
# used 0.85 alone and reported nothing, and the hand-check that "proved" it should
# have fired had compared the 150-character PREVIEWS rather than the goals.
#
# So a long shared opening counts on its own. Two goals that begin the same way
# for 60 characters are about the same work whatever happens at the end, and the
# end is exactly where the difference the reader needs to see lives.
keys = list(texts)
pairs = []
for i, a in enumerate(keys):
    for b in keys[i + 1:]:
        ta, tb = norm[a], norm[b]
        r = difflib.SequenceMatcher(None, ta, tb).ratio()
        pre = shared_prefix(ta, tb)
        if r >= 0.85 or pre >= 60:
            pairs.append((max(r, pre / max(len(ta), len(tb), 1)), r, pre, a, b))
if pairs:
    print()
    print(f"{len(pairs)} near-duplicate pair(s), reported NOT merged: the difference may be the point")
    for _s, r, pre, a, b in sorted(pairs, reverse=True)[:8]:
        # Both detection and display use the NORMALISED text, and the header says
        # so. Showing the raw text instead was tried and is worse: the
        # representative record for a goal may be a variant padded with leading
        # spaces, and a prefix computed on raw strings is then zero, so the
        # "difference" printed is the entire goal. The full original wording is
        # one line up in the list above; this block exists to show the delta.
        print(f"  {a} / {b}   {r:.0%} alike, same for the first {pre} chars (normalised)")
        print(f"    then: {norm[a][pre:pre+60]!r}")
        print(f"    vs:   {norm[b][pre:pre+60]!r}")
PY
    ;;
  *) echo "goal.sh: unknown command $CMD" >&2; sed -n '22,30p' "$0" >&2; exit 2 ;;
esac
