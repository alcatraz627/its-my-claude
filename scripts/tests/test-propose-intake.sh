#!/usr/bin/env bash
# The backlog intake: one open row per need. A repeat filing adds evidence to the
# open row instead of a new proposal, auto-stubs wait for a third sighting, and
# every close carries a real reason. Runs against a scratch store.
set -uo pipefail

P="$HOME/.claude/scripts/propose.sh"
T=$(mktemp -d)
export PROPOSE_STORE="$T/proposals.jsonl" PROPOSE_LOCK="$T/.lock"

pass=0 fail=0
check() {  # $1 name, $2 haystack, $3 needle
  if [[ "$2" == *"$3"* ]]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1"; echo "     want: $3"; echo "     got:  ${2:0:300}"; fi
}
rows() { jq -s 'length' "$PROPOSE_STORE"; }
open_rows() { jq -s '[.[] | select(.status == "open")] | length' "$PROPOSE_STORE"; }

out=$(bash "$P" add --title "Make the reaper respect restarts" --body "b" --category scripts)
check "a new need files a proposal" "$out" "✓ filed prop-"
first=$(jq -r '.id' "$PROPOSE_STORE")

out=$(bash "$P" add --title "make the reaper  respect restarts!" --body "again" --category scripts)
check "the same need again adds evidence to the open row" "$out" "✓ evidence +1 on $first"
check "and files nothing new" "$(rows)" "1"
check "the open row counts its evidence" "$(jq -r '.evidence' "$PROPOSE_STORE")" "2"

bash "$P" add --title "lm self-audit: recurring failure — server_down on qwen3.6:35b-a3b × 14 (last 7d)" \
  --tags "src:lm-self-audit" >/dev/null
out=$(bash "$P" add --title "lm self-audit: recurring failure — server_down on qwen3.6:35b-a3b × 9 (last 7d)" \
  --tags "src:lm-self-audit")
check "a weekly refile with a different count is the same need" "$out" "✓ evidence +1 on prop-"
out=$(bash "$P" add --title "lm self-audit: recurring failure — timeout on gemma4:27b × 6 (last 7d)" --tags "src:lm-self-audit")
check "a different failure is a different need" "$out" "✓ filed prop-"

bash "$P" add --title "Graduate a recurring pattern to a gate (ledger alert: 2026-09)" --tags "ledger auto-filed graduate-to-mechanism" >/dev/null
out=$(bash "$P" add --title "Graduate a recurring pattern to a gate (ledger alert: 2026-10)" --tags "ledger auto-filed graduate-to-mechanism")
check "the monthly ledger alert lands on the open row" "$out" "✓ evidence +1 on prop-"
out=$(bash "$P" add --title "Gate structural claims that name a call chain" --tags "graduate-to-mechanism")
check "a hand-filed gate with the same tag is its own proposal" "$out" "✓ filed prop-"
out=$(bash "$P" add --title "Graduate a recurring pattern to a gate (ledger alert: 2026-09-structural-claim)" --tags "ledger auto-filed graduate-to-mechanism")
check "a ledger alert for a different slug is its own row" "$out" "✓ filed prop-"
check "evidence shows on the open row" "$(bash "$P" show "$first")" "seen 2 times"

# Numbers that name different things stay apart; counts and windows do not.
bash "$P" add --title "Free port 5106 for the hub" >/dev/null
check "port 5107 is a different need from port 5106" "$(bash "$P" add --title "Free port 5107 for the hub")" "✓ filed prop-"
check "a punctuation-only title never merges" "$(bash "$P" add --title '???')$(bash "$P" add --title '!!!')" "✓ filed prop-"

# idream-reader: the cluster is the need, whatever the title says this week.
bash "$P" add --title "AI-smell prose keeps shipping" --tags "src:idream-reader idream-cluster:c-2d84 target:hooks" >/dev/null
check "an idream cluster refiled under a new title is evidence" \
  "$(bash "$P" add --title "AI-smell prose persists past the gate" --tags "src:idream-reader idream-cluster:c-2d84 target:hooks")" "✓ evidence +1 on prop-"

