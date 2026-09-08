#!/usr/bin/env bash
# task.test.sh — task.sh writes the same store shape the Task tool writes, and
# task-table.sh reads it back.
set -uo pipefail
T=/Users/alcatraz627/.claude/scripts/task-table/task.sh; TT=/Users/alcatraz627/.claude/scripts/task-table/task-table.sh
pass=0; fail=0; ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }
SB=$(mktemp -d); REAL="$HOME"; export HOME="$SB"; mkdir -p "$HOME/.claude/tasks" "$HOME/.claude/scripts/task-table"; cp "$T" "$TT" "$HOME/.claude/scripts/task-table/"; T="$HOME/.claude/scripts/task-table/task.sh"; TT="$HOME/.claude/scripts/task-table/task-table.sh"
export CLAUDE_CODE_SESSION_ID=cccccccc-0000-0000-0000-000000000003
$T store >/dev/null 2>&1; [ $? -eq 4 ] && ok "no store: rc 4, says so" || ko "no store rc"
$T add "first thing" --new --class spec --domain gcc >/dev/null && ok "--new creates the store and adds" || ko "add --new"
S="$HOME/.claude/tasks/session-cccccccc"; [ -f "$S/1.json" ] && ok "id 1 allocated" || ko "id 1"
jq -e '.id=="1" and .status=="pending" and .metadata.class=="spec" and .metadata.domain=="gcc" and (.blocks|type)=="array" and (.blockedBy|type)=="array" and has("activeForm") and has("description")' "$S/1.json" >/dev/null && ok "shape matches the Task tool's file" || ko "shape"
$T add "second, gated" --blocked-on "USER: rule me" --verified false --blocked-by 1 >/dev/null; jq -e '.id=="2" and .metadata.blocked_on=="USER: rule me" and .metadata.verified==false and .blockedBy==["1"]' "$S/2.json" >/dev/null && ok "flags land in metadata/blockedBy" || ko "flags"
$T update 1 --status in_progress --append-desc "note one" >/dev/null; jq -e '.status=="in_progress" and (.description|test("note one"))' "$S/1.json" >/dev/null && ok "update patches in place" || ko "update"
$T meta 2 verified=prod owner=me >/dev/null; jq -e '.metadata.verified=="prod" and .metadata.owner=="me"' "$S/2.json" >/dev/null && ok "meta sets arbitrary keys" || ko "meta"
$T done 1 >/dev/null; jq -e '.status=="completed"' "$S/1.json" >/dev/null && ok "done completes" || ko "done"
$T update 99 --status completed >/dev/null 2>&1; [ $? -eq 1 ] && ok "unknown id: rc 1" || ko "unknown id"
$T update 2 --bogus x >/dev/null 2>&1; [ $? -eq 2 ] && ok "unknown flag: rc 2, nothing written" || ko "unknown flag"
jq -e '.metadata.owner=="me"' "$S/2.json" >/dev/null && ok "file untouched after bad flag" || ko "bad flag wrote"
mkdir "$S/.task-sh.lock"; out=$( (sleep 0.6; rmdir "$S/.task-sh.lock") & $T add "third, waited for the lock" ); echo "$out" | rg -q "added #3" && ok "waits for a held lock, then writes" || ko "lock wait: $out"
[ ! -d "$S/.task-sh.lock" ] && ok "lock released" || ko "lock left"
$T add "fourth" --session cccccccc >/dev/null; [ -f "$S/4.json" ] && ok "--session picks the store" || ko "--session"
ls "$S" | rg -q "tmp" && ko "temp file left" || ok "no temp files left"
$TT --session cccccccc 2>/dev/null | rg -q "second, gated" && ok "task-table.sh renders the store" || ko "table read"
$TT --session cccccccc 2>/dev/null | rg -q "⚡ CLEAR NOW" && ok "gated row reaches CLEAR NOW" || ko "gated section"
$T list | rg -q "^   3  pending" && ok "list prints" || ko "list"
echo "== D7: every rejection names the whole acceptable set =="
# Owner ruling 2026-08-20, verbatim: "Map and refuse and on every bad flag print a
# helper warning with all the acceptable messages (irrespective of it being a warn
# or error type)." Each row below asserts BOTH halves: the verdict AND the set.

err=$($T update 3 --status done 2>&1 >/dev/null)
case "$err" in *'writing "completed"'*) ok "colloquial 'done' maps to completed" ;;
                                     *) ko "'done' was not mapped: $err" ;; esac
