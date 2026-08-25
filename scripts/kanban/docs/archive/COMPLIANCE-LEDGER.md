# Compliance ledger

Every ask the owner made (seed §1), and for each one the check that proves what
shipped complies, or an honest UNVERIFIED. Written 2026-08-23 on branch
`kanban/aug22-sweep`. Evidence for a "recorded" check is the task store note
(`task.sh show <id> --session f00a0017`), which carries the measurement and its
date; "re-run today" means this session executed it again.

Status vocabulary: **COMPLIES** (a check exists and passed, date given) ·
**RECORDED** (a check passed on 2026-08-22 and was not re-run today; the note
holds it) · **DISPUTED** (two records disagree; the ledger says which is right)
· **PARTIAL** · **NOT DONE** · **DEFERRED** (owner ruling) · **UNVERIFIED**
(shipped but no check anyone can point at).

## V3, 2026-08-22

| # | Ask (owner's words) | Status | Check |
|---|---|---|---|
| 2 | "Pressing any key in the help screen closes it, only esc key should" | RECORDED | key matrix in the note: j a ↵ Space ↓ x / swallowed, Esc and ? close, Tab traverses. Re-run: open `?`, press `j`, modal stays. |
| 3 | "'Hey Claude' Put the note tags section below 'The Example Card'" | RECORDED | scroll range 552 → 288 px, measured. Re-run: `HELP-MODAL-SCROLL-PARITY.md` procedure on the Hey Claude tab. |
| 4 | "'Keyboard': rows below the preview in 2 cols" | RECORDED | 637 → 233 px; 6 groups, 0 split, 0 orphaned heads. Re-run: same parity procedure, Keyboard tab. |
| 5 | "maximising space utilization without asking for more" | COMPLIES | charter §18 exists, dated 2026-08-22 (`UI-CHARTER.md:369`). |
| 6 | "Allow marking / unmarking a board as active for me" | COMPLIES, re-run today | hub a11y tree shows the archive toggle on every row; Archived folds with its count. Gap: the button has no accessible name (catalog §1). |
| 7 | "a lot of older boards show up" | COMPLIES, re-run today | hub today: WANTS YOU 7, QUIET 2, no Archived group because none archived; tiers render per `hub.html:496-499`. |
| 8 | "Enable auto-save" | RECORDED | 1500 ms debounce; a new editor typed into for 2.6 s minted nothing (guard exercised). `test-drafts.sh` covers the save path, 68/0 today. |
| 9 | "better visual identification in the editing / preview surface" | RECORDED | writing surface raised to `--card` in both themes, measured identical-to-body before. Independence UNCONFIRMED (memo numbers run by their author). |
| 10 | "Can we get gfm working here?" | RECORDED | strikethrough, emphasis, autolinks, task checkboxes; `test-drafts.sh` renderMd rows. Doc viewer NOT re-checked after the change (seed §4). |
| 1 | "'Offer to a session' -> doesn't work" | COMPLIES | root-caused (`isPulled` keyed on id alone; no drafts block in `session-start-line.sh`); both halves mutation-tested; owner's own re-offer proved it live. Today: `kanban.sh drafts` lists the pending draft. |
| 13 | "Need to improve that everywhere" (editing surface) | PARTIAL, NOT DONE | no boundary on the ask. Opening decision 3 below. |
| 12 | "Need a persistent undo/redo" | RECORDED | buffer-level stack survives `render()`; ⌘Z / ⌘⇧Z / ⌘Y; 600 ms coalescing. Re-run: type, rebuild editor (switch mode), ⌘Z restores. |
| 11 | "The editor in the drafts is eating up chars" | RECORDED | probed to mechanism (poll `render()` rebuilt the textarea mid-edit); guard added; `test-drafts.sh` row. |
| 26 | "let the agent see the editing history ... a timestamp and some form of a diff" | RECORDED | LCS line diff on pull after a revision, 120k cap, "cannot diff" honesty path for pre-snapshot pulls. Today: the V3 draft row reads `pulled 48m ago`, pull note inline. |
| 27 | "save and later pull verbatim user input from the chat ... /plan" | DEFERRED | owner ruling. |
| 13b | "images and links and tables and other stuff" | PARTIAL | autolinks shipped; images and tables folded into #13. |
| 14 | conversation history per board | DEFERRED | owner ruling. |
| 15 | "/plan for how to support this on the phone" | DEFERRED | owner ruling. |

