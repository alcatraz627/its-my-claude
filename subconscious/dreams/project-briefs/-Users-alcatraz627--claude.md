<!-- i-dream project brief · 2026-08-16T03:48:23.863817+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the user's global `~/.claude` configuration project — rules, skills, hooks, memory, and meta-tooling for Claude Code itself. Work is heavily multi-agent, peer-review-driven, and self-referential; the product is the agent runtime.

## Things to do (or keep doing)
- **Execute both sides independently before comparing plans** — in the two-agent peer-review workflow, produce a full independent output first, then contrast (never merge without explicit instruction).
- **Treat this repo as protected**: prepare the diff and hand the commit to the user; never push or commit autonomously.
- **On terse continuation signals** ("proceed", "keep going"), continue without asking for clarification as long as context is not under pressure.
- **Always surface hook nudges as a bordered callout** — the user never sees `additionalContext` otherwise.

## Things to avoid
- **Don't make structural claims about the codebase without a file:line citation** — "this doesn't exist here" requires a grep first; "X is the authority" requires reading the source.
- **Don't claim a UI or runtime fix is done without exercising it on the running dev server** — false assurance cycles are the top trust-damage pattern here.
- **Don't re-raise a topic the user has explicitly deferred or skipped three or more times** — scope violation.
- **Don't regenerate AI-smell prose (em-dashes, bold-spam) after a hook flags it** — mechanically distinct output is required, not rewording.

## Open questions / known gaps
- Parallel multi-agent bursts (sub-agent completions, concurrent edits) consistently degrade task-list and branch-state accuracy — syncing after each burst is the stated rule but remains the top recurring miss.
- Proxy-evidence confusion (send-success ≠ peer received, test-pass ≠ feature works) recurs across IPC, testing, and UI verification; direct artifact confirmation is the required gate.