case "$err" in *"pending in_progress completed"*) ok "the mapping warning still names the set" ;;
                                               *) ko "mapping warning named no acceptable set" ;; esac
$T show 3 2>/dev/null | rg -q '"status": "completed"' \
  && ok "the file records the canonical spelling, not the colloquial one" \
  || ko "store kept a non-canonical status"

err=$($T update 3 --status finito 2>&1 >/dev/null); rc=$?
case "$err" in *"does not accept"*) ok "an unmappable status is refused" ;;
                                 *) ko "bad status was accepted: $err" ;; esac
case "$err" in *"pending in_progress completed"*) ok "the refusal names the set" ;;
                                               *) ko "refusal named no acceptable set" ;; esac

err=$($T update 3 --tier gpt5 2>&1 >/dev/null)
case "$err" in *"fable opus sonnet haiku lm"*) ok "a bad tier is refused WITH the set" ;;
                                            *) ko "tier refusal named no set: $err" ;; esac

err=$($T update 3 --sessionn xyz 2>&1 >/dev/null)
case "$err" in *"unknown flag"*) ok "an unknown flag is still refused" ;;
                              *) ko "unknown flag not refused" ;; esac
case "$err" in *"--status"*) ok "the unknown-flag error lists the real flags" ;;
                          *) ko "unknown-flag error listed nothing: $err" ;; esac
# derived, not hand-maintained: a flag added to the parser must appear here
case "$err" in *"--blocked-on"*) ok "the flag list is derived from the parser itself" ;;
                              *) ko "flag list looks hand-maintained" ;; esac

# and the canonical values still pass untouched
$T update 3 --status pending >/dev/null 2>&1 && ok "a canonical status is accepted silently" || ko "canonical status refused"

echo "== meta cannot walk around the vocabularies the flags enforce =="
# `--tier nonsense` was refused while `meta tier=nonsense` wrote it without a
# word, which made the flag-path validator decorative. Three tiers now: a closed
# vocabulary is refused, a key shadowing a top-level field is refused, and an
# unfamiliar key is warned but still written so meta stays an escape hatch.
$T meta 3 tier=nonsense >/dev/null 2>&1 && ko "meta wrote an invalid tier" || ok "meta refuses a tier the flag path refuses"
jq -e '.metadata.tier != "nonsense"' "$S/3.json" >/dev/null && ok "and the refusal wrote nothing" || ko "refused but wrote anyway"
err=$($T meta 3 tier=nonsense 2>&1 >/dev/null)
case "$err" in *"fable"*"opus"*) ok "the meta refusal names the whole set" ;; *) ko "meta refusal hid the set" ;; esac

$T meta 3 status=whatever >/dev/null 2>&1 && ko "meta minted a shadow status" || ok "meta refuses a key that shadows a top-level field"
jq -e '.metadata.status == null' "$S/3.json" >/dev/null && ok "no shadow key on disk" || ko "shadow key written"
err=$($T meta 3 status=whatever 2>&1 >/dev/null)
case "$err" in *"task.sh update"*) ok "and it names the flag to use instead" ;; *) ko "shadow refusal offered no route" ;; esac

# The escape hatch stays open, which is the whole reason meta exists. It warns.
$T meta 3 laen=hands >/dev/null 2>&1 && ok "an unfamiliar key is still written" || ko "meta closed its escape hatch"
jq -e '.metadata.laen == "hands"' "$S/3.json" >/dev/null && ok "the unfamiliar key landed" || ko "unfamiliar key lost"
err=$($T meta 3 laen=hands 2>&1 >/dev/null)
case "$err" in *"not a key anything reads"*) ok "and the typo is called out" ;; *) ko "typo written in silence" ;; esac

# A vocabulary here must never be TIGHTER than the flag it mirrors. `prod` is a
# documented --verified value; a first draft refused it and this case caught it.
$T meta 3 verified=prod >/dev/null 2>&1 && ok "a documented value the flag allows is allowed here too" || ko "meta is stricter than its flag"

echo "== containment at the write path: D6a and D3b describe different rows =="
# goal with no milestone is malformed on its face under three-levels-always.
$T add "has a goal, no milestone" --goal "G" >/dev/null 2>&1 && ko "a goal without a milestone was written" || ok "a goal without a milestone is refused"
err=$($T add "has a goal, no milestone" --goal "G" 2>&1 >/dev/null)
case "$err" in *"--batch"*) ok "the refusal names the flag that fixes it" ;; *) ko "refusal offered no route" ;; esac
case "$err" in *"Right now,"*) ok "and it carries the milestone naming test" ;; *) ko "no naming test in the refusal" ;; esac

