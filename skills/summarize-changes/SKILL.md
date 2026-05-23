---
name: summarize-changes
description: Generates a categorized changelog of recent work, scoped by three orthogonal axes (time / topic / source) and rendered in a user-selected format. Treats git as ONE signal source among many — also reads WAL, checkpoint files, runtime-notes, memory entries, recently-modified files, and past-session transcripts — and reads the actual code, never relying on commit messages or commit boundaries alone. Asks the user when sources disagree.
allowed-tools: Bash, Read, Write, Glob, Grep, Agent
user-invokable: true
argument-hint: "[--last <dur> | --since <when> | --between <a> <b> | --unstaged | --staged | --vs <ref> | --pr [#]] [--topic <q>] [--path <p>] [--include-sources <csv>] [--format <k>]"
---

## Brief

Interactive multi-source change summarizer. Asks _when_, _what about_, and _where to look_ — then collects evidence from git AND the surrounding signal layer (WAL, checkpoints, runtime-notes, memory, recently-modified files, past-session transcripts), cross-references the sources, reads the actual code (not just diffs and not just commit messages), classifies entries by user-visible impact, and emits the requested format.

Designed to replace two lazy framings:

1. _"Changes = commits"_ — features can span many commits, multiple unrelated changes can hide inside one commit, and a lot of meaningful work lives outside git entirely (in-flight WAL events, checkpoint notes, recently-edited files not yet committed).
2. _"git log is enough"_ — commit subjects are starting points, not summaries.

> ⚠ Load-bearing anti-patterns — re-read before any output
>
> 1. **Commits are signals, not boundaries.** A change can be spread across N commits with no clean delimiter, OR bundled inside a single huge commit. Never assume one commit = one change.
> 2. **Never produce output by paraphrasing commit subjects.** Every non-trivial entry must be understood by reading the diff AND the surrounding code — `git show <sha>` plus a `Read` of the touched file at HEAD.
> 3. **Don't ignore ambient signals.** WAL, checkpoint files (`_*.claude.md`), runtime-notes, memory entries, and recently-modified files often capture work-in-progress that git hasn't seen yet. Read them. Cross-reference them against git.
> 4. **When sources disagree or scope is ambiguous, ASK.** Present the conflict with explicit options. Never resolve silently.
> 5. **Never silently default a user-input axis.** Every axis the user did not explicitly resolve via a CLI flag in `argv` (time / topic / path / sources / filters / format / PR-edit confirmation) is a MANDATORY interactive prompt via the Interactive Inputs MCP (`pick_one` / `pick_many` / `text_input` / `pick_path`). "The user probably wants X" / "auto mode means just pick" / "I'll default and announce it" are all forbidden. Auto mode is execute-on-low-risk; a 6-option format choice (or any axis where the user has visible preferences) is not low-risk. If the inputs MCP is unavailable, fall back to a numbered text menu via `read -r` — fall back, do NOT skip.

---

## Phase gating rule — applied to every Phase below

For each phase that takes a user input (1A / 1B / 1C / 2 / 4 / 7.3 PR-edit confirmation):

```
if <relevant flag(s) present in argv>:
    parse and proceed                    ← only path that skips the prompt
else:
    run the interactive picker           ← MANDATORY, no defaults
```

There is no third branch. "No flag was passed AND I have a strong guess" is NOT a path that skips the picker — it is a path that fires the picker WITH the guess pre-selected as the default highlight. The user always presses Enter (or picks something else) to confirm. Silent decisions on any axis are a re-occurrence of anti-pattern #5.

Argv → axis mapping (use this table to decide which prompts to skip):

| Axis           | Flags that resolve it                                                                        | Phase    |
| -------------- | -------------------------------------------------------------------------------------------- | -------- |
| Time           | `--last`, `--since`, `--between`, `--unstaged`, `--staged`, `--vs`, `--pr`, `--last-commits` | 1A       |
| Topic          | `--topic`                                                                                    | 1B       |
| Path           | `--path`                                                                                     | 1B (sub) |
| Sources        | `--include-sources`                                                                          | 1C       |
| Filters        | (none — Phase 2 is always interactive unless `--no-filters` is passed)                       | 2        |
| Format         | `--format`                                                                                   | 4        |
| PR-edit opt-in | `--push-pr-body` (explicit only — default is "do not push")                                  | 7.3      |

If an axis has zero resolving flags in argv, you MUST run its prompt. No exceptions.

---

## Step 0: Load Shared Guidelines and Runtime Context

