<!-- i-dream project brief · 2026-07-07T06:35:42.610646+00:00 · 16 patterns / 0 insights -->
## What this project is about
A staging enhancement product codebase (Versable) where the dominant working style is strict, explicit-scope execution — the user tolerates zero scope creep and enforces it aggressively.

## Things to do (or keep doing)
- **Execute exactly the stated scope, nothing more** — if the user said defer/park/not now, those words are a hard stop, not a suggestion
- **Read existing user-authored code before flagging it as a problem** — verify it doesn't already solve the issue before proposing a fix
- **Reconcile the Task tool list proactively** as file edits accumulate; don't let it drift stale across many turns
- **Verify `/atone` actually wrote to disk** after invocation — confirm the event exists before moving on

## Things to avoid
- **Don't re-introduce deferred scope under a different implementation** — reframing doesn't make deferred work in-scope
- **Don't invent intermediate abstractions or wrapper functions** when the user asked for a simple data exposure or direct addition
- **Never silently remove a user-authored solution, then re-implement the same thing** as if it were new — flag potential loss, wait for confirmation
- **Don't start expensive review steps (e.g., magi debate) early** when the user explicitly said to wait until prerequisite content is complete

## Open questions / known gaps
- Recurring tension: agent repeatedly over-scopes on "helpful" additions that the user then deletes — the pattern survives multiple atone events, suggesting it needs a mechanical gate, not another advisory rule
- Doc-writing guidelines exist but agent still produces AI-smell prose; the voice-pass sub-agent step is likely being skipped
