<!-- i-dream project brief · 2026-07-20T11:42:31.206540+00:00 · 20 patterns / 8 insights -->
## What this project is about
React frontend for Versable's enhancement product, worked on in parallel multi-agent sessions with IPC coordination. Documents produced here may go directly to external business stakeholders.

## Things to do (or keep doing)
- **Breadth-first sweep before polish**: complete a v1 pass across all surfaces before deepening any one area; pausing mid-sweep to perfect one item is the recurring friction point.
- **Batch work autonomously**: halt only at genuine decision points with full context + ≥2 concrete options; rubber-stamp go-aheads waste the user's attention.
- **Fix the class, not the instance**: when correcting a UI component on one page, audit every sibling page for the same component before writing a single line of code.
- **Verify names by reading implementations**: identifiers (CSS class names, flag mnemonics, rg flags) are hints, not contracts — always read the definition before relying on behavior.

## Things to avoid
- **Don't use `rg -rn`**: `-r` means `--replace`, which silently mangles output; use `rg -n` for line numbers in recursive searches.
- **Don't treat send-success as delivery confirmation**: IPC message delivery requires a round-trip reply from the peer, not inspection of the sender's logs.
- **Don't overcorrect tone fixes**: removing stakeholder banter from a doc must not strip technical detail — target the inappropriate register only.
- **Don't let sub-agents touch guard mute-files**: a dropped mute file disables machine-wide safety guards for all concurrent sessions silently.

## Open questions / known gaps
- Multi-agent parallel work repeatedly degrades state bookkeeping (task lists drift, ownership ambiguous, stale edits clobbered) — no stable coordination ritual has landed yet.
- Deferred decision items keep arriving without prior context; the pattern of underspecified handoffs persists across sessions despite repeated correction.
