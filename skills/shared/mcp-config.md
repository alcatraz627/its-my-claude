# MCP Configuration Reference

## File locations — read this first

| File | Purpose | Scope |
|---|---|---|
| `~/.claude/.mcp.json` | **Active global MCP servers** — Claude Code reads this | All sessions |
| `<project>/.mcp.json` | Active project-level MCP servers — merged with global | That project only |
| `~/.claude/mcp-catalog.json` | Pre-configured definitions for `/add-mcp` skill | Reference only — NOT read by Claude Code directly |

## ⚠ Common mistake: wrong filename

`~/.claude/.mcp.json` and `~/.claude/mcp.json` are **two different files**.

Claude Code reads **`.mcp.json`** (dot-prefixed). Creating `mcp.json` (no dot) is silently ignored.

This burned us on 2026-04-03: the Opus agent created `~/.claude/mcp.json` when adding `shell-mem`, which meant the server was registered nowhere Claude Code could see it. The real config at `~/.claude/.mcp.json` already had 8 servers.

**Always verify with:**
```bash
cat ~/.claude/.mcp.json | jq '.mcpServers | keys'
```

## Adding a new global MCP server

Edit `~/.claude/.mcp.json` — add to the `mcpServers` object:
```json
"my-server": {
  "type": "stdio",
  "command": "node",
  "args": ["/absolute/path/to/server.js"]
}
```

Then also add an entry to `~/.claude/mcp-catalog.json` so `/add-mcp` can inject it into projects later.

## Adding a project-level MCP server

Edit or create `.mcp.json` in the project root (dot-prefixed). Same format.

## Currently registered global servers

As of 2026-04-03, `~/.claude/.mcp.json` contains:

| Server | Package / path |
|---|---|
| `github` | `@modelcontextprotocol/server-github` |
| `vercel` | `@vercel/mcp-server` |
| `mongodb` | `mongodb-mcp-server` |
| `aws` | `awslabs.core-mcp-server@latest` |
| `redis` | `redis-mcp` |
| `postgres` | `@modelcontextprotocol/server-postgres` |
| `vscode` | `@vscode/mcp` |
| `scratchpad` | `~/.claude/scratchpad/mcp-server.mjs` |
| `shell-mem` | `~/Code/Claude/diy-claude-mem/mcp-server/server.js` |

## Catalog vs active config

The catalog (`mcp-catalog.json`) is a menu of servers you *could* add. The `.mcp.json` is what's actually running. They are separate. Adding to the catalog does not activate a server.
