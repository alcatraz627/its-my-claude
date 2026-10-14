# /catchup reference

Detailed procedures `SKILL.md` points to. They change rarely and most resumes never
reach them, so they live here instead of in the skill text every resumed session
carries. Where this file and `SKILL.md` disagree, `SKILL.md` wins: it holds the
2026-10-13 rulings (goals are offered, never re-armed; Standing authorizations carry
over; agent-side work continues without asking).

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
    Contract disagree, the Resume Contract wins, and Standing authorizations
    carry over as the Resume Contract lists them (SKILL.md).

## Phase 0.3: Direct Resolution (when `--session-id` or `--pick` was used)

The JSON entry returned by `resolve.sh` contains `checkpoint_path`, `project_root`, `name`, `summary`, `ts`. It may be preceded by a `note:` line on stderr (collision-preserved pointers exist). Parse only the `{…}` JSON object, or invoke with `2>/dev/null`. Run the Phase 0.4.4 validation + announce sequence on it (same checks as the picker path), then skip to Phase 1.3 (parse the checkpoint file).

## Phase 0.4: Global Checkpoint Resolution (CHECK FIRST when CWD is `~/.claude/` OR no filename arg)

This phase exists to defeat the "stale `~/.claude/_checkpoint.claude.md` masquerading as project root" trap. After `/clear`, the new session's CWD often resets to `~/.claude/` rather than the project the previous session was working in. Without this phase, /catchup would Glob from `~/.claude/`, find a stale leftover checkpoint, and confidently load the wrong project's context.

### 0.4.1: Decide whether to consult the global index

Consult `~/.claude/checkpoints/` when **any** of these conditions hold:

1. CWD is exactly `$HOME/.claude` (the global config dir, never a real project)
2. CWD does NOT contain a `.claude/` subdirectory (not in a project at all)
3. No `filename` argument was passed AND no `_checkpoint.claude.md` exists at the resolved project root

If the user passed an explicit `filename` argument, skip this phase. They've named the file they want.

### 0.4.2: Try `--auto` resolution (single fresh entry)

```bash
~/.claude/scripts/checkpoint/resolve.sh --auto --cwd "$PWD"
```

Exit code meaning:
- `0`: exactly one checkpoint is fresh (<30 min); use it. Stdout is the JSON entry.
- `2`: multiple fresh entries OR no fresh entries but stale ones exist; **show picker** (next step).
- `3`: no checkpoints at all; fall through to Phase 0.5.

`--cwd` is what stops the two confident-wrong resumes of 2026-09-07 (ledger 4
and 25): the project you sit in wins a tie between fresh entries, a shell-only
snapshot (precompact or session-end) never wins outright when a real core-dump
for that project exists at any age, and `_*.claude.md` files on disk in the cwd
that the index never saw make `--auto` defer to the picker instead of serving
another project's entry over them.

### 0.4.3: Show picker (`mcp__inputs__pick_one`)

When `--auto` returned exit 2, render the list and prompt the user to pick:

```bash
~/.claude/scripts/checkpoint/list.sh --limit 8 --cwd "$PWD"
```

This prints a numbered table with name / project / age / summary, in three
blocks: this project's indexed entries first, then checkpoint files on disk in
the cwd that the index never saw (each with its absolute path, since those are
picked by path, not by number), then other projects. The numbers stay global
newest-first so they line up with `resolve.sh --pick N`. Show that
table to the user AS PLAIN TEXT and ask for a number in the conversation, plus
"or paste an explicit checkpoint path". Never present this through
`mcp__inputs__pick_one` or any dialog tool. Plain text stays the default even
though the old fullscreen ban on AskUserQuestion is retired (memory
`feedback_askuserquestion_tui_fullscreen`, re-verified working 2026-08-20): a
resume must never hang on a dialog surface, and the inputs-MCP dialogs carry no
equivalent re-verification on record. That memory is about AskUserQuestion,
not them. A picker that hangs is a failed resume.

Resolve the typed number via `~/.claude/scripts/checkpoint/resolve.sh --pick <N>` and use that JSON entry; a pasted path is used directly.

### 0.4.4: Validate and load

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

Then read `checkpoint_path` directly and skip to **Phase 1.3** (parse). Do NOT continue to Phase 0.5 / 1.1. Those would re-find the wrong file.

