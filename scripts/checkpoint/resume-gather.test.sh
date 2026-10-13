#!/usr/bin/env bash
# Tests for resume-gather.sh. Everything runs on temp fixtures: a fake HOME, a
# throwaway git repo, and stub claude-ipc / gh / left.py / shell-mem, so the
# owner's real index, nonce files and mailbox are never touched.
#
# RG_DIR points the tests at another copy of the scripts; that is how each
# guard is mutation-tested (copy, break the guard, expect red).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
RG_DIR="${RG_DIR:-$HERE}"
RG="$RG_DIR/resume-gather.sh"
T=$(mktemp -d)
mkdir -p "$T/.claude/checkpoints" "$T/bin" "$T/repo" "$T/proj"
pass=0; fail=0; total=0
ok()  { pass=$((pass+1)); total=$((total+1)); echo "  PASS  $1"; }
bad() { fail=$((fail+1)); total=$((total+1)); echo "  FAIL  $1"; }
has() { case "$OUT" in *"$1"*) return 0 ;; esac; return 1; }
expect()     { if has "$2"; then ok "$1"; else bad "$1 (missing: $2)"; fi; }
expect_not() { if has "$2"; then bad "$1 (found: $2)"; else ok "$1"; fi; }

# A repo with two commits on feat/x and a GitHub-looking origin.
git -C "$T/repo" init -q -b feat/x
git -C "$T/repo" config user.email t@example.com
git -C "$T/repo" config user.name tester
git -C "$T/repo" remote add origin https://github.com/acme/repo.git
echo one > "$T/repo/f"; git -C "$T/repo" add f; git -C "$T/repo" commit -q -m "first"
SHA1=$(git -C "$T/repo" rev-parse --short HEAD)
echo two > "$T/repo/f"; git -C "$T/repo" commit -q -am "second"
SHA2=$(git -C "$T/repo" rev-parse --short HEAD)

# Stubs for the outside world.
cat > "$T/bin/claude-ipc" <<'EOF'
#!/usr/bin/env bash
echo "$@ [self=${CLAUDE_CODE_SESSION_ID:-}]" >> "$RG_TEST_DIR/ipc.log"
[ -f "$RG_TEST_DIR/ipc-down" ] && { echo "broker down" >&2; exit 1; }
case "$1" in
  who) cat "$RG_TEST_DIR/ipc-who.json" ;;
  register) exit 0 ;;
  count) echo 3 ;;
  inbox) echo '{"messages":[{"id":"m1"},{"id":"m2"}]}' ;;
esac
EOF
cat > "$T/bin/gh" <<'EOF'
#!/usr/bin/env bash
[ "$1" = "--version" ] && { echo "gh stub"; exit 0; }
n="$3"
[ -f "$RG_TEST_DIR/gh-$n.json" ] && { cat "$RG_TEST_DIR/gh-$n.json"; exit 0; }
echo "no such PR" >&2; exit 1
EOF
cat > "$T/bin/left.py" <<'EOF'
#!/usr/bin/env python3
import json, sys
if "--json" in sys.argv:
    print(json.dumps({"id": "abc123", "tasks": [
        {"id": "7", "subject": "ship the parser", "state": "ready", "gate": None},
        {"id": "8", "subject": "approve the vendor", "state": "owner-gate", "gate": {"text": "USER: approve", "do": "say yes or no"}},
        {"id": "9", "subject": "old thing", "state": "done", "gate": None}],
        "effective": {"7": "ready", "8": "owner-gate", "9": "done"}}))
else:
    print("LEFT  abc123")
    print("  \U0001F534 = #8   approve the vendor")
