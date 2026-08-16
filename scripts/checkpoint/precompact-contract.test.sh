#!/usr/bin/env bash
# Tests that pre-compact-checkpoint.sh emits a file /catchup can actually parse
# (task #37 / D13, part 1).
#
# The defect: the PreCompact writer emitted Session Stats, User Goals, Working
# Directory and Recovery Sequence, and NONE of the four headings
# validate-checkpoint.sh requires. /catchup Phase 0.2 reaches for the precompact
# file first on a post-compact resume, so every one of those resumes hit a FAIL
# and degraded to a partial read. Nothing failed loudly, which is why it survived.

set -uo pipefail
WRITER="$HOME/.claude/scripts/session-mgmt/pre-compact-checkpoint.sh"
VALIDATE="$HOME/.claude/scripts/checkpoint/validate-checkpoint.sh"

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok   $1"; }
bad() { fail=$((fail+1)); echo "  FAIL $1"; }

# write <sid8> [with-todos] -> path to the generated checkpoint
write_cp() {
  local sid8="$1" todos="${2:-}" t
  t=$(mktemp -d)
  if [ -n "$todos" ]; then
    mkdir -p "$t/.claude/scratchpad"
    printf -- '- [ ] finish the sweep\n- [ ] verify the gate\n' > "$t/.claude/scratchpad/plan.md"
    printf '#1 [pending] do the thing\n#2 [in_progress] the other thing\n' > "/tmp/claude-tasks-${sid8}"
  fi
  jq -cn --arg c "$t" --arg s "${sid8}-1111-2222-3333-444455556666" \
    '{session_id:$s,trigger:"manual",cwd:$c}' | bash "$WRITER" >/dev/null 2>&1
  rm -f "/tmp/claude-tasks-${sid8}" 2>/dev/null || true
  printf '%s' "$t/_precompact-checkpoint.claude.md"
}

echo "== the parse contract, with todos present =="
F=$(write_cp aaa11111 yes)
if [ -f "$F" ]; then ok "the writer produced a file"; else bad "no file written"; fi
bash "$VALIDATE" "$F" >/dev/null 2>&1 \
  && ok "validate-checkpoint accepts it" \
  || bad "still breaks the /catchup parse contract"

for h in "Initial Goal" "Agent Actions" "Current Expectation" "Pending Items"; do
  rg -q "^## ${h}\$" "$F" && ok "emits ## ${h}" || bad "missing ## ${h}"
done

echo "== Pending Items carries content, not just a heading =="
body=$(awk '/^## Pending Items/{f=1;next} /^## /{f=0} f' "$F")
printf '%s' "$body" | rg -q 'do the thing' \
  && ok "the live Task list reaches Pending Items" \
  || bad "Pending Items heading exists but the task list is not in it"
printf '%s' "$body" | rg -q 'finish the sweep' \
  && ok "workspace todos reach Pending Items" \
  || bad "workspace todos missing from Pending Items"

echo "== an empty queue is a legitimate state, and must not break the contract =="
E=$(write_cp bbb22222)
bash "$VALIDATE" "$E" >/dev/null 2>&1 \
  && ok "validates with no tasks and no todos" \
  || bad "empty queue breaks the contract"
awk '/^## Pending Items/{f=1;next} /^## /{f=0} f' "$E" | rg -q 'no tasks or workspace todos' \
  && ok "says so explicitly rather than emitting an empty section" \
  || bad "empty Pending Items has no placeholder"

echo "== no duplicate todo sections (they were folded into Pending Items) =="
n=$(rg -c '^## (Session Todos|Agent Tasks)' "$F" 2>/dev/null || echo 0)
[ "$n" = 0 ] && ok "the old Session Todos / Agent Tasks H2s are gone" \
             || bad "todo lists are emitted twice"

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
