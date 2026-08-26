---
name: catchup
description: Resumes a session from a /core-dump checkpoint. Resolves via the ~/.claude/checkpoints/ index (picker when ambiguous) or a named _checkpoint.claude.md, loads only targeted file sections for pending tasks, and presents a compact briefing to resume work. Companion to /core-dump.
allowed-tools: Read, Glob, Grep, Bash
argument-hint: "[filename | --session-id ID | --pick N]"
user-invocable: true
---

## Brief

Resume a cleared session from a `/core-dump` checkpoint with minimum exploration overhead. Parses the six-section checkpoint format (Resume Contract first, when present), presents the resume contract and pending items first, loads only targeted file sections referenced by pending tasks — no full file reads, no broad codebase scans — then hands off cleanly for immediate work.

## The session-resume surfaces

A resume is not just "read the checkpoint". A cleared session drops several
independent kinds of state, each restored by a different phase below. This is the
map, so none of them is silently skipped — if you only do the checkpoint, you
resume with the wrong todo list, an unreachable mailbox, and a false picture of
what is still running.

| surface | what it restores | owner |
|---|---|---|
| **Checkpoint file** | goal · actions · pending items · Resume Contract (incl. decaying prerequisites) | 0.4 resolve → 1 parse |
| **WAL** | a fresher last-known-good than the checkpoint, when <24h | 0.5 (fast path) |
| **Workspace todos** | the user-curated list — rehydrated into the LIVE Task tool | 0.8 |
| **ipc identity + mail** | your alias, the dead predecessor's mail, peers owed a reply | 3.1b |
| **Live subsystem state** | servers / watchers / jobs still running from before | 3.4 |
| **Git reality** | what moved under you since the dump | 1.4 |
| **Task table** | the store's own view, in the ratified shape, shown to the owner | 3.6 |

