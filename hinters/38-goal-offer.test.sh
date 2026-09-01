#!/usr/bin/env bash
# Tests for 38-goal-offer.sh. Mirrors 37-goal-standing.test.sh's shape.
set -uo pipefail
H="$HOME/.claude/hinters/38-goal-offer.sh"
pass=0; fail=0
ck(){ if [ "$2" = "$3" ]; then echo "  ok    $1"; pass=$((pass+1)); else echo "  FAIL  $1 (got '$3' want '$2')"; fail=$((fail+1)); fi; }
run(){ SID="$1"; shift; printf '%s' "$1" | CLAUDE_HINT_SID="$SID" bash "$H" 2>/dev/null | rg -c '^\[goal\]' 2>/dev/null || echo 0; }
clean(){ rm -f "/tmp/claude-goaloffer-${1:0:8}"; rm -f "$HOME/.claude/goals/$1.json"; }

[ -x "$H" ] && ck "hinter carries the x bit" 1 1 || ck "hinter carries the x bit" 1 0

S=goaloffer-aaaa-aaaa; clean "$S"
ck "work verb, no goal: fires"            1 "$(run "$S" 'lets build the export pipeline for the console')"
ck "second prompt same session: silent"   0 "$(run "$S" 'now implement the second half')"

S=goaloffer-bbbb-bbbb; clean "$S"
ck "plain lookup: silent"                 0 "$(run "$S" 'what is in my tasks right now')"

S=goaloffer-cccc-cccc; clean "$S"
ck "lookup wearing a work verb: silent"   0 "$(run "$S" 'show me the plan you built earlier')"

S=goaloffer-dddd-dddd; clean "$S"
ck "recon phrasing: fires"                1 "$(run "$S" 'dig into why the reconciler drops rows')"

S=goaloffer-eeee-eeee; clean "$S"
ck "terse continuation: silent"           0 "$(run "$S" 'keep going')"

S=goaloffer-ffff-ffff; clean "$S"
mkdir -p "$HOME/.claude/goals"; printf '{"text":"x","by":"owner"}' > "$HOME/.claude/goals/$S.json"
ck "goal already set: silent (37 owns it)" 0 "$(run "$S" 'lets build the thing')"
clean "$S"

S=goaloffer-gggg-gggg; clean "$S"
ck "machine turn: silent"                 0 "$(run "$S" '<system-reminder>build something</system-reminder>')"

S=goaloffer-hhhh-hhhh; clean "$S"
touch "$HOME/.claude/.no-goal-hint"
ck "mute honoured"                        0 "$(run "$S" 'lets build the export pipeline')"
rm -f "$HOME/.claude/.no-goal-hint"; clean "$S"

echo "---- pass=$pass fail=$fail ----"
[ "$fail" -eq 0 ]