EOF
cat > "$T/bin/shell-mem.sh" <<'EOF'
#!/usr/bin/env bash
echo "- [10:00:00] [sid:aaaaaaaa-1111] \`npm run dev --prefix $RG_TEST_DIR/proj\` [BG] [est:1h]"
echo "- [10:05:00] [sid:bbbbbbbb-2222] \`python other-project/server.py\` [BG] [est:5m]"
EOF
chmod +x "$T/bin/"*
echo '{"matches":[]}' > "$T/ipc-who.json"
echo '{"state":"OPEN","isDraft":false,"title":"Add the parser","headRefOid":"deadbeef00000000000000000000000000000000"}' > "$T/gh-12.json"

export HOME="$T" RG_TEST_DIR="$T" RG_IPC="$T/bin/claude-ipc" RG_GH="$T/bin/gh" \
       RG_LEFT="$T/bin/left.py" RG_SHELL_MEM="$T/bin/shell-mem.sh"
unset CLAUDE_CODE_SESSION_ID

fill() { # fill <file>: replace the @TOKENS@ with this run's paths
  sed -e "s|@REPO@|$T/repo|g" -e "s|@T@|$T|g" -e "s|@SHA1@|$SHA1|g" -e "s|@SHA2@|$SHA2|g" "$1" > "$1.tmp" && mv -f "$1.tmp" "$1"
}
gather() { OUT=$(bash "$RG" "$@" 2>&1); RC=$?; }

# ---- new-field checkpoint
CK="$T/proj/_20261013-new.claude.md"
cat > "$CK" <<'EOF'
# Core Dump, 2026-10-13T10:00+05:30

## Resume Contract

- **Standing constraints:** "never merge" · keep it small
- **Standing caveats:** (1) one caveat
- **Next action:** Wire the parser into the gather script and run its tests.
- **Next action's requirements:** @REPO@/f
- **Blocked on:** USER: approve the merge of the release; pick a vendor. AGENT: none.
- **Standing authorizations:** "push feat/x once" (2026-10-13 09:00) · target: repo/feat/x @@SHA2@ · one-shot · "merge the release" (2026-10-13 09:05) · target: repo/feat/x @@SHA1@ · one-shot · UNVERIFIED: "deploy it" (2026-10-13 09:10) · target: repo @@SHA2@ · standing
- **Pending approval codes:** repo/main · nonce abc123
- **Decaying prerequisites:** server on :9999 · fix: touch @T@/FIX_RAN · check: test -f @T@/check-ok · cache warm · fix: touch @T@/FIX2_RAN · check: test -f @T@/missing-file · no probe here · fix: touch @T@/FIX3_RAN
- **Verification state:** parser tests 4 passed · gather run once
- **Goal record:** abc123
- **ipc alias:** my-alias
- **Key files:** @REPO@/f
- **Atone this session:** none
- **Rulings this session:** none

## Initial Goal

Build the thing.

## Agent Actions

1. Wrote the parser in `@REPO@/f`.
2. Ran its tests.

## Current Expectation

Owner reviews.

## Pending Items

- Agent: finish the wiring for PR #12.
- Owner: pick a vendor.

## Session Insights

- none
EOF
fill "$CK"
touch "$T/check-ok"
# Working surface sits above the contract in real dumps
{ printf '**Working surface:** worktree `%s` on `feat/x`.\n\n' "$T/repo"; cat "$CK"; } > "$CK.tmp" && mv -f "$CK.tmp" "$CK"

