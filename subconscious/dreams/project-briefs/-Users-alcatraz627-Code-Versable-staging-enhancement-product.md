<!-- i-dream project brief · 2026-07-15T18:50:13.324814+00:00 · 20 patterns / 4 insights -->
## What this project is about
Versable's staging enhancement product — a multi-agent, multi-surface codebase with data extraction pipelines, access-control gates, and externally-shared documents. Protected repo: prepare diffs, hand commits to the user.

## Things to do (or keep doing)
- **Breadth-first before depth**: complete a v1 pass across all surfaces before polishing any single area; sweep, then refine.
- **Explore and ground first**: read the relevant code, surface a recommendation, then edit — never jump to edits cold.
- **Batch work, pause at real decision points only**: don't interrupt for lightweight go-aheads; halt at genuine forks or critical reviews.
- **Runtime exercise over test-count**: dogfood the affected flow live; claimed correctness from 99+ tests without running the path is insufficient.

## Things to avoid
- **Don't use `rg -rn`** — `-r` is `--replace`, not recursive; use `rg -n` for line numbers.
- **Don't default-allow in access gates**: unrecognized commands must DENY; a default-allow fallback invalidates the entire gate.
- **Don't patch the instance, fix the class**: adding one CLI to a fallback list while leaving the structural default-allow in place re-exposes the same vulnerability.
- **Don't defer state-ledger writes**: `TaskUpdate`, IPC reply, and git commit are blocking obligations after each unit — not bookkeeping to batch later.

## Open questions / known gaps
- Multi-agent IPC coordination is a recurring friction point: parallel agents must pre-negotiate ownership via IPC before starting, and unanswered peer queries must be replied to before session end.
- Enforcement placed at advisory/text layers is silently bypassable by agents that don't read them; gates belong at the data-write layer (hook, CLI, schema check).