# Neither is D3b's case: ALLOWED, because refusing it would contradict the
# ruling and would break every peer session that adds a row today.
$T add "wholly unfiled row" >/dev/null 2>&1 && ok "an unfiled row is still allowed (D3b)" || ko "D3b's allowed case was refused"
err=$($T add "another unfiled row" 2>&1 >/dev/null)
case "$err" in *"UNFILED"*) ok "but it says so loudly" ;; *) ko "unfiled row written in silence" ;; esac

# A milestone with no goal is the measured 38-row orphan shape. Allowed: the
# goal is what is missing, and D3b governs that.
$T add "orphan milestone row" --batch "M" >/dev/null 2>&1 && ok "a milestone without a goal is allowed" || ko "orphan milestone refused"

# The lock must survive a death inside the critical section. Before the EXIT
# trap, one bad expansion inside with_lock left the directory behind and every
# later call to that store waited 5s and refused: the store was wedged and
# nothing said why.
mkdir -p "$S/.task-sh.lock"
rmdir "$S/.task-sh.lock"
$T add "after a lock cycle" --goal "G" --batch "M" >/dev/null 2>&1
[ -d "$S/.task-sh.lock" ] && ko "the lock outlived its operation" || ok "the lock is released, not leaked"

echo "== the seven states (D2 plus D7a), on both write paths =="
# metadata.state is SEPARATE from top-level status on purpose. status belongs to
# the harness Task tool, which writes these same files and knows only its three
# values, so widening it would hand the harness something it cannot read.
_allseven=1
for s in owner-gate blocked active review deferred done unassigned; do
  $T update 3 --state "$s" >/dev/null 2>&1 || _allseven=0
  [ "$(jq -r '.metadata.state' "$S/3.json")" = "$s" ] || _allseven=0
done
[ "$_allseven" = 1 ] && ok "all seven states are accepted and land" || ko "a ruled state was refused or lost"

$T update 3 --state nonsense >/dev/null 2>&1 && ko "an eighth state was accepted" || ok "an eighth state is refused"
err=$($T update 3 --state nonsense 2>&1 >/dev/null)
case "$err" in *"unassigned"*) ok "the state refusal names the whole set" ;; *) ko "state refusal hid the set" ;; esac

# The residual D7a exists for. Without it the migration's only home for 156 of
# 181 open rows was `active`, which breaks one-active-row-per-lane on all four.
$T update 3 --state unassigned >/dev/null 2>&1
[ "$(jq -r '.metadata.state' "$S/3.json")" = "unassigned" ] && ok "unassigned is a real state, not a placeholder" || ko "unassigned missing"

$T meta 3 state=nonsense >/dev/null 2>&1 && ko "meta walked around the state enum" || ok "meta inherits the state enum"

# The separation is the load-bearing part: if a future edit merges them, the
# harness Task tool starts reading a value it does not know.
$T update 3 --state deferred >/dev/null 2>&1
case "$(jq -r '.status' "$S/3.json")" in
  pending|in_progress|completed) ok "top-level status stays in the harness vocabulary" ;;
  *) ko "status was widened; the harness Task tool cannot read it" ;;
esac

echo "== the ledger's three task.sh defects (2026-09-08) =="
$T add "closes with the flag" >/dev/null; idv=$(ls "$S" | rg -o '^[0-9]+' | sort -n | tail -1)
out=$($T done "$idv" --verified "task.test.sh ran it" 2>&1)
jq -e '.status=="completed" and .metadata.verified=="task.test.sh ran it"' "$S/$idv.json" >/dev/null && ok "done <id> --verified <text> closes WITH the instrument" || ko "done --verified: $(jq -c '{status,v:.metadata.verified}' "$S/$idv.json")"
echo "$out" | rg -q "NO instrument" && ko "warned for an instrument it was given" || ok "no warning when the instrument was given"
$T add "meta takes a name" >/dev/null; idm=$(ls "$S" | rg -o '^[0-9]+' | sort -n | tail -1)
$T meta "$idm" verified="goal-box.test.sh 80/0" >/dev/null 2>&1; jq -e '.metadata.verified=="goal-box.test.sh 80/0"' "$S/$idm.json" >/dev/null && ok "meta verified=<instrument name> is accepted" || ko "meta refused the instrument name"
out=$($T update "$idm" --state review 2>&1); echo "$out" | rg -q "pending \(review\)" && ok "the update echo names the state it set" || ko "update echo: $out"

