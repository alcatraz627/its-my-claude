---
brief: Non-source files under assets/<type>/; asset.sh register; diagrams dual-saved; CWD=~/.claude double-nest hazard
triggers:
  - tool:asset.sh
  - topic:assets
  - topic:screenshots
  - topic:reports
related: []
tier: 2
category: conventions
updated: 2026-04-24
stale_after_days: 90
---

# Asset Management
Non-source files (screenshots, reports, PDFs, data exports) go in `~/.claude/assets/<type>/`, not the `~/.claude/` root.

## Preferred method

```bash
bash ~/.claude/assets/asset.sh register <file>
```

Handles naming + manifest registration.

## Acceptable fallback

Direct copy to the right subdirectory:
- Screenshots → `~/.claude/assets/images/`
- Reports → `~/.claude/assets/reports/`
- PDFs → `~/.claude/assets/pdfs/`
- Data exports → `~/.claude/assets/data/`

## Diagrams — dual-save

Always save to `~/.claude/assets/diagrams/` as the **canonical copy**. If the user wants a local project copy, write to both locations (global first, then copy to local). This ensures diagrams are discoverable across projects and survive project deletions.

## When CWD is `~/.claude` itself — MANDATORY

Skill templates (e.g. `/create-report`) often use relative paths like `.claude/output/...` assuming CWD is a project root with a `.claude/` subdirectory. When CWD is `~/.claude` itself, these relative paths resolve to `~/.claude/.claude/...` — a broken double-nest.

**Never create `~/.claude/.claude/` paths.** (Anti-pattern also cross-referenced in [`rules/shell.md`](../rules/shell.md) and [CLAUDE.md quick-rules](../CLAUDE.md) — watch for it whenever CWD is `~/.claude`.)

Correct targets when CWD is `~/.claude`:

| Skill default | Redirect to |
|---|---|
| `.claude/output/<report>/` | `~/.claude/assets/reports/<report>/` |
| `.claude/scratchpad/` | `~/.claude/scratchpad/` |
| `.claude/skills/` | `~/.claude/skills/` |
| any other `.claude/X` | `~/.claude/X` (drop the redundant prefix) |

A PreToolUse hook (`~/.claude/scripts/block-nested-claude.sh`) blocks any tool call whose path or command contains `/.claude/.claude/`. If you see that rejection, use an absolute path under `~/.claude/assets/` or the appropriate root instead.

## Full reference

`~/.claude/skills/shared/asset-management.md`.
