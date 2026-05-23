# `~/.claude/hinters/` — UserPromptSubmit hint scripts

> Hinters are small scripts that inspect each user prompt and optionally inject a one-time hint into Claude's context. They're the "see something, say something" layer.

## Lifecycle

Each script:
1. Reads the prompt from stdin
2. Decides whether to fire (regex match, file-existence, recency check)
3. Emits hint text to stdout (or exits silently)

Hooked in via `settings.json` under `hooks.UserPromptSubmit`. Latency budget: **<100 ms per hinter** — they run in series before each prompt.

## File naming

`NN-<slug>.sh` where `NN` is a 2-digit priority (00–99, lower fires first). Disabled hinters use `_disabled-NN-<slug>.sh.<reason>`.

## When to add a hinter

- A specific prompt pattern reliably indicates a behavior worth surfacing context for
- A subsystem (atone, scratchpad, asset.sh) has TLDR content that helps when triggered

## When NOT to add a hinter

- Always-loaded context → `CLAUDE.md` directly (per `PLACEMENT.md` Tier 0/1)
- Tool-specific gating → PreToolUse hook in `settings.json` instead
- A heavy classifier (>100 ms) — delegate to `mini` or move offline

## Mute mechanism

Hinters should support a touch-file mute (e.g., `~/.claude/atone/.nudge-off`). Document the mute path in the hinter's header.

## See also

- `features/hinter-pipeline.md`
- `rules/corrections.md` — when an atone hinter should fire
