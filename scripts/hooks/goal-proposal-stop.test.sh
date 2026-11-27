#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
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

# Lag regression: the reply judged is the Stop input's last_assistant_message,
# never the one-message-stale transcript tail.
runlam(){ printf '{"transcript_path":"%s","session_id":"%s","stop_hook_active":false,"last_assistant_message":%s}' "$1" "$sid" "$(printf '%s' "$2" | jq -Rs .)" | bash "$H"; }
rm -f "/tmp/claude-goalprop-${sid:0:8}"
mk "$ROOT/clean-tail.jsonl" $'Previous reply, nothing proposed.'
out=$(runlam "$ROOT/clean-tail.jsonl" $'Now arm this.\n\n/goal The thing is built.\n')
printf '%s' "$out" | rg -q '"decision":"block"' && ok "current reply proposes, clean tail: blocks" || bad "lag: current bad, clean tail not blocked: $out"
rm -f "/tmp/claude-goalprop-${sid:0:8}"
mk "$ROOT/bad-tail.jsonl" $'/goal The thing is built.\n'
out=$(runlam "$ROOT/bad-tail.jsonl" 'Plain reply, nothing proposed.')
[ -z "$out" ] && ok "current reply clean, proposing tail: silent" || bad "lag: current clean, bad tail blocked: $out"

# The owner asked for a plan or a pick, so the reply is the answer and the next move is theirs
# (c314380d L277 then L359: the gate pushed edits before the owner's "go on all").
export KEEPWARM_PY="$HOME/.claude/scripts/keepwarm/keepwarm.py"
mkp(){ # mkp <file> <owner prompt> <assistant text>
  { printf '{"type":"user","message":{"role":"user","content":%s}}\n' "$(printf '%s' "$2" | jq -Rs .)"
    printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":%s}]}}\n' "$(printf '%s' "$3" | jq -Rs .)"; } > "$1"
}
rm -f "/tmp/claude-goalprop-${sid:0:8}"
mkp "$ROOT/e.jsonl" 'Can you also make a plan to fix the issues, and then tell me which ones are worth doing' $'Do six of the ten.\n\n| # | Fix | Verdict |\n|---|---|---|\n| 1 | chmod -x | Do |\n\n/goal The hooks fire once and the stamps are current.\n'
out=$(run "$ROOT/e.jsonl"); [ -z "$out" ] && ok "a plan the owner asked to choose from passes (c314380d L359)" || bad "pushed past the owner's pick: $out"
rm -f "/tmp/claude-goalprop-${sid:0:8}"
mkp "$ROOT/f.jsonl" 'fix the flaky hook' $'Here is the fix plan.\n\n/goal The hook fires once.\n\nIf no reply: hold, the restart is yours to time.'
out=$(run "$ROOT/f.jsonl"); [ -z "$out" ] && ok "a declared hold passes" || bad "declared hold blocked: $out"
rm -f "/tmp/claude-goalprop-${sid:0:8}"
mkp "$ROOT/g.jsonl" 'fix the flaky hook' $'Plan is set.\n\n/goal The hook fires once.\n'
out=$(run "$ROOT/g.jsonl"); printf '%s' "$out" | rg -q '"decision":"block"' && ok "a bare proposal after a build order still blocks" || bad "build-order proposal passed"
printf '%s' "$out" | rg -q 'read-only' && ok "the block says a pending choice allows only read-only calls" || bad "block lacks the read-only clause: $out"

# MUTATION: without the owner-prompt check, the c314380d shape is pushed again.
MUT="$ROOT/mut.sh"; sed 's/owner_asked_pick=1/owner_asked_pick=0/' "$H" > "$MUT"
rm -f "/tmp/claude-goalprop-${sid:0:8}"
out=$(printf '{"transcript_path":"%s","session_id":"%s","stop_hook_active":false}' "$ROOT/e.jsonl" "$sid" | bash "$MUT")
printf '%s' "$out" | rg -q '"decision":"block"' && ok "MUTATION: dropping the owner-prompt check blocks the plan again (the check is load-bearing)" || bad "mutant still passed: $out"

echo "---- pass=$pass fail=$fail"; [ "$fail" -eq 0 ]
