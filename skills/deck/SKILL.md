---
name: deck
description: Turns a source document (or the conversation) into one self-contained HTML slide deck with a synced presenter-notes window, verifies that no slide overflows by measuring pixels, runs a lightweight prose gate, and refuses to hand over a deck whose claims a reviewer cannot trace to a source line. Fast by default; the agent writes DECK.md and the scripts own every other decision. Use when asked for a deck, slides, a presentation, a talk, or a walkthrough someone will present.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent
user-invocable: true
argument-hint: "<source.md | topic> [--outline] [--check <deck.html>] [--review <deck.html>] [--in-project] [--deep] [--publish]"
---

## Brief

`/deck` makes a slide deck the way three real decks (automation, vb-fable, gcc-fable,
all 2026-08-17) turned out to need: one HTML file that opens on a double-click, no
library, no build, no network; an overflow check that looks at pixels because that was
the first failure all three hit; presenter notes that never appear in the room; and a
reviewer that traces every claim to a source line, because that reviewer found 3
contradictions and 16 overstatements in a deck its author thought was clean.

The agent's job is **content and structure**. Everything else, the theme, the chrome,
the keyboard, the notes window, print, deep links, the overflow estimate, the colour
rule, the prose gate, is a script (`~/.claude/scripts/deck/`). Owner, 2026-08-18: "remove
as much scaffolding / decisions / basic functional validation out of the agent's hands".

## Step 0

Read `~/.claude/skills/GUIDELINES.md` and this skill's `runtime-notes.md` if present.

## Usage

```
/deck <source.md | topic>            gather → outline → author → render → check → lint → review → deliver
/deck --outline <source.md>          stop after the outline (a DECK.md skeleton with slide titles only)
/deck --check <deck.html>            only the overflow / theme screenshot pass
/deck --review <deck.html|DECK.md>   only the claim-tracing reviewer
/deck --deep                         the escape hatch, see below
```

Output, owner ruling 2026-08-18: decks live in the gcc, `~/.claude/assets/decks/<YYYYMMDD>-<slug>/`
(`DECK.md`, `deck.html`, `check/`, `review.md`), never in a project's local `.claude/output`.
`--in-project` puts them at `<project>/deck/` instead, when the deck belongs to the repo.
Nothing leaves the machine by default: `--publish` (an Artifact) is OFF ALWAYS and only
runs when the owner asks for it in that turn.

## The phases, and who owns each

| phase | who | what |
|---|---|---|
| gather | agent | read the sources; write the **claim ledger**: every number, ruling and quote you intend to use, each with `file:line`. Ten lines in the reply, not a document. |
| outline | agent | the advisory skeleton (below), edited to the argument. Stop here on `--outline`. |
| author | agent | write `DECK.md` against the ledger, in the source shape `render.py` documents (`python3 ~/.claude/scripts/deck/render.py -h`). One claim per slide. Notes are full sentences. |
| render | script | `render.py DECK.md` → `deck.html`. Refuses an over-budget slide (estimate) or a colour literal; fix the markdown, do not add flags. |
| check | script | `check.sh deck.html`: headless Chrome measures real overflow at 1440x900 and 1920x1080, screenshots the first bad slide (or slide 1) in both themes. **Open the PNGs and look** before going on. |
| lint | script + agent | `lint.py DECK.md`, the prose gate. The loop is fixed, see below. |
| review | one opus seat | `review-prompt.md`, filled and dispatched (model **opus**, read-only, no nesting, output written to disk). Fill `{{DECK_MTIME}}` from the live file, not from memory. CONTRADICTED or UNSOURCED blocks hand-off; OVERSTATED is listed. **Read the report back and state its verdict in your own reply** before handing anything over. |
| deliver | agent | paths, the check summary line, the lint outcome, the review counts, an `:::open` line for the deck. |

### The prose-gate loop (owner ruling 2026-08-18, verbatim in short)

"Not a heavy review, just enough to catch offending issues; if the first run gives
more than 2 issues, then after the fixes the agent must re-run and fix again; the
agent MAY ignore some feedback, but with justification."

