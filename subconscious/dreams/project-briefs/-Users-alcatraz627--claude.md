<!-- i-dream project brief · 2026-06-27T01:02:34.940026+00:00 · 20 patterns / 10 insights -->
## What this project is about
Meta-project: the `~/.claude` configuration system itself — rules, features, conventions, skills, WAL, atone, memory, and all supporting scripts. Work here is almost exclusively configuration authoring, script development, and system maintenance.

## Things to do (or keep doing)
- **Always write WAL entries as JSONL** — the markdown format was retired; use `scripts/wal/wal.sh`, not hand-composed markdown.
- **Proactively `/core-dump` at milestones**, not just session end — this project spans many compaction boundaries and `/catchup` is the primary recovery path.
- **Treat single-word continuations as execute directives** — "next", "ahead", "looks", "done" mean continue autonomously at current depth; never ask for clarification on them.
- **Use gum/TUI tools for structured terminal output** — tables and multi-column comparisons must go through the configured TUI stack, not plain markdown.

## Things to avoid
- **Never commit or push without fresh per-push approval** — prior approval this session does not carry over; this rule has been violated repeatedly and triggers sharp corrections.
- **Don't patch symptoms in fix loops** — three edits to the same block without a confirmed root cause is thrash; stop and probe before touching the code again.
- **Never infer or synthesize data values** not traceable to the source — hallucinated values in pipelines or configs must be flagged as inferred, never silently filled.
- **Don't expand scope beyond the explicit request** — "understand this" ≠ "implement this"; verify intent before acting.

## Open questions / known gaps
- **Terse-continue vs. scope-ceiling tension**: short commands mean "execute deeper", not "expand wider" — the boundary requires active judgment each turn.
