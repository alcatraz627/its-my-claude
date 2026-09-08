#!/usr/bin/env bash
# 39-goal-arm-lint.test.sh — the arm lint mirrors the owner's /goal into the gcc
# store, nags only on a clause the owner would have to finish, and retires the
# mirror when he clears the goal. Three ledger entries on 2026-09-08 were the
# lint asking him to re-arm his own register; one was a cleared goal that left
# no trace any tool reads.
set -uo pipefail
H=/Users/alcatraz627/.claude/hinters/39-goal-arm-lint.sh; G=/Users/alcatraz627/.claude/scripts/goal/goal.sh
WL=/Users/alcatraz627/.claude/scripts/hooks/warn-log.sh
pass=0; fail=0; ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }
T=$(mktemp -d); REAL="$HOME"; export HOME="$T"
mkdir -p "$HOME/.claude/goals" "$HOME/.claude/scripts/goal" "$HOME/.claude/scripts/hooks" "$HOME/.claude/hinters" "$HOME/.claude/projects/-"
cp "$G" "$HOME/.claude/scripts/goal/"; cp "$H" "$HOME/.claude/hinters/"; [ -f "$WL" ] && cp "$WL" "$HOME/.claude/scripts/hooks/"
H="$HOME/.claude/hinters/39-goal-arm-lint.sh"
SID=cccccccc-0000-0000-0000-000000000039; export CLAUDE_HINT_SID=$SID
ST="/tmp/claude-goalarm-${SID:0:8}"; trash "$ST" 2>/dev/null || true
export WARN_LOG_STORE="$T/warnlog"
TR="$HOME/.claude/projects/-/$SID.jsonl"
arm(){ printf '{"type":"user","timestamp":"t","message":{"role":"user","content":"<command-name>/goal</command-name>\\n<command-message>goal</command-message>\\n<command-args>%s</command-args>"}}\n' "$1" >> "$TR"; }
run(){ (cd / && echo hi | bash "$H"); }

echo "== an owner goal with only a quantifier: silent, and mirrored into the gcc store =="
arm "Every open row in the store carries a goal by Friday"
out=$(run)
[ -z "$out" ] && ok "no nag for a quantifier in the owner's own goal" || ko "nagged: $out"
[ "$(jq -r '.by // empty' "$HOME/.claude/goals/$SID.json" 2>/dev/null)" = "owner" ] && ok "the arm is mirrored into the gcc store, by owner" || ko "no mirror: $(ls "$HOME/.claude/goals/")"
[ "$(jq -r '.text' "$HOME/.claude/goals/$SID.json" 2>/dev/null)" = "Every open row in the store carries a goal by Friday" ] && ok "the mirror carries the text verbatim" || ko "mirror text differs"

echo "== an owner goal with an actor clause: one nag, naming the clause =="
trash "$ST" 2>/dev/null || true
arm "Draft the plan and take the owner's review of it"
out=$(run)
echo "$out" | rg -q "clause only the owner can finish" && ok "the actor clause is nagged" || ko "no nag for an actor clause: $out"
echo "$out" | rg -q "names an OWNER action" && ok "the finding names the clause" || ko "finding missing from the nag"
echo "$out" | rg -q "unbounded quantifier" && ko "a non-actor finding rode the nag" || ok "no other finding rides the nag"
[ -z "$(run)" ] && ok "the same text is nagged once" || ko "nagged twice"

echo "== the owner clears the goal: the mirror is retired =="
arm "clear"
out=$(run)
[ -z "$out" ] && ok "silent on a cleared goal" || ko "spoke on clear: $out"
[ ! -f "$HOME/.claude/goals/$SID.json" ] && ok "the gcc mirror is gone after the owner's clear" || ko "mirror survived the clear: $(jq -c . "$HOME/.claude/goals/$SID.json")"

echo "== a gcc goal the agent set is never cleared by this hinter =="
bash "$HOME/.claude/scripts/goal/goal.sh" set "an agent-set goal" --by catchup --sid "$SID" >/dev/null 2>&1
printf '%s' "deadbeef0000" > "$ST"
run >/dev/null
[ -f "$HOME/.claude/goals/$SID.json" ] && ok "an agent-set gcc goal survives a harness that is not armed" || ko "the hinter cleared a goal it did not mirror"

export HOME="$REAL"; trash "$T" "$ST" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
