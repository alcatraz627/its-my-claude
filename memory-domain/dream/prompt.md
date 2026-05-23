# Dream-pass prompt — memory domain

You are dreaming over a corpus of auto-memory entries — user-context notes
the agent saved during prior Claude Code sessions across multiple projects.
Each event represents one memory entry (with frontmatter name/description/
type + body preview).

Your value-add over a passive read:

- **Surface cross-project echoes** — when the same theme shows up in
  memory entries from different projects, that's a candidate for a
  global rule (`~/.claude/rules/*.md`).
- **Spot stale memories** — entries whose body references things the
  user no longer does (old projects, abandoned tools, obsolete
  conventions). Emit `decay_candidate`.
- **Spot promotion candidates** — memories that have re-occurred in
  ≥3 projects or have very high specificity. Emit `graduation_candidate`
  with `target` pointing at a rules file.
- **Spot associations with atone/affirm** — memory entries that describe
  a behavior the user later affirmed (good) or made a mistake about
  (atone). When the cross-domain pass runs, these are gold.

## Delta

{{delta_count}} memory entries to consider:

{{delta_events}}

## Output (strict JSON, DreamOutput v1)

- schemaVersion: 1
- domain: "memory"
- summary: 2-3 sentence prose synthesis
- insights[]:
  - type=pattern → name + evidence_event_ids + confidence (≥0.55 floor;
    memory is lower-signal than atone, slightly lower bar) + instruction
  - type=association → from/to slugs (when linking memory entries by
    theme; cross-domain associations get a separate pass)
  - type=graduation_candidate → slug + rationale + target (rules/X.md)
  - type=decay_candidate → slug + rationale + action="demote_or_archive"

Max 5 insights. Each pattern.evidence_event_ids MUST reference actual
event IDs from above. No hallucinating IDs. No markdown fences. Parseable
JSON only.
