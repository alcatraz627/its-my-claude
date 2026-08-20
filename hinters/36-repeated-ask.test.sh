#!/usr/bin/env bash
# 36-repeated-ask.test.sh — fires only when the user says they already asked AND the
# prompt links to a recent one; quiet on plain follow-ups and unrelated escalations.
set -uo pipefail
H=/Users/alcatraz627/.claude/hinters/36-repeated-ask.sh; pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }
export CLAUDE_HINT_SID=t36test1; ST=/tmp/claude-repeatask-t36test; trash "$ST"* 2>/dev/null || true
run(){ echo "$1" | bash "$H"; }
[ -x "$H" ] && ok "hinter carries the x bit (hint-injector skips 644 silently)" || ko "not executable"
[ -z "$(run "can you fix the session start hook entry for kanban")" ] && ok "first prompt seeds, no fire" || ko "seed fired"
run "No I asked you IF the session start hook entry was firing, not to rewrite it" | rg -q "repeated-ask" && ok "shape-7 re-ask fires" || ko "shape 7"
[ -z "$(run "as I said, the weather api key expired")" ] && ok "unrelated escalation phrase: quiet" || ko "unrelated fired"
[ -z "$(run "also make the hook entry log its start time")" ] && ok "plain follow-up: quiet" || ko "follow-up fired"
run "again: fix the session start hook entry" | rg -q "repeated-ask" && ok "'again:' arm fires (I5)" || ko "again: arm"
[ -z "$(run "<system-reminder>session start hook entry")" ] && ok "machine turn: quiet" || ko "machine turn fired"
touch "$HOME/.claude/.no-repeated-ask"; [ -z "$(run "I asked you about the session start hook entry")" ] && ok "mute honoured" || ko "mute"; trash "$HOME/.claude/.no-repeated-ask"
trash "$ST"* 2>/dev/null || true; echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