echo "== new-field checkpoint =="
gather "$CK" --no-ipc --session-id sess-new --self-uuid sess-new
[ "$RC" = 0 ] && ok "exits 0" || bad "exit $RC"
expect "names the checkpoint" "checkpoint: $CK"
expect "validates the checkpoint" "validate: valid"
expect "done list carries the agent actions" "Ran its tests."
expect "pending on agent lists the agent bullet" "Agent: finish the wiring for PR #12."
expect "pending on agent includes a goal row not gated" "#7 ship the parser"
expect "pending on owner lists the blocked-on items" "approve the merge of the release"
expect "pending on owner includes the gated goal row" "#8 approve the vendor: say yes or no"
expect_not "an owner bullet already in Blocked on is not repeated" "Owner: pick a vendor."
expect "continue is yes when AGENT: none" "continue: yes"
expect "drift matches the claimed branch" "feat/x (matches claim)"
expect "drift counts commits" "dirty 0"
expect "PR looked up in the repo's GitHub slug" "PR #12 in acme/repo: OPEN"
expect "the goal record view is shown" "LEFT  abc123"
expect "owner-gated goal rows are marked in the view" "[OWNER]"
expect "owner-gated summary line" "owner-gated rows: #8"
expect "standing auth that still matches" "target now: matches"
expect "standing auth that moved" "moved (1 commit(s) since @$SHA1"
expect "UNVERIFIED auth is not actionable" "NOT ACTIONABLE (UNVERIFIED)"
expect "pending code from the old session" "repo/main -> nonce abc123"
expect "no nonce file for this session: re-issue hint" "re-issue: re-run repo/main's push once"
expect "shell shows this project's job" "npm run dev"
expect_not "shell hides other projects' jobs" "other-project/server.py"
expect "shell says how many were hidden" "1 active background command(s) from other projects hidden"

echo "== decaying prerequisites: only check: commands run =="
expect "passing check" "pass  server on :9999"
expect "failing check" "FAIL rc=1  cache warm"
expect "entry without a check is listed, not run" "not run (no check: command)  no probe here"
[ ! -e "$T/FIX_RAN" ] && [ ! -e "$T/FIX2_RAN" ] && [ ! -e "$T/FIX3_RAN" ] && ok "no fix command was executed" || bad "a fix command ran"

echo "== check timeout =="
CKT="$T/proj/_20261013-slow.claude.md"
cat > "$CKT" <<'EOF'
# Core Dump, 2026-10-13T10:00+05:30

## Resume Contract

- **Next action:** do the thing
- **Blocked on:** AGENT: none
- **Decaying prerequisites:** slow probe · check: pgrep -f anything

## Initial Goal

g

## Agent Actions

1. a

## Current Expectation

e

## Pending Items

- p
EOF
printf '#!/usr/bin/env bash\nsleep 25\n' > "$T/bin/pgrep"; chmod +x "$T/bin/pgrep"
t0=$(date +%s); PATH="$T/bin:$PATH" gather "$CKT" --no-ipc --session-id s; t1=$(date +%s)
expect "a hung check is cut off" "TIMEOUT 10s  slow probe"
[ $((t1 - t0)) -lt 18 ] && ok "whole run stayed under 18s with a 25s check" || bad "run took $((t1 - t0))s"

echo "== ipc =="
: > "$T/ipc.log"
gather "$CK" --no-ipc --session-id sess-new --self-uuid sess-new
if rg -q '^register' "$T/ipc.log"; then bad "--no-ipc still registered"; else ok "--no-ipc never calls register"; fi
expect "inbox counts are read" "predecessor's inbox (my-alias): 3 pending"
expect "project mailbox is read" "project mailbox: 2 message(s)"
: > "$T/ipc.log"
gather "$CK" --self-uuid sess-new
if rg -q '^register my-alias' "$T/ipc.log"; then ok "registers the checkpoint's alias when it is free"; else bad "no register call: $(cat "$T/ipc.log")"; fi
expect "reports the registration" "registered as my-alias"
echo '{"matches":[{"alias":"my-alias","sessionId":"other-live","status":"live","sessionAliases":["my-alias"]}]}' > "$T/ipc-who.json"
: > "$T/ipc.log"
gather "$CK" --self-uuid sess-new
if rg -q '^register my-alias' "$T/ipc.log"; then bad "took over a live session's alias"; else ok "does not take over an alias a live session holds"; fi
expect "falls back to this session's own id" "registered as sess-new"
echo '{"matches":[]}' > "$T/ipc-who.json"

