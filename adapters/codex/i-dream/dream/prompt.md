# Dream-pass prompt — codex-sessions domain

You are dreaming over the session log of Codex, a second coding agent that
runs on this machine beside Claude Code. Each event is one Codex session:
`slug` is how it was launched (`exec` = headless, usually a seat dispatched by
a Claude session through the codex plugin; `cli`/`vscode` = the owner by hand;
`subagent:*` = Codex's own sub-agents), `originator` names the launcher, `cwd`
the project, `first_prompt` the opening ask.

Look for what per-session reading cannot show:

- **What work gets handed to Codex**, by project and by shape (review, rescue,
  research, implementation). A cluster here is a candidate for a standing
  route in the owner's model-tier rules.
- **Repeated hand-offs of the same task** to fresh sessions, which reads as a
  hand-off that did not land the first time.
- **Projects where Codex runs alone** (no Claude checkpoint in the same cwd),
  where the owner's records are thinnest.
- **Handoff outcomes** when repeated prompts, a handback, or a review verdict
  show a recurring gap. `verified_claims` counts lines in a handback, not proof
  that those claims are true. A missing handback may be a short inquiry.
- **Associations** with other domains by cwd or by slug when the join pass
  offers them.

Do not rate single sessions or infer quality from a count alone. For a proposed
rule or route, state the owner benefit and cite real `evidence_event_ids` from
the delta. Return `DreamOutput` v1: `domain` and `summary` are strings,
`insights` is an array. Use the exact parser field names:
`pattern.name`, `pattern.instruction`, `pattern.confidence`, and
`pattern.evidence_event_ids`. Do not use `slug` or `description` in place of
`name` or `instruction`. For an association use `from_slug` and `to_slug`; for a
graduation candidate use `slug` and `rationale`. Omit an insight if its required
fields cannot be filled from this batch.

Return this shape, with real values from the delta:

```json
{
  "schemaVersion": 1,
  "domain": "codex-sessions",
  "summary": "One sentence about the batch",
  "insights": [{
    "type": "pattern",
    "name": "short-pattern-name",
    "instruction": "What the owner or agent should do when it recurs",
    "confidence": 0.8,
    "evidence_event_ids": ["real-event-id-from-the-delta"]
  }]
}
```

Every insight object needs a `type`. Return at most five insights and no text
outside the JSON.

## Delta to dream over

{{delta_count}} new events since last cursor:

{{delta_events}}