Session-scoped counters (tool count, ctx %) need no action here — a `source==clear`
SessionStart injector resets them on the first tool call (`scripts/session-mgmt/post-clear-counter-reset.sh`).

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md`. Apply all rules — forbidden paths, retry logic,
tool preferences, verbosity, timeouts, post-run insights, and the **file lock protocol**
— for the entire duration of this skill run before proceeding.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after. Never write to `runtime-notes.md` or any SKILL.md without
> holding its lock.

## Usage

```
/catchup [filename | --session-id ID | --pick N]
```

| Argument          | Type     | Description                                                                                                                                                                                                            |
| ----------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `filename`        | optional | Explicit checkpoint file to read. Must follow `_*.claude.md` convention. When given, Phase 0.4 is skipped entirely — use this when you know exactly which file. Defaults to `_checkpoint.claude.md` in the project.    |
| `--session-id ID` | optional | Resolve via `~/.claude/checkpoints/<ID>.json`. Use when a long-running agent knows its own session-id and wants to skip the picker.                                                                                    |
| `--pick N`        | optional | Resolve the Nth most-recent entry in `~/.claude/checkpoints/index.jsonl` (1-based). Use to re-pick the same option from a previous picker non-interactively.                                                            |

When none of the above are passed and CWD is ambiguous (`~/.claude/` or not in a project), Phase 0.4 runs the auto/picker resolution flow.

## Phase 0.1 — Parse Arguments

Inspect the args string before any resolution work:

1. **`--session-id ID`** present → set `ARG_SESSION_ID=ID`. Skip the rest of Phase 0 entirely. Jump to Phase 0.3 to resolve directly:
   ```bash
   ~/.claude/scripts/checkpoint/resolve.sh --session-id "$ARG_SESSION_ID"
   ```
2. **`--pick N`** present → set `ARG_PICK_N=N`. Skip Phase 0.4 picker UI; resolve directly:
   ```bash
   ~/.claude/scripts/checkpoint/resolve.sh --pick "$ARG_PICK_N"
   ```
3. **Bare filename** (a token matching `_*.claude.md`) → set `ARG_FILENAME`. Skip Phase 0.4 (the user named the file).
4. **No args** → continue to Phase 0.4 for resolution.

If `resolve.sh` exits non-zero from `--session-id` or `--pick`, fall through to Phase 0.4 (the user's chosen reference is stale; let them pick fresh).

## Phase 0.2: Detect the resume mode (post-clear vs post-compact)

`/clear` and `/compact` leave different wreckage, and the restore must match. Decide
the mode from signals already in front of you, with no tool calls:

| signal | post-clear (fresh session) | post-compact (same session) |
|---|---|---|
| conversation before /catchup | empty | a compaction summary survives |
| `[post-compact]` SessionStart injection | absent | present this session |
| live Task list | empty | still populated |
| ipc identity | new; the predecessor alias is dead | unchanged; peers still reach you |

Announce the mode in one line, then let it gate the later phases:

- **post-clear → FULL path.** Run every phase below as written.
- **post-compact → LIGHT path.** The session keeps its id, its Task list, and its
  ipc alias, so "restoring" them again duplicates live state. Run checkpoint
  resolution (the fresh `_precompact-checkpoint.claude.md` is usually the right
  target), the Phase 1.3/1.4 parse and reality drift, and the briefing. Three cuts
  apply:
  - **SKIP Phase 0.8's TaskCreate rehydration.** The live Task list survived
    compaction; re-creating workspace todos duplicates every open task. Read the
    workspace doc for drift only.
  - **SKIP Phase 3.1b entirely.** Your ipc identity is unchanged; no mail was
    orphaned by a compaction.
  - **Trust the checkpoint over the summary.** Compaction reliably preserves task
    momentum while stripping constraints, caveats, and the not-yet-approved state
    of gated actions. Where the compaction summary and the checkpoint's Resume
    Contract disagree, the Resume Contract wins, and every push/deploy/destructive
    approval is expired regardless of what the summary implies.

## Phase 0.3 — Direct Resolution (when `--session-id` or `--pick` was used)

The JSON entry returned by `resolve.sh` contains `checkpoint_path`, `project_root`, `name`, `summary`, `ts`. It may be preceded by a `note:` line on stderr (collision-preserved pointers exist) — parse only the `{…}` JSON object, or invoke with `2>/dev/null`. Run the Phase 0.4.4 validation + announce sequence on it (same checks as the picker path), then skip to Phase 1.3 (parse the checkpoint file).

## Phase 0.4 — Global Checkpoint Resolution (CHECK FIRST when CWD is `~/.claude/` OR no filename arg)

This phase exists to defeat the "stale `~/.claude/_checkpoint.claude.md` masquerading as project root" trap. After `/clear`, the new session's CWD often resets to `~/.claude/` rather than the project the previous session was working in. Without this phase, /catchup would Glob from `~/.claude/`, find a stale leftover checkpoint, and confidently load the wrong project's context.

### 0.4.1 — Decide whether to consult the global index

Consult `~/.claude/checkpoints/` when **any** of these conditions hold:

1. CWD is exactly `$HOME/.claude` (the global config dir — never a real project)
2. CWD does NOT contain a `.claude/` subdirectory (not in a project at all)
3. No `filename` argument was passed AND no `_checkpoint.claude.md` exists at the resolved project root

If the user passed an explicit `filename` argument, skip this phase — they've named the file they want.

### 0.4.2 — Try `--auto` resolution (single fresh entry)

```bash
~/.claude/scripts/checkpoint/resolve.sh --auto
```

Exit code meaning:
- `0` — exactly one checkpoint is fresh (<30 min); use it. Stdout is the JSON entry.
- `2` — multiple fresh entries OR no fresh entries but stale ones exist; **show picker** (next step).
- `3` — no checkpoints at all; fall through to Phase 0.5.

### 0.4.3 — Show picker (`mcp__inputs__pick_one`)

When `--auto` returned exit 2, render the list and prompt the user to pick:

```bash
~/.claude/scripts/checkpoint/list.sh --limit 8
```

This prints a numbered table with name / project / age / summary. Show that
table to the user AS PLAIN TEXT and ask for a number in the conversation, plus
"or paste an explicit checkpoint path". Never present this through
`mcp__inputs__pick_one` or any dialog tool: the inputs dialogs are unusable in
the owner's fullscreen TUI (memory `feedback_askuserquestion_tui_fullscreen`),
and a picker that hangs is a failed resume.

Resolve the typed number via `~/.claude/scripts/checkpoint/resolve.sh --pick <N>` and use that JSON entry; a pasted path is used directly.

### 0.4.4 — Validate and load

For whichever JSON entry was resolved (`--auto` or `--pick`):

- `checkpoint_path` exists on disk (project moved/deleted check)
- `project_root` is NOT `$HOME/.claude` (would re-trigger the trap)
- `ts` is younger than 7 days (older entries: warn but allow if user explicitly picked)

If valid, **announce clearly** before loading, in the same visual language the
briefing itself uses. `--no-seal` gives the header alone, since an announce opens
a run rather than closing one:

```bash
printf '{"session_id":"<name>","timestamp":"<ts>, <N>h ago",
         "status":"loading","project_root":"<project_root>",
         "checkpoint_path":"<checkpoint_path>"}' > /tmp/catchup-announce-<sid>.json
/bin/bash ~/.claude/scripts/render/trace.sh /tmp/catchup-announce-<sid>.json \
  --kind catchup --no-seal
```

With no tier data present, every tier is omitted and only the header renders.
Follow it with one plain line carrying the summary, and one more only when the
pick could be wrong:

```
<summary>
Wrong checkpoint? Re-run as: /catchup <explicit-filename>
```

Then read `checkpoint_path` directly and skip to **Phase 1.3** (parse). Do NOT continue to Phase 0.5 / 1.1 — those would re-find the wrong file.

### 0.4.5 — Back-compat fallback

`resolve.sh` already falls back to the legacy `~/.claude/_last-checkpoint.json` when the new index is empty. That fallback is removed in migration 0008 once all sessions have written to the new index at least once.

### 0.4.6 — CWD-trap hard-stop

If CWD is `$HOME/.claude` AND no entries exist in the index AND no `filename` arg was passed, **stop and ask** rather than scanning `~/.claude/` for `_*.claude.md` files. Print:

```
CWD is ~/.claude/ — this is the global config dir, not a project.
No entries in ~/.claude/checkpoints/index.jsonl either.

