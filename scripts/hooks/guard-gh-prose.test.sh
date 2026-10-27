#!/usr/bin/env bash
# Suite for guard-gh-prose.py: prose posted through gh that reads as a wall is
# refused, a plain rewrite of the same text passes, and short automation
# triggers such as "/clanky review" pass. The real case is the 20 Oct landing-app
# PR description (both of PR 60's bodies, recovered from the session).
# GUARD_UNDER_TEST points the suite at a mutated copy (it must sit in scripts/hooks/).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="${GUARD_UNDER_TEST:-$HERE/guard-gh-prose.py}"
MARKER_HOOK="$HERE/guard-github-agent-marker.sh"
REC="$HOME/.claude/assets/reports/20261027-readability-gate-fixture"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

T=$(mktemp -d)
export GH_PROSE_STATE="$T" WARN_LOG_STORE="$T/warn.jsonl"
unset GH_PROSE_OFF

MARKER='> Generated via a 🤖 on @someone machine (_he got lazy_)'
DASH=$'\xe2\x80\x94'
DENSE='The cache keeps recent reads in memory for the length of one request. A second call with the same key gets the stored reply instead of going back to disk. Entries expire after sixty seconds so a stale value cannot linger for long. The size is capped at five hundred entries and the oldest one is dropped first.'
MECH='The `fetch` in `src/lib/beehiiv.ts` memoizes the GET for 3s. Each retry adds an `X-Retry-Attempt` header, which changes the cache key. The `revalidate = 3600` setting then applies per key.'

# rc 2 is the hook's refusal; anything else is a pass
run_bash() { # run_bash <command> [session]
  jq -nc --arg c "$1" --arg s "${2:-s$RANDOM}" '{tool_name:"Bash", tool_input:{command:$c}, cwd:"/tmp", session_id:$s}' \
    | python3 "$HOOK" 2>"$T/err" >"$T/out"; echo $?
}
run_mcp() { # run_mcp <tool> <tool_input json>
  jq -nc --arg t "$1" --argjson i "$2" '{tool_name:$t, tool_input:$i, session_id:("m" + ($t|length|tostring))}' \
    | python3 "$HOOK" 2>"$T/err" >"$T/out"; echo $?
}
blocked() { [ "$(run_bash "$1")" = 2 ] && ok "REFUSED: ${2:-${1:0:72}}" || bad "not refused: ${2:-${1:0:72}}"; }
allowed() { [ "$(run_bash "$1")" != 2 ] && ok "allow: ${2:-${1:0:72}}" || bad "refused (should pass): ${2:-${1:0:72}}: $(head -c 200 "$T/err")"; }

# ---- the real case: PR 60 of 20 Oct
blocked "gh pr create --repo o/r --title t --body-file $REC/pr60-body-dense.md" "PR 60 body as written, from a file"
allowed "gh pr edit 60 --repo o/r --body-file $REC/pr60-body-plain.md" "PR 60 plain rewrite, from a file"
allowed "gh pr edit 60 --repo o/r --body-file $REC/pr60-body-reviewed.md" "PR 60 body after its review pass (bold-led bullets, a Details list)"
blocked "gh pr edit 60 --body \"\$(cat <<'EOF'
$(cat "$REC/pr60-body-dense.md")
EOF
)\"" "PR 60 body inside a \$(cat <<EOF) substitution"
allowed "gh pr edit 60 --body \"\$(cat <<'EOF'
$(cat "$REC/pr60-body-plain.md")
EOF
)\"" "PR 60 plain rewrite inside a \$(cat <<EOF) substitution"
run_bash "gh pr edit 60 --body-file $REC/pr60-body-dense.md" >/dev/null
grep -q "dense block" "$T/err" && ok "the refusal names the dense block" || bad "no dense-block reason: $(head -c 200 "$T/err")"
grep -q "Details" "$T/err" && ok "and says how to rewrite it" || bad "no rewrite advice"

