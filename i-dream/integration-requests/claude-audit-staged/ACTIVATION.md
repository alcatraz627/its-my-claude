# Activation — claude-audit dream domain

**Status: STAGED, NOT LIVE.** These artifacts are wired and ready, but the
hook-feedback system isn't built yet, so there are no events to dream over.
Registering an empty domain would feed the dreamer noise and can't be validated
(no real `evidence_event_ids` to ground insights). Activate only after the data
flows.

## Owner decisions already baked in
- **Synthesized join** — an `extract-events.sh` LEFT-JOINs vents ⋈ telemetry on
  `hook_id` into one enriched `events.jsonl` (carries `heeded` + `fire_count`).
- **Severity** — `severity_field = "impact"`, `severity_order = ["low","med","high"]`
  (i-dream's `severity_rank` is now data-driven; shipped in i-dream this session).
- **slug = hook_id**, no domain prefix — the cross-domain join already qualifies
  slugs by domain (`from_domain`/`to_domain`), so no collision with atone slugs.

## Go-live checklist (claude-audit's agent + user)

1. **Build the feedback system** (G2/G3 of `~/.claude/assets/reports/20260521-hook-opportunity-audit/FINAL-plan.md`)
   so vents land at `~/.claude/hooks/feedback.jsonl` and telemetry at
   `~/.claude/hooks/warn-events.jsonl`.
2. **Create the domain home:** `mkdir -p ~/.claude/hooks-feedback-domain/{dream,derived}`.
3. **Write `~/.claude/hooks-feedback-domain/extract-events.sh`** — the vents ⋈
   telemetry join on `hook_id`, emitting events matching the request's schema
   (`id, ts, slug, kind, impact, hook_id, note, command_or_context, heeded,
   fire_count_14d`). `impact` derived from `kind` (false-positive/obstructive →
   high; confusing/slowed → med; useful → low).
4. **Write `~/.claude/hooks-feedback-domain/dream/adapter.sh`** — on a
   `decay_candidate` file a TUNE/PRUNE proposal via `~/.claude/scripts/propose.sh add`;
   on a `graduation_candidate` file a strengthen-hook proposal. Idempotent.
5. **Copy the staged artifacts:**
   - `claude-audit.toml` → `~/.claude/i-dream/domains/claude-audit.toml`
   - `dream-prompt.md` → `~/.claude/hooks-feedback-domain/dream/prompt.md`
6. **Run the extractor once** so `events.jsonl` has real events.
7. **Verify discovery:** `i-dream domain list` → `claude-audit` appears (`kind=external`).
8. **Validate** (contract §10): `i-dream dream-pass` → `claude-audit status: ok`,
   `insight_count > 0`; produced insights cite **real** vent ids; `adapter.sh`
   filed proposals; event `id`s stable across two passes.

## Notes
- The manifest + prompt here are i-dream-owner-authored and contract-conformant.
- `extract-events.sh` and `adapter.sh` are **claude-audit's** to write (its data
  shape + its proposal mechanism). The manifest just points at them.
- Source request: `../claude-audit.md`. Contract: `i-dream contract`.
