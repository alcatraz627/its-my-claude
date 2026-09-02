---
brief: "The warden: session-liveness + event-driven revive for working agents. The 45m standing-judgment beat is RETIRED (2026-09-02, D1a); on-demand judgment survives (claude-warden open); event-driven revive is NOT currently wired (no runner for ipc-wake; ward-revive was beat-driven) pending an owner decision. Institution at ~/.claude/warden/; turn-state freshness via turnstate-active.sh."
triggers:
  - tool:claude-warden
  - topic:warden
  - topic:session-monitoring
  - phrase:"pause the warden"
  - phrase:"warden beat"
related: [scheduling-discipline, model-tier-routing]
tier: 2
category: features
updated: 2026-09-02
stale_after_days: 90
---

# The warden

> **Status, 2026-09-02: the 45m standing-judgment beat is RETIRED** (owner
> ruling lifecycle-fixes-0902 D1a, after an efficacy review). `com.alcatraz.warden-beat`
> is bootout + disabled and `warden/.paused` is set. What survives is **on-demand judgment** (`claude-warden open` resumes the
> session interactively). **Event-driven revive is NOT currently wired**: an
> adversarial review (2026-09-02) found `ward-revive.sh` was only ever invoked by
> the now-retired beat, and `ipc-wake.sh` (the intended `--reply-by` wake loop)
> has no runner and last ran 2026-08-27. Its mid-turn read was also still the
> bare-existence wedge, now repointed. Wiring a runner for it is a pending owner
> decision (it is an autonomous headless-turn-spawning daemon). The
> standing judgment session was retired because its own record showed that every warden-tagged atone
> event is a first-person warden-seat failure (6 of 6), including
> `supervisor-gate-made-the-lanes-halt` ("As warden I told both lanes 'nothing
> is done until I ratify it'"), which is the "incompetent, not merely down"
> failure the owner named. Efficacy review +
> plan: `assets/reports/20260901-warden-keep-or-kill/`. The section below
> describes the retired beat model, kept for reference until the group-entity
> rescope (owner ruling 2a) lands.

The warden watched working agents against their goals, challenged done-claims
with evidence, and escalated to the owner, never overruling. Its durable self is
`~/.claude/warden/` (PROMPT.md charter with conduct rules 1-10, WATCH.md early-life
watch items, state/ per-ward notes, ledger.jsonl, spend.jsonl, insights.md), not
any process or context.

The liveness read that once wedged the beat for 10 days (an orphaned turn-state
sentinel read as "mid-turn" forever) is fixed: `scripts/session-mgmt/turnstate-active.sh`
answers "mid-turn?" by sentinel freshness within a 30m TTL, and both the beat and
ward-revive call it. `scripts/startup/tasks/60-reap-session-state.sh` reaps the
leaked turn-state that fed the wedge.

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