## V4, 2026-08-22

| # | Ask | Status | Check |
|---|---|---|---|
| 34 | "Allow all actions to be via keyboard, eg: open / close is still via click" | RECORDED | `toggleSide()` bound to `\|`; key and button share one function. Today: help Keyboard tab lists `\|` for the sidebar. |
| 35 | "Middle click on a card ... toggle add / remove ... without stealing focus" | RECORDED | gesture measured before change; focus theft and collapse state were already fine; toggle added. Re-run: middle-click twice, selection count returns to 0, `document.activeElement` unchanged. |
| 36 | "column 'settings' popover has too much vertical space on top" | RECORDED | 29.6 px above vs 13 below; UA `h4` margin; now symmetric. Today: popover opens with heading, count, width slider, title length, reset, Done. |
| 37 | "Action buttons should not wrap text + use icons and tooltips" | PARTIAL | board + drafts: glyphs 5/5, tips 5/5, one control-row height. **hub never audited** (#46); catalog §1 finds 18 unnamed icon buttons there. #45: eight board buttons still typed dingbats. |
| 38 | "See what else can be added to column settings" | NOT DONE | needs a proposal; popover today is width + title length. |
| 39 | "pair it with filter views that both the agent and I can create / update / delete" | NOT DONE | P1, unbuilt. |

## Asked in conversation

| Ask | Status | Check |
|---|---|---|
| "ensure a standard UI is conformed to" | ONGOING | charter is the standard; §14 round after each change (ran 2026-08-22), §17 never run (#16). |
| "prepare a charter we can use and keep adding to" | COMPLIES | 19 sections, changelog §19 dated; three rulings appended on the day. |
| "I don't want a 100 subagent run I want it capped" | COMPLIES | zero sub-agents on 2026-08-22 and today so far. |
| unify the two nav models, charter first | PARTIAL | `NAV-UNIFICATION.md` + slice 1 (switcher, sectioned). Per-kind index pages NOT done. |
| "add the charter to the help modal as a tab" | COMPLIES, re-run today | `/api/charter` route at `server.ts:517`; tab present in the modal markup (`board.html:1362`). |
| help modal table hierarchy consistent | RECORDED | one table treatment, 5 px padding. |
| sticky top section per tab, "not hey claude" | RECORDED | sticky on Keyboard, Taxonomy, Vibe Code; excluded on Hey Claude. |
| "no scroll hiccups ... don't cause a mess here" | RECORDED | parity check, three re-runs, every tab 0/0, with the positive assertion (modal open, pane scrolled). |
| "Make and update a kanban board for this session itself" | COMPLIES, re-run today | board `.claude` shows milestone `aug22-kanban` on 41 cards (sidebar count today: 41). |
| search "needs more visual hinting ... chips / tabs / suggestions" | **DISPUTED → COMPLIES**, re-run today | seed §1 and the checkpoint said shipped; task store #41 was still `pending`. Exercised today: `/` with nothing typed renders a hint line and 8 pressable chips (blocked, unread, needs you, milestone, @me, plus 3 board tags), `board.html:4339-4357`. The store lagged; closed today with this note. |
| Q1 ruling "B + C" | COMPLIES | charter §4 amended, dated. |
| Q2 ruling, third mode | RECORDED | Edit / Live / Preview buttons present today; Live behaviour per #33's note. |
| "sweeping changes in a branch" | COMPLIES, today | `kanban/aug22-sweep` at `6de4e97`; `main` at `e1783d3`. |

## What no check covers (carried caveats, none retired)

1. Independence of the direction memo's numbers.
2. Five composite control states (charter §7).
3. `prefers-reduced-motion`.
4. Concurrent edits to one note body.
5. Nudge delivery to a live peer, end to end.
6. The doc viewer after `renderMd` changes.
7. Light theme on surfaces not touched 2026-08-22.
8. Every commit unreviewed by an independent seat, including today's.

## Corrections this ledger makes to earlier records

- #41: the seed and checkpoint said shipped, the task store said pending. A
  first read of the store sided with the store; a grep and a live run proved the
  chips exist and render. Lesson re-learned: when two records disagree, the
  verdict comes from exercising the surface, not from picking the record that
  sounds more careful. Store closed today.
- Charter §16's `title=` count: `board.html` has exactly one, and it is the doc
  modal iframe's name, which is not a tooltip. Record it so the count reads
  true rather than as a violation.
