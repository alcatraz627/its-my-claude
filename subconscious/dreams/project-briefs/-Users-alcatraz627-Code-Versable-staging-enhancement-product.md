<!-- i-dream project brief · 2026-08-15T03:46:22.599533+00:00 · 20 patterns / 10 insights -->
## What this project is about
A multi-tenant SaaS enhancement product (Versable staging) built with a Next.js frontend and Node/Python backend. Working style is multi-agent, high-velocity, protected-repo — no commits or pushes without explicit user approval.

## Things to do (or keep doing)
- **Audit globally before implementing locally**: any UI shell component (drawer, sidebar, modal, pagination) must enumerate ALL consuming pages before writing the first line — per-page variants are always wrong here
- **Verify at the receiver, not the sender**: after IPC sends, after sub-agent writes, after edits — check the artifact or delivery at the destination, not the send-side telemetry
- **Default-DENY on access gates**: unrecognized commands/callers must deny, never fall through to allow
- **Attach decision context to deferred items**: when surfacing backlogged decisions, include what was decided, what options remain, and what changed — never surface a bare item name

## Things to avoid
- **Don't make structural claims without reading source**: never assert "this doesn't exist" or "X lives at Y" without a file:line citation — grep first
- **Don't let prose-smell tells survive rewrites**: em-dashes, Label:fragment rows, and bold-span excess in user-facing or external docs must be purged on first emission — the hook will fire repeatedly otherwise
- **Don't treat `rg -rn` as recursive+line-numbers**: `-r` is `--replace`; use `rg -n` for line numbers in recursive searches
- **Never include internal commentary in externally-shared documents**: strip all banter, critique, and framing about stakeholders before writing docs that go to external parties

## Open questions / known gaps
- Multi-agent parallel bursts consistently leave task lists, branch state, and ownership ambiguous — state-sync discipline degrades under exactly the conditions it's most needed
- Prose-smell correction is not sticking across rewrites; the agent regenerates the same tells after the hook fires, suggesting the correction is acknowledged but not internalized
