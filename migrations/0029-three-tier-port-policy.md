---
number: 0029
title: Three-tier port policy — ports.sh ledger + blocking guard + registry move
slug: three-tier-port-policy
status: complete
date: 2026-07-10
affected_paths:
  - scripts/dev-servers/ports.sh
  - scripts/hooks/guard-dev-server-port.sh
  - dev-servers/port-events.jsonl
  - dev-servers/port-registry.md
  - scratchpad/global/port-registry.md
  - features/dev-servers.md
  - settings.json
---

# Migration 0029 — Three-tier port policy

## Summary

Replaces the pm2-centric "30xx/50xx + hand-edited registry" dev-server
convention with a three-tier port policy (mature=user-pinned ·
local-persistent=pm2+5100-5399 · one-off=6200-6499+24h-TTL), a live event-sourced
ledger (`scripts/dev-servers/ports.sh`, state in the NEW top-level
`~/.claude/dev-servers/`), and a BLOCKING PreToolUse hook
(`guard-dev-server-port.sh`) on dev-server launches.

## Why

Agents were stacking orphaned dev servers on framework defaults (five identical
fastfetch Vite servers on 5173-5178; a next-server squatting :3000 for 2.5 days)
because the old convention was advisory, the hand-edited registry rotted (stale
since April), and Vite's auto-increment masked every collision. User decision
2026-07-10: block, don't nudge; ports are the unit of discipline, not pm2.

## Label / path changes

| From | To |
|---|---|
| `scratchpad/global/port-registry.md` (hand-edited, canonical) | `dev-servers/port-registry.md` (DERIVED from `dev-servers/port-events.jsonl`; old path holds a pointer stub) |
| "all agent apps use pm2" | pm2 = tier-2 runner only |
| FE 30xx / BE 50xx allocation | tier-2 5100-5399 · tier-3 6200-6499 · tier-1 user-pinned |

## Executed cleanup (2026-07-10)

Killed 5 fastfetch-explorer Vite orphans (5174-5178) + the versable-builder
playground next-server (:3000) — both recorded as revivable reaps (6200/6201).
Re-homed pm2 `walmart-fe` 5173→5100 and `speedway-fe` 5174→5101 (`--strictPort`,
`pm2 save`, smoke-tested 200/302). Pinned user tier-1 ports 3003/3006/8001.
Grandfathered tier-2 claims: decision-pages 5197, review-feedback 5199,
data-forge 5040.

## Recovery / revert

`trash scripts/dev-servers/ports.sh scripts/hooks/guard-dev-server-port.sh`;
remove the hook's settings.json PreToolUse entry; restore the old registry from
git. Reaped processes: `ports.sh revive <name>` (revive info is in the events
file). Re-homed pm2 apps: `pm2 delete` + restart without the `--port` args.

## Post-review hardening (same day)

The 2026-07-10 skeptical review (`assets/reports/20260710-1709-skeptical-review/`)
found 21 issues; the approved set was fixed same-day: allocation mutex around
claim/revive (the lockless allocator handed one port to 8 concurrent claimers),
owner semantics for pins AND claims (cwd-boundary match; `pin`/`claim` default
`--cwd` to `$PWD`; unscoped pins get their own verdict + rescope remedy),
config-sniffing before the portless block (vite/next/astro/nuxt configs, .env,
package.json), revive reads raw reap events + relocates when the old port has a
new tenant, `free`-by-name via a real resolver, and the pm2 exemption narrowed
to pm2-only commands. Remaining accepted edges are catalogued in the
architecture doc.

## Cross-references

- `features/dev-servers.md` — the rewritten convention (the user-facing doc)
- `assets/docs/port-system-architecture.md` — internals, invariants, known
  edges, upgrade + testing guidance (read before modifying the system)
- `features/hook-design.md` — block-tier justification (cost-of-miss = the
  user's named top pain; false-fire escape = `PORTS_OK=1`)
