#!/usr/bin/env bash
# Tests for relpath-stop.sh (task #29 / D1).
#
# Every exemption the hook's header CLAIMS gets a row here. A hook that documents
# an exemption it does not have is worse than one with no exemptions, because the
# next reader trusts the comment instead of the code.

set -uo pipefail
cd "$(dirname "$0")" || exit 1

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok   $1"; }
bad() { fail=$((fail+1)); echo "  FAIL $1"; }

# run <message-text> [sid] -> WARN | SILENT
run() {
  local txt="$1" sid="${2:-relp$RANDOM}" t tp out
  t=$(mktemp -d); tp="$t/transcript.jsonl"
  jq -cn --arg x "$txt" '{type:"assistant",message:{content:[{type:"text",text:$x}]}}' > "$tp"
  out=$(jq -cn --arg s "$sid" --arg p "$tp" '{session_id:$s,transcript_path:$p}' \
        | bash relpath-stop.sh 2>/dev/null)
  rm -rf "$t"
  printf '%s' "$out" | grep -q systemMessage && echo WARN || echo SILENT
}

expect() { # expect <want> <label> <text>
  local got; got=$(run "$3")
  [ "$got" = "$1" ] && ok "$2" || bad "$2 (want $1, got $got)"
}

echo "== it fires on the real shape =="
expect WARN "a report handed over by repo-relative path" \
  'The full writeup is in assets/reports/20260816-sweep/report.md and covers all four.'
expect WARN "the .claude/output root" \
  'Findings landed in .claude/output/20260816-audit/findings.md for review.'
expect WARN "the docs root" \
  'I updated docs/architecture/overview.md with the new flow.'

echo "== exemptions the header claims =="
expect SILENT "absolute path" \
  'The full writeup is in /Users/alcatraz627/.claude/assets/reports/20260816-sweep/report.md now.'
expect SILENT "tilde path" \
  'See ~/.claude/docs/architecture/overview.md for the flow.'
expect SILENT "dot-slash path" \
  'See ./docs/architecture/overview.md for the flow.'
expect SILENT "file:line code reference" \
  'The guard lives at docs/notes/design.md:42 if you want the rationale.'
expect SILENT "inside a fenced block" \
  'Run this:
```
cat assets/reports/20260816-sweep/report.md
```
That prints it.'
expect SILENT "command position" \
  'Run cat docs/architecture/overview.md to see the flow.'
expect SILENT "absolute form present in the same message" \
  'Wrote /Users/alcatraz627/.claude/docs/architecture/overview.md — after that, docs/architecture/overview.md holds the flow.'

echo "== narrowness is the FP tuning: ordinary repo talk must not fire =="
expect SILENT "relative source path outside the deliverable roots" \
  'The change is in scripts/hooks/relpath-stop.sh and its suite.'
expect SILENT "a bare directory with no file" \
  'Everything under assets/ is generated, so do not hand-edit it.'
expect SILENT "no path at all" \
  'All nine suites are green and nothing is committed yet.'

echo "== loop safety =="
SID="loopsid1"
a=$(run 'The writeup is in assets/reports/20260816-sweep/report.md now.' "$SID")
b=$(run 'The writeup is in assets/reports/20260816-sweep/report.md now.' "$SID")
[ "$a" = WARN ] && [ "$b" = SILENT ] \
  && ok "warns once, then steps aside on the identical message" \
  || bad "loop safety broken (first=$a second=$b)"
rm -f "/tmp/claude-relpath-${SID}" 2>/dev/null || true

echo "== the mute is honoured =="
MUTE="$HOME/.claude/.no-relpath-gate"; had=0; [ -f "$MUTE" ] && had=1
touch "$MUTE"
g=$(run 'The writeup is in assets/reports/20260816-sweep/report.md now.')
[ "$had" = 1 ] || rm -f "$MUTE"
[ "$g" = SILENT ] && ok "silent while ~/.claude/.no-relpath-gate exists" \
                  || bad "mute file did not stop the hook"

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
