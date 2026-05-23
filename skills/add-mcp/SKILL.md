---
name: add-mcp
description: Add pre-configured MCP servers from the central catalog (~/.claude/mcp-catalog.json) into the current project's .mcp.json. Avoids re-configuring from scratch.
triggers:
  - "add mcp"
  - "set up mcp"
  - "configure mcp"
  - "need mongodb mcp"
  - "need redis mcp"
  - "add mcp server"
  - "/add-mcp"
---

# add-mcp

Injects MCP server configs from `~/.claude/mcp-catalog.json` into the current project's `.mcp.json`. Handles template variable substitution interactively.

## Usage

```
/add-mcp [server-name,...] [--list] [--dry-run]
```

| Argument | Description |
|---|---|
| `server-name,...` | One or more catalog entry names (e.g. `mongodb-local redis`) |
| `--list` | Print all available catalog entries with descriptions and exit |
| `--dry-run` | Show what would be written without modifying `.mcp.json` |

If no server names are given, show the catalog and ask which to add.

---

## Step 1 — Read the catalog

```bash
cat ~/.claude/mcp-catalog.json
```

Parse `catalog` object. Each entry has:
- `description` — one-line summary
- `tags` — categories (database, cloud, hosting, etc.)
- `requiresEnv` — env var names that must exist in the shell (from `~/.zshrc` or env)
- `templateVars` — keys with default values that the user can override at inject time
- `when` — guidance on when to use this MCP
- `config` — the actual `mcpServers` entry to inject

If `--list`, print a table and exit:
```
Available MCP servers in catalog:

  github          version-control   GitHub API (issues, PRs, repos, files)
  vercel          hosting           Vercel deployments, logs, env vars
  mongodb         database          MongoDB with custom connection string
  mongodb-local   database,local    MongoDB at localhost:27017 (preset)
  redis           cache             Redis with custom connection string
  redis-local     cache,local       Redis at localhost:6379 (preset)
  postgres        database          PostgreSQL with custom connection string
  postgres-local  database,local    PostgreSQL at localhost:5432/postgres (preset)
  aws             cloud             AWS services via default profile
  render          hosting           Render.com services and deploys
  svelte          docs,framework    Official Svelte/SvelteKit documentation
  vscode          editor            VS Code workspace state access
```

---

## Step 2 — Resolve which servers to add

If server names were passed as arguments, use those.

If no arguments:
1. Print the catalog table above
2. Ask: "Which MCP servers should I add to this project? (space-separated names, or 'all')"
3. Wait for input

Validate all names against the catalog. For any unknown name, print an error and list close matches.

---

## Step 3 — Read or initialize project .mcp.json

Check for `.mcp.json` in the current working directory:

```bash
cat .mcp.json 2>/dev/null
```

If it exists: parse it and note existing `mcpServers` keys.
If it doesn't exist: start with `{ "mcpServers": {} }`.

For each requested server that **already exists** in the project's `.mcp.json`:
- Print: `  ⚠ 'name' already present in .mcp.json — skipping`
- Remove from the list unless `--force` was passed

---

## Step 4 — Resolve template variables

For each server being added, check `templateVars`:

If `templateVars` is empty or absent: proceed directly.

If `templateVars` has keys:
1. Print the default values
2. Ask: "Override any template values? Press Enter to keep defaults."
   - Show each key with its default: `  MONGO_URI [mongodb://localhost:27017]: `
   - Wait for input per variable
3. Substitute `{{KEY}}` in the config with the resolved value

For `requiresEnv` keys: check if they exist in the environment. If missing, warn but don't block:
```
  ⚠ GITHUB_PERSONAL_ACCESS_TOKEN not found in environment.
    The MCP will be added but will fail at runtime until this env var is set.
    Add it to ~/.zshrc or your project's .env file.
```

---

## Step 5 — Merge and write

Deep-merge the resolved `config` entries into the existing `.mcp.json` under `mcpServers`.

If `--dry-run`: print the resulting JSON and exit without writing.

Write the file:
```bash
# Use python for reliable JSON formatting
python3 -c "
import json, sys
with open('.mcp.json') as f:
    existing = json.load(f)
new_servers = json.loads(sys.stdin.read())
existing.setdefault('mcpServers', {}).update(new_servers)
print(json.dumps(existing, indent=2))
" <<< '<json>' > .mcp.json
```

Or write directly with the Write tool if python isn't available.

---

## Step 6 — Confirm

Print a summary:
```
  ✓ .mcp.json updated

  Added:
    mongodb-local   → npx mongodb-mcp-server (localhost:27017)
    redis-local     → npx redis-mcp (localhost:6379)

  Restart Claude Code (or run /mcp) for new servers to take effect.
```

Remind the user that `.mcp.json` changes require a Claude Code restart to connect the new servers.

---

## Notes

- Never print secret values from `requiresEnv` entries.
- The catalog is at `~/.claude/mcp-catalog.json`. Add new entries there to make them available everywhere.
- To add a new entry to the catalog, edit `~/.claude/mcp-catalog.json` directly — it's plain JSON.
- Plugin-provided MCPs (Chrome DevTools, Playwright, Sentry, Slack) are managed by their plugin and do NOT need entries here.
