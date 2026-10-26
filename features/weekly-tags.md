---
brief: A weekly tag is a note queued for the owner's Tuesday weekly gcc session, in ~/.claude/handoffs/tags/. Written with handoff.sh tag (frontmatter fields title, kind, after, times, domain, sessions, reply-to, refs), listed with handoff.sh tags, closed after handling with handoff.sh close-tag, which counts down, re-dates and tells reply-to.
triggers:
  - tool:handoff.sh
  - topic:weekly-session
  - topic:weekly-review
  - phrase:"add to the weekly review"
  - phrase:"next weekly session"
related:
  - scheduled/weekly-session-brief.md
  - scripts/schedule/handoff.sh
  - features/work-focus-identity.md
tier: 2
category: features
updated: 2026-10-26
stale_after_days: 120
---

# Weekly tags: notes for the owner's weekly session

The weekly gcc session (Tuesdays 09:00, a card the owner starts when ready) has
fixed upkeep steps and one variable step: every tag file in
`~/.claude/handoffs/tags/`. A tag is how any session or job says "bring this to
the owner at the weekly session" without interrupting them now.

## Writing one

```
bash ~/.claude/scripts/schedule/handoff.sh tag "<what to do and what to show the owner>" \
  --title "<one line>" --kind decide --times 2 --after 2026-11-02 \
  --domain gcc --reply-to <alias | project path | msg-id> --ref <commit, file, proposal>
```

The note body says what the session should do and what the owner needs to see
to decide. Write it for a session that knows nothing about the work.

| Field | Meaning | Default |
|---|---|---|
| `title` | one line the listing shows | first line of the note |
| `kind` | `review` (look and report), `decide` (needs the owner's call), `do` (the session just does it), `fyi` (tell the owner, nothing owed) | `review` |
| `after` | not before this date; the session leaves it alone until then | none, due now |
| `times` | how many weekly sessions should see it; each close counts down and re-dates it a week out | 1 |
| `domain` | the area it belongs to: `gcc`, a project name, a skill | none |
| `sessions` | the session that tagged it, with its ipc alias when it had one | filled in |
| `reply-to` | who hears the outcome: an ipc alias, a project path (its mailbox waits for any session there), or a message id to reply on | none |
| `refs` | commits, files, proposal ids the session should open | none |
| `created` | when it was tagged | filled in |

## Handling them (the weekly session)

1. `handoff.sh tags` lists them, due ones first.
2. For each due tag: do it, or put it to the owner as a decision.
3. `handoff.sh close-tag <file> "<outcome in one line>"`. A tag with `times`
   left stays, re-dated a week out, with the outcome appended so the next
   session sees the history. The last close trashes it. If `reply-to` is set,
   the outcome goes there through claude-ipc, best effort.

## Why these fields

The format grew from what the neighbouring systems taught. Proposals carry a
reason on every close, so a tag carries its outcome. Decision pages carry an
origin (session, project) so an answer can find its asker, so a tag carries
`sessions` and `reply-to`. The first real use was a review the owner wanted on
two consecutive weeks, which one-shot notes could not express without a second,
future-dated file; `times` and `after` cover that. Left out on purpose: a
priority field (the session does every due tag anyway) and an owner field (the
owner is always the audience).
