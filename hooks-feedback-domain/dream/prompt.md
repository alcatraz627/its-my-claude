# Dream-pass prompt — claude-audit domain (hook-usage feedback)

> STAGED template. Goes to {root}/dream/prompt.md on activation. i-dream
> substitutes {{delta_count}} and {{delta_events}} at render time; do not edit
> those placeholders.

You are dreaming over hook/guardrail usage feedback (claude-audit). Each event
is one observation of a `~/.claude/` hook firing — a "vent" the agent recorded
when a hook blocked or nudged it, optionally enriched with telemetry (`heeded` =
did the agent comply, fire counts). Your job is to judge which hooks earn their
friction and which are noise — the kind of cross-event judgement a per-firing
counter can't make:

- Find **noise hooks** — slugs that recur with `kind` = false-positive /
  obstructive / too-aggressive. These are friction without payoff →
  `decay_candidate` (tune the allowlist, downgrade, or remove).
- Find the **fire-but-ignored** pattern — a slug recurring with `heeded:false`.
  A hook the agent routes around isn't changing behavior; it's pure friction
  even if "correct" → `decay_candidate` or a `pattern` describing the evasion.
- Find **load-bearing hooks** — slugs recurring with `kind` = useful. Surface
  these as keep-evidence so they're NOT pruned.
- **Cross-domain (the high-value one):** propose `association`s between a
  noisy/ignored hook slug here and a mistake slug in the **atone** domain —
  *does a hook the agent keeps routing around precede the very mistake it was
  meant to prevent?* (e.g. a `cli-gating` false-positive the agent bypassed,
  followed by a guard-evasion atone event.)

## Severity weighting

Each event carries an `impact` tag: **high** (false-positive / obstructive /
too-aggressive — actively harmful, especially when also `heeded:false`),
**med** (confusing / slowed-me-down), **low** (useful — positive, low surface
need). Weight your `confidence` and which insights survive the cap by impact ×
recurrence: a slug recurring at **high** impact AND ignored is the top
prune-priority and should always make the cut.

## Delta to dream over

{{delta_count}} new events since last cursor:

{{delta_events}}

## Output (strict JSON, DreamOutput v1)

Return ONE JSON object: `{ "schemaVersion": 1, "domain": "claude-audit",
"summary": "<2-3 sentences>", "insights": [ ... ] }`.

Insight types: `pattern` (name, evidence_event_ids, confidence, instruction,
trigger_keywords?, tool_signatures?), `association` (from_slug, to_slug,
confidence, instruction?), `graduation_candidate` (slug, rationale, target?),
`decay_candidate` (slug, rationale, action), `summary` (text).

## Rules

- Confidence < 0.6 → drop. Quiet is better than noisy.
- Confidence reflects impact × recurrence, not how neat the pattern reads.
- Max 5 insights. Quality over quantity.
- Every `pattern.evidence_event_ids` MUST cite real ids from the delta above —
  no hallucinating. The whole point is grounding "this hook is noise" in actual
  agent experience.
- For `association`, the hook slug is from this delta; the other slug (e.g. an
  atone mistake slug) may come from cross-domain context.
- For `decay_candidate`, `action` ∈ {tune, downgrade, remove}.
- Return parseable JSON. No markdown fences. No preamble.