Options:
  1. cd to the project and re-run /catchup
  2. Pass an explicit checkpoint path: /catchup <filename>
```

Wait for user direction. Do NOT proceed to scan or load anything from `~/.claude/`.

---

## Phase 0.5 — Check WAL First (Fast Path)

Before looking for a checkpoint file, check if a Write-Ahead Log exists.
The WAL may be in either format — prefer JSONL, fall back to markdown:

1. **Try `.claude/wal.jsonl` first** (canonical format since 2026-04-17):
   - If found and **less than 24 hours old** (check `ts` of the last line):
     - Read the last checkpoint with:
       ```bash
       jq -c 'select(.kind == "checkpoint")' .claude/wal.jsonl | tail -1
       ```
     - **Validate before trusting.** WAL checkpoint entries are written by callers
       that sometimes shift or misname arguments (live example: a checkpoint whose
       `session_id` held the literal string `--goal`). Sanity-check the object:
       `goal` and `current` must be non-empty prose, and no field value may look
       like a flag token (`--goal`, `--done`, …). A malformed entry disqualifies
       the fast path: fall through to Phase 1 instead of presenting garbage.
     - Present `goal` / `done` / `current` / `next` / `blockers` fields from that object
     - **The WAL carries no Resume Contract.** Constraints, caveats, and expired
       authorizations live only in the checkpoint file. If any `_*.claude.md`
       checkpoint exists for this project, extract its `## Resume Contract` section
       (a targeted Grep, not a full read) and surface it in the briefing's NOW tier
       even on the fast path. The fast path saves the read of the checkpoint's
       narrative sections, never the contract.
     - Print: `Resumed from WAL (JSONL fast path). Last checkpoint at [ts].`
     - Skip directly to Phase 2 (targeted file loading), driving Phase 2 from the
       `next` field and any file paths referenced in recent `action` entries:
       ```bash
       jq -r 'select(.kind == "action" and .target) | .target' .claude/wal.jsonl | tail -20 | sort -u
       ```
2. **If `wal.jsonl` is missing, stale, or empty** — try `.claude/wal.md` (legacy):
   - Find the **last `=== CHECKPOINT ===` block**
   - Present Goal / Done / Current / Next / Blockers from the checkpoint
   - Print: `Resumed from WAL (legacy markdown fast path). Last checkpoint at [time].`
   - Skip directly to Phase 2 using the checkpoint's pending items
3. **If neither exists or both are stale (>24h)** — fall through to Phase 1 (checkpoint file).

This fast path avoids reading the larger `_checkpoint.claude.md` when the WAL has recent state.
Format reference: `skills/shared/wal-format.md`.

---

## Phase 0.8 — Read session workspace (if present)

Before the main checkpoint parse, read the resuming session's workspace doc. **Resolve it by session id, NOT via `_active.md`** — `session_id` is stable across resume, and multiple sessions can share a project dir, so the shared `_active.md` symlink may point at a *different* session's doc. Read `<notes-dir>/$CLAUDE_CODE_SESSION_ID.md` first; fall back to `_active.md` only if the session's own doc is absent. Its **Todos** (unchecked) and **Doc Links** are the most direct expression of "what the user was actually trying to do" and should anchor the briefing.

```bash
ND="$PROJECT/.claude/session-notes"; { [ "$PROJECT" = "$HOME/.claude" ] || [[ "$PROJECT" == */.claude ]]; } && ND="$PROJECT/session-notes"
DOC="$ND/${CLAUDE_CODE_SESSION_ID}.md"; [ -f "$DOC" ] || DOC="$ND/_active.md"
test -e "$DOC" && cat "$DOC"
```

When rendering the briefing in Phase 2, surface the workspace's unchecked Todos as the **immediate next steps** above (or in place of) the checkpoint's Pending Items. The workspace is the user-curated truth; the checkpoint is the agent's synthesis. When they disagree, the workspace wins.

**TaskList first, rehydrate only what is missing.** The Task store has survived /clear on every observed resume since early August (four consecutive by 2026-08-14), so a blind rehydration duplicates every open task. Call TaskList before creating anything: if the store is populated, read the workspace doc for drift only and add just the items genuinely absent. Only when the store is empty (fresh harness, expired store) recreate the unchecked Todos (the `## Todos` machine block plus any human-area items) via TaskCreate, so the session resumes with a populated, syncing task list rather than a stale doc.

Silently skip this phase if neither the session's own doc nor `_active.md` exists. (The `stop-sync` hook auto-creates `<sid>.md` once a session has more than a couple of tasks, so a substantive prior session will have left its own doc.)

## Phase 1 — Locate and Parse Checkpoint

### 1.1 Resolve filename

- If a `filename` argument was provided, use it.
- Otherwise default to `_checkpoint.claude.md`.

Use Glob to locate the resolved filename in the project root (the directory containing `.claude/`).

### 1.2 Handle missing file

If the file is **not found**:

