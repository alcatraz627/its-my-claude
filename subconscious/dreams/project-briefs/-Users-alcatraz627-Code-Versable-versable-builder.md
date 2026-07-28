<!-- i-dream project brief · 2026-07-28T01:07:21.869052+00:00 · 20 patterns / 10 insights -->
## What this project is about
Versable Builder is a multi-page UI application (React/Next.js) with shared shell components, access-gate systems, and multi-agent/multi-session coordination. Work style is iterative with high parallelism and external-stakeholder-facing document output.

## Things to do (or keep doing)
- **Audit ALL pages** before implementing any shared UI shell component (sidebar, drawer, modal) — never build per-page variants; the fix applies to every sibling page simultaneously.
- **Exercise the fix on the running dev server** before claiming done/works/fixed — a code edit that looks correct is not verified until the actual code path fires on localhost.
- **Pre-negotiate task ownership via IPC** before parallel sub-agent work; overlapping edits without coordination produces silent clobbers.
- **Embed decision context** when creating deferred items — a backlog entry or question to the user must carry enough rationale for the consumer to act without a follow-up.

## Things to avoid
- **Don't treat send-success as delivery** — IPC verification requires an actual round-trip reply from the peer, not inspection of the sender's own logs.
- **Don't default-ALLOW unknown inputs** in access gates — unrecognized CLIs/commands must DENY; default-open makes the entire gate bypassable.
- **Don't include internal banter or stakeholder critique** in any document that may be shared externally; strip all conversational framing before writing the file.
- **Don't cite file basenames alone** — always include the full path; a basename forces the user to hunt.

## Open questions / known gaps
- Recurring tension: agent claims UI fix is done, user tests on real app, still broken — the declared-ready gate is known but the pattern persists under velocity.
- Design mocks exist for UI surfaces but are not always consulted before shipping labels/flows — establish a pre-implementation grep for mocks as a standard step.
