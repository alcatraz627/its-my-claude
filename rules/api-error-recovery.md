---
brief: After an API-outage abort, a terse "keep going" means re-orient first — reconstruct goal + what's done + the interrupted step — then continue, rolling back if the abort left things half-done.
triggers:
  - topic:api-error-recovery
  - phrase:keep going
  - phrase:proceed
  - phrase:recover
  - phrase:api error
related:
  - rules/subagent-fleet-discipline.md
  - features/context-retention.md
  - rules/todo-discipline.md
tier: 1
category: rules
updated: 2026-06-18
stale_after_days: 365
---

# Recovering after an API-outage abort

When an interactive turn dies on a transient API error (the
*"Server is temporarily limiting requests · Rate limited"* 429), Claude Code
emits **no** Stop and **no** Notification — the turn just stops, and the only
event that fires is your next prompt. So when the user comes back with a terse
**"keep going" / "proceed" / "recover" / "continue"**, that short message is NOT
"blindly resume the exact next token." It is "pick the work back up correctly."
The abort may have landed mid-tool-sequence, mid-plan, or mid-edit, and the
in-flight reasoning that knew where you were is gone.

## The rule — re-orient before you resume

On a terse resume after an API error, spend the first move re-grounding, in this
order, before taking any new action:

1. **Original goal.** Restate the task you were on in one line. If unsure, read
   the open `Task` list (the live todo source of truth — see [[todo-discipline]])
   and the session workspace / checkpoint.
2. **What's already done.** Don't trust memory — it predates the abort. Check the
   concrete record: the `Task` list statuses, `git status` / `git diff --stat`,
   the WAL tail, recently-modified files. Establish the real current state.
3. **The interrupted step.** Identify the single action that was in flight when
   the turn died. Was a file write completed or truncated? A command half-run? A
   multi-edit partially applied? **Verify it on disk** rather than assuming it
   either fully happened or didn't.
4. **Resume — or roll back, then resume.** If the interrupted step left a clean
   boundary, continue from the next step. If it left something half-done
   (partial edit, orphaned temp file, a commit that didn't finish), **roll that
   step back to its last good state first**, then redo it. A half-applied step
   is worse than an un-started one.

Only after 1-4 do you continue the actual work. One or two tool calls of
re-orientation is cheap insurance against compounding a half-finished edit.

## If the abort was a sub-agent fleet

A terse "recover" after a fleet died means follow [[subagent-fleet-discipline]]:
triage with `fleet-triage.py`, reuse `SALVAGED` outputs, re-dispatch only the
dead, batch if it's the second outage. Don't re-run the whole fleet.

## What this rule does NOT mean

- Not every "keep going" is post-error. If the previous turn ended cleanly, this
  ritual doesn't apply — just continue. The trigger is specifically *resume after
  an aborted turn* (the `api-recovery-nudge` hook detects this and reminds you).
- Re-orientation is bounded: read the state, don't re-investigate the whole
  project. If state is obviously intact (a single isolated edit completed), a
  one-line confirmation is enough.

## Enforcement

Advisory text is invisible to an in-flight session, so this rule is backed by a
mechanical trigger: `scripts/hooks/api-recovery-nudge.sh` (UserPromptSubmit)
detects that the prior real assistant turn was a synthetic API error and injects
a pointer to this ritual into the resuming turn's context. Stop/Notification do
not fire on the abort, but the user's re-prompt always does — that is the hook's
foothold.

## Diagnostic signal

You're about to continue work right after an *"API Error … Rate limited"* turn,
and you have not re-read the Task list / git state / the interrupted step. Stop —
re-orient first.
