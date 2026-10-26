#!/usr/bin/env bash
# Tests for creation-box-stop.py on synthetic transcripts.
#   bash ~/.claude/scripts/hooks/creation-box-stop.test.sh
set -uo pipefail
H="$HOME/.claude/scripts/hooks/creation-box-stop.py"
T=$(mktemp -d); export CREATION_BOX_STATE="$T"
pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }

# transcript <file> <command> <tool output> <final reply>
transcript() {
  python3 - "$@" <<'PY'
import json, sys
f, cmd, out, reply = sys.argv[1:5]
rows = [
  {"type": "user", "message": {"role": "user", "content": "do the thing"}},
  {"type": "assistant", "message": {"content": [{"type": "tool_use", "id": "t1", "name": "Bash", "input": {"command": cmd}}]}},
  {"type": "user", "message": {"content": [{"type": "tool_result", "tool_use_id": "t1", "content": out}]}},
  {"type": "assistant", "message": {"content": [{"type": "text", "text": reply}]}},
]
open(f, "w").write("\n".join(json.dumps(r) for r in rows) + "\n")
PY
}
run() { printf '{"session_id":"%s","transcript_path":"%s"}' "$1" "$2" | python3 "$H"; }

ID="mist-20261026-101010-ab"
transcript "$T/a.jsonl" "bash ~/.claude/scripts/atone.sh add --slug x" "recorded $ID" "Logged it as $ID."
out=$(run s1 "$T/a.jsonl")
case "$out" in *'"decision": "block"'*) ok "an atone named in prose but not boxed blocks" ;; *) ko "no block: $out" ;; esac
case "$out" in *"$ID"*) ok "the block names the id" ;; *) ko "id missing: $out" ;; esac
out=$(run s1 "$T/a.jsonl")
case "$out" in *systemMessage*) ok "the same reply a second time is only a note" ;; *) ko "blocked twice: $out" ;; esac

transcript "$T/b.jsonl" "bash ~/.claude/scripts/atone.sh add --slug x" "recorded $ID" "$(printf '┌─ 🙏 atone · x ──\n│ %s · S2\n└──' "$ID")"
out=$(run s2 "$T/b.jsonl"); [ -z "$out" ] && ok "a boxed atone with its id passes" || ko "boxed reply blocked: $out"

transcript "$T/c.jsonl" "bash ~/.claude/scripts/propose.sh show prop-20261026-101010-cd" "prop-20261026-101010-cd ..." "It says this."
out=$(run s3 "$T/c.jsonl"); [ -z "$out" ] && ok "reading a proposal is not a creation" || ko "read blocked: $out"

P="prop-20261026-111111-ef"
transcript "$T/d.jsonl" "bash ~/.claude/scripts/propose.sh add --title t" "filed $P" "$(printf '┌─ 🏁 done · filed ──\n│ something else\n└──')"
out=$(run s4 "$T/d.jsonl")
case "$out" in *'"decision": "block"'*) ok "a box that leaves out the new id still blocks" ;; *) ko "no block: $out" ;; esac

transcript "$T/e.jsonl" "i-dream pin add --from-json -" "pinned pin-20261026101010-7e" "Pinned."
out=$(run s5 "$T/e.jsonl")
case "$out" in *pin-20261026101010-7e*) ok "a pin is a creation too" ;; *) ko "pin missed: $out" ;; esac

touch "$T/mute"; out=$(CREATION_BOX_GATE_OFF=1 run s6 "$T/a.jsonl"); [ -z "$out" ] && ok "the off switch silences it" || ko "off switch ignored"
[ -s "$T/creation-box-gate.jsonl" ] && ok "blocks are logged" || ko "no telemetry"

trash "$T" >/dev/null 2>&1
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
