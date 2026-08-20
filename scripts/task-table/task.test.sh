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
$TT --session cccccccc 2>/dev/null | rg -q "GATES \\(you\\)" && ok "gated row lands in the GATES band" || ko "gated section"
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

export HOME="$REAL"; trash "$SB" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
