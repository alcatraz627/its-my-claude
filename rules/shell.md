---
brief: Resolve project root before Glob/Grep; trash not rm; non-interactive flags; background task hygiene
triggers:
  - topic:shell
  - topic:file-deletion
  - tool:rm
  - tool:trash
related: [features/shared-library.md]
tier: 1
category: rules
updated: 2026-04-24
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

## Compound commands and permissions

Long multi-command chains (e.g., `echo ... && ls ... && find ... && wc ...`) can trigger permission prompts even when each individual command is allowed. Prefer multiple separate calls over one mega-compound when any component might be unfamiliar.

## Sentinel values

macOS `bash` is 3.2 — no associative arrays. Any script needing `declare -A` or bash-4 features must shebang `/opt/homebrew/bin/bash` if available, or delegate to Python.

## macOS shell gotchas (silent-failure class)

Two macOS-specific traps that fail *silently* — the code looks right, runs without error, and quietly does nothing. Both bit a hook this session and only surfaced under test:

- **`find /tmp …` descends nothing.** `/tmp` is a symlink to `/private/tmp`, and BSD `find` does not follow a symlink **start point** without a trailing slash. `find /tmp -name x` → 0 matches; `find /tmp/ -name x` (or `find /private/tmp …`, or `find -L /tmp …`) works. Any `find` rooted at a symlinked dir needs the trailing slash.
- **There is no `timeout`/`gtimeout` by default**, and the obvious fallback `perl -e 'alarm N; exec @ARGV' cmd` **does not actually time out** — `alarm` kills the shell but its child (e.g. a `sleep`/hung subprocess) is orphaned and keeps the output pipe open, so a `$(…)` capture blocks the full duration anyway. A real cap must kill the whole **process group**: `perl -e 'my $p=fork; if($p==0){setpgrp(0,0); exec(@ARGV)} local $SIG{ALRM}=sub{kill "KILL",-$p}; alarm N; waitpid($p,0)' cmd` (verified: dies at the cap, no orphan). Prefer `timeout`/`gtimeout` when present.

## Prefer dedicated tools over shell reimplementations

Shell-log scans show repeated hand-built patterns when a better tool exists:

| Shell pattern | Prefer |
|---------------|--------|
| `find ... -name "*.X" \| head -N` | **Glob** (agent) · **`fd`** (in shell) — gitignore-aware, parallel, dodges the macOS `find /tmp` symlink trap |
| `grep -r "X" ... --include="*.Y"` | **rg** — 18–65× faster; see section below |
| `cat file 2>/dev/null \| head` | **Read** — reads only what's needed, cleaner errors |
| `grep`/`sed`/`awk` on `.yaml`/`.toml`/`.xml` | **File Tools MCP** (`read_structured`) for programmatic R/W · **`yq`** for shell pipelines / in-place edits |

Use Bash for shell-only operations (process control, pipes, environment). Don't use it as a filesystem browser.

### `fd` over `find` (in shell contexts)

In a Bash script or pipeline, prefer **`fd`** to `find` for locating files: it
respects `.gitignore`, runs in parallel, has saner syntax, and — critically on
this machine — sidesteps the BSD `find <symlinked-dir>` no-descent trap above
(`find /tmp …` silently matches nothing). The agent's primary file-find is still
the **Glob tool**; `fd` is for when you're already in a shell.

This is a **preference, not a hard block** (unlike grep→rg): `find -delete`,
`-exec`, `-newer`, `-mtime` have no clean `fd` equivalent, so `find` stays
legitimate for its action/predicate flags. Reach for `fd` for "locate files by
name/type"; keep `find` when you need what only `find` can do.

### `yq` for structured config — under the File Tools MCP mandate

**`yq`** reads/edits YAML · TOML · XML · properties from the shell
(`yq '.a.b' f.yaml`, `yq -p toml '.x'`, in-place `yq -i '.x = 1' f.yaml`). It does
**not** override the standing **File Tools MCP** mandate: for programmatic
read/write of a data file, the MCP (`read_structured` / `write_structured`) is
still preferred. Use `yq` when already inside a Bash pipeline (transforming
command output, a quick `.field` extraction, an in-place edit a script must do)
where invoking the MCP would be awkward. Order of preference for structured data:
**File Tools MCP → `yq` (shell) → never hand-rolled `grep`/`sed`**.

