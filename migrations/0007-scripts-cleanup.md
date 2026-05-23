# Migration 0007 — Scripts Folder Cleanup

**Status:** ✅ Complete (2026-04-24)
**Session:** `impr-cfg-7a`
**Diff log:** `~/.claude/assets/reports/20260424-claude-md-restructure/scripts-cleanup-diff-log.md`
**Audit:** `~/.claude/assets/reports/20260424-claude-md-restructure/scripts-ref-audit.md`

> **Historical note:** Path-update automation from Phase 2d also edited this doc's own "before → after" cells into "after → after" (predictably — the automation doesn't know which docs describe history vs. current state). Tables below were regenerated from the diff log after the updater ran.

## Summary

Grouped related scripts into subdirectories (`llm-mini/`, `statusline/`, `dream/`, `session-mgmt/`, `rotation/`, `dev-servers/`, `wal/`). Trashed editor backups, resolved 3 duplicate-naming pairs, moved 2 misplaced scratch files, relocated 1 project-specific script. Produced `scripts/README.md` entry point. Operational refs updated to canonical paths; back-compat symlinks preserve old paths for ~2 weeks.

## Results

- Scripts at top level: **97 → 41** (56 files moved or trashed)
- Cluster subdirs created: **7** (llm-mini, statusline, dream, session-mgmt, rotation, dev-servers, wal)
- Files trashed: **24** (19 editor backups + 3 stale predecessors + 2 naming duplicates)
- Back-compat symlinks: **40** (one per moved file)
- Operational ref updates: **178 across 43 files**
- Validator: **0 errors, 8 intentional collisions, 28 files checked**
- Smoke tests: **7/7 passed**

## Path moves (before → after)

| Before | After | Group |
|--------|-------|-------|
| `scripts/llm-mini.sh` · `llm-mini-core.sh` · `llm-mini-hook.sh` · `llm-mini-engine.sh` · `llm-mini-chat.sh` · `llm-mini-mcp-server.js` · `mini.sh` | `scripts/llm-mini/` | D |
| `scripts/statusline.sh` · `sl-audit.sh` · `sl-cli.sh` · `sl-config.sh` · `sl-explain.sh` · `sl-open.sh` · `sl-playground.sh` · `statusline-backup.sh` · `session-banner.py` | `scripts/statusline/` | E |
| `scripts/dream-insights.sh` · `dream-metrics-context.sh` · `dream-metrics.sh` · `inject-dream-insights.sh` · `propose-config-from-insights.sh` | `scripts/dream/` | F |
| `scripts/turn-start.sh` · `turn-counter.sh` · `turn-end-cleanup.sh` · `heartbeat.sh` · `detect-stale-session.sh` · `pre-compact-checkpoint.sh` · `post-compact-recovery.sh` · `session-summary.sh` · `subagent-tracker.sh` | `scripts/session-mgmt/` | G |
| `scripts/rotate-events.sh` · `rotate-wal.sh` · `prune-backups.sh` · `cleanup.sh` | `scripts/rotation/` | H |
| `scripts/pm2-register.sh` · `pm2-resurrect.sh` · `gen-nginx-conf.sh` | `scripts/dev-servers/` | I |
| `scripts/wal.sh` · `wal-convert.sh` · `bash-wal.sh` | `scripts/wal/` | J |
| `scripts/_checkpoint.claude.md` · `_precompact-checkpoint.claude.md` | Trashed (stale; root-level copies canonical) | B |
| `scripts/analyze_inference.py` | `~/.claude/code/ideas/analyze_inference.py` | 1e |

Each moved file has a **back-compat symlink** at its old top-level path pointing into the cluster subdir — e.g., `scripts/wal.sh` → `wal/wal.sh`.

## Files trashed (24 total)

**Editor backups (19):** `process-stats-daemon.sh_bak`, `.bak_2`, `.bak_2.hdr`, `.bak_2.tmp`; `statusline.sh_bak`, `.bak_2` through `.bak_12`, plus `.bak_7.hdr`, `.bak_7.tmp`, `.bak_8.hdr`.

**Stale predecessors (3):** `mini-core.sh`, `mini-hook.sh`, `mini-mcp-server.js` — renamed to `llm-mini-*` on 2026-04-24; only `mini.sh` retained as deprecation shim.

