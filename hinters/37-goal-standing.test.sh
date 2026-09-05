#!/usr/bin/env bash
# 37-goal-standing.test.sh — the goal hinter fires on prompt 1 and every 8th, only when a
# gcc goal exists and the harness /goal is not armed; machine turns cost no slot.
set -uo pipefail
H=/Users/alcatraz627/.claude/hinters/37-goal-standing.sh; G=/Users/alcatraz627/.claude/scripts/goal/goal.sh
pass=0; fail=0; ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }
T=$(mktemp -d); REAL="$HOME"; export HOME="$T"; mkdir -p "$HOME/.claude/goals" "$HOME/.claude/scripts/goal" "$HOME/.claude/hinters"
cp "$G" "$HOME/.claude/scripts/goal/"; cp "$H" "$HOME/.claude/hinters/"; H="$HOME/.claude/hinters/37-goal-standing.sh"; G="$HOME/.claude/scripts/goal/goal.sh"
SID=bbbbbbbb-0000-0000-0000-000000000002; export CLAUDE_HINT_SID=$SID; ST="/tmp/claude-goalhint-${SID:0:8}"; trash "$ST" 2>/dev/null || true
run(){ echo "$1" | bash "$H"; }
[ -z "$(run hi)" ] && ok "no goal file: silent" || ko "no goal silent"
bash "$G" set "finish the thing" --by catchup --sid $SID >/dev/null
out=$(run hi)
echo "$out" | rg -q "Standing objective.*finish the thing" && ok "prompt 1 fires" || ko "prompt 1"
# The paste line is its own bare line (adv-goal F7): exactly "/goal <text>", no
# prose before it, no mute clause after it, so selecting the line copies clean.
echo "$out" | rg -qx "/goal finish the thing" && ok "the paste line stands alone, bare" || ko "paste line not bare: $(echo "$out" | rg '/goal')"
[ -z "$(run hi)" ] && ok "prompt 2 silent" || ko "prompt 2"
for i in 3 4 5 6 7; do run x >/dev/null; done
[ -n "$(run x)" ] && ok "prompt 8 fires" || ko "prompt 8"
c=$(cat "$ST"); run "<system-reminder>x" >/dev/null; [ "$(cat "$ST")" = "$c" ] && ok "machine turn: no slot spent" || ko "machine turn"
# arm the harness goal via a fixture transcript in this sandbox HOME, cwd = /
mkdir -p "$HOME/.claude/projects/-"; printf '{"type":"user","timestamp":"t","message":{"role":"user","content":"<command-name>/goal</command-name>\\n<command-message>goal</command-message>\\n<command-args>finish the thing</command-args>"}}\n' > "$HOME/.claude/projects/-/$SID.jsonl"
trash "$ST" 2>/dev/null || true; out=$(cd / && echo hi | bash "$H"); [ -z "$out" ] && ok "harness armed: silent" || ko "harness armed should be silent: $out"
touch "$HOME/.claude/.no-goal-hint"; trash "$ST" 2>/dev/null || true; [ -z "$(run hi)" ] && ok "mute honoured" || ko "mute"
export HOME="$REAL"; trash "$T" "$ST" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
