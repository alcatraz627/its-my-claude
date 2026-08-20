#!/usr/bin/env bash
# tool-counter.test.sh — the auto-checkpoint nudge fires only on a MEASURED context
# percentage of 50 or more, never on the tool count alone (owner ruling 2026-08-18).
set -uo pipefail
S=/Users/alcatraz627/.claude/scripts/tool-counter.sh; pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }
# The counter file is keyed on $PPID (the claude pid). Run under a fixed parent so the
# 30th call is deterministic: a subshell whose $$ is the PPID of each hook run.
# (capturing run_n itself with $(...) is fine: the fork happens outside bash -c)
# No $(...) capture around the hook: command substitution forks, and the fork's pid
# would become the hook's PPID, scattering the tally over 30 different files.
run_n(){ # $1 = n calls, $2 = stdin json, $3 = optional ctx file value
  bash -c '
    f="/tmp/claude-tools-$$"; trash "$f" "$f.lockdir" 2>/dev/null; : > "$f"
    export CTX_FILE_OVERRIDE="/tmp/claude-ctx-test-$$"; trash "$CTX_FILE_OVERRIDE" 2>/dev/null
    [ -n "$3" ] && printf "%s" "$3" > "$CTX_FILE_OVERRIDE"
    o="/tmp/claude-tools-out-$$"; for i in $(seq 1 "$1"); do printf "%s" "$2" | bash '"$S"' > "$o" 2>/dev/null; done
    cat "$o"; trash "$f" "$o" "$CTX_FILE_OVERRIDE" 2>/dev/null' _ "$1" "$2" "${3:-}"
}
J='{"tool_name":"Bash","tool_input":{"command":"true"},"cwd":"/tmp/nowhere-x"}'
[ -z "$(run_n 30 "$J")" ] && ok "tool 30, no context measurement: silent" || ko "unknown ctx fired"
[ -z "$(run_n 30 "$J" 80)" ] && ok "tool 30, 20% used: silent" || ko "20% fired"
[ -z "$(run_n 60 "$J" 55)" ] && ok "tool 60, 45% used: silent" || ko "45% fired"
[[ "$(run_n 30 "$J" 50)" == *"auto-checkpoint] Tool count 30, context ~50%"* ]] && ok "tool 30, 50% used: fires with the measured figure" || ko "50% silent"
[[ "$(run_n 60 "$J" 30)" == *"Tool count 60, context ~70%"* ]] && ok "tool 60, 70% used: fires" || ko "70% silent"
[[ "$(run_n 60 "$J" 30)" == *"auto-compact soon"* ]] && ko "old unmeasured wording survives" || ok "no 'may auto-compact soon' claim in the text"
JP='{"tool_name":"Bash","tool_input":{"command":"true"},"cwd":"/tmp/nowhere-x","context_window":{"remaining_percentage":35}}'
[[ "$(run_n 30 "$JP")" == *"context ~65%"* ]] && ok "payload context_window wins over the file" || ko "payload ctx"
[ -z "$(run_n 29 "$J" 30)" ] && ok "tool 29 at 70%: silent (still a multiple-of-30 nudge)" || ko "29 fired"
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
