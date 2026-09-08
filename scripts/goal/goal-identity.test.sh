#!/usr/bin/env bash
# goal-identity.test.sh — a goal is its text, not the session that armed it.
#
# The store keys one file per session id, so it never looked wrong: nothing was
# appended to a list and no record was malformed. What it lost was the fact that
# two records are the SAME goal. Every resume gets a fresh sid, catchup re-arms
# the checkpoint goal verbatim under it, and a week of resuming one piece of work
# leaves a pile no query can collapse. Measured 2026-09-04: 44 records, and
# nothing could say how many goals that was.
#
# goal_id is a content hash over the normalised text. The file stays at
# $GOALS/$SID.json so every reader is untouched; this adds identity, it does not
# move anything.
#
# Run: bash ~/.claude/scripts/goal/goal-identity.test.sh
set -uo pipefail

G="$HOME/.claude/scripts/goal/goal.sh"
ROOT="$(mktemp -d "${TMPDIR:-/tmp}/goalid-XXXXXX")"
trap 'rm -rf "$ROOT"' EXIT
mkdir -p "$ROOT/.claude/goals"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1"; echo "        got  [$2]"; echo "        want [$3]"; fi; }
has(){ if printf '%s' "$2" | rg -q -- "$3" 2>/dev/null; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — no match for [$3]"; fi; }

set_as(){ # set_as <sid> <by> <text>
  HOME="$ROOT" CLAUDE_CODE_SESSION_ID="$1" bash "$G" set --by "$2" "$3" 2>&1
}
gid_of(){ jq -r '.goal_id' "$ROOT/.claude/goals/$1.json"; }

TEXT="The runner suite is green at head and every check is mutation-proven."

echo "── the same text in three sessions is ONE goal ──"
o1=$(set_as sid-aaaa owner "$TEXT")
has "the first one is announced as new" "$o1" 'new goal'
o2=$(set_as sid-bbbb catchup "$TEXT")
has "the second says it is a re-arm"    "$o2" 'RE-ARMED'
o3=$(set_as sid-cccc catchup "$TEXT")
has "and so does the third"             "$o3" 're-arm #2'

ok "all three carry the same id" \
   "$([ "$(gid_of sid-aaaa)" = "$(gid_of sid-bbbb)" ] && [ "$(gid_of sid-bbbb)" = "$(gid_of sid-cccc)" ] && echo yes || echo no)" "yes"

echo "── lineage survives the re-arm ──"
# first_by is what answers "which goals did the owner set". Without it the third
# record says by=catchup and the owner's authorship is gone.
ok "first_by is the owner, not the last re-armer" "$(jq -r '.first_by' "$ROOT/.claude/goals/sid-cccc.json")" "owner"
# Written when `by` held the mechanism too; it now holds the party and `via`
# holds the mechanism, so this asserts both rather than the old merged value.
ok "by records the re-arming party"               "$(jq -r '.by' "$ROOT/.claude/goals/sid-cccc.json")" "agent"
ok "via records the mechanism that re-armed it"   "$(jq -r '.via' "$ROOT/.claude/goals/sid-cccc.json")" "catchup"
ok "first_set_at comes from the first record"     "$(jq -r '.first_set_at' "$ROOT/.claude/goals/sid-cccc.json")" "$(jq -r '.first_set_at' "$ROOT/.claude/goals/sid-aaaa.json")"
ok "every session that armed it is listed"        "$(jq -r '.sids | length' "$ROOT/.claude/goals/sid-cccc.json")" "3"

echo "── the hash normalises case and whitespace, and nothing else ──"
set_as sid-dddd owner "  THE RUNNER SUITE IS GREEN AT HEAD   AND EVERY CHECK IS MUTATION-PROVEN.  " > /dev/null
ok "case and spacing do not make a new goal" "$(gid_of sid-dddd)" "$(gid_of sid-aaaa)"

# Two goals that differ by a real clause are TWO goals. Merging them would lose
# whichever text the owner meant, so the identity hash is exact on purpose.
set_as sid-eeee owner "$TEXT And the deploy is smoke-checked." > /dev/null
ok "an appended clause is a different goal" \
   "$([ "$(gid_of sid-eeee)" = "$(gid_of sid-aaaa)" ] && echo same || echo different)" "different"

echo "── survey collapses the records and reports the near-miss ──"
s=$(HOME="$ROOT" bash "$G" survey 2>&1)
has "it counts goals, not records" "$s" '2 distinct goal\(s\) across 5 record\(s\)'
has "the re-armed one shows its count" "$s" '×4'
# The near pair here shares a long opening and diverges at the end, which is the
# shape that actually occurs. A whole-string ratio scores it about 0.7 and would
# drop it, so the shared-prefix test is what catches it.
has "the near-duplicate pair is reported" "$s" 'near-duplicate pair'
# The block prints normalised text, which the header says; the original wording
# is in the goal list above. Asserting the raw casing here would pin a display
# detail that deliberately does not hold.
has "and it shows where they diverge"     "$s" 'and the deploy is smoke-checked'
has "reported, never merged"              "$s" 'NOT merged'

echo "── a record written before identity existed still groups ──"
# Old files carry no goal_id. survey hashes them on read so the existing pile
# collapses without anyone rewriting their files.
python3 - "$ROOT/.claude/goals/sid-legacy.json" "$TEXT" <<'PY'
import json, sys
json.dump({"set": True, "text": sys.argv[2], "by": "owner", "sid": "sid-legacy",
           "cwd": "/tmp", "set_at": "2026-08-01T00:00:00Z"}, open(sys.argv[1], "w"))
PY
s=$(HOME="$ROOT" bash "$G" survey 2>&1)
has "the legacy record joins its goal" "$s" '×5'
has "and the total still says 2 goals" "$s" '2 distinct goal\(s\) across 6 record\(s\)'

echo "── by and via are two closed fields, so 'which did the owner set' is an equality test ──"
# `by` used to hold three orthogonal things at once. Measured 2026-09-04: 13
# values over 44 records, mixing roles (owner, user, owner-ruling), mechanisms
# (catchup, core-dump) and session aliases (gcp-fable, walmart, watcher).
byvia(){ jq -r '"\(.by) \(.via)"' "$ROOT/.claude/goals/$1.json"; }

set_as v-owner owner "owner text one" > /dev/null
ok "owner is the deciding party, set by hand" "$(byvia v-owner)" "owner manual"
set_as v-user user "owner text two" > /dev/null
ok "user is the same party under another name" "$(byvia v-user)" "owner manual"
set_as v-ruling owner-ruling "owner text three" > /dev/null
ok "so is owner-ruling" "$(byvia v-ruling)" "owner manual"

# The two callers that write most records must keep working. Refusing them was
# never an option; they are mapped instead.
set_as v-catchup catchup "agent text one" > /dev/null
ok "catchup becomes an agent goal, via catchup" "$(byvia v-catchup)" "agent catchup"
set_as v-cd core-dump "agent text two" > /dev/null
ok "core-dump likewise" "$(byvia v-cd)" "agent core-dump"

# And they map SILENTLY. Warning on the healthy path every time teaches the
# reader to skip the channel, so only an unrecognised value speaks.
_q=$(set_as v-quiet catchup "agent text three")
ok "a known mechanism maps without a warning" "$(printf '%s' "$_q" | rg -c 'not a deciding party' || echo 0)" "0"

# A session alias is not a fourth axis: sid already records which agent.
_w=$(set_as v-alias gcp-fable "agent text four")
ok "a session alias is recorded as an agent" "$(byvia v-alias)" "agent manual"
has "and it says why, naming both sets" "$_w" 'a session alias belongs in sid'
has "the warning lists the deciding parties" "$_w" 'who: owner agent'

# An unknown mechanism is named and recorded as via=unknown, never guessed and
# never a reason to drop the goal (A13, owner default accepted 2026-09-05: the
# one field that could lose a goal was the only one with a hard gate).
_r=$(HOME="$ROOT" CLAUDE_CODE_SESSION_ID=v-bad bash "$G" set --by owner --via telepathy "x" 2>&1)
has "an unknown via is named" "$_r" 'not a known mechanism'
ok "and the goal is still written, with via=unknown" "$(byvia v-bad)" "owner unknown"

s=$(HOME="$ROOT" bash "$G" survey 2>&1)
has "survey answers the owner question directly" "$s" 'the owner set,'

echo "── the register is read on every write, which is what makes a re-arm safe ──"
# /catchup revives a checkpoint goal marked STILL VALID verbatim. Nothing used to
# read it on the way back in, which is how prose-shaped goals kept propagating
# for days after the register was rewritten. WARN tier throughout: the owner's
# own goals go through this path and a register that can block him is worse than
# one he sometimes ignores.
lint(){ HOME="$ROOT" bash "$G" lint "$1" 2>&1; }

# The owner's own best goal, from the register's worked example. Silence here is
# the case that matters most: a linter that fires on good input gets muted.
_good=$(lint "A nontechnical teammate gets one real JEGS workbook through the console alone: upload, preview, run, read the results, export. No step needs me.")
ok "a good goal draws no finding" "$(printf '%s' "$_good" | rg -c 'register finding' || echo 0)" "0"

# Finite sets are fine. "every open row in /tasks" names something on disk; the
# defect is a universal over a set nobody can enumerate.
_fin=$(lint "Every open row in /tasks sits under a goal and a milestone. Every row under GATES is one I can act on today.")
ok "a universal over a FINITE set is not flagged" "$(printf '%s' "$_fin" | rg -c 'unbounded quantifier' || echo 0)" "0"

has "an unbounded quantifier is named" \
    "$(lint 'Every way stage 7 can fail shows an operator what happened.')" 'unbounded quantifier'
has "a standing behaviour is named" \
    "$(lint 'Every question another lane sends is answered the turn it arrives.')" 'standing behaviour'
has "a checklist is named" \
    "$(lint 'Fix all 14 findings (H1..L5), then continue REMAINING-WORK.md')" 'reads as a checklist'
has "one long sentence is named" \
    "$(lint "Level 4 is closed in the runner's own suite and every one of the nine checks is proven by a planted defect that turns its test red and is then restored rather than by inspection, and a caller key with no capability list is visible rather than silent, and keystore list and revoke are driven through the CLI, and punctured output is gone so every row reaches a terminal state carrying a reason a person can read")" \
    'one long sentence'
# The rule file's REAL Before example, full stops intact. The long-sentence rule
# above is proved on a rewritten copy with the stops replaced by "and", which is
# fair for THAT rule but let the real text pass the whole register (adv-goal F2).
# The real text must trip the widened quantifier check on "every one of the nine".
has "the rule file's own Before example is named, as written" \
    "$(lint "Level 4 is closed in the runner's own suite. Every one of the nine checks is proven by a planted defect that turns its test red and is then restored, not by inspection. A caller key with no capability list is visible rather than silent.")" \
    'unbounded quantifier'
has "an owner-actor clause is still named" \
    "$(lint 'Draft the migration and get the owner approval before applying it.')" 'OWNER action'

# A summary that undercounts what is on screen teaches the reader to distrust it.
_two=$(lint "Draft the migration and get the owner's approval, and make sure every way it can fail is visible.")
has "two findings are counted as two" "$_two" '2 register finding'

# The register is a READ, not a gate: the write still happens.
set_as r-lint owner "Every way it can fail is visible." > /dev/null 2>&1
ok "a flagged goal is still written" "$([ -f "$ROOT/.claude/goals/r-lint.json" ] && echo written || echo refused)" "written"
_w=$(set_as r-lint2 catchup "Every way it can fail is visible.")
has "and a re-arm reads the register too" "$_w" 'unbounded quantifier'

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