1. Glob for all `_*.claude.md` files in the project root.
2. If matches exist: print the list and ask the user which one to use. Wait for their selection, then proceed with the chosen file.
3. If no `_*.claude.md` files exist at all: print a clear error and stop.

```
No checkpoint file found.
Run /core-dump first to create one, then re-run /catchup.
```

### 1.3 Parse the checkpoint

Read the checkpoint file. Extract the sections produced by `/core-dump`:

1. **Resume Contract** — the act-on-this-first block: standing constraints,
   standing caveats, next action, blocked-on, expired authorizations, decaying
   prerequisites, verification state, **live commitments**, **task store**, key
   anchor (the first two are absent on pre-2026-07-16 checkpoints, and the two
   bold ones on pre-2026-08-18 checkpoints; their absence there is normal)
2. **Initial Goal** — what the session was originally trying to accomplish
3. **Agent Actions** — sequential log of what was done (with file references)
4. **Current Expectation** — what the user expected to happen next at dump time
5. **Pending Items** — what still needs to be done
6. **Session Insights** — gotchas, dead ends, decisions, notes for future agents

Get the structural verdict mechanically before parsing by hand:

```bash
bash ~/.claude/scripts/checkpoint/validate-checkpoint.sh <file>          # full dumps
bash ~/.claude/scripts/checkpoint/validate-checkpoint.sh <file> --mini   # when line 1 is "# Mini Core Dump"
```

Mini dumps are a DIFFERENT shape by design: bold labels (Goal, Resume, Done,
Not Done, Next Steps), no H2 sections. Parse those labels; do not warn about
missing H2 headings on a mini. For full dumps, Resume Contract and Session
Insights are OPTIONAL on precompact / pre-2026-07 checkpoints and their absence
is normal. The middle four are mandatory: on a FAIL verdict, show the
validator's missing-list, warn the user, and present whatever content exists.
Do not fail silently, and do not refuse the resume; partial context beats none.

**Expired authorizations are binding:** anything the Resume Contract lists there
needs fresh user confirmation before you act on it — a checkpoint is never a
carrier of push/deploy/destructive-op approval across a clear or compact.

**Live commitments are re-armed, never merely displayed.** The goal, an armed
`/wake`, a live `/deadline`: these are what a `/clear` drops silently, and showing
them as narrative is what made the owner re-set the goal on every resume. Owner
ruling 2026-08-18: catchup "will either auto-re-arm it or ask the user to re-arm
it". So for each entry, do one of exactly two things, and never a third:

| entry | action |
|---|---|
| `goal: … · STILL VALID` | **Auto-re-arm, mechanically.** Run `bash ~/.claude/scripts/goal/goal.sh set "<text>" --by catchup` so the goal lives in the gcc store for THIS session id (the `37-goal-standing` hinter then re-injects it every 8 prompts while the harness `/goal` is not armed). State it back in one line and work under it. Then run `bash ~/.claude/scripts/goal/goal.sh box` and surface its output verbatim: one 🎯 structured box (heavy rail while the harness `/goal` is not armed, because only the owner can arm the Stop hook and it died with the old session), followed by the bare `/goal <text>` paste line between two double rules. That paste line is the owner-loved surface: keep it on ONE line with no rail character, so selecting it copies clean text. No question needed; the previous session already judged it. If the owner says not to, `goal.sh clear`. |
| `goal: none` (nothing was ever set) | **Propose one.** Read the task list (`bash ~/.claude/scripts/task-table/task-table.sh --compact`) and the Next action, draft a one-line goal, and print it as a paste line `/goal <proposed>` under the briefing. **Every clause must be one YOU can finish alone**, because an armed goal is a Stop condition and a clause whose actor is the owner blocks every stop until they disarm it by hand (vb-fable, six stop rounds, 2026-08-19). Put the agent half in the goal and the owner half in the briefing blocked-on row: draft X and put it to the owner, never take the owner review of X. Do NOT write it to the gcc store unasked; a proposal is the owner's to accept. |
| `goal: … · SUPERSEDED by …` | **Ask.** One line: the old goal, what superseded it, and whether the new one stands. |
| `wake: … · ARMED` | **Ask before re-arming.** A wake fires an action on a clock. Re-arming one the owner has moved on from is a side effect they did not order. |
| `deadline: … · LIVE` | **Ask.** Its burn projection and veto ledger belong to the run that set it; a resumed session inherits the commitment, not the accounting. |
| `crons: <duty (job, schedule)> …` | **CronList first; re-arm only what is absent.** CronCreate jobs are PROCESS-scoped: they survive /clear and /compact, and die only with the process. A checkpoint claiming a cron "died with the /clear" is wrong by construction. Run `CronList` and `bash ~/.claude/scripts/cron/cron-duty.sh list`; re-arm only duties missing from both, `record` what you arm, and delete any duplicate you find (the c2271ddc double check-in, 2026-08-21). |
| any `FIRED` / `MET` / `MISSED` / `none` | Say nothing. Spent commitments are not news. |

Never silently inherit, and never silently drop. Both failures look identical from
the outside, which is why the two-outcome rule is written as a table rather than a
preference.

