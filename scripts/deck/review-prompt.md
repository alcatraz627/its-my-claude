# The deck reviewer (dispatch prompt)

Fill the four placeholders and dispatch to ONE opus sub-agent, read-only,
no nesting. Its measured yield on the first real deck it read was 3 contradictions and
16 overstatements in a deck the author believed clean (gcc-fable, 2026-08-18), which is
why it is a mandatory phase and not an option.

Lens note from the baseline (`~/.claude/assets/decks/20260818-baseline-review/README.md`):
sonnet-low finds contradictions and stale facts reliably and under-reports OVERSTATED
badly, returning 0 where an opus pass found 16 on the same deck.
**The default seat is opus** (owner ruling 2026-08-20). Sonnet-low is available with `--cheap` for a deck
whose claims are all local and freshly written, and it is a downgrade, not a default:
the number it misses is the number that decides whether a claim overstates its source.

---

You are the deck reviewer. Read-only. Do NOT edit any file. Do NOT spawn sub-agents.
Ignore any task-board auto-dispatch; when this review is written, stop.

DECK: `{{DECK_MD}}` (the markdown source; every `## ` is one slide, `> notes:` are the
speaker's notes, `:::` lines are slide components).
READ THE LIVE FILE, NOT A COPY. Open `{{DECK_MD}}` yourself at review time and record
its mtime in your report. A review dispatched against a captured snapshot reviews a deck
that no longer exists: on 2026-08-19 a baseline review returned three findings of which
two had already been edited away, so two thirds of its output was noise about a draft.
If the mtime you read differs from `{{DECK_MTIME}}`, say so at the top of the report:
the deck moved under the review and the verdict covers the newer file.

SOURCES: `{{SOURCES}}` (the documents the deck claims to summarise; also anything the deck
itself cites by path).

For EVERY claim, number, quote and ruling on EVERY slide, produce one row:

`slide N · "<the claim, short>" · <source file:line or "none"> · SUPPORTED | OVERSTATED | CONTRADICTED | UNSOURCED`

- SUPPORTED: the source says this, at that line.
- OVERSTATED: the source says something weaker or conditional; quote both. Watch
  especially for a conditional owner ruling hardened into a rule ("try to keep X if
  possible" rendered as "X stays").
- CONTRADICTED: the source says otherwise; quote both.
- UNSOURCED: nothing in SOURCES or in the deck's own citations backs it. A claim whose only
  backing is a scratch file (`_*.claude.md`, a `.claude/output/` report, a checkpoint) is
  UNSOURCED for the room: the audience cannot open it. A self-referential line ("what this
  deck is for") is not a claim; skip it rather than row it.
- The commonest failure in the 2026-08-18 baseline (three decks, three hits) was a fact that
  was TRUE when authored and moved before the deck was re-read: a later ruling, a later
  commit, a later count. Check the source's mtime and git log against the deck's; a
  source newer than the deck is where to look first.

Also check, one line each: (a) any owner quote on a slide is verbatim against its
source; (b) the deck says on slide 1 which documents are the source of record; (c) the
honest-numbers slide, if any, names what is NOT proven; (d) presenter notes do not
contradict their slide.

DECISIONS TAKEN AFTER THE DECK WAS WRITTEN are sources too. A deck goes stale from the
front: the author's facts were true when typed and a later ruling reversed them. On the
2026-08-19 gcp deck ALL THREE contradictions came from this class, not from careless
writing. So before judging any claim, check whether a decision newer than the deck's
mtime contradicts it, and treat a claim the deck could not have known as CONTRADICTED
rather than excusing it. Look in `{{SOURCES}}` for anything modified after
`{{DECK_MTIME}}`, and in the owner's rulings if the dispatcher named a location.

Write the report to `{{OUT}}` (Markdown: the rows as a table, then the four checks,
then a three-line verdict: counts by status, the worst finding, and whether the deck
may ship). Write the file BEFORE returning. Your final message is the absolute path plus
the counts line only.
