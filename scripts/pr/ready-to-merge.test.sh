#!/usr/bin/env bash
# Tests for ready-to-merge.py. GitHub is replaced by recorded answers: fixtures/real-*.json are
# real `gh pr view` responses for a draft PR (slack-automation#248, recorded 2026-11-03), and each
# case changes one thing in them with jq, so the shapes stay real and only the fact under test moves.
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
T=$(mktemp -d)
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

export PR_REVIEW_GATE_GH="$D/fixtures/gh-stub.sh" PR_REVIEW_GATE_STATE="$T/state" FIX_DIR="$T/fix"
export READY_TO_MERGE_ENVS="$D/fixtures/envs-stub.py" READY_TO_MERGE_POLL_S=0 ENVS_JSON="$T/envs.json"
PR="versable-git/slack-automation#248"
HEAD=$(jq -r .headRefOid "$D/fixtures/real-fetch.json")
OUT=""; RC=0

# scenario <fetch jq filter> <extra jq filter>: rebuild the fixtures from the recorded answers, then run
scenario() {
  rm -rf "$T/fix" "$T/envs.json" "$T/state"; mkdir -p "$T/fix"
  jq "(.isDraft = false) | $1" "$D/fixtures/real-fetch.json" > "$T/fix/fetch.json"
  jq "$2" "$D/fixtures/real-extra.json" > "$T/fix/extra.json"
  echo '{"data":{"repository":{"pullRequest":{"reviewThreads":{"totalCount":0,"nodes":[]}}}}}' > "$T/fix/threads.json"
}
run() { OUT=$(python3 "$D/ready-to-merge.py" "$PR" --repo-dir "$T/no-such-clone" "$@" 2>&1); RC=$?; }
expect() { # expect <rc> <text the output must contain> <name>
  if [ "$RC" = "$1" ] && printf '%s' "$OUT" | rg -qF -- "$2"; then ok "$3"; else bad "$3 (rc=$RC, wanted $1 and '$2')"; echo "$OUT" | sed 's/^/        /'; fi
}

echo "-- a ready PR, from the real response"
scenario . .; run
expect 0 "READY TO MERGE" "a clean, non-draft PR with a current Clanky review is ready"
expect 0 "All 2 checks passed" "five old cancelled and skipped reruns do not count, only the newest run of each check"

scenario . '.statusCheckRollup += [{"__typename":"CheckRun","name":"claude / body","workflowName":"pr","status":"COMPLETED","conclusion":"FAILURE","startedAt":"2000-01-01T00:00:00Z"}] | .mergeStateStatus = "BLOCKED"'; run
if printf '%s' "$OUT" | rg -qF "All 2 checks passed"; then ok "an old failed run that a newer run replaced does not count"; else bad "an old failed run that a newer run replaced does not count"; echo "$OUT" | sed 's/^/        /'; fi

echo "-- each precondition on its own"
scenario '.isDraft = true' .; run;                                                   expect 1 "still a draft" "a draft is blocked"
scenario '.mergeable = "CONFLICTING"' '.mergeStateStatus = "DIRTY"'; run;            expect 1 "conflicts with main" "a conflict is blocked and named"
printf '%s' "$OUT" | rg -q "rules require is missing" && bad "a conflict is not also reported as clean branch rules" || ok "a conflict is not also reported as clean branch rules"
scenario '.mergeable = "UNKNOWN"' '.mergeStateStatus = "UNKNOWN"'; run;              expect 1 "has not finished working out whether" "an unfinished GitHub answer is blocked, never read as clean"
scenario . '.mergeStateStatus = "BEHIND"'; run;                                      expect 1 "behind main" "a branch behind its base is blocked when the rules need it current"
scenario . '.mergeStateStatus = "BLOCKED" | .reviewDecision = "REVIEW_REQUIRED"'; run; expect 1 "need an approving review" "a missing required review is blocked"
scenario . '.mergeStateStatus = "BLOCKED"'; run;                                      expect 1 "nothing above shows why" "a blocked branch with no visible cause is still blocked"
scenario . '.latestReviews = [{"author":{"login":"sam"},"state":"CHANGES_REQUESTED"}] | .reviewDecision = "CHANGES_REQUESTED"'; run
expect 1 "sam asked for changes" "a reviewer who asked for changes is named"
scenario . '.statusCheckRollup += [{"__typename":"CheckRun","name":"claude / body","workflowName":"pr","status":"COMPLETED","conclusion":"FAILURE","startedAt":"2099-01-01T00:00:00Z"}] | .mergeStateStatus = "BLOCKED"'; run
expect 1 "1 check failed" "a failing newest run is blocked when the rules need it"
scenario . '.statusCheckRollup += [{"__typename":"CheckRun","name":"claude / body","workflowName":"pr","status":"COMPLETED","conclusion":"FAILURE","startedAt":"2099-01-01T00:00:00Z"}]'; run
expect 0 "none of them is required" "a failing check the rules do not require is only a note"
scenario . '.statusCheckRollup += [{"__typename":"CheckRun","name":"build","workflowName":"pr","status":"IN_PROGRESS","conclusion":"","startedAt":"2099-01-01T00:00:00Z"}]'; run
expect 1 "still running" "a check still running is blocked"
scenario . '.statusCheckRollup += [{"__typename":"StatusContext","context":"ci/legacy","state":"FAILURE","startedAt":"2099-01-01T00:00:00Z"}] | .mergeStateStatus = "BLOCKED"'; run
expect 1 "ci/legacy (failure)" "an old-style status context is read too"
scenario '.state = "MERGED"' .; run;                                                 expect 1 "is merged" "a merged PR is blocked"
scenario '.headRefOid = "ffffffffffffffffffffffffffffffffffffffff"' .; run;          expect 1 "A push landed while this was reading" "a head that moved between the two reads is blocked"

