---
number: 0018
title: Context-capture automation (PreCompact/SessionEnd enrichment + settings guard)
slug: context-capture-automation
status: complete
date: 2026-06-05
affected_paths:
  - scripts/session-mgmt/pre-compact-checkpoint.sh
  - scripts/session-mgmt/session-end-checkpoint.sh
  - scripts/session-mgmt/enqueue-auto-coredump.sh
  - scripts/hooks/ctx-signal-nudge.sh
  - scripts/hooks/guard-settings-write.py
  - scripts/tool-counter.sh
  - settings.json
  - ~/.claude.json
---

# Migration 0018 — Context-capture automation

## Why

Two driving constraints, both surfaced in one session (2026-06-05):

1. **Recurring "MCP down + settings error".** Root cause was two genuinely broken
   MCP servers (shell-mem missing node deps; mongodb unpinned npx hitting an
   `Invalid Version`) plus a duplicate github definition where a broken global
   copy (empty token) shadowed the working pinned project copy. There was **no
   write-time guard** against invalid settings — only a non-blocking SessionStart
   warning that fired *after* corruption.

2. **Context-management paralysis.** The user wanted the compact /
   core-dump+clear+catchup decision automated as far as mechanically possible.
   Audit showed the PreCompact checkpoint captured only mechanical state and
   ignored the richest semantic artifact (`session-notes/_active.md`, which
   sync-todos already populates); there was no SessionEnd snapshot; tool-counter
   nudges were one-shots at 30/60 with no checkpoint awareness.

## What changes

| Area | From | To |
|---|---|---|
| PreCompact checkpoint | mechanical only (git/files/counts) | also reads `session-notes/<sid>.md` / `_active.md`; honors `PRECOMPACT_KIND_OVERRIDE` |
| SessionEnd | no hook (event unused) | `session-end-checkpoint.sh` reuses PreCompact logic, kind=`session-end`, skips `prompt_input_exit` |
| tool-counter nudges | one-shot at 30 & 60 | recurring every 30; suppressed if a checkpoint landed in last 5 min |
| Boundary detection | none | `ctx-signal-nudge.sh` (UserPromptSubmit): cwd-change / long-idle → compact-vs-clear nudge, rate-limited 15 min |
| Auto semantic core-dump | manual `/retro-dump` only | opt-in `enqueue-auto-coredump.sh` on PreCompact+SessionEnd → retro-dump queue (gate: `~/.claude/.auto-coredump-enabled`) |
| Settings write safety | SessionStart warning (post-hoc) | `guard-settings-write.py` (PreToolUse): blocks invalid JSON / bad hook shape / missing mcpServers before the write |
| MCP servers (user config) | mongodb (broken) + github×2 | mongodb removed; broken global github removed, pinned project copy kept |

## What does NOT change

- The existing PreCompact/PostCompact recovery flow, `/catchup`, `/core-dump`,
  `/workspace`, sync-todos — all unchanged; this is additive.
- `validate-settings-hooks.sh` (the SessionStart warning) stays as a backstop.
- C1 (auto core-dump) is **inert until opted in** — wiring it changes nothing
  until `~/.claude/.auto-coredump-enabled` exists AND a queue processor is
  scheduled.
- shell-mem MCP config (path unchanged; only its `node_modules` were installed).

## Verification

- [x] `python3 -c json.load` passes on settings.json / settings.local.json / .mcp.json
- [x] `validate-settings-hooks.sh` reports clean
- [x] all 5 new hook commands present under correct events
- [x] all scripts `bash -n` / `ast.parse` clean
- [x] A1: synthetic PreCompact run includes "Workspace Notes" section
- [x] A2: SessionEnd payload writes checkpoint kind=session-end; `prompt_input_exit` bails
- [x] A3: nudge at 30/90, silent at 45, suppressed with fresh checkpoint
- [x] B1: cwd-change + idle nudges fire; first turn + rate-limit silent
- [x] C1: gate-absent no-op; low-tool skip; gated+enough-tools queues
- [x] guard-settings-write.py: 7/7 cases (valid pass, invalid/bad-shape/no-mcpServers block, unrelated ignore)
- [ ] Live confirmation next session (hooks bind at session start)

## Rollback

```bash
# Restore settings.json from a dated backup (pick the earliest of the run)
cp -f ~/.claude/settings.json.bak-2026-06-05 ~/.claude/settings.json
# Remove the new scripts
trash ~/.claude/scripts/session-mgmt/session-end-checkpoint.sh \
      ~/.claude/scripts/session-mgmt/enqueue-auto-coredump.sh \
      ~/.claude/scripts/hooks/ctx-signal-nudge.sh \
      ~/.claude/scripts/hooks/guard-settings-write.py
# pre-compact-checkpoint.sh / tool-counter.sh: revert via git
git -C ~/.claude checkout -- scripts/session-mgmt/pre-compact-checkpoint.sh scripts/tool-counter.sh
```

Consider rollback if: the settings guard blocks legitimate edits (it fails open
by design, so this would be a bug), or the new nudges prove noisy.

## Phases

1. **Tier A** — PreCompact enrichment + SessionEnd hook + tool-counter awareness ✅
2. **Tier B** — ctx-signal-nudge UserPromptSubmit hook ✅
3. **Tier C** — opt-in enqueue-auto-coredump (inert until enabled) ✅
4. **MCP cleanup** — mongodb removed, github deduped ✅

## Notes / followups

- **Activating C1** requires two steps: `touch ~/.claude/.auto-coredump-enabled`
  AND scheduling `~/.claude/scripts/checkpoint/retro-dump.sh --queue` (via
  gcc-schedule, which auto-creates the Calendar companion per
  rules/cron-calendar-companion.md). Without the processor, queued items never run.
- **github token**: dedup revealed `GITHUB_PERSONAL_ACCESS_TOKEN` is unset; the
  old global copy masked this with an empty string. User must export it.
- backups: `settings.json.bak-2026-06-05` (+ bak2/bak3/bak4 for each wiring step).