## ripgrep over grep (MANDATORY)

A hook (`scripts/prefer-ripgrep.sh`) blocks every direct `grep` / `/usr/bin/grep` Bash call. Benchmarked on this machine's 2.8 GB `~/.claude` corpus: **rg is 18–65× faster** across all pattern types. Always use `rg` instead.

### Standard rg equivalents

```bash
# Recursive file search (replaces grep -r)
rg --no-ignore --hidden "PATTERN" /path/

# Case-insensitive (replaces grep -ri)
rg --no-ignore --hidden -i "PATTERN" /path/

# List matching files only (replaces grep -rl)
rg --no-ignore --hidden -l "PATTERN" /path/

# File-type scoped — MUCH faster than find|xargs grep
rg --no-ignore --hidden -g "*.jsonl" "PATTERN" /path/

# Pipe filter (replaces cmd | grep pattern)
cmd | rg "PATTERN"

# Count matches per file (replaces grep -rc)
rg --no-ignore --hidden -c "PATTERN" /path/
```

**Flag note:** `--no-ignore --hidden` makes rg match grep's full scope (including dotfiles and gitignored paths). Default `rg` is even faster but may miss hidden/ignored files.

### Scripts and generated code

When writing shell scripts or generating code that performs text search, use `rg` over `grep`. If a script must be portable to machines without rg, add a guard:

```bash
RG=$(command -v rg 2>/dev/null) || { echo "Install ripgrep: brew install ripgrep"; exit 1; }
$RG --no-ignore --hidden "PATTERN" /path/
```

### When grep MUST be used — confirm with user first

Before falling back to `/usr/bin/grep`, try:
1. Check if rg is available: `command -v rg`
2. If missing, install: `brew install ripgrep` (then use rg)
3. Only after both fail, OR for the specific cases below, ask the user for approval:

| Situation | Why grep may be needed |
|-----------|----------------------|
| No network / restricted env, brew unavailable | rg can't be installed |
| Strict POSIX BRE syntax (`-P` Perl features) | Rust regex differs on edge cases (lookbehinds, some Unicode) |
| Binary byte-offset scanning (`grep -a -b`) | rg's binary handling differs |
| `git grep` | Searches git index — rg cannot replace this; allowed through the hook |

**Never silently fall back to grep.** State the reason and get user acknowledgement first.

## Prefer existing scripts over one-off code

Before writing a shell one-liner for a recurring operation, check `~/.claude/scripts/` (see [`scripts/README.md`](../scripts/README.md) when present, or `LOOKUP.md §Hook Scripts`). Most common ops already have a script:

- WAL writes → `scripts/wal/wal.sh`
- Propose improvement → `scripts/propose.sh`
- Weekly todo → `scripts/weekly-todo.sh`
- macOS GUI → `scripts/desktop.sh`
- Fast model → `scripts/llm-mini/llm-mini.sh`
- Frontmatter validator → `scripts/validate-triggers.sh`

If no script fits and the work is multi-step, write a temp script under `/tmp/` (`.sh` / `.py` / `.js`) with error handling and basic logging — so a failure produces something diagnosable, not a silent half-done state.

**Promotion rule:** if a temp script proves useful in 2+ sessions, ask the user whether to promote it to `~/.claude/scripts/` (global) or to the project's local `.claude/scripts/` (project-specific). Don't promote unilaterally.

## Anti-pattern — `~/.claude/.claude/` paths

When CWD is `~/.claude` itself, relative paths like `.claude/output/X` resolve to `~/.claude/.claude/X` — a broken double-nest. A hook (`scripts/block-nested-claude.sh`) blocks tool calls containing `/.claude/.claude/`. Full redirect table: [`conventions/asset-management.md`](../conventions/asset-management.md).