echo "-- review threads"
scenario . .; echo '{"data":{"repository":{"pullRequest":{"reviewThreads":{"totalCount":1,"nodes":[{"isResolved":false,"isOutdated":false,"path":"src/a.py","comments":{"nodes":[{"author":{"login":"sam"},"body":"Why not use the helper?"}]}}]}}}}}' > "$T/fix/threads.json"; run
expect 1 "src/a.py, sam: Why not use the helper?" "an unresolved thread is blocked and quoted"
scenario . .; rm "$T/fix/threads.json"; run;                                         expect 0 "Could not read the review threads" "unreadable threads are listed as not checked, not as clear"

echo "-- Clanky"
FINDING='. + "\n### P2 1. a.py:3 · sym\nThe helper skips an empty list.\n"'
scenario ".comments |= map(if .author.login == \"clanky-gh\" and (.body | startswith(\"<!-- pr-claude:review\")) then .body |= ($FINDING) else . end)" .; run
expect 1 "no answer yet" "a finding nobody answered is blocked"
mkdir -p "$T/state"; REVSHA=$(jq -r '.comments[] | .body | capture("pr-claude:review:sha=(?<s>[0-9a-f]+)").s' "$D/fixtures/real-fetch.json" | head -n 1)
FTEXT="a.py:3 · sym · The helper skips an empty list."
printf '%s\n' "{\"pr\":\"versable-git/slack-automation#248\",\"sha\":\"$REVSHA\",\"n\":1,\"disposition\":\"will-fix\",\"reason\":\"next push\",\"finding\":\"$FTEXT\"}" > "$T/state/ledger.jsonl"; run
expect 1 "marked will-fix" "a finding answered will-fix and not fixed is blocked"
printf '%s\n' "{\"pr\":\"versable-git/slack-automation#248\",\"sha\":\"$REVSHA\",\"n\":1,\"disposition\":\"optional\",\"reason\":\"style\",\"finding\":\"$FTEXT\"}" > "$T/state/ledger.jsonl"; run
expect 0 "every finding is answered (1 optional)" "a finding answered optional is ready"
scenario '.title = "[nobot] smoke"' .; run;                                          expect 0 "no-bot tag" "a no-bot title skips the Clanky row"
scenario '.comments |= map(select(.body | startswith("<!-- pr-claude:review") | not))' .; run
expect 1 "Clanky has not reviewed this PR yet" "a versable-git PR with no Clanky review is blocked"
scenario '.headRefOid = "0000000000000000000000000000000000000000"' '.headRefOid = "0000000000000000000000000000000000000000"'; run
expect 1 "older push" "a push after Clanky's review is blocked"

echo "-- target branch from the env map"
scenario . '.baseRefName = "main" | .headRefName = "feature-x"'; echo '{"staging_branch":"development","release_branch":"main"}' > "$T/envs.json"; run
expect 1 "targets main, which is production" "a feature PR into the release branch is blocked"
scenario . '.baseRefName = "main" | .headRefName = "development"'; echo '{"staging_branch":"development","release_branch":"main"}' > "$T/envs.json"; run
expect 0 "READY TO MERGE" "a promotion from staging to release is allowed"
scenario . .; echo '{"staging_branch":null}' > "$T/envs.json"; run;                  expect 0 "has no branch for slack-automation" "a repo missing from the map is listed as not checked"

echo "-- unpushed local commits"
G="$T/clone"; mkdir -p "$G"; git -C "$G" init -q -b feat; git -C "$G" remote add origin https://github.com/versable-git/slack-automation.git
git -C "$G" -c user.name=t -c user.email=t@t commit -q --allow-empty -m one; H1=$(git -C "$G" rev-parse HEAD)
git -C "$G" -c user.name=t -c user.email=t@t commit -q --allow-empty -m two
scenario . '.headRefName = "feat"'
sed -i '' -e "s/$HEAD/$H1/g" -e "s/$REVSHA/${H1:0:${#REVSHA}}/g" "$T/fix/fetch.json" "$T/fix/extra.json"  # Clanky's review names the short sha
OUT=$(python3 "$D/ready-to-merge.py" "$PR" --repo-dir "$G" 2>&1); RC=$?
expect 1 "1 commit on your local feat is not on the PR" "a local commit the PR does not have is blocked"
git -C "$G" reset -q --hard "$H1"
OUT=$(python3 "$D/ready-to-merge.py" "$PR" --repo-dir "$G" 2>&1); RC=$?
expect 0 "Everything on your local feat is already on the PR" "a clone level with the PR is ready"

echo "-- GitHub unreadable"
rm -rf "$T/fix"; mkdir -p "$T/fix"; run;                                              expect 2 "Could not read" "an unreadable PR exits 2, not 0 or 1"
scenario . .; run --json
printf '%s' "$OUT" | jq -e '.ready == true and (.checks | length) > 5' >/dev/null 2>&1 && ok "--json carries the verdict and every row" || bad "--json carries the verdict and every row"

echo "---- pass=$pass fail=$fail"
cd / && trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