# An open atone proposal for a slug absorbs the stubs for that slug.
bash "$P" add --title "[atone] hook proposal: odd-slug" --tags "link:atone:odd-slug src:atone-graduation" >/dev/null
check "a stub for a slug with an open proposal is evidence on it" \
  "$(bash "$P" add --title "Flesh out gcc friction from session ffff0000 (auto-stub: odd-slug)" --tags "src:auto-stub needs-fleshing link:atone:odd-slug")" "✓ evidence +1 on prop-"
check "tab-separated stub tags are still held" \
  "$(bash "$P" add --title "Flesh out gcc friction (auto-stub: tab-slug)" --tags $'src:auto-stub\tlink:atone:tab-slug')" "held as evidence 1/3"

# hook-feedback files on first sight: its producer never sends a second.
check "a hook-feedback finding files at once" \
  "$(bash "$P" add --title "[hook-feedback] TUNE hook 'x'" --tags "hook-feedback dream-derived")" "✓ filed prop-"

# A broken evidence file must not swallow a stub.
mkdir -p "$T/proposals-evidence.jsonl.d"
out=$(PROPOSE_EVIDENCE="$T/proposals-evidence.jsonl.d" bash "$P" add --title "Flesh out (auto-stub: lost-slug)" --tags "src:auto-stub link:atone:lost-slug" 2>&1)
check "an unwritable evidence file files the stub instead of losing it" "$out" "✓ filed prop-"

stub() { bash "$P" add --title "Flesh out gcc friction from session $1 (auto-stub: bare-id)" --body "(Stub: not yet reviewed.)" \
  --tags "src:auto-stub needs-fleshing link:atone:bare-id" --session "$1"; }
check "a first auto-stub is held as evidence" "$(stub aaaa1111)" "held as evidence 1/3"
check "a second auto-stub is still held" "$(stub bbbb2222)" "held as evidence 2/3"
before=$(rows)
out=$(stub cccc3333)
check "the third sighting files one proposal" "$out" "✓ filed prop-"
check "and only one" "$(rows)" "$((before + 1))"
check "its body lists the sightings" "$(jq -r 'select(.title | test("auto-stub: bare-id")) | .body' "$PROPOSE_STORE")" "aaaa1111"
check "a fourth sighting adds evidence to it" "$(stub dddd4444)" "✓ evidence +1 on prop-"
stubid=$(jq -r 'select(.title | test("auto-stub: bare-id")) | .id' "$PROPOSE_STORE")
bash "$P" retire "$stubid" --as rejected "covered by the bare-id cluster hook" >/dev/null
check "after it closes, sightings start over instead of refiling at once" "$(stub eeee5555)" "held as evidence 1/3"

out=$(bash "$P" add --title "Make the reaper respect restarts" --allow-duplicate)
check "--allow-duplicate files anyway" "$out" "✓ filed prop-"

bash "$P" retire "$first" --as rejected "superseded by the restart fix" >/dev/null
dup=$(jq -r 'select(.title == "Make the reaper respect restarts" and .status == "open") | .id' "$PROPOSE_STORE")
bash "$P" retire "$dup" --as rejected "test cleanup of the forced duplicate" >/dev/null
out=$(bash "$P" add --title "Make the reaper respect restarts" --body "back")
check "a closed row does not swallow a new filing" "$out" "✓ filed prop-"

new=$(jq -r 'select(.status == "open" and .title == "Make the reaper respect restarts") | .id' "$PROPOSE_STORE")
out=$(bash "$P" done "$new" 2>&1)
check "a close with no reason is refused" "$out" "needs a reason"
check "and changes nothing" "$(jq -r "select(.id == \"$new\") | .status" "$PROPOSE_STORE")" "open"
out=$(bash "$P" done "$new" "ok" 2>&1)
check "a two-letter reason is refused" "$out" "needs a reason"
check "a real reason closes it" "$(bash "$P" done "$new" fixed in svc-sample.py)" "→ done"
check "an unquoted reason is kept whole" "$(jq -r "select(.id == \"$new\") | .reason" "$PROPOSE_STORE")" "fixed in svc-sample.py"
other=$(jq -r 'select(.status == "open") | .id' "$PROPOSE_STORE" | head -1)
check "reject refuses an empty reason too" "$(bash "$P" reject "$other" 2>&1)" "needs a reason"

trash "$T" >/dev/null 2>&1
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