### 0.4.5: Back-compat fallback

`resolve.sh` already falls back to the legacy `~/.claude/_last-checkpoint.json` when the new index is empty. That fallback is removed in migration 0008 once all sessions have written to the new index at least once.

### 0.4.6: CWD-trap hard-stop

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

## Phase 0.5: Check WAL First (Fast Path)

Before looking for a checkpoint file, check if a Write-Ahead Log exists.
The WAL may be in either format. Prefer JSONL and fall back to markdown:

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
2. **If `wal.jsonl` is missing, stale, or empty**, try `.claude/wal.md` (legacy):
   - Find the **last `=== CHECKPOINT ===` block**
   - Present Goal / Done / Current / Next / Blockers from the checkpoint
   - Print: `Resumed from WAL (legacy markdown fast path). Last checkpoint at [time].`
   - Skip directly to Phase 2 using the checkpoint's pending items
3. **If neither exists or both are stale (>24h)**, fall through to Phase 1 (checkpoint file).

This fast path avoids reading the larger `_checkpoint.claude.md` when the WAL has recent state.
Format reference: `skills/shared/wal-format.md`.

---

## Phase 0.8: Read session workspace (if present)

Before the main checkpoint parse, read the resuming session's workspace doc. **Resolve it by session id, NOT via `_active.md`**. `session_id` is stable across resume, and multiple sessions can share a project dir, so the shared `_active.md` symlink may point at a *different* session's doc. Read `<notes-dir>/$CLAUDE_CODE_SESSION_ID.md` first; fall back to `_active.md` only if the session's own doc is absent. Its **Todos** (unchecked) and **Doc Links** are the most direct expression of "what the user was actually trying to do" and should anchor the briefing.

```bash
ND="$PROJECT/.claude/session-notes"; { [ "$PROJECT" = "$HOME/.claude" ] || [[ "$PROJECT" == */.claude ]]; } && ND="$PROJECT/session-notes"
DOC="$ND/${CLAUDE_CODE_SESSION_ID}.md"; [ -f "$DOC" ] || DOC="$ND/_active.md"
test -e "$DOC" && cat "$DOC"
```

When rendering the briefing in Phase 2, surface the workspace's unchecked Todos as the **immediate next steps** above (or in place of) the checkpoint's Pending Items. The workspace is the user-curated truth; the checkpoint is the agent's synthesis. When they disagree, the workspace wins.

**The goal record first; never rehydrate rows into the Task tool from a doc (D1, 2026-09-23).** Read the Resume Contract's **Goal record** id; resume-gather already prints the record's open rows and unread handoff notes for it. Do NOT run `gs link <id>` yourself: linking arms the standing-goal hinter, which is re-arming a goal (owner ruling 2026-10-13). Offer `gs link <id>` next to the `/goal` paste line instead. That is the truth across sessions; the workspace Todos block and the checkpoint's Pending Items are derived from it and are read for drift only. The agent's own Task-tool checklist may be rebuilt from the goal's open rows if the harness has the tool and the list is empty, but the record is what the owner reads. With no goal id in the contract, propose one (Phase 3.5) rather than inventing rows.

Silently skip this phase if neither the session's own doc nor `_active.md` exists. (The `stop-sync` hook auto-creates `<sid>.md` once a session has more than a couple of tasks, so a substantive prior session will have left its own doc.)

### 1.2 Handle missing file

If the file is **not found**:

1. Glob for all `_*.claude.md` files in the project root.
2. If matches exist: print the list and ask the user which one to use. Wait for their selection, then proceed with the chosen file.
3. If no `_*.claude.md` files exist at all: print a clear error and stop.

```
No checkpoint file found.
Run /core-dump first to create one, then re-run /catchup.
```

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
  "standing_auth":["<grant, verbatim, as the Resume Contract lists it>"],
  "expired_auth":["<legacy checkpoints only: needs fresh confirmation>"],
  "done":["<what landed, as of dump unless re-checked; max 6>"],

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
  //   {"head": "Goal in force",  "body": "<the goal, verbatim> · not armed; paste /goal <text> to arm"}
  //   {"head": "Wake armed",     "body": "<schedule> · re-arm? not yet asked"}
  //   {"head": "Deadline live",  "body": "<commitment> due <when> · re-arm? not yet asked"}
  // A goal is only ever offered (owner ruling 2026-10-13); catchup never arms it.
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

