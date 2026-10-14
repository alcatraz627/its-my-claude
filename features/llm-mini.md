---
brief: Fast sub-second model: CLI, chat REPL, MCP, hook callable; Ollama local + Haiku fallback; engine management
triggers:
  - tool:llm-mini
  - skill:mini
  - topic:fast-lookups
  - mcp:llm-mini
related: []
tier: 2
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Llm Mini
A fast, sub-second mini-model for quick tasks: session titles, doc lookups, command composition and short summaries. It runs Ollama (llama3.2) with automatic fallback to cloud Haiku, and cold-starts serverless.

## Surfaces (all delegate to `scripts/llm-mini/llm-mini-core.sh`)

| Surface       | Usage |
|---------------|-------|
| CLI           | `llm-mini "question"` or `echo text \| llm-mini summarize` |
| Chat          | `llm-mini chat`, an interactive REPL with context retention |
| MCP           | `mcp__llm-mini__ask` (registered globally in `.mcp.json`) |
| Hook callable | `source ~/.claude/scripts/llm-mini/llm-mini-hook.sh; mini_quick "question"` |

## Templates (`~/.claude/assets/mini-prompts/`)

`session-title`, `doc-lookup`, `cmd-compose`, `summarize`. Use `llm-mini --list` to see all.

## Backends

- `--local` (Ollama, <500ms warm)
- `--quality` (Haiku API, ~1-2s)
- Auto (the default): local first, cloud fallback

The cloud method is configurable: `cli` (subscription via `claude -p`, cheaper), `api` (direct Anthropic API, faster) or `auto` (API first, CLI fallback). Set it via `cloud_method` in `~/.claude/llm-mini.conf`.

## Chat mode

`llm-mini chat [--local|--quality|--tools]` starts a multi-turn REPL. `--tools` enables tool use (shell, read_file, list_dir) via the cloud API. Commands: `/help`, `/clear`, `/exit`, `/tools`, `/model`, `/backend`, `/history`.

## Engine management

`llm-mini engine start [model]`, `engine stop`, `engine status`, `engine switch <model>`, `engine stats`, `engine models`, `engine pull <model>`, `engine rm <model>`. State: `~/.claude/llm-mini-state/`.

## When to use vs full Claude

**Use llm-mini for** short labels, one-line definitions and single shell command composition, where speed matters more than depth.

**Do NOT use llm-mini for** reasoning, code generation or multi-step analysis.

**Source:** github.com/alcatraz627/llm-mini
