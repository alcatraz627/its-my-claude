#!/usr/bin/env bash
export HOOK_TEST=1  # keeps the hook's ledger writes out of the live log
# persona-suggest.sh: the planning persona is suggested only when the prompt asks
# for planning (a verb, or a request to make a plan), never because the word
# "plan" names a plan that already exists.
set -uo pipefail
HOOK="${PERSONA_SUGGEST_BIN:-$HOME/.claude/scripts/hooks/persona-suggest.sh}"
T=$(mktemp -d)
mkdir -p "$T/home/.claude/personas/usage"
ln -s "$HOME/.claude/scripts" "$T/home/.claude/scripts"
export TMPDIR="$T"

pass=0 fail=0
n=0
# run PROMPT [SID]: prints the hook's output; a fresh session id each call unless given.
run() {
  n=$((n+1)); local sid="${2:-pstest$$x$n}"
  jq -cn --arg s "$sid" --arg p "$1" '{session_id:$s, prompt:$p}' | HOME="$T/home" bash "$HOOK"
  rm -f "/tmp/claude-personasuggest-${sid:0:8}"
}
yes_() { if [[ "$2" == *"task-goal-planner"* ]]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; echo "     got: ${2:0:160}"; fi; }
no_()  { if [ -z "$2" ]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; echo "     got: ${2:0:160}"; fi; }

yes_ "lets plan, said as a verb"                 "$(run "ok lets plan the migration to postgres properly before we touch anything")"
yes_ "help me plan"                              "$(run "read this handoff and help me plan and build and test the new importer")"
yes_ "a request to make a plan"                  "$(run "yes lets make a plan for this and lay out review checkpoints along the way")"
yes_ "come up with the best plan"                "$(run "approved subset, come up with the best plan and proceed with the cheaper shape")"
yes_ "plan as a leading imperative"              "$(run "plan the rollout of the new billing system across all three environments")"
yes_ "an adverb between lead and verb"           "$(run "we should thoroughly plan the data move and then do the cutover next week")"
yes_ "how should we approach"                    "$(run "how should we approach the migration of the old reports into the new store")"
yes_ "break this down"                           "$(run "this is a huge ask so break this down into steps we can check one at a time")"
yes_ "curly apostrophe in let's"                 "$(run "ok let’s plan the cutover with a rollback step before we begin the work")"

no_ "where are we in the plan is not a planning ask" "$(run "where are we in the plan, what all is next for the migration this week")"
no_ "a plan path is not a planning ask"          "$(run "check that docs/plan/clanky-hands/workflow.md has the details we agreed on here")"
no_ "your plan file is not a planning ask"       "$(run "adversarial review codex on your plan file and make sure it is documented today")"
no_ "the plan is good is not a planning ask"     "$(run "the refactor plan is good, get the peer to review it before we move on please")"
no_ "planning words inside another word"         "$(run "the airplane planner and the plantation sequence of events are unrelated to this")"
no_ "roadmap alone is not a planning ask"        "$(run "the roadmap page is rendering a blank card on the staging site since this morning")"
no_ "a short prompt stays quiet"                 "$(run "lets plan it")"
no_ "a prompt naming a skill stays quiet"        "$(run "/plan lets plan the whole thing out properly with some checkpoints in between")"

# Other personas are untouched by the planning rule.
out=$(run "should we build the export feature first or is the importer the better thing to build")
if [[ "$out" == *"strategic triad"* ]]; then pass=$((pass+1)); echo "ok   a prioritization cue still suggests the strategic triad"; else fail=$((fail+1)); echo "FAIL a prioritization cue still suggests the strategic triad"; fi

# One suggestion per session.
rm -f /tmp/claude-personasuggest-dedupsid
ask_same() { jq -cn --arg p "$1" '{session_id:"dedupsid1", prompt:$p}' | HOME="$T/home" bash "$HOOK"; }
first=$(ask_same "lets plan the first thing carefully before we start on the build")
second=$(ask_same "lets plan the second thing carefully before we start on the build")
rm -f /tmp/claude-personasuggest-dedupsid
yes_ "the first planning prompt in a session suggests" "$first"
no_ "a second planning prompt in the same session stays quiet" "$second"

trash "$T" >/dev/null 2>&1
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
