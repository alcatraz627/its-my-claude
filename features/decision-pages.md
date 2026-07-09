---
brief: Interactive decision/feedback pages — when an agent needs a human verdict on MANY items (design review, migration plan, per-screen feedback), scaffold a pre-answered HTML page from the template instead of asking N questions; the human flips what's wrong and pastes ONE compact answer string back. Registry ~/.claude/assets/decision-pages/ served once by pm2 on :5197.
triggers:
  - tool:decision-page.sh
  - topic:decision-page
  - topic:feedback-form
  - phrase:"minimize the work I have to do"
  - phrase:"answer complex forms"
related:
  - conventions/html-output.md
  - features/dev-servers.md
tier: 2
category: features
updated: 2026-07-10
stale_after_days: 180
---

# Decision pages — structured human feedback with near-zero human effort

## When to reach for this

The moment a task needs the human to make **more than ~4 related judgments**
(per-screen design feedback, a migration go/no-go list, config triage), do NOT
serialize questions into chat and do NOT hand them an empty form. Build a
decision page: every item carries YOUR drafted answer + recommendation, the
human only flips what's wrong, then one button copies a compact answer string
they paste back. Authoring effort moves to the agent; the human's cost drops to
one skim + one paste.

Born 2026-07-09 in the versable-builder MVP-rework session: a 13-screen design
feedback pass became a 3-line paste. The owner asked for it as a standing
capability ("minimize the work I have to do").

## Mechanics

```
bash ~/.claude/scripts/decision-page/decision-page.sh new <slug> [--title "…"]
# → scaffolds ~/.claude/assets/decision-pages/<slug>/{index.html,config.json}
#   ensures ONE pm2 static server "decision-pages" on :5197 + a hub at :5197/
# agent then: writes real config.json + drops images
bash …/decision-page.sh check <slug>     # THE verification call before handoff
# → schema-lint (ids unique, exactly one rec:true per decision, images exist) +
#   HTTP-200 render check; every failure prints a "fix:" line; exits non-zero
#   until READY. Then hand the human http://localhost:5197/<slug>/
```

Full command set (each failure proposes its fix, agent-first per
`conventions/agent-first-tools.md`):

| command | does |
|---|---|
| `new <slug> [--title …]` | scaffold + print the agent TODO; refuses to clobber an existing slug (points at check/open/rm) |
| `check <slug>` | verify schema + images + render; **run before every handoff** |
| `list` | slug · item counts (`2d+5s`) · age · URL · title |
| `status` | server up/down + page count + hub URL |
| `open [slug]` | open the page (or the hub) in the browser |
| `serve` | ensure the pm2 server + regenerate the hub manifest |
| `rm <slug>` | trash a page |
| `prune --older-than <days>` | trash old pages (confirms on a TTY) |

The **hub** (`:5197/`) lists every page with a live status chip
(`untouched` / `viewed · as drafted` / `N flipped` / `broken config`), reads each
page's answers straight from localStorage, and can copy any page's answer string
without opening it. Regenerated (`pages.json` + `index.html`) on every mutating op.

Pages are TEMPORARY — the registry is a scratch surface, prune freely. State
(the human's picks) lives in THEIR browser localStorage, keyed per page.

## The page is keyboard-first (power-user surface)

The human never has to hunt with a mouse. On any page: `j`/`k` move between items,
`1`–`9` pick an option in the focused decision, `a` toggles agree, `n` jumps to the
note field, `f` shows only flipped items, `p` opens the answer-preview drawer (the
exact paste text, live), `c` copies, `t` themes, `?` shows the shortcut card. A
sticky header shows `N flipped` progress and the Copy button badges the deviation
count. "Untouched = agreed" so a full agree is one keystroke (`c`).

## config.json schema

```jsonc
{
  "title": "…header + tab title…",
  "storageKey": "unique-slug",          // localStorage key
  "copyHeader": "rework feedback",      // first line of the pasted answer
  "intro": "one-line contract note",
  "decisions": [                         // radio groups, answered as D1a D2b …
    { "id": "D1", "question": "…", "context": "…",
      "options": [ { "code": "a", "label": "…", "rec": true },
                   { "code": "b", "label": "…" } ] }
  ],
  "sections": [                          // item cards, answered as id: agree/DISAGREE — note
    { "id": "wm-01", "group": "Walmart", "title": "Dashboard", "prio": "MUST",
      "read": "my read…", "images": ["wm-01.png"],
      "slots": { "KEEP": "…", "CHANGE": "…", "VISUAL": "…" } }
  ]
}
```

Answer string shape (what the human pastes back — parse it leniently):

```
rework feedback:
D1a D2a D3c D4a
wm-01: agree — exception note…
sw-03: DISAGREE
```

## Rules for the authoring agent

- **Every option/section carries your draft + a recommendation** (`rec: true`
  on exactly one option per decision). An empty form defeats the purpose.
- Untouched = agreed is the contract — state it in `intro`.
- Images are optional but load-bearing for design feedback; screenshot first,
  reference by relative filename inside the slug folder.
- **Verify with `check <slug>`, not by eye** — one call lints the schema, confirms
  every referenced image exists, and checks the page renders (HTTP 200); it exits
  non-zero with fix-proposing lines until READY. Don't hand over an unchecked page.
- Template renders dark AND light (toggle built in) and is keyboard-first.
- The template + hub are generic — if they can't express something, extend the
  TEMPLATE (`scripts/decision-page/template.html`) or `hub.html`, not a one-off
  copy; that's how the capability compounds. The answer-string logic is mirrored
  in both the page and the hub — change both if you change the shape.
