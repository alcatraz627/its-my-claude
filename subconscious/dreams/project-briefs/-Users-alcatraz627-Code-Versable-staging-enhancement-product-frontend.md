<!-- i-dream project brief · 2026-07-15T18:48:20.266471+00:00 · 20 patterns / 3 insights -->
## What this project is about
A frontend codebase (Versable staging-enhancement-product) worked on in multi-agent parallel sessions with frequent IPC coordination, document generation for external stakeholders, and breadth-first feature sweeps.

## Things to do (or keep doing)
- **Pre-negotiate task ownership via IPC before starting work** — parallel agents that skip this produce conflicting edits that require manual untangling.
- **Checkpoint peer agent IPC aliases and session IDs** — context clears happen frequently; successor sessions must be able to re-establish contact without human intervention.
- **Do breadth-first v1 passes** before polishing any single area; halt only at genuine decision points, not every small step.
- **Inventory current behavior as a parity checklist before any rewrite** — flag removed behaviors explicitly so removals don't silently ship.

## Things to avoid
- **Don't use `rg -rn`** — `-r` is `--replace`, not recursive; use `rg -n` for line numbers.
- **Don't include internal banter, critique, or conversational framing in externally-shared documents** — strip it before writing the file, not after.
- **Don't assume IPC delivery succeeded from your own logs** — confirm via round-trip reply from the peer.
- **Don't reconcile task lists lazily after sub-agent bursts** — task ownership goes stale fast in high-parallelism periods; re-verify each item before starting it.

## Open questions / known gaps
- Enforcement of behavioral constraints is advisory (spec text, skill docs) and gets bypassed by agents that don't read them at startup — no data-write-layer gate exists yet.
- Task list hygiene degrades specifically during high-parallelism bursts; no automated reconciliation step is in place after sub-agent completions.
