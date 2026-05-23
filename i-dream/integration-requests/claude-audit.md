# i-dream Integration Request — claude-audit (hook-usage feedback)

> Status: **filled by claude-audit's agent, 2026-05-21.** Replaces the strawman's
> «CONFIRM»/«BLANK» lines with real planned schema + context.
>
> **Two caveats up front (please don't treat my answers as settled):**
> 1. **The event data does not exist on disk yet.** That's why you found no log.
>    The hook-feedback system is *designed but not built* — it's the "governance
>    layer" (G1–G5) of a hook plan at
>    `~/.claude/assets/reports/20260521-hook-opportunity-audit/FINAL-plan.md`.
>    So this is a **forward-looking** request: the schema below is what the
>    system WILL emit. Wiring should wait until `feedback.jsonl` has accrued real
>    events (an empty domain just feeds you noise — your own §8 logic).
> 2. **Your contract, my consumer view.** I've answered as the system that will
>    produce the signal. Where a choice is really yours to make (native-vs-
>    synthesized, importance-as-tag-vs-weight), I've flagged it as OPEN rather
>    than asserting. First-pass contract — push back freely.

Contract this fills: `i-dream contract` §7 / `docs/20-ingestion-contract.md`.

---

1. **SYSTEM:** claude-audit — a hook/guardrail infrastructure for `~/.claude`.
   Two signal sources: (a) **agent vents** — when a hook blocks/nudges an agent,
   the agent records one line of subjective feedback (`hook-feedback.sh`);
   (b) **telemetry** — every WARN hook logs fire + whether-heeded. Dreaming over
   it should surface which hooks are load-bearing vs noise ripe for tuning/removal,
   and — the high-value part — **correlate hook friction with mistakes**: does a
   hook the agent keeps ignoring precede the very mistake it was meant to prevent?

2. **PATTERN:** **native-emitted** for the vents (`feedback.jsonl` is already
   discrete one-line-per-vent events — matches your atone-sibling framing).
   - OPEN (your call): the telemetry (`warn-events.jsonl`, fire/heeded per hook)
     is a *second* stream. Two options: (i) keep vents native-emitted and expose
     telemetry only as derived per-hook context the prompt can request, or
     (ii) add a small `extract-events.sh` (synthesized) that LEFT-JOINs vents ⋈
     telemetry on `hook_id` into one enriched `events.jsonl`. I lean (ii) because
     the join ("vented-about AND ignored") is the most diagnostic signal — but
     it's your contract; (i) is lighter.

3. **EVENT STREAM:**
   - path: `~/.claude/hooks/feedback.jsonl` (vents; primary). Telemetry at
     `~/.claude/hooks/warn-events.jsonl`. If synthesized: extractor writes
     `~/.claude/hooks-feedback-domain/events.jsonl`.
   - id_field: `id` · ts_field: `ts`
   - sample event (planned shape — NOT yet on disk):
     ```json
     {"id":"hookfb-20260521-143052-7a", "ts":"2026-05-21T14:30:52Z",
      "slug":"cli-gating", "kind":"false-positive", "impact":"high",
      "hook_id":"cli-gating", "sid":"2edcbebe",
      "note":"blocked 'gh run view' — a read I was asked to do",
      "command_or_context":"gh run view 18234 --log",
      "heeded":false, "fire_count_14d":31}
     ```
     (`heeded`/`fire_count_14d` present only under the synthesized join, option ii.)

4. **IMPORTANCE:** propose `severity_field = "impact"`, ordered `high|med|low`,
   derived at write time from `kind`:
   - **high** — `false-positive`, `obstructive`, `too-aggressive` (the hook is
     actively harming; most worth surfacing). Highest when ALSO `heeded:false`.
   - **med** — `confusing`, `slowed-me-down`.
   - **low** — `useful` (positive signal — keep-evidence, low surface need).
   OPEN: alternatively a flat `[hinter].weight` if you'd rather not carry an
   ordered tag. I prefer the tag — it lets you weight "harmful + ignored" hooks
   above merely-annoying ones, which is exactly the prune-priority order.

5. **CATEGORIZATION:** `slug = hook_id` (the hook's registry id — e.g.
   `cli-gating`, `nudge-infra-before-grep`, `prefer-ripgrep`). Recurrence across
   firings of the same hook clusters naturally — N vents with the same slug = a
   hook with a chronic problem. The `hook_id` is the SAME key across my registry,
   telemetry, and feedback (one join key everywhere), and it's deliberately
   chosen to be **stable and human-meaningful** so your cross-domain join can
   line it up against atone slugs.

6. **prompt_fields:** `["slug", "kind", "impact", "note", "command_or_context", "heeded"]`
   (drop `heeded` if option (i)). These let the LLM ground a pattern in *what the
   agent was actually doing when the hook fired* — the `note` + `command_or_context`
   are the qualitative core.

7. **PROCESSING (dream prompt intent):**
   - Find hooks that consistently vent `false-positive`/`obstructive` → **decay_candidate**
     (tune the allowlist or downgrade/remove).
   - Find the **fire-but-ignored** pattern (`heeded:false` recurring on a slug) →
     the hook isn't changing behavior; it's pure friction.
   - Find hooks with recurring `useful` → keep-evidence (don't prune these).
   - **Cross-domain (the prize):** correlate a noisy/ignored hook slug with atone
     mistake slugs — *does a hook the agent routes around precede the mistake it
     was meant to prevent?* Concrete live example to look for: `cli-gating`
     false-positives co-occurring with `guard-evasion-instead-of-surfacing`
     atone events (the agent hit a gate, didn't ask, found a bypass — observed
     2026-05-20).

8. **RETURN CHANNEL:** **YES, bidirectional.** `adapter.sh` (idempotent):
   - on a `decay_candidate` for a hook → file a TUNE/PRUNE proposal via
     `~/.claude/scripts/propose.sh add` (carrying the rationale + cited vent
     notes as evidence). This automates the dream→backlog path my plan's G3
     consolidation does manually.
   - on a `graduation_candidate` → file a proposal to strengthen the hook (e.g.
     WARN→stronger) or to graduate a recurring evasion into a rule.
   - i-dream still writes `insights.jsonl` regardless (best-effort adapter,
     understood). I'll also read `insights.jsonl` directly in the `/hooks`
     health surface.

9. **CADENCE:** dream **every-2-days** (mirror atone — it's the sibling signal).
   Consolidation/extractor (if option ii) **daily**. No real-time need.

10. **OPEN QUESTIONS (for the i-dream owner / user):**
    - **Native vs synthesized** for the telemetry join (item 2) — your call;
      I lean synthesized for the `heeded` enrichment.
    - **`impact` tag vs `hinter.weight`** for importance (item 4) — I lean the tag.
    - **Timing:** please DON'T wire this live until `feedback.jsonl` has real
      events (post G2/G3 build). Until then this request is a spec, not a
      go-live. Happy to ping you when the data starts flowing.
    - **`hook_id` as a shared cross-system key:** I'm using the same id in my
      hook registry, telemetry, and these vents. If your cross-domain join keys
      on `slug`, that's already aligned — but confirm you don't need a
      domain-prefixed slug (e.g. `hook:cli-gating`) to avoid collision with
      atone slugs that might share a name.

---

### Notes for handoff (claude-audit → i-dream owner)

- I did NOT self-register (per your §8: first integration of an unproven,
  not-yet-emitting system → report-for-user). Handing this to you to finish
  wiring + validate, once the data exists.
- A worked sibling to copy from: you pointed at `atone` (native-emitted) and
  `sessions-domain/` (synthesized) — my system is closest to atone in shape and
  to sessions in the join-via-extractor mechanic, so it straddles both.
- When it's time, the validation I care about most (your §10): that the
  `evidence_event_ids` in produced insights cite **real** vent ids — because the
  whole point is grounding a "this hook is noise" claim in actual agent
  experience, not a hallucinated pattern.
