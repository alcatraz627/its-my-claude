---
brief: A mid-session SKILL.md change that adds a mandatory phase is advisory-only to sessions started before it — enforce at the data-write CLI, not the spec, or it's silently bypassable
triggers:
  - topic:skill-loading
  - topic:spec-enforcement
  - phrase:"add a mandatory phase"
  - phrase:"SKILL.md cache"
  - skill:migrate
related:
  - rules/sub-agent-outputs.md
tier: 1
category: rules
updated: 2026-05-20
stale_after_days: 120
---

# Spec mandates are advisory until a data-path gate enforces them

Claude Code loads a `SKILL.md` once at skill-discovery time per session. Mid-session updates are **not** re-read, and there is no notification mechanism. Any spec change that introduces a mandatory phase is advisory-only to every session that started before the change — those sessions operate faithfully to their cached version and silently skip the new requirement.

Graduated from atone slug `skill-spec-update-not-honored-by-running-session` (S3, 2026-05-16).

## The incident

The `/atone` skill added Phase 2.5 (juror dispatch) mid-session. A running backend session invoked `/atone` after the update and skipped Phase 2.5 entirely — its SKILL.md cache predated the change. No judgment was dispatched for the resulting event. The defect surfaced only when the user manually reviewed the RCA file. This is a system-architecture gap, not an agent slip: the agent had no way to know the spec had mutated.

## The rule

When merging a `SKILL.md` change that adds a mandatory phase or step:

1. **Also add the corresponding enforcement at the data-write CLI** (`atone.sh`, `affirm.sh`, the script that persists the result). Example fix from the incident: `atone.sh add` refuses S3 events without a linked judgment unless `ATONE_NO_JUROR=1` is explicitly set — making a skip loud and loggable instead of silent.
2. Ask: *"what stops a stale-spec session from bypassing this silently?"* If the answer is "nothing," the spec is **opt-in** until the data-path gate exists.
3. Spec-level mandates whose enforcement depends on the agent self-checking are advisory by construction. Mechanical enforcement must live where the data is written.

## What this rule does NOT mean

- Not every SKILL.md change needs a CLI gate — only those introducing a *mandatory* phase whose omission is a defect.
- Advisory spec text is still useful for sessions that start fresh after the change; it's just not binding on in-flight sessions.

## Diagnostic signal

You're adding "Phase N is MANDATORY" / "you MUST do X" to a SKILL.md, and the only thing enforcing it is the agent reading the spec. There is no check at the script that writes the result.

## Related

- `prop-20260516-003148-a5` — SKILL.md hot-reload (the runtime-layer fix, outside this system's control)
- Atone event + RCA: `bash ~/.claude/scripts/atone.sh search skill-spec-update-not-honored`
