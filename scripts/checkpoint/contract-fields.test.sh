#!/usr/bin/env bash
# Tests for validate-checkpoint.sh's Resume Contract field check (task #98).
#
# The failure it guards is a dump whose HEADINGS all parse while a specified
# FIELD is simply absent. That is not hypothetical: the 2026-08-19 dump shipped
# without "Task list, glanced" and this validator returned a clean OK, because
# the field lived in the skill's prose (SKILL.md 2.6) and never in the emitted
# template the agent writes from. A spec nobody writes from is advisory.
#
# The check is WARN TIER by ruling D2a, so every row here asserts on the warn
# TEXT and on exit 0. A row that asserted a non-zero exit would be pinning the
# wrong contract, and would break the day the tier is promoted for a reason.

set -uo pipefail
V="$HOME/.claude/scripts/checkpoint/validate-checkpoint.sh"

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok   $1"; }
bad() { fail=$((fail+1)); echo "  FAIL $1"; }

ALL="Standing constraints|Standing caveats|Next action|Next action's requirements|Blocked on|Expired authorizations|Decaying prerequisites|Verification state|Live commitments|Task list, glanced|Task store|Key anchor"

mk() {  # mk [label-to-omit …] -> path to a dump carrying every OTHER field
  local t; t=$(mktemp -d)
  {
    printf '# Core Dump\n\n## Resume Contract\n\n'
    local IFS='|'
    for lbl in $ALL; do
      local skip=""
      for omit in "$@"; do [ "$lbl" = "$omit" ] && skip=1; done
      [ -n "$skip" ] || printf -- '- **%s:** value\n' "$lbl"
    done
    printf '\n## Initial Goal\nx\n\n## Agent Actions\nx\n\n## Current Expectation\nx\n\n## Pending Items\nx\n'
  } > "$t/cp.md"
  printf '%s' "$t/cp.md"
}

echo "== a complete contract is silent =="
OUT=$(bash "$V" "$(mk)" 2>&1); rc=$?
[ "$rc" = 0 ] && ok "complete contract exits 0" || bad "complete contract exited $rc"
case "$OUT" in *"field(s) absent"*) bad "warned on a contract that has every field";;
                                 *) ok "no warn when nothing is missing";; esac

echo "== the field that started this fires =="
OUT=$(bash "$V" "$(mk 'Task list, glanced')" 2>&1); rc=$?
case "$OUT" in *"'Task list, glanced'"*) ok "the missing glanced field is named";;
                                      *) bad "the glanced field went unreported";; esac
[ "$rc" = 0 ] && ok "a missing field warns, it does not fail (D2a warn tier)" \
              || bad "warn tier regressed to a failure, exit $rc"

echo "== the requirements field is checked too (task #100) =="
OUT=$(bash "$V" "$(mk "Next action's requirements")" 2>&1)
case "$OUT" in *"'Next action's requirements'"*) ok "a missing requirements pointer is named";;
                                              *) bad "the requirements field is in the template but not the check";; esac

echo "== it reports EVERY missing field, not just the first =="
OUT=$(bash "$V" "$(mk 'Expired authorizations' 'Verification state' 'Key anchor')" 2>&1)
n=0
for lbl in "Expired authorizations" "Verification state" "Key anchor"; do
  case "$OUT" in *"'$lbl'"*) n=$((n+1));; esac
done
[ "$n" = 3 ] && ok "all three omissions named" || bad "named only $n of 3 omissions"

echo "== a dump with no Resume Contract is not spammed =="
T=$(mktemp -d)
printf '# X\n\n## Initial Goal\nx\n\n## Agent Actions\nx\n\n## Current Expectation\nx\n\n## Pending Items\nx\n' > "$T/cp.md"
OUT=$(bash "$V" "$T/cp.md" 2>&1)
case "$OUT" in *"field(s) absent"*) bad "listed every field for a dump that has no contract at all";;
                                 *) ok "no contract means no field warn (precompact and older dumps)";; esac

echo "== a mini dump is untouched by the field check =="
printf '# Mini Core Dump\n\n**Goal:** g\n**Resume:** r\n**Done:** d\n**Not Done:** n\n**Next Steps:** s\n' > "$T/mini.md"
OUT=$(bash "$V" "$T/mini.md" --mini 2>&1); rc=$?
[ "$rc" = 0 ] && ok "mini contract still passes" || bad "mini mode broke, exit $rc"
# NOTE: a "field check did not leak into mini mode" row would be vacuous here,
# because --mini returns before the field block is reached. It could not fail,
# and a row that cannot fail pins nothing (rules/testing.md
# [mutation-test-the-guard]). What IS worth pinning is the structural reason:
rg -n -- "--mini" "$V" | head -1 | cut -d: -f1 > "$T/mini_line"
rg -n "Resume Contract field" "$V" | head -1 | cut -d: -f1 > "$T/field_line"
[ "$(cat "$T/mini_line")" -lt "$(cat "$T/field_line")" ] \
  && ok "mini mode returns before the field check, so it can never see it" \
  || bad "the field check now sits above the mini branch and will fire on minis"

echo "== the real dumps on disk =="
R="$HOME/.claude/_20260819-gcc-work-78.claude.md"
if [ -f "$R" ]; then
  bash "$V" "$R" >/dev/null 2>&1 \
    && ok "the live 2026-08-19 dump still passes its parse contract" \
    || bad "the field check broke a real dump's validation"
else
  echo "  skip  live dump absent"
fi

echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
