#!/bin/bash
# Checks the doc-voice gate against the real offending doc (must speak), its
# plain rewrite (must stay quiet), and the scope rules.
H="$HOME/.claude/scripts/hooks/doc-voice-gate.py"
FIX="$HOME/.claude/assets/reports/20261019-reader-doc-fixture"
T=$(mktemp -d)
fail=0
run() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1" | DOC_VOICE_OFF=0 python3 "$H"; }
expect() {
  local name="$1" want="$2" got="$3"
  if [ "$want" = silent ]; then
    [ -z "$got" ] && echo "ok   $name" || { echo "FAIL $name: ${got:0:200}"; fail=1; }
  else
    printf '%s' "$got" | grep -q "$want" && echo "ok   $name" || { echo "FAIL $name: '${got:0:200}'"; fail=1; }
  fi
}
mkdir -p "$T/docs/plan" "$T/notes" "$T/proj/.claude/docs"
cp "$FIX/cprd-parity-before.md" "$T/docs/plan/before.md"
cp "$FIX/cprd-parity-after.md" "$T/docs/plan/after.md"
expect "the ledger-style doc is flagged" "internal ledger" "$(run "$T/docs/plan/before.md")"
expect "and asks for a reader line" "reader:" "$(run "$T/docs/plan/before.md")"
expect "the plain rewrite is quiet" silent "$(run "$T/docs/plan/after.md")"
cp "$FIX/cprd-parity-before.md" "$T/notes/before.md"
expect "outside docs/ with no reader is out of scope" silent "$(run "$T/notes/before.md")"
{ printf -- '---\nreader: CEO\n---\n'; cat "$FIX/cprd-parity-before.md"; } > "$T/notes/declared.md"
expect "a declared human reader brings it into scope" "internal ledger" "$(run "$T/notes/declared.md")"
{ printf -- '---\nreader: agent\n---\n'; cat "$FIX/cprd-parity-before.md"; } > "$T/docs/plan/agent.md"
expect "reader: agent is skipped" silent "$(run "$T/docs/plan/agent.md")"
cp "$FIX/cprd-parity-before.md" "$T/proj/.claude/docs/x.md"
expect "agent folders are skipped" silent "$(run "$T/proj/.claude/docs/x.md")"
{ printf 'Plain intro.\n\n## Sources\n'; cat "$FIX/cprd-parity-before.md" | grep -v '^#'; } > "$T/docs/plan/tail.md"
expect "ids inside a final Sources section do not count" silent "$(run "$T/docs/plan/tail.md")"
expect "enforce mode blocks" '"decision": "block"' "$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$T/docs/plan/before.md" | DOC_VOICE_ENFORCE=1 python3 "$H")"
trash "$T" 2>/dev/null
exit $fail
