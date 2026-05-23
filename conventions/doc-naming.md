---
brief: Point-in-time YYYYMMDD- prefix + session tag; living docs no datestamp; session-tag format rules
triggers:
  - topic:doc-naming
  - topic:file-naming
  - phrase:"session tag"
related: [features/context-retention.md]
tier: 1
category: conventions
updated: 2026-04-24
stale_after_days: 90
---

# Doc Naming
Naming and session-tagging rules for files Claude creates.

## Quick rules

- **Point-in-time files** (scratchpad plans, checkpoints, research, memory files): prefix with `YYYYMMDD-`, add session tag
- **Living docs** (WAL, runtime-notes, CLAUDE.md, SKILL.md, registries, source code): no datestamp, no session tag (WAL/runtime-notes encode session identity in their headers)

## Session tag format

```html
<!-- sessions: fix-auth-3b@2026-03-31, add-chart-f1@2026-03-29 -->
```

Each entry has `id@date`. Update timestamp if >1 day stale. Remove entries >3 days old when touching the file.

## Examples

- Scratchpad plan written 2026-04-24, session `impr-cfg-7a`: `20260424-claude-md-restructure-plan.md` with session tag
- Report for same session: `~/.claude/assets/reports/20260424-claude-md-restructure/plan.md`
- Checkpoint file: `_20260424-impr-cfg-7a.claude.md` (root-level scratch uses underscore prefix)

## Full spec

See `~/.claude/skills/shared/doc-naming.md` for complete rules, edge cases, and rationale.
