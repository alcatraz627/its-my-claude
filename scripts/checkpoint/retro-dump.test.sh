#!/usr/bin/env bash
# Tests for retro-dump.sh: a run is done only when the index says so, the queue
# runs newest first, stale entries expire without a call, and the timeout scales.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
RD="$HERE/retro-dump.sh"
T=$(mktemp -d); export HOME="$T"
Q="$T/.claude/checkpoints/retro-queue"; INDEX="$T/.claude/checkpoints/index.jsonl"
P="$T/.claude/projects/-proj"
mkdir -p "$Q" "$P" "$T/bin"
: > "$INDEX"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

# A fake claude. FAKE_MODE=writes appends an index line the way /core-dump would;
# FAKE_MODE=silent exits 0 and writes nothing. Every call leaves a marker.
cat > "$T/bin/claude" <<'SH'
#!/usr/bin/env bash
uuid=""; while [ $# -gt 0 ]; do [ "$1" = "--resume" ] && uuid="$2"; shift; done
echo "$uuid" >> "$HOME/calls.log"
if [ "${FAKE_MODE:-silent}" = "writes" ]; then
  printf '{"ts":"2026-09-08T00:00:00Z","session_id":"%s","project_root":"/p","checkpoint_path":"/p/_r.claude.md","name":"retroactive-%s","kind":"core-dump"}\n' "$uuid" "${uuid:0:8}" >> "$HOME/.claude/checkpoints/index.jsonl"
fi
exit 0
SH
chmod +x "$T/bin/claude"
export CLAUDE_BIN="$T/bin/claude"

U1=11111111-aaaa-bbbb-cccc-000000000001   # newest transcript
U2=22222222-aaaa-bbbb-cccc-000000000002   # older, still in window
U3=33333333-aaaa-bbbb-cccc-000000000003   # past the window
mk() { # mk <uuid> <touch -t stamp>
  printf '{"type":"user"}\n' > "$P/$1.jsonl"; touch -t "$2" "$P/$1.jsonl"
  jq -cn --arg u "$1" --arg t "$P/$1.jsonl" '{session_uuid:$u, transcript:$t}' > "$Q/$1.queued"
}
U4=44444444-aaaa-bbbb-cccc-000000000004   # fresh, but a hand-made dump already indexed it
mk "$U1" "$(date -v-1H +%Y%m%d%H%M)"
mk "$U2" "$(date -v-2d +%Y%m%d%H%M)"
mk "$U3" "$(date -v-20d +%Y%m%d%H%M)"
mk "$U4" "$(date -v-30M +%Y%m%d%H%M)"
printf '{"ts":"2026-09-07T00:00:00Z","session_id":"csync-hand","session_uuid":"%s","kind":"core-dump"}\n' "$U4" >> "$INDEX"

echo "== the queue expires the stale, runs the newest, and counts only the index =="
: > "$T/calls.log"
out=$(FAKE_MODE=silent bash "$RD" --queue --max-per-run 1)
[ -f "$Q/expired/$U3.queued" ] && ok "20-day-old entry moved to expired/ without a call" || bad "stale entry not expired"
rg -q "$U3" "$T/calls.log" && bad "the expired uuid was still run" || ok "no LLM call spent on the expired uuid"
[ "$(cat "$T/calls.log")" = "$U1" ] && ok "newest transcript ran first, alone (cap 1)" || bad "order wrong: $(cat "$T/calls.log")"
[ -f "$Q/expired/$U4.queued" ] && ok "a uuid the index already holds is retired, not re-dumped (the csync case)" || bad "already-indexed uuid still queued"
ls "$Q/failed/$U1.queued.rc97."* >/dev/null 2>&1 && ok "silent rc=0 with no index entry is failure rc 97" || bad "silent run treated as success: $(ls "$Q" "$Q/failed" 2>/dev/null)"
rg -q "NO CHECKPOINT WRITTEN for $U1" "$T/.claude/logs/retro-dump.log" && ok "the log names the silent no-write" || bad "log silent on the no-write"
[ -f "$Q/$U2.queued" ] && ok "the older live entry waits for the next run" || bad "U2 consumed by a cap-1 run"
printf '%s' "$out" | rg -q 'processed 1 .*expired 2' && ok "summary line counts both" || bad "summary: $out"

echo "== a run that writes the index is a success =="
: > "$T/calls.log"
FAKE_MODE=writes bash "$RD" --queue --max-per-run 1 >/dev/null
[ ! -f "$Q/$U2.queued" ] && [ ! -e "$Q/failed/$U2.queued"* ] && ok "queue file removed on a real write" || bad "U2 not cleared"
rg -q "end retro-dump $U2 \(rc=0\)" "$T/.claude/logs/retro-dump.log" && ok "rc 0 logged" || bad "no rc=0 line"
rg -q '^\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9:]{8}Z\]' "$T/.claude/logs/retro-dump.log" && ok "log stamps are UTC-shaped" || bad "log stamp shape"

echo "== the timeout scales with the transcript =="
t0=$(bash "$RD" --print-timeout "$U1")
[ "$t0" = 180 ] && ok "a tiny transcript gets the 180 s base" || bad "base timeout $t0"
head -c 26000000 /dev/zero > "$P/$U1.jsonl"
t1=$(bash "$RD" --print-timeout "$U1")
[ "$t1" = 540 ] && ok "a 26 MB transcript (the csync case) gets 540 s, not 120" || bad "scaled timeout $t1"
head -c 60000000 /dev/zero > "$P/$U1.jsonl"
t2=$(bash "$RD" --print-timeout "$U1")
[ "$t2" = 900 ] && ok "capped at 900 s" || bad "cap $t2"
t3=$(bash "$RD" --timeout-seconds 42 --print-timeout "$U1")
[ "$t3" = 42 ] && ok "--timeout-seconds still overrides" || bad "override $t3"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
