#!/usr/bin/env bash
# Tests for hand-rendered-tasks-stop.sh: a hand-painted task table warns; a
# fenced /tasks render, a turn that ran the tool, and plain prose stay quiet.
set -uo pipefail
HOOK="$HOME/.claude/scripts/hooks/hand-rendered-tasks-stop.sh"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/handtasks-XXXXXX")
trap 'trash "$TMP" 2>/dev/null || rm -rf "$TMP"' EXIT
pass=0; fail=0
ok(){ echo "  ok    $1"; pass=$((pass+1)); }
bad(){ echo "  FAIL  $1"; fail=$((fail+1)); }

# Build a transcript: one user turn, then assistant turns from JSON fragments.
# Args: <file> <user-text> then pairs of TYPE:PAYLOAD where TYPE is text|tool.
mk(){ python3 - "$@" <<'PY'
import json, sys
f = sys.argv[1]; user = sys.argv[2]; rest = sys.argv[3:]
lines = [json.dumps({"type": "user", "message": {"content": [{"type": "text", "text": user}]}})]
i = 0
while i < len(rest):
    kind, payload = rest[i].split(":", 1); i += 1
    if kind == "text":
        blk = {"type": "text", "text": payload}
    else:  # tool:NAME=CMD
        name, cmd = payload.split("=", 1)
        blk = {"type": "tool_use", "name": name, "input": {"command": cmd}}
    lines.append(json.dumps({"type": "assistant", "message": {"content": [blk]}}))
open(f, "w").write("\n".join(lines) + "\n")
PY
}

run(){ # <transcript> <sid> -> prints hook stdout
  printf '{"session_id":"%s","transcript_path":"%s"}' "$2" "$1" | bash "$HOOK" 2>/dev/null
}

# 1. hand-rendered markdown table, no tool call -> WARN
T1="$TMP/t1.jsonl"
mk "$T1" "what's pending on me?" \
  "text:Here's what is open:

| id | subject | state |
|---|---|---|
| #11 | the audit | pending |
| #12 | acceptance block | pending |

That's the queue."
o1=$(run "$T1" "sess-aaaa1111-0000-0000-0000-000000000001")
printf '%s' "$o1" | rg -q "hand-rendered task table" && ok "hand-rendered md table warns" || bad "hand-rendered md table should warn"

# 2. same table but inside a code fence -> QUIET (ruled shape)
T2="$TMP/t2.jsonl"
mk "$T2" "show me /tasks" \
  "text:Here it is:

\`\`\`
| #11 | the audit | pending |
| #12 | acceptance block | pending |
\`\`\`

done."
o2=$(run "$T2" "sess-bbbb2222-0000-0000-0000-000000000002")
[ -z "$o2" ] && ok "fenced table is exempt" || bad "fenced table should be exempt (got output)"

# 3. hand table BUT the turn ran task-table.sh -> QUIET (tool consulted)
T3="$TMP/t3.jsonl"
mk "$T3" "what's left?" \
  "tool:Bash=bash ~/.claude/scripts/task-table/task-table.sh --session 231496bc" \
  "text:| #11 | the audit | pending |
| #12 | acceptance block | pending |"
o3=$(run "$T3" "sess-cccc3333-0000-0000-0000-000000000003")
[ -z "$o3" ] && ok "tool-consulted turn is exempt" || bad "tool-consulted turn should be exempt"

# 4. loose #N list of three, no tool -> WARN
T4="$TMP/t4.jsonl"
mk "$T4" "list my tasks" \
  "text:Your open items:
#11 the audit
#12 the acceptance block
#13 the plane-2 hook
those are next."
o4=$(run "$T4" "sess-dddd4444-0000-0000-0000-000000000004")
printf '%s' "$o4" | rg -q "hand-rendered task table" && ok "loose #N list warns" || bad "loose #N list should warn"

# 5. plain prose, one glossed id -> QUIET (the gloss rule is satisfied)
T5="$TMP/t5.jsonl"
mk "$T5" "what next?" \
  "text:Next I'd start #11, the /tasks failure-mode audit, since it is briefed and ready."
o5=$(run "$T5" "sess-eeee5555-0000-0000-0000-000000000005")
[ -z "$o5" ] && ok "prose with one glossed id is quiet" || bad "single glossed id should be quiet"

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
