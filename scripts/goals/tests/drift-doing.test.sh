#!/usr/bin/env bash
# drift, doing and import-callouts in a sandbox HOME, each finding induced on
# purpose and then removed to show the view goes quiet (the mutation control).
set -uo pipefail
SRC="$HOME/.claude/scripts/goals"; REAL="$HOME"
SB=$(mktemp -d "${TMPDIR:-/tmp}/drift-home-XXXXXX")
mkdir -p "$SB/.claude/scripts/goals/views" "$SB/repo" "$SB/.claude/tasks/session-aaaaaaaa"
cp -f "$SRC/gs" "$SRC/goalstore.py" "$SRC/render.py" "$SB/.claude/scripts/goals/"
cp -f "$SRC"/views/*.py "$SB/.claude/scripts/goals/views/"
export HOME="$SB"; export CLAUDE_CODE_SESSION_ID="aaaaaaaa-1111-2222-3333-444444444444"
GS="$HOME/.claude/scripts/goals/gs"; V="$HOME/.claude/scripts/goals/views"
trap 'export HOME="$REAL"; trash "$SB" 2>/dev/null || true' EXIT
pass=0; fail=0
ok(){ echo "  ok    $1"; pass=$((pass+1)); }
bad(){ echo "  FAIL  $1"; fail=$((fail+1)); }
git -C "$SB/repo" init -q 2>/dev/null; cd "$SB/repo" || exit 1
py(){ python3 -c "import sys,json;sys.path.insert(0,'$HOME/.claude/scripts/goals');import goalstore as G;$1"; }

"$GS" new "The console shows live job status" --accept "visual: the status pill updates without a refresh" >/dev/null 2>&1
G1=$(py "print(G.goal_id('The console shows live job status'))")
"$GS" milestone "$G1" "LIVE: the socket feed is wired" >/dev/null 2>&1
"$GS" task "$G1" m1 "Wire the socket feed" --lane watcher --tier sonnet >/dev/null 2>&1
"$GS" task "$G1" m1 "Approve the socket vendor" --gate "approve the vendor" --do "reply yes on the decision page" --lane owner >/dev/null 2>&1
"$GS" start "$G1" 1 >/dev/null 2>&1
"$GS" note "$G1" "re-run the socket probe before anything else" >/dev/null 2>&1
cat > "$SB/.claude/tasks/session-aaaaaaaa/1.json" <<'J'
{"id":"1","subject":"An agent-private row","status":"pending","metadata":{}}
J

echo "── drift: a fresh goal ──"
python3 "$V/drift.py" > "$SB/d0.txt" 2>&1
rg -q "📝 1 handoff note" "$SB/d0.txt" && ok "unread note is a finding" || bad "note missing: $(cat "$SB/d0.txt")"
rg -q "1 open agent row\(s\) in session-aaaaaaaa under no goal" "$SB/d0.txt" && ok "agent rows under no goal are named, with adopt as the remedy" || bad "unfiled rows missing"
rg -q "gate untouched" "$SB/d0.txt" && bad "a fresh gate flagged stale" || ok "a fresh gate is not stale"

echo "── drift: induced findings ──"
python3 - "$HOME/.claude/goals/by-id/$G1.json" <<'PY'
import json, sys
p = sys.argv[1]; r = json.load(open(p))
r["updated"] = "2026-09-01T00:00:00Z"
for t in r["tasks"]:
    if t["gate"]: t["updated"] = "2026-09-01T00:00:00Z"
json.dump(r, open(p, "w"))
PY
printf '{"ts":"2026-09-20T10:00:00Z","slug":"vendor-ruling"}\n' > "$SB/answers.jsonl"
printf '{"peers":[{"alias":"gcp-hands","sessionId":"bbbbbbbb-0000","status":"online"}]}' > "$SB/peers.json"
TASKS_RULINGS_JSONL="$SB/answers.jsonl" TASKS_PEERS_JSON="$SB/peers.json" python3 "$V/drift.py" > "$SB/d1.txt" 2>&1
rg -q "⏳ drifting .*idle 2[0-9]d" "$SB/d1.txt" && ok "a goal idle over 14 days is drifting" || bad "drift missing: $(cat "$SB/d1.txt")"
rg -q "🔴 gate untouched .*#2" "$SB/d1.txt" && ok "a gate untouched over a day is flagged" || bad "stale gate missing"
rg -q "gate\(s\) set before your last ruling \(vendor-ruling\)" "$SB/d1.txt" && ok "a gate older than the last decision-page ruling is flagged" || bad "ruling check missing"
rg -q "running in a lane no live session claims: watcher #1" "$SB/d1.txt" && ok "a running row in a lane no live peer claims is an orphan" || bad "orphan lane missing"
head -1 "$SB/d1.txt" | rg -q "^DRIFT  [5-9] finding" && ok "header counts findings" || bad "header: $(head -1 "$SB/d1.txt")"
sev=$(rg -n "🔴|⏳" "$SB/d1.txt" | head -1 | cut -d: -f2); rg -q "🔴" <<< "$sev" && ok "gates (severity 0) sort above drift" || bad "ordering: first finding is $sev"
TASKS_RULINGS_JSONL="$SB/answers.jsonl" TASKS_PEERS_JSON="$SB/peers.json" python3 "$V/drift.py" --json > "$SB/d1.json" 2>&1
python3 -c "import json;j=json.load(open('$SB/d1.json'));k={f['kind'] for f in j['findings']};assert {'drifting','stale-gate','gate-predates-ruling','orphan-lane'}<=k, k" && ok "--json carries every finding kind" || bad "--json kinds wrong"

echo "── drift: built, not accepted ──"
"$GS" ungate "$G1" 2 >/dev/null 2>&1; "$GS" close "$G1" 1 --by true >/dev/null 2>&1; "$GS" close "$G1" 2 --by true >/dev/null 2>&1
python3 "$V/drift.py" > "$SB/d2.txt" 2>&1
rg -q "🟡 built, not accepted" "$SB/d2.txt" && ok "all rows done + acceptance unproven = built, not accepted" || bad "built-not-accepted missing: $(cat "$SB/d2.txt")"
"$GS" prove "$G1" a1 --by "screenshot" >/dev/null 2>&1
python3 "$V/drift.py" > "$SB/d3.txt" 2>&1
rg -q "built, not accepted" "$SB/d3.txt" && bad "MUTATION: proven acceptance still reads built-not-accepted" || ok "MUTATION: proving the row clears the finding"

echo "── doing ──"
"$GS" new "Peers see each other's queues" --accept "functional: x" >/dev/null 2>&1
G2=$(py "print(G.goal_id('Peers see each other queues'.replace('other queues','other\'s queues')))")
"$GS" milestone "$G2" "FEED: the peer feed renders" >/dev/null 2>&1
"$GS" task "$G2" m1 "Render the peer feed" --lane hands --tier sonnet >/dev/null 2>&1
"$GS" task "$G2" m1 "Audit the feed for leaks" --lane hands --tier opus >/dev/null 2>&1
"$GS" task "$G2" m1 "A row nobody holds" >/dev/null 2>&1
"$GS" start "$G2" 1 >/dev/null 2>&1; "$GS" delegate "$G2" 2 --to auditor-seat >/dev/null 2>&1
TASKS_PEERS_JSON="$SB/peers.json" python3 "$V/doing.py" --goal "$G2" > "$SB/do.txt" 2>&1
rg -q "^DOING  1 running, 1 delegated, 0 in review" "$SB/do.txt" && ok "doing header counts" || bad "doing header: $(head -1 "$SB/do.txt")"
rg -q "🔵 ▶ #1 .*Render the peer feed.*◆ hands" "$SB/do.txt" && ok "running row with its lane" || bad "running row missing"
rg -q "🤝 @ #2 .*◆ auditor-se" "$SB/do.txt" && ok "delegated row names the seat" || bad "delegated row missing: $(rg '#2' "$SB/do.txt")"
rg -q "session aaaaaaaa .*tombstone" "$SB/do.txt" && ok "a running row whose session is not live reads as a tombstone" || bad "tombstone missing: $(rg '#1' "$SB/do.txt")"
rg -q "#3" "$SB/do.txt" && bad "a ready row leaked into doing" || ok "ready rows are not 'doing'"
python3 "$V/doing.py" --goal "$G2" > "$SB/do2.txt" 2>&1
rg -q "no ipc broker answered" "$SB/do2.txt" && ok "without a broker, liveness is not claimed" || bad "liveness claimed without an instrument"

echo "── import-callouts ──"
cat > "$SB/callouts.jsonl" <<'J'
{"id":"co-1","ts":"2026-09-20T10:00:00Z","surface":"job-page","words":"the status pill is invisible in dark mode","category":"visual","status":"open","rechecks":[]}
{"id":"co-2","ts":"2026-09-20T10:01:00Z","surface":"job-page","words":"clicking retry double-submits","category":"behavior","status":"retired","rechecks":[{"ts":"x","result":"pass","evidence":"clicked 10x, one request"}]}
{"id":"co-3","ts":"2026-09-20T10:02:00Z","surface":"docs","words":"the README lies about the port","category":"literary","status":"open","rechecks":[]}
J
CALLOUTS_STORE="$SB/callouts.jsonl" "$GS" import-callouts "$G2" --surface job-page > "$SB/ic.txt" 2>&1 && rg -q "imported 2 callout" "$SB/ic.txt" && ok "imports the surface's callouts" || bad "import: $(cat "$SB/ic.txt")"
"$GS" show "$G2" > "$SB/show.txt" 2>&1
rg -q "◻︎ a2 visual: job-page: the status pill is invisible in dark mode" "$SB/show.txt" && ok "open visual callout → unproven visual acceptance" || bad "a2 wrong: $(rg a2 "$SB/show.txt")"
rg -q "✅ a3 functional: job-page: clicking retry double-submits  · by callout co-2 retired by owner" "$SB/show.txt" && ok "retired callout with a pass recheck → proven functional acceptance" || bad "a3 wrong: $(rg a3 "$SB/show.txt")"
if CALLOUTS_STORE="$SB/callouts.jsonl" "$GS" import-callouts "$G2" --surface job-page >/dev/null 2>&1; then bad "re-import duplicated rows"; else ok "re-import refuses: nothing new" ; fi
n=$(py "print(len(G.load('$G2')['accept']))"); [ "$n" = 3 ] && ok "three acceptance rows, no duplicates" || bad "$n acceptance rows"

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