# ---- every way gh carries a body
blocked "gh pr comment 3 --body '$DENSE'" "pr comment --body"
blocked "gh pr comment 3 -b '$DENSE'" "pr comment -b"
blocked "gh pr comment 3 --body='$DENSE'" "pr comment --body="
blocked "gh issue comment 3 --body '$DENSE'" "issue comment"
blocked "gh issue create --title t --body '$DENSE'" "issue create"
blocked "gh issue edit 3 --body '$DENSE'" "issue edit"
blocked "gh pr review 3 --comment --body '$DENSE'" "pr review"
blocked "gh pr close 3 --comment '$DENSE'" "pr close --comment"
blocked "gh issue close 3 -c '$DENSE'" "issue close -c"
blocked "gh pr merge 3 --squash --body '$DENSE'" "pr merge --body"
blocked "gh release create v1 --notes '$DENSE'" "release create --notes"
blocked "gh api repos/o/r/issues/1/comments -f body='$DENSE'" "gh api -f body="
blocked "gh api repos/o/r/issues/1/comments -F body='$DENSE'" "gh api -F body="
blocked "gh api repos/o/r/pulls/1/reviews --raw-field body='$DENSE' -f event=COMMENT" "gh api --raw-field body="
blocked "gh api repos/o/r/pulls/1/reviews -f 'comments[][body]=$DENSE' -f 'comments[][path]=a.py'" "gh api review comment array body"
blocked "gh api repos/o/r/issues/1/comments -F body=@$REC/pr60-body-dense.md" "gh api -F body=@file"
printf '{"body": "%s"}' "$DENSE" > "$T/payload.json"
blocked "gh api repos/o/r/issues/1/comments --input $T/payload.json" "gh api --input JSON file"
blocked "gh api repos/o/r/issues/1/comments --input - <<'EOF'
{\"body\": \"$DENSE\"}
EOF" "gh api --input - heredoc"
blocked "gh pr comment 3 --body-file - <<'EOF'
$DENSE
EOF" "--body-file - heredoc"
blocked "cat <<'EOF' | gh pr comment 3 -F -
$DENSE
EOF" "piped heredoc into -F -"
blocked "gh pr comment 3 -R o/r --body \"\$(cat $REC/pr60-body-dense.md)\"" "\$(cat FILE)"
blocked "cd repo && gh pr comment 3 --body '$DENSE'" "behind a cd"
blocked "bash -c \"gh pr comment 3 --body '$DENSE'\"" "inside bash -c"
blocked "gh pr comment 3 --body '$MECH'" "an internals-only run, not long enough to be dense"
blocked "gh pr comment 3 --body '/clanky review
$MARKER
$DENSE'" "a trigger does not excuse the prose next to it"
blocked "gh pr comment 3 --body 'Fixed it ${DASH} the cache key now includes the retry count.'" "a short comment with an em-dash"
blocked "gh pr comment 3 --body 'The retry now sends its own header so the reply is not reused by the next attempt; the old code reused it every time.'" "one long semicolon line"

# ---- what must pass
allowed "gh pr comment 3 --body '/clanky review'" "a bare automation trigger"
allowed "gh pr comment 3 --body '/claude-bot ask what changed in the cache?'" "a trigger with a short question"
allowed "gh pr comment 3 --body '$MARKER
/clanky review'" "a trigger under the owner's marker"
allowed "gh pr comment 3 --body '$MARKER
Fixed in the last commit. The retry now has its own cache entry.'" "a short plain comment under the marker"
allowed "gh pr comment 3 --body 'Thanks, fixed.'" "a short plain comment"
allowed "gh pr comment 3 --body '$(printf '```\n%s\n```' "$DENSE")'" "dense text inside a code fence is a quote, not prose"
allowed 'gh pr view 3' "a read"
allowed 'gh api repos/o/r/pulls/1' "an api read"
allowed 'gh pr list --search "cache"' "a list"
allowed "gh pr create --title t --fill" "a body-less create"
allowed "gh pr comment 3 --body \"\$BODY\"" "a body only a variable knows"
allowed "gh pr comment 3 --body-file /nonexistent/body.md" "a body file that cannot be read"
allowed "echo \"run gh pr comment 3 --body '$DENSE' later\"" "words in an echo"
allowed "git commit -m \"docs: gh pr comment 3 --body '$DENSE'\"" "words in a commit message"
allowed "cat > /tmp/t.sh <<'EOF'
gh pr comment 3 --body '$DENSE'
EOF" "a script that names gh in a heredoc"

# ---- the owner's attribution marker stays exactly as its own hook wants it
marked="gh pr edit 60 --repo o/r --body-file $REC/pr60-body-plain.md"
[ "$(run_bash "$marked")" != 2 ] && ok "marked plain body: prose gate passes" || bad "marked plain body refused by the prose gate"
if jq -nc --arg c "$marked" '{tool_name:"Bash", tool_input:{command:$c}, cwd:"/tmp"}' | bash "$MARKER_HOOK" >/dev/null 2>&1; then
  ok "marked plain body: marker hook passes the same command"
else
  bad "marker hook refused the plain marked body"
fi
if jq -nc --arg c "gh pr edit 60 --body '$DENSE'" '{tool_name:"Bash", tool_input:{command:$c}, cwd:"/tmp"}' | bash "$MARKER_HOOK" >/dev/null 2>&1; then
  bad "marker hook should still refuse an unmarked body"
else
  ok "marker hook still refuses an unmarked body (untouched)"
fi

# ---- GitHub MCP tools
mcp_dense=$(jq -nc --arg b "$DENSE" '{owner:"o", repo:"r", issue_number:1, body:$b}')
mcp_plain=$(jq -nc '{owner:"o", repo:"r", issue_number:1, body:"Thanks, fixed in the last commit."}')
[ "$(run_mcp mcp__github__add_issue_comment "$mcp_dense")" = 2 ] && ok "REFUSED: mcp add_issue_comment" || bad "mcp comment not refused"
[ "$(run_mcp mcp__github__add_issue_comment "$mcp_plain")" != 2 ] && ok "allow: mcp plain comment" || bad "mcp plain comment refused"
rev=$(jq -nc --arg b "$DENSE" '{owner:"o", repo:"r", pullNumber:1, event:"COMMENT", comments:[{path:"a.py", body:$b}]}')
[ "$(run_mcp mcp__github__create_pull_request_review "$rev")" = 2 ] && ok "REFUSED: mcp review comment body" || bad "mcp review comment not refused"
[ "$(run_mcp mcp__github__get_issue '{"owner":"o"}')" != 2 ] && ok "allow: mcp read" || bad "mcp read refused"

# ---- loop safety: the same body is refused twice, then goes through with a note
S=loop1
a=$(run_bash "gh pr comment 9 --body '$DENSE'" $S); b=$(run_bash "gh pr comment 9 --body '$DENSE'" $S); c=$(run_bash "gh pr comment 9 --body '$DENSE'" $S)
[ "$a$b$c" = "220" ] && ok "same body: refused, refused, then through" || bad "loop valve gave $a $b $c"
grep -q systemMessage "$T/out" && ok "and the third says so" || bad "no note on the third attempt"
d=$(run_bash "gh pr comment 9 --body '$DENSE More words here.'" $S)
[ "$d" = 2 ] && ok "an edited body is judged again" || bad "edited body let through ($d)"

# ---- mute
[ "$(GH_PROSE_OFF=1 run_bash "gh pr comment 3 --body '$DENSE'")" != 2 ] && ok "GH_PROSE_OFF=1 mutes it" || bad "GH_PROSE_OFF ignored"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
