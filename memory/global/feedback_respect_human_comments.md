---
name: Human-commented values + independent verification + mistake discipline
description: Ask before changing human-commented code; verify each change independently; log mistake patterns for future agents
type: feedback
---

## Rule 1: Human-commented values require confirmation

Code with `NOTE(by human)`, `HACK`, `IMPORTANT`, or similar comments reflects a deliberate, tested decision. If you think it should change, **ask the user first** with your reasoning. If approved, make the change AND verify the result — report back if it doesn't look right.

A PreToolUse hook (`check-human-comments.sh`) warns when editing files with these markers.

**Why:** User set `.line-row { line-height: 0.25 }` with a clear comment. Agent overrode it silently to 1.6 — the opposite of the user's preference.

## Rule 2: Verify each change independently

When making N distinct changes in one edit, verify each one separately. Don't batch-verify by only checking the primary fix and letting secondary changes ride along unchecked.

**How to apply:**
- N changes → N verification steps (screenshots, test calls, etc.)
- "While I'm here" fixes are encouraged, but each needs its own check
- If you can't verify a secondary change, flag it: "I also changed X — please verify"
- Never assume a numeric value "looks wrong" based on the number alone — render it first

## Rule 3: Mistake pattern discipline

After user corrections, follow the post-correction ritual in CLAUDE.md:
1. State mistake → 2. Identify pattern → 3. Update `~/.claude/mistake-patterns.md` → 4. Check if hook can prevent → 5. Fix

`mistake-patterns.md` is a compact index (max 20 entries) of recurring mistake categories that future agents scan to avoid known pitfalls. Patterns, not incidents.
