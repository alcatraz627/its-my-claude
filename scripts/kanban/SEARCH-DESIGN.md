# What search on this board has to do

Written before the search bar exists, so the bar is built to answer real
questions rather than to expose the fields we happen to store. It is also the
validation reference: a later stage checks the built thing against §5 and §6
rather than against its own implementation.

The organising idea: **search is not a filter with a text box.** A filter
narrows what is already on screen. Search answers a question, and the questions
people bring to this board are mostly not "which cards contain this word".

---

## 1. Who is asking, and what they actually want

One person uses this board: the owner of a project an agent is working on. They
arrive with one of a small number of intents, and search either serves the
intent or wastes the visit.

| They are thinking | They will type | What answers it |
|---|---|---|
| "where did that thing go" | a half-remembered phrase | a card, by title or by the note on it |
| "what is left for the milestone" | `M2` | the group, not one card |
| "what is blocking me" | nothing, they want a state | a saved question, one press |
| "what did I say about the export" | `export` | their own notes, quoted |
| "what has the agent not looked at" | nothing | unread and unacked work |
| "which board was that on" | a project name | a different board entirely |
| "what did I ask for and never got" | nothing | unsorted asks with no landing |

Two of those seven are text. The rest are **states and groups**, which is the
single most important finding in this document. A search box that only greps
titles fails five of the seven.

## 2. The capabilities it must give them

Stated as things the person can do, not features the system has.

1. **Find a card I half-remember** without knowing which lane it is in, which
   board it is on, or the exact words.
2. **Ask a question about state** without composing a query: blocked, unread,
   needs me, untagged, stale, no goal.
3. **Pull up a group** by milestone, model tier, effort, area or risk, and act
   on the whole group.
4. **Search my own writing**, which is a different corpus from the cards. My
   note is mine. The card's title came from a document.
5. **Cross a board boundary** without going back to the hub first.
6. **Keep a question I ask often** so it costs one press next time.
7. **Turn a result set into a working set**, so what I searched for is what I
   send to an agent.
8. **Get out** with nothing changed. A search that leaves the board filtered
   after I close it has stolen my place.

## 3. What it must not do

- **It must not be the only way to reach any of this.** The tag chips, the
  status band counts and the sidebar already answer some of these questions by
  pointing. Search is the fallback for when you do not know where to point.
- **It must not require syntax.** `is:blocked` may exist, but nobody should
  have to know it. Typing `blocked` offers it.
- **It must not silently search one corpus.** If the word appears in a note and
  not a title, saying "no results" is a lie by omission.
- **It must not mutate on the way past.** Opening a result is a navigation, not
  a state change.
- **It must not lose the board.** Charter §1: nothing modal by default, and the
  board underneath stays where it was.

## 4. The shape that follows

The palette, already built for boards and tags, is the right surface: one
component, sectioned results, keyboard-first, escapable. Search is that same
palette with more sources.

**Sections, in priority order.** Priority is by how often the intent occurs,
not by how cheap the source is to query.

1. **Questions.** The state intents, offered as soon as the query matches a
   word in their name. This section is first because five of the seven intents
   live here.
2. **Cards.** Title and brief, this board first, then other boards.
3. **My notes.** Quoted with their card, because a note only means something
   attached to something.
4. **Tags.** Jumping to a tag opens its peek column, which is the group intent.
5. **Asks.** The unsorted ones, since "I asked for that" is a real question.
6. **Boards.** The existing board rows, so `b` and search are one door.

**Two result verbs, and the difference matters.** A card result offers *go
there* (scroll and pulse, which the peek already does) and *open it* (a tab).
A question or a tag result offers *show me all of them*, which is a peek column
rather than a jump.

**Saved questions** are the seventh capability and the cheapest to build. A
question is a filter string plus a name, stored per board next to the tags.
Starring one puts it in the palette's first section permanently.

**From result set to working set** is the eighth. Any result list can be
selected wholesale, which drops it into the existing selection and therefore
into `kanban.sh selected` and Send to agent. This is the payoff that makes
search worth building rather than nice to have.

## 5. Acceptance, written now so it cannot be graded on a curve

The built bar is checked against these, and each is a thing to run:

1. Typing three characters of a card's title finds it, from any lane, with the
   panel closed and with it open.
2. Typing a word that appears only inside a note returns that note, and the
   result names its card.
3. Typing `blocked` offers the blocked question without the person typing a
   colon.
4. Typing a milestone name offers the tag, and choosing it opens the peek.
5. Typing a project name offers that board, and choosing it navigates.
6. A query with no matches says which corpora it searched.
7. Escape closes it and the board is exactly as it was: same scroll, same
   filter, same open tabs.
8. The whole flow works from the keyboard alone, from opening to acting.
9. A result set can be turned into a selection in one action, and
   `kanban.sh selected` then reports it.
10. Both themes.

## 6. Deliberately deferred

Named so nobody has to guess whether they were forgotten.

- **Boolean and composite queries** such as `milestone:M2 AND is:blocked`. The
  owner asked to keep it simple and ergonomic first. The section model above is
  what makes composition addable later without a rewrite.
- **Fuzzy matching.** Substring is enough for a corpus this size, and fuzzy
  ranking is where search engines get confusing.
- **Search across note history.** Only current note text is searched, because
  nothing keeps old versions today.
- **Regex.** No.

## 7. Provenance

Owner, 2026-08-22: *"let's also add a powerful search bar... Need to plan out
how this should work, suggest based on the workflows and paths and user
capabilities (not system capabilities, not system features)."* This document is
that plan, and the capability list in §2 is the part to argue with before the
bar is built.
