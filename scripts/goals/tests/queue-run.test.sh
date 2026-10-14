#!/usr/bin/env bash
# queue-run: every rule the runner keeps (order, gate-first, the per-row budget,
# park with a reason, one retry, what counts as ready, the owner's list, on/off),
# exercised through the CLI in a sandbox HOME. Then each guard is broken on a
# scratch copy and the check that pins it must go red. Never touches ~/.claude/goals.
set -uo pipefail
SRC="$HOME/.claude/scripts/goals"; REAL="$HOME"
SB=$(mktemp -d "${TMPDIR:-/tmp}/qrun-home-XXXXXX")
mkdir -p "$SB/.claude/scripts/goals" "$SB/.claude/scripts/session-mgmt" "$SB/repo"
cp -f "$SRC/gs" "$SRC/goalstore.py" "$SRC/queue_run.py" "$SRC/queue-run.sh" "$SB/.claude/scripts/goals/"
cp -f "$REAL/.claude/scripts/session-mgmt/compact-gate.sh" "$SB/.claude/scripts/session-mgmt/"
export HOME="$SB"
export CLAUDE_CODE_SESSION_ID="aaaaaaaa-2222-3333-4444-555555555555"
export COMPACT_GATE_DIR="$SB/compact" COMPACT_GATE_LOG="$SB/compact.jsonl"
GS="$HOME/.claude/scripts/goals/gs"
GOALS="$HOME/.claude/goals"
trap 'export HOME="$REAL"; trash "$SB" 2>/dev/null || true' EXIT
git -C "$SB/repo" init -q 2>/dev/null
cd "$SB/repo" || exit 1
pass=0; fail=0
ok(){ echo "  ok    $1"; pass=$((pass+1)); }
bad(){ echo "  FAIL  $1"; fail=$((fail+1)); }

# fresh: an empty store with one linked goal, m1 holding #1 alpha and #2 beta, m2 holding #3 gamma.
fresh() {
  [ -d "$GOALS" ] && trash "$GOALS"
  [ -d "$COMPACT_GATE_DIR" ] && trash "$COMPACT_GATE_DIR"
  "$GS" new "The queue runner works its rows" --accept "functional: the suite passes" --accept "reviewed: the owner reads the page" >/dev/null 2>&1
  GID=$(ls "$GOALS/by-id" | sed 's/.json//' | head -1)
  "$GS" link "$GID" >/dev/null 2>&1
  "$GS" milestone "$GID" "The first milestone holds" >/dev/null 2>&1
  "$GS" milestone "$GID" "The second milestone holds" >/dev/null 2>&1
  "$GS" task "$GID" m1 "alpha" >/dev/null 2>&1
  "$GS" task "$GID" m1 "beta" >/dev/null 2>&1
  "$GS" task "$GID" m2 "gamma" >/dev/null 2>&1
}
state_of(){ python3 -c "import json,sys;r=json.load(open(sys.argv[1]));print(next(t['state'] for t in r['tasks'] if t['id']==sys.argv[2]))" "$GOALS/by-id/$GID.json" "$1"; }
# backdate: move the newest start/retry of the ledger back N minutes
backdate(){ python3 - "$GOALS/runs/$GID.jsonl" "$1" <<'PY'
import json, sys, time
p, mins = sys.argv[1], int(sys.argv[2])
rows = [json.loads(l) for l in open(p)]
i = max(k for k, r in enumerate(rows) if r["ev"] in ("start", "retry"))
rows[i]["ts"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(time.time() - mins * 60))
open(p, "w").write("".join(json.dumps(r) + "\n" for r in rows))
PY
}

# Each check takes the runner to use, prints nothing, returns 0 on pass.
c_order(){ local Q="$1"; fresh
  [ "$(bash "$Q" next | head -1 | cut -d' ' -f1)" = "#1" ] && [ "$(state_of 1)" = active ]; }
c_gate_first(){ local Q="$1"; fresh
  "$GS" task "$GID" m2 "unblocker" >/dev/null 2>&1
  "$GS" task "$GID" m2 "needs the owner" --gate "rule on it" --do "pick option A" --blocked-by 4 >/dev/null 2>&1
  [ "$(bash "$Q" next | head -1 | cut -d' ' -f1)" = "#4" ]; }
c_budget_attempts(){ local Q="$1"; fresh
  bash "$Q" next >/dev/null; bash "$Q" next >/dev/null; bash "$Q" next >"$SB/out" 2>&1; local rc=$?
  [ $rc -eq 4 ] && rg -q "budget spent on #1" "$SB/out" && rg -q "queue-run.sh park 1" "$SB/out"; }