1. Run `python3 ~/.claude/scripts/deck/lint.py DECK.md`.
2. Zero to two findings: fix them or justify each in one line, then continue.
3. Three or more: fix, **re-run**, fix again, until it is clean or every remaining
   finding carries a one-line justification in the delivery message. Never a third
   pass without saying why the second was not enough.
4. `lint.py` is the whole gate. Do not add `/skeptical-review`, `/validate` routing,
   or a second reviewer unless the owner asks or `--deep` is on.

### The advisory skeleton (#81, ruled advisory 2026-08-18)

```
1  title + sub                     what this is, one line
2  the problem                     one claim
3  (optional) the second problem   automation's opening; keep only if there are two
4  one picture                     a diagram slide
5..n  one claim per slide          value / decisions / findings, each with its number
n+1  honest numbers                a table with a caveat column, includes what is NOT proven
n+2  the ask / what is next        bullets + :::open rows
```

Reorder, drop, add. Say in the delivery message where you left the default and why.

## Fast by default; `--deep` is the escape hatch

**The review's verdict is in-band or it does not exist.** Write the report to disk, then
READ IT BACK and put its counts in your own reply: supported, overstated, contradicted,
unsourced. A CONTRADICTED or UNSOURCED row blocks hand-off, and you cannot be blocked by
a file you never opened. On 2026-08-18 automation's review found a flatly false claim
they had written and believed, and they learned it existed only because a peer messaged
them: the report had landed in a directory nobody reads. A gate whose output the agent
does not read is not a gate (owner ruling 2026-08-20).

Default is the table above, once, with no e2e suite and no second reviewer. If the
owner asks for more, or you believe this deck needs it (a board audience, numbers that
will be quoted back, a deck that supersedes a source of record), **offer** `--deep`
in one line and wait: it adds a second reviewer seat with a different lens, both
themes screenshotted for every slide, and a `/skeptical-review` of the DECK.md. Never
default to it; a month of use decides what stays.

## The theme is the approved look, and regeneration restyles

The renderer's one theme IS the deck look the owner approved on 2026-08-17
(versable-builder `20260817-presentation/deck.html`): centered slide-inner at 920px, its
palette, gradient kicker and stat numbers, the `leave:` take-away line, the pill "Show"
row, round chrome. **Regenerating any deck through `/deck` restyles it to this look; say
so in the delivery message when the deck existed before.** Changing the theme needs a
side-by-side screenshot pair and the owner's word (atone `mist-20260818-151647-b8`).
`check/` beside a deck holds screenshots and is gitignored by `check.sh`; never commit it.
The reviewer's counts go in the delivery message, in-band, not only in its file.

## Conventions the renderer already applies (do not re-decide them)

- One theme, dark first, light on toggle; nine tokens; no accent choices; a colour
  literal in slide content is an error. Type ramp and kicker idiom follow
  versable-builder's docs conventions (`docs/design-language/12-typography.md:13-16`,
  `01-foundations.md:45`, `09-page-composition.md:28-29`): roles not sizes, mono only
  for identifiers, an 11px/600/0.08em uppercase kicker, buttons never underline, prose
  links do, one prose measure (68ch), containers widen and prose never does.
- Icons: a five-item inline registry (theme, notes strip, notes window, and the
  toned cells' colour), nothing else; vb's rule is "icons from the registry, never at
  a call site" (`02-buttons-and-actions.md:40-41`).
- Callouts, neutral: `note`, `tip`, `quote`, `aside`, `term`. Visual: `info`, `ok`,
  `warn`, `bad`, `stat`. Tables tone a `ruling` / `caveat` / `status` / `verdict`
  column by cell value.
- Presenter notes: `> notes:` lines; shown only in the `?notes=1` window (button
  "notes ↗", opens on a second screen, synced over BroadcastChannel) or the `n` strip.
- Keys: arrows, space, PageUp/Down, Home/End, `n`, `t`. Deep link `?s=N`, `?light=1`.
  Print: one slide per page.

## Runtime notes

Prepend to `~/.claude/skills/deck/runtime-notes.md` per GUIDELINES.md §7 after each real
deck: what the outline became, what lint caught, what the reviewer caught.
