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
updated: 2026-09-01
stale_after_days: 90
---

# Shell
Shell, search, and delete discipline.

## File search scope

**Never Glob/Grep from `~/` — always resolve to a project root first.** Searches from the home directory will traverse massive trees and return irrelevant results.

## Safe delete — `trash` not `rm`

A `PreToolUse` hook (`~/.claude/scripts/safe-delete.sh`) blocks every `rm` invocation. Use `trash <path>` instead (macOS built-in → Finder Trash, recoverable). Full reference: `~/.claude/skills/shared/safe-delete.md`.

If you hit the block, it means you tried `rm`. Do not try to work around it (no `\rm`, no `/bin/rm`). The block is intentional.

## Non-interactive flags are mandatory

`npm install -y`, `cp -f`, `mv -f`, `apt-get install -y`. Any command that might prompt must be flagged non-interactive, or it will hang.

## Background tasks

Don't use `run_in_background: true` unless the user explicitly asks. Background processes orphan on `/clear` and survive across sessions, polluting the next session's state.

## One command per Bash call. No chaining. (MANDATORY)

Never join commands with `&&`, `;` or a pipe to save a round trip. One command
per Bash call, always. The round trip is free; the prompt costs the owner a
click and his attention, and he gets one for every chain.

**The mechanism, and an earlier version of this file got it wrong.** Every
segment of a compound must match an allow entry. One unlisted segment prompts
the human about the entire chain, which is why `cd` being absent from the list
poisoned every command that began with it, and why a chain is far likelier to
prompt than the same commands sent one at a time.

This file previously said the tiers were not involved and that adding entries
did nothing. That was wrong, and wrong in the costly direction: an agent reading
it would conclude the list cannot help and stop looking. What actually happened
on 2026-09-03 is that this account's `defaultMode` was `auto`, where the tiers
decide, and three passes of list-widening did land, but the sessions running at
the time had read their settings before the edits. 149 prompts that day against
1 to 6 a day before, 93 percent carrying a chaining operator, 84 of the 149
never running at all.

**Settings are read at session start.** A fix landed mid-session cannot take
effect in the session that is running. Before concluding a list is wrong, check
whether the session predates the change; the answer is often a restart rather
than an edit, and only the owner does the restart.

Two further traps worth knowing. The activating launch flag is
`--dangerously-skip-permissions`; `--allow-dangerously-skip-permissions` only
permits the mode and activates nothing, and passing the `allow-` form twice does
nothing at all. And in `bypassPermissions` the tiers genuinely are not
consulted, so the same prompt in two sessions can have two different causes.

So the rule is behavioural and there is no settings fix for it:

- **No `|`.** Do not pipe into `head`, `tail`, `grep` or `wc`. Ask the tool for
  less output instead: `rg -m 5`, `sed -n '1,40p'`, `pytest -q`, `git log -5`.
  If you genuinely need to filter, write the output to a file in one call and
  read the file in the next.
- **No `&&` or `;`.** Issue the commands separately. The Bash tool's working
  directory persists between calls, so a bare `cd` once is enough and
  `cd X && cmd` is never needed.
- **No `VAR=value cmd` chains and no inline shell functions.** A bare
  assignment or a `t() { ... }` is its own unmatched segment. Write the value
  out, or put the script in a file.
- **Multi-line `python3 -c "..."` with embedded quotes: write a file instead.**
  Use the Write tool, then `python3 /abs/path.py` as one segment. This also
  stops text-scanning hooks firing on a command quoted inside the payload.

**Every sub-agent dispatch prompt carries this**, in the same slot as the four
clauses of `rules/subagent-dispatch-prompt.md`. A dispatched agent that chains
three reads generates a prompt the owner answers for work he never saw
dispatched, which is the worst version of this.

**Diagnostic:** you are about to type `&&`, `;` or `|` in a Bash command. Don't.

## Sentinel values

**Two different shells run your code, and they differ in what they support.** A Bash-tool command runs under **zsh 5.9** on this account, where `declare -A` works fine. A script you *write* with `#!/bin/bash` runs **bash 3.2**, which has no associative arrays. The 3.2 limit therefore binds scripts, not inline commands: a script needing `declare -A` or other bash-4 features must shebang `/opt/homebrew/bin/bash` if available, or delegate to Python. Confirm which you are in with `${ZSH_VERSION:-}` / `${BASH_VERSION:-}` rather than assuming.

## ripgrep over grep (MANDATORY)

A hook (`scripts/prefer-ripgrep.sh`) NUDGES on a direct `grep` Bash call; rg is
18-65x faster on this machine. Use `rg --no-ignore --hidden` for grep-equivalent
scope. **Never silently fall back to grep** — install rg or get the user's
acknowledgement first; `git grep` is allowed through the hook. Full equivalents
table, the legitimate-grep cases, and script guards: `rules/shell-reference.md`.

## The reference catalog — moved

macOS silent-failure gotchas (the zsh `path` trap, `find /tmp` no-descent,
`timeout`), the dedicated-tools table (fd/yq/File-Tools), rg equivalents, and
the prefer-existing-scripts law live in `rules/shell-reference.md`, which
autoloads when you touch shell files. Split per prime-demotion-0901 D2a,
2026-09-01.

## Anti-pattern — a relative `.claude/…` write while CWD is `~/.claude`

When CWD is `~/.claude` itself, relative paths like `.claude/output/X` resolve to `~/.claude/.claude/X` — a broken double-nest. A hook (`scripts/block-nested-claude.sh`) blocks the **write**, judging it against CWD rather than by matching command text, so reading, grepping, or testing that path is not blocked. The directory itself is legitimate: it is this project's own project-scoped `.claude/`, holding `settings.local.json` and `worktrees/`. The accident is the relative resolution, never the path. Full redirect table: [`conventions/asset-management.md`](../conventions/asset-management.md).
