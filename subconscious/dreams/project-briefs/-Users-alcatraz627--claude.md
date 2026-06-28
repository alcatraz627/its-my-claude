<!-- i-dream project brief · 2026-06-28T12:39:11.901790+00:00 · 20 patterns / 10 insights -->
## What this project is about
The `~/.claude` meta-repo — the user's own Claude Code configuration, rules, scripts, skills, and tooling infrastructure. Work spans long multi-session arcs; continuity across compactions is the dominant operational concern.

## Things to do (or keep doing)
- Always write WAL entries as JSONL (not markdown); the migration is complete and canonical
- Checkpoint with `/core-dump` at every major milestone, not just session end — `/catchup` is the primary recovery path between sessions
- Treat terse single-word continuations (`ahead`, `next`, `done`, `looks`) as autonomous-execute signals; match response density to input density
- Before any new script or feature, check `~/.claude/scripts/` and `LOOKUP.md` — it likely already exists

## Things to avoid
- Never commit or push without fresh, explicit per-push approval — terse continuation signals grant implementation autonomy only, never scope-axis actions like git push
- Don't repeat fix attempts on the same failure without first writing a one-line root-cause hypothesis; fix-thrashing is the dominant frustration pattern here
- Never infer, synthesize, or extrapolate values not traceable to source data when generating output from data files — flag gaps explicitly instead
- Stop expanding scope on terse signals; `keep going` means depth, not breadth

## Open questions / known gaps
- Pattern extraction pipeline lacks deduplication — the WAL migration appears 4× as distinct patterns, suggesting the system over-indexes on high-friction structural changes
- Tension between "terse = execute" and "terse = only help understand, don't implement" is unresolved; when context is ambiguous, pause for one-line clarification before acting
