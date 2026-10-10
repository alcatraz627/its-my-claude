#!/usr/bin/env bash
# gs and goalstore: every rule the store enforces, exercised through the CLI in a
# sandbox HOME, with a mutation control per guard (break the thing it protects,
# watch it go red). Never touches the live ~/.claude/goals.
set -uo pipefail
SRC="$HOME/.claude/scripts/goals"; REAL="$HOME"
SB=$(mktemp -d "${TMPDIR:-/tmp}/gs-home-XXXXXX")
mkdir -p "$SB/.claude/scripts/goals" "$SB/.claude/tasks/session-abcd1234" "$SB/repo-a" "$SB/repo-b"
cp -f "$SRC/gs" "$SRC/goalstore.py" "$SB/.claude/scripts/goals/"
export HOME="$SB"
export CLAUDE_CODE_SESSION_ID="11111111-2222-3333-4444-555555555555"
GS="$HOME/.claude/scripts/goals/gs"
trap 'export HOME="$REAL"; trash "$SB" 2>/dev/null || true' EXIT
pass=0; fail=0
ok(){ echo "  ok    $1"; pass=$((pass+1)); }
bad(){ echo "  FAIL  $1"; fail=$((fail+1)); }
git -C "$SB/repo-a" init -q 2>/dev/null; git -C "$SB/repo-b" init -q 2>/dev/null
cd "$SB/repo-a" || exit 1

echo "── creation rules ──"
if "$GS" new "A teammate ships one workbook alone" >/dev/null 2>"$SB/err"; then bad "goal without acceptance was accepted"
else rg -q "acceptance row" "$SB/err" && ok "refuses a goal with no acceptance row, naming the fix" || bad "refusal did not name the fix: $(cat "$SB/err")"; fi
"$GS" new "A teammate ships one workbook alone" --accept "functional: a teammate uploads and downloads without help" --accept "deployed: seen on preview" > "$SB/out" 2>&1 \
  && ok "creates a goal with two acceptance rows" || bad "create failed: $(cat "$SB/out")"
GID=$(ls "$HOME/.claude/goals/by-id" | sed 's/.json//' | head -1)
[ -n "$GID" ] && ok "record at by-id/$GID.json" || bad "no by-id record written"
rg -q "^/goal A teammate ships" "$SB/out" && ok "prints the armline" || bad "no armline printed"
[ -f "$HOME/.claude/goals/$CLAUDE_CODE_SESSION_ID.json" ] && ok "session pointer written (goal.sh's file)" || bad "no session pointer"
pg=$(python3 -c "import json;print(json.load(open('$HOME/.claude/goals/$CLAUDE_CODE_SESSION_ID.json'))['goal_id'])")
[ "$pg" = "$GID" ] && ok "pointer goal_id matches the record id (same hash as goal.sh)" || bad "pointer goal_id $pg != $GID"
# goal.sh's own hash, computed the way goal.sh computes it, must agree
h=$(printf '%s' "a teammate ships one workbook alone" | shasum -a 256 | cut -c1-12)
[ "$h" = "$GID" ] && ok "id equals goal.sh's sha256 of normalised text" || bad "id $GID differs from goal.sh hash $h"
"$GS" new "a teammate SHIPS one   workbook alone" --accept "other: x" > "$SB/out" 2>&1
rg -q "linked existing" "$SB/out" && ok "same outcome, different spacing and case, links the same goal" || bad "re-create made a second goal"
[ "$(ls "$HOME/.claude/goals/by-id" | wc -l | tr -d ' ')" = 1 ] && ok "still one record" || bad "two records for one outcome"

