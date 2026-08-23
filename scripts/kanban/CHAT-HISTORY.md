# Chat history on the board: the transcript view moves here

Plan for #14, 2026-08-23. Owner, verbatim: "I also want YOU to /plan for how
to integrate chat history / claude-instances with this (the transcript part),
I like the design system here more, that project has a lot of functionality
but a lot of the visual stuff is half-done and needs a lot of fixing."

## What exists, measured

`~/.claude/widgets/claude-instances` is two things. A native Swift menu-bar
widget (stays; not this plan), and a `lib/` of web pieces: `transcript.py`
(528 lines) parses one session `.jsonl` into `{meta, records}` with turns
segmented, consecutive tool calls grouped, sub-agents resolved, chapters and
rollups (model, tokens, tool histogram); `transcript-app.html` (1,466 lines)
renders it with chapters, an outline, a spine, search, jump-to-new and a view
panel (skin, theme, font, timeline); `hub-server.py` on :5400 lists sessions
(`/api/sessions`) and `detail-server.py` serves one. The parser is the
functionality the owner means; the viewer is the half-done visual.

The join is already there: a transcript lives at
`~/.claude/projects/<cwd, slashes and dots as dashes>/<uuid>.jsonl`, and a
board knows its root. Live sessions are already on the board (`livePeers`,
`server.ts:207`, via the ipc db) as aliases.

## The model

A **session** is a surface of kind `session` (UNIFIED-SURFACES §the model):
`{ id: uuid, alias, board: slug, model, branch, startedAt, lastAt, live,
turns, chapters }`. A board has many sessions; a session has one board (its
root at the time). The transcript is the session's content, read on demand,
never copied into the kanban store.

Two rules that keep it honest:
- **Derived, never stored.** Which sessions a board has is computed from the
  projects directory plus the ipc db at read time; nothing writes a session
  list to disk (the "record versus verdict" pattern).
- **The parser is the contract.** `transcript.py` is called as a subprocess by
  `server.ts` (`/api/session/<uuid>` → its JSON), not ported, until a measured
  reason appears. Its `{meta, records}` shape is the API; the viewer here reads
  that and nothing else. One parser, two homes, zero drift.

## The surfaces

**1. Sessions on the board.** The sidebar's HERE NOW group becomes SESSIONS:
live aliases first (as today), then recent sessions by `lastAt`, each a row
with alias or short id, model tier dot (the `tier` hue), branch, `Nh ago`.
Press opens the transcript drawer tab. The hub row's `N live` pill links here.

**2. The transcript view, on this design system.** A drawer tab (the drawer
already holds tabs of open things; a session is one more kind of open thing,
violet-tinted like a card, with its own glyph). Inside:
- a **spine** of chapters on the left (the parser's chapters; caps labels, the
  lane-hue swatch per chapter), pressable, `[`/`]` to move;
- **turns** as cards: owner turns on `--well`, agent turns on `--card`, tool
  blocks folded to one pill row (`N tools · read write bash`) that expands,
  sub-agent runs nested one step in with the `tier` dot of their model;
- the **board links**: a turn that mentions a card id, a card title, a note or
  a draft gets the card's chip inline; pressing it opens that card's tab. This
  is the one thing the old viewer cannot do and the reason the view belongs
  here;
- search (`/` inside the tab searches the transcript, sectioned by chapter);
  `jump to new` since the owner's last read (the board's `since` mechanism,
  reused); the view panel's skin/font/timeline knobs are dropped (the design
  system decides those), theme follows the page.

**3. Card ↔ session.** The drawer's "What the agent claims" group gains a line
"worked on in: <alias> · <alias>", derived from turns that touched the card,
each pressable. A card with no session mentions shows nothing.

**4. Hub.** The Boards tab's `N live` pill already exists; a **Sessions** tab
is not added (the unified-surfaces hub gets Decisions and Previews; sessions
are per board, the wrong altitude for the hub, same reasoning as views).

## What happens to claude-instances

- The Swift widget keeps running and keeps its `/api/sessions` hub on :5400
  for its own dropdown. Nothing there changes in this plan.
- `transcript-app.html` and `detail-server.py` are **retired** once the drawer
  tab ships and the widget's "open transcript" action points at
  `http://localhost:5106/b/<slug>?session=<uuid>`. Retiring, not fixing: the
  owner's words are that the visuals are half-done and the system here is
  preferred, so the fix is to stop having two viewers.
- `transcript.py` stays where it is and is invoked by path; moving it is a
  later migration if the widget is ever split.

## Phases, each shippable

1. **Join and list.** `server.ts` `/api/sessions?slug=`: transcripts under
   the board root's projects dir, merged with live aliases from the ipc db,
   sorted live-first then `lastAt`. Sidebar SESSIONS group. Check: the
   `.claude` board lists this session (live) and yesterday's, with branch and
   age; a board with no transcripts shows the group empty with one line.
2. **The transcript tab.** `/api/session/<uuid>` calls `transcript.py`; the
   drawer renders spine + turns + folded tools + nested sub-agents on the
   ladders (DESIGN-SYSTEM §§1–7); `?session=` deep link. Check: a11y tree has
   a `tablist` entry per open session, chapters as a `navigation`, turns as
   `article`; both themes screenshot-read; the §14 round; the 21-hour-old
   session's transcript renders under 2 s (measure, `performance.now()`).
3. **Board links.** Card-id, title, note and draft mentions become chips in
   turns; the card drawer's "worked on in" line. Check: a turn from today that
   names `#48` links to its card; a card touched by two sessions lists both.
4. **Search and since.** `/` inside the tab; `jump to new`. Check: the
   search chips seed with chapter names; `since` reads the ack the board
   already keeps.
5. **Retire the old viewer.** Widget's transcript action re-pointed; the two
   files moved to `archive/` with a note. Check: the widget opens the board
   tab; `rg -c "transcript-app" lib/` = 0 outside archive.

## Rules this binds to

- DESIGN-SYSTEM §7.6: the tab is a drawer surface, violet tint, no new
  radius, no new shadow. §2: turn text is body 12.5, tool pills small 11.5,
  chapter labels caps 10.5. §8: hover one step; Esc steps out of the tab.
- Charter §12 honesty: a session's `live` comes from the ipc heartbeat, which
  reads live for 21-hour-dead sessions (catalog §10 lesson); the row shows
  `live` only when the heartbeat is under the same window the nudge uses.
- Not number-heavy: no token or cost columns on the row; `meta` rollups live
  behind a pill's tip, not on the face.
- UNIFIED-SURFACES: `session` is a kind; when the registry (phase 1 there)
  lands, sessions register through it like everything else.

## Model plan

```
phases 1-2  → opus, inline, one surface at a time, §14 each
phase 2 UI  → the §14 round; the §17 pass covers the tab when it runs
phase 3-5   → opus, after unified-surfaces phase 1
```

## Owner decisions (next decision page)

> On the page as of 2026-08-24: `http://localhost:5197/kanban-aug24-rulings/`
> (D2, D3, D4 there are D-ch-1, D-ch-2, D-ch-3 here). Nothing in this plan
> gets built until they are answered.

- D-ch-1: the transcript view lives on the board and the old viewer retires
  (recommended) or both stay.
- D-ch-2: `transcript.py` as a subprocess contract (recommended) or a TS port.
- D-ch-3: sessions as a drawer tab (recommended) or a full page `/b/<slug>/sessions`.
