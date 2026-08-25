# Seed for the comprehensive plan

Written 2026-08-22 for the next session, which the owner asked to run as a
comprehensive `/plan` with a fable seat. This file is the input. It exists
because the transcript holds the asks and `/clear` destroys the transcript.

## The instruction that frames the whole run

Owner, 2026-08-22, verbatim:

> next session let's do a comprehensive /plan with fable, so seed that task with
> ALL the things I have asked a feedback for, the patterns, the places checked
> and to use as reference, the places not reviewed by me / you haven't done much
> on, all my asks, and to confirm the compliance with it. Also tell it to make
> the sweeping changes in a branch and merge it later (or keep the original copy)

Two hard requirements in that sentence, and neither is optional:

1. **The plan confirms compliance.** Not "considers" the asks below: goes through
   them and states, per item, whether what shipped complies, with the check that
   proves it. An item nobody can point at a check for is not compliant.
2. **Sweeping changes happen on a branch.** `main` keeps a working copy until the
   owner merges. Today's entire session is uncommitted on `main`'s worktree, so
   the branch decision is the FIRST thing the plan settles, not the last.

## 1 · Every ask the owner has made, and where it stands

Their words, in the order they arrived. "Shipped" means built AND verified in a
browser this session; nothing here is claimed on a build passing alone.

### From feedback draft V3 (2026-08-22)

