---
name: gcc-proposal
description: Files a ~/.claude improvement proposal into the backlog via propose.sh — derives the title, category, effort, and cross-links from a rough description or from the current conversation, so you never have to remember the script or its flags.
allowed-tools: Bash, Read
user-invocable: true
argument-hint: "[rough description of the improvement]"
---

## Brief

Low-friction filing into the gcc proposals backlog. Say `/gcc-proposal <rough idea>` — or
nothing at all right after a friction moment — and it formalizes the idea, files it via
`propose.sh`, and prints the receipt id. Filing only; review and promote/drop decisions
live in `/backlog-triage`.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after. Never write to `runtime-notes.md` or any SKILL.md without
> holding its lock.

## Usage

```
/gcc-proposal [rough description of the improvement]
```

| Argument            | Type     | Description                                                                                                                                  |
| ------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `rough description` | optional | The improvement idea, however rough. Omit it right after a friction moment and the skill derives the proposal from the current conversation. |

## Phase 1 — Gather

1. Take the idea from the arguments. If empty, derive it from the current conversation:
   the most recent friction, lesson, or "we should really…" moment. If neither yields a
   concrete idea, ask once: "What's the improvement to file?"
2. Collect cross-links present in nearby context — session id
   (`$CLAUDE_CODE_SESSION_ID`), related atone slugs, prior proposal ids, file pointers.
   None are required; take what's there.
3. Sanity check: is this actually about `~/.claude` itself (a hook, script, skill,
   config, doc, convention) and reusable? A project-local fix or a one-off task is NOT a
   gcc proposal — say so and stop instead of polluting the backlog.

## Phase 2 — Formalize

Shape the raw idea into the backlog's format:

- **Title**: imperative, ≤80 chars ("Add X to Y", "Guard Z against W").
- **Body**: the friction observed · a pointer (file, incident, session) · the proposed
  fix. Two to four sentences.
- **Category**: one of `hooks | scripts | skills | config | docs | other`.
- **Effort**: `small | medium | large`.
- Never set value/priority fields — those are computed at triage from corroboration.

## Phase 3 — File

- **Arguments were given** → file immediately (the user already said what they want):

  ```bash
  bash ~/.claude/scripts/propose.sh add \
    --title "<title>" --body "<body>" \
    --category <category> --effort <effort> \
    --session "${CLAUDE_CODE_SESSION_ID:-}" \
    --tags "src:gcc-proposal-skill[ link:atone:<slug>][ link:prop:<id>]"
  ```

- **Derived from context** → show the formalized title + one-line body first, confirm
  once ("File this? (yes / tweak)"), then run the same command.

One proposal per invocation. Never hand-edit `~/.claude/proposals.jsonl` — the script is
the only writer.

## Phase 4 — Verify

`propose.sh` prints the receipt (`✓ filed prop-…`) — that IS the verification. Echo the
id and title back to the user. If the script exited non-zero, show its stderr verbatim
and stop; do not retry blind.

## Notes

- Sibling: `/backlog-triage` reviews and promotes/drops filed proposals — this skill
  never does.
- Agents working mid-task should keep calling `propose.sh` directly (30 seconds, no
  ceremony); this skill exists so the HUMAN never has to remember the script's name or
  flags.
- The backlog is append-only; a badly-scoped proposal is cheap (triage drops it), but a
  non-gcc idea (project-local fix) should be refused in Phase 1, not filed.
