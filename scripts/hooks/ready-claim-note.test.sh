#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# Tests for ready-claim-note.sh: a reply that says a PR is ready to merge gets a note when nothing
# asked GitHub this turn, or when the check ran and disagreed; it stays quiet for quoted, negated,
# conditional and question forms, for a run that agreed, and for a run in an earlier turn. It never
# blocks. The last step also runs the command's own suite (scripts/pr/ready-to-merge.test.sh), since
# nothing else runs it.
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
T=$(mktemp -d)
export WARN_LOG_STORE="$T/warn.jsonl"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
if [ -f "$HOME/.claude/.no-ready-claim-note" ]; then echo "mute file present, test would pass vacuously"; exit 2; fi

SID="rclaim01-1111-2222-3333-444444444444"; S8="rclaim01"
HOOK="${READY_CLAIM_HOOK:-$D/ready-claim-note.sh}"
fresh() { rm -f "/tmp/claude-ready-claim-$S8" "/tmp/claude-ready-claim-$S8.seen"; : > "$WARN_LOG_STORE"; }

# Transcript pieces. turn_user starts a turn; bash_run is a Bash call plus its result.
user()     { jq -nc --arg t "$1" '{type:"user",message:{content:$t}}'; }
bash_run() { jq -nc --arg c "$1" --arg r "$2" --arg id "t$RANDOM" \
  '{type:"assistant",message:{content:[{type:"tool_use",id:$id,name:"Bash",input:{command:$c}}]}},
   {type:"user",message:{content:[{type:"tool_result",tool_use_id:$id,content:$r}]}}'; }
# stop <transcript file> <reply text>: the hook's output for a reply ending the turn
stop() { jq -nc --arg s "$SID" --arg p "$1" --arg m "$2" '{session_id:$s,transcript_path:$p,last_assistant_message:$m}' | bash "$HOOK" 2>/dev/null; }
noted() { printf '%s' "$1" | jq -e '.systemMessage | test("ready-claim")' >/dev/null 2>&1; }
quiet() { [ -z "$1" ]; }
heeds() { jq -r --arg v "$1" 'select(.kind=="heed" and .hook_id=="ready-claim" and .heeded==$v) | .id' "$WARN_LOG_STORE" | wc -l | tr -d ' '; }

PLAIN="$T/plain.jsonl"; user "is it ready?" > "$PLAIN"
CLAIM="The review is done and the PR is ready to merge."

echo "-- the claim with nothing behind it"
fresh; out=$(stop "$PLAIN" "$CLAIM")
noted "$out" && ok "a ready-to-merge claim with no check this turn gets a note" || bad "a ready-to-merge claim with no check this turn gets a note: $out"
printf '%s' "$out" | jq -e 'has("decision") | not' >/dev/null 2>&1 && ok "it only notes, never blocks" || bad "it only notes, never blocks"
printf '%s' "$out" | rg -q 'ready-to-merge.py' && ok "the note names the command" || bad "the note names the command"
for phrase in "Looks good to merge." "It can be merged now." "This one is safe to merge." "That is merge-ready."; do
  fresh; out=$(stop "$PLAIN" "$phrase"); noted "$out" && ok "claim form: $phrase" || bad "claim form: $phrase"
done

echo "-- what is not a claim"
for phrase in "The PR is not ready to merge." "It is ready to merge?" "Is the PR ready to merge?" "It will be ready to merge once CI is green." \
              "If it is ready to merge I will say so." "Nothing here is a merge claim." "The tests pass."; do
  fresh; out=$(stop "$PLAIN" "$phrase"); quiet "$out" && ok "silent: $phrase" || bad "silent: $phrase ($out)"
done
fresh; out=$(stop "$PLAIN" $'The output reads:\n```\nPR is ready to merge\n```\nThat was the old run.'); quiet "$out" && ok "silent: a claim inside a code block" || bad "silent: a claim inside a code block"
fresh; out=$(stop "$PLAIN" $'> the PR is ready to merge\nThat was quoted from the thread.'); quiet "$out" && ok "silent: a claim inside a block quote" || bad "silent: a claim inside a block quote"
fresh; out=$(stop "$PLAIN" 'The script prints `READY TO MERGE` when it is.'); quiet "$out" && ok "silent: a claim inside inline code" || bad "silent: a claim inside inline code"

echo "-- the check ran this turn"
READY="$T/ready.jsonl"; { user "check it"; bash_run "python3 ~/.claude/scripts/pr/ready-to-merge.py repo#9" "READY TO MERGE: versable-git/repo#9 at abc1234 has no blockers."; } > "$READY"
fresh; out=$(stop "$READY" "$CLAIM"); quiet "$out" && ok "a run that said READY leaves the claim alone" || bad "a run that said READY leaves the claim alone: $out"
NOT="$T/not.jsonl"; { user "check it"; bash_run "python3 ~/.claude/scripts/pr/ready-to-merge.py repo#9" "NOT READY TO MERGE: versable-git/repo#9 has 1 blocker."; } > "$NOT"
fresh; out=$(stop "$NOT" "$CLAIM"); noted "$out" && printf '%s' "$out" | rg -q 'disagree' && ok "a run that said NOT READY while the reply says ready gets the disagreement note" || bad "a run that said NOT READY while the reply says ready gets the disagreement note: $out"
LATER="$T/later.jsonl"; { user "check it"; bash_run "python3 ~/.claude/scripts/pr/ready-to-merge.py repo#9" "NOT READY TO MERGE: versable-git/repo#9 has 1 blocker."; bash_run "python3 ~/.claude/scripts/pr/ready-to-merge.py repo#9" "READY TO MERGE: versable-git/repo#9 at abc1234 has no blockers."; } > "$LATER"
fresh; out=$(stop "$LATER" "$CLAIM"); quiet "$out" && ok "the newest run decides: blocked, fixed, then ready is quiet" || bad "the newest run decides: blocked, fixed, then ready is quiet: $out"
OLD="$T/old.jsonl"; { user "check it"; bash_run "python3 ~/.claude/scripts/pr/ready-to-merge.py repo#9" "READY TO MERGE: versable-git/repo#9 at abc1234 has no blockers."; user "ok, anything else?"; } > "$OLD"
fresh; out=$(stop "$OLD" "$CLAIM"); noted "$out" && ok "a run in an earlier turn does not cover a claim in this one" || bad "a run in an earlier turn does not cover a claim in this one: $out"

echo "-- loop safety and the heed record"
fresh; stop "$PLAIN" "$CLAIM" >/dev/null
out=$(stop "$PLAIN" "$CLAIM"); quiet "$out" && ok "the same claim at the next Stop is silent" || bad "the same claim at the next Stop is silent"
stop "$PLAIN" "$CLAIM" >/dev/null
[ "$(heeds false)" = 1 ] && ok "a repeated claim is scored heeded:false exactly once" || bad "a repeated claim is scored heeded:false exactly once ($(heeds false))"
out=$(stop "$PLAIN" "A different sentence: the PR is also good to merge."); noted "$out" && ok "a different claim is noted again" || bad "a different claim is noted again"
fresh; stop "$PLAIN" "$CLAIM" >/dev/null; stop "$READY" "Checked. $CLAIM" >/dev/null
[ "$(heeds true)" = 1 ] && ok "a run after the note is scored heeded:true" || bad "a run after the note is scored heeded:true ($(heeds true))"

echo "-- fail-safe"
out=$(printf 'not json' | bash "$HOOK" 2>/dev/null); rc=$?; [ $rc = 0 ] && quiet "$out" && ok "malformed input: exit 0, silent" || bad "malformed input: exit 0, silent"
out=$(jq -nc '{session_id:"x"}' | bash "$HOOK" 2>/dev/null); rc=$?; [ $rc = 0 ] && quiet "$out" && ok "no reply text: exit 0, silent" || bad "no reply text: exit 0, silent"

echo "-- the command's own suite"
if bash "$D/../pr/ready-to-merge.test.sh" >"$T/pr-suite.log" 2>&1; then ok "scripts/pr/ready-to-merge.test.sh passes ($(tail -n 1 "$T/pr-suite.log"))"; else bad "scripts/pr/ready-to-merge.test.sh passes"; tail -n 5 "$T/pr-suite.log" | sed 's/^/        /'; fi

fresh
echo "---- pass=$pass fail=$fail"
cd / && trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