echo "== a pending nonce for this session =="
printf '{"nonce":"f00dcafe","target":"repo main","why":"x","ts":1}' > "$T/.claude/.push-nonce-sess-new"
gather "$CK" --no-ipc --self-uuid sess-new
expect "reports this session's nonce" "pending nonce: f00dcafe"
trash "$T/.claude/.push-nonce-sess-new"

echo "== --session-id names the checkpoint; this session's identity is its own uuid =="
echo '{"matches":[]}' > "$T/ipc-who.json"
printf '{"nonce":"a11ce000","target":"repo main","why":"x","ts":1}' > "$T/.claude/.push-nonce-sess-pred"
printf '{"nonce":"11feed00","target":"repo main","why":"x","ts":1}' > "$T/.claude/.push-nonce-live-uuid"
: > "$T/ipc.log"
CLAUDE_CODE_SESSION_ID=live-uuid gather "$CK" --session-id sess-pred
if rg -q 'register my-alias \[self=live-uuid\]' "$T/ipc.log"; then ok "registers under the live session's uuid"; else bad "register call: $(cat "$T/ipc.log")"; fi
if rg -q 'sess-pred' "$T/ipc.log"; then bad "the predecessor's name leaked into an ipc call"; else ok "the --session-id value is never used as this session's identity"; fi
expect "the nonce read is the live session's file" "pending nonce: 11feed00"
expect_not "and not the predecessor's" "a11ce000"
echo '{"matches":[{"alias":"my-alias","sessionId":"other-live","status":"live","sessionAliases":["my-alias"]}]}' > "$T/ipc-who.json"
CLAUDE_CODE_SESSION_ID=live-uuid gather "$CK" --session-id sess-pred
expect "the fallback registers the live uuid" "registered as live-uuid"
expect_not "and never the predecessor's name" "registered as sess-pred"
echo '{"matches":[]}' > "$T/ipc-who.json"
: > "$T/ipc.log"
gather "$CK" --session-id sess-pred
if rg -q '^register' "$T/ipc.log"; then bad "registered with no identity of its own: $(cat "$T/ipc.log")"; else ok "with no identity of its own it does not register at all"; fi
trash "$T/.claude/.push-nonce-sess-pred" "$T/.claude/.push-nonce-live-uuid"

echo "== standing authorizations: only a full, verified grant is actionable =="
CKG="$T/proj/_20261013-grants.claude.md"
sed -e 's|^- \*\*Standing authorizations:\*\*.*|- **Standing authorizations:** "push feat/x once" (2026-10-13 09:00) · target: repo/feat/x @@SHA2@ · one-shot · "deploy everything to production" · target: app/prod @abc1234 · standing · "merge the release now" (2026-10-13 09:05) · one-shot · "restart the nightly job" (2026-10-13 09:06) · target: ops/cron · always|' "$CK" > "$CKG"
fill "$CKG"
gather "$CKG" --no-ipc
expect "a full grant is actionable (it gets a target now)" "push feat/x once"
expect "a dateless entry is NOT ACTIONABLE" 'NOT ACTIONABLE (not a full grant: needs "words" (date) · target: … · one-shot|standing): "deploy everything to production"'
expect "an entry with no target is NOT ACTIONABLE" 'NOT ACTIONABLE (not a full grant: needs "words" (date) · target: … · one-shot|standing): "merge the release now"'
expect "an entry with no one-shot or standing is NOT ACTIONABLE" 'NOT ACTIONABLE (not a full grant: needs "words" (date) · target: … · one-shot|standing): "restart the nightly job"'
N_TARGET=$(printf '%s\n' "$OUT" | rg -c 'target now:' || true)
[ "$N_TARGET" = 1 ] && ok "exactly one grant reached the target-now check" || bad "target now appeared $N_TARGET times"

echo "== check: commands run only when they are read-only =="
CKC="$T/proj/_20261013-allow.claude.md"
cat > "$CKC" <<'CKEOF'
# Core Dump, 2026-10-13T10:00+05:30

## Resume Contract

