---
name: improve-skill
description: Audit a Claude or Codex skill after a misfire or stale behavior, read its run history, patch an authorized defect, and verify the skill's own usefulness measure. Use for skill behavior repair.
---

# Improve a skill in Codex

Read `/Users/alcatraz627/.claude/skills/improve-skill/SKILL.md` and the target skill. Find the real trigger, companion files, run notes, failures, and its `Validation` rubric. Run `python3 /Users/alcatraz627/.claude/scripts/skill-lint.py <skill-path>` and inspect the warnings; do not turn a generic score into efficacy.

Name the observed failure and a realistic acceptance case before editing. For Codex skills, check whether the entry appears in the current skills list and whether a fresh invocation would see the changed body. Apply changes already authorized by the user; present a concrete patch for any remaining owner decision. Validate the actual trigger and output, not just lint. For source skill edits under `~/.claude`, prepare a full-content schema-1 manifest, preview with `gcc canon check`, and apply with `gcc canon apply` after the required owner review. Run the adapter installer if discovery wiring changed. Do not run Claude's `Task`, `skill-log.sh`, or direct ledger writers from Codex.