Re-arming is not re-authorizing. A revived wake or deadline carries no push,
deploy, or destructive-op approval with it; those stay dead under Expired
authorizations regardless of what got re-armed.

**Task store:** when the contract names one, use it directly rather than
re-deriving it. `/tasks` otherwise resolves the store by content-matching task
subjects against the transcript, which is sound but is work the checkpoint already
did. Carry the id into the briefing so `/tasks` and the Todos mirror agree on
which store they mean. If the named store no longer exists on disk, say so and
fall back to content-match rather than rendering an empty list as if it were true.

**Standing constraints are binding scope fences:** surface them FIRST in the
briefing, restate them verbatim (never paraphrased), and re-read the relevant
entry before any change touching a surface it names. **Standing caveats transfer
debt:** repeat them verbatim in the briefing; never launder them into a rosier
summary — checkpoint compression dropping constraints and caveats while task
momentum survives is the documented cross-session drift engine
(`rules/invariant-graduation.md`, doc-22 + claude-ipc hardening evidence).

### 1.4 Cross-check against git reality (take with a grain of salt)

When the checkpoint is older than ~1 hour and `project_root` is a git repo,
snapshot present state before briefing:

```bash
cd "$PROJECT_ROOT" && git branch --show-current && git status --short | head -20 && git log -1 --oneline
```

Compare against the checkpoint's **Working surface** line and the edits claimed
in Agent Actions.

**"Grain of salt", defined:** a mismatch does NOT mean the checkpoint is wrong —
it means the world moved after the dump (another session, the user, a revert, a
merge). The checkpoint stays authoritative about what happened and what was
intended *at dump time*; git is authoritative about what is true *now*. On
mismatch: list each discrepancy in the briefing under **▸ Reality drift**,
re-verify any pending item that depends on the drifted surface before acting on
it, and never auto-reconcile — no reverts, no branch switches, no silently
assuming either side is the truth.

## Phase 2 — Extract File References

Scan the **Resume Contract**, **Agent Actions**, and **Pending Items** sections for file path references — tokens that look like file paths (contain `/`, end in `.ts`, `.tsx`, `.py`, `.md`, etc.).

Build an ordered reference list:

- The Resume Contract's **Key anchor** ranks first when present — it is by definition the single most load-bearing location
- Then rank paths that appear in **Pending Items** (most relevant to continuing work)
- Then paths from **Agent Actions** that relate to pending items
- Exclude paths from actions that are clearly already resolved

**Do not read any files yet.** This phase only builds the list.

Print the reference list so the user can see what will be loaded.

## Phase 3 — Present Briefing

### 3.0 Assemble first, render once

Phases 3.1b through 3.4 are **collectors**, not printers. Run them (ipc, targeted
file context, learnings, live subsystem state) before rendering, keeping any
intermediate output to one-line status notes. Then print ONE briefing. A briefing
that dribbles out across six tool calls buries the next action under scrollback;
the whole point of the resume surface is that the user reads a single screen.

### 3.1 Render the briefing in three tiers

The tiers are ordered by what the reader must do with them: **NOW** is binding
(act from it), **STATE** is situational (check what moved), **CONTEXT** is
optional (read if unfamiliar). Within a tier, omit any row with nothing to show.
`Next action` is the only mandatory row in the whole briefing; never render an
empty section header just to show the skeleton.

**Do not retype the layout.** Write the briefing data to
`/tmp/catchup-data-<session-id>.json` and render it:

```bash
/bin/bash ~/.claude/scripts/render/trace.sh /tmp/catchup-data-<session-id>.json --kind catchup
```

This is the same renderer `/core-dump` Phase 4 calls, so a briefing and the
record it came from read as one house style. The briefing wears a teal accent
against the dump's gold, so the two are never confused. A layout retyped by the
model drifts every run, which is the defect this call exists to remove.

The JSON keys, every one optional and omitted when empty:

