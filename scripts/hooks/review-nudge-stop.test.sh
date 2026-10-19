#!/usr/bin/env bash
# Tests for review-nudge-stop.sh and the review-marker.sh fix it depends on: a
# substantial unreviewed change warns once, a review marker written with ANY form of
# the session id silences it (and records the heed), small or non-code or test-only
# changes stay quiet, and the pre-edit snapshot decides what "added" means.
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
MARKER="${REVIEW_MARKER_SH:-$HOME/.claude/scripts/review-marker.sh}"
T=$(mktemp -d)
export WARN_LOG_STORE="$T/warn.jsonl"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
if [ -f "$HOME/.claude/.no-review-nudge-gate" ]; then echo "mute file present, test would pass vacuously"; exit 2; fi

mkdir -p "$T/proj/src"
cd "$T/proj" || exit 2   # not a git repo, so the marker sees only the edit tracker

fresh() { # fresh <sid8>: drop every /tmp artifact of a test session
  rm -rf "/tmp/claude-edited-files-$1" "/tmp/claude-review-done-$1" "/tmp/claude-review-nudge-$1" "/tmp/claude-review-nudge-$1.seen" "/tmp/claude-presnap-$1" "/tmp/claude-review-done-$1.tmp"
  : > "$WARN_LOG_STORE"
}
lines() { awk -v n="$2" 'BEGIN{for(i=1;i<=n;i++) print "x" i " = " i}' > "$1"; }
track() { printf '%s\n' "$2" >> "/tmp/claude-edited-files-$1"; }
stop() { jq -nc --arg s "$1" '{session_id:$s, stop_hook_active:false}' | REVIEW_MARKER_SH="$MARKER" bash "$D/review-nudge-stop.sh" 2>/dev/null; }
warns() { printf '%s' "$1" | jq -e '.systemMessage | test("review-nudge")' >/dev/null 2>&1; }
heeds() { jq -r --arg v "$1" 'select(.kind=="heed" and .hook_id=="review-nudge" and .heeded==$v) | .id' "$WARN_LOG_STORE" | wc -l | tr -d ' '; }

SID="rnudge01-1111-2222-3333-444444444444"; S8="rnudge01"

# 1. nothing tracked
fresh $S8
out=$(stop "$SID"); [ -z "$out" ] && ok "no edits this session: silent" || bad "no edits this session: silent"

# 2. a substantial new file warns
fresh $S8; lines src/a.py 80; track $S8 "$T/proj/src/a.py"
out=$(stop "$SID"); warns "$out" && ok "80 added lines in an unreviewed code file warns" || bad "80 added lines in an unreviewed code file warns: $out"
printf '%s' "$out" | jq -e 'has("decision") | not' >/dev/null 2>&1 && ok "it only warns, never blocks" || bad "it only warns, never blocks"

# 3. the same set stays quiet and is scored once as not heeded
out=$(stop "$SID"); [ -z "$out" ] && ok "the same set at the next Stop is silent" || bad "the same set at the next Stop is silent"
stop "$SID" >/dev/null
[ "$(heeds false)" = 1 ] && ok "a still-unreviewed set is scored heeded:false exactly once" || bad "a still-unreviewed set is scored heeded:false exactly once ($(heeds false))"

# 4. small change
fresh $S8; lines src/small.py 10; track $S8 "$T/proj/src/small.py"
out=$(stop "$SID"); [ -z "$out" ] && ok "10 added lines: silent" || bad "10 added lines: silent"

# 5. docs only, and test files only
fresh $S8; lines notes.md 300; track $S8 "$T/proj/notes.md"
out=$(stop "$SID"); [ -z "$out" ] && ok "a large markdown file is not code: silent" || bad "a large markdown file is not code: silent"
fresh $S8; lines src/a.test.py 300; track $S8 "$T/proj/src/a.test.py"
out=$(stop "$SID"); [ -z "$out" ] && ok "a large test file alone: silent" || bad "a large test file alone: silent"

# 6. the pre-edit snapshot decides what was added: a 200-line file with 10 lines added is small
fresh $S8; lines src/big.py 200; cp "src/big.py" "$T/big.snap"; printf 'y = 1\n%.0s' 1 2 3 4 5 6 7 8 9 10 >> src/big.py
mkdir -p "/tmp/claude-presnap-$S8"
fr=$(cd src && printf '%s/%s' "$(pwd -P)" big.py); key=$(printf '%s' "$fr" | shasum | awk '{print $1}')
cp "$T/big.snap" "/tmp/claude-presnap-$S8/$key"; track $S8 "$T/proj/src/big.py"
out=$(stop "$SID"); [ -z "$out" ] && ok "snapshot: 10 lines added to a 200-line file is not substantial" || bad "snapshot: 10 lines added to a 200-line file is not substantial: $out"

# 6b. regression: with a snapshot present and 80 lines added, diff exits 1 and the count must
# still be a single number. A doubled "80\n0" once broke the arithmetic and silenced every nudge.
fresh $S8; lines src/grow.py 20; cp "src/grow.py" "$T/grow.snap"; lines src/grow.py 100
mkdir -p "/tmp/claude-presnap-$S8"
fr=$(cd src && printf '%s/%s' "$(pwd -P)" grow.py); key=$(printf '%s' "$fr" | shasum | awk '{print $1}')
cp "$T/grow.snap" "/tmp/claude-presnap-$S8/$key"; track $S8 "$T/proj/src/grow.py"
out=$(stop "$SID"); warns "$out" && ok "snapshot: 80 lines added to a 20-line file warns" || bad "snapshot: 80 lines added to a 20-line file warns: $out"

# 7. the marker fix: write with the FULL uuid, the 8-char form, and nothing at all
for form in "$SID" "$S8" ""; do
  fresh $S8; lines src/b.py 80; track $S8 "$T/proj/src/b.py"
  out=$(stop "$SID"); warns "$out" || bad "marker form '$form': setup did not warn"
  if [ -z "$form" ]; then CLAUDE_CODE_SESSION_ID="$SID" bash "$MARKER" write >/dev/null; else bash "$MARKER" write "$form" >/dev/null; fi
  out=$(stop "$SID")
  [ -z "$out" ] && [ "$(heeds true)" = 1 ] && ok "review-marker write '${form:-<env>}' silences the nudge and records heeded:true" || bad "review-marker write '${form:-<env>}' silences the nudge and records heeded:true (out='$out' heed=$(heeds true))"
done

# 8. a new unreviewed file after a review is a new set and warns again
lines src/c.py 80; track $S8 "$T/proj/src/c.py"
out=$(stop "$SID"); warns "$out" && ok "a new file after a review warns again" || bad "a new file after a review warns again"

# 9. another session's review does not cover this session's files
fresh $S8; rm -f /tmp/claude-review-done-otherses; lines src/d.py 80; track $S8 "$T/proj/src/d.py"
echo "$T/proj/src/d.py" > "/tmp/claude-review-done-otherses"
out=$(stop "$SID"); warns "$out" && ok "another session's marker does not silence this session" || bad "another session's marker does not silence this session"
rm -f /tmp/claude-review-done-otherses

fresh $S8
echo "---- pass=$pass fail=$fail"
cd / && trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
