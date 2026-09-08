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

echo "== the pointer stays on a real core-dump at any age (ledger 4) =="
t=$(mktemp -d)
printf '# Core Dump\n## Initial Goal\nx\n' > "$t/_20260906-real.claude.md"
touch -t "$(date -v-11H +%Y%m%d%H%M)" "$t/_20260906-real.claude.md"
ln -s "_20260906-real.claude.md" "$t/_checkpoint.claude.md"
jq -cn --arg c "$t" '{session_id:"ccc33333-1111-2222-3333-444455556666",trigger:"session-end",cwd:$c}' | bash "$WRITER" >/dev/null 2>&1
[ "$(readlink "$t/_checkpoint.claude.md")" = "_20260906-real.claude.md" ] \
  && ok "an 11-hour-old core-dump keeps the pointer" \
  || bad "the stub took the pointer from a core-dump"
[ -f "$t/_precompact-checkpoint.claude.md" ] && ok "the stub is still written by its own name" || bad "no stub written"
ln -sf "_gone.claude.md" "$t/_checkpoint.claude.md"
jq -cn --arg c "$t" '{session_id:"ccc33333-1111-2222-3333-444455556666",trigger:"manual",cwd:$c}' | bash "$WRITER" >/dev/null 2>&1
[ "$(readlink "$t/_checkpoint.claude.md")" = "_precompact-checkpoint.claude.md" ] \
  && ok "a dangling pointer is retargeted" \
  || bad "dangling pointer left dangling"

echo "== another session's _active.md is not folded in as ours =="
t=$(mktemp -d); mkdir -p "$t/.claude/session-notes"
printf '## Todos\n- [x] june thing done\n' > "$t/.claude/session-notes/june-session.md"
ln -s "june-session.md" "$t/.claude/session-notes/_active.md"
jq -cn --arg c "$t" '{session_id:"ddd44444-1111-2222-3333-444455556666",trigger:"manual",cwd:$c}' | bash "$WRITER" >/dev/null 2>&1
F="$t/_precompact-checkpoint.claude.md"
rg -q 'june thing done' "$F" && bad "a foreign session's todos landed in the snapshot" || ok "foreign _active.md content excluded"
rg -q "not this session's doc" "$F" && ok "the snapshot says why the workspace block is absent" || bad "no explanation for the missing workspace block"
ln -sf "ddd44444-1111-2222-3333-444455556666.md" "$t/.claude/session-notes/_active.md"
printf '## Todos\n- [ ] mine\n' > "$t/.claude/session-notes/ddd44444-1111-2222-3333-444455556666.md"
jq -cn --arg c "$t" '{session_id:"ddd44444-1111-2222-3333-444455556666",trigger:"manual",cwd:$c}' | bash "$WRITER" >/dev/null 2>&1
rg -q '\[ \] mine' "$F" && ok "own _active.md still folded in" || bad "own doc dropped"

echo "== the session-end kind is accepted by the index writer =="
S=$(mktemp -d); mkdir -p "$S/.claude"
HOME="$S" bash "$HOME/.claude/scripts/checkpoint/write.sh" --session-id eee55555 --project-root "$S" \
  --checkpoint-path "$S/_precompact-checkpoint.claude.md" --kind session-end --name se >/dev/null 2>&1
rg -q '"kind": *"session-end"' "$S/.claude/checkpoints/index.jsonl" 2>/dev/null \
  && ok "write.sh indexes kind=session-end (it was 'invalid --kind' before)" \
  || bad "session-end snapshots are still never indexed"

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
