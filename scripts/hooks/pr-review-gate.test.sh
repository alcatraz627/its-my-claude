#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# Exercises pr-review-gate.py against a stub gh and a stub claude-ipc: tracking,
# findings blocking until dispositioned, the background wait and its wake, what
# the owner is told instead of a block, the block cap, and the skips.
set -uo pipefail

GATE="${GATE_UNDER_TEST:-$HOME/.claude/scripts/hooks/pr-review-gate.py}"
T=$(mktemp -d)
export PR_REVIEW_GATE_STATE="$T/state"
export PR_FIXTURE="$T/pr.json"
cat > "$T/gh" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$PR_FIXTURE.calls"
cat "$PR_FIXTURE"
EOF
chmod +x "$T/gh"
export PR_REVIEW_GATE_GH="$T/gh"
# Short by default so a wait started by any no-review Stop below ends on its own.
export PR_REVIEW_GATE_POLL_S=0.1 PR_REVIEW_GATE_AUTO_WAIT_S=1
export IPC_LOG="$T/ipc.log"
cat > "$T/ipc" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  peers) echo '{"peers":[{"sessionId":"sess-alias","aliases":["friendly-a1","other"]},{"sessionId":"new-sess","succeededSid":"cleared-sess","aliases":["successor-b2"]},{"sessionId":"cleared-sess","aliases":["gone-c3"]}]}' ;;
  register) echo "register $*" >> "$IPC_LOG.reg" ;;
  send) [ -n "${IPC_STUB_FAIL:-}" ] && { echo "broker down" >&2; exit 2; }; printf '%s\n' "$*" >> "$IPC_LOG" ;;
esac
EOF
chmod +x "$T/ipc"
export PR_REVIEW_GATE_IPC="$T/ipc"
trap 'pkill -f "$T/state" 2>/dev/null' EXIT

pass=0 fail=0
check() {  # $1 name, $2 haystack, $3 needle ("" = expect empty output)
  if [ -z "$3" ] && [ -z "$2" ]; then pass=$((pass+1)); echo "ok   $1"
  elif [ -n "$3" ] && [[ "$2" == *"$3"* ]]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1"; echo "     got: $2"; fi
}
check_not() {  # $1 name, $2 haystack, $3 text that must be absent; the haystack must hold something
  if [ -n "$2" ] && [[ "$2" != *"$3"* ]]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1"; echo "     got: $2"; fi
}
same() {  # $1 name, $2 got, $3 want
  if [ "$2" = "$3" ]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1"; echo "     got: $2, want: $3"; fi
}
sends() { [ -f "$IPC_LOG" ] && rg -c -- "--to $1 " "$IPC_LOG" || echo 0; }
waiters() { pgrep -f "wake $1 --marker $T/state" | wc -l | tr -d ' '; }
auto_marker() { echo "$PR_REVIEW_GATE_STATE/autowaits/versable-git-demo-7@$2-$1.json"; }
until_true() {  # up to about 8 s for a condition given as a command
  for _ in $(seq 1 80); do "$@" && return 0; sleep 0.1; done; return 1
}
sends_reached() { [ "$(sends "$1")" -ge "$2" ]; }
marker_ended() { [ -f "$1" ] && rg -q '"ended"' "$1"; }
pid_gone() { ! kill -0 "$1" 2>/dev/null; }
age_push() {  # $1 session
  python3 - "$PR_REVIEW_GATE_STATE/sessions/$1.json" <<'EOF'
import json, sys
p = sys.argv[1]; st = json.load(open(p))
for v in st["prs"].values(): v["pushed_at"] -= 400
json.dump(st, open(p, "w"))
EOF
}