- **Next action:** do the thing
- **Blocked on:** AGENT: none
- **Decaying prerequisites:** pA · check: touch @T@/SIDE_A · pB · check: test -f @T@/check-ok && touch @T@/SIDE_B · pC · check: curl -X POST http://127.0.0.1:9/ · pD · check: ls $(touch @T@/SIDE_D) · pE · check: pm2 delete everything · pF · check: git log --output=@T@/SIDE_F · pG · check: ls @T@ · pH · check: curl -s -o /dev/null http://127.0.0.1:9/ · pI · check: curl -s -o @T@/SIDE_I http://127.0.0.1:9/ · pJ · check: test -f @T@/check-ok · pK · check: nc -z -e /bin/sh 127.0.0.1 9 · pL · check: curl -sd x=1 http://127.0.0.1:9/ · pM · check: touch @T@/SIDE_M > /dev/null

## Initial Goal

g

## Agent Actions

1. a

## Current Expectation

e

## Pending Items

- p
CKEOF
fill "$CKC"
gather "$CKC" --no-ipc --session-id s
expect "a touch is refused" "not run (not a read-only check; fix it by hand: touch $T/SIDE_A)"
expect "a chained touch is refused" "fix it by hand: test -f $T/check-ok && touch"
expect "curl -X is refused" "fix it by hand: curl -X POST"
expect "a command substitution is refused" "fix it by hand: ls \$(touch"
expect "pm2 delete is refused" "fix it by hand: pm2 delete everything"
expect "git log --output is refused" "fix it by hand: git log --output="
expect "curl writing to a file is refused" "fix it by hand: curl -s -o $T/SIDE_I"
expect "nc -e is refused" "fix it by hand: nc -z -e"
expect "curl with a body is refused" "fix it by hand: curl -sd x=1"
expect "a redirect is refused" "fix it by hand: touch $T/SIDE_M > /dev/null"
expect "ls runs" "pass  pG"
expect "test runs" "pass  pJ"
expect "curl -o /dev/null runs (and its refused connection is a FAIL, not a refusal)" "FAIL rc=7  pH"
[ ! -e "$T/SIDE_A" ] && [ ! -e "$T/SIDE_B" ] && [ ! -e "$T/SIDE_D" ] && [ ! -e "$T/SIDE_F" ] && [ ! -e "$T/SIDE_I" ] && [ ! -e "$T/SIDE_M" ] \
  && ok "none of the refused commands left a trace" || bad "a refused check ran: $(ls "$T" | rg SIDE | tr '\n' ' ')"

echo "== legacy checkpoint: Expired authorizations, no Key files, no Pending approval codes =="
CKL="$T/proj/_20261013-legacy.claude.md"
cat > "$CKL" <<'EOF'
# Core Dump, 2026-10-01T10:00+05:30

## Resume Contract

- **Standing constraints:** none
- **Next action:** keep going
- **Blocked on:** none
- **Expired authorizations:** every push and deploy needs fresh confirmation.
- **Decaying prerequisites:** none
- **Task store:** none

## Initial Goal

g

## Agent Actions

1. a

## Current Expectation

e

## Pending Items

- Agent: p
EOF
gather "$CKL" --no-ipc --session-id s
[ "$RC" = 0 ] && ok "exits 0" || bad "exit $RC"
expect "legacy authorizations shown as expired" "LEGACY (expired; needs fresh owner confirmation"
expect "missing Pending approval codes degrades" "unknown (checkpoint has no Pending approval codes field)"
expect "missing goal record degrades" "unknown (checkpoint names no goal record)"
expect "continue yes on plain none" "continue: yes"

