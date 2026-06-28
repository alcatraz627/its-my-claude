---
brief: Registry of the context-injecting and learning-capturing "plugs" wired into the session lifecycle (start / per-turn / compact / end), with each plug's trigger, direction, token cost, mute file, and current observability. The catalog behind `/plugs`.
triggers:
  - tool:plugs
  - topic:session-plugs
  - topic:context-injection
  - phrase:"what's plugged in"
  - phrase:"what context is injected"
related:
  - features/hinter-pipeline.md
  - features/context-retention.md
  - skills/shared/ledger-format.md
tier: 2
category: features
updated: 2026-06-28
stale_after_days: 60
---

# Session plugs

The "plugs" are the hooks and skill-phases that either **inject context into** a
session or **capture learning from** it, at four lifecycle points: session start,
each turn, compaction, and session end. This is the catalog the `/plugs` reader
renders, and the basis for measuring whether each plug earns its tokens.

Scope: this lists **context/learning** plugs only — not the guard hooks
(safe-delete, prefer-rg, the Stop gates) or pure side-effects (tab-title,
emit-event). Those are real hooks but they neither inject context nor learn from
the session, so they are out of scope for "what's shaping my context."

Direction legend: **inject** = adds to the agent's context · **capture** = records
learning from the session · **side-effect** = neither (listed only where it shares
a lane). Trigger: **blanket** = fires every time · **conditional** = only when its
condition holds (the cheaper, lower-noise kind).

## Session start (the injection lane)

All start-time injectors run through `scripts/session-mgmt/sessionstart-inject.sh`
(synchronous; merges each one's additionalContext into one SessionStart object).
Mute the whole lane: `~/.claude/.no-sessionstart-inject`.

| Plug | Dir | Trigger | ~Cost | Mute | Observability today |
|---|---|---|---|---|---|
| dream-insights | inject | blanket | ~3700 ch | .tldr-off (atone part) | i-dream/injections.jsonl logs each injection |
| pending-proposals | inject | conditional (pending exist) | ~2000 ch | none | none |
| dream-metrics-context | inject | blanket | ~290 ch | none | none |
| detect-stale-session | inject | conditional (prior crash) | ~760 ch, 816ms | none | none |
| health-check | inject | conditional (warnings) | ~65 ch | none | none |
| validate-settings-hooks | inject | conditional (misconfig) | silent | none | none |
| backlog-surface | inject | conditional (PROMOTE + cooldown) | 1 line | .no-backlog-surface | .backlog-surface-last marker |

Also at start (not injectors): claude-ipc session register; the async orchestrator
runs side-effect tasks (tab title, retro-queue, shell-mem init, daemon notify,
sync-todos pull).

## Per turn (UserPromptSubmit)

| Plug | Dir | Trigger | Mute | Observability today |
|---|---|---|---|---|
| ctx-pressure-nudge | inject | conditional (>80% fill) | none (rate-limited) | /tmp/claude-ctxpress-<sid> band marker |
| ctx-signal-nudge | inject | conditional (cwd change / idle) | none | /tmp/claude-ctxsig-<sid> |
| api-recovery-nudge | inject | conditional (post-API-error turn) | none | self-limiting (transcript) |
| persona-suggest | inject | conditional | persona mute files | personas/usage/events.jsonl |
| hint-injector | inject | conditional (autocorrect / hinters) | per-hinter mutes | hinter pipeline logs |
| shell-mem inject-shell-state | inject | conditional (recent shell ctx) | none | shell-logs/ |

## Compaction

| Plug | Dir | Trigger | Event |
|---|---|---|---|
| pre-compact-checkpoint | capture | blanket | PreCompact |
| shell-mem pre-compact-shell | capture | conditional (active bg) | PreCompact -> wal.md SHELL SNAPSHOT |
| enqueue-auto-coredump | capture | conditional (opt-in gate + >=15 tools) | PreCompact + SessionEnd |
| post-compact-recovery + /catchup nudge | inject | blanket | PostCompact |

## Session end + capture

| Plug | Dir | Trigger | Mute | Observability today |
|---|---|---|---|---|
| session-end-checkpoint | capture | blanket | n/a | checkpoints/ |
| gcc-signal-capture | capture | conditional (edited gcc + atoned + no proposal) | .no-gcc-signal-capture | proposals.jsonl (src:auto-stub) |
| atone-stop-check / fired-and-ignored | capture | conditional (atone this session) | atone mute files | atone feedback |

## Skill-phase plugs (not hooks)

| Plug | Dir | Trigger | Where |
|---|---|---|---|
| core-dump gcc-contribution (3.8) | capture | conditional (reusable friction) | /core-dump |
| catchup post-catchup contribution (3.5) | capture | conditional (reusable friction) | /catchup |
| catchup subsystem-state (3.4) | inject | conditional (active bg) | /catchup |

## Why this registry exists (noise + efficacy)

Every **inject** plug spends tokens in the agent's context. The risk is noise: a
blanket injector that fires every session but is rarely acted on costs tokens for
no benefit (the prime suspect today is dream-insights — ~3700 ch every session,
and the analysis found ~0 of ~922 promoted insights ever became a gcc change).

The defense is the value-system in `ledger/goals.toml` (`attention-scarcity`:
precision over recall, single-digit interrupts/day) plus a measurement: per plug,
**fired vs acted-on**. The "Observability today" column above is deliberately
sparse — most plugs leave no trace, so the ratio cannot be computed yet. Closing
that gap (one `plug-events` ledger line per firing, via `ledger-common.sh`) is the
next step, and this registry names exactly where those log calls go.

`conditional` plugs are inherently low-noise (they cost nothing when idle);
`blanket` plugs must earn their place by the fired-vs-acted measure or graduate to
a mechanical gate (`goals.toml` `graduate-to-mechanism`) rather than re-inject
forever.
