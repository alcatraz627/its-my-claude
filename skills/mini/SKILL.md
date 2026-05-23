---
name: mini
description: Fast mini-model query (<1s) using local Ollama or cloud Haiku — for quick lookups, titles, summaries, and command composition
invocation: /mini
arguments: "[--quality] [--local] [--template T] [--max-tokens N] [--context FILE] [--list] <prompt>"
---

# mini

Fast mini-model callable for sub-second queries. Uses local Ollama (llama3.2) by default
with automatic fallback to cloud Haiku. Designed for quick tasks that don't need full
Claude reasoning: session titles, doc lookups, command composition, short summaries.

## Usage

```
/mini what does jq -r do?
/mini --template session-title "Fix the auth bug in login flow"
/mini --quality "explain this error message"
/mini --list
echo "long text" | mini summarize
```

| Argument | Description |
|---|---|
| `<prompt>` | The question or text to process |
| `--template T` | Use a prompt template: `session-title`, `doc-lookup`, `cmd-compose`, `summarize` |
| `--quality` | Force cloud Haiku backend (slower but smarter) |
| `--local` | Force local Ollama backend (fastest, no network) |
| `--max-tokens N` | Cap output tokens (default: 200) |
| `--context FILE` | Attach file content as context (capped at 16KB) |
| `--list` | List available prompt templates |

## Step 0: Load Shared Guidelines

Read `~/.claude/skills/GUIDELINES.md`. Apply all rules for the duration of this skill run.

## Step 1: Parse and Route

Parse the user's arguments:

| Intent | Action |
|---|---|
| `--list` | List templates, then stop |
| Has `--template T` | Run with template |
| Plain text | Run as direct prompt |
| No args | Ask user for a prompt |

## Step 2: Execute

Run mini-core.sh with the parsed arguments:

```bash
bash ~/.claude/scripts/mini-core.sh [FLAGS] <prompt>
```

Capture both stdout (the result) and stderr (any errors). If the command fails:
- Local backend failed → suggest `--quality` to try cloud
- Cloud backend failed → check if ANTHROPIC_API_KEY is set
- All backends failed → report the error

## Step 3: Present Result

Print the mini-model's response directly. No reformatting — the output is already concise.

If the response is empty or an error, explain what went wrong and suggest alternatives.

## Step 4: Offer Follow-ups

For interactive use, offer:

```
Options: --quality (cloud Haiku), --template <name>, --list (show templates)
```

## Architecture

```
/mini slash command
  └── bash ~/.claude/scripts/mini-core.sh
        ├── Local: Ollama (llama3.2) — <1s warm
        └── Cloud: Anthropic API (Haiku) — ~1-2s
              └── Fallback: claude -p --model haiku — ~20s
```

All 6 surfaces (CLI, MCP, slash command, hook, Python, stdin pipe) share `mini-core.sh`
as the single backend dispatcher. Templates live in `~/.claude/assets/mini-prompts/`.

## Latency Profile

| Backend | Warm | Cold |
|---|---|---|
| Local (Ollama) | 200-500ms | 2-4s (model load) |
| Cloud (API key) | 1-2s | 1-2s |
| Cloud (CLI fallback) | 15-25s | 15-25s |

## Notes

- **MCP server**: Also available as MCP tool `mini.ask` — Claude can call it directly without the slash command
- **Hook callable**: `source ~/.claude/scripts/mini-hook.sh` provides `mini_quick()` for hooks
- **Python shim**: `from shared import mini` for Python scripts
- **Templates**: Stored in `~/.claude/assets/mini-prompts/*.prompt`. Use `{{input}}` placeholder.