```jsonc
{
  "session_id": "<checkpoint name>", "timestamp": "<age, e.g. 2h ago>",
  "status": "<post-clear FULL | post-compact LIGHT>",
  "project_root": "<absolute>", "checkpoint_path": "<file it came from>",
  "ipc": "<this session's ipc alias>", "model": "<model name>",

  // NEXT: one imperative; auth/blocked render as its one-line fence state
  "next_action": "<ONE imperative sentence, hard-capped to the imperative>",
  "blocked_on":  "<USER: … | external actor | omit when none>",
  "expired_auth":["<needs fresh user confirmation>"],

  // TODO: first-class, priority-classed. p: "now" (do first, usually the
  // next_action restated as row 1) | "ready" (agent can run it) | "gate"
  // (needs the owner) | "parked" (filed, not scheduled). Notes stay short.
  "todos": [{"p": "now|ready|gate|parked", "text": "<the item>", "note": "<short>"}],

  // FENCES: constraints + caveats + LIVE COMMITMENTS. head = 2-3 word bold label
  // the agent composes; body = the VERBATIM text (quotes carried as-is, never
  // paraphrased INSTEAD of; the head sits beside, not in place of).
  // Long caveat sets may roll into one fence whose body headlines each,
  // with the full text remaining in the checkpoint (owner ruling 2026-08-14).
  //
  // A live commitment rides here rather than in its own key, because a goal that
  // still holds binds the next step exactly the way a constraint does, and the
  // renderer's key list is fixed. Lead the fence list with them when present:
  //   {"head": "Goal in force",  "body": "<the goal, verbatim> · gcc re-armed · harness not armed, paste: /goal <text>"}
  //   {"head": "Wake armed",     "body": "<schedule> · re-arm? not yet asked"}
  //   {"head": "Deadline live",  "body": "<commitment> due <when> · re-arm? not yet asked"}
  // A goal marked STILL VALID is stated as in force, because it was auto-re-armed.
  // A wake or deadline is stated as PENDING YOUR CALL, because those are asked
  // rather than assumed. Spent commitments are omitted entirely.
  //
  // Same-work-stream atone prechecks also ride here (Phase 3.3 promotion rule):
  //   {"head": "🙏 precheck", "body": "<slug> (this work stream, <date>): <precheck, verbatim imperative>"}
  // Cap 2, newest first. Never rendered as Learnings; a recurrence-1 slug's only
  // carrier at resume time is the checkpoint, and its precheck binds like a fence.
  "fences": [{"head": "<2-3 words>", "body": "<verbatim>"}],

  // QUIET: merged to one line by the renderer
  "drift":    ["<checkpoint claim vs git-now, one per mismatch>"],
  "running":  ["<verified processes/ports only, never unverified claims>"],
  "mail":     ["<one per waiting message or orphan inbox>"],

  // CONTEXT: two rendered lines; the rest stays in the checkpoint
  "goal": "<one line>",
  "learnings": ["<2-4, highest continuation value first>"],
  "files": [{"path": "<ranked ref, anchor first>", "change": "<why it matters>"}]
}
```

Pre-redesign keys (`pipeline`, `constraints`, `caveats`, `decaying`) still
render, mapped into TODO ready-rows and FENCES respectively, so old data files
stay readable. **The height law (owner ruling 2026-08-14):** the whole briefing
fits one screen, roughly 44 lines (1.25x the ratified mock), so the task list
never scrolls away. Width is free. The renderer enforces this with loud
truncation rows ("… +N more in checkpoint"); never pre-trim silently to dodge
them, and never move detail out of the checkpoint file, which stays complete.

**Constraints and caveats go in verbatim.** The renderer reproduces the strings
it is given, so a paraphrase here is a paraphrase in the briefing, and that is
exactly how a constraint quietly stops binding across a resume.

Rendering rules:

1. **Nothing prints above NOW.** The header identifies the checkpoint (so a wrong
   pick is caught immediately); NOW is the first content the user reads.
2. **Constraints and Caveats stay verbatim** (never paraphrased) and always land
   in NOW when present. This is the anti-laundering rule from
   `rules/invariant-graduation.md`; it survives every render decision.
3. **Verification state** from the Resume Contract folds into `Next action` or
   `Drift` (whichever it qualifies) rather than getting its own row: "UNCONFIRMED,
   nothing run" belongs next to the action it taints.
4. **Budget CONTEXT to roughly a dozen lines.** The full checkpoint stays on disk;
   this tier is orientation, not a reproduction. Cite the checkpoint path once in
   the header region instead of quoting more of it.
5. **Pending rows are numbered by the renderer**, so pass `pipeline` in priority
   order and do not number the strings yourself. The Phase 4 hand-off asks
   "which item"; numbers make the answer a single keystroke.
6. **Snippets loaded in 3.2 do not appear in the briefing.** They are working
   context for you; the briefing cites the file:line and why it matters, one line
   each, under Key files.

### 3.1b ipc — register, peek, then answer what the predecessor owes

A resumed session is a NEW ipc identity. The alias peers were talking to died with
the old session, so anyone holding an unanswered query cannot reach you — and
because `send` carries a `--reply-by` contract, that sender gets chased and then
told nobody answered, for a question you are in fact now able to answer. Three
steps, all best-effort: a down broker skips silently and never blocks the briefing.

**1 — Be reachable.** The session-start ritual normally registers; re-running is a
harmless no-op and cheap insurance on a resumed session:

```bash
claude-ipc register <this-session-id>
```

**2 — Peek what is waiting** (non-consuming; the predecessor named by the
checkpoint is the first inbox worth opening):

```bash
claude-ipc inbox --project 2>/dev/null    # project mailbox for this cwd
claude-ipc orphans --project 2>/dev/null  # dead sessions here still holding mail
claude-ipc inbox <predecessor-alias> 2>/dev/null   # what your predecessor never answered
```

**3 — Close the loop on anything owed.** For each unanswered `query`/`request` in
the predecessor's inbox, reply on its correlation id — you inherit the obligation,
the sender is still waiting on it:

```bash
claude-ipc reply <corr-id> --from <this-session-id> <answer, or the hand-off>
```

Answer it if the checkpoint gives you the answer. If it does not, say exactly that —
that the predecessor ended and you have taken over as `<alias>` — so their chase
resolves instead of dangling. Use `snooze <msg-id> --as <alias>` if it is real work
you will do later (it stays pending + owed rather than vanishing).

