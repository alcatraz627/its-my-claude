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
updated: 2026-09-18
stale_after_days: 90
---
# Shell discipline

- **One command per Bash call. No `&&`, `;` or `|`.** Every segment of a compound must match an allow entry, so one unlisted segment prompts the owner about the whole chain and halts the session. Ask the tool for less output (`rg -m 5`, `sed -n '1,40p'`, `git log -5`); redirect to a file and read it next call. No `VAR=x cmd`, no inline functions; multi-line python goes in a file. Settings are read at session start; a list fix lands only after a restart.
- Every sub-agent dispatch prompt carries the one-command clause.
- **Never dump the environment** (`env`, `printenv`, `set` bare): live API tokens are exported on purpose, and a dump copies them into the transcript. Read one var: `printenv NAME`. Hook: guard-env-dump.sh.
- **`trash`, never `rm`.** `safe-delete.sh` blocks `rm`, `\rm`, `/bin/rm`, `command`/`env`/`sudo rm`, `xargs rm`, `find -exec rm`, `find -delete`, `unlink` and `bash -c "rm ..."`; it cannot see `rmdir`, a variable or alias (`$RM`), or a runtime call (`python3 -c "os.remove(...)"`).
- Never Glob/Grep from `~/`; resolve to a project root first.
- Non-interactive flags always (`-y`, `-f`).
- No `run_in_background` unless asked.
- Inline commands run zsh 5.9: never name a variable `path`. Scripts with `#!/bin/bash` get bash 3.2, no associative arrays.
- `rg` over `grep` (hook nudges); never silently fall back.
- When CWD is `~/.claude`, a relative `.claude/…` write lands in `~/.claude/.claude/` (blocked); use the redirect table in `conventions/asset-management.md`.
- Catalog of gotchas and tool preferences: `rules/shell-reference.md`.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/shell.md`
