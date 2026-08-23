# Unified surfaces: one place for the things you look at and answer

Plan for #56, 2026-08-23. Owner, verbatim, from the decision page: "standardize
the UI and functionality of decision pages into kanban, and also the one-off
html render preview pages that I keep asking agents to make for me. Logically,
they are all multiple ways of the similar kind of bidirectional visual display
and sync. ALSO, the ability to tag and display plans ... I mainly care about
colocation and thanks to the claude-instances switchboard its easy to bring up
and locate all these tool servers."

## What exists, measured today

| surface | where | served by | UI standard | owner's way back to it |
|---|---|---|---|---|
| boards, asks, drafts | `~/.claude/kanban/` | kanban, pm2 :5106 | the charter | the hub, the `b` switcher |
| decision pages | `~/.claude/assets/decision-pages/<slug>/` (46 today) | `decision-pages`, pm2 :5197, Python static server + `_submit` | its own template; not the charter | a URL pasted in chat, or :5197's hub |
| one-off HTML previews | `~/.claude/assets/reports/**/*.html` (54) and scattered | nothing, `file://` or whatever port the agent picked | none; each agent's own | the chat message that linked it |
| plans | markdown under `scripts/kanban/`, `assets/reports/`, project docs (~40 match "plan") | `/doc` on :5106 when linked from a card | `renderMd` | a card's doc link, or memory |

Four kinds of the same thing: an agent produced a page for the owner to read
and, for two of them, answer. Each has its own address, its own look, and no
shared list. That is the complaint.

## The model: surfaces are kinds, and every kind has the same four facts

A surface is `{ kind, id, title, origin, state, href, updatedAt }` where
`kind ∈ board · ask · draft · decision · preview · plan`. `origin` is the
session and project that made it (decision pages already record this).
`state` is per kind: a decision is `pending | answered`, a preview is `new |
seen`, a plan is `draft | ruled | superseded`, a board is its attention tier.

Two things follow from treating them as one set:

1. **Colocation is a registry, not a server merge.** The kanban hub lists
   every kind from one manifest; where each is served stays as it is until
   there is a reason to move it. The owner said colocation is what matters,
   and the instances switchboard already finds the ports.
2. **The charter is the standard for all of them.** Decision pages and
   previews adopt `shared.css` + `shared.js` (the page head, the theme, the
   tooltip layer) the way hub and drafts did. Their own content stays theirs.

## Phases, each shippable alone

**Phase 1, the registry and the hub (colocation).** `server.ts` gains
`/api/surfaces`: boards from the registry, decision pages by reading
`assets/decision-pages/*/config.json` + `.pending.txt`, previews from a new
`~/.claude/assets/previews/manifest.jsonl` that a tiny `preview.sh register
<html> --title --origin` appends to, plans from a `plans.jsonl` (phase 3). The
hub gains two tabs, **Decisions** and **Previews**, sectioned by state
(pending first), each row carrying origin and age like a board row; the `b`
switcher gains the kinds with the §4 grouping-plus-hue rule. Nothing moves.
Check: the hub lists today's 46 decision pages with the right pending count;
`preview.sh register` on one report shows it in Previews within one reload.

**Phase 2, the decision page on the charter.** `template.html` links
`shared.css`/`shared.js`, takes the page head (Boards · Asks · Drafts ·
Decisions · Previews) so the owner can leave a page the way they leave a
draft, and drops its own theme code. Its keyboard (`j k 1-9 a n c s ?`) and
answer string stay exactly as they are: that contract is what every skill
pastes back. The §14 round runs on one real page in both themes. Check: the
page still `check`s READY; an answer submitted from the restyled page reaches
the Monitor unchanged (byte-equal to the old format on the same config).

**Phase 3, plans as a kind.** A plan is a markdown doc registered to a board
with a state, via `kanban.sh plan add <path> --board <slug> [--state draft]`
and `plan rule <id>` when the owner rules on it (which a decision page's
Submit can do automatically when its config names a plan). Plans appear in
the hub's Decisions tab as the thing a decision page is about, and on the
board's sidebar as PLANS with state. Tagging: a plan takes the board's tags
(milestone first), through the same `/api/tag` with `kind: plan`. Check: the
five plan docs written this week register and show; ruling one from a
decision page flips its state.

