---
brief: Inline commands run zsh (never name a var `path`); trash not rm; no Glob from ~/; non-interactive flags
triggers:
  - topic:shell
  - topic:zsh
  - topic:file-deletion
  - tool:rm
  - tool:trash
  - tool:timeout
related: [features/shared-library.md]
tier: 1
category: rules
updated: 2026-11-04
stale_after_days: 90
---
# Shell discipline

- **One command per Bash call. No `&&`, `;` or `|`.** Every segment of a compound must match an allow entry, so one unlisted segment prompts the owner about the whole chain. Ask the tool for less output (`rg -m 5`, `sed -n '1,40p'`, `git log -5`); redirect to a file and read it next call. No `VAR=x cmd`, no inline functions; multi-line python goes in a file. Settings are read at session start; a list fix lands only after a restart.
- Every sub-agent dispatch prompt carries the one-command clause.
- **API tokens are not in agent shells.** Linear, Render, Slack and GitHub tokens live in the Keychain; your shell strips them. When a command needs one, run `with-token LINEAR_API_KEY -- <command>`. It needs no approval. A token not stored: find or mint it, never voice credential worries. Never print a token. Detail: `features/api-tokens.md`.
- **Never dump the environment** (`env`, `printenv`, `set` bare): live API tokens are exported on purpose, and a dump copies them into the transcript. Read one var: `printenv NAME`.
- **`trash`, never `rm`.** `safe-delete.sh` blocks `rm` in every form it can parse; it cannot see `rmdir`, a variable or alias (`$RM`), or a runtime call (`os.remove`).
- Never Glob/Grep from `~/`; resolve to a project root first.
- Non-interactive flags always (`-y`, `-f`).
- No `run_in_background` unless asked.
- Inline commands run zsh 5.9: never name a variable `path`. Scripts with `#!/bin/bash` get bash 3.2, no associative arrays.
- `rg` over `grep` (hook nudges); never silently fall back.
- When CWD is `~/.claude`, a relative `.claude/…` write lands in `~/.claude/.claude/` (blocked); use the redirect table in `conventions/asset-management.md`.
- Catalog of gotchas and tool preferences: `rules/shell-reference.md`.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/shell.md`