| Ask, in the owner's words | State |
|---|---|
| "Pressing any key in the help screen closes it, only esc key should" | shipped (#2) |
| "'Hey Claude' Put the note tags section below 'The Example Card', currently wasted space + scrolls below extra" | shipped (#3), 552px to 288px |
| "'Keyboard': The rows below the preview, put them in 2 cols instead of full scroll" | shipped (#4), 637px to 233px |
| "The guideline of maximising space utilization without asking for more if the existing is sufficient" | charter §18 |
| "Allow marking / unmarking a board as active for me" | shipped (#6), archive toggle |
| "Also right now a lot of older boards show up" | shipped (#7), folded Archived tier |
| "Enable auto-save · The editing surface needs to be auto-save=true" | shipped (#8) |
| "Need better visual identification in the editing / preview surface" | shipped (#9) |
| "Can we get gfm working here?" + "I don't want to overcomplicate just incrementally improv" | shipped (#10) |
| "'Offer to a session' -> What and how, this doesn't work as fine" | shipped (#1), was a dead channel |
| "Need to improve that everywhere" (editing surface) | PARTIAL (#13), not done |
| "Need a persistent undo/redo" | shipped (#12) |
| "The editor in the drafts is eating up chars like '# # #' becomes '#'" | shipped (#11), probed to mechanism |
| "let the agent see the editing history ... a timestamp and some form of a diff" | shipped (#26) |
| "allow the agent to save and later pull verbatim user input from the chat ... do it separately and /plan" | DEFERRED by owner (#27) |
| "Allow supporting images and links and tables and other stuff" | PARTIAL, folded into #13 |
| conversation history per board, folding in claude-instances | DEFERRED by owner (#14) |
| "/plan for how to support this on the phone" | DEFERRED by owner (#15) |

### From feedback draft V4 (2026-08-22)

| Ask | State |
|---|---|
| "Allow all actions to be via keyboard, eg: open / close is still via click" | shipped (#34) |
| "Middle click on a card ... toggle add / remove ... without stealing focus or changing sidebar open state" | shipped (#35) |
| "The column 'settings' popover has too much vertical space on top and not enough on the bottom" | shipped (#36) |
| "Action buttons should not wrap text + use icons and tooltips and minimal actual content" | shipped for board + drafts (#37); **hub.html NEVER AUDITED** (#46) |
| "See what else can be added to column settings" | NOT DONE (#38), open-ended, needs a proposal |
| "pair it with filter views that both the agent and I can also create / update / delete, and also be able to talk in terms of that" | NOT DONE (#39) |

### Asked in conversation

| Ask | State |
|---|---|
| "ensure a standard UI is conformed to" | ongoing; charter is the standard |
| "prepare a charter we can use and keep adding to ... I don't have to repeat everything everywhere" | charter live, 19 sections |
| "I don't want a 100 subagent run I want it capped" | honoured; zero sub-agents this session |
| unify the two nav models, "first think about it on how it conforms to the ... charter" | analysis + slice 1 shipped (#20, #21) |
| "the index and specific pages for all ... enough distinction to not have to read" | PARTIAL: switcher done, per-kind index pages NOT done |
| "add the charter to the help modal as a tab" | shipped (#22) |
| help modal "visual hierarchy in the tables ... consistent across all" | shipped (#23) |
| sticky top section per tab, "not hey claude" | shipped (#24) |
| "the modal title and tab stay as is without any scroll hiccups ... don't cause a mess here" | parity check, 3 re-runs, all 0/0 |
| "Make and update a kanban board for this session itself" | shipped: milestone `aug22-kanban`, 41 cards |
| search "needs more visual hinting on what all is available, some chips / tabs / suggestions" | shipped (#41) |
| Q1 ruling: "B + C, as applicable, let's conform but add C on top of it" | charter §4 amended |
| Q2 ruling: third mode, "having a third surface will help in case of bugs" | shipped (#33) |

## 2 · The patterns this session found, which the plan should apply rather than rediscover

These are the reusable ones. Each was found more than once.

- **A record and a verdict are different questions.** `pulls[id]` exists vs the
  draft is consumed. A tag row exists vs the card exists. A pull happened vs the
  text is still unread. Three defects, one shape: a surface asked the cheap
  question and got a confidently wrong answer. Fix is always one function
  everyone asks.
- **Two surfaces describing the same thing disagreeing is the cheapest tell there
  is.** It caught the tag count (42 vs 41), the drafts list (Pulled vs waiting),
  and the CLI-vs-UI count divergence I briefly created myself.
- **A green measurement is not a look.** Live mode measured perfectly (1 raw line,
  46 rendered, focused) while rendering as unreadable columns. The hazard ledger
  already says this; it earned its place twice today.
- **A check whose verdict is "nothing moved" needs a positive assertion.** The
  scroll-parity check passed on a modal a toggle had closed and reported it as a
  pass.
- **Comments assert things the data contradicts.** `livePeers` called the broker
  status column authoritative (it reads live for 21-hour-dead sessions); a comment
  I wrote claimed code spans were protected (they were not). Both confident, both
  wrong, ten minutes and three weeks old respectively.
- **A standing count is a measurement with a date.** §16's "zero native tooltips"
  was false and a peer found it. Re-measure before repeating.
- **Probe artifacts describe the wrong moment.** Four times today: two theme reads
  set one attribute where the app sets two; an arrow-key test dispatched on
  `document` where the handler is on the input; a status check sliced 60 chars off
  a string whose payload is last. When a probe says a feature is broken, check the
  probe's target first.
- **UA defaults nobody set.** An `h4` margin made a popover lopsided; the same
  default cost the Taxonomy tab 280px. `font:` shorthand does not reset margin.

## 3 · Reference surfaces, in the order a plan should read them

- `UI-CHARTER.md` — the standard. §13 anti-patterns and §14's capped round are
  the QA instrument; §17 is the thorough review, never run; §18 space; §19 log.
- `hazards.md` — facts code reading does not recover.
- `SEARCH-DESIGN.md` — 7 intents, 8 capabilities, written before search existed.
- `DRAFTS-ROUTING-PLAN.md` + `DRAFTS-ROUTING-TODAY.md` — slices 1-3 shipped, 4 deferred.
- `NAV-UNIFICATION.md` — the kind/instance analysis; slice 1 only.
- `DRAFTS-EDITOR-TODAY.md` — the pre-change capability baseline.
- `HELP-MODAL-SCROLL-PARITY.md` — the owner's no-hiccup constraint and its re-runs.
- `~/.claude/assets/reports/20260822-0640-drafts-editor-direction/` — memo +
  cited research sheet. NOT git-tracked; `assets/` is gitignored.
- `~/.claude/assets/reports/20260728-ui-categorical/patterns.md` — C1-C5 classes.

## 4 · What the owner has NOT reviewed, and what was barely touched

**This is the section the plan must not skim.** Everything above was seen by the
owner or verified against their words. What follows was not.

- **hub.html** — never audited for the button contract (#46). Drafts looked fine
  until it was measured at 0 of 5 glyphs.
- **board.html has no shared stylesheet** — links neither `shared.css` nor
  `shared.js`, alone among the pages. Its kind glyphs are a KNOWN COPY of
  `NAV_ICON`, named in a comment at the copy site. Converting it was listed as
  riskier and deferred by the previous session, and it is still deferred.
- **The charter §17 thorough review has never run** (#16). Seven passes, per
  element, per surface. It was this session's original plan and was displaced in
  the first ten minutes.
- **Three validator caveats, still unexercised** across two sessions: the five
  composite control states, `prefers-reduced-motion`, and concurrent edits to one
  note body.
- **Every commit is unreviewed.** 16 predate today; today's work is entirely
  uncommitted. No independent review has run on any of it.
- **The direction memo's numbers were never independently verified** — the capped
  ruling meant no second seat, and that skill exists because a memo once shipped
  false measurements.
- **The doc viewer and drafts.html rich content** — `renderMd` gained lazy
  continuation and GFM, but the doc viewer was never re-checked after either.
- **Light theme** is verified on the surfaces touched today and nowhere else.
- **Nudge delivery to a live peer** was verified as far as target resolution only.
- **vb-fable's decision-surface report** (#48, #49) arrived at the end and is
  unassessed beyond the one fix; their (b) and (c) are unbuilt.

## 5 · What the plan must decide first

1. **The branch.** Owner ruling: sweeping changes go on a branch and merge later,
   or keep the original copy. Nothing is committed, so the plan opens by deciding
   how today's work lands before adding to it.
2. **Whether §17 runs, and against what.** It was displaced once already.
3. **Scope of "improve the editing surface everywhere" (#13)** — the one ask still
   open with no boundary on it.
4. **vb-fable's answer path (#48)** — build a decision kind, or tell them the
   board is not that surface.

## 6 · Compliance pass the owner asked for

For every row in §1: name the check that proves compliance, or mark it
UNVERIFIED. Rows marked shipped carry a verification note in the task store
(`session-f00a0017`, `task.sh show <id>`), which is where the evidence lives.
`shipped` in this file is a pointer to that note, not a substitute for it.
