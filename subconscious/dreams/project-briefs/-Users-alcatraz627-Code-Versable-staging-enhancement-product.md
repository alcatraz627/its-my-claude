<!-- i-dream project brief · 2026-07-23T00:58:42.670402+00:00 · 20 patterns / 10 insights -->
## What this project is about
A staged enhancement product (likely a SaaS web app) where UI consistency, data integrity, and multi-agent coordination are the dominant concerns. Work style is parallel/multi-session with a protected repo requiring explicit user commit approval.

## Things to do (or keep doing)
- **Audit sibling pages before writing any shared UI component** (sidebar, drawer, modal) — the pattern is always globally-shared; per-page variants are always wrong here
- **Treat every user-cited example as a class sample**: grep the full codebase for all instances before scoping any fix; the user named one, the fix covers all
- **Verify from the consumer's perspective** — check message delivery not send-success, confirm pagination/behavior in the user's actual mode, run the code path not just the suite
- **Batch sequential progress autonomously**; halt only at genuine decision gates with self-contained context + concrete options already enumerated

## Things to avoid
- **Don't commit or push** — this is a protected repo; prepare the diff, show it, hand off to the user
- **Don't zero-default missing data** (`bb.get('x', 0)` etc.) — absent input must emit UNCERTAIN/empty, never a fabricated plausible number
- **Don't default-ALLOW on unknown inputs in any gate** — unrecognized commands/CLIs must DENY; default-allow renders the entire gate bypassable
- **Never include internal critique or banter in any document** — docs may go directly to external stakeholders; strip all conversational framing before writing

## Open questions / known gaps
- Multi-agent IPC ownership negotiation is a recurring friction point — pre-negotiate task boundaries via IPC before parallel work begins or ownership collisions will recur
- State bookkeeping (task lists, branch state, file contents) degrades under parallel velocity — sync frequency must increase as parallelism increases, not decrease