Surface all of it in the briefing's `Mail` row: one line per
message/orphan (`kind from <alias>: <body head>` · `<dead-alias> holds N — peek:
claude-ipc inbox <dead-alias>`), and say which ones you answered. Post-compact
LIGHT path: this whole subsection is skipped (Phase 0.2).

### 3.2 Load targeted file context

For each file in the ranked reference list (Phase 2), load **only the relevant section** using Grep:

- If the action log cites a specific line or function: use Grep to extract ±10 lines around that reference
- If no specific location is cited: use Grep for the relevant symbol/function name
- Never read the full file — targeted context only

Keep the snippets as working context. In the briefing they surface only as
one-line `Key files` citations (path:line + why); never paste snippet bodies into
the briefing.

### 3.3 Load relevant runtime notes and checkpoint insights

Scan `.claude/skills/runtime-notes.md` for entries relevant to the task domain (match by skill names, file paths, or keywords mentioned in the checkpoint). Distill matches into the briefing's `Learnings` row, one line each and 2-4 max; these may prevent repeating past mistakes.

Fold the checkpoint's own **Session Insights** section (parsed in 1.3) into the same "Learnings" block: its gotchas and decisions were written by the session you're resuming and routinely carry the highest-value continuation context (model-routing choices, dead ends already explored, non-obvious traps).

Third source, the atone register: read `~/.claude/atone/derived/_tldr.txt` (skip silently if absent). Pick AT MOST 2 patterns whose precheck plausibly binds the checkpoint's next action or pending items, and fold each into Learnings as `🙏 watch · <slug> ×N: <the tie to this resume's work>`. The SessionStart lane already shows the whole register, so the briefing's only job is the tie to the work being resumed; an unrelated top pattern is noise here, not diligence.

**Same-work-stream atones are FENCES, never Learnings.** An atone event named in
the checkpoint's Session Insights (core-dump 2.5 records them) was filed by the
work stream you are resuming, and a slug at recurrence 1 is invisible in the
register BY CONSTRUCTION, which makes the checkpoint its only carrier at the
moment its precheck is cheapest to apply. A precheck is an imperative; a learning
is a fact; rendering the first as the second is how a session re-reads its own
wound as orientation and repeats it hours later (gcp-fable msg-7d2ea2ed,
mist-20260820-191749-17: the slug's first instance was parsed from the checkpoint
into Learnings, surfaced, and repeated the same day). So: for each atone event the
checkpoint names (cap 2, newest first), fetch its precheck text
(`bash ~/.claude/scripts/atone.sh show <id>`, or the checkpoint's own wording when
the ledger is unavailable) and render it as a Phase 3.1 `fences` row, head
`🙏 precheck`, body `<slug> (this work stream, <date>): <precheck, verbatim
imperative>`. These rows land in NOW with the constraints; they never appear as
`🙏 watch` Learnings, and they do not count against the register's 2-pick cap.
Register-wide picks stay in Learnings as before: a fresh wound beats a chronic
one, and the fence tier is the difference.

### 3.4 Surface live subsystem state

A resumed session loses awareness of what was *running* when the prior session ended — background servers, file watchers, long jobs. The shell-mem subsystem already records these; the checkpoint does not. Surface them so you don't relaunch a server that is already up, or assume a job that was mid-flight never ran.

```bash
# Background commands still marked active ([BG], not [BG:DONE]) in the last 2 days.
bash ~/.claude/scripts/shell-mem.sh shell-log-active

# If this resume follows a compaction, pre-compact-shell.sh appended a snapshot
# of the processes that were live at compaction time. Show the most recent block:
WAL="$HOME/.claude/wal.md"; [ -f "$WAL" ] || WAL="$PWD/.claude/wal.md"
[ -f "$WAL" ] && awk '/=== SHELL SNAPSHOT/{buf=""} {buf=buf $0 "\n"} /Resume with/{snap=buf} END{printf "%s", snap}' "$WAL"
```

If any active background processes are found, surface them in the briefing's **Running** row: list each command and its port if known. Do **not** assert a process is still running — verify the load-bearing ones (e.g. `lsof -ti :<port>` or a quick curl) before relying on or restarting them, since the prior session may have exited and taken its children with it. Silently skip this step when there is no active background state (the common case).

### 3.5 Contribute a gcc-improvement proposal (post-catchup, only when reusable friction surfaced)

Resuming is a uniquely good moment to spot improvements to `~/.claude` itself, because you have just loaded a wide slice of cross-session residue — the checkpoint, the WAL, the workspace, runtime-notes, the live subsystem state. Cross-session friction shows up here that an in-session reflection misses: the checkpoint format was missing something you needed, the prior session crashed for a reason worth guarding against, or `/catchup` / `/core-dump` themselves were rough.

Judge: did this resume surface a friction that is **(a) about the gcc itself** (not this project) **and (b) reusable**?

- **No** → skip silently. The common case — do not manufacture a contribution.
- **Yes** → file **exactly one** proposal, cross-linked to the residue that motivated it:

```bash
bash ~/.claude/scripts/propose.sh add \
  --title "<imperative — what to change in ~/.claude>" \
  --body  "<the friction surfaced during this resume · pointer · proposed fix>" \
  --category hooks|scripts|skills|config|docs|other \
  --effort  small|medium|large \
  --session "${CLAUDE_CODE_SESSION_ID:-}" \
  --tags    "src:post-catchup link:prop:<id> link:atone:<slug>"
