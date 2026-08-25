# The kanban surfaces system: taxonomy, laws, patterns, and the incumbent look

Attached to `design/HANDOFF.md`. Section labels say what binds: NORMATIVE
and PRESCRIPTIVE bind any design; EXISTING is context only, the incumbent
to beat. Written 2026-08-25 from the live code and the rulings ledger.

## 1. The product, and what it has / wants

Have (built, live): the board page (six lanes + ephemeral peek columns, a
right drawer for one card, a left panel for views/plans/tags/pins/presence),
the hub (indexes of boards, asks, decisions, previews), drafts (a document
editor with templates, routing and pulls), decision pages (adopted at
/dp/<slug>/), a kind registry driving tabs/counts/search/palette on every
page, per-board plans, a CLI (`kanban.sh`) that is the agent's equal-rights
surface, and a pm2 server owning all reads and most writes.

Want (ruled or filed, not built): sessions as a kind with a per-board
transcript view (CHAT-HISTORY.md, rulings in); an app-wide movement/keyboard
model (#70); the combined board toolbar (see §5.4); phone support; drafts
routing slice 4 (a draft landing as an ask); showcase boards; the
decision-page retirement (:5197 folds away once /dp/ has proven itself).

## 2. NORMATIVE: the taxonomy

Every noun the system has. A design may re-present these; it may not
quietly merge, split, or rename their MEANINGS. (Machine name → owner's
word, where they differ, per charter §2: the UI always speaks the owner's.)

**Board.** A mirror of one project's docs, harvested by sync; never the
source of truth for the docs it mirrors. Carries `syncedAt`, and staleness
is stated, never hidden. Registry-listed; can be starred and archived
(archive is an instruction about the list, not an opinion about the board).

**Card.** One unit of work on a board. Harvested from docs (source
path:line it can reopen) or manual. Has: title + `titleBrief` (a ≤56-char
scannable NAME, auto-cut ones marked as the agent's to improve), sub-items,
lane, linked docs, age, provenance (`via` session), and the verify block.

**Lane.** Inbox · backlog · active · blocked · done · stale. Fixed
vocabulary. Per-lane view prefs (sort, density, fold, width) layer on board
defaults; a shared soft limit turns the count amber, a signal never a block.

**Peek column.** An ephemeral lane showing every card wearing one tag.
Explicitly dismissed, never dropped by a stray click; several can stand;
each keeps its dragged position.

**Note.** A message on a card, many per card, each with its own id and
read/ack state. The owner's lane of the conversation. Carries the note-tag
grammar (`@me` self-notes suppress unread; `!now`; `/skill`; `>lane`;
`#defer`; `#review-me`). Notes order is draggable; a draft-in-progress is
stashed per card+note and offered back, never auto-applied.

**Ask (machine: item).** Something the owner wrote for agents. Unassigned
by default; where it SHOWS is a display rule (explicit boards > origin
board > everywhere). Starred = notice this; triggered = pick up now. An
agent CLASSIFIES it into a landing: shape task | subtask | clarification |
remark, optionally becoming/attaching to a card, with a one-line account.
Deleting is writing an empty body. Unsorted asks are counted and nudged.

**Draft.** A document the owner writes over days; templates are drafts
marked as such; a PULL hands a draft to a recipient session (pulled state
struck through, not hidden). Wants: landing as an ask (routing slice 4).

**View.** A NAMED query both sides can say. Clauses with AND (space), OR,
NOT; no parentheses; at most one free word. Carries the owner's optional
note ("what I use this for", written for agents to read). By owner or by
agent, and the byline shows.

**Tag.** Per-board vocabulary word with a KIND: milestone · priority ·
class · tier · effort · area · risk · plain. Each kind has a hue and a
preset value list; a tag can carry a note; a tag's COLOUR can be overridden
once, globally, by kind:name, and holds on every board. Tags are created
on use, renamed in place, counted live, and every count filters.

**Goal.** One line on a card: why this card exists / what done means.
(The "goals" the owner names; MILESTONES are the tag kind that groups cards
toward a marker. Goals are per-card prose; milestones are shared vocabulary.)

**Seq.** Execution-order edges between cards (card comes after cards).

**Verify.** The agent's grade on a card: executed | cited | reasoned, with
optional needs-human and a note. The evidence vocabulary of the whole gcc.

**Ask-on-a-card (the choice, #48).** When verify needs the owner, the card
carries the question itself: options in the agent's words, the agent's own
recommended pick, and the owner's answer (a pick, or null-pick with text:
"neither, do X" is a real answer). AskState: unseen · seen · answered, and
unseen vs deferred stay distinguishable. A decision nobody opened is NOT
undecided.

**Selection.** The set of cards + notes the owner has picked to send to an
agent. Mirrors server-side; `kanban.sh selected` is how an agent reads it.

**Pin / star.** Owner-only jump list (kinds: card, item, board). No agent
reads pins; that is the difference between a pin and a star on an ask.

**Plan (doc).** A registered markdown doc bound to a board with a state:
draft · ruled · superseded. The artifact a decision page is ABOUT.

**Decision page.** A pre-answered form: decisions (radio options, exactly
one recommended) + sections (agree/note per item) + optional per-item and
end-of-form notes. Produces ONE compact answer string (untouched = agreed;
only deviations serialize). Pending = handed off, awaiting the human;
answered = .answer.json exists. Now served in-app at /dp/<slug>/.

**Preview.** A registered one-off HTML page an agent rendered for the
owner (manifest exists, registrar tool not yet built). State new | seen.

**Session.** (future kind, ruled) an agent conversation bound to a board;
transcript viewable in place; a drawer tab, not a hub page.

**Kind.** The meta-taxon: one registry entry (name, owner's label, glyph,
hue, index route, search adapter, count) and every consumer reads it. A new
noun becomes a kind, never a special case.

**Sync / harvest / delta.** The mirror loop. `syncedAt` honesty, the
since-your-last-visit delta chips (news, not state; each one filters), ack
(when an agent last read notes). Overrides (agent lane verdicts) and
tombstones (dropped cards stay dropped) survive re-harvest.

## 3. PRESCRIPTIVE: the laws any design must keep

Distilled from UI-CHARTER.md (§ refs) and FEEDBACK-CLASSES.md (C refs);
each is a ruling paid for in lived friction, not a taste.

1. **Honesty (§12).** Unknown is never zero; an unloadable list is not an
   empty one; staleness is stated where the stale thing is shown; "searched
   X, Y, Z" names only what actually answered; a verification verb needs
   its evidence. No surface asserts what nothing verified.
2. **The owner's words (§2, C1).** UI labels use the human vocabulary
   (Your asks, not items.json). Machine nouns stay in machine surfaces.
3. **A count is a control (§13).** Every number shown filters to exactly
   what it counted.
4. **Capability parity (C6).** A capability built on one surface is owed to
   its siblings in the same change, or the gap is stated.
5. **One write path, views re-read (C5, §11).** A write leaves through one
   path and every view re-renders from the store; no view patches its own
   copy of the truth.
6. **Floating surfaces are first-class (C3).** Popovers/panels are titled,
   draggable, tethered to their opener, keyboard-reachable, and dismissed
   deliberately.
7. **Keyboard routes for structure (C4, §10).** Everything structural is
   reachable without a pointer; keys live where their control is visible.
8. **No zone reaches zero (§18b).** Under pressure surfaces SHED in a
   stated order with visible signs (fades, ellipses with floors), and the
   fix for one zone starving is never another zone starving.
9. **Drawn, not typed (§5).** Glyphs are SVG; a glyph accompanies a label
   or has a tooltip; no dingbat-only buttons.
10. **No native tooltips (§16); one delegated tip layer.**
11. **Irrelevant is hidden; unavailable is visible, quiet, explained (§7).**
    Amended 2026-08-25: the old form collapsed two cases. A control that makes
    no sense here is hidden; one that cannot act right now stays put with a
    tooltip saying why.
12. **Overlays are symmetric, Esc closes, one scrim (§9).**
13. **Optimism only with re-sync.** Optimistic touches must re-read; errors
    roll back visibly (the ask-routing busy/error idiom).
14. **Finish parity (C9).** Sibling surfaces ship at the same finish level;
    a raw control where the system has a component is a defect (C8).
15. **Never rebuild a focused element**; a re-render is invisible to
    someone typing (caret restored, buffers survive the node).
16. **The bar stays uncrowded (owner, 2026-08-25).** Buttons carry icons
    with tooltips; only the verbs that need emphasis get it; when a page
    has many verbs, prefer a SECOND per-page bar under the main navbar to
    cramming the one bar. Weigh this across the whole app.

## 4. EXISTING: the incumbent visual language (context, not a target)

Tokens (shared.css): a dark-first two-theme palette on `--canvas/--well/
--card/--card-hover` depth steps; accent hues blue · amber · green · red ·
violet · grey · teal · pink, each with -bg/-br tints; radius ladder 2/4/6/
8/10/20/99; type ladder 9/10.5/11.5/12.5/13.5/15.5/19 (SF Pro / SF Mono);
motion .12s colour + .22s travel with one easing; a named z-stack; one
control height (31px). Components in use: buttons (outline/solid/ghost/
icon), styled selects + `searchSelect` (filterable dropdown), chips and
pills, the colcard popover family, the right drawer, modals, toasts, the
delegated tooltip, resize grips, FLIP column glides, fade-masked scrolling
strips, skeleton bones, the navbar (below). Read DESIGN-SYSTEM.md for the
full component inventory; UI-CHARTER.md §19 for how it got this way.
REMEMBER: this section is the incumbent. Ideation may keep, bend, or
replace any of it on merit.

## 5. Pattern library, with the surface examples to ideate on

### 5.1 The rich-row family (one object family, per-context ornament)

The same "thing in a list" idea wears different ornament and actions per
context, and that variance is deliberate:
- Board CARD face: name, tag chips (hue dots), note chips with unread,
  verify pill, first line of the agent's claim at full density, source
  path, age, arrival fx; click opens, shift-click selects, middle-click
  background-opens, chips are their own controls.
- Hub BOARD row: identity glyph, live counts (each a pill), needs-you and
  blocked pills, star and archive on hover, root path, sync age.
- ASK row: full body text (the ask IS its text), routing dropdown, star,
  shape/landing state, origin.
- DECISION/surf row: title, origin · item count, age, pending amber edge.
- Sidebar rows: dense, one-line, count at the edge, verbs revealed on
  hover (rename/delete/note), state chips (plan draft/ruled).
- Palette/search rows: glyph + name + subtitle + kind section header.
NORM: ornament answers "what would I want to know before acting HERE";
actions surface where the eye already is; identity glyphs and hue language
stay one family across all of them. IDEATE: a unified row grammar that
makes the variance feel designed rather than accreted.

### 5.2 Toolbars

Today: navbar zones (identity · status · find · common), the board's
action groups (find / pick / act / view, grouped by gap not boxes), drafts'
editor toolbar (title, mode switch, send-now as the one solid), the
decision page's verb bar. NORM: group by spacing, one primary verb per
bar, verbs that vanish when they cannot act. IDEATE: one toolbar grammar
spanning all pages.

### 5.3 The powerful search bar

Today three searches exist: the board palette (intent questions first,
then cards/notes/tags/every kind, honest corpus sentence, stays-here vs
navigates), the cross-kind find box (hub/drafts), the board switcher (b).
NORM: results grouped by kind in registry order/rank; a result already on
this page scrolls, one elsewhere navigates; the empty state names what was
searched. IDEATE: whether these three are one control with three moods,
and what a truly powerful single bar (verbs? filters-as-you-type? actions
in results?) looks like.

### 5.4 The combined board toolbar (a WANT)

The board currently splits: navbar (identity/status/tabs/verbs) + a
filter/search row + the sidebar's views/tags. The owner wants these
thought of as ONE combined toolbar surface. IDEATE from scratch: where do
filter, views, saved searches, selection mode, sync state, and the send
verb live when designed together instead of accreted.

### 5.5 The navbar, unified, and its views

One bar on all pages: logo-home, crumb grammar (`All <kind> / <instance>`),
status band (counts that filter + delta news + sync freshness), find zone,
kinds TABS AS INDICATOR (counts, hue rule under the active kind), page
verbs, theme/help. Sheds in a stated order under pressure. IDEATE: the bar
as the app's one constant; what else earns a place, what should leave.

### 5.6 The transcript / ask hub

The hub today: boards · asks · decisions · previews views, one list column.
Ruled future: sessions as a kind, transcripts viewable per board (drawer
tab), decisions-without-a-card deriving attention. IDEATE: the hub as the
owner's morning surface: what wants you (asks unsorted, decisions pending,
needs-you cards, key-expiring), then everything else, across ALL kinds.

## 6. The eleven failure classes (design pitfalls, lived)

C1 machine nouns in UI · C2 owner feedback parked behind agent planning ·
C3 floating surfaces not first-class · C4 no keyboard route · C5 a write
refreshing only its own view · C6 capability on one surface only · C7 a
navbar assembled not designed · C8 raw controls where components exist ·
C9 uneven finish across siblings · C10 approved surfaces never carded ·
C11 a helper built beside the one that exists. A new design is reviewed
against exactly these, because these are the ones that actually recur.
