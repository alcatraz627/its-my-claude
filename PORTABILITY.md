# ~/.claude portability

This repo versions the **config/code layer** of the Claude setup so it ports
cleanly to a new machine. It is deliberately NOT a full backup — big data and
runtime state move separately (rsync), and large sub-projects are their own
repos. Goal: "blue-moon" convenience, not server-grade reproducibility.

## What this repo tracks
Code + config only: `scripts/`, `skills/`, `hinters/`, `rules/`, `conventions/`,
`features/`, `personas/`, `migrations/`, `hooks-feedback-domain/` (code), the
root indices (`CLAUDE.md`, `LOOKUP/NAMESPACE/GLOSSARY/PLACEMENT/FOLDERS.md`, …),
`settings.json`, `mcp-catalog.json`. ~80 MB. See `.gitignore` (allowlist model).

## What this repo does NOT track (and how it moves instead)
| Not tracked | Why | How it moves |
|---|---|---|
| `projects/` `assets/` `subconscious/` `i-dream/` `widgets/` `plugins/` | large data / dream state / transcripts | rsync — `mac-migration/MANIFEST.md` §6 |
| `memory*/` `sessions*/` `topics/` `pinned/` `plans/` `output/` `telemetry/` | accumulated runtime data | rsync (MANIFEST §6) |
| `.turn-state/` `file-history/` `paste-cache/` `shell-snapshots/` `*/locks/` `wal.*` | transient / regenerated | skip (MANIFEST §6) |
| `atone/` `affirm/` `claudew/` `atone-snapshots/` | own their own `.git` | independent repos |
| secrets (`.env` `*.pem` `*.key` `~/.zenv` `~/.claude.json`) | sensitive | MANUAL secure copy + rotate (MANIFEST §8) |

## Standalone sub-projects → separate repos, registered as dependencies
Central to the workflow but large enough to stand alone. Cloned/installed
separately on a new machine; this repo only depends on their presence.

| Project | Path | State | Re-provision |
|---|---|---|---|
| i-dream (subconscious engine) | `~/Code/Claude/i-dream` | own git repo (has remote) | `mac-migration/kit/clone-all.sh` + `cargo install` the `i-dream` binary |
| claude-instances (widget) | `~/.claude/widgets/claude-instances` | **TODO: not yet its own repo** | needs `git init` + remote, then register here |
| file-tools MCP | `~/Code/Claude/mcp-file-tools` | local-only repo (unpushed) | push first, then clone (MANIFEST §5) |
| interactive-inputs MCP | `~/Code/Claude/mcp-interactive-inputs` | local-only repo (unpushed) | push first, then clone (MANIFEST §5) |
| **atone** (mistake-learning log) | `~/.claude/atone` | own repo → `github.com/alcatraz627/claude-atone` (private) | `git clone` to `~/.claude/atone`; daemon pushes biweekly |
| **affirm** (affirmed-good-behavior log) | `~/.claude/affirm` | own repo → `github.com/alcatraz627/claude-affirm` (private) | `git clone` to `~/.claude/affirm`; daemon pushes biweekly |

> Note: `atone`/`affirm` keep their own repos (their CLIs commit append-only as they run); the `sync-all.sh` daemon pushes them. The rest of the learned state (dream insights, memory, intentions, valence, calibration) is folded into THIS repo (`its-my-claude`) — see `.gitignore`, which tracks curated `subconscious/` outputs but excludes the ~130M of raw churn (logs, metacog samples, dream traces, introspection chains).

## Runtime / system state (NOT in git — re-provision on new machine)
The migration kit (`~/mac-migration/kit/`) owns the heavy lifting; this is the
std::claude-specific checklist that pairs with it:
- **Symlinks** `~/.local/bin/{claudew,llm-mini,mini,fiber-snatcher,i-dream}` → `~/.claude/scripts/...` (MANIFEST §6 recreate step)
- **Daemons / LaunchAgents** (MANIFEST §6b, `kit/launchd-agents.txt`): i-dream daemon+menubar+audit/daily/dreampass, claude-instances menubars, claude-startup, atone-consolidate + atone-snapshot
- **Cron** (MANIFEST §6b): weekly-todo, asset cleanup, process-stats-daemon
- **External deps** the scripts assume: ripgrep, jq, gum, trash, duti, fzf, ollama (llm-mini local mode), pm2 — all in `kit/Brewfile` / `kit/npm-globals.txt`
- **System registrations**: duti file-handler associations (if used); `/etc/hosts` + nginx local-proxy (MANIFEST §13)

## On a new machine (order)
1. Clone this repo to `~/.claude` (or restore then `git init`-clean).
2. Run the migration kit (`mac-migration/`) for deps, data rsync, daemons, secrets.
3. Recreate `~/.local/bin` symlinks; `cargo install` i-dream; rebuild the 2 MCPs.
4. Clone the standalone sub-project repos to their paths.
