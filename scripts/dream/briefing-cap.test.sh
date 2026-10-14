#!/usr/bin/env bash
# briefing-cap.test.sh: the two SessionStart briefings (i-dream project brief and
# the atone block) together stay near 1,200 characters, newest first.
# BRIEF_CAP / ATONE_BUDGET override the budgets so a mutation run can lift them.
set -uo pipefail
REAL="$HOME"
FIX="$REAL/.claude/assets/reports/20261015-queue/q-cuts-work/idream-brief.fixture.txt"
CAP="$REAL/.claude/scripts/dream/brief-cap.py"
INS="${INS:-$REAL/.claude/scripts/dream/dream-insights.sh}"
SS="$REAL/.claude/subconscious/hooks/session-start.sh"
pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }

# 1. brief-cap.py on the captured daemon response
n=$(python3 "$CAP" "${BRIEF_CAP:-700}" < "$FIX" | wc -m | tr -d ' ')
raw=$(wc -m < "$FIX" | tr -d ' ')
[ "$n" -le 700 ] && ok "brief capped to 700 ($raw -> $n chars)" || ko "brief is $n chars, over 700"
python3 "$CAP" 700 < "$FIX" | rg -q "Graduate corrections into hooks" && ok "first-ranked do item survives the cap" || ko "first do item lost"
python3 "$CAP" 700 < "$FIX" | rg -q "<!--" && ko "html comment leaked" || ok "html comment stripped"
n=$(printf 'plain text with no sections. %.0s' $(seq 1 80) | python3 "$CAP" 300 | wc -m | tr -d ' ')
[ "$n" -le 301 ] && ok "unstructured text is cut at the budget ($n)" || ko "unstructured text $n chars"

# 2. session-start.sh end to end against a fake daemon socket
D=$(mktemp -d /tmp/idbXXXX)
cat > "$D/srv.py" <<'PY'
import socket, sys, os
p, fix = sys.argv[1], sys.argv[2]
s = socket.socket(socket.AF_UNIX); s.bind(p); s.listen(1)
c, _ = s.accept(); c.makefile().readline(); c.sendall(open(fix, "rb").read()); c.close()
PY
python3 "$D/srv.py" "$D/d.sock" "$FIX" &
srv=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do [ -S "$D/d.sock" ] && break; sleep 0.2; done
out=$(printf '{"session_id":"cap-test-1","cwd":"/x"}' | env IDREAM_SOCKET="$D/d.sock" IDREAM_BRIEF_CAP="${BRIEF_CAP:-700}" bash "$SS")
kill "$srv" 2>/dev/null || true
b=$(printf '%s' "$out" | wc -m | tr -d ' ')
[ "$b" -le 701 ] && ok "session-start.sh emits the capped briefing ($b chars)" || ko "session-start.sh emitted $b chars"

# 3. dream-insights atone block: newest first, held to the budget, no long header
H=$(mktemp -d); mkdir -p "$H/.claude/atone/derived" "$H/.claude/hooks" "$H/.claude/i-dream"
long="Before doing the thing, check the other thing carefully and read the file again and again until you are sure it is right and then continue"
{
  for s in old-slug mid-slug new-slug fourth-slug; do
    case $s in old-slug) ts=2026-10-10T10:00:00Z;; mid-slug) ts=2026-10-12T10:00:00Z;; new-slug) ts=2026-10-14T10:00:00Z;; *) ts=2026-10-11T10:00:00Z;; esac
    for i in 1 2 3; do jq -nc --arg s "$s" --arg t "$ts" --arg p "$long" '{ts:$t,slug:$s,precheck:$p}'; done
  done
} > "$H/.claude/atone/derived/.events-view.jsonl"
ins=$(env HOME="$H" INJECT_TEST=1 INJECT_SID=cap-test-1 ATONE_BUDGET="${ATONE_BUDGET:-500}" bash "$INS" | jq -r '.additionalContext')
a=$(printf '%s' "$ins" | wc -m | tr -d ' ')
[ "$a" -le 500 ] && ok "atone block held to 500 ($a chars)" || ko "atone block is $a chars"
small=$(env HOME="$H" INJECT_TEST=1 INJECT_SID=cap-test-1 ATONE_BUDGET=250 bash "$INS" | jq -r ".additionalContext" | wc -m | tr -d " ")
[ "$small" -le 250 ] && ok "a 250 budget drops rows to fit ($small chars)" || ko "budget not applied ($small chars at 250)"
first=$(printf '%s' "$ins" | rg -o "^- [a-z-]+" | head -1)
[ "$first" = "- new-slug" ] && ok "newest mistake listed first" || ko "first row is '$first'"
printf '%s' "$ins" | rg -q "High-confidence rules" && ko "long header still present" || ok "long header dropped"

tot=$((b + a))
[ "$tot" -le 1250 ] && ok "both briefings together: $tot chars (was $((raw + 897)))" || ko "both briefings total $tot"

trash "$D" "$H" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
