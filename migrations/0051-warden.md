# 0051: the warden

**Date:** 2026-08-21
**Type:** new subsystem (persistent monitor session + beat scheduler + institution dir)
**Sessions:** docs-skill (fc30c063)

## What changed

Owner-approved warden per `assets/reports/20260820-warden-plan/PLAN-v3.md`
(trial evidence from vb-fable/gcp-fable's live run folded in; D1-D6 approved
2026-08-21).

1. `~/.claude/warden/` — the institution: PROMPT.md (standing identity + 10
   conduct rules), state/<ward-sid8>.md, ledger.jsonl, insights.md (craft,
   prepend), spend.jsonl, WATCH.md (early-life watch list), warden-beat.sh.
2. `~/Library/LaunchAgents/com.alcatraz.warden-beat.plist` — StartInterval
   2700s, working-hours gate (09-22) inside the script, loaded; calendar
   companion event 8E135425 in Automations.
3. Beat mechanics: roster = armed goals + opt-ins, liveness cut (24h), swarm
   fence (subagents denylist); L0 artifact delta short-circuits to $0; sonnet
   session resumed via current-session with succession-on-death; governor caps
   12 invoked beats/day; spend.jsonl rows per beat.
4. Review-system integration: warden-beat row in review/registry.jsonl
   (freshness watches the watcher); docs-skill runs 3h check-ins (session
   cron c2271ddc) against WATCH.md; docs-skill is the standing guidebook
   (consulted via ipc only for novel failure shapes).
5. Tested pre-load with stubbed claude: no-ward path, delta-invoke path
   (7 live wards), $0 no-delta path, hours gate live-verified, succession
   file write verified. First REAL beat: first fire after 09:00 IST 2026-08-21.

## Rollback

launchctl bootout gui/501 ~/Library/LaunchAgents/com.alcatraz.warden-beat.plist;
trash the plist + ~/.claude/warden/; delete calendar event 8E135425; remove the
warden-beat registry row; CronDelete c2271ddc in docs-skill.
