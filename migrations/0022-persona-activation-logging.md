---
number: 0022
title: Persona activation + efficacy logging — persona-log.sh, two hooks, dispatch wiring
slug: persona-activation-logging
status: complete
date: 2026-06-18
affected_paths:
  - scripts/persona-log.sh
  - personas/usage/events.jsonl
  - scripts/hooks/persona-suggest.sh
  - scripts/hooks/persona-log-nudge.sh
  - scripts/atone-juror-dispatch.sh
  - skills/skeptical-review/SKILL.md
  - features/persona-activation.md
  - settings.json
  - personas/README.md
---

# Migration 0022 — Persona activation + efficacy logging

## Summary

Adds the missing substrate for two things the persona system never had: a
**proactive trigger** (how a persona gets picked up) and an **efficacy residue
trail** (how we later judge whether a persona helped). New script
`persona-log.sh` (append-only JSONL recorder + summarizer), two advisory hooks
(`persona-suggest` UserPromptSubmit, `persona-log-nudge` PostToolUse), and
mechanical logging wired into the two dispatch consumers (juror script,
skeptical-review skill). Companion to the 2026-06-18 persona Claude-consumption
rewrites (in-place, not part of this migration's structural surface).

## Why

`rg "personas/" skills/ scripts/ hooks/` returned only `atone-juror-dispatch.sh`
and `magi/SKILL.md` — i.e. working-mode personas had **no activation event at
all**. With no activation point, there was nowhere to hang a usage log, and no
proactive trigger beyond the agent reading a file when told to. That made both
"improve the trigger" and "log every usage" impossible without first building
the activation substrate. Design + rationale: `features/persona-activation.md`.

## What changes

| Area | From | To |
|---|---|---|
| Usage log | none | `scripts/persona-log.sh record\|summary\|list` → append-only `personas/usage/events.jsonl`; proxies (outcome/corrections/loop) + residue note, never a fabricated success bit |
| Dispatch logging (mechanical) | none | `atone-juror-dispatch.sh` records `juror` after persisting the verdict (stdout-safe, errors swallowed); `skeptical-review` SKILL step 5 records `skeptical-reviewer` |
| Working-mode logging (convention) | none | agents call `persona-log.sh record --mode adopted` at end of work; documented in `personas/README.md` |
| Proactive trigger | implicit file-read only | `persona-suggest.sh` (UserPromptSubmit) suggests a matching persona on strong prompt cues; action-oriented `role:` frontmatter on the rewritten personas |
| Convention enforcement | none | `persona-log-nudge.sh` (PostToolUse) nudges once/session when a working-mode persona was read but nothing logged |

## Data schema (events.jsonl)

One JSON object per invocation; empty fields omitted:
`{id, ts, persona, session, mode(adopted|dispatched), depth, task, outcome(accepted|revised|discarded|unknown), loop(converged|partial|skipped), iterations, corrections, cost_tokens, note}`.
Additive only — no consumer parses it yet except `persona-log.sh summary`.

## Backward compatibility

Fully additive. The hooks are advisory (never block) and muteable
(`personas/usage/.suggest-off`, `personas/usage/.nudge-off`). The juror logging
is best-effort and cannot affect the verdict (output forced off stdout, errors
swallowed) — the dispatch contract is unchanged (verified against
`atone-juror-dispatch.sh`: JSON keys, pure-function framing, `$PERSONA` path all
intact). Removing any piece leaves the rest working.

## Verification

- `persona-log.sh` record/summary/list exercised; events.jsonl validates as JSONL.
- juror logging exercised in isolation (records correctly, stdout stays the verdict).
- both hooks exercised with simulated payloads (suggest fires on cues + dedupes;
  nudge fires on the 5th call after a working-mode read and excludes dispatch personas).
- `settings.json` re-validated as JSON after registration.
- **Not exercised end-to-end:** a live `claude -p` juror dispatch and a real
  session firing the hooks in the harness — both verified by isolated simulation
  only (UNCONFIRMED in-harness; the added code paths are individually tested).

## Recovery / revert

`trash scripts/persona-log.sh scripts/hooks/persona-suggest.sh scripts/hooks/persona-log-nudge.sh`;
remove the two hook entries from `settings.json`; revert the logging blocks in
`atone-juror-dispatch.sh` (the `persona-log` call before the final `printf`) and
`skills/skeptical-review/SKILL.md` (step 5). `personas/usage/events.jsonl` is
inert if unread.

## Cross-references
- Design: `features/persona-activation.md`
- Grounding: `assets/reports/20260618-persona-dogfood/` (research, spec, skeptical-review)
- `rules/skill-spec-update-not-honored-by-running-session.md` — why the nudge hook (data-path gate), not just the README convention, is the binding part
