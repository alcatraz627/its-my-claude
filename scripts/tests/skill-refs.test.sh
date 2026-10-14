#!/usr/bin/env bash
# Checks that the skill-text defects from the process-skills review stay fixed.
# Each check greps for the defect (or for the required line) and fails if it
# reappears. Run: bash ~/.claude/scripts/tests/skill-refs.test.sh
set -u
R="${CLAUDE_HOME:-$HOME/.claude}"
fail=0
pass=0

bad() { echo "FAIL $1"; fail=$((fail + 1)); }
ok() { pass=$((pass + 1)); }

# must_absent LABEL PATTERN FILE...  fails when PATTERN matches in any FILE
must_absent() {
  local label="$1" pat="$2"
  shift 2
  if rg -q -i -e "$pat" "$@" 2>/dev/null; then bad "$label: $(rg -n -i -e "$pat" "$@" | head -3)"; else ok; fi
}

# must_present LABEL PATTERN FILE  fails when PATTERN is missing from FILE
must_present() {
  local label="$1" pat="$2" f="$3"
  if rg -q -i -e "$pat" "$f" 2>/dev/null; then ok; else bad "$label: missing in $f"; fi
}

# Finding 3: router:* names do not resolve in the Skill tool.
must_absent "router: caller" '/router:' \
  "$R/CLAUDE.md" "$R/scripts/hooks/persona-suggest.sh" "$R/conventions/absence-run-checklist.md" \
  "$R/skills/wake/SKILL.md" "$R/skills/page/SKILL.md" "$R/skills/plan/SKILL.md" \
  "$R/skills/pick-skill/SKILL.md" "$R/skills/validate/SKILL.md" "$R/skills/intake/SKILL.md"

# Finding 4: the retired fullscreen-dialog ban.
for s in core-dump pick-skill decision-wizard gcc-explore pr-description; do
  must_absent "fullscreen ban in $s" 'fullscreen|tui_fullscreen|dialog tools? hang|never use a dialog tool|are dead in this' "$R/skills/$s/SKILL.md"
done

# Finding 13: long unattended runs must know the compaction opt-in.
for s in wake deadline catchup; do
  must_present "compact-gate line in $s" 'compact-gate\.sh on' "$R/skills/$s/SKILL.md"
done

# Finding 7: the seat builder emits the one-command clause.
out=$(bash "$R/scripts/seat/seat.sh" prompt --role intent-review --out "$R/scratchpad/skill-refs-probe.md" 2>&1)
if printf '%s' "$out" | rg -q -i 'do not chain commands'; then ok; else bad "seat.sh prompt lacks the one-command clause"; fi

# Finding 7: no piped or chained procedure in bloop and magi.
must_absent "bloop 4.0 pipe" 'git diff <range> \|' "$R/skills/bloop/SKILL.md"
must_absent "magi echo|jq" 'echo "\$RESULT" \|' "$R/skills/magi/SKILL.md"

# Finding 9d: magi must not cite the dead fable sentinel.
must_absent "magi fable sentinel" 'allow-fable-subagents' "$R/skills/magi/SKILL.md"
must_present "magi snooze check" 'fable-restrict-subagents' "$R/skills/magi/SKILL.md"

# Finding 10: bloop has one delivery contract and no stale guard claim.
must_absent "bloop stale guard paragraph" 'guard currently BLOCKS' "$R/skills/bloop/SKILL.md"

# Finding 11 and 12: adversarial-review threshold, absolute path, real cite.
must_absent "adversarial >=5 threshold" '≥5 user judgments' "$R/skills/adversarial-review/SKILL.md"
must_absent "adversarial relative runtime-notes" '^Also read `\.claude/skills' "$R/skills/adversarial-review/SKILL.md"
must_absent "git.md Review contract cite" 'git\.md` § Review contract' "$R/skills/adversarial-review/SKILL.md" "$R/skills/skeptical-review/SKILL.md"

# D12: both review skills specify the Coverage and Observations lines.
for s in skeptical-review adversarial-review; do
  must_present "Coverage spec in $s" 'Coverage: files=' "$R/skills/$s/SKILL.md"
  must_present "Observations slot in $s" 'Observations:' "$R/skills/$s/SKILL.md"
done

# Finding 1c to 1e: routers must not end the turn, loop back, or arm /wake.
must_absent "plan halts after routing" '^Then stop\.' "$R/skills/plan/SKILL.md"
must_absent "plan sequences through bloop" 'bloop` Phase 1' "$R/skills/plan/SKILL.md"
must_absent "validate routes back to bloop" 'bloop` Phase 4' "$R/skills/validate/SKILL.md"
must_absent "deadline arms wake" '\*\*Arm `/wake`\*\*' "$R/skills/deadline/SKILL.md"

echo "skill-refs: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
