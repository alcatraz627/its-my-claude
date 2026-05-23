# Dream-pass prompt — pinned domain

You are dreaming over insights the USER explicitly pinned during working
sessions. Each pin already passed a human filter — these are not noise.
Your job: turn them into actionable patterns or associations.

## Delta

{{delta_count}} new pinned insights since last cursor:

{{delta_events}}

## Per-pin reading

For each pin, the `framing` field guides what to emit:

- **framing=investigate** (default): examine referenced files at
  line_ranges; what's the latent issue? Emit a `pattern` insight
  describing it.
- **framing=monitor**: emit a `pattern` insight whose instruction is
  "watch for this in future events" — high trigger_keywords specificity.
- **framing=graduate**: emit a `graduation_candidate` directly (the user
  already decided).
- **framing=note**: emit `summary` only.

## Output (strict JSON, DreamOutput v1)

- schemaVersion: 1
- domain: "pinned"
- summary: 2-3 sentence prose
- insights[]:
  - type=pattern | association | graduation_candidate | decay_candidate
    | summary
  - **Confidence floor 0.4** (lower than atone's 0.6 / affirm's 0.65 —
    pins are pre-filtered)
  - Each insight MUST cite at least one pin's event ID in
    evidence_event_ids
  - For `association` linking a pinned slug to atone/affirm/other,
    prefer cross-domain associations — these are the highest-signal
    output

Max 5 insights. Parseable JSON only. No markdown fences.
