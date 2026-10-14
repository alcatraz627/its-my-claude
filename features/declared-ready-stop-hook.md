---
brief: Stop-hook design that blocks a premature "done/works/shipped" claim when no run/test/build actually fired that turn
triggers:
  - tool:guard-declared-ready
  - topic:declared-ready
  - phrase:"declared ready"
related:
  - rules/testing.md
  - scripts/hooks/retired/review-gate-stop.sh
tier: 2
category: features
updated: 2026-06-01
stale_after_days: 365
---

# declared-ready Stop-hook (built, migration 0019)

> Blocks the turn from ending when the agent claims success ("done / works /
> shipped / fixed / passing / verified") but no run/test/build command executed
> that turn. It is the strongest of the Phase-2 interventions and the
> highest-friction, so tune it and live-test it before shipping.
>
> **Status:** built 2026-06-15 as `scripts/hooks/declared-ready-stop.sh`, wired in
> settings.json `Stop`, and paired with `rules/exercise-based-verification.md`
> (migration 0019). Carve-out: collect, compile and lint do not count as a run.
> Loop-safe. Mute via `~/.claude/.no-declared-ready-gate`. The design below is
> the as-built spec. (It came from atone slug `declared-ready-without-runtime-exercise`,
> S3, 5-6 occurrences.)

## Why a Stop hook (not PreToolUse)

The mistake is in the agent's *claim* at end of turn, not in a tool *input*.
Only a Stop hook sees the completed turn and can refuse to let it end. That
makes this a real guard that blocks a premature "done", where an advisory
would be easy to ignore.

## Mechanism: a direct settings.json Stop hook

- **Input:** stdin JSON has `.session_id` and `.transcript_path`.
- **Block:** emit `{"decision":"block","reason":"…"}` on stdout and `exit 0`. The
  `reason` is fed to the agent and the turn does NOT end.
- **Non-blocking note:** emit `{"systemMessage":"…"}` (no block).
- **Loop-safety (mandatory):** hash the trigger signature to
  `/tmp/claude-declared-ready-<sid8>`. If it matches the last Stop, step aside to a
  `systemMessage` instead of re-blocking. Without this the hook traps the agent.
- **Not via hook-orchestrator.** Its task stdout goes to /dev/null and cannot carry a
  decision. Register directly in settings.json `Stop`.
- **Mute:** `touch ~/.claude/.no-declared-ready-gate`.

## The two fuzzy detections (where the tuning lives)

1. **Did the agent claim done?** Scan the LAST assistant message in the
   transcript for: `\b(done|works|working|shipped|fixed|passing|verified|ready|
   complete)\b` near a self-referential subject. The false-positive surface is
   high ("done reading", "works like X"), so require the claim to be about the
   *change* (near "the fix/feature/it/this" plus past-tense success). Start narrow.
2. **Did a run actually happen this turn?** Scan the turn's tool_use entries in
   the transcript for a Bash command matching a run/test/build:
   `cargo (test|run|build)|npm (test|run)|pnpm|yarn (test|dev)|pytest|go test|
   ./.*|node |python3? .*\.py|build\.sh|swiftc|curl localhost`. If a claim fired
   AND no such command ran, trigger.

Both regexes are approximations. Ship with the loop-safe step-aside and an easy
mute, watch reflect's `declared-ready` trend, and tighten. It is better to
under-fire (miss some) than over-fire, because an over-firing hook traps the
agent, gets muted, and stops guarding.

## Build checklist (apply the Phase-3 template)

- [ ] Reads `transcript_path`; degrades silently (exit 0) on missing or bad input.
- [ ] Block uses `{"decision":"block","reason":…}`; the reason is actionable.
- [ ] Loop-safe signature file; a second identical Stop gives `systemMessage`, not a block.
- [ ] Claim and run regexes tested on real transcripts for over-fire and under-fire.
- [ ] **Live-tested in-session** (claim without a run blocks once; with a run stays
      silent; mute works), not just via stdin.
- [ ] Mute file and env hatch.

## Family note

This is the Stop-event member of the "process-adherence" family, a sibling to the
PreToolUse `sub-agent-output` and `env-access` hooks and a future WAL-adherence hook.
They share one shape: detect the documented-process violation, surface it to the AGENT
(block/decision for Stop, additionalContext for PreToolUse), stay loop-safe, and
offer a mute. Phase 3's template formalizes this.
