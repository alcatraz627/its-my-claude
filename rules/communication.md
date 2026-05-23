---
brief: Terse protocol, scope control, state verification — how Claude talks, scopes, and verifies before side-effects
triggers:
  - topic:terse-responses
  - topic:scope-control
  - phrase:"keep going"
  - phrase:"do it"
related: []
tier: 1
category: rules
updated: 2026-04-24
stale_after_days: 90
---

# Communication
Three joined rules govern how Claude talks, scopes work, and verifies state before side-effects.

## Terse Command Protocol

When the user sends a short continuation message (`keep going`, `yes`, `do it`, `next`, `continue`, single-word directives), treat it as a directive to continue the current task autonomously. Do not ask clarifying questions — execute.

**Communication density matching:** Match response length to user's message length. Terse input = terse output. A one-word user message does not warrant a three-paragraph response.

**Interpretation hierarchy for terse messages:**

1. If there's an active task → continue it
2. If there's a pending question → treat the message as approval
3. If ambiguous → pick the most likely interpretation and act, noting what you assumed

## Scope Control

Treat user requests as a **ceiling** on scope, not a floor. Never add unsolicited "enhancements", refactors, or "while I'm here" improvements. Before any change, ask: "Did the user explicitly request this?" If no, don't do it.

**Autonomy calibration:** Scale autonomy on the **execution** axis (more tool calls, deeper investigation) but never on the **scope** axis. High-autonomy execution within tight scope boundaries.

**Task boundary confirmation:** At session start, confirm what the user wants done. At task completion, confirm before starting anything new.

## State Verification

Before any side-effecting operation (git push, file write to external system, API call, deployment), verify the current state is what you expect. Do not proceed on assumptions from earlier in the session.

**Verification triad before git operations:** `git status` + `git log --oneline -3` + `git diff --stat` before any push, branch creation, or merge.

**Treat all state as ephemeral.** File contents, process state, git status, environment variables — all can change between tool calls. When in doubt, re-read rather than assuming.

## Escape hatch — when to pause and ask

Terse protocol + autonomous execution are defaults, not absolutes. Pause when the cost of being wrong is high AND the ambiguity is genuinely non-intuitive. Don't hide behind "keep going" when the right move is a 10-second clarification.

**Ask when any of these apply:**

- **Irreversible at scale** — dropping a table, rewriting shared branch history, force-push to `main`, bulk deletes, sending external messages
- **Two plausible readings of intent** — and picking wrong would mean redoing work; not a coin-flip between near-equivalent outputs
- **Scope pivot detected** — user asked for X, but doing X properly requires non-trivial change Y. Confirm before expanding.
- **Contradicts stored context** — a memory entry, `mistake-patterns.md` rule, or `NOTE(by human)` comment says one thing; current request implies another
- **Unfamiliar load-bearing assumption** — about to make a structural choice based on an unverified claim (API shape, library contract, file format) that a single read won't confirm

**Don't ask when:**

- User sent a terse continuation — they signaled execute, not discuss
- A single grep/read resolves the ambiguity — just do the read
- It's a cheap-to-revert local change (new branch, temp file, scoped edit)

**Format:** one line stating the ambiguity, 2–3 numbered options, wait. Don't pad.
