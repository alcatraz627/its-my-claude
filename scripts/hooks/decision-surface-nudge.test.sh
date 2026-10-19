#!/bin/bash
# Checks that the decision-surface nudge speaks for decision sets and visual
# comparisons, and stays silent for a single plain question or another tool.
H="$HOME/.claude/scripts/hooks/decision-surface-nudge.sh"
fail=0
run() { DECISION_SURFACE_OFF=0 bash "$H" <<<"$1"; }
expect() {
  local name="$1" want="$2" got="$3"
  case "$want" in
    silent) [ -z "$got" ] && echo "ok   $name" || { echo "FAIL $name: $got"; fail=1; } ;;
    *) printf '%s' "$got" | grep -q "$want" && echo "ok   $name" || { echo "FAIL $name: '$got'"; fail=1; } ;;
  esac
}
one='{"tool_name":"AskUserQuestion","tool_input":{"questions":[{"question":"a?","options":[{"label":"x"},{"label":"y"}]}]}}'
two='{"tool_name":"AskUserQuestion","tool_input":{"questions":[{"question":"a?","options":[]},{"question":"b?","options":[]}]}}'
vis='{"tool_name":"AskUserQuestion","tool_input":{"questions":[{"question":"a?","options":[{"label":"x","preview":"[box]"},{"label":"y"}]}]}}'
other='{"tool_name":"Bash","tool_input":{"command":"ls"}}'
expect "single question is silent" silent "$(run "$one")"
expect "two questions route to the wizard" "decision-wizard" "$(run "$two")"
expect "previews route to mock-app" "mock-app" "$(run "$vis")"
expect "other tools are silent" silent "$(run "$other")"
expect "malformed input is silent" silent "$(run 'not json')"
exit $fail
