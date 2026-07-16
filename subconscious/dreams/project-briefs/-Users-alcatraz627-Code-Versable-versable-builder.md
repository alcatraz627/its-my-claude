<!-- i-dream project brief · 2026-07-16T07:36:03.118269+00:00 · 20 patterns / 2 insights -->
## What this project is about
A multi-agent collaborative codebase (versable-builder) where parallel agent sessions coordinate via IPC; the dominant working style is breadth-first sweeps with autonomous batched execution and protected-repo commit discipline.

## Things to do (or keep doing)
- **Breadth-first first**: complete a full v1 pass across all surfaces before polishing any single area; pausing mid-sweep to perfect one item wastes the sweep's momentum
- **Batch autonomously**: run sequential steps without halting for lightweight go-aheads; only pause at genuine decision points or destructive/irreversible operations
- **Confirm IPC via round-trip**: wait for an actual reply from the peer before asserting delivery — send-side logs prove transmission, not receipt
- **Treat state writes as blocking**: IPC replies, task updates, commit staging — execute immediately after completing a unit of work, never defer as bookkeeping

## Things to avoid
- **Never commit or push**: this is a protected repo; prepare the diff, show it, hand the commit to the user explicitly
- **Don't use `rg -rn`**: `-r` is `--replace`, silently corrupts output; use `rg -n` for line numbers
- **Don't emit plausible defaults for unknown input**: gates must default to DENY; extractors must error on missing data, not return zero — a plausible-looking default suppresses investigation
- **Strip internal commentary before any external doc**: no conversational framing, critique, or stakeholder banter in documents the user may share directly

## Open questions / known gaps
- Multi-agent task ownership negotiation via IPC is required but the pre-negotiation protocol isn't fully codified; overlapping parallel claims still produce muddle
- Decision questions posed to the user have recurrently lacked enough background to be self-contained; always include tradeoffs inline so the user can answer without a follow-up
