#!/usr/bin/env bash
# Tests for guard-subagent-output.sh, focused on the sanctioned-inverse
# exemption added 2026-08-16 (task #39 / prop-20260722-220830-c9).
#
# The guard exists to catch material sub-agent work dispatched with no
# instruction to persist the output. It was ALSO firing on prompts that had
# already complied via the documented inverse: the sub-agent returns everything
# inline and the PARENT persists. Both halves are asserted here, because an
# exemption that also silences the real case is worse than the false fire it
# replaced.

set -uo pipefail

# Redirect the warn-log ledger so this suite never writes into the live audit
# file. Without it, test fires are indistinguishable from live ones, which is
# how 102 test events were read as live adherence data (audit 2026-08-18).
export WARN_LOG_STORE="$(mktemp "${TMPDIR:-/tmp}/warnlog-test-XXXXXX")"
cd "$(dirname "$0")" || exit 1

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok   $1"; }
bad() { fail=$((fail+1)); echo "  FAIL $1"; }

# expect <FIRES|SILENT> <label> <prompt>
expect() {
  local want="$1" label="$2" prompt="$3" out got
  out=$(jq -cn --arg p "$prompt" '{tool_name:"Agent",tool_input:{prompt:$p}}' \
        | bash ./guard-subagent-output.sh 2>/dev/null)
  got=SILENT; [ -n "$out" ] && got=FIRES
  [ "$got" = "$want" ] && ok "$label" || bad "$label (want $want, got $got)"
}

echo "== the sanctioned inverse: sub-agent inline, parent persists =="
# Heuristic 2 cannot read these. "persists" defeats \bpersist\b because the \b
# needs a non-word char and "s" is one; "will persist it" carries no
# to/into/at/disk/file within range. Both are correct instructions.
expect SILENT "parent persists to <path>" \
  "Audit the auth subsystem and produce a research analysis. Deliver EVERYTHING inline; the parent persists to /Users/x/report.md"
expect SILENT "return FULL text, parent will persist" \
  "Perform a design review of the schema. Return FULL text in your final message; the parent will persist it."
expect SILENT "inline delivery with no path named" \
  "Do a full research analysis of the caching layer. Deliver everything inline."

echo "== the gap the guard exists for must STILL fire =="
expect FIRES "material work, no persistence instruction at all" \
  "Research the caching layer and produce a full analysis of the tradeoffs."
expect FIRES "material work, only a vague report-back" \
  "Perform a thorough audit of the auth subsystem and report back on what you find."

echo "== the pre-existing compliant path is unaffected =="
expect SILENT "write to disk before returning" \
  "Research the caching layer and produce a full analysis. Write it to /tmp/out.md before returning."

echo "== non-material dispatches were never in scope =="
expect SILENT "a short mechanical ask" "List the files under scripts/hooks."

echo "== the mutes still work =="
out=$(jq -cn --arg p "Research the caching layer and produce a full analysis of the tradeoffs." \
      '{tool_name:"Agent",tool_input:{prompt:$p}}' \
      | SUBAGENT_OUTPUT_OFF=1 bash ./guard-subagent-output.sh 2>/dev/null)
[ -z "$out" ] && ok "SUBAGENT_OUTPUT_OFF=1 silences it" || bad "env mute ignored"

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
