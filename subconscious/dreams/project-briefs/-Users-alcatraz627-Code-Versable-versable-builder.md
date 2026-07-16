<!-- i-dream project brief · 2026-07-15T18:47:57.494528+00:00 · 20 patterns / 4 insights -->
## What this project is about

Versable Builder is a multi-agent product-building system where parallel Claude sessions coordinate via IPC to build features. Work sessions are frequent, concurrent, and stateful — the dominant style is agent-coordinated implementation with the human as approver, not driver.

## Things to do (or keep doing)

- **Always pre-negotiate task ownership via IPC before touching shared files** — overlapping edits without coordination produces conflicts the user must untangle.
- **Breadth-first pass before polish** — complete a v1 sweep across all surfaces, then circle back to deepen individual items.
- **Batch sequential work; halt only at genuine decision points** — don't interrupt the user for lightweight go-aheads; save pauses for critical reviews or ambiguous choices requiring tradeoffs.
- **Run the affected code path live before claiming done** — test coverage (even 99+ tests) does not substitute for runtime dogfooding.

## Things to avoid

- **Don't use `rg -rn`** — `-r` means `--replace`, silently mangling output; use `rg -n` for line numbers.
- **Don't default to ALLOW or zero on unknown/missing input** — unrecognized commands must DENY; missing data must error, not silently produce a plausible-looking `0`.
- **Don't defer TaskUpdate calls** — a task list that accumulates edits without updates drifts into uselessness; mark tasks done immediately on completion.
- **Don't jump to edits without grounding first** — read the codebase, surface a recommendation, then touch code.

## Open questions / known gaps

- IPC round-trip reliability is unresolved: delivery confirmation via sender logs gets rejected; only actual peer reply counts, but unreplied messages trigger stop-hook loops.
- Enforcement placed at advisory layers (SKILL.md text, mute files) is silently bypassable by agents that don't read them — data-write-layer gates are the intent but not yet consistently applied.
