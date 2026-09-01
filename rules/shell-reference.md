---
brief: The shell reference catalog — macOS silent-failure gotchas (zsh path trap, find /tmp, timeout), the dedicated-tools table (fd/yq/File-Tools), rg equivalents + the legitimate-grep cases, and the prefer-existing-scripts law. The catalog half of rules/shell.md, split out 2026-09-01 (prime-demotion-0901 D2a).
triggers:
  - topic:shell
  - topic:bash
  - topic:zsh
  - tool:rg
  - tool:fd
  - tool:yq
related:
  - rules/shell.md
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "**/*.zsh"
tier: 1
category: rules
updated: 2026-09-01
stale_after_days: 180
---

# Shell reference — the catalog half

The law half (trash not rm, search scope, non-interactive flags, background
discipline, the rg mandate) lives in [`rules/shell.md`](shell.md).

## macOS shell gotchas (silent-failure class)

Traps that fail *silently* on this machine. The code looks right, runs without error, and quietly does nothing. Each one surfaced only under test:

- **`path` is a booby-trapped loop-variable name, because inline commands run zsh.** zsh binds the scalar `$PATH` to an array named `$path`, so `while read path; do …; done` and `for path in …` overwrite your PATH with a filename. Every later command in that same call then dies with `(eval):3: command not found: sed`, which reads like a broken machine rather than a naming collision. The blast radius is the single Bash call, so the next call looks healthy and the bug seems intermittent. Name the variable `p`, `f`, `file`, or `target` instead. Measured on zsh 5.9 (2026-08-11): `path` is the only common name that fails *silently*. `status`, `history`, `modules`, `jobstates`, `parameters`, `functions`, `commands`, `aliases` and `options` are reserved too, but they fail loudly with a read-only or associative-array error, so they announce themselves. Ordinary names (`file`, `dir`, `line`, `item`, `key`, `val`, `out`, `cmd`, `src`, `target`) are all safe. Scale, re-derived across the full corpus on 2026-08-13: **two** organic incidents in two months, a `find | while read ts path` loop on 2026-06-19 and a `local path=` function on 2026-07-07. An earlier version of this line said "roughly 175 hits", which counted matching strings rather than incidents and overstated the real figure about 90-fold; that count also self-inflates, because the guard's own message quotes the error string being counted. Rare but silent, which is why `scripts/hooks/guard-zsh-path-var.sh` warns rather than blocks.
- **`find /tmp …` descends nothing.** `/tmp` is a symlink to `/private/tmp`, and BSD `find` does not follow a symlink **start point** without a trailing slash. `find /tmp -name x` → 0 matches; `find /tmp/ -name x` (or `find /private/tmp …`, or `find -L /tmp …`) works. Any `find` rooted at a symlinked dir needs the trailing slash.
- **`timeout` is installed here, so use it instead of hand-rolling a cap.** macOS ships none of its own, which is why this note used to say there was none. GNU coreutils provides `/opt/homebrew/bin/timeout`, with `gtimeout` as a byte-identical second name. It returns 124 on expiry, passes the command's own exit code through otherwise, escalates TERM to KILL with `-k` (`timeout -k 5 30 cmd`), and signals the whole **process group**, so a backgrounded grandchild cannot hold a `$(…)` capture open after the cap fires. All six behaviours verified 2026-08-11. Restore it with `brew install coreutils`; it is tracked in the zcmd manifest. Without coreutils, the obvious fallback `perl -e 'alarm N; exec @ARGV' cmd` **does not actually time out**: `alarm` kills the shell, but its child (a `sleep`, a hung subprocess) is orphaned and keeps the output pipe open, so a `$(…)` capture blocks the full duration anyway. A real hand-rolled cap must kill the whole process group: `perl -e 'my $p=fork; if($p==0){setpgrp(0,0); exec(@ARGV)} local $SIG{ALRM}=sub{kill "KILL",-$p}; alarm N; waitpid($p,0)' cmd` (verified: dies at the cap, no orphan).

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

