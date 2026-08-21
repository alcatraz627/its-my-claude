---
brief: "The warden: a persistent monitor session judging working agents' trajectories from artifacts, run by a 45m launchd beat with $0 short-circuits, cost-unit governor, usage gate, owner pause, and handoff-style succession. CLI claude-warden; institution at ~/.claude/warden/."
triggers:
  - tool:claude-warden
  - topic:warden
  - topic:session-monitoring
  - phrase:"pause the warden"
  - phrase:"warden beat"
related: [scheduling-discipline, model-tier-routing]
tier: 2
category: features
updated: 2026-08-21
stale_after_days: 90
---

# The warden

One persistent sonnet session that watches working agents against their goals,
challenges done-claims with evidence, and escalates to the owner, never
overruling. Its durable self is `~/.claude/warden/` (PROMPT.md charter with
conduct rules 1-10, WATCH.md early-life watch items, state/ per-ward notes,
ledger.jsonl, spend.jsonl, insights.md), not any process or context.

## Moving parts

- **Beat**: `~/.claude/warden/warden-beat.sh`, launchd every 45m
  (com.alcatraz.warden-beat), working window 09:00 to 03:00. Skip ladder before
  any spend: hours, then owner pause (`warden/.paused`), then usage gate (5h or
  weekly >90%, `scripts/cron/usage-gate.sh`, self-clears on quota reset), then
  $0 when no ward moved, then the cost-unit governor (model + transcript-size +
  effort, budget 12/day), then the mid-turn lock. Delta stamps commit ONLY
  after a successful invoke, so every skip preserves catch-up.
- **Succession** (migration 0054): retirement at 8MB transcript is a told
  final beat plus a self-written handoff note; the successor bootstraps with a
  computed brief and a mandatory read-back ledger row. Resume-failure ladder:
  one beat of slack on a transient error, forced succession on the second.
  Invoke capped at 20m so beats never stack.
- **Owner surfaces**: `claude-warden` CLI (status/actions/ward/wards/ipc/
  spend/log/pause/open, colored); the claude-instances switchboard Warden row
  (green live, yellow standing-down-usage, off paused; click is the manual
  override, which supersedes the auto-gate everywhere); ledger FINDING rows;
  the weekly review item in weekly-todos.md.
- **Watchers**: WATCH.md items 1-13 read at the docs-skill 3h check-in;
  review/freshness.sh row warden-beat (beats stopped = RED).

## Provenance

PLAN-v3 (`assets/reports/20260820-warden-plan/PLAN-v3.md`, owner-approved
D1-D6), migrations 0051 (institution), 0053 (usage gate), 0054 (succession
hardening). Tests: `warden/warden-beat.test.sh` (stubbed model, fixture
institution) and the switchboard probe's warden section.
