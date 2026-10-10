---
name: validate
description: Choose and run the checks a Codex change needs before reporting it complete, including runtime, visual, safety, parity, writing, and user intent.
---

# Validate a Codex change

Read the actual diff and the user's request. For every relevant question below, name the check that would answer it, run that check, and record the result. State why an inapplicable check was skipped. A checker result is evidence for its own question only.

| Question | Useful evidence |
|---|---|
| Does it run? | Execute the changed path with a realistic input; the `test` skill can find project commands. |
| Is the code right? | Review changed call sites, invariants, and edge cases; use `probe` for an unconfirmed cause. |
| Does it look right? | Inspect rendered screenshots in each relevant theme and state; use `see`, OCR, or `lm ui-verify` as supporting evidence. |
| Is it safe and consistent? | Check security, types, dependencies, sibling patterns, and project constraints appropriate to the change. |
| Is the writing right? | Read user-facing copy and report prose; use `ste-writing` or the existing prose linter when they apply. |
| Did old behavior survive? | List existing behaviors touched by the change, then exercise a check for each. Include open `callouts` rows. |
| Is this what was asked? | Compare the result with the user's words and accepted corrections; name missing or extra scope. |

For a config, hook, or guard, include one test that makes the guard fire and one that must pass. For a UI, a DOM assertion cannot replace a rendered-frame read. For a large or high-stakes change, seek independent review when an authorized reviewer is available; retain final judgment and do not claim a check that did not run. Report `UNCONFIRMED` for any material question left open.

Source questions and examples: `/Users/alcatraz627/.claude/skills/validate/SKILL.md`. Use its reasoning, not its Claude-only dispatch commands.