c_attempt_two_allowed(){ local Q="$1"; fresh
  bash "$Q" next >/dev/null; bash "$Q" next >"$SB/out" 2>&1; local rc=$?
  [ $rc -eq 0 ] && rg -q "attempt 2 of 2" "$SB/out"; }
c_budget_minutes(){ local Q="$1"; fresh
  bash "$Q" next >/dev/null; backdate 31; bash "$Q" next >/dev/null 2>&1; [ $? -eq 4 ]; }
c_park(){ local Q="$1"; fresh
  bash "$Q" next >/dev/null
  bash "$Q" park 1 >/dev/null 2>&1 && return 1
  bash "$Q" park 1 --why "" >/dev/null 2>&1 && return 1
  bash "$Q" park 1 --why "fixture flakes; evidence /x/report.md" >"$SB/out" 2>&1 || return 1
  [ "$(state_of 1)" = deferred ] || return 1
  rg -q "evidence /x/report.md" "$GOALS/by-id/$GID.json" || return 1
  rg -q '"ev": "park"' "$GOALS/runs/$GID.jsonl" || return 1
  rg -q "^next: #2 beta" "$SB/out" || return 1
  [ "$(bash "$Q" next | head -1 | cut -d' ' -f1)" = "#2" ]; }
c_retry_once(){ local Q="$1"; fresh
  "$GS" drop "$GID" 2 --why "fixture" >/dev/null 2>&1; "$GS" drop "$GID" 3 --why "fixture" >/dev/null 2>&1
  bash "$Q" next >/dev/null; bash "$Q" park 1 --why "first park" >/dev/null
  bash "$Q" next >"$SB/out" 2>&1 || return 1
  rg -q "^#1 alpha.*second pass" "$SB/out" || return 1
  bash "$Q" park 1 --why "second park" >/dev/null
  bash "$Q" next >/dev/null 2>&1; [ $? -eq 1 ] || return 1
  bash "$Q" ready >/dev/null 2>&1; [ $? -eq 1 ]; }
c_ready_set(){ local Q="$1"; fresh
  "$GS" task "$GID" m2 "gated" --gate "rule" --do "say yes" >/dev/null 2>&1      # 4: owner-gated
  "$GS" task "$GID" m2 "behind beta" --blocked-by 2 >/dev/null 2>&1              # 5: blocked
  "$GS" defer "$GID" 3 >/dev/null 2>&1                                            # 3: deferred by hand
  "$GS" close "$GID" 1 --by "true: fixture" >/dev/null 2>&1                       # 1: done
  local got; got=$(bash "$Q" ready | cut -d' ' -f1 | tr '\n' ' ')
  [ "$got" = "#2 " ] || return 1
  "$GS" close "$GID" 2 --by "true: fixture" >/dev/null 2>&1
  got=$(bash "$Q" ready | cut -d' ' -f1 | tr '\n' ' ')
  [ "$got" = "#5 " ] || return 1
  "$GS" close "$GID" 5 --by "true: fixture" >/dev/null 2>&1
  bash "$Q" ready >/dev/null 2>&1; [ $? -eq 1 ]; }
c_in_hand_first(){ local Q="$1"; fresh
  bash "$Q" next >/dev/null
  # a gate filed after the pick puts #2 first in work order; the row in hand still leads
  "$GS" task "$GID" m2 "needs the owner" --gate "rule" --do "say yes" --blocked-by 2 >/dev/null 2>&1
  [ "$(bash "$Q" ready | head -1 | cut -d' ' -f1)" = "#1" ]; }
c_gates(){ local Q="$1"; fresh
  "$GS" task "$GID" m2 "gated" --gate "rule on the layout" --do "take layout B" >/dev/null 2>&1
  bash "$Q" next >/dev/null; bash "$Q" park 1 --why "needs a live browser" >/dev/null
  bash "$Q" gates >"$SB/out" 2>&1 || return 1
  rg -q "gated   #4 gated: USER: rule on the layout  » draft: take layout B" "$SB/out" || return 1
  rg -q "accept  a2 reviewed: the owner reads the page" "$SB/out" || return 1
  rg -q "the suite passes" "$SB/out" && return 1
  rg -q "parked  #1 alpha: needs a live browser" "$SB/out" || return 1
  bash "$Q" gates --json | python3 -c "import json,sys;j=json.load(sys.stdin);assert [g['id'] for g in j['gated']]==['4'] and j['parked'][0]['why']=='needs a live browser'"; }
