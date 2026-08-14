---
migration: 0045
title: Callout dialect v2, checkpoint-pair integration, triage-0814 gates
session: gcc-work@2026-08-14
status: complete
date: 2026-08-14
---

# Migration 0045: callout v2 + checkpoint-pair + triage-0814 gates

## Why

One session's batched structural work, recorded as a retrofit at the owner's
direction. Driving constraints: five callout dialects doing one job (the
2026-08-13 spec closed them; the owner ratified the v2 model and caught two
more dialects the same hour); the enh-credits six-draft saga demanding a
content-model-first PR skill; and the 2026-08-14 backlog triage, where the
owner dispositioned 27 items and picked six for immediate action (D2, D5,
D9, D15, D18, D21 on the decision page backlog-triage-0814).

## What changes

| Surface | Change | Why |
|---|---|---|
| `scripts/box/` (NEW) | `box.sh` renderer + `vocab.tsv`, THE callout vocabulary; zcmd ext row + `~/.local/bin/box` symlink | one dialect needs one vocabulary source |
| `scripts/hooks/hook-common.sh` | `hook_box_kind()` vocab bridge added; `hook_box()` untouched | hook-side and agent-side boxes cannot drift |
| `scripts/hooks/subagent-box.sh` | v2 titles (🛫/🛬); Stop-only strays → ledger + one drain line-tag, never a box | harness internals were training the reader to ignore landings |
| `scripts/hooks/prose-smell-stop.sh` | block box is `⛔ gate · prose-smell`, heavy rails | v2 vocabulary |
| `settings.json` | NEW PreToolUse Write\|Edit gate `guard-ai-signature.sh` | the trailer ban's reason covers every human-read surface |
| `scripts/hooks/guard-prose-quality.sh` | lints ADDED lines only (diff vs old_string or existing file) | carried context kept re-blocking pre-existing dashes |
| `skills/GUIDELINES.md` §Output | both completion templates are 🏁 done boxes | absorbed dialect (owner pick 1) |
| `conventions/callout-boxes.md` | v2 spec: emoji emitters, rail severity, lifecycle seals, ▸ refs, 🏁/💡 absorbed | the ratified model |
| `skills/core-dump/SKILL.md` + `scripts/render/trace.sh` | generated `/catchup at <path>` resume row (`resume_hint` key); template H1s use commas; 2.5 captures same-session atone events | 90% consumption path made literal; fresh wounds cross the clear |
| `skills/catchup/SKILL.md` | TaskList-first rehydration (0.8); ≤2 atone watch rows in the briefing (3.3) | store survives /clear; register tied to resumed work |
| `COMMIT.md` | scoped-add default; `add -A` reserved for deliberate syncs | multi-session sweep hazard, proven in-session |
| `skills/pr-description/` (NEW) | content-model-first PR body skill | enh-credits request + adversarial verdict |
| `scripts/decision-page/decision-page.sh` | `ensure_server` trusts the port, revives via svc.sh | pm2 entry lied while the port was dead, caught mid-triage |
| `skills/shared/prepend-runtime-note.sh` | documented heading uses `·` not an em-dash | the gate blocked its own mandated format |

## What does NOT change

- `hook_box()` signature and output shape (test-pinned, 40/40).
- `/gcc-map` in any way (standing Part-4 constraint).
- The trace.sh ceremonial dump/catchup designs; rows were added, the rites
  were not redesigned.
- The checkpoint parse contract headings and validate-checkpoint.sh.
- The kanban board's independence from the Task list (owner ruling 2026-08-10).

## Verification

- [x] hook-common.test.sh 40/40, including hook_box_kind + heavy-rails pins
- [x] box.sh exercised every kind, template, tag, error path; missing-action
      guard mutation-tested red and green
- [x] subagent-box synthetic events: dispatch + landing boxes, unmatched
      ledger + deduped tag, re-fire parked
- [x] guard-prose-quality four-direction probe (carried allow, added block,
      both Write and Edit)
- [x] guard-ai-signature five-direction probe (block, allow, carried,
      policy-doc exclusion, session-line)
- [x] ensure_server green path + dead-entry revive, page HTTP 200 after
- [x] trace.sh renders: dump with hint, bare, receipt, catchup regression
- [x] cli-gating suite 155/155 core + 17/17 shim
- [x] settings.json parses (jq empty)

## Recovery

- Callout v2: revert 81da802 + 60337ce; hooks degrade to plain hook_box via
  hook_box_kind's built-in fallback, nothing dies on a half-rollback.
- Gates: remove the guard-ai-signature entry from settings.json and trash
  the script; revert the guard-prose-quality hunk in f5d58bc.
- Checkpoint pair: revert 67ea894 + 4944bc0.
- Mute files as circuit breakers, no revert needed: `.no-ai-signature-gate`,
  `.no-subagent-box`, `.no-prose-quality-gate`.

## Cross-references

- Commits: 81da802, 60337ce (pushed at 71a23f6) · 67ea894, 47fbc2c, 4944bc0,
  f5d58bc (local when this entry was written).
- Design records: `assets/reports/20260814-1410-callout-box-ideas/` ·
  `assets/reports/20260814-1655-gcc-explore-spec/spec.md` · decision page
  `backlog-triage-0814`.
- Proposals: 15 closed done + 8 rejected on 2026-08-14; deferred ids live in
  tasks #29-#41.
