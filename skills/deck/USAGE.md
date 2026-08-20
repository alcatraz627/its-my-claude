# /deck usage

```
/deck ~/Code/x/docs/plan.md            full run: ledger, outline, DECK.md, render, check, lint, review, deliver
/deck the goal re-arm work             from the conversation; sources are what you cite
/deck --outline ~/Code/x/docs/plan.md  outline only
/deck --check  ~/.claude/assets/decks/20260818-goal/deck.html
/deck --review ~/.claude/assets/decks/20260818-goal/DECK.md
/deck --in-project …                   write to <project>/deck/ instead of ~/.claude/assets/decks/
/deck --deep …                         second reviewer lens + every slide screenshotted + skeptical-review of DECK.md (offer, never default)
/deck --publish …                      Artifact publish; OFF unless asked in that turn
```

Scripts (`~/.claude/scripts/deck/`):

| script | does |
|---|---|
| `render.py DECK.md [-o deck.html] [--allow-overflow] [--allow-color] [--json]` | the deterministic renderer; `-h` prints the source shape and callout kinds |
| `check.sh deck.html [--all]` | headless Chrome overflow measurement at two sizes + screenshots (both themes) into `check/` |
| `lint.py DECK.md [--json]` | the prose gate: em-dash, one-claim, bullets, words, adjectives, triads, STE sentence length, notes voice, unsourced numbers |
| `review-prompt.md` | the claim-tracing reviewer, dispatched to one sonnet seat |
| `render.test.sh` | 32 rows: every slide type, refusals, notes isolation, lint fires |
| `fixtures/DECK.md` | a real ten-slide deck exercising every type; open `fixtures/deck.html` to see the theme |

Presenting: open `deck.html`, press the "notes ↗" button, drag that window to the second
screen. Arrow keys in either window move both. `n` toggles a dim notes strip in the
main window when there is no second screen. `t` toggles theme; `?s=N` deep-links a
slide; print gives one slide per page.
