#!/usr/bin/env bash
# The proposal-then-halt gate: blocks once on a bare /goal line, never on a
# hand-off, never twice, never while the harness is already continuing.
set -uo pipefail
H="$HOME/.claude/scripts/hooks/goal-proposal-stop.sh"
pass=0; fail=0
ok(){ echo "  ok    $1"; pass=$((pass+1)); }
bad(){ echo "  FAIL  $1"; fail=$((fail+1)); }
ROOT=$(mktemp -d "${TMPDIR:-/tmp}/goalprop-XXXXXX"); trap 'rm -rf "$ROOT"' EXIT
sid="tttttttt-0000-4000-8000-000000000000"; rm -f "/tmp/claude-goalprop-${sid:0:8}"
mk(){ # mk <file> <assistant text> [tool]
  { printf '{"type":"user","message":{"role":"user","content":"do the thing"}}\n'
    if [ "${3:-}" = tool ]; then
      printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":%s},{"type":"tool_use","name":"Bash","input":{"command":"ls"}}]}}\n' "$(printf '%s' "$2" | jq -Rs .)"
    else
      printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":%s}]}}\n' "$(printf '%s' "$2" | jq -Rs .)"
    fi; } > "$1"
}
run(){ printf '{"transcript_path":"%s","session_id":"%s","stop_hook_active":%s}' "$1" "$sid" "${2:-false}" | bash "$H"; }

mk "$ROOT/a.jsonl" $'Arm line first.\n\n/goal The thing is built and checked.\n'
out=$(run "$ROOT/a.jsonl"); printf '%s' "$out" | rg -q '"decision":"block"' && ok "a bare proposal with no tool call is blocked" || bad "bare proposal not blocked: $out"
out=$(run "$ROOT/a.jsonl"); [ -z "$out" ] && ok "the same message is not blocked twice" || bad "blocked twice"
rm -f "/tmp/claude-goalprop-${sid:0:8}"
out=$(run "$ROOT/a.jsonl" true); [ -z "$out" ] && ok "steps aside while the harness is continuing" || bad "blocked under stop_hook_active"
mk "$ROOT/b.jsonl" $'/goal The thing is built.\n' tool
out=$(run "$ROOT/b.jsonl"); [ -z "$out" ] && ok "a proposal followed by a tool call passes" || bad "blocked a working turn"
mk "$ROOT/c.jsonl" $'Briefing done.\n\n/goal The thing is built.\n\nWhich pending item should we start with?'
out=$(run "$ROOT/c.jsonl"); [ -z "$out" ] && ok "a catchup hand-off passes" || bad "blocked a hand-off"
mk "$ROOT/d.jsonl" $'All done here, nothing proposed.'
out=$(run "$ROOT/d.jsonl"); [ -z "$out" ] && ok "a turn with no proposal passes" || bad "blocked a plain turn"
echo "---- pass=$pass fail=$fail"; [ "$fail" -eq 0 ]
