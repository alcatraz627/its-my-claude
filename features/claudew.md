---
brief: Plugin-based claude CLI wrapper; lifecycle phases; seed plugins; HINT protocol; config.toml
triggers:
  - tool:claudew
  - topic:auto-resume
  - topic:rate-limit-recovery
  - phrase:"rate limit"
related: []
tier: 2
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Claudew
`claudew` wraps the `claude` CLI with a plugin-based lifecycle system. It is a drop-in replacement: `claudew "Fix the login bug"`. Repo: `~/.claude/claudew/`, symlinked at `~/.local/bin/claudew`.

## Lifecycle phases

`pre_spawn` → spawn claude → `post_spawn` → `poll` (30s) → `on_exit` → `on_recover` (if recoverable) → loop back.

## Seed plugins (6)

| Plugin | Hooks | Default | Purpose |
|--------|-------|---------|---------|
| `00-auto-resume` | on_exit, on_recover | enabled | Detect rate limit/API error, poll for recovery, resume |
| `10-session-rehydrate` | pre_spawn | disabled | Inject last WAL checkpoint as context |
| `20-pre-turn-wal` | post_spawn, on_exit | disabled | Write session boundary WAL entries |
| `30-budget-guard` | pre_spawn, poll | disabled | Warn at 80%/95% rate limit thresholds |
| `40-recent-dir-context` | pre_spawn | disabled | Inject `git log --since=1h` from CWD |
| `50-post-turn-diff` | on_exit | disabled | Run `git diff --stat`, write to WAL |

## CLI

`claudew list`, `claudew enable <name>`, `claudew disable <name>`, `claudew new-plugin <name>`.

## HINT protocol

Plugins emit `HINT:` lines on stdout. The host collects them and injects them into the next turn's `additionalContext`. All other stdout is discarded.

## Config

`~/.claude/claudew/config.toml` holds host settings, the enabled plugin list and per-plugin overrides. Use single-line TOML arrays only, because the minimal parser does not support multiline.

## Plugin development

See `~/.claude/claudew/PLUGIN-CONTRACT.md`. Scaffold with `claudew new-plugin 60-my-plugin`.

## State

Per-plugin state lives in `~/.claude/claudew/state/<name>/`. The host event log is `~/.claude/claudew/events.jsonl`.