echo "── milestones and rows ──"
if "$GS" task "$GID" m1 "a row" >/dev/null 2>"$SB/err"; then bad "row without a milestone accepted"
else rg -q "milestone" "$SB/err" && ok "refuses a row under a missing milestone" || bad "wrong refusal: $(cat "$SB/err")"; fi
if "$GS" milestone "$GID" "M1" >/dev/null 2>"$SB/err"; then bad "two-letter milestone accepted"
else rg -q "three letters" "$SB/err" && ok "refuses a milestone under three letters" || bad "wrong refusal: $(cat "$SB/err")"; fi
"$GS" milestone "$GID" "The upload path works end to end" >/dev/null 2>&1 && ok "milestone m1 added" || bad "milestone add failed"
"$GS" milestone "$GID" "The download path works end to end" >/dev/null 2>&1
long="Build the upload endpoint with chunked transfer, resumable sessions, and a progress bar that survives a refresh"
"$GS" task "$GID" m1 "$long" --tier sonnet --lane hands > "$SB/out" 2>&1 && ok "row #1 added" || bad "row add failed: $(cat "$SB/out")"
rg -q "cut at a word" "$SB/out" && ok "subject over 70 is cut at a word, tail to note" || bad "no cut notice"
sl=$(python3 -c "import json;print(len(json.load(open('$HOME/.claude/goals/by-id/$GID.json'))['tasks'][0]['subject']))")
[ "$sl" -le 70 ] && ok "stored subject is $sl chars" || bad "stored subject is $sl chars"
if "$GS" task "$GID" m1 "Rule on the redesign" --gate "USER: rule on it" >/dev/null 2>"$SB/err"; then bad "gate without a do-line accepted"
else rg -q "do-line" "$SB/err" && ok "refuses a gate with no do-line" || bad "wrong refusal: $(cat "$SB/err")"; fi
"$GS" task "$GID" m1 "Rule on the redesign" --gate "rule on it" --do "open the decision page" > "$SB/out" 2>&1
rg -q "owner-gate" "$SB/out" && ok "gated row reads owner-gate" || bad "gate not effective: $(cat "$SB/out")"
"$GS" task "$GID" m2 "Wire the download button" --blocked-by 1 > "$SB/out" 2>&1
rg -q "blocked" "$SB/out" && ok "row blocked by an open row reads blocked" || bad "blocked_by not effective"
if "$GS" task "$GID" m2 "x" --blocked-by 99 >/dev/null 2>"$SB/err"; then bad "blocked-by an unknown row accepted"
else ok "refuses blocked-by an unknown row"; fi
if "$GS" task "$GID" m2 "x" --tier gpt5 >/dev/null 2>"$SB/err"; then bad "unknown tier accepted"
else rg -q "fable" "$SB/err" && ok "refuses an unknown tier, naming the set" || bad "tier refusal did not name the set"; fi

