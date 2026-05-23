# Shared Skill Guidelines

> **Mandatory for all skills.** Every skill must read this file as its **first step** and apply all rules for the entire run. These rules override any conflicting instructions in individual SKILL.md files.
>
> **Need a reference file?** See `~/.claude/LOOKUP.md` — the address book for all config, shared references, hooks, and scripts.

---

## 1. Forbidden Paths

Never read from, write to, modify, or delete files in these locations:

| Path Pattern                        | Reason                                                     |
| ----------------------------------- | ---------------------------------------------------------- |
| `node_modules/`                     | Third-party code — enormous and irrelevant                 |
| `.git/`                             | Version control internals                                  |
| `dist/`, `.next/`, `build/`, `out/` | Generated build artifacts                                  |
| `.env`, `.env.local`, `.env.*`      | Secrets and environment config                             |
| `*.pem`, `*.key`, `*.cert`          | Cryptographic material                                     |
| `coverage/`, `.turbo/`, `.cache/`   | Tool caches                                                |
**Rules:**

- Never pass `node_modules/` to any Glob, Grep, or Read — always exclude it
- **Never Glob or Grep from the home directory (`~/`)** — this causes timeouts on large filesystems. Always resolve to a specific project root first, then search within it.
- Never **write** outside the project root (directory containing `package.json` or equivalent project marker) unless the task explicitly requires it
- If a resolved path matches any row above, skip it silently and note it in your summary

---

## 2. Rules

### Safety

- **Never commit** changes without explicit user approval — do not run `git commit` or `git push`
- **Always confirm** before overwriting a file that already exists and was not created by this skill run
- **Never delete** files; if cleanup is needed, report what would be deleted and ask the user
- **No force operations** — do not use `--force`, `--no-verify`, or `rm -rf`
- **Safe delete** — never use `rm` to delete files. Use `trash <path>` (macOS built-in) which moves to Finder Trash. A PreToolUse hook blocks `rm` automatically. Full reference: `shared/safe-delete.md`
- **Asset management** — non-source output files (screenshots, reports, PDFs, exports) go in `~/.claude/assets/<type>/`. Prefer `asset.sh register` (handles naming + manifest); direct copy to the right subdirectory is also fine. Full reference: `shared/asset-management.md`

### Behavior

- Prefer read-only exploration before any write operation
- Before any Bash write/delete command, state what you are about to do and why
- Use absolute paths in all output so files are clickable in terminals and IDEs
- When uncertain about a destructive action, stop and ask

### Output

- At the end of every skill run, print a completion block:
  ```
  ─────────────────────────────────────────────────
    ✓ [Skill name] complete
  ─────────────────────────────────────────────────

    What was done:   [1-2 sentence summary]
    Files modified:  [absolute paths, one per line]
    Files created:   [absolute paths, one per line]
    Errors/skipped:  [any issues, or "none"]

    Runtime stats:
      Duration:      [wall-clock time from skill start to end]
      Tools used:    [count of Read/Write/Edit/Bash/Glob/Grep calls]
      Files touched: [total unique files read + written]
      Lines changed: [approx insertions + deletions]

  ─────────────────────────────────────────────────
  ```
- All file paths in output must be **absolute** — clickable in terminals and IDEs

### Task Completion Summary

