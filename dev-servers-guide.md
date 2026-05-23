# Dev Servers — pm2 and Ports

Full reference for running agent apps with pm2.

## Port Convention

- Frontend: `30xx`, Backend: `50xx`
- Last 2 digits of port must match across frontend/backend pair
- Pick an unused suffix (10–99): `ls ~/.claude/scratchpad/global/port-registry.md`
- **Never use port 3000 or 5000** — reserved by AirPlay/macOS system services

## Port Registry

`~/.claude/scratchpad/global/port-registry.md` — update this when adding a new server.

## Persistence — One-Time Machine Setup

**Both steps required** — `pm2 save` alone is not enough to survive a reboot.

```bash
pm2 startup          # prints a sudo command — run it to register the LaunchAgent
# (run the printed command, then:)
pm2 save             # snapshot current process list to ~/.pm2/dump.pm2
```

After this, pm2 auto-resurrects all saved processes on boot. If the daemon restarts
unexpectedly and processes are missing, run `pm2 resurrect` to restore from the dump.

> **Gotcha (2026-04-08):** After a system event cleared the pm2 daemon, only scaffold-server
> survived because it was started manually. The 10 other saved processes in dump.pm2 were not
> restored — `pm2 startup` had not been configured. Always verify with `pm2 startup` after
> setting up a new machine.

## Registering a New App (Standard Workflow)

Use `pm2-register.sh` to allocate ports, update the registry, and get an ecosystem config snippet:

```bash
# Backend only
bash ~/.claude/scripts/dev-servers/pm2-register.sh register --name my-api --type server

# Frontend + backend pair (Vite default)
bash ~/.claude/scripts/dev-servers/pm2-register.sh register --name my-app --type pair

# Pair with specific framework and suffix
bash ~/.claude/scripts/dev-servers/pm2-register.sh register --name my-app --type pair --framework next --suffix 47

# Change a project's ports
bash ~/.claude/scripts/dev-servers/pm2-register.sh change --name my-app --suffix 55

# Remove from registry
bash ~/.claude/scripts/dev-servers/pm2-register.sh deregister --name my-app

# Show registry + live pm2 status
bash ~/.claude/scripts/dev-servers/pm2-register.sh list
```

The script:
1. Auto-picks an unused suffix (or validates your `--suffix`)
2. Appends rows to `port-registry.md`
3. Prints a ready-to-use `ecosystem.config.cjs` snippet
4. Shows both `localhost:PORT` and `http://local.PORT.run` access URLs

After registration:
```bash
# Copy the ecosystem snippet, then:
pm2 start ecosystem.config.cjs && pm2 save

# Optional: activate .test domains
bash ~/.claude/scripts/dev-servers/gen-nginx-conf.sh && sudo nginx -t && sudo nginx -s reload
```

## pm2 Setup for a New Server (Manual)

1. Pick unused suffix (10-99)
2. Create `ecosystem.config.cjs` in project root
3. Register ports in port-registry.md
4. Add pm2 scripts to `package.json`:
   ```json
   "scripts": {
     "start": "pm2 start ecosystem.config.cjs",
     "stop": "pm2 delete ecosystem.config.cjs",
     "logs": "pm2 logs"
   }
   ```
5. Start, then save: `pm2 start ecosystem.config.cjs && pm2 save`
6. Use `pm2 delete <name>` to stop permanently (not `pm2 stop`)

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Processes missing after reboot | `pm2 startup` not configured | Run `pm2 startup`, run the printed command, `pm2 save` |
| Process keeps restarting (`↺` count high) | Script error or missing file | `pm2 logs <name>` to see error |
| Port already in use | Stale process or another app | `lsof -i :<port>` to find the owner |
| `pm2` not found in Claude tools | PATH doesn't include homebrew | Prefix commands: `export PATH="$PATH:/opt/homebrew/bin"` |

## One-off HTML

Use the scaffold server at `localhost:5080` — no pm2 needed.

## Full Infrastructure Templates

`~/Code/Claude/visualize-claude/templates/_agent-infra/`
