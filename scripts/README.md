# `~/.claude/scripts/` — Entry-point reference

<!-- sessions: impr-cfg-7a@2026-04-24 -->

Operational executables for the global Claude config. Organized into clusters (subdirs) with core hooks and workflow utilities at the top level. See `~/.claude/migrations/0007-scripts-cleanup.md` for the 2026-04-24 restructure.

> **Back-compat:** every moved script has a symlink at its old top-level path pointing to the new subdir. Old paths keep working for ~2 weeks, then symlinks get pruned. Use the canonical paths below when writing new code.

---

## Layout

```
scripts/
├── <core scripts at top level>    # hooks + workflow utilities with many callers
│
├── llm-mini/                      # Fast sub-second model surfaces
├── statusline/                    # Status bar rendering + sl-* CLI
├── dream/                         # Self-feedback / dream-mode insights
├── session-mgmt/                  # Session lifecycle, heartbeats, turn state
├── rotation/                      # WAL/event/backup rotation
├── dev-servers/                   # pm2 + nginx helpers
├── wal/                           # WAL writers + converters
└── diy-mem/                       # Shell-history tracking (pre-existing subdir)
```

---

## Top level — core hooks & workflow utilities

Scripts that stay at the top level have high reference counts and/or are registered as hooks in `settings.json`. Moving them would require updating many references.

| Script | Purpose |
|--------|---------|
| `safe-delete.sh` | PreToolUse hook — blocks `rm`, suggests `trash` |
| `block-nested-claude.sh` | PreToolUse hook — blocks `~/.claude/.claude/` paths |
| `emit-event.sh` | Writes events to `events.jsonl` on hook firings |
| `hint-injector.sh` | UserPromptSubmit — runs `~/.claude/hinters/*` chain |
| `notify.sh` / `notification-context.sh` / `permission-notify.sh` | macOS notification helpers |
| `desktop.sh` | macOS GUI automation (screenshot/click/type/windows) |
| `annotate-screenshot.py` | Grid-overlay on screenshots for coordinate reading |
| `propose.sh` | Cross-session improvement backlog CLI |
| `weekly-todo.sh` | Weekly todos CLI |
| `validate-triggers.sh` / `.py` | Frontmatter validator for rules/features/conventions |
| `validate-memory.sh` | Validates memory files, flags stale refs |
| `health-check.sh` | `/doctor` backend — env audit |
| `find-events-log.sh` | Resolves path to global `events.jsonl` |
| `claude-resilient.sh` | Retry wrapper for the `claude` CLI |
| `auto-format.sh` | PostToolUse Edit/Write — runs Prettier |
| `diff-preview.sh` | PostToolUse — inline diff display |
| `edit-tracker.sh` / `file-changed.sh` | PostToolUse — change tracking |
| `tool-counter.sh` / `check-human-comments.sh` / `exit-code-hook.sh` | PostToolUse hooks |
| `cost-alert.sh` | Stop — cost velocity alerts |
| `pending-proposals.sh` | Reminder for open proposals |
| `process-stats-daemon.sh` | Background — Claude CPU/MEM stats for statusline |
| `update-tab-title.sh` | Stop — tab title from session state |
| `test-hooks.sh` / `test-status-hook.sh` | Test harnesses |

---

## Clusters

### `llm-mini/` — Fast mini-model

Single-source mini-model dispatcher + surfaces. Core: `llm-mini-core.sh` (backend), `llm-mini.sh` (CLI), `llm-mini-engine.sh` (Ollama lifecycle), `llm-mini-chat.sh` (REPL), `llm-mini-hook.sh` (sourceable), `llm-mini-mcp-server.js` (MCP surface). `mini.sh` is a deprecation shim → `llm-mini` (will be removed with the 2-week symlink sweep).

Docs: `~/.claude/features/llm-mini.md`

### `statusline/` — Status bar

`statusline.sh` is the renderer entry point. `sl-*.sh` are the CLI/config/audit/explain/open/playground tools. `session-banner.py` renders the session-start banner. `statusline-backup.sh` rotates backups.

Docs: `~/.claude/features/shared-library.md` (gum usage) · `assets/docs/statusline-dev-guide.md` (full dev guide)

### `dream/` — Self-feedback / dream mode

Dream-mode insights and metrics: `dream-insights.sh`, `dream-metrics.sh`, `dream-metrics-context.sh`, `inject-dream-insights.sh`, `propose-config-from-insights.sh`.

Related: `features/proposals.md` (self-feedback → canon promotion workflow — still being wired)

### `session-mgmt/` — Session lifecycle

Turn-state: `turn-start.sh`, `turn-counter.sh`, `turn-end-cleanup.sh`. Session boundaries: `heartbeat.sh`, `detect-stale-session.sh`, `pre-compact-checkpoint.sh`, `post-compact-recovery.sh`, `session-summary.sh`, `subagent-tracker.sh`.

Docs: `~/.claude/features/context-retention.md` · `~/.claude/features/wal.md`

### `rotation/` — Log & backup rotation

`rotate-events.sh`, `rotate-wal.sh`, `prune-backups.sh`, `cleanup.sh`. Registered as Stop hooks and/or invoked via `/doctor`.

### `dev-servers/` — pm2 + nginx

`pm2-register.sh` (auto-assign 30xx/50xx ports), `pm2-resurrect.sh` (startup recovery), `gen-nginx-conf.sh` (generate `.test` domain configs).

Docs: `~/.claude/features/dev-servers.md` · `~/.claude/dev-servers-guide.md`

### `wal/` — Write-ahead log

`wal.sh` (canonical JSONL writer — always use this, never hand-compose), `wal-convert.sh` (legacy `.md` → `.jsonl`), `bash-wal.sh` (Pre/PostToolUse hook that writes `bash_intent`/`bash_closed` events).

Docs: `~/.claude/features/wal.md` · canonical spec `~/.claude/skills/shared/wal-format.md`

### `diy-mem/` — Shell history

Pre-existing subdir (not part of the 2026-04-24 restructure). Tracks shell commands via hooks, surfaces via `shell-mem` CLI.

Docs: `~/.claude/features/shell-memory.md`

---

## Adding a new script

1. Pick a home:
   - Part of an existing cluster → put it in the cluster subdir
   - Core hook / high-reference workflow utility → top level
   - One-off analysis / reference code → `~/.claude/code/ideas/` (not here)
2. If it's executable, `chmod +x` and consider a symlink under `~/.local/bin/` for CLI convenience
3. Add to `~/.claude/LOOKUP.md` § Hook Scripts (or the appropriate section)
4. If it's a hook, register in `~/.claude/settings.json`
5. If another script calls it, use absolute path `~/.claude/scripts/<cluster>/<name>` — never relative

---

## Back-compat symlinks (temporary)

For every file moved in the 2026-04-24 cleanup, there's a symlink at the old top-level path pointing into the cluster subdir. These exist purely to keep in-flight sessions working; new code should use canonical paths.

Planned removal: ~2026-05-08 (14 days after migration). Tracked via `~/.claude/proposals.jsonl`.
