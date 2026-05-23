---
brief: pm2 dev servers; port conventions (30xx/50xx); persistence (startup + save); never 3000/5000
triggers:
  - tool:pm2
  - topic:dev-servers
  - topic:ports
related: []
tier: 2
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Dev Servers
All agent apps use **pm2** for dev server lifecycle.

## Port conventions

- **Frontend:** `30xx`
- **Backend:** `50xx` (last 2 digits match frontend)
- **Never use 3000 or 5000** — AirPlay / macOS conflicts

Example pair: frontend `3042` / backend `5042`.

## Persistence requires BOTH steps

```bash
pm2 startup    # registers LaunchAgent
pm2 save       # snapshots process list
```

**`pm2 save` alone does NOT survive reboots.** Both are required.

## Port registry

`~/.claude/scratchpad/global/port-registry.md` tracks all assigned ports. Use `bash ~/.claude/scripts/dev-servers/pm2-register.sh register <name>` — it auto-assigns the next free 30xx/50xx pair and writes ecosystem config.

## nginx + `.test` domains

`bash ~/.claude/scripts/dev-servers/gen-nginx-conf.sh` generates nginx server blocks for registered apps, handling the Host-header rewrite needed for Vite/Next.js. `--dry-run` to preview.

## Full guide

`~/.claude/dev-servers-guide.md` — complete pm2 + nginx + port workflow including persistence, registration script usage, and troubleshooting.
