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
Fast sub-second mini-model for quick tasks: session titles, doc lookups, command composition, short summaries. Ollama (llama3.2) with automatic fallback to cloud Haiku. Cold-start serverless.

## Surfaces (all delegate to `scripts/llm-mini/llm-mini-core.sh`)

| Surface       | Usage |
|---------------|-------|
| CLI           | `llm-mini "question"` or `echo text \| llm-mini summarize` |
| Chat          | `llm-mini chat` — interactive REPL with context retention |
| MCP           | `mcp__llm-mini__ask` (registered globally in `.mcp.json`) |
| Hook callable | `source ~/.claude/scripts/llm-mini/llm-mini-hook.sh; mini_quick "question"` |

## Templates (`~/.claude/assets/mini-prompts/`)

`session-title`, `doc-lookup`, `cmd-compose`, `summarize`. Use `llm-mini --list` to see all.

## Backends

- `--local` (Ollama, <500ms warm)
- `--quality` (Haiku API, ~1-2s)
- Auto (default — local first, cloud fallback)

Cloud method configurable: `cli` (subscription via `claude -p`, cheaper), `api` (direct Anthropic API, faster), `auto` (API first, CLI fallback). Set via `cloud_method` in `~/.claude/llm-mini.conf`.

## Chat mode

`llm-mini chat [--local|--quality|--tools]`. Multi-turn REPL. `--tools` enables tool use (shell, read_file, list_dir) via cloud API. Commands: `/help`, `/clear`, `/exit`, `/tools`, `/model`, `/backend`, `/history`.

## Engine management

`llm-mini engine start [model]`, `engine stop`, `engine status`, `engine switch <model>`, `engine stats`, `engine models`, `engine pull <model>`, `engine rm <model>`. State: `~/.claude/llm-mini-state/`.

## When to use vs full Claude

**Use llm-mini for:** short labels, one-line definitions, single shell command composition — tasks that need speed over depth.

**Do NOT use llm-mini for:** reasoning, code generation, multi-step analysis.

**Source:** github.com/alcatraz627/llm-mini