**Phase 4, decisions without a card.** The owner's D2 note: "projects do need
decisions, sometimes related to a card, sometimes otherwise ... surface the
attention and callout for decisions as derived from that." With phase 1 and 3
in place a decision is a surface of kind `decision` whose origin may name a
card (`ANSWER-PATH.md`'s field), a plan, or nothing. Attention is derived: the
hub's `N needs you` counts pending decisions alongside needs-human cards; the
board's summary chip gains `N to decide` that filters to cards with an ask
and lists board-level decisions in the rail. One rule, written into charter
§12: a decision the owner has not opened shows as unseen, never as undecided.
Check: three decisions (card-bound, plan-bound, free) count correctly on the
hub and the board; opening one moves it from unseen to seen without answering.

**Phase 5, previews that sync back.** Only if wanted after 1 to 4: a preview
page that links `shared.js` can post a `seen` and a one-line reaction to
`/api/surface`, so "did you look at it" stops being a chat question. Cheap
once phase 1 exists; deliberately last because most previews are read once.

## Phase 0, added 2026-08-23: the navbar, uniform and powerful; the help modal, everywhere

> **Navbar shipped 2026-08-24 (#68).** `navbar()` in `shared.js` replaces
> `pageHead`; all three pages mount it. The board keeps its dense controls but
> hands them to the bar as zone contents rather than re-creating them, so every
> id and handler survives. Logo-press-for-home, the page tabs and the help
> control are common now; the board gained tabs it never had and the hub and
> drafts gained the logo. The active tab carries its kind's hue as a 2px rule.
> Two things diverge from the text below and are recorded rather than silently
> resolved. **The `g` chord is not on the board**: `g` there already edits a
> card's goal, and the board reaches the same places with `b`, which this plan
> also lists; the chord works on every page that does not own its key map.
> **The help control is absent, not disabled, on the hub and drafts** until the
> shared modal lands with #69, because §7 says a control that cannot act is
> hidden rather than greyed. The command bar verbs, the needs-you counter and
> pinned context are NOT built: they overlap #70, the app-wide movement plan
> the owner asked for on 2026-08-24, and building them twice is the risk.
>
> **Help modal shipped 2026-08-24 (#69), partly.** `helpModal()` in `shared.js`
> plus the shell, table and keycap CSS in `shared.css`. It works two ways,
> because the board's panes are long hand-written tables and moving them into
> JavaScript would be a rewrite rather than a reuse: a page that already has
> the markup is ADOPTED (the component takes the tab strip and the lazy
> per-pane build; the board keeps open/close because those are wired to its own
> overlay stack), and a page with none gets one BUILT from a tab spec. The hub
> and drafts now answer `?` with a Keyboard reference generated from
> `SHARED_KEYS`, the same list `shared.js` binds from, so the reference cannot
> drift from the behaviour. A single-tab modal renders no tab strip.
>
> **What remains of #69:** the Taxonomy and Charter tabs for the hub and
> drafts, and the decision-page and transcript hosts. Charter needs the 17
> `.cdoc` rules moved to `shared.css` (the server already returns rendered
> HTML, so the fetch itself is page-agnostic); Taxonomy needs content that does
> not exist for those pages yet. Shipping them empty would have been worse than
> shipping one tab that is real.

Owner, verbatim: "Make the navbar 'uniform' for all pages, it can have section
/ page specific elements but the core nav + logo icon click for home + other
common info should still be shown, essentially I shouldn't lose access to
common things in the navbar across; also improve the visual highlighting and
controls in the navbar across + empower it even more for me to use it like a
'power user' (define this properly and map to workflows / features / common
minimal user actions or viewing for maximum customizable context)". And: "I
really like everything about the help modal in the board, how else can we reuse
the work done there to make it useful across other places as well".

**The uniform navbar.** Today the hub and drafts share `pageHead` (shared.js)
and the board has its own top bar (catalog §4), so the owner loses the page
tabs on the board and the board's search on every other page. One `navbar`
in `shared.js`, three zones, on every page:

| zone | always | per page |
|---|---|---|
| left: identity | logo glyph (press = hub), crumb `All boards / <board>`, the `b` switcher | the board's path, the draft's title |
| middle: find | the command bar (`/`): search on a board, filter on hub lists, find in a transcript | the placeholder says what it searches here |
| right: common | page tabs (Boards · Asks · Drafts · Decisions · Previews), live peers, theme, help `?` | the board's select/nudge/copy group; drafts' Offer |

Highlighting: the active tab carries the kind's hue under the label (§4
grouping-plus-hue), the current board's name is `--text` 600, everything
common is `--text-2`, and the page-specific group sits in its own bordered
pill so the eye can tell "here" from "everywhere".

**Power user, defined.** The owner's minimal recurring actions, measured from
the session-start line, the asks rail and the decision pages: open a board,
find a thing, see what needs them, write an ask, answer a decision, read a
transcript, switch theme. The navbar serves those without the mouse:

- `b` go-to (boards, asks, drafts, decisions, previews, sessions, views)
- `/` the command bar, with verbs: `>lane card`, `#tag card`, `@agent ask`,
  `view name` applies a view, `?` opens help; the search picker's chips are
  the vocabulary
- a **needs-you counter** in the right zone (cards needing you + pending
  decisions + unread drafts pulls), pressable, the same number the hub shows
- **pinned context**: the owner pins up to three things (a board, a view, a
  decision) to the left zone from the switcher (`p`); they persist in the pin
  store and render as small chips, so "my three boards" is one keystroke
- `g` then a letter: `g b` boards, `g a` asks, `g d` drafts, `g s` sessions,
  `g ?` help (chorded, shown in the help modal's Keyboard tab)
- the theme, help and the live-peers pill never move

**The help modal, everywhere.** What makes it good is the five-tab shape
(Keyboard · Taxonomy · Vibe Code · Hey Claude · Charter), one table
treatment, sticky heads where a tab warrants one, Esc-only dismissal, and the
Charter tab rendering the source live. Reuse is one component in `shared.js`
(`helpModal(tabs)`) with the board's CSS moved to `shared.css`, and per-page
tab sets: hub (Keyboard · Taxonomy · Charter), drafts (Keyboard · Taxonomy ·
Templates · Charter), decision pages (Keyboard · How to answer · Charter),
transcript tab (Keyboard · Reading a session · Charter). Keyboard and
Taxonomy are generated from the same tables the navbar and the pickers read,
so the modal never drifts from the keys. `?` opens it on every page.
Check: `HELP-MODAL-SCROLL-PARITY.md` re-run on every page that mounts it;
the a11y tree shows one `dialog "help"` per page with the page's tab names.

Sequence: the navbar lands before phase 1's hub tabs (they are its right
zone); the help component lands with phase 2 (the decision page is its first
new host).

## Served from where

Recommendation: leave :5197 and :5106 as they are through phase 3. The Python
server does one thing (static + `_submit`) and moving it buys nothing the
registry does not. If, after phase 4, the two hubs feel like two places, fold
`_submit` into `server.ts` as `/api/decision` and retire the Python server in
one migration; the registry layout stays, so nothing an agent does changes.

## Model plan

```
phases 1-3  → this session's model, inline, one surface at a time, §14 each
phase 2 UI  → the §14 round; a fable seat only if the owner wants a second
               read of the restyled decision page before skills depend on it
phase 4     → after ANSWER-PATH.md ships, same seat
```

No fleet. Each phase is one branch commit with its check in the message.

## Ruled, 2026-08-23 (decision page kanban-plans-round-2)

D5a registry first. D6a phase order 1 → 2 → 3 → 4. D10a §14 round only.

D7c, scan and mark unclaimed, with this note, verbatim: "Also tell agent to
use this as a part of the standard /kanban + /decision-pages generation it
does". So phase 1 both scans `assets/reports/**/*.html` (listed as
`unclaimed`, with path and mtime) and takes explicit registrations; and the
`/decision-wizard` and `/kanban` skills, plus `decision-page.sh new`, register
what they make as a matter of course, so new pages are never unclaimed.

D8b, plan states mirror the lanes: `inbox · backlog · active · blocked ·
done · stale`, the same vocabulary a card has, so a plan on the board reads
like everything else on it and the lane filters apply to it.

D9a, with this note, verbatim: "a, but optionally open b to view all in one
place, tell the agent to update and store the decided ones here too and allow
me to add commments and hook into the standard agent nudge workflow from
kanban". So: attention derived (hub count, board chip, rail) AND a Decisions
view on the board that lists every decision in one place, card-bound or not,
pending first, decided below with the answer; the agent records decisions it
took to the owner there (`kanban.sh decide add`) and marks them decided when
answered; the owner can comment on any decision (the note composer, reused,
with the card-less case writing to the decision); and a pending decision
counts for the nudge the way an unread note does, so `kanban.sh nudge` and
the session-start line name it.

## Owner decisions (answered above)

- D-uni-1: registry-first, servers stay (recommended) or merge :5197 into
  :5106 now.
- D-uni-2: phase order 1 → 2 → 3 → 4 (recommended) or 2 first (restyle the
  decision page before colocating).
- D-uni-3: previews register by an explicit `preview.sh register` call
  (recommended, agents must opt in) or by scanning `assets/reports` for HTML.
- D-uni-4: plan states `draft | ruled | superseded` (recommended) or a
  richer set.
