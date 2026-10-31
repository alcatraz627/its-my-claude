#!/usr/bin/env bash
# Exercises pr-review-gate.py against a stub gh: tracking, the three block
# phases, dispositions clearing the gate, the block cap, and the skips.
set -uo pipefail

GATE="${GATE_UNDER_TEST:-$HOME/.claude/scripts/hooks/pr-review-gate.py}"
T=$(mktemp -d)
export PR_REVIEW_GATE_STATE="$T/state"
export PR_FIXTURE="$T/pr.json"
cat > "$T/gh" <<'EOF'
#!/usr/bin/env bash
cat "$PR_FIXTURE"
EOF
chmod +x "$T/gh"
export PR_REVIEW_GATE_GH="$T/gh"

pass=0 fail=0
check() {  # $1 name, $2 haystack, $3 needle ("" = expect empty output)
  if [ -z "$3" ] && [ -z "$2" ]; then pass=$((pass+1)); echo "ok   $1"
  elif [ -n "$3" ] && [[ "$2" == *"$3"* ]]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1"; echo "     got: $2"; fi
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

# Fresh push, no review for the head yet: wait.
track s2 "gh pr create --fill" "https://github.com/versable-git/demo/pull/7"
fixture "t" "$HEAD" "0000000"
check "fresh push without review blocks with wait" "$(stop s2)" "pr-review-gate.py wait versable-git/demo#7"

# Same push, five minutes on: retrigger.
python3 - "$PR_REVIEW_GATE_STATE/sessions/s2.json" <<'EOF'
import json, sys
p = sys.argv[1]; st = json.load(open(p))
for v in st["prs"].values(): v["pushed_at"] -= 400
json.dump(st, open(p, "w"))
EOF
check "stale push blocks with retrigger" "$(stop s2)" "clanky-review.py"

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
fixture "t" "fff9999" "abc1234"
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
check "gh -R ... pr create tracks" "$(stop s8)" "has not reviewed head"
mcp_track s9 "mcp__github__create_pull_request" '{"html_url":"https://github.com/Versable-Git/demo/pull/7"}'
check "a PR opened through the GitHub MCP tracks, org case-insensitive" "$(stop s9)" "has not reviewed head"

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
check "a conflicted PR blocks with a rebase instruction" "$(stop s13)" "has merge conflicts"

fixture "t" "abc1234def" "abc1234"
check "a blank reason is refused" "$(python3 "$GATE" dispose demo#7 "1=fixed:   " 2>&1)" "a real one-line reason"

# A wait already polling for this PR's head (run in the background) satisfies Stop.
track s14 "git push" "https://github.com/versable-git/demo/pull/7"
fixture "t" "abc1234def" ""
python3 "$GATE" wait demo#7 60 >/dev/null 2>&1 &
wpid=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do [ -f "$PR_REVIEW_GATE_STATE/waits/versable-git-demo-7@abc1234.json" ] && break; sleep 0.3; done
check "a live background wait for the head clears Stop" "$(stop s14)" ""
kill "$wpid" 2>/dev/null; wait "$wpid" 2>/dev/null
check "a dead wait's leftover marker does not" "$(stop s14)" "has not reviewed head"
python3 - "$PR_REVIEW_GATE_STATE/waits/versable-git-demo-7@9999999.json" <<'EOF'
import json, os, sys, time
json.dump({"pid": os.getppid(), "head": "9999999", "started": time.time(), "deadline": time.time() + 600}, open(sys.argv[1], "w"))
EOF
check "a live wait for another head does not" "$(stop s14)" "has not reviewed head"

# Past the settle window, only a wait started after the retrigger instruction counts.
track s15 "git push" "https://github.com/versable-git/demo/pull/7"
python3 - "$PR_REVIEW_GATE_STATE/sessions/s15.json" "$PR_REVIEW_GATE_STATE/waits/versable-git-demo-7@abc1234.json" <<'EOF'
import json, os, sys, time
p = sys.argv[1]; st = json.load(open(p))
for v in st["prs"].values(): v["pushed_at"] -= 400
json.dump(st, open(p, "w"))
json.dump({"pid": os.getppid(), "head": "abc1234def", "started": time.time() - 390, "deadline": time.time() + 600}, open(sys.argv[2], "w"))
EOF
check "a wait from before the retrigger point still gets the retrigger" "$(stop s15)" "clanky-review.py"
python3 - "$PR_REVIEW_GATE_STATE/waits/versable-git-demo-7@abc1234.json" <<'EOF'
import json, os, sys, time
json.dump({"pid": os.getppid(), "head": "abc1234def", "started": time.time(), "deadline": time.time() + 600}, open(sys.argv[1], "w"))
EOF
check "a wait started after it clears Stop" "$(stop s15)" ""
trash "$PR_REVIEW_GATE_STATE"/waits/*.json >/dev/null 2>&1

# Findings from an earlier head's review can be answered with --sha.
fixture "t" "abc1234def" "abc1234" two
out=$(python3 "$GATE" dispose demo#7 --sha 1111111 "1=fixed:removed in the same push" 2>&1)
check "dispose --sha records against the earlier review" "$out" "Clanky on 1111111"
check "and the summary for that review shows it" "$(python3 "$GATE" summary demo#7 --sha 1111111)" "fixed: removed in the same push"
check "an unknown --sha is refused with the known ones" "$(python3 "$GATE" dispose demo#7 --sha 2222222 "1=fixed:x y" 2>&1)" "reviews on: 1111111, abc1234"
fixture "t" "9999999aaa" "abc1234" two
check "without --sha a moved head still points at --sha" "$(python3 "$GATE" dispose demo#7 "1=fixed:x y" 2>&1)" "--sha <reviewed head>"

trash "$T" >/dev/null 2>&1
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
