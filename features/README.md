# `~/.claude/features/` — Subsystem & integration docs

> Features document **how a thing works**. Reference material for tools, MCPs, hooks, and integrations — not behavioral rules.

## When to write here

- A new script or CLI tool worth referencing (`features/llm-mini.md`, `features/claudew.md`)
- An MCP server's intent and usage pattern (`features/mcp-catalog.md`)
- A hook system or pipeline (`features/hinter-pipeline.md`, `features/wal.md`)
- An OS-level integration (`features/desktop-automation.md`, `features/tab-title.md`)

## When NOT to write here

- A behavioral mandate → `~/.claude/rules/`
- An output format spec → `~/.claude/conventions/`
- The script itself → `~/.claude/scripts/<name>/`
- A point-in-time report → `~/.claude/assets/reports/`

## File shape

YAML frontmatter required (`brief`, `triggers:`, `related`, `tier`, `category`, `updated`, `stale_after_days`). Triggers prefixed `tool:` / `topic:` / `phrase:` / `skill:` / `mcp:`.

Body: open with what the thing IS (code-agnostic), then how to invoke / configure, then caveats. Cross-link related features with `[[feature-name]]`-style links when natural.

## See also

- `PLACEMENT.md` — placement rules
- `LOOKUP.md` — global address book
- `NAMESPACE.md` — std::claude::\* clusters that often touch features
