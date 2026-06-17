---
brief: Stop-hook design that blocks a premature "done/works/shipped" claim when no run/test/build actually fired that turn
triggers:
  - tool:guard-declared-ready
  - topic:declared-ready
  - phrase:"declared ready"
related:
  - rules/testing.md
  - scripts/hooks/review-gate-stop.sh
tier: 2
category: features
updated: 2026-06-01
stale_after_days: 365
---

# declared-ready Stop-hook (BUILT — migration 0019)

> Blocks the turn from ending when the agent claims success ("done / works /
> shipped / fixed / passing / verified") but no run/test/build command actually
> executed that turn. The strongest of the Phase-2 interventions — and the
> highest-friction, so it must be tuned + live-tested before shipping.
>
> **Status:** BUILT 2026-06-15 as `scripts/hooks/declared-ready-stop.sh`, wired in
> settings.json `Stop`, paired with `rules/exercise-based-verification.md`
> (migration 0019). Carve-out: collect/compile/lint ≠ run. Loop-safe; mute via
> `~/.claude/.no-declared-ready-gate`. The design below is the as-built spec.
> (Originated from atone slug `declared-ready-without-runtime-exercise`, S3, 5–6×.)

## Why a Stop hook (not PreToolUse)

The mistake isn't in a tool *input* — it's in the agent's *claim* at end-of-turn.
Only a Stop hook sees the completed turn and can refuse to let it end. That
makes this a real guard (blocks premature "done"), not an ignorable advisory.

## Mechanism (mirrors review-gate-stop.sh — a DIRECT settings.json Stop hook)

- **Input:** stdin JSON has `.session_id` and `.transcript_path`.
- **Block:** emit `{"decision":"block","reason":"…"}` on stdout, `exit 0`. The
  `reason` is fed to the agent and the turn does NOT end.
- **Non-blocking note:** emit `{"systemMessage":"…"}` (no block).
- **Loop-safety (MANDATORY):** hash the trigger signature to
  `/tmp/claude-declared-ready-<sid8>`; if it matches last Stop → step aside to a
  `systemMessage` instead of re-blocking. Without this it traps the agent.
- **NOT via hook-orchestrator** (its task stdout → /dev/null can't carry a
  decision). Register directly in settings.json `Stop`.
- **Mute:** `touch ~/.claude/.no-declared-ready-gate`.

## The two (fuzzy) detections — where the tuning lives

1. **Did the agent claim done?** Scan the LAST assistant message in the
   transcript for: `\b(done|works|working|shipped|fixed|passing|verified|ready|
   complete)\b` near a self-referential subject. HIGH false-positive surface
   ("done reading", "works like X") — require it to be about the *change*
   (near "the fix/feature/it/this" + past-tense success). Start narrow.
2. **Did a run actually happen this turn?** Scan the turn's tool_use entries in
   the transcript for a Bash command matching a run/test/build:
   `cargo (test|run|build)|npm (test|run)|pnpm|yarn (test|dev)|pytest|go test|
   ./.*|node |python3? .*\.py|build\.sh|swiftc|curl localhost`. If a claim fired
   AND no such command ran → trigger.

The honest risk: both regexes are approximations. Ship with the loop-safe
step-aside + an easy mute, watch reflect's `declared-ready` trend, and tighten.
Better to under-fire (miss some) than over-fire (trap the agent → guard gets
muted → dilution).

## Build checklist (apply the Phase-3 template)

- [ ] Reads `transcript_path`; degrades silent (exit 0) on missing/bad input.
- [ ] Block uses `{"decision":"block","reason":…}`; reason is actionable.
- [ ] Loop-safe signature file; second identical Stop → `systemMessage`, not block.
- [ ] Claim + run regexes tested on real transcripts for over/under-fire.
- [ ] **Live-tested in-session** (claim-without-run blocks once; with-run silent;
      mute works) — not just stdin.
- [ ] Mute file + env hatch.

## Family note

This is the "process-adherence" family's Stop-event member (sibling to the
PreToolUse `sub-agent-output` / `env-access` and a future WAL-adherence hook).
Shared shape: detect the documented-process violation → surface to the AGENT
(block/decision for Stop, additionalContext for PreToolUse) → loop-safe → mute.
Phase 3's template formalizes this.
