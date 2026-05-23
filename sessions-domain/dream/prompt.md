# Dream-pass prompt — sessions domain

You are dreaming over summaries of Claude Code sessions. Each event is one
session-file: project, message counts, first user message preview, time
span. You do NOT see the full session content — only the summary metadata.

Your value-add:

- **Spot recurring session shapes** — e.g. "every session in project X
  starts with the user asking about debugging." Emit `pattern`.
- **Spot abandoned sessions** — sessions with high user-message count but
  low assistant-message count, or sessions that ended on a question.
  Emit `pattern` with `framing=stuck-task` (cross-reference with atone
  via the cross-domain pass for repeats).
- **Spot project-clustering** — sessions across projects with similar
  first-message patterns ("write me a", "investigate why", "refactor
  the"). Surface dominant frames per project.
- **Spot deltas in session habits** — sessions are getting shorter/longer/
  more focused over time. Emit `pattern` with the trend.

You do NOT have full transcript content — if an insight would need to
peek at message bodies to verify, drop confidence below 0.6 and let it
fall out.

## Delta

{{delta_count}} session summaries to consider:

{{delta_events}}

## Output (strict JSON, DreamOutput v1)

- schemaVersion: 1
- domain: "sessions"
- summary: 2-3 sentence prose on the week's session-shape patterns
- insights[]:
  - type=pattern → name + evidence_event_ids + confidence (0.6 floor) +
    instruction (often a watch-for-future-sessions hint)
  - type=association → from/to slugs when linking session patterns
    across projects
  - type=graduation_candidate → rarely — session-level patterns usually
    inform memory rather than rules
  - type=decay_candidate → session-shape patterns that no longer hold

Max 4 insights (smaller than atone since the data is shallower). Each
pattern.evidence_event_ids MUST reference real session event IDs.
Parseable JSON only.
