<!-- i-dream project brief · 2026-08-28T01:24:34.858749+00:00 · 10 patterns / 0 insights -->
## What this project is about
Versable Foundry is a full-stack product codebase worked on through structured implementation sessions with heavy sub-agent use. Dominant pattern: plan-then-implement with frequent UI verification and session-state discipline.

## Things to do (or keep doing)
- **Verify existence before asserting absence**: run `rg --no-ignore` or `fd --no-ignore` across the full relevant tree before claiming a file/module doesn't exist
- **Exercise the changed path before claiming done**: execute the actual code path (not collect, not compile) before writing done/works/fixed; the declared-ready gate fires correctly on doc-only edits — surface false positives plainly
- **Open the browser at desktop width** for any UI change involving tables or wide layout; no parity ledger entry substitutes for a rendered screenshot read as a whole frame

## Things to avoid
- **Don't cite file paths with a trailing period** in terminal output or replies; the period is absorbed into the auto-link and breaks clickability — follow every path with a space, comma, or word
- **Don't use relative or bare paths in user-facing replies**; expand to absolute (`/` or `~`) on first mention
- **Don't treat a sub-agent's idle signal as proof of output**; verify the output file exists on disk before acting on it — a stale idle from an already-stopped agent is a no-op
- **Don't implement a UI element literally** without checking whether the resulting layout serves the stated legibility goal; literal wording is a sample of intent, not its boundary

## Open questions / known gaps
- Session-store reads during wake checks risk reading the wrong session's queue — no reliable mechanical guard yet; verify store header against expected session ID before acting
