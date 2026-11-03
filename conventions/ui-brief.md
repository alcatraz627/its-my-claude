---
brief: The short brief to read before writing any UI, internal tools included, with each rule's check. Injected by a hook on the first UI edit.
triggers:
  - topic:ui-design
  - topic:html-output
  - topic:dashboard-tool
  - topic:small-tool
  - skill:build-ui
  - skill:bloop
  - phrase:"service hub"
related:
  - conventions/visual-design.md
  - conventions/pages.md
  - conventions/dashboard-tools.md
  - conventions/ui-charter.md
  - rules/ui-visual-verification.md
tier: 2
category: conventions
updated: 2026-11-03
stale_after_days: 180
---

# Before you write UI

A small local tool gets the same care as a product page, and passing the page check does not cover it. The check proves the page works. It says nothing about whether the page reads well, and the owner rejects pages on sight that pass it.

Owner, 2026-11-01: "needs a much better UI, the html and ui best practices for various aspects. Sigh, I have to keep repeating this feedback".

## Before the first line of markup

1. Say the one decision the page serves, and what a first-time reader must manage in 10 seconds.
2. Read `conventions/visual-design.md`, and run `frontend-design` for anything new or reshaped. An existing surface goes through `/ui`, which needs a list of what it does today.
3. Look up what the owner already rejected on this surface: its charter (`conventions/ui-charter.md`), its git log, and `rg -il "<surface name>" ~/.claude/memory ~/.claude/projects/*/memory`. A fix that restores a rejected look is the worst outcome here. It nearly happened on the hub: the cure for "this looks like plain text" was a boxed dropdown and a blue button on every row, the exact look already rejected.
4. Open one sibling page and follow it, or say in a sentence why this one differs.

## What the owner sees first

Owner, 2026-11-03, on a page that passed every check and an independent review: "My gripe is what I see." The kit now carries most of this, so use it and do not rebuild it.

| Rule | Check |
|---|---|
| A favicon, a meta description and an svg icon in the bar. `pagekit.page(icon_name=..., description=...)` gives all three | `check_page.py` prints a note when one is missing |
| The theme switch looks the same on every page: the kit's one icon, never a word or a homemade control | Compare against any kit page |
| Buttons are plain: an icon and a word, or an icon with a tooltip, and a shade on hover. Use `.kit-btn` and `.kit-icon-only`. A border or a fill needs a reason | Read computed border and background at rest |
| Every button that acts has an icon, from the kit's sprite, and every icon-only control has a tooltip and a label | Search the rendered page for controls without an svg or `data-tip` |
| The bar, search and alerts belong to one design: same background, same control height, same radius as what is below them. Search can live in the bar | Screenshot the top 200px and ask whether they look like one page |
| No footer of words nobody reads. Key lists and explanations go in a help icon's tooltip | Read the last line of the page and ask who it is for |

## What the page must do

Each rule was missed on a page that passed every check, and each check is one you can run.

| Rule | Check |
|---|---|
| Say what each column or value is. A bare "Never" or ":5106" means nothing to a first reader | Cover the code and name every value on screen from the page alone |
| The common action carries the weight. Starting a process must not look louder than opening a running one | List the row's controls by visual weight, then by how often each is used. The orders match |
| Colour means state. No brand fill repeated down a list; a crash must be the loudest thing on the page | With a crash on screen, it is what the eye lands on first |
| Status outranks settings. What a reader came for is the bright text, and what they rarely change is not | List the row's text by brightness: state comes first |
| One question gets one place. When two columns answer "when will this stop", write one sentence instead. A table with a dropdown on every row reads as a form, whatever its colours | Say aloud what each column answers, and merge any that overlap |
| A setting can live in the sentence it changes, with its box and arrow only where a pointer or keyboard is | Hover and tab to it, and check touch, where nothing can hover |
| An action that moves rows must not put the next row's action under the pointer. Anything that stops or deletes takes two presses | Click the same spot twice: only one thing happens |
| A warning means the same on every row. Decide it from what the reader feels (minutes left), not a share of each row's own limit | Compare two rows: the one closer to the event never looks safer |
| One thing has one name in the heading, menu, keys legend and labels | Search the source for every name of the setting |
| Rows share one height and actions share one edge | Compare the height and left edge of every row's controls in the browser |
| A size step keeps the layout. If text grows, the page width grows with it, or `em` breakpoints collapse columns on a wide screen | Render md and lg at 1440, and compare with sm: same columns |
| The theme follows the OS until the reader chooses | Load with no stored choice, under OS light and OS dark |
| Words fit their control at every width, and wrap rather than clip | `scrollWidth > clientWidth` is empty for every control at 1440, 1024, 820 and 390 |
| Data is written for people. Agent bookkeeping ("retro-claim of orphan vite fleet"), raw ids and reasons shown as descriptions do not reach the screen unedited | Read the page with real data, not a fixture you wrote |
| Rare facts stay out of the way, and one fact shows once | Machine-wide facts show once, at the top |
| Keyboard use keeps your place. An action must not drop focus, and every row can be reached | Press the action's key, then the next key, and see that it still works |
| Loading, empty, error, busy and recovered each have their own surface | See the next section |

## See the states today's data does not show

The live page usually shows the calm case. The hub's real data had no crash and no running countdown, so those states would never have been looked at.

Serve the page's API from a stand-in in the browser test and induce them: crash, low countdown, booting, failed read then recovery, failed action, nothing to show. This also means no check ever stops a real service. Worked example: `~/Code/Claude/sys-pier/hub/ui-check.py`.

## Before you call it done

- Keep the checks in a script beside the project, so a later change can fail them.
- Break two things on purpose and watch the checks go red. A check written after a bug was seen is the one most likely to pass by accident.
- Read the render. A green script missed text running into the next button at 820 wide, and a screenshot caught it.
- Make a check measure what it claims. A row named "a crash stays the loudest thing" only tested that no button was blue, and it passed while the crash was one small dot.
- Have someone who did not write it read it: `/ui-categorical-check`, or one review seat told to say what the owner would reject.
- Report what you looked at and name the states you did not.