echo "== ledger 43, 45, 47 (2026-09-08): note without desc warns, reversed edge refused, --json carries description =="
out=$($T add "noted only" --note "just a note" 2>&1 >/dev/null); echo "$out" | rg -q "without --desc" && ok "add --note with no --desc says the description is what a close is judged against" || ko "no warning: $out"
idn=$(ls "$S" | rg -o '^[0-9]+' | sort -n | tail -1)
$T add "child of the noted row" >/dev/null; idc=$(ls "$S" | rg -o '^[0-9]+' | sort -n | tail -1)
$T update "$idn" --blocked-by "$idc" >/dev/null 2>&1
$T update "$idc" --blocked-by "$idn" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "a reversed --blocked-by edge is refused (rc 2)" || ko "reversed edge accepted (rc $rc)"
jq -e '.blockedBy == []' "$S/$idc.json" >/dev/null && ok "the refused edge wrote nothing" || ko "the refused edge was written"
$T update "$idc" --desc "the child's ask" >/dev/null
$TT --session cccccccc --json 2>/dev/null | jq -e --arg id "$idc" '.tasks[] | select((.id|tostring)==$id) | .description == "the child'"'"'s ask"' >/dev/null && ok "--json carries description under its own name" || ko "json description missing"

echo "== P3 (#24, 2026-09-08): what a goal says about itself lives in the store's .goals sidecar =="
$T add "row under a real goal" --goal "The screen never lies" --batch "The header is right" >/dev/null 2>&1
idg=$(ls "$S" | rg -o '^[0-9]+' | sort -n | tail -1)
$T goal "$idg" --direction "See where things stand" --when "checks 1 and 3 are green" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && [ -f "$S/.goals" ] && ok "goal <id> writes the sidecar, resolving the id to its goal text" || ko "goal by id (rc $rc)"
jq -e '.["The screen never lies"].direction=="See where things stand" and .["The screen never lies"].when=="checks 1 and 3 are green" and (.["The screen never lies"].set_at|length)>0' "$S/.goals" >/dev/null && ok "keyed by goal text, both fields and a timestamp" || ko "sidecar shape: $(cat "$S/.goals")"
$T goal "The screen never lies" --when "" >/dev/null 2>&1
jq -e '.["The screen never lies"] | (has("when")|not) and .direction=="See where things stand"' "$S/.goals" >/dev/null && ok "an empty value clears one field and leaves the other" || ko "clear: $(cat "$S/.goals")"
out=$($T goal "The screen never lies" 2>&1); echo "$out" | rg -q '"direction": "See where things stand"' && ok "no flag shows what is set" || ko "show: $out"
$T goal "a goal nobody filed" --direction x >/dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && ok "a goal no row carries is refused (rc 1)" || ko "unfiled goal accepted (rc $rc)"
err=$($T goal "a goal nobody filed" --direction x 2>&1 >/dev/null); echo "$err" | rg -q "The screen never lies" && ok "and the refusal lists the goals this store has" || ko "refusal named no goals: $err"
$T goal "$idg" --bogus x >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "an unknown flag is refused (rc 2)" || ko "bad flag rc $rc"
$T goal "$idg" --direction >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "a flag with no value is refused, not looped on" || ko "dangling flag rc $rc"
jq -e '.["The screen never lies"].direction=="See where things stand"' "$S/.goals" >/dev/null && ok "the refusals wrote nothing" || ko "a refusal wrote"
$T goal 1 --direction x >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "an id whose row carries no goal is refused and told to file it" || ko "goalless id rc $rc"
[ ! -d "$S/.task-sh.lock" ] && ok "the lock is released after goal" || ko "lock left by goal"
ls "$S" | rg -q '^\.goals\.json$' && ko "the sidecar must not end in .json (pathlib reads it as a row)" || ok "the sidecar is .goals, no .json suffix"
# --group goal: this store's rows mostly carry class and domain, so auto-grouping
# picks one of those, and a direction belongs to a goal box only.
$TT --session cccccccc --group goal 2>/dev/null | rg -q '^🧭 See where things stand$' && ok "the renderer draws the direction from the sidecar" || ko "direction not drawn"
$TT --session cccccccc --json 2>/dev/null | jq -e '.goals["The screen never lies"].direction=="See where things stand"' >/dev/null && ok "--json carries the goal-level fields" || ko "json goals missing"

export HOME="$REAL"; trash "$SB" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
