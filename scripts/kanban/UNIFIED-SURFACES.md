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

## Owner decisions (combined page)

- D-uni-1: registry-first, servers stay (recommended) or merge :5197 into
  :5106 now.
- D-uni-2: phase order 1 → 2 → 3 → 4 (recommended) or 2 first (restyle the
  decision page before colocating).
- D-uni-3: previews register by an explicit `preview.sh register` call
  (recommended, agents must opt in) or by scanning `assets/reports` for HTML.
- D-uni-4: plan states `draft | ruled | superseded` (recommended) or a
  richer set.