c_gates_keep_every_reason(){ local Q="$1"; fresh
  bash "$Q" next >/dev/null; bash "$Q" park 1 --why "first: evidence /x/a.log" >/dev/null
  bash "$Q" next >/dev/null; bash "$Q" park 1 --why "second: backstop" >/dev/null
  bash "$Q" gates | rg -q "parked  #1 alpha: first: evidence /x/a.log · then: second: backstop"; }
c_on_off(){ local Q="$1"; fresh
  local act="$GOALS/runs/active/$CLAUDE_CODE_SESSION_ID.json"
  [ "$(bash "$HOME/.claude/scripts/session-mgmt/compact-gate.sh" status)" = refused ] || return 1
  bash "$Q" on >/dev/null 2>&1 || return 1
  [ -f "$act" ] || return 1
  [ "$(bash "$HOME/.claude/scripts/session-mgmt/compact-gate.sh" status)" = allowed ] || return 1
  bash "$Q" status | rg -q "drive on since" || return 1
  bash "$Q" off >/dev/null 2>&1 || return 1
  [ ! -f "$act" ] || return 1
  [ "$(bash "$HOME/.claude/scripts/session-mgmt/compact-gate.sh" status)" = refused ]; }
c_no_goal(){ local Q="$1"; fresh
  trash "$GOALS/$CLAUDE_CODE_SESSION_ID.json"
  bash "$Q" next >"$SB/out" 2>&1; [ $? -eq 2 ] || return 1
  rg -q "no goal" "$SB/out" || return 1
  [ "$(bash "$Q" next --goal "$GID" | head -1 | cut -d' ' -f1)" = "#1" ]; }

Q="$HOME/.claude/scripts/goals/queue-run.sh"
CHECKS="c_order c_gate_first c_budget_attempts c_attempt_two_allowed c_budget_minutes c_park c_retry_once c_ready_set c_in_hand_first c_gates c_gates_keep_every_reason c_on_off c_no_goal"
echo "── the runner ──"
for c in $CHECKS; do $c "$Q" >/dev/null 2>&1 && ok "$c" || bad "$c"; done

# mutate <check> <old> <new> <label>: break one guard on a scratch copy; its check must go red.
mutate(){
  local check="$1" old="$2" new="$3" label="$4" M="$SB/mut"
  mkdir -p "$M"; cp -f "$SB/.claude/scripts/goals/goalstore.py" "$M/"
  printf '#!/usr/bin/env bash\nexec python3 "$(dirname "$0")/queue_run.py" "$@"\n' > "$M/queue-run.sh"
  python3 - "$SB/.claude/scripts/goals/queue_run.py" "$M/queue_run.py" "$old" "$new" <<'PY' || { bad "mutation $label: pattern not found"; return; }
import sys
src, dst, old, new = sys.argv[1:5]
s = open(src).read()
if old not in s: sys.exit(1)
open(dst, "w").write(s.replace(old, new, 1))
PY
  if $check "$M/queue-run.sh" >/dev/null 2>&1; then bad "mutation $label stayed green ($check)"; else ok "mutation $label goes red ($check)"; fi
}
echo "── each guard, broken alone ──"
mutate c_budget_attempts 'hand["attempts"] >= BUDGET_ATTEMPTS or ' '' "attempt budget"
mutate c_attempt_two_allowed 'hand["attempts"] >= BUDGET_ATTEMPTS' 'hand["attempts"] >= 1' "budget off by one"
mutate c_budget_minutes ' or hand["minutes"] >= BUDGET_MINUTES' '' "minute budget"
mutate c_gate_first 'rows.sort(key=lambda t: 0 if t["id"] in unblocks else 1)' 'pass' "gate-first order"
mutate c_order 'rows.sort(key=lambda t: (order.get(t["milestone"], 99), int(t["id"])))' 'rows.reverse()' "milestone order"
mutate c_retry_once 'if len(p) == 1 and not r' 'if len(p) >= 1' "one retry only"
mutate c_park 'if not (a.why or "").strip(): die(' 'if False: die(' "park needs a reason"
mutate c_ready_set 'in ("ready", "active")]' 'not in ("done",)]' "ready excludes gated, blocked, parked"
mutate c_in_hand_first 'rows = [hand["task"]] + [t for t in rows if t["id"] != hand["task"]["id"]]' 'pass' "row in hand listed first"
mutate c_gates 'and x["kind"] in OWNER_CHECKED' '' "owner-checked acceptance only"
mutate c_gates_keep_every_reason '" · then: ".join(e["why"] for e in p)' 'p[-1]["why"]' "every park reason kept"
mutate c_on_off 'if d.get("compact_gate_was") == "refused"' 'if False' "off restores the compaction gate"

echo "---- pass=$pass fail=$fail"; [ "$fail" -eq 0 ]