When a **user-defined goal** is completed (not every small edit — only when the user's stated objective is fulfilled), print a similar completion block:

```
─────────────────────────────────────────────────
  ✓ Done: [goal description]
─────────────────────────────────────────────────

  What was done:   [1-3 sentence summary]
  Files modified:  [absolute paths, one per line]
  Files created:   [absolute paths, one per line]
  Errors/skipped:  [any issues, or "none"]

  Stats:
    Files touched: [total unique files read + written]
    Lines changed: [approx insertions + deletions]

─────────────────────────────────────────────────
```

**When to print:** After the final action that resolves what the user asked for — feature implemented, bug fixed, refactor complete, config updated. Do not print for intermediate steps, clarifying questions, or exploratory reads.

---

## 3. Retry Mechanism

When a tool call fails, follow this escalation:

```
Attempt 1 → fail → log the error → retry with same parameters
Attempt 2 → fail → log the error → try an alternative approach
Attempt 3 → fail → STOP. Report full error context to the user and ask how to proceed.
```

**Rules:**

- Never retry more than 3 times for the same logical operation
- Never silently swallow errors — always surface them with context
- If a Bash command fails with a non-zero exit code, treat it as a failure and escalate

---

## 4. Common Tools & Utilities

### Preferred Tool Order

Always use dedicated Claude tools over Bash equivalents:

| Task                   | Use     | Not                        |
| ---------------------- | ------- | -------------------------- |
| Read a file            | `Read`  | `Bash(cat)` / `Bash(head)` |
| Find files by pattern  | `Glob`  | `Bash(find)` / `Bash(ls)`  |
| Search file contents   | `Grep`  | `Bash(grep)` / `Bash(rg)`  |
| Write a new file       | `Write` | `Bash(echo >)`             |
| Patch an existing file | `Edit`  | `Bash(sed)` / `Bash(awk)`  |
| Terminal / system ops  | `Bash`  | —                          |

### Shared Helper Scripts

Small reusable scripts live in `~/.claude/skills/shared/`. Always use absolute paths when calling them via Bash:

| Script / Reference                     | Purpose                                            | Usage                        |
| -------------------------------------- | -------------------------------------------------- | ---------------------------- |
| `check-path.sh <path>`                 | Exits 1 if the path is forbidden; prints a warning | Before any write operation   |
| `log-run.sh <skill-name> <msg>`        | Appends a timestamped entry to `shared/run.log`    | At skill start and end       |
| `lock-file.sh <action> <path> [skill]` | Acquire/release/check a file lock                  | Before and after every write |
| `doc-naming.md`                        | Datestamp + session ID naming/tagging rules         | Before creating any new file |
| `safe-delete.md`                       | Use `trash` not `rm`; recovery procedures           | Before any file deletion     |
| `asset-management.md`                  | Asset registry via `asset.sh`                       | Creating non-source file output |
| `wal-format.md`                        | WAL session header and action log format            | When writing WAL entries     |

### std::claude::shared Imports

All reusable utilities live in `~/.claude/skills/shared/` (the **std::claude::shared** library). Skills must import from this package rather than copy-pasting utility code.

**Python** — canonical import pattern:
```python
import sys, os
sys.path.insert(0, os.path.expanduser("~/.claude/skills"))
from shared import Banner, Section, Item, tree, kv_line, truncate_path, THEMES
```

**Bash** — always use absolute paths:
```bash
bash ~/.claude/skills/shared/lock-file.sh <action> <path> [skill]
bash ~/.claude/skills/shared/prepend-runtime-note.sh <skill> <tmpfile>
bash ~/.claude/skills/shared/check-path.sh <filepath>
bash ~/.claude/skills/shared/log-run.sh <logfile> <message>
```

**Public exports** (Python `shared.__all__`):
`Banner`, `Section`, `Item`, `tree`, `kv_line`, `truncate_path`, `THEMES`, `__version__`

Full API reference: `~/.claude/skills/shared/README.md`

---

### Interactive UI with `gum`

Every skill **may** (and **should**, where it improves clarity) use `gum` to replace plain-text prompts with structured TUI components. `gum` is a single binary providing blocking interactive widgets for the terminal.

**Install (once):**

```bash
brew install gum
```

**Availability check** — add to any skill that uses gum to fail fast if not installed:

```bash
command -v gum >/dev/null 2>&1 || { echo "gum not installed — run: brew install gum" >&2; exit 1; }
```

**Core components:**

| Component          | Command                                    | Use when                              |
| ------------------ | ------------------------------------------ | ------------------------------------- |
| Single-select list | `gum choose <items...>`                    | User must pick exactly one option     |
| Multi-select list  | `gum choose --no-limit <items...>`         | User picks any number of options      |
| Fuzzy filter       | `<list> \| gum filter`                     | Long list where user wants to search  |
| Text input         | `gum input --placeholder "..."`            | Free-form single-line string          |
| Multiline text     | `gum write --placeholder "..."`            | Free-form multi-line string           |
| Confirm (yes/no)   | `gum confirm "Question?"`                  | Binary decision (exits 0=yes, 1=no)   |
| Spinner            | `gum spin --title "..." -- <cmd>`          | Long-running operation feedback       |
| Styled output      | `gum style --bold --foreground 212 "text"` | Highlighted terminal output           |
| Table display      | `printf "H1\tH2\n...\n" \| gum table`      | Structured data with column alignment |

**When to use gum vs. plain text prompts:**

- Use `gum choose` whenever presenting a fixed list of options — never make the user type one
- Use `gum confirm` for any yes/no gate — replaces `"(yes / no) →"`
- Use `gum filter` when the list has more than ~8 items
- Use `gum spin` for any operation expected to take >3 seconds
- Use plain text only for truly open-ended, unconstrained input

**Full guide:** See `.claude/skills/shared/gum-guide.md` for multi-turn interaction patterns, data visualization techniques, and copy-paste recipes.

#### Styled Output with `gum-tui.sh`

For **non-interactive output** (status messages, tables, panels, dashboards, completion blocks),
always prefer `gum-tui.sh` over raw `gum style` calls. It provides 22 composable functions
that are TTY-safe and zsh-compatible:

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_header "Skill Name"
gum_table "Col1,Col2" "val1,val2"
gum_success "Done"
gum_complete "skill-name" "Key=Value"
```

**When to use `gum-tui.sh` vs. raw gum:**

- **Use `gum-tui.sh`** for all styled output in Bash tool calls — headers, tables, status
  lines, panels, dashboards, progress counters, completion blocks
- **Use raw gum** only for interactive TTY components (`gum choose`, `gum confirm`, `gum input`)
  that must run in the user's terminal via `! gum ...`

Run `bash ~/.claude/skills/shared/gum-tui.sh list` for the full function reference,
or `bash ~/.claude/skills/shared/gum-tui.sh demo` for a visual showcase.

---

### File Lock Protocol

Every agent **must** use `lock-file.sh` to coordinate file access and prevent races when multiple subagents run in parallel.

**Rules:**

- **Before any `Edit` or `Write` operation:** acquire a lock. If `acquire` exits 1 (locked), do NOT proceed — print the owner info and wait or abort.
- **After every `Edit` or `Write` operation:** release the lock immediately, even if the edit failed.
- **Before any `Read` of a high-contention file** (`runtime-notes.md`, any SKILL.md being improved): run `check`. If locked for writing, print a notice but reads may still proceed.
- **Stale locks** (>5 minutes old) are auto-cleared by the script. If you see a `STALE_LOCK` message, the previous agent likely crashed without releasing — continue safely.
- **At skill startup**, run `bash ~/.claude/skills/shared/lock-file.sh cleanup` to sweep all stale locks left by crashed sessions. This is cheap (one `ls` + age check) and prevents stale locks from accumulating.
- Lock files live in `.claude/skills/shared/locks/` — never commit this directory.

**Pattern (wrap every file write):**

```bash
# Acquire
bash ~/.claude/skills/shared/lock-file.sh acquire "relative/path/to/file.md" "my-skill"
# → exits 1 and prints owner if locked; abort the write in that case

# ... perform Edit or Write ...

# Release (always, even on failure)
bash ~/.claude/skills/shared/lock-file.sh release "relative/path/to/file.md" "my-skill"
```

**High-contention files that always require a lock before writing:**

| File                                             | Reason                              |
| ------------------------------------------------ | ----------------------------------- |
| `.claude/skills/runtime-notes.md`                | Appended by every skill at run end  |
| `.claude/skills/shared/run.log`                  | Appended by `log-run.sh`            |
| Any `SKILL.md` being modified by `improve-skill` | Multiple skills targeted in one run |

---

## 5. Verbosity

Skills must narrate their work at every step. The agent must print:

- **Before each tool call:** what it is about to do and why (e.g., "Reading `src/app/api/auth/route.ts` to find session handling logic")
- **Every file scanned:** its relative path and what was found or not found
- **Intermediate results:** counts, matches, decisions (e.g., "Found 14 route files, filtering to 3 that mention `session`")
- **Each decision branch:** why a path was skipped, retried, or escalated

Do not compress or skip intermediate steps in the output. Full chain of thought is required.

### Task Title

The agent must derive a short task title from the user's initial input and update it after every subsequent user message if the scope or focus has shifted. Print the current task title as a bold header in these three moments:

1. **Before halting to ask the user for input** (any `AskUserQuestion` call or blocking prompt)
2. **After completing a major task or a collection of related tasks** (e.g., a phase finishes, a set of files is written, a pipeline step is done)
3. **At the very end of the skill run** (just before or as part of the closing summary)

Format:

```
**Task: [Derived title]**
```

The title must be ≤10 words, imperative or noun-phrase style (e.g., "Generate project index report", "Audit improve-skill SKILL.md"), and updated to reflect any scope changes introduced by user replies.

---

## 6. Timeouts

| Operation               | Limit     | Action if exceeded                    |
| ----------------------- | --------- | ------------------------------------- |
| Any single Bash command | 2 minutes | Stop, report, ask user how to proceed |
| Any HTTP / network call | 5 minutes | Stop, report, ask user how to proceed |

**Exceptions:** The agent may extend these limits only when the process is expected to be long (e.g., `npm install`, large file generation). In that case, it must:

1. Announce the exception before starting ("This command typically takes ~4 minutes — proceeding with extended timeout")
2. State the expected duration
3. Still stop and report if the extended estimate is exceeded

---

## 7. Post-Run Insights

After every skill run, the agent must:

1. **Generate 2–6 insight points** — concrete observations that would make a future run of the same skill faster or more accurate (e.g., "Grepping for `useSession` directly was faster than tracing from the route file")
2. **Print the insights** to the user as the final section of the run output
3. **Write the entry to a temp file**, then call `prepend-runtime-note.sh` — it handles lock acquire, atomic prepend, and lock release automatically:

   ```bash
   cat > /tmp/runtime-note-entry.md << 'ENTRY'
   [formatted entry — see template below]
   ENTRY

   bash ~/.claude/skills/shared/prepend-runtime-note.sh "<skill-name>" /tmp/runtime-note-entry.md
   ```

```markdown
## [Skill Name]: [Brief description of what was run] — [YYYY-MM-DD HH:MM]

**Purpose:** [One sentence: what this run was trying to accomplish]

**Insights:**

1. [point]
2. [point]
   ...

---
```

If `.claude/skills/runtime-notes.md` does not exist, create it with a header before writing the first entry.

### Runtime Notes Rotation

When `runtime-notes.md` exceeds **50 entries**, archive older entries to keep the active file fast to load:

1. Count entries (each starts with `## `)
2. Keep the newest 50 in `runtime-notes.md`
3. Move the rest to `runtime-notes-archive-YYYY-QN.md` (e.g., `runtime-notes-archive-2026-Q1.md`) in the same directory
4. Preserve the file header in both files
5. Verify: original count = kept + archived

This prevents context window bloat — a 1,000-entry file costs 30-50K tokens per session load.

### Project CLAUDE.md

Every project with **10+ sessions** in runtime notes should have a `CLAUDE.md` at its root (next to `package.json` or equivalent). This file provides session-start context so agents don't re-discover conventions from scratch each time.

Required sections: project description, tech stack, directory conventions, key gotchas. Keep under 100 lines.

---

## Preamble Template

Every SKILL.md workflow must begin with this section:

```markdown
## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md`. Apply all rules — forbidden paths, retry logic,
tool preferences, verbosity, timeouts, post-run insights, and the **file lock protocol**
— for the entire duration of this skill run before proceeding.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock hygiene: run `bash ~/.claude/skills/shared/lock-file.sh cleanup` once at skill start
> to clear any stale locks from crashed sessions. Then acquire a lock via `lock-file.sh
> acquire` before every Edit/Write, and release it immediately after. Never write to
> `runtime-notes.md` or any SKILL.md without holding its lock.
```

---

## 8. Skill Frontmatter Reference

When creating or improving skills, use these frontmatter fields:

| Field                      | Required                  | Notes                                                                  |
| -------------------------- | ------------------------- | ---------------------------------------------------------------------- |
| `name`                     | No (defaults to dir name) | Lowercase, hyphens only. Becomes the `/command`                        |
| `description`              | Recommended               | How Claude decides when to auto-invoke. Start with a verb.             |
| `argument-hint`            | No                        | `<required>` vs `[optional]` syntax                                    |
| `user-invokable`           | No                        | `false` = background knowledge only; not in `/` menu                   |
| `allowed-tools`            | No                        | Tools auto-approved when this skill is active                          |
| `disable-model-invocation` | No                        | `true` = Claude cannot auto-trigger; use for deploy/commit/push skills |
| `context`                  | No                        | `fork` = runs in isolated subagent context; keeps main context clean   |
| `model`                    | No                        | Override model for this skill                                          |

**When to use `disable-model-invocation: true`:** Any skill with side effects — deploys, commits, git push, sending messages. Prevents accidental auto-invocation.

**When to use `context: fork`:** Heavy exploration skills (`/pr-review`, `/arch-qa`, `/project-index`) that scan many files. Keeps main conversation context clean.

---

## 9. Internal Context File Convention

When a skill generates a file intended as **internal agent context** (session checkpoints, hand-off notes, intermediate state files), follow this naming convention:

- **Prefix:** filename must start with `_`
- **Suffix:** filename must end with `.claude.md`
- **Pattern:** `_<descriptive-name>.claude.md`

**Datestamped naming & session tagging:** All agent-created files must follow the naming and tagging rules in **`shared/doc-naming.md`**. Key points:
- Point-in-time files (checkpoints, plans, research) get a `YYYYMMDD-` prefix and a `<!-- sessions: [id] -->` tag
- Living docs (WAL, runtime-notes, indexes) do not get datestamped
- Core-dump checkpoints use `_YYYYMMDD-<session-id>.claude.md` with a `_checkpoint.claude.md` symlink

**Examples:**

| Purpose                           | Filename                              |
| --------------------------------- | ------------------------------------- |
| Session checkpoint for `/catchup` | `_20260331-fix-auth-3b.claude.md` (+ `_checkpoint.claude.md` symlink) |
| Design decisions hand-off         | `_20260331-decisions.claude.md`       |
| File reference index              | `_20260331-file-refs.claude.md`       |

**Rules:**

- Never use bare names like `checkpoint.md` or `notes.md` for agent-generated context files
- These files live in the project root alongside `.claude/` unless a skill explicitly scopes them elsewhere
- The `_` prefix signals "agent-generated internal file" and the `.claude.md` suffix prevents confusion with project documentation
- Full reference: `~/.claude/skills/shared/doc-naming.md`

---

## Skill Authoring Conventions

When **creating a new skill**, follow these conventions documented in `skills/README.md`:

1. **Check existing skills first** — read every skill's name and description; enhance or compose rather than duplicate where possible
2. **Use the four-phase skeleton** — Information Gathering → Planning → Execution → Testing/Verification (in whatever order, however many iterations)
3. **Run Prettier** on every file written or modified during the run: `npx prettier --write <filepath>`
4. **Always include `## Brief`** immediately after frontmatter
5. **Use `user-invokable: true`** (not `user-invocable`)