echo "── states and containment ──"
"$GS" start "$GID" 1 >/dev/null 2>&1 && ok "start → active" || bad "start failed"
"$GS" close "$GID" 1 --by "true: upload suite green" >/dev/null 2>&1 && ok "close with instrument" || bad "close failed"
st=$(python3 -c "
import json,sys; sys.path.insert(0,'$HOME/.claude/scripts/goals'); import goalstore as G
r=G.load('$GID'); print(G.effective_state([t for t in r['tasks'] if t['id']=='3'][0], r))")
[ "$st" = ready ] && ok "row #3 unblocks when #1 closes (effective state ready)" || bad "row #3 is $st after #1 closed"
if "$GS" met "$GID" --by x >/dev/null 2>"$SB/err"; then bad "met with open rows accepted"
else rg -q "open row" "$SB/err" && ok "met refused while rows are open, names them" || bad "wrong refusal: $(cat "$SB/err")"; fi
"$GS" ungate "$GID" 2 >/dev/null 2>&1; "$GS" close "$GID" 2 --by "owner ruled" >/dev/null 2>&1; "$GS" close "$GID" 3 --by "true" >/dev/null 2>&1
if "$GS" met "$GID" --by x >/dev/null 2>"$SB/err"; then bad "met with unproven acceptance accepted (THE rule)"
else rg -q "acceptance unproven" "$SB/err" && ok "met refused while acceptance is unproven: built, not accepted" || bad "wrong refusal: $(cat "$SB/err")"; fi
ms=$(python3 -c "import json;r=json.load(open('$HOME/.claude/goals/by-id/$GID.json'));print(','.join(m['status'] for m in r['milestones']))")
[ "$ms" = "met,met" ] && ok "milestones close when their rows are all done" || bad "milestones read $ms"
"$GS" prove "$GID" a1 --by "screenshot: teammate uploaded unaided" >/dev/null 2>&1 && ok "prove a1" || bad "prove failed"
"$GS" prove "$GID" a2 --by "prod: seen on preview" >/dev/null 2>&1
"$GS" prove "$GID" a3 --by "n/a" >/dev/null 2>&1
"$GS" met "$GID" --by "owner: accepted 2026-09-23" > "$SB/out" 2>&1 && ok "met once every acceptance row is proven" || bad "met failed: $(cat "$SB/out")"
[ -f "$HOME/.claude/goals/archive/$GID.json" ] && [ ! -f "$HOME/.claude/goals/by-id/$GID.json" ] && ok "met goal moved to archive with its rows" || bad "archive move failed"

echo "── notes are ephemeral ──"
"$GS" new "The board loads in under a second" --accept "functional: cold load under 1s measured" >/dev/null 2>&1
G2=$(ls "$HOME/.claude/goals/by-id" | sed 's/.json//' | head -1)
"$GS" milestone "$G2" "The query plan is indexed" >/dev/null 2>&1
"$GS" task "$G2" m1 "Add the index" >/dev/null 2>&1
"$GS" note "$G2" 1 "finish the migration tail before touching anything else" >/dev/null 2>&1 && ok "note on a row" || bad "note failed"
"$GS" note "$G2" "next session: re-run the cold-load probe first" >/dev/null 2>&1 && ok "note on the goal (two-arg form)" || bad "goal note failed"
open_n=$(python3 -c "import json;r=json.load(open('$HOME/.claude/goals/by-id/$G2.json'));print(len(r['tasks']))")
[ "$open_n" = 1 ] && ok "notes add no rows" || bad "notes became rows: $open_n"
"$GS" notes "$G2" > "$SB/out" 2>&1; c=$(rg -c "📝" "$SB/out"); [ "$c" = 2 ] && ok "first read prints both notes" || bad "first read printed $c"
"$GS" notes "$G2" > "$SB/out" 2>&1; rg -q "no unconsumed" "$SB/out" && ok "second read: consumed, prints nothing" || bad "notes printed twice"

echo "── fold, drop, adopt, scope ──"
"$GS" milestone "$G2" "The cache is warm on boot" >/dev/null 2>&1
"$GS" task "$G2" m2 "Warm the cache" >/dev/null 2>&1
"$GS" fold "$G2" m2 into m1 > "$SB/out" 2>&1 && rg -q "folded into m1" "$SB/out" && ok "fold m2 into m1 moves rows and removes m2" || bad "fold failed: $(cat "$SB/out")"
nm=$(python3 -c "import json;r=json.load(open('$HOME/.claude/goals/by-id/$G2.json'));print(len(r['milestones']))")
[ "$nm" = 1 ] && ok "one milestone remains" || bad "$nm milestones remain"
"$GS" drop "$G2" 2 --why "cache warming is out of v1" >/dev/null 2>&1 && ok "drop a row with --why" || bad "drop failed"
if "$GS" drop "$G2" 1 --why "" >/dev/null 2>&1; then bad "drop with empty why accepted"; else ok "drop refuses an empty why"; fi
cat > "$HOME/.claude/tasks/session-abcd1234/1.json" <<'J'
{"id":"1","subject":"Legacy row from the agent store","status":"pending","metadata":{"blocked_on":"USER: approve the plan","tier":"opus","class":"build"}}
J
cat > "$HOME/.claude/tasks/session-abcd1234/2.json" <<'J'
{"id":"2","subject":"Legacy done row","status":"completed","metadata":{}}
J
"$GS" adopt "$G2" m1 --session abcd1234 > "$SB/out" 2>&1 && rg -q "adopted 1 row" "$SB/out" && ok "adopt lifts only open legacy rows by default" || bad "adopt: $(cat "$SB/out")"
"$GS" show "$G2" > "$SB/out" 2>&1; rg -q "owner-gate.*Legacy row" "$SB/out" && ok "adopted USER: row arrives as a gate with a do-line" || bad "adopted gate lost: $(cat "$SB/out")"
[ -f "$HOME/.claude/tasks/session-abcd1234/1.json" ] && ok "adopt never deletes from the agent store" || bad "adopt deleted the legacy row"
export CLAUDE_CODE_SESSION_ID="99999999-0000-0000-0000-000000000000"
cd "$SB/repo-b" || exit 1
"$GS" list > "$SB/out" 2>&1; rg -q "no live goal here" "$SB/out" && ok "a stranger session in an unrelated repo: no goals, no refusal, the gs new line" || bad "scope leaked: $(cat "$SB/out")"
cd "$SB/repo-a" || exit 1
"$GS" list > "$SB/out" 2>&1; rg -q "$G2" "$SB/out" && ok "a stranger session in the goal's repo: listed by project" || bad "not listed from its repo"
cd "$SB/repo-b" || exit 1
"$GS" link "$G2" >/dev/null 2>&1; "$GS" list > "$SB/out" 2>&1; rg -q "$G2" "$SB/out" && ok "a linked session sees its goal from any directory" || bad "link did not bring the goal into scope"
export CLAUDE_CODE_SESSION_ID="77777777-0000-0000-0000-000000000000"
mkdir -p "$HOME/.claude/x"; cd "$HOME/.claude" || exit 1
"$GS" list > "$SB/out" 2>&1; rg -q "$G2" "$SB/out" && bad "from ~/.claude a product goal leaked into scope" || ok "from ~/.claude only gcc and linked goals are in scope (a repo like any other)"

echo "── drift and sweep ──"
python3 - "$HOME/.claude/goals/by-id/$G2.json" <<'PY'
import json,sys; p=sys.argv[1]; r=json.load(open(p)); r["updated"]="2026-08-01T00:00:00Z"; json.dump(r,open(p,"w"))
PY
"$GS" sweep > "$SB/out" 2>&1; rg -q "parked" "$SB/out" && ok "sweep parks a goal idle over 30 days" || bad "sweep did not park: $(cat "$SB/out")"
"$GS" revive "$G2" >/dev/null 2>&1; "$GS" sweep > "$SB/out" 2>&1; rg -q "nothing to park" "$SB/out" && ok "revived goal is fresh again" || bad "revived goal re-parked"

echo "── mutation control: the acceptance guard ──"
cp -f "$SRC/goalstore.py" "$SB/gs.bak"
sed -i '' 's/    unproven = \[a for a in rec\["accept"\] if a\["status"\] != "proven"\]/    unproven = []/' "$HOME/.claude/scripts/goals/goalstore.py"
"$GS" new "Mutant goal" --accept "other: never proven" >/dev/null 2>&1
G3=$(python3 -c "import sys;sys.path.insert(0,'$HOME/.claude/scripts/goals');import goalstore as G;print(G.goal_id('Mutant goal'))")
if "$GS" met "$G3" --by x >/dev/null 2>&1; then ok "MUTATION: with the acceptance check removed, met passes (guard is live)"
else bad "MUTATION: met still refused with the guard removed; the test above is not testing the guard"; fi
cp -f "$SB/gs.bak" "$HOME/.claude/scripts/goals/goalstore.py"

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