fixture() {  # $1 title, $2 head sha, $3 review sha ("" = no review), $4 extra: draft|closed|rerun|quoted
  python3 - "$1" "$2" "$3" "${4:-}" > "$PR_FIXTURE" <<'EOF'
import json, sys
title, head, rsha, extra = sys.argv[1:5]
comments = [{"body": "a human comment"}]
first = "A different concern after a re-run." if extra == "rerun" else "A failed lookup reads as missing."
if rsha:
    comments.append({"body": "<!-- pr-claude:review -->\n## Clanky's Review\n"
        f"### ⚠️ 1. [`a.py:3`](https://x) · `exists`\n\n{first}\n\n- detail\n"
        "### ℹ️ 2. [`b.md:9`](https://x) · `docs`\n"
        f"<!-- pr-claude:review:sha={rsha} -->"})
if extra == "two":
    comments.insert(1, {"body": "<!-- pr-claude:review -->\n## Clanky's Review\n"
        "### ⚠️ 1. [`old.py:1`](https://x) · `gone`\n\nAn earlier concern.\n"
        "<!-- pr-claude:review:sha=1111111 -->"})
if extra == "usage":
    comments.append({"body": "<!-- pr-claude:review -->\n<!-- pr-claude:review:dead -->\n## nobody looked\n\n"
        "\U0001F99E Claude usage exhausted\n\nClaude's usage resets 3:50pm (UTC), and I am asleep until then. "
        "A run after that picks it up.\n\n<!-- pr-claude:review:outcome=review.not_run.out_of_usage -->"})
if extra == "stood-down":
    comments.append({"body": f"\U0001F99E> `/claude-bot review`\n\nReview stood down on `{head[:7]}`: Claude usage exhausted; the next run overwrites this"})
if extra == "paused":
    comments.append({"body": "\u23f8\ufe0f Automatic reviews are paused on this PR: they failed on 3 different commits."})
if extra == "quoted":
    comments.append({"body": "> <!-- pr-claude:review -->\n> quoting the bot"})
print(json.dumps({"url": "https://github.com/versable-git/demo/pull/7",
                  "state": "CLOSED" if extra == "closed" else "OPEN",
                  "isDraft": extra == "draft", "title": title, "headRefOid": head, "comments": comments,
                  "mergeable": "CONFLICTING" if extra == "conflict" else "MERGEABLE"}))
EOF
}
mcp_track() {  # $1 sid, $2 tool name, $3 response text
  jq -cn --arg s "$1" --arg t "$2" --arg o "$3" '{session_id:$s, tool_name:$t, tool_input:{}, tool_response:$o}' \
    | python3 "$GATE" track
}

stop() { printf '{"session_id":"%s"}' "$1" | python3 "$GATE" stop; }
track() {  # $1 sid, $2 command, $3 stdout
  jq -cn --arg s "$1" --arg c "$2" --arg o "$3" \
    '{session_id:$s, tool_name:"Bash", tool_input:{command:$c}, tool_response:{stdout:$o}}' \
    | python3 "$GATE" track
}
HEAD=abc1234def

# Untracked session: nothing to check.
fixture "t" "$HEAD" ""
check "untracked session is silent" "$(stop s0)" ""

# Another org is never tracked.
track s1 "gh pr create --fill" "https://github.com/other-org/demo/pull/7"
check "other org is not tracked" "$(stop s1)" ""

# Fresh push, no review for the head yet: the hook waits, the model does nothing.
track s2 "gh pr create --fill" "https://github.com/versable-git/demo/pull/7"
fixture "t" "$HEAD" "0000000"
out=$(stop s2)
check "fresh push without review starts a wait and says so" "$out" "waiting for Clanky on versable-git/demo#7"
check_not "and does not block" "$out" '"decision"'
until_true marker_ended "$(auto_marker s2 abc1234)"

# Same push, five minutes on, the wait over: tell the owner and leave the retrigger to them.
age_push s2
out=$(stop s2)
check "stale push names the local trigger to the owner" "$out" "clanky-review.py versable-git/demo#7"
check "and says it needs approval" "$out" "needs your approval"
check_not "and does not block" "$out" '"decision"'
check "the owner hears about it once per head" "$(stop s2)" ""