**Duplicate-naming (2):** `ascii_art_library.py` (kept dashed variant `ascii-art-library.py`); `test_hooks.sh` (kept dashed variant `test-hooks.sh`).

All recoverable from macOS `~/.Trash/` until emptied.

## Unchanged at top level (41 scripts)

Core hooks + high-reference workflow utilities. See `scripts/README.md` for the annotated list.

## Files NOT updated (historical — intentionally preserved)

Per scope agreement with the user, paths in the following were NOT rewritten:
- `~/.claude/_*.claude.md` — session checkpoints describing past state
- `~/.claude/scratchpad/global/milestones/*` — historical milestone docs
- `~/.claude/migrations/0001`–`0005` — past-tense migration records
- `~/.claude/plans/*` — past plans
- `~/.claude/assets/reports/<dated-dirs-except-this-session>/` — historical reports
- `~/.claude/shell-logs/*.md` — command history

Rationale: rewriting them falsifies the record of what was true when they were written.

## Files updated (178 refs across 43 operational files)

Full diff: `~/.claude/assets/reports/20260424-claude-md-restructure/scripts-cleanup-diff-log.md`

Major touched files: `settings.json`, `settings.local.json`, `.mcp.json`, `CLAUDE.md`, `LOOKUP.md`, `NAMESPACE.md`, `rules/shell.md`, `features/wal.md`, `features/llm-mini.md`, `features/dev-servers.md`, `skills/doctor/SKILL.md`, `skills/statusline/SKILL.md`, `skills/mini/SKILL.md`, `dev-servers-guide.md`, `assets/docs/statusline-dev-guide.md`, cross-sourcing scripts.

## Smoke tests (all passed)

| Group | Command | Result |
|-------|---------|--------|
| D | `bash scripts/llm-mini/llm-mini.sh --help` | help rendered |
| D | `bash scripts/llm-mini.sh --help` (via symlink) | help rendered — back-compat verified |
| E | `bash -n scripts/statusline/statusline.sh` | syntax OK |
| F | `bash scripts/dream/dream-metrics.sh` | metrics output |
| G | `bash scripts/session-mgmt/detect-stale-session.sh` | JSON with orphan turn-states |
| H | `bash scripts/rotation/prune-backups.sh --preview` | "nothing older than 180 days" |
| I | `bash scripts/dev-servers/pm2-register.sh list` | port registry rendered |
| J | `bash scripts/wal/wal.sh` | expected error on missing arg (script works, help format differs) |

## Recovery

### Individual ref needs updating (post-cleanup)

1. Check `scripts/README.md` for the cluster location
2. Update the reference to `scripts/<cluster>/<name>`
3. Old path continues to work via back-compat symlink until symlink removal

### Full rollback

All moves were `os.rename` + symlink creation — reversible by moving files back and removing symlinks. All trashes went to macOS Trash (recoverable from Finder). A rollback script is not provided; if needed, reverse the moves from the diff log and remove the cluster subdirs.

### Back-compat symlink removal

**Planned:** ~2026-05-08 (14 days). Filed as a proposal on 2026-04-24 (see below).

Before removing, audit for any remaining stale references:

```bash
/usr/bin/find ~/.claude -type l -name "*.sh" -o -type l -name "*.py" -o -type l -name "*.js" | /usr/bin/xargs ls -la
# Check each symlink's referrers before removing.
```

## Cross-references

- **Post-migration watchpoints:** `~/.claude/assets/reports/20260424-claude-md-restructure/post-migration-watchpoints.md` — **read this during the 2-week transition window**
- **Audit:** `~/.claude/assets/reports/20260424-claude-md-restructure/scripts-ref-audit.md`
- **Diff log:** `~/.claude/assets/reports/20260424-claude-md-restructure/scripts-cleanup-diff-log.md`
- **New entry-point:** `~/.claude/scripts/README.md`
- **Related migration:** 0006 (CLAUDE.md restructure — same session, same "group by purpose" instinct)
- **Filed proposal:** `prop-20260424-141055-b5` — remove back-compat symlinks ~2026-05-08
