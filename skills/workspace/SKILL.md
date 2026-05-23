---
name: workspace
description: Manage per-session workspace docs at <project>/.claude/session-notes/<session-id>.md. Each serious session has its own Todos, Notes, Doc Links, and Decisions file that survives /clear and /compact. Read by /catchup at resume time, updated by /core-dump (with diff-confirm — never blind overwrite), and feeds the cross-session forgotten-todos surfacing. Use /workspace to create a workspace, open the current one, or list workspaces in this project.
allowed-tools: Read, Write, Edit, Bash, Glob
argument-hint: "[init | show | list | open]"
user-invokable: true
---

## Brief

A workspace doc is a session-scoped Todos/Notes/Doc-Links/Decisions file at `<project>/.claude/session-notes/<session-id>.md`. It persists across `/clear` and `/compact`. The `_active.md` symlink always points at the currently-active session's doc, so other skills (`/catchup`, `/core-dump`) can find it without knowing the session-id.

Where it slots in:
- **`/core-dump`** reads `_active.md`, synthesizes proposed updates (todos done, new todos, notes append, doc links, decisions), shows a diff to the user, applies on confirmation. Never blind overwrite.
- **`/catchup`** reads `_active.md` first when restoring. Surfaces Todos prominently as the immediate next steps.
- **`/forgotten-todos`** ingests Todos via the dream pipeline → cross-session unfinished-todo surfacing.

## When to use

- Starting a "serious" session — manually invoke `/workspace init` to create the doc up front
- Auto-trigger: `/core-dump` will auto-create on its first run for a session if `--init-workspace` is passed or the session has >20 turns
- Browsing: `/workspace list` to see what's stacked up in this project

## Usage

```
/workspace init                  # create workspace doc for the current session
/workspace show                  # print the _active.md contents
/workspace list                  # list all session-notes in this project
/workspace open                  # open _active.md in $EDITOR
```

## Phase 1 — Parse subcommand

Default is `show` if no arg.

## Phase 2 — Resolve project + session-id

- Project = CWD if CWD has `.claude/`, else error out
- Session-id = `$CLAUDE_CODE_SESSION_ID` (env), or fall back to today's checkpoint name if available

## Phase 3 — Dispatch

### `init`

```bash
~/.claude/scripts/session-notes/create.sh \
  --session-id "$SESSION_ID" \
  --project    "$PROJECT" \
  --name       "${NAME:-$SESSION_ID}"
```

Prints the absolute path to the new doc. Refresh `_active.md` symlink.

### `show`

```bash
cat "$PROJECT/.claude/session-notes/_active.md"
```

If no `_active.md` → print "no workspace yet. Run /workspace init to create one."

### `list`

```bash
ls -lt "$PROJECT/.claude/session-notes/"*.md 2>/dev/null | head -20
```

Render as a table with session-id, mtime, todo count.

### `open`

```bash
"${EDITOR:-vi}" "$PROJECT/.claude/session-notes/_active.md"
```

## Integration contract

For `/core-dump` to update the workspace, it should:

1. After Phase 2 (synthesis), check for `<project>/.claude/session-notes/_active.md`
2. If present, build a JSON proposal:
   ```json
   {
     "todos_done":    ["…"],   // from Phase 2 "Done" section
     "todos_new":     ["…"],   // from Phase 2 "Pending Items"
     "notes_append":  ["…"],   // selected new observations
     "doclinks_new":  ["…"],   // new URLs / file refs the session worked against
     "decisions_new": ["…"]    // load-bearing choices from Phase 2.5
   }
   ```
3. Run `scripts/session-notes/diff.sh` to print the proposed diff
4. Present `mcp__inputs__confirm` with three options: `apply` / `edit` / `skip`
5. On `apply`: run `scripts/session-notes/apply.sh` with the same JSON
6. On `edit`: write the JSON to a tmp file, open `$EDITOR`, re-read, apply
7. On `skip`: do nothing

For `/catchup` to read the workspace:

1. After resolving project_root, check for `_active.md`
2. If present, read it BEFORE the checkpoint file
3. Surface the unchecked Todos section as the immediate-next-steps briefing

## Notes

- `_active.md` is a symlink with a RELATIVE target (`<session-id>.md`), so it survives project moves
- Per-project location was chosen over a global `~/.claude/sessions/notes/` farm — keeps the artifacts with the project's git history (user can choose to commit them)
- Dedupe heuristic when /core-dump proposes the same todo twice: lowercase + whitespace-collapse comparison; apply.sh treats existing-checked items as no-op
- Diff/apply are pure shell+Python — no LLM call. Cost-free.