```

Set only the `link:*` tags you actually have. Do not set a value/priority (computed at triage from corroboration). This must not delay the hand-off — it is a quick reflective check, not a research task. Skip silently if nothing reusable surfaced.

## Phase 3.6 — Render `/tasks`, below the briefing

Run the task table and show it. Every resume, not only when something looks
wrong.

```bash
bash ~/.claude/scripts/task-table/task-table.sh
```

Owner ask, 2026-08-18: *"Good to have: During core-dump or catchup (or after),
have the agent run /tasks and also suggest a new / update existing goal"*, and
again on 2026-08-19, *"Show me the /tasks"*. Before this phase existed the table
was run as a private collector whose rows were folded into the briefing's TODO
tier, which is not the same thing: the owner asked to see the store, and the
briefing shows the agent's reading of it.

**It goes BELOW the briefing, never inside it.** Both surfaces are capped at
roughly 44 lines, so a table nested in a briefing has to lose most of itself to
fit, and what it loses is the row detail that made the shape worth ratifying.
Two surfaces, each whole, beats one surface with both halves crushed.

Resolve the store from the Resume Contract's **Task store** field, not by
content-match. A resumed session's own transcript matches nothing, so the
resolver correctly refuses and lists candidates; the contract already holds the
answer:

```bash
bash ~/.claude/scripts/task-table/task-table.sh --session <sid8-from-the-contract>
```

Use `--session`, not `--pin`. `--pin` writes the live-session mapping and exits
without rendering anything, so an agent following this phase with `--pin` shows
the owner no table at all. Pin separately if you want the bare command to work
for the rest of the session.

Render it as the tool prints it. Constraint, owner 2026-08-19 via gcp-fable:
every `/tasks` run in every session renders the ratified batched-sequence shape
(GOAL › BATCH bands, lane·tier, state glyphs, GATES first, legend of lanes).
Do not hand-render, do not re-summarise, do not re-sort it into prose.

Two cases where this phase says something short instead of a table:

- **No store resolves and the contract named none.** One line saying so. Do not
  guess a store; a confident wrong table is the defect the resolver's refusal
  exists to prevent.
- **The named store is gone from disk.** `--session` refuses: it exits 3, says
  the sid names no store, and prints the candidates. Read the refusal and pick,
  or say in one line that the contract's store is gone. Do not fall back to the
  bare command hoping for the best, which renders the pin under a header naming
  a store you did not ask for.

Read the header back either way. The `session-<sid8>` it prints must be the sid
the Resume Contract named, because a table that is right about itself and wrong
about your question is the hardest kind to catch (`rules/testing.md`
`[trust-the-tool-not-blind-to-it]`).

## Phase 4: hand off

**The Phase 3.1 render is the hand-off.** Do not print a separate "context
restored" box under it. Exactly two things follow it, in this order: the Phase
3.6 `/tasks` table, then the re-arm surface. Nothing else. The re-arm surface
earns its place because it is for the owner to paste, not to read: the
`goal.sh box` output
(🎯 box plus the bare `/goal <text>` line between double rules), and, only when the
checkpoint's Re-arm block carried them, `/wake …` and `/deadline …` as bare lines.
The same one-line paste surface is welcome, unprompted, at the end of a long planning
session or a catchup onto a long-running plan (owner, 2026-08-18: "I LOVE it"). The briefing's own seal already closes the document, and
a plain ASCII block underneath undoes the visual and is the last thing the user
reads.

Then ask:

```
Which pending item should we start with? (number from the Pending list, or say)
→
```

When the owner picks one, the first move on it is `/router:intake` (owner ruling
2026-08-27, skills-0826 D1a: the routers are the default hand-off), so the ask is
modelled before any file is touched.

```
```

Wait for the user's response before beginning any work. Do not make assumptions about priority or start executing autonomously.

## Notes

- **Input contract:** expects the `_*.claude.md` format written by `/core-dump`. Sections are identified by `## Resume Contract`, `## Initial Goal`, `## Agent Actions`, `## Current Expectation`, `## Pending Items`, `## Session Insights` headings (first and last optional on mini/precompact/older dumps).
- **The tier order is deliberate:** NOW → STATE → CONTEXT. The user knows their goal; they need the next action and its fences first, situation second, orientation last.
- **Targeted Grep over full Read:** reduces token usage for large referenced files. The checkpoint's agent actions log provides enough location context (file + symbol) to scope the Grep correctly.
- **Do not begin work autonomously:** always hand off with a question. The user may want to reprioritize or provide new context before continuing.
- **Malformed checkpoint:** if sections are missing, warn but do not stop — partial context is better than none.
- **Post-run:** write a runtime-notes entry via `prepend-runtime-note.sh` as per GUIDELINES.md §7.