1. **DONE, then NOW.** The header identifies the checkpoint (so a wrong pick is
   caught immediately); the short DONE list comes first, then NEXT and its fences.
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
   order and do not number the strings yourself. Numbers let the owner redirect with
   a single keystroke; the hand-off itself does not ask "which item" (SKILL.md Phase 4).
6. **Snippets loaded in 3.2 do not appear in the briefing.** They are working
   context for you; the briefing cites the file:line and why it matters, one line
   each, under Key files.

### 3.1b ipc: register, peek, then answer what the predecessor owes

A resumed session is a NEW ipc identity. The alias peers were talking to died with
the old session, so anyone holding an unanswered query cannot reach you, and
because `send` carries a `--reply-by` contract, that sender gets chased and then
told nobody answered, for a question you are in fact now able to answer. Three
steps, all best-effort: a down broker skips silently and never blocks the briefing.

**1. Be reachable.** The session-start ritual normally registers; re-running is a
harmless no-op and cheap insurance on a resumed session:

```bash
claude-ipc register <this-session-id>
```

**2. Peek what is waiting** (non-consuming; the predecessor named by the
checkpoint is the first inbox worth opening):

```bash
claude-ipc inbox --project 2>/dev/null    # project mailbox for this cwd
claude-ipc orphans --project 2>/dev/null  # dead sessions here still holding mail
claude-ipc inbox <predecessor-alias> 2>/dev/null   # what your predecessor never answered
```

**3. Close the loop on anything owed.** For each unanswered `query`/`request` in
the predecessor's inbox, reply on its correlation id. You inherit the obligation,
the sender is still waiting on it:

```bash
claude-ipc reply <corr-id> --from <this-session-id> <answer, or the hand-off>
```

Answer it if the checkpoint gives you the answer. If it does not, say exactly that:
the predecessor ended and you have taken over as `<alias>`, so their chase
resolves instead of dangling. Use `snooze <msg-id> --as <alias>` if it is real work
you will do later (it stays pending + owed rather than vanishing).

Surface all of it in the briefing's `Mail` row: one line per
message/orphan (`kind from <alias>: <body head>` · `<dead-alias> holds N, peek:
claude-ipc inbox <dead-alias>`), and say which ones you answered. Post-compact
LIGHT path: this whole subsection is skipped (Phase 0.2).

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

A resumed session loses awareness of what was *running* when the prior session ended: background servers, file watchers, long jobs. The shell-mem subsystem already records these; the checkpoint does not. Surface them so you don't relaunch a server that is already up, or assume a job that was mid-flight never ran.

```bash
# Background commands still marked active ([BG], not [BG:DONE]) in the last 2 days.
bash ~/.claude/scripts/shell-mem.sh shell-log-active

# If this resume follows a compaction, pre-compact-shell.sh appended a snapshot
# of the processes that were live at compaction time. Show the most recent block:
WAL="$HOME/.claude/wal.md"; [ -f "$WAL" ] || WAL="$PWD/.claude/wal.md"
[ -f "$WAL" ] && awk '/=== SHELL SNAPSHOT/{buf=""} {buf=buf $0 "\n"} /Resume with/{snap=buf} END{printf "%s", snap}' "$WAL"
```

If any active background processes are found, surface them in the briefing's **Running** row: list each command and its port if known. Do **not** assert a process is still running. Verify the load-bearing ones (e.g. `lsof -ti :<port>` or a quick curl) before relying on or restarting them, since the prior session may have exited and taken its children with it. Silently skip this step when there is no active background state (the common case).

## Phase 3.6: Render `/tasks` below the briefing

Run the task table and show it. Every resume, not only when something looks
wrong.

```bash
python3 ~/.claude/scripts/goals/views/path.py
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

Catchup does not link the session to the goal (Phase 0.8), so pass the contract's
goal id: `python3 ~/.claude/scripts/goals/views/path.py --goal <id-from-the-contract>`.
With no goal id, the bare command shows live goals touching the CWD repo. There is
no store to resolve and nothing to pin.

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

