#!/usr/bin/env bash
# detect-stale-session.test.sh: each orphan turn-state file and each dangling WAL
# session is reported to one session, then stays quiet; a new orphan is reported
# on its own. D=<path> points the suite at a mutated copy of the script.
set -uo pipefail
REAL="$HOME"
D="${D:-$REAL/.claude/scripts/session-mgmt/detect-stale-session.sh}"
pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }

T=$(mktemp -d); export HOME="$T"; mkdir -p "$T/.claude/.turn-state"
S="$T/.claude/.turn-state"
orphan(){ printf '{"session_id":"%s","ts":"2026-10-14T10:00:00Z","prompt_preview":"fix the thing"}' "$1" > "$S/$1.json"; }
start(){ printf '{"session_id":"new"}' | bash "$D" | jq -r '.hookSpecificOutput.additionalContext // empty'; }
has(){ printf '%s' "$1" | rg -q "$2"; }

orphan aaaa1111; orphan bbbb2222
o=$(start)
has "$o" aaaa1111 && has "$o" bbbb2222 && ok "first session names both orphans" || ko "first session: $o"
o=$(start)
[ -z "$o" ] && ok "second session is silent" || ko "second session repeated: $o"
o=$(start)
[ -z "$o" ] && ok "third session is silent" || ko "third session repeated"
orphan cccc3333
o=$(start)
has "$o" cccc3333 && ok "a new orphan is reported" || ko "new orphan silent"
has "$o" aaaa1111 && ko "old orphan repeated beside the new one" || ok "old orphan not repeated beside the new one"

trash "$S/.acked-orphans" 2>/dev/null
o=$(start)
has "$o" aaaa1111 && ok "clearing the marker directory brings the notice back" || ko "no notice after reset"

trash "$S/.acked-orphans" 2>/dev/null
o=$(printf '{"session_id":"new"}' | env I_DREAM_CHILD=1 bash "$D" | jq -r '.hookSpecificOutput.additionalContext // empty')
has "$o" aaaa1111 && ok "an i-dream helper still sees the notice" || ko "helper saw nothing"
o=$(start)
has "$o" aaaa1111 && ok "but it did not consume it for the owner" || ko "helper ate the notice"

# dangling WAL session: reported once
trash "$S"/*.json "$S/.acked-orphans" 2>/dev/null
now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
printf '{"kind":"session_start","session_id":"walsess1","ts":"%s"}\n' "$now" > "$T/.claude/wal.jsonl"
o=$(start)
has "$o" walsess1 && ok "dangling WAL session reported" || ko "WAL session silent: $o"
o=$(start)
[ -z "$o" ] && ok "dangling WAL session reported once" || ko "WAL session repeated"

export HOME="$REAL"; trash "$T" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