Read `~/.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths, retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock protocol — for the entire duration of this skill run.

Also read `~/.claude/skills/runtime-notes.md` for past run history relevant to this skill. If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and release it immediately after. Never write to `runtime-notes.md` or any SKILL.md without holding its lock.

---

## Usage

```
/summarize-changes [time-flag] [--topic <q>] [--path <p>] [--include-sources <csv>] [--format <k>]
```

### Time axis (pick one if non-interactive)

| Flag                 | Meaning                                                                                    |
| -------------------- | ------------------------------------------------------------------------------------------ |
| `--last <dur>`       | `30m` / `2h` / `1d` / `1w` / `session` (= since last WAL `session_start`) — **time-based** |
| `--since <when>`     | Anything `git log --since` accepts (`"yesterday 9am"`, `"2026-05-01"`)                     |
| `--between <a> <b>`  | Two timestamps OR two refs (e.g. `--between v1.2 HEAD`)                                    |
| `--unstaged`         | Working-tree diff only                                                                     |
| `--staged`           | Index diff only                                                                            |
| `--vs <ref>`         | HEAD vs ref                                                                                |
| `--pr [#]`           | Current branch's PR or explicit `#NNN`                                                     |
| `--last-commits <N>` | Explicit commit count (rare — use only when you genuinely mean "exactly N commits")        |

### Topic axis (optional, composes)

| Flag          | Meaning                                                                                                                   |
| ------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `--topic <q>` | Keyword / feature name / ticket id (`auth`, `INGEST-241`, `cache layer`) — used for filtering and ambient-source matching |
| `--path <p>`  | Path / glob — composes with `--topic`                                                                                     |

### Source axis (where to read evidence from — multi-select)

| Flag                      | Meaning                                                                                  |
| ------------------------- | ---------------------------------------------------------------------------------------- |
| `--include-sources <csv>` | Comma list of: `git,worktree,wal,runtime-notes,checkpoints,memory,recent-files,sessions` |
| no flag                   | **Auto-detect**: include every source that has data within the time window               |

### Format axis

| Flag           | Meaning                                                                                                                             |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `--format <k>` | `bullets` / `report` / `pr` / `markdown` / `html` / `conventional` (skip Phase 4 prompt)                                            |
| `--style <s>`  | When `--format html`, passed through to `/create-report` (`feed` / `dashboard` / `data-table` / `magazine` / `terminal` / `notion`) |

### Specificity axis (informs Phase 1D follow-ups)

| Flag                      | Meaning                                                                                                    |
| ------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `--quick`                 | Skip Phase 1D entirely — use defaults for emphasis / audience / depth / compare                            |
| `--emphasis <e>`          | `risks-first` / `features-first` / `chronological` / `by-area`                                             |
| `--audience <a>`          | `me` (terse) / `team` / `pr-reviewer` / `release-notes` / `retro` / `new-hire` — shapes vocabulary + depth |
| `--depth <d>`             | `headline` (1-line) / `brief` (3-line) / `standard` (default) / `deep` (with code snippets)                |
| `--compare-against <ref>` | Adds a "vs prior" mini-section with diffstat + commit-count delta against a ref or duration                |

### No flags

Full interactive mode — Phase 0.5 (preliminary scan) → Phase 1A → 1B → 1C → 1D → 2 → 4 prompts.

---

## Phase 0.5 — Preliminary scan (research-then-ask)

Run BEFORE any wizard fires. The scan informs every subsequent picker — turning generic questions into ones grounded in what's actually in the data.

### 0.5.1 — Cheap probes

Run all probes in parallel (single Bash call where possible):

| Probe                    | Command / Method                                                                                               | Captured                                                |
| ------------------------ | -------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| Source availability      | (the table in 1C.1)                                                                                            | Per-source counts                                       |
| Author count             | `git log <range> --format='%ae' \| sort -u \| wc -l`                                                           | Distinct author count                                   |
| Top directories          | `git log <range> --name-only --format= \| awk -F/ '{print $1"/"$2}' \| sort \| uniq -c \| sort -rn \| head -5` | Where the work is concentrated                          |
| Theme cluster preview    | `git log <range> --format='%s' \| awk '{print $1}' \| sort \| uniq -c`                                         | feat/fix/refactor/chore/test/docs distribution          |
| Env-var sniffing         | `git log -p <range> -- '*.py' '*.ts' \| grep -E '(require_env\|process\.env\.[A-Z_]+\s*\?\?)'  \| sort -u`     | New env var introductions                               |
| Migration sniffing       | `git log <range> --name-only \| grep -E 'migrat' \| sort -u`                                                   | Migration files touched                                 |
| Hardcoded-secret removal | `git log -p <range> \| grep -E '^-.*("[A-Z_]+_PASSWORD\|api[_-]?key\|secret).*"' \| head -5`                   | Security cleanups                                       |
| Public API rename        | Grep diff for `def\|export function\|export const` lines with `-` AND a `+` partner of similar shape           | Likely API surface changes                              |
| Checkpoint Goal hint     | If `_checkpoint.claude.md` mtime within window: read its "Initial Goal" line                                   | One-line topic anchor                                   |
| Worktree-vs-git delta    | `git diff --name-only` set MINUS `git log <range> --name-only` set                                             | Files modified ONLY in worktree (uncommitted-only work) |

### 0.5.2 — Theme detection

Cluster files by directory + commit-subject keywords to produce a candidate list of "themes" (3–8 typically). Each theme: `{title, file_count, commit_count, status: committed/uncommitted/mixed, signals: [security|safety|breaking|env|migration]}`.

Theme detection is best-effort — the user can override in 1D. Don't claim certainty.

### 0.5.3 — Print the scan summary

Before the first wizard fires, print a brief summary so the user sees what the agent found:

```
─────────────────────────────────────────────────────
  Preliminary scan
─────────────────────────────────────────────────────
  Window:       <lower> → <upper>  (<duration>)
  Sources:      git (<N> commits) · worktree (<F> files) · WAL · ...
  Authors:      <N>
  Top dirs:     frontend/src/app/jobs (<N> files) · backend/api (<N>) · ...
  Type mix:     feat <N> · fix <N> · refactor <N> · test <N> · chore <N>
  Detected themes (best-effort):
    1. <theme name>     (<N commits>, <status>)  signals: [<list>]
    2. ...
  Ambient hooks:
    • Checkpoint Goal:  "<one line from _checkpoint.claude.md>"
    • Env vars added:   <names if any>
    • Migrations:       <files if any>
    • Security:         <hardcoded-secret removals if any>
    • Uncommitted-only: <N files in worktree NOT in git log>
─────────────────────────────────────────────────────
```

This panel is the **single most valuable thing** the skill emits. It surfaces in 6 lines what the user usually wants to know before deciding how detailed a report to ask for.

---

## Phase 1A — Time Selection

If a time flag is in `argv`, parse it and skip this phase. Otherwise:

Use **`mcp__inputs__pick_one`**:

```
1. Right now — uncommitted work (staged + unstaged combined)
2. Since the last work session  (WAL session_start, ~hours ago)
3. Last N hours / days / weeks   → follow-up: duration text
4. Between two timestamps / refs → follow-up: two text inputs
5. Compared to a branch / ref    → follow-up: pick from recent branches
6. A specific date range         → follow-up: since + until
7. A pull request                → follow-up: PR # (default = current branch's PR)
8. Since the last git tag        (release-notes use case)
```

Fallback to a numbered text menu if the inputs MCP is unavailable.

**`--last session` resolution:** read `.claude/wal.jsonl` (or `~/.claude/wal.jsonl`), find the most recent `kind: session_start` line, use its `ts` as the lower bound. If WAL is missing or stale (>48h), fall back to "last 4 hours" with a printed warning.

---

## Phase 1B — Topic Selection (optional)

Use **`mcp__inputs__pick_one`**:

```
1. No topic filter — summarize everything in the time window
2. A feature / area / keyword         → text_input
3. A specific file or directory       → pick_path (composes with #2)
4. A ticket / issue / PR id           → text_input (will be matched in commit messages, runtime-notes, memory)
5. The topic of the most recent checkpoint (_checkpoint.claude.md "Initial Goal" section)
```

Topic is propagated as a filter to every source query in Phase 5+.

---

## Phase 1C — Source Selection (multi-pick)

Use **`mcp__inputs__pick_many`**. Pre-check sources where data exists within the time window (run cheap probes first — see 1C.1).

```
[?] Git history          (commits in window)
[?] Working tree         (uncommitted diff)
[?] WAL                  (.claude/wal.jsonl events)
[?] Runtime notes        (.claude/skills/runtime-notes.md entries in window)
[?] Checkpoint files     (_*.claude.md mtime in window)
[?] Memory               (~/.claude/projects/<encoded>/memory/*.md created/modified in window)
[?] Recently-modified    (find . -mtime within window — captures uncommitted work)
[?] Past-session transcripts  (via `/past-sessions` if available — slow, opt-in)
```

Each `[?]` becomes `[x]` (default-on) if the cheap probe found data, `[ ]` (default-off) if empty.

### 1C.1 — Cheap availability probes (run before showing the picker)

| Source            | Probe command                                                                                    |
| ----------------- | ------------------------------------------------------------------------------------------------ |
| Git               | `git log --since=<lower> --oneline -1 \| wc -l`                                                  |
| Worktree          | `git status --porcelain \| wc -l`                                                                |
| WAL               | `tail -100 .claude/wal.jsonl 2>/dev/null \| jq -r 'select(.ts > "<lower>") .kind' \| head -1`    |
| Runtime notes     | `grep -c "^## " .claude/skills/runtime-notes.md 2>/dev/null` + filter by date                    |
| Checkpoint files  | `find . -maxdepth 2 -name "_*.claude.md" -newermt "<lower>" \| head -1`                          |
| Memory            | `find ~/.claude/projects/$(pwd \| sed 's:/:-:g')/memory -newermt "<lower>" \| head -1`           |
| Recently-modified | `find . -type f -newermt "<lower>" -not -path "*/node_modules/*" -not -path "*/.git/*" \| wc -l` |
| Past-sessions     | (skip probe — always opt-in due to cost)                                                         |

---

## Universal picker options — applied to EVERY pick_one and pick_many in this skill

Every interactive picker in this skill (Phase 1A / 1B / 1C / 1D / 2 / 4) MUST include these two options at the top of its option list, in addition to its domain-specific choices:

- **"All / select everything"** (semantics depends on the picker — for `pick_one`, it means "include everything this picker controls"; for `pick_many`, it pre-selects every box). Sources picker → all 8 sources. Topic picker → no topic filter (the broadest scope). Format picker → "All styles" chains to `--all-styles` mode of `/create-report`. Filters picker → all default-on filters checked.
- **"Skip remaining questions — use sensible defaults"** (one-shot mode). Selecting this on ANY picker short-circuits the rest of the wizard and uses defaults for every subsequent axis. Useful when the user just wants the report and trusts the defaults.

These two options compose with the existing "Other" / free-text options that the inputs MCP already injects.

---

## Phase 1D — Specificity follow-ups (informed by Phase 0.5)

If `--quick` is in argv OR a previous picker selected "skip remaining questions", skip this entire phase. Otherwise:

Each follow-up is a separate `pick_one` call. Question text references findings from Phase 0.5 — generic versions are fallbacks if no scan signal applied.

### 1D.1 — Theme grouping (only if 0.5 detected ≥3 themes)

```
I detected <N> themes in the window:
  • <theme 1>
  • <theme 2>
  • <theme 3>
  ...

How should the report group entries?
  1. By detected theme — narrative around the <N> themes above
  2. By impact bucket — Big / Medium / Small (default)
  3. By area — directory-tree-aligned sections (frontend/backend/infra)
  4. By type — feat / fix / refactor / chore / docs
  5. Chronological — oldest first
  ─
  All / both — try multiple groupings if the window is small enough
  Skip remaining questions — use defaults
```

If only 1–2 themes detected, skip this picker (use impact bucket default).

### 1D.2 — Anchor on checkpoint Goal (only if 0.5 read a Goal)

```
Most recent checkpoint says:
  Goal: "<one line from checkpoint Initial Goal>"

Anchor the report's TL;DR on this goal?
  1. Yes — frame the narrative as progress against this goal
  2. No — treat the goal as one signal among many (default)
```

Skip if no checkpoint Goal in window.

### 1D.3 — Audience

```
Who's reading this report?
  1. Me (terse, terminal-only, optimized for fast skim)
  2. Team (default — moderate depth, defensible without me explaining)
  3. PR reviewer (Summary / Changes / Test plan / Risks)
  4. Release notes (user-facing language, no internal jargon)
  5. Retrospective (chronological + insights + lessons)
  6. New-hire onboarding (extra context, link to architecture docs)
  ─
  All — render multiple audiences as separate sections
  Skip remaining questions — use "Team" defaults
```

Audience sets vocabulary ("the engine" vs "JobsManager.get_job_output"), depth (1-line vs full hunks), and structural preset.

### 1D.4 — Depth

```
How deep should the agent read into each entry?
  1. Headline only — one line per entry
  2. Brief — 3 lines per entry (what / why / watch)
  3. Standard — full What/Why/Watch + file table (default)
  4. Deep — include code snippets from key diffs + git blame context
  ─
  Skip remaining questions — use "Standard" defaults
```

### 1D.5 — Emphasis

```
What should the report emphasize?
  1. Risks-first — Watch lines + uncommitted/security/breaking surface up top
  2. Features-first — feat: commits and new modules up top (default)
  3. Chronological — strict time order
  4. By-area — frontend / backend / infra as top-level sections
  5. Author-by-author — split by who did the work
  ─
  Skip remaining questions — use "Features-first" defaults
```

### 1D.6 — Compare-against (optional)

```
Compare this window to anything?
  1. No (default)
  2. Prior period (same duration, immediately preceding)
  3. A baseline branch — pick from recent branches → text_input
  4. A specific tag → text_input
```

If selected, the report adds a small "vs prior" panel: file count delta, lines delta, commit count delta, themes that ARE in this window but not the comparison.

---

## Phase 2 — Filters (optional, pick_many)

Same as before, but applies across all sources, not just git:

```
[x] Exclude bot commits / bot WAL events
[x] Exclude lockfiles + generated files (*.lock, dist/, *.min.js)
[x] Skip merge commits (--no-merges)
[ ] My commits / my WAL events only (match git config user.email)
[ ] Custom path exclude → text_input
```

---

## Phase 3 — Sanity Check

Cheap sizing pass across selected sources. Print to user:

```
Time window:     <lower> → <upper>  (<duration>)
Topic filter:    <q | none>
Sources:         git (<N> commits), worktree (<F> files), WAL (<E> events),
                 runtime-notes (<M> entries), checkpoints (<C> files),
                 recently-modified (<R> files), memory (<X> entries)
Estimated read:  ~<K> diff lines + ~<L> note lines
```

If totals exceed thresholds (>150 commits, >50k diff lines, >500 files, >50 note entries), stop and ask:

```
This range is large.
  1. Continue at full depth (slow, most accurate)
  2. Coarse mode — diffstat only, skip per-file diff reads
  3. Top-N mode — read the N largest entries per source (default N=20)
  4. Cancel and refine the scope
```

---

## Phase 4 — Output Format Selection

If `--format` was passed, skip. Otherwise `pick_one`:

```
1. Terse bullets             (terminal, ≤ 12 lines)
2. Detailed grouped report   (terminal, big/medium/small + cross-source insights)
3. GitHub PR description     (markdown: Summary / Changes / Test plan / Risks)
4. Markdown file             → follow-up: file path
5. HTML report               → chains /create-report
6. Conventional-commits log
```

---

## Phase 5 — Source Collection

For each selected source, run the appropriate query. Store results keyed by source.

| Source            | Query                                                                                                                                  |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| Git               | `git log <range> --pretty=format:"%h\|%ad\|%an\|%ae\|%s" --date=iso` + `git log <range> --numstat`                                     |
| Worktree          | `git diff` + `git diff --cached` + `git status --porcelain`                                                                            |
| WAL               | `jq -c 'select(.ts >= "<lower>" and .ts <= "<upper>")' .claude/wal.jsonl` — collect `kind`, `target`, `goal`, `current`, `next` fields |
| Runtime notes     | Parse `.claude/skills/runtime-notes.md`, extract `## session: ... — DATE` blocks, filter by date in heading                            |
| Checkpoint files  | `find . -maxdepth 2 -name "_*.claude.md" -newermt "<lower>"` then `Read` each — extract Goal / Pending / Current Expectation           |
| Memory            | List + Read modified files in `~/.claude/projects/<encoded-cwd>/memory/`. Cross-reference against `MEMORY.md` index                    |
| Recently-modified | `find . -type f -newermt "<lower>" \| filter forbidden paths` — focus on files NOT in `git log` (uncommitted work)                     |
| Past-sessions     | Invoke `/past-sessions` (or its underlying script) with the time window + topic — receive a digest, not raw transcripts                |

For PR scope: prefer `gh pr view <num> --json title,body,commits,files` + `gh pr diff <num>`.

---

## Phase 6 — Cross-Source Reconciliation

This is the load-bearing differentiator. Fuse evidence from all selected sources into a single set of "change entries". An entry is a user-visible unit of work, NOT a commit.

### 6.1 — Cluster signals into entries

For each piece of evidence (commit, WAL event, checkpoint goal, runtime-notes insight, modified-file group):

1. Identify a **theme key** — extract from the strongest signal (commit subject, checkpoint Goal line, WAL `goal` field, or the directory of touched files).
2. Cluster all signals sharing or adjacent to that key into one entry. Adjacency: same files, same module path, same ticket id, same author within an hour, same WAL session id, mention by name in another signal.
3. **A single entry can pull from many signals.** A "feat: add X" commit + a checkpoint that says "implement X" + a runtime-notes insight about "fix Y bug while implementing X" + 3 follow-up "fix:" commits = ONE entry, not five.
4. Conversely, **one commit can produce multiple entries.** A 4000-line commit titled "misc fixes" gets re-clustered by file group.

### 6.2 — Classify by user-visible impact

Use diffstat thresholds AND ambient evidence:

| Bucket | Signals                                                                                  |
| ------ | ---------------------------------------------------------------------------------------- |
| Big    | ≥ 500 diff lines OR new module/dir OR explicitly flagged as "Initial Goal" in checkpoint |
| Medium | 100–499 diff lines OR cross-cutting (≥ 3 files in different modules)                     |
| Small  | < 100 diff lines AND single-area                                                         |

Demote one bucket: pure auto-doc, lockfile-only, formatter-only.

### 6.3 — Read the actual code (mandatory for Big/Medium)

For every Big and Medium entry — **don't stop at `git show`**:

| Read                                                                                              | Why                                                                                                       |
| ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `git show <sha> --stat \| head -50`                                                               | File list + sizes                                                                                         |
| `git show <sha> -- <largest 1-3 files>`                                                           | Actual hunks                                                                                              |
| `Read` the file at HEAD (not just the diff)                                                       | Surrounding code, exports, imports, comments — diff hunks are deceptive in isolation                      |
| `Grep` for the new symbols / renamed identifiers                                                  | See callers — was the rename complete? Are there stale references?                                        |
| `git blame -L <hot-line-range> <file>`                                                            | Who else touched the same lines, when. Distinguishes a fresh feature from a tweak to a long-standing area |
| `Read` 1–2 sibling files in the same directory                                                    | Often the real shape of a refactor — the touched file changed because the sibling did first               |
| Any **referenced** runtime-notes / checkpoint / memory entry mentioned in the diff or commit body | The "why" almost always lives in the note, not the diff                                                   |

For Smalls, the diff alone is usually enough — but if the commit subject is uninformative (`fix: minor`, `wip`, `cleanup`), do the full read anyway.

### 6.4 — Translate to human meaning

Per entry, write 1–4 lines answering:

| Question                             | Source                                                                   |
| ------------------------------------ | ------------------------------------------------------------------------ |
| What user-visible behavior changed?  | Read of file at HEAD + diff + ambient note                               |
| Why? (intent, motivation)            | Checkpoint Goal / WAL `goal` / commit body / runtime-notes — NOT subject |
| What's the load-bearing detail?      | New env var, default flipped, public API rename, migration, dependency   |
| What ambient signal corroborates it? | WAL event, checkpoint mention, runtime-notes insight                     |

Surface signals from the diff:

| Signal                                               | Surface as                                      |
| ---------------------------------------------------- | ----------------------------------------------- |
| New env var (`require_env`, `process.env.X`)         | Deploy / config concern                         |
| New top-level dir or new dep in package manifest     | Architectural addition                          |
| Public API signature change                          | Breaking surface — flag explicitly              |
| Default flipped (true↔false, threshold value change) | Silent regression risk — flag explicitly        |
| Migration files                                      | Always surface separately, even when small      |
| Mass auto-formatter                                  | Demote to "formatting only — N files"           |
| WAL event with no corresponding commit               | In-flight work — flag as "uncommitted" or "WIP" |
| Checkpoint Pending Item with corresponding commits   | Mark as "completed since checkpoint"            |
| Runtime-notes insight referenced in commit body      | Quote it in the entry summary                   |

### 6.5 — Ambiguity escalation (load-bearing)

When sources contradict or scope is unclear — DO NOT pick silently.

Trigger conditions:

- Two checkpoints in the window with conflicting Goals
- WAL says "fixed X" but no commit touches X-related files
- A topic filter matched files but no commits in the time window
- A runtime-notes insight describes behavior that the diff doesn't reflect
- A checkpoint Pending Item is unresolved AND no commit addresses it

For each conflict, pause and `pick_one`:

```
Conflict:
  WAL @ 2026-05-04T15:39 says: "fixed task-claimer race condition"
  But no commit in the window touches lib/tasks/claimer.py.

How should this be reconciled?
  1. Treat the WAL as authoritative — include as "uncommitted fix"
  2. Treat git as authoritative — drop the WAL signal
  3. Mark as ambiguous in output and let the reader decide
  4. Investigate further — let me read the WAL session in detail
  5. Skip this entry entirely
```

Wait for the user. Apply their choice.

---

## Phase 7 — Render

Same six formats as before, but each format includes ambient evidence, not just commits.

### 7.1 — `bullets`

```
• <theme>          — <user impact> · evidence: git, WAL
• <theme>          — <user impact> · evidence: checkpoint + 3 commits
• [WIP] <theme>    — uncommitted, captured in WAL/recent-files only
```

The `evidence:` tag is one short word per source contributing to the entry.

### 7.2 — `report`

A skim-friendly report. The reader should be able to understand the whole window in 30 seconds without reading any prose, then dive deeper as needed. Layout — top to bottom:

#### 7.2.a — Scan card (≤8 lines, FIRST thing in the report)

```
═══════════════════════════════════════════════════════════════
  SCAN CARD — what happened in this window
═══════════════════════════════════════════════════════════════
  Window:   <lower> → <upper>  (<duration>)
  Volume:   <C> commits · <F> files · +<I> -<D> lines · <U> uncommitted
  Themes (top): <theme1>, <theme2>, <theme3>
  Risks:    <count> security · <count> breaking · <count> uncommitted
  Read:     ~<minutes> min for a careful pass; jump to RISKS first
═══════════════════════════════════════════════════════════════
```

The Volume / Themes / Risks lines must be one-liners with hard counts — no prose.

#### 7.2.b — Aggregate Risks panel (collapses every entry's "Watch")

```
RISKS / DEPLOY CONCERNS — read before merging
─────────────────────────────────────────────
  🔒  <Item B>  Security cleanup (hardcoded password removal) UNCOMMITTED
  ⚠   <Item D>  "catastrophic for refund" — verify null-check at every caller
  💥  <Item A>  cache.py _SENTINEL — `is None` callers silently broken
  🆕  <Item A>  3 new env vars: JOB_OUTPUT_CACHE_DISABLED / *_TTL_SEC / ADMIN_SCRAPER_API_TOKEN
  ⏳  <Items B/D/F/G>  Significant uncommitted surface — /clear + git stash would lose it
─────────────────────────────────────────────
```

If no risks, print "No deploy concerns flagged." in the panel — never omit the panel.

#### 7.2.c — Theme list with status pills (one line per entry)

```
THEMES                                                                STATUS
────────────────────────────────────────────────────────────────────────────
A. Job-output engine refactor                       🟢 committed + 🟡 worktree
B. Internal Scraper API                                       🟡 uncommitted 🔒
C. Backend test framework                                      🟢 committed
D. Refund-credits flow                                        🟡 uncommitted ⚠
E. Modal redesigns                                             🟢 committed
F. Frontend type mirror                                       🟡 uncommitted
G. Status-message tooltip                                     🟡 uncommitted
────────────────────────────────────────────────────────────────────────────
```

Pills (one-character icons preceded by a space): 🟢 fully committed · 🟡 uncommitted · 🟣 mixed · 🔒 security cleanup · ⚠ safety-critical · 💥 breaking surface · 🆕 new module/dir · 🚚 migration · 📦 dep change.

#### 7.2.d — Big / Medium / Small detailed entries

For each entry — header line with status pills + a tight FILE TABLE (replaces dense bullet lists), then What/Why/Watch as 1–3 lines each:

```
<theme>                                       🟢 committed  🔒 security
─────────────────────────────────────────────────────────────────────
  Files
    ├─ backend/api/internal/scraper.py        +87        🆕 NEW
    ├─ backend/api/internal/helpers.py        +90        🆕 NEW
    ├─ backend/api/auth.py                    +15 / -0   ✏ modified
    └─ frontend/.../route.ts                  +120       🆕 NEW (untracked)

  What:   <2 lines — behavior change>
  Why:    <1 line — quoted from checkpoint Goal / memory entry / commit body>
  Watch:  <1 line — env var / default flip / breaking surface>
```

The file table is the single most-skimmable artifact. Three columns: path · diffstat · one-icon status. If >6 files, show first 6 + `└─ ... and N more`.

#### 7.2.e — Insights block (2–4 bullets)

End-of-report. Includes any ambiguities the user resolved in Phase 6.5.

#### Depth modulation

When `--depth headline` was selected: render only Scan Card + Risks panel + Theme list (skip 7.2.d/7.2.e).
When `--depth deep` was selected: 7.2.d also includes 1 short code snippet per Big entry, pulled from the largest hunk.

### 7.3 — `pr` (GitHub PR description)

Audience-aware. Same skim-friendly layout as 7.2 but in markdown — Scan Card → Risks → Themes → Detailed Changes → Test Plan → "Context not in this branch" (if WAL/checkpoints describe related work that didn't land in commits).

### 7.4 — `markdown` (file)

Identical content to 7.2 (Scan Card → Risks → Themes → Big/Medium/Small entries → Insights), written to disk. Default path: `~/.claude/assets/reports/<YYYYMMDD>-summarize-changes/summary.md`. Print absolute path at end.

### 7.5 — `html` (chains `/create-report`)

Render the markdown body to a temp file, then chain `/create-report` with a skim-friendly style. **Default style is `feed`** — narrative-card layout where each theme renders as a discrete card with status pills visible without scrolling. `feed` was chosen over `dashboard` because the dashboard style buries entry-level status in dense paragraphs; `feed` surfaces it.

If `--style <s>` was passed in argv, use it. Otherwise, prompt via `pick_one` (NOT silent default — anti-pattern #5):

```
Which HTML layout?
  1. Feed — card-per-theme, status pills visible, best for skim (default)
  2. Dashboard — analytics layout with metric cards (good for many small entries)
  3. Data-table — spreadsheet layout (good when most entries are file-list-heavy)
  4. Magazine — editorial layout (good for narrative emphasis, e.g. retro)
  5. Notion — clean minimal (good for sharing externally)
  6. Terminal — green-on-black (good for me-only)
  ─
  All styles — chain `--all-styles` to render every variant
```

Output written to `~/.claude/assets/reports/<YYYYMMDD>-<slug>/index.html` (colocated with `source.md` and `data.json`). Print absolute path AND the `restyle.sh` command at end so the user can swap styles without re-running the whole skill.

### 7.6 — `conventional` (log)

One line per commit, conventional-commits-style. Prefix inferred from diff content when commit subject doesn't already follow the convention.

---

## Phase 8 — Footer

```
─────────────────────────────────────────────────────
  Time window:    <lower> → <upper>
  Sources used:   <list with per-source count>
  Topic filter:   <q | none>
  Filters:        <list>
  Stats:          <N entries · M files · +K -L lines · A commits · B WAL events>
  Conflicts resolved: <N> (see Insights)
─────────────────────────────────────────────────────
```

If output went to a file, print path. If terminal output > 40 lines, offer to save.

---

## Notes

### Constraints

- **Read-only by default.** Never commits, pushes, or edits source files. The single exception is `gh pr edit --body-file` in Phase 7.3 with explicit opt-in.
- **Cross-source reconciliation is mandatory.** Output that draws only from git when other selected sources had data is broken — see anti-pattern #3.
- **Ambiguity is escalated, never resolved silently.** See anti-pattern #4 / Phase 6.5.
- **Forbidden paths** (per GUIDELINES.md) are excluded from all source queries.
- **Source flexibility:** if a source is selected but produces no data, note it in the footer rather than failing the run.

### Edge cases

| Case                                             | Behavior                                                                     |
| ------------------------------------------------ | ---------------------------------------------------------------------------- |
| No data in any source                            | Print "No activity in scope." and exit 0                                     |
| Only ambient data, no commits                    | Render normally; flag entries as "uncommitted / WIP"                         |
| Only commits, no ambient data                    | Render normally; footer notes which optional sources were empty              |
| WAL is corrupt / unparseable                     | Skip WAL with a printed warning; continue                                    |
| Multiple checkpoint files in window              | Treat each as a separate entry under "Goals stated this window"              |
| Past-sessions selected but `/past-sessions` slow | Run as a subagent (Agent tool) so it doesn't block the main flow             |
| Topic filter matches nothing in any source       | Tell the user; offer to broaden (drop topic, widen window, add more sources) |
| `--last session` but no WAL                      | Fall back to "last 4 hours" with a printed warning                           |
| User declines all conflict-resolution options    | Exit 0 with a hint to refine the scope                                       |

### Integrations

- Calls `/create-report` when `--format html`.
- Calls `/past-sessions` (or its underlying script) when that source is selected.
- Pairs with `/commit-push-pr` — generate a PR description, then commit-push.
- Reads `.claude/wal.jsonl` per the WAL spec (`~/.claude/skills/shared/wal-format.md`).
- Reads `_checkpoint.claude.md` per the `/core-dump` schema (Initial Goal / Agent Actions / Current Expectation / Pending Items).

### Implementation hints for the running model

- Use `Bash` for git + filesystem probes, `Read` for code AND notes, `Grep` for cross-referencing.
- For Phase 6 (cross-source reconciliation) on a window with > 30 entries, spawn an `Agent` (subagent_type: general-purpose) with the structured signal list — keeps the diff- and note-reading off the main context. Return a structured list of entries, not free-text.
- Cache the parsed `numstat` and the WAL events — reused in Phases 3, 6.1, 6.2.
- Don't `cat` large diffs — `git show -- <file>` per file, piped through `head` if needed.
- When reading checkpoint files, only Read the four canonical sections — don't slurp the whole file if it's long.
- Memory entries are tiny — Read in full.
- Recently-modified files: focus on the ones NOT covered by `git log` — that's the uncommitted-work signal git can't see.

---

## Validation Examples

### Example: Time window with both committed and uncommitted work

**Scenario:** User runs `/summarize-changes --last 4h --format report`. The window contains 3 commits + uncommitted changes in 2 files + 1 WAL session_start + 1 checkpoint file.
**Expected behavior:**

- [ ] Phase 1C auto-detects all four sources have data and pre-checks them
- [ ] Phase 5 collects from git, worktree, WAL, AND checkpoints — not git only
- [ ] Phase 6.1 clusters the uncommitted-file signals as their own entry, separate from committed entries
- [ ] Phase 6.3 reads the actual file at HEAD for at least one Big/Medium entry — not just `git show`
- [ ] Phase 7.2 output flags the uncommitted entry as "WIP / uncommitted"
- [ ] Phase 8 footer shows per-source counts including WAL events

### Example: Conflicting sources trigger user prompt

**Scenario:** WAL has `goal: "fix race in claimer"` event, but the time window has zero commits touching the claimer module.
**Expected behavior:**

- [ ] Phase 6.5 detects the mismatch (WAL signal without git counterpart)
- [ ] User is shown a `pick_one` with at least 4 resolution options
- [ ] No silent decision — output reflects whichever option the user picked
- [ ] Phase 8 footer increments the "Conflicts resolved" counter

### Example: Topic filter with no commits but ambient evidence

**Scenario:** `/summarize-changes --last 1d --topic auth`. Zero commits mention "auth", but a runtime-notes insight from earlier today describes auth refactor planning.
**Expected behavior:**

- [ ] Phase 5 picks up the runtime-notes hit even when git is empty
- [ ] Output renders the runtime-notes signal as the entry, marked as planning/discussion not implementation
- [ ] User is offered to broaden the topic / window if even ambient sources are sparse

### Example: One commit produces multiple entries

**Scenario:** A 4000-line commit titled "misc fixes" touches 30 files across 4 distinct modules.
**Expected behavior:**

- [ ] Phase 6.1 re-clusters the commit by directory/module — does NOT emit it as one entry
- [ ] Each cluster gets its own theme heading
- [ ] All clusters share the same SHA in their evidence tag

### Example: Multiple commits collapse to one entry

**Scenario:** A refactor lands as 1 big commit + 5 follow-up "fix: update callers" commits within an hour.
**Expected behavior:**

- [ ] Phase 6.1 clusters all 6 into one entry by adjacency (same files / same author / same hour)
- [ ] Evidence tag shows the SHA range
- [ ] Body summarizes the refactor + notes the 5 caller-update commits as follow-ups, not separate entries

### Example: Format axis with no flag — interactive prompt is MANDATORY

**Scenario:** User runs `/summarize-changes --since "2026-04-30" --path frontend backend`. No `--format` flag. Auto mode is active.
**Expected behavior:**

- [ ] Phase 4 fires `pick_one` with all 6 format options — does NOT default
- [ ] Skill does NOT pre-render output and announce a default format choice
- [ ] "Auto mode" is not invoked as a justification to skip the prompt
- [ ] If the inputs MCP is unavailable, fall back to `read -r` numbered menu — never skip
- [ ] Same rule applies to ALL axes: time / topic / sources / filters / format / PR-edit

### Example: Multiple axes without flags — multiple prompts fire

**Scenario:** User runs `/summarize-changes` with no flags at all.
**Expected behavior:**

- [ ] Phase 1A (time) fires `pick_one`
- [ ] Phase 1B (topic) fires `pick_one`
- [ ] Phase 1C (sources) fires `pick_many` with auto-detected pre-checks
- [ ] Phase 2 (filters) fires `pick_many`
- [ ] Phase 4 (format) fires `pick_one`
- [ ] All five prompts run in sequence — no axis is silently defaulted

### Example: Preliminary scan runs BEFORE any wizard

**Scenario:** User runs `/summarize-changes --since "2026-04-30"` with no other flags. Window contains 19 commits across 3 themes, 1 checkpoint with a Goal, and 2 env-var additions.
**Expected behavior:**

- [ ] Phase 0.5 runs FIRST — before Phase 1A's time prompt is even relevant (or before any subsequent picker if time is in argv)
- [ ] Scan output prints commit count, distinct authors, top dirs, type-mix, detected themes, env-var sniff, checkpoint Goal hint
- [ ] Phase 1D follow-ups reference the scan findings — e.g. "I detected 3 themes" not generic "what should we group by"
- [ ] If 0.5 found a checkpoint Goal, Phase 1D.2 fires with the Goal quoted; if no Goal, 1D.2 is skipped entirely

### Example: Universal "all" + "skip-rest" available on every picker

**Scenario:** User runs `/summarize-changes` interactively and on the first picker (Phase 1A time) selects "Skip remaining questions — use sensible defaults".
**Expected behavior:**

- [ ] EVERY picker (1A / 1B / 1C / 1D.1-6 / 2 / 4) has BOTH "All / select everything" AND "Skip remaining questions — use sensible defaults" as the top two options, in addition to its domain-specific choices
- [ ] When user picks "Skip remaining" on Phase 1A, the wizard short-circuits — every subsequent axis uses defaults (no further prompts fire)
- [ ] Defaults applied are documented in the SKILL.md so the skill is reproducible (e.g. format=`report`, sources=auto-detect, depth=`standard`, audience=`team`, emphasis=`features-first`)
- [ ] On the format picker specifically, "All" maps to `--all-styles` mode of `/create-report` — generating every style variant in one shot

### Example: Scan card + risks panel + theme list dominate the report layout

**Scenario:** User runs `/summarize-changes --since "2026-04-30" --format report --depth standard`. Window has 7 entries across Big/Medium/Small with 3 risks (1 security, 1 safety, 1 breaking).
**Expected behavior:**

- [ ] First thing rendered is the SCAN CARD (≤8 lines: window / volume / themes / risks / read-time)
- [ ] Second thing rendered is the AGGREGATE RISKS PANEL — every entry's "Watch" line collapsed into one scannable list with icon prefixes (🔒 / ⚠ / 💥 / 🆕 / ⏳)
- [ ] Third thing rendered is the THEME LIST with status pills — one line per entry, status (🟢/🟡/🟣) + risk icons (🔒/⚠/💥) visible without scrolling
- [ ] Big/Medium entry sections include a FILE TABLE (path · diffstat · status icon) instead of dense bullet lists; >6 files → first 6 + "... and N more"
- [ ] When `--depth headline` is passed, ONLY the scan card + risks panel + theme list render — Big/Medium/Small detail sections are skipped

### Example: HTML format defaults to skim-friendly style, prompts when ambiguous

**Scenario:** User runs `/summarize-changes --since "2026-04-30" --format html` with no `--style` flag.
**Expected behavior:**

- [ ] Phase 7.5 fires a `pick_one` for style — does NOT silently default to `dashboard`
- [ ] First option is `feed` (Recommended) — labeled as "card-per-theme, status pills visible, best for skim"
- [ ] "All styles" option chains to `/create-report --all-styles` mode
- [ ] When `--style <s>` IS passed, no picker fires; the style is forwarded to `/create-report`
- [ ] Output path is `~/.claude/assets/reports/<YYYYMMDD>-<slug>/index.html` colocated with `source.md` + `data.json`; the `restyle.sh` command is printed at the end
