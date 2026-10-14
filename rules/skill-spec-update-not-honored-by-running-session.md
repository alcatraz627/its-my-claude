---
brief: SKILL.md mandates are advisory to already-running sessions (specs are cached at discovery and never re-read). When adding a mandatory phase to a skill, add enforcement at the data-write CLI in the same change, or it is silently bypassable. Read this rule when editing SKILL.md mandates or debugging a skipped skill phase.
triggers:
  - topic:skill-loading
  - topic:spec-enforcement
  - phrase:"add a mandatory phase"
  - phrase:"SKILL.md cache"
  - skill:migrate
related:
  - rules/sub-agent-outputs.md
paths:
  # autoload opt-out (2026-07-09 demotion pass): only fires when editing a SKILL.md
  # mandate or debugging a skipped phase, a narrow authoring domain. Read on demand
  # from rules/00-index.md. Sentinel never matches a real file; revert by deleting
  # this paths: block.
  - "zz-on-demand--never-autoloads"
tier: 2
category: rules
updated: 2026-07-09
stale_after_days: 120
---

# Spec mandates are advisory until a data-path gate enforces them

Claude Code loads a `SKILL.md` once at skill-discovery time per session. Mid-session updates are **not** re-read, and there is no notification mechanism. Any spec change that introduces a mandatory phase is advisory-only to every session that started before the change. Those sessions operate faithfully to their cached version and silently skip the new requirement.

Graduated from atone slug `skill-spec-update-not-honored-by-running-session` (S3, 2026-05-16).

## The incident

The `/atone` skill added Phase 2.5 (juror dispatch) mid-session. A running backend session invoked `/atone` after the update and skipped Phase 2.5 entirely, because its SKILL.md cache predated the change. No judgment was dispatched for the resulting event. The defect surfaced only when the user manually reviewed the RCA file. The cause is a system-architecture gap, and the agent made no slip: it had no way to know the spec had mutated.

## The rule

When merging a `SKILL.md` change that adds a mandatory phase or step:

1. **Also add the corresponding enforcement at the data-write CLI** (`atone.sh`, `affirm.sh`, the script that persists the result). Example fix from the incident: `atone.sh add` refuses S3 events without a linked judgment unless `ATONE_NO_JUROR=1` is explicitly set, which makes a skip loud and loggable instead of silent.
2. Ask: *"what stops a stale-spec session from bypassing this silently?"* If the answer is "nothing," the spec is **opt-in** until the data-path gate exists.
3. Spec-level mandates whose enforcement depends on the agent self-checking are advisory by construction. Mechanical enforcement must live where the data is written.

## What this rule does NOT mean

- Not every SKILL.md change needs a CLI gate. Only changes that introduce a *mandatory* phase whose omission is a defect need one.
- Advisory spec text is still useful for sessions that start fresh after the change. It just does not bind in-flight sessions.

## Diagnostic signal

You are adding "Phase N is MANDATORY" or "you MUST do X" to a SKILL.md, and the only thing enforcing it is the agent reading the spec. There is no check at the script that writes the result.

## Related

- `prop-20260516-003148-a5`: SKILL.md hot-reload (the runtime-layer fix, outside this system's control)
- Atone event and RCA: `bash ~/.claude/scripts/atone.sh search skill-spec-update-not-honored`
