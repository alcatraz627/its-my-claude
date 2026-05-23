---
brief: MCP server catalog (mcp-catalog.json); add-mcp skill; version pinning rules for npx servers
triggers:
  - tool:add-mcp
  - skill:add-mcp
  - topic:mcp-setup
  - mcp:mongodb
  - mcp:redis
  - mcp:postgres
  - mcp:vercel
related: []
tier: 2
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Mcp Catalog
MCP server definitions at `~/.claude/mcp-catalog.json`. Use the `add-mcp` skill to inject from catalog — **never configure from scratch**. Run `add-mcp --list` to see available servers.

## Catalog entries

`github`, `vercel`, `mongodb`, `mongodb-local`, `redis`, `redis-local`, `postgres`, `postgres-local`, `aws`, `render`, `svelte`, `vscode`, `file-tools`, `interactive-inputs`.

Proactively check when a project uses MongoDB, Redis, PostgreSQL, or other cataloged services — offer to inject via `/add-mcp`.

## Version pinning — MANDATORY for npx servers

Always pin package versions in `args` (e.g., `"mongodb-mcp-server@1.9.0"` not `"mongodb-mcp-server"`). Unpinned `npx -y` hits the npm registry on every startup to check for updates, adding 200-500ms per server.

When adding a new npx-based MCP server: **resolve the current version first and pin it.**

## Global `.mcp.json` scope

Only holds always-on servers: `github`, `scratchpad`, `shell-mem`, `inputs`, `file-tools`. Database/hosting servers (mongodb, redis, postgres, vercel, vscode) live in the catalog — inject per-project via `add-mcp`.

## Dot-prefix rule

The active file is `~/.claude/.mcp.json` (dot-prefixed). Never create `mcp.json` (no dot) — it is silently ignored. See `~/.claude/skills/shared/mcp-config.md` for the full file reference.
