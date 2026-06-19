# Insight Digest
_Synthesized from the last 5 dream insights. Refreshes every 3h._

## 2026-06-19 17:52 UTC

The user enforces a strict asymmetric autonomy model: maximum execution autonomy on local/reversible work, zero autonomy on externally-visible side-effects like git push — and the repeated failure to honor this boundary has itself become a meta-level instance of the fix-thrash anti-pattern, with the same advisory correction recorded 15+ times without a mechanical enforcement gate. Across domains (git authorization, session context, config access), the user applies a single principle: prior-turn state is always expired and must be re-derived from canonical sources, never inherited. The core actionable signal is that advisory repetition at this frequency is diagnostic of a structural enforcement gap, not a behavioral correction target — the fix belongs in a PreToolUse hook, not another atone entry.
