---
brief: diy-mem shell history via hooks; MCP tools preferred over log-file reads; BG process tracking
triggers:
  - tool:shell-mem
  - mcp:shell-mem
  - topic:shell-history
  - topic:background-processes
related: []
tier: 2
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Shell Memory
Shell command history is logged automatically via hooks. Use MCP tools (preferred) or the CLI dispatcher — **never read log files directly**.

## Access patterns

| Action | MCP tool (preferred) | Bash fallback |
|--------|----------------------|---------------|
| Recent commands | `shell_tail(n, date)` | `shell-mem tail [N] [date]` |
| Search history | `shell_search(query, scope)` | `shell-mem search <q> [scope]` |
| Mark BG done | `shell_mark_done(sid, cmd)` | `shell-mem mark-done <sid> <cmd>` |
| Cleanup old logs | `shell_cleanup()` | `shell-mem cleanup` |

## Log storage

`~/.claude/shell-logs/YYYY-MM-DD.md` — one file per day. Files older than 2 months can be deleted.

## Auto-injection

Context is auto-injected only when active `[BG]` entries exist. You do not need to check manually — if the injection fires, it appears in your context.

## When to use

- User asks "what did I run earlier?" → `shell_tail` or `shell_search`
- User mentions a background process → `shell_search` + `shell_mark_done` when confirmed
- Starting work in a new project → check recent commands for context
