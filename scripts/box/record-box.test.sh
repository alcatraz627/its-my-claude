#!/usr/bin/env bash
# record-box.test.sh: each record kind draws its rows from the stored record,
# with the show command bare under the box, and an unknown id fails.
set -uo pipefail
R="$(cd "$(dirname "$0")" && pwd)/record-box.py"
T=$(mktemp -d)
pass=0 fail=0
ok() { if [ "$2" = "$3" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); printf '  FAIL: %s: got [%s] want [%s]\n' "$1" "$2" "$3"; fi; }
mkdir -p "$T/atone" "$T/affirm" "$T/pinned"
cat > "$T/atone/events.jsonl" <<'EOF'
{"id":"mist-1","slug":"s-one","title":"Did the slip","severity":"S2","juror_verdict":"very-wrong","judgment_id":"judg-1","rca_id":null}
{"id":"mist-0","slug":"s-one","title":"Earlier","severity":"S1"}
EOF
cat > "$T/atone/judgments.jsonl" <<'EOF'
{"id":"judg-1","agent_defense":"It looked fine. More words.","verdict":"very-wrong","confidence":"high","reasoning":"Skipped the check. Later.","should_have_done":"Run the check first. Then more."}
{"id":"judg-2","user_callout":"why did you push","agent_defense":"The nonce covered it.","verdict":"reasonably-right","confidence":"medium","reasoning":"The approval named it.","outcome":"pending","related_atone_slugs":["s-two"],"verdict_path":"/abs/v.json"}
EOF
echo '{"id":"aff-1","slug":"a-one","title":"Good call","why_good":"Saved a round trip.","instruction":"Do it again."}' > "$T/affirm/events.jsonl"
echo '{"id":"prop-1","title":"Add a thing","category":"hooks","effort":"small","tags":["link:prop:prop-0"]}' > "$T/proposals.jsonl"
echo '{"id":"pin-1","text":"Fix the generator. Not the copy.","framing":"graduate","context":{"files":[{"path":"/a/b/hooks.rs"}]}}' > "$T/pinned/events.jsonl"
run() { env RECORD_BOX_ROOT="$T" python3 "$R" "$1" 2>&1; }

a=$(run mist-1)
ok "atone title carries the recurrence" "$(printf '%s\n' "$a" | head -1 | rg -c 'atone · s-one ×2')" "1"
ok "atone attr is severity and verdict" "$(printf '%s\n' "$a" | head -1 | rg -c 'S2 · very-wrong ──$')" "1"
ok "slip row" "$(printf '%s\n' "$a" | rg -c '🔴 slip +Did the slip$')" "1"
ok "defense row is the first sentence" "$(printf '%s\n' "$a" | rg -c '🔵 defense +It looked fine\.$')" "1"
ok "juror row names verdict and confidence" "$(printf '%s\n' "$a" | rg -c '🟣 juror +very-wrong, high: Skipped the check\.$')" "1"
ok "fix row comes from should_have_done" "$(printf '%s\n' "$a" | rg -c '➡️ fix +Run the check first\.$')" "1"
ok "show command sits bare under the box" "$(printf '%s\n' "$a" | tail -1)" "bash ~/.claude/scripts/atone.sh show mist-1"

c=$(run judg-2)
ok "a cleared judgment says so" "$(printf '%s\n' "$c" | head -1 | rg -c 'atone · s-two .*juror cleared you')" "1"
ok "cleared box offers the overrule" "$(printf '%s\n' "$c" | rg -c '🟠 you')" "1"
ok "cleared box links the verdict file" "$(printf '%s\n' "$c" | tail -1)" "/abs/v.json"

ok "affirm rows" "$(run aff-1 | rg -c '🟢 call +Good call$|🔵 why +Saved a round trip\.$|➡️ use +Do it again\.$')" "3"
ok "proposal what row and attr" "$(run prop-1 | rg -c '➡️ what +Add a thing$|hooks · small ──$')" "2"
ok "pin files row uses basenames" "$(run pin-1 | rg -c '🔗 files +hooks\.rs$')" "1"
run mist-9 >/dev/null; ok "a missing id fails" "$?" "1"
run zzz-1 >/dev/null; ok "an unknown id shape fails" "$?" "1"

trash "$T" 2>/dev/null || true
printf -- '---\npass=%s fail=%s\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