echo "== continue verdict =="
CKB="$T/proj/_20261013-blocked.claude.md"
sed -e 's|^- \*\*Blocked on:\*\*.*|- **Blocked on:** USER: confirm the parser wiring for the gather script. AGENT: none.|' "$CK" > "$CKB"
gather "$CKB" --no-ipc --session-id s
expect "an owner item that names the next action blocks it" "continue: no (needs the owner: confirm the parser wiring"
CKA="$T/proj/_20261013-agentblocked.claude.md"
sed -e 's|^- \*\*Blocked on:\*\*.*|- **Blocked on:** AGENT: waiting on the CI run to finish.|' "$CK" > "$CKA"
gather "$CKA" --no-ipc --session-id s
expect "an agent blocker blocks" "continue: no (agent is blocked: waiting on the CI run"

echo "== drift when the branch moved =="
CKM="$T/proj/_20261013-moved.claude.md"
sed -e 's|on `feat/x`|on `old/branch`|' "$CK" > "$CKM"
gather "$CKM" --no-ipc --session-id s
expect "a moved branch is flagged" "MOVED, claimed old/branch"

echo "== degrading sections =="
RG_GH="$T/bin/none" gather "$CK" --no-ipc --session-id s
[ "$RC" = 0 ] && ok "missing gh keeps exit 0" || bad "exit $RC"
expect "missing gh is unknown, not fatal" "unknown (gh not available)"
touch "$T/ipc-down"
gather "$CK" --no-ipc --session-id s
trash "$T/ipc-down"
[ "$RC" = 0 ] && ok "broker down keeps exit 0" || bad "exit $RC"
expect "broker down is unknown" "unknown (claude-ipc who"
RG_SHELL_MEM="$T/bin/absent.sh" gather "$CK" --no-ipc --session-id s
expect "missing shell-mem is unknown" "unknown (shell-mem.sh not found)"
RG_LEFT="$T/bin/absent.py" gather "$CK" --no-ipc --session-id s
[ "$RC" = 0 ] && ok "missing goal view keeps exit 0" || bad "exit $RC"
expect "missing goal view is unknown" "unknown (goal abc123"

echo "== mini dump =="
CKI="$T/proj/_20261013-mini.claude.md"
cat > "$CKI" <<'EOF'
# Mini Core Dump

**Goal:** tiny
**Resume:** continue the tiny thing
**Done:**
- wrote a
**Not Done:**
- write b
**Next Steps:**
- run c
EOF
gather "$CKI" --no-ipc --session-id s
[ "$RC" = 0 ] && ok "mini exits 0" || bad "mini exit $RC"
expect "mini done list" "wrote a"
expect "mini pending list" "write b"
expect "a mini with no owner blocker continues" "continue: yes"
CKI2="$T/proj/_20261013-mini2.claude.md"
sed -e 's|^- write b|- USER: approve the merge of the release|' "$CKI" > "$CKI2"
gather "$CKI2" --no-ipc --session-id s
expect "a mini that names a USER blocker does not continue" "continue: no (needs the owner: approve the merge of the release"

echo "== resolving and not finding =="
gather "$T/proj/_nope.claude.md"
[ "$RC" = 3 ] && ok "missing explicit path exits 3" || bad "exit $RC"
expect "says not found" "checkpoint: not found"
gather --cwd "$T/proj" --no-ipc
[ "$RC" = 2 ] || [ "$RC" = 3 ] && ok "no index: exits 2 or 3, never 0" || bad "exit $RC"
printf '{"session_id":"sess-ptr","session_uuid":"","project_root":"%s","checkpoint_path":"%s","name":"ptr","summary":"s","ts":"2026-10-13T04:00:00Z","kind":"core-dump"}\n' "$T/proj" "$CK" > "$T/.claude/checkpoints/sess-ptr.json"
gather --session-id sess-ptr --no-ipc
[ "$RC" = 0 ] && ok "session pointer resolves" || bad "pointer exit $RC"
expect "pointer resolution names the checkpoint" "checkpoint: $CK"
expect "pointer entry name is used" "name ptr"

echo "---- $pass/$total passed"
trash "$T" 2>/dev/null || true
[ "$fail" -eq 0 ]