# Review for the head with two findings and no dispositions.
fixture "t" "$HEAD" "abc1234"
out=$(stop s2)
check "undispositioned findings block" "$out" "2 finding(s) with no disposition"
check "finding headline carries the concern" "$out" '1. `a.py:3` · `exists` · A failed lookup reads as missing.'

# Bad disposition word is refused.
out=$(python3 "$GATE" dispose demo#7 "1=meh:x" 2>&1)
check "unknown disposition refused" "$out" "bad item"

# One disposition leaves one open.
python3 "$GATE" dispose demo#7 "1=fixed:guarded the call" >/dev/null
check "partial dispositions still block" "$(stop s2)" "1 finding(s) with no disposition"

# Both dispositioned: the gate opens and the summary shows both.
python3 "$GATE" dispose demo#7 "2=optional:docs follow-up" >/dev/null
check "all dispositioned is silent" "$(stop s2)" ""
check "summary lists the resolution" "$(python3 "$GATE" summary demo#7)" "2. \`b.md:9\` · \`docs\` · optional: docs follow-up"

# Block cap: a third identical block becomes a note.
track s3 "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "c0ffee1aaa" "c0ffee1"
stop s3 >/dev/null
stop s3 >/dev/null
check "third block demotes to a note" "$(stop s3)" "systemMessage"

# Skips: [nobot] title, draft.
track s4 "gh pr create" "https://github.com/versable-git/demo/pull/7"
fixture "[nobot] t" "fff9999" ""
check "[nobot] title is skipped" "$(stop s4)" ""

# Non-trigger command is not tracked.
track s5 "gh pr view 7" "https://github.com/versable-git/demo/pull/7"
fixture "t" "fff9999" ""
check "gh pr view does not track" "$(stop s5)" ""

# Commands that only mention a push, or quote it, are not tracked.
track s6 "git stash push -m wip" "https://github.com/versable-git/demo/pull/7"
track s6 "echo \"git push\"" "https://github.com/versable-git/demo/pull/7"
track s6 "git commit -m 'fix push bug'" "https://github.com/versable-git/demo/pull/7"
check "push only mentioned or quoted does not track" "$(stop s6)" ""

# A URL quoted in the command is not a PR this command touched.
track s7 "git push origin x # see https://github.com/versable-git/other/pull/99" ""
check "a URL only in the command text is not tracked" "$(cat "$PR_REVIEW_GATE_STATE/sessions/s7.json" 2>/dev/null)" '"versable-git/demo#7"'

# gh with -R before the subcommand, and the GitHub MCP, are both tracked.
track s8 "gh -R versable-git/demo pr create --fill" "https://github.com/versable-git/demo/pull/7"
check "gh -R ... pr create tracks" "$(stop s8)" "waiting for Clanky on"
mcp_track s9 "mcp__github__create_pull_request" '{"html_url":"https://github.com/Versable-Git/demo/pull/7"}'
check "a PR opened through the GitHub MCP tracks, org case-insensitive" "$(stop s9)" "waiting for Clanky on"

# Draft PRs are skipped; closed ones are dropped from the session.
track s10 "gh pr create" "https://github.com/versable-git/demo/pull/7"
fixture "t" "fff9999" "" draft
check "a draft PR is skipped" "$(stop s10)" ""
fixture "t" "fff9999" "" closed
stop s10 >/dev/null
check "a closed PR is dropped from the session" "$(cat "$PR_REVIEW_GATE_STATE/sessions/s10.json")" '"prs": {}'

# A new head needs fresh dispositions; a re-run on the same head with a changed finding does too.
track s11 "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "abc1234def" "abc1234"
check "old dispositions still clear the same review" "$(stop s11)" ""
fixture "t" "abc1234def" "abc1234" rerun
check "a re-run that changed finding 1 needs it again" "$(stop s11)" "1 finding(s) with no disposition"
fixture "t" "9999999aaa" "9999999"
check "a new head needs fresh dispositions" "$(stop s11)" "2 finding(s) with no disposition"

# A quote-reply of the bot's marker does not hide the real review.
track s12 "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "abc1234def" "abc1234" quoted
check "a quoted marker is not taken as the review" "$(stop s12)" ""

track s13 "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "abc1234def" "" conflict
out=$(stop s13)
check "a conflicted PR is reported to the owner" "$out" "has merge conflicts"
check_not "and does not block, there being no findings" "$out" '"decision"'
same "and starts no wait, since no review is coming" "$(waiters s13)" "0"
track s13b "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "d1234567ff" "d123456" conflict
check "findings on a conflicted PR still block" "$(stop s13b)" "with no disposition"

fixture "t" "abc1234def" "abc1234"
check "a blank reason is refused" "$(python3 "$GATE" dispose demo#7 "1=fixed:   " 2>&1)" "a real one-line reason"

# A wait the model started itself counts: the hook adds none beside it.
track s14 "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "d1234567ff" ""
PR_REVIEW_GATE_POLL_S=20 python3 "$GATE" wait demo#7 60 >/dev/null 2>&1 &
wpid=$!
until_true test -f "$PR_REVIEW_GATE_STATE/waits/versable-git-demo-7@d123456.json"
check "a live wait for the head keeps Stop silent" "$(stop s14)" ""
same "and the hook adds no wait of its own" "$(waiters s14)" "0"
kill "$wpid" 2>/dev/null; wait "$wpid" 2>/dev/null
check "a killed wait's leftover marker does not hold it back" "$(stop s14)" "waiting for Clanky on"
trash "$PR_REVIEW_GATE_STATE"/waits/*.json >/dev/null 2>&1

# Another session's background wait wakes that session only, so this one still needs its own.
track s28 "git push" "https://github.com/versable-git/demo/pull/7"
mkdir -p "$PR_REVIEW_GATE_STATE/waits"
python3 - "$PR_REVIEW_GATE_STATE/waits/versable-git-demo-7@d123456.json" <<'EOF'
import json, os, sys, time
json.dump({"pid": os.getppid(), "head": "d1234567ff", "started": time.time(), "deadline": time.time() + 600, "wake": "someone-else"}, open(sys.argv[1], "w"))
EOF
check "another session's wait does not stand in for this one's" "$(stop s28)" "waiting for Clanky on"
trash "$PR_REVIEW_GATE_STATE"/waits/*.json >/dev/null 2>&1

# The hook's own wait: started once, silent while it runs, and detached from the hook.
export PR_REVIEW_GATE_AUTO_WAIT_S=30
track sess-alias "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "d1234567ff" ""
started=$SECONDS
out=$(stop sess-alias 2>&1)
same "Stop returns at once with the wait running, holding no stream of ours" "$(( SECONDS - started < 5 ))" "1"
check "the first Stop starts a wait" "$out" "waiting for Clanky on versable-git/demo#7 at d123456"
same "one wait is running" "$(waiters sess-alias)" "1"
m20=$(auto_marker sess-ali d123456)
wpid=$(pgrep -f "wake sess-alias --marker $T/state")
same "the wait leads its own process group, so cleaning up the hook leaves it alive" "$(ps -o pgid= -p "$wpid" | tr -d ' ')" "$wpid"
out=$(stop sess-alias)
check "a repeat Stop while it runs is silent" "$out" ""
same "and starts no second wait" "$(waiters sess-alias)" "1"

# Findings arrive: one message wakes the session, and Stop blocks until they are answered.
fixture "t" "d1234567ff" "d123456"
until_true sends_reached friendly-a1 1
until_true pid_gone "$wpid"
same "the wait's end sends one message" "$(sends friendly-a1)" "1"
line=$(rg -- "--to friendly-a1 " "$IPC_LOG")
check "it comes from the gate" "$line" "--from pr-review"
check "it asks, because the inbox watcher only wakes a session for an ask" "$line" "--kind request"
check "it expects no reply" "$line" "--no-reply-expected"
check "it names the PR" "$line" "versable-git/demo#7"
check "it says how many findings" "$line" "2 finding(s)"
check "it says what to run" "$line" "pr-review-gate.py dispose versable-git/demo#7"
same "it is one line" "$(printf '%s\n' "$line" | wc -l | tr -d ' ')" "1"
check "the sender was registered first, or the broker refuses it" "$(cat "$IPC_LOG.reg")" "register pr-review --service"
until_true marker_ended "$m20"
out=$(stop sess-alias)
check "findings block once the wait is over" "$out" '"decision": "block"'
check "and the block lists them" "$out" "2 finding(s) with no disposition"
PR_REVIEW_GATE_AUTO_WAIT_S=1 python3 "$GATE" wait demo#7 1 --wake sess-alias >/dev/null 2>&1
same "a second wait reaching the same review sends nothing more" "$(sends friendly-a1)" "1"
python3 "$GATE" wait demo#7 1 --wake cleared-sess >/dev/null 2>&1
same "a session cleared during the wait: the message reaches its successor" "$(sends successor-b2)" "1"
same "and not the old name" "$(sends gone-c3)" "0"

# When the wait times out, the session hears once, and only about what is true.
export PR_REVIEW_GATE_AUTO_WAIT_S=1
fixture "t" "d1234567ff" ""
python3 "$GATE" wait demo#7 1 --wake sess-timeout >/dev/null 2>&1
line=$(rg -- "--to sess-timeout " "$IPC_LOG")
check "a timeout says nothing is there to disposition" "$line" "Nothing to disposition yet"
check_not "and leaves the retrigger to the owner" "$line" "clanky-review.py"
fixture "t" "0123456def" "" closed
python3 "$GATE" wait demo#7 1 --wake sess-closed >/dev/null 2>&1
same "a PR closed during the wait wakes nobody" "$(sends sess-closed)" "0"

# ipc down: the wait still ends cleanly, and the findings still block at the next Stop.
fixture "t" "d1234567ff" "d123456"
IPC_STUB_FAIL=1 python3 "$GATE" wait demo#7 1 --wake sess-down >"$T/o" 2>"$T/e"
same "a refused send does not raise" "$?" "0"
check "and is logged" "$(cat "$T/e")" "wake not sent: broker down"
check_not "with no traceback" "$(cat "$T/e")" "Traceback"
PR_REVIEW_GATE_IPC="$T/no-such-binary" python3 "$GATE" wait demo#7 1 --wake sess-gone >"$T/o" 2>"$T/e"
same "a missing claude-ipc does not raise" "$?" "0"
check_not "with no traceback" "$(cat "$T/e")" "Traceback"
track s22 "git push" "https://github.com/versable-git/demo/pull/7"
check "and with ipc down the findings still block" "$(IPC_STUB_FAIL=1 stop s22)" "2 finding(s) with no disposition"

# A mute stops all of it: no wait started and no message from one already running.
mkdir -p "$T/home/.claude"
touch "$T/home/.claude/.no-pr-review-gate"
track s23 "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "d1234567ff" ""
check "a mute file is silent" "$(HOME="$T/home" stop s23)" ""
same "and starts no wait" "$(waiters s23)" "0"
same "and leaves no marker" "$(ls "$(auto_marker s23 d123456)" 2>/dev/null | wc -l | tr -d ' ')" "0"
check "the one-shot off is silent too" "$(PR_REVIEW_GATE_OFF=1 stop s23)" ""
fixture "t" "d1234567ff" "d123456"
HOME="$T/home" python3 "$GATE" wait demo#7 1 --wake sess-muted >/dev/null 2>&1
same "a wait that ends under a mute sends nothing" "$(sends sess-muted)" "0"

# A dead wait must not leave its marker in charge.
export PR_REVIEW_GATE_AUTO_WAIT_S=30
track s24 "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "d1234567ff" ""
stop s24 >/dev/null
sleep 0.3
wpid=$(pgrep -f "wake s24 --marker $T/state")
kill -9 "$wpid"; until_true pid_gone "$wpid"
check "a wait that died is started again" "$(stop s24)" "waiting for Clanky on"
same "as one process" "$(waiters s24)" "1"
sleep 0.3
wpid=$(pgrep -f "wake s24 --marker $T/state")
kill -9 "$wpid"; until_true pid_gone "$wpid"
check "a wait that keeps dying is not restarted forever" "$(stop s24)" ""
same "so no process is left" "$(waiters s24)" "0"
age_push s24
check "and the owner still hears there is no review" "$(stop s24)" "no Clanky review for head d123456"
fixture "t" "d1234567ff" "d123456"
check "a dead wait's marker does not hide findings" "$(stop s24)" "2 finding(s) with no disposition"

# A marker whose pid looks alive long past its limit is a recycled pid, not a wait.
export PR_REVIEW_GATE_AUTO_WAIT_S=1
track s25 "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "d1234567ff" ""
mkdir -p "$PR_REVIEW_GATE_STATE/autowaits"
python3 - "$(auto_marker s25 d123456)" <<'EOF'
import json, os, sys, time
json.dump({"pid": os.getppid(), "started": time.time() - 900, "deadline": time.time() - 300, "restarts": 0}, open(sys.argv[1], "w"))
EOF
check "a marker past its deadline does not stop a new wait" "$(stop s25)" "waiting for Clanky on"
python3 - "$(auto_marker s26 d123456)" <<'EOF'
import json, os, sys, time
json.dump({"pid": os.getppid(), "started": time.time(), "deadline": time.time() + 900, "restarts": 0}, open(sys.argv[1], "w"))
EOF
track s26 "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "d1234567ff" "d123456"
check "a live-looking marker does not hide findings either" "$(stop s26)" "2 finding(s) with no disposition"
fixture "t" "d1234567ff" ""
# A wait that has started but not yet read the PR has no polling marker, only this one.
python3 - "$(auto_marker s29 d123456)" <<'EOF'
import json, os, sys, time
json.dump({"pid": os.getppid(), "started": time.time(), "deadline": time.time() + 900, "restarts": 0}, open(sys.argv[1], "w"))
EOF
track s29 "git push" "https://github.com/versable-git/demo/pull/7"
check "a wait still starting up is not started twice" "$(stop s29)" ""
same "so nothing new runs" "$(waiters s29)" "0"
python3 - "$(auto_marker s27 d123456)" <<'EOF'
import json, sys, time
json.dump({"pid": 1, "ended": time.time(), "started": time.time(), "deadline": time.time()}, open(sys.argv[1], "w"))
EOF
track s27 "git push" "https://github.com/versable-git/demo/pull/7"
check "a wait that ran its course is not started again at this head" "$(stop s27)" ""
same "so nothing runs" "$(waiters s27)" "0"
fixture "t" "fff9999aaa" ""
check "but a new head gets its own wait" "$(stop s27)" "waiting for Clanky on versable-git/demo#7 at fff9999"

# Clanky out of usage, read from what it wrote on the PR.
track s30 "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "d1234567ff" "" usage
out=$(stop s30)
check "out of usage is reported" "$out" "ran out of Claude usage"
check "with the reset time it gave" "$out" "resets 3:50pm (UTC)"
check_not "and no block" "$out" '"decision"'
check_not "and no retrigger instruction" "$out" "clanky-review.py"
age_push s30
python3 - "$PR_REVIEW_GATE_STATE/sessions/s30.json" <<'EOF'
import json, sys
p = sys.argv[1]; st = json.load(open(p)); st["noted"] = {}
json.dump(st, open(p, "w"))
EOF
check_not "past the settle time too" "$(stop s30)" "clanky-review.py"
python3 "$GATE" wait demo#7 1 --wake sess-usage >/dev/null 2>&1
same "a wait timing out on a spent account wakes nobody, the owner was told" "$(sends sess-usage)" "0"
track s31 "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "d1234567ff" "" stood-down
check "a stand-down reply on this head reads as out of usage" "$(stop s31)" "ran out of Claude usage"
track s32 "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "9999999aaa" "" stood-down
python3 - "$PR_FIXTURE" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
d["comments"][-1]["body"] = d["comments"][-1]["body"].replace("9999999", "1234567")
json.dump(d, open(sys.argv[1], "w"))
EOF
check_not "a stand-down about an older head does not" "$(stop s32)" "ran out of Claude usage"

# Reviews paused on the PR: running one is what is needed, so the owner is told how.
track s33 "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "d1234567ff" "" paused
stop s33 >/dev/null
until_true marker_ended "$(auto_marker s33 d123456)"
out=$(stop s33)
check "paused automatic reviews are reported" "$out" "paused automatic reviews"
check "naming the local trigger" "$out" "clanky-review.py versable-git/demo#7"
check_not "with no block" "$out" '"decision"'

# Nothing here ever posts to GitHub.
same "no run asked gh to comment" "$(rg -c '^pr (comment|review|edit)' "$PR_FIXTURE.calls" || echo 0)" "0"
same "every gh call was a read" "$(rg -c -v '^pr view ' "$PR_FIXTURE.calls" || echo 0)" "0"

# A headless run has nothing to wake it, so it still sits through the wait itself.
track s40 "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "d1234567ff" ""
out=$(HOOK_POPULATION_TEST=1 CLAUDE_CODE_ENTRYPOINT=sdk-cli stop s40)
check "a headless run is told to wait" "$out" "pr-review-gate.py wait versable-git/demo#7"
check "by a block" "$out" '"decision": "block"'
same "and no background wait starts for it" "$(waiters s40)" "0"
age_push s40
out=$(HOOK_POPULATION_TEST=1 CLAUDE_CODE_ENTRYPOINT=sdk-cli stop s40)
check_not "past the settle time it is not blocked on a retrigger" "$out" '"decision"'
check "only the owner is told" "$out" "needs your approval"
fixture "t" "d1234567ff" "d123456"
check "findings block a headless run" "$(HOOK_POPULATION_TEST=1 CLAUDE_CODE_ENTRYPOINT=sdk-cli stop s40)" "with no disposition"
mkdir -p "$T/kw"
: > "$T/kw/claude-keepwarm-wake-s41"
track s41 "git push" "https://github.com/versable-git/demo/pull/7"
check "a keep-warm ping is excused" "$(HOOK_POPULATION_TEST=1 KEEPWARM_WAKE_DIR="$T/kw" CLAUDE_CODE_SESSION_ID=s41 stop s41)" ""

# Findings from an earlier head's review can be answered with --sha.
fixture "t" "abc1234def" "abc1234" two
out=$(python3 "$GATE" dispose demo#7 --sha 1111111 "1=fixed:removed in the same push" 2>&1)
check "dispose --sha records against the earlier review" "$out" "Clanky on 1111111"
check "and the summary for that review shows it" "$(python3 "$GATE" summary demo#7 --sha 1111111)" "fixed: removed in the same push"
check "an unknown --sha is refused with the known ones" "$(python3 "$GATE" dispose demo#7 --sha 2222222 "1=fixed:x y" 2>&1)" "reviews on: 1111111, abc1234"
fixture "t" "9999999aaa" "abc1234" two
check "without --sha a moved head still points at --sha" "$(python3 "$GATE" dispose demo#7 "1=fixed:x y" 2>&1)" "--sha <reviewed head>"

pkill -f "$T/state" 2>/dev/null
trash "$T" >/dev/null 2>&1
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
