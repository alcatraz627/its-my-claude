#!/usr/bin/env bash
# Tests for dense-briefing-shapes-stop.sh: shape 2 (reply restates a file written
# this turn) and shape 3 (done-claim skips the stated criterion) fire once in
# dry-run; a reply that leads with the path, or names the criterion, passes.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HOOK="$HERE/dense-briefing-shapes-stop.sh"
T=$(mktemp -d); export HOME="$T"; mkdir -p "$T/.claude/scripts/hooks"
printf '#!/usr/bin/env bash\nexit 0\n' > "$T/.claude/scripts/hooks/warn-log.sh"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
pad=$(printf 'filler sentence to reach the length floor. %.0s' $(seq 1 20))
tx() { # tx <file> <user text> <assistant text> [written md path]
  : > "$1"
  jq -cn --arg u "$2" '{type:"user", message:{role:"user", content:$u}}' >> "$1"
  if [ -n "${4:-}" ]; then
    jq -cn --arg p "$4" '{type:"assistant", message:{role:"assistant", content:[{type:"tool_use", name:"Write", input:{file_path:$p}}]}}' >> "$1"
    jq -cn '{type:"user", message:{role:"user", content:[{type:"tool_result", content:"ok"}]}}' >> "$1"
  fi
  jq -cn --arg a "$3" '{type:"assistant", message:{role:"assistant", content:[{type:"text", text:$a}]}}' >> "$1"
}
run() { jq -cn --arg tp "$1" --arg s "sess-$2" --argjson a "${3:-false}" '{transcript_path:$tp, session_id:$s, stop_hook_active:$a}' | bash "$HOOK" 2>/dev/null; }
rm -rf /tmp/claude-dense-shapes-sess-*

echo "== shape 2: the reply restates the file it just wrote =="
MD="$T/report.md"; printf '# Title\n\n## What the owner asked\n\ntext\n\n## The direct answer\n\ntext\n\n## The three decisions\n\ntext\n' > "$MD"
tx "$T/a.jsonl" "write it up" "Report written.

## What the owner asked
Four things. $pad

## The direct answer
It works. $pad

## The three decisions
Pick one." "$MD"
out=$(run "$T/a.jsonl" a1)
printf '%s' "$out" | rg -q 'shape 2' && ok "two repeated headings fire shape 2" || bad "shape 2 silent: $out"
printf '%s' "$out" | rg -q 'WOULD-BLOCK' && ok "dry-run tier by default" || bad "not dry-run"
out=$(run "$T/a.jsonl" a1); [ -z "$out" ] && ok "same reply fires once" || bad "fired twice"
rm -rf /tmp/claude-dense-shapes-sess-*
out=$(DENSE_SHAPES_ENFORCE=1 run "$T/a.jsonl" a2)
printf '%s' "$out" | rg -q '"decision":"block"' && ok "ENFORCE=1 blocks" || bad "enforce did not block"
tx "$T/b.jsonl" "write it up" "Written to $MD, one decision for you: keep or cut the smell panel. $pad $pad $pad" "$MD"
out=$(run "$T/b.jsonl" b1); [ -z "$out" ] && ok "path plus the one decision passes" || bad "lean reply flagged: $out"

echo "== shape 3: done-claim without the stated criterion =="
tx "$T/c.jsonl" "Fix the export. Make sure the spreadsheet keeps the leading zeros in the identifier column." "Done. The export is fixed and the suite is green. $pad $pad $pad"
out=$(run "$T/c.jsonl" c1)
printf '%s' "$out" | rg -q 'shape 3' && ok "done-claim that never mentions the criterion fires" || bad "shape 3 silent: $out"
tx "$T/d.jsonl" "Fix the export. Make sure the spreadsheet keeps the leading zeros in the identifier column." "Done. Leading zeros survive in the identifier column: opened the spreadsheet and read the cells. $pad $pad $pad"
out=$(run "$T/d.jsonl" d1); [ -z "$out" ] && ok "naming the criterion passes" || bad "criterion named but flagged: $out"
tx "$T/e.jsonl" "how does the export work?" "It streams rows. $pad $pad $pad"
out=$(run "$T/e.jsonl" e1); [ -z "$out" ] && ok "no criterion, no done-claim: silent" || bad "plain answer flagged"

echo "== harness and mute =="
out=$(run "$T/c.jsonl" f1 true); [ -z "$out" ] && ok "steps aside under stop_hook_active" || bad "fired under stop_hook_active"
touch "$T/.claude/.no-dense-shapes-gate"; rm -rf /tmp/claude-dense-shapes-sess-*
out=$(run "$T/c.jsonl" g1); [ -z "$out" ] && ok "mute file silences it" || bad "fired under mute"
rm -f "$T/.claude/.no-dense-shapes-gate"

echo "== MUTATION: without the heading match, shape 2 is a no-op =="
mkdir -p "$T/mut"; sed 's/if len(hit) >= 2:/if False:/' "$HERE/dense-briefing-shapes-stop.py" > "$T/mut/dense-briefing-shapes-stop.py"
M="$T/mut/dense-briefing-shapes-stop.sh"; cp "$HOOK" "$M"
rm -rf /tmp/claude-dense-shapes-sess-*
out=$(jq -cn --arg tp "$T/a.jsonl" '{transcript_path:$tp, session_id:"sess-m1", stop_hook_active:false}' | bash "$M" 2>/dev/null)
printf '%s' "$out" | rg -q 'shape 2' && bad "mutant still fires shape 2" || ok "mutant goes quiet, so the heading match is load-bearing"

echo "---- pass=$pass fail=$fail"; [ "$fail" -eq 0 ]
