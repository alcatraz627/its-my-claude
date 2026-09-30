---
name: banner-fun
description: Render a daily fun terminal banner with weather, quote, moon phase, and code riddle. Use for the daily fun banner — not dev metrics, which live in the statusline.
user-invocable: true
---

# banner-fun — Daily Fun Terminal Banner

Renders a daily terminal banner with weather, quote, moon phase, and code riddle. Pure fun — no dev metrics (those live in the statusline).

## Step 0: Load Shared Guidelines

Read `~/.claude/skills/GUIDELINES.md`. Apply all rules for the duration of this skill run.

## Usage

```
/banner-fun [--module MODULE] [--refresh] [--setup]
/banner-fun --answer RIDDLE_ID
/banner-fun --list-quotes [--topic TOPIC]
/banner-fun --add-quote | --remove-quote | --edit-quote
/banner-fun --list-riddles [--category CAT]
/banner-fun --add-riddle | --remove-riddle ID | --edit-riddle ID
```

## Script Location

`/Users/alcatraz627/Code/Claude/banner-fun/banner-fun.py`

Run with: `/usr/bin/python3 /Users/alcatraz627/Code/Claude/banner-fun/banner-fun.py`

## Phase 1 — Route the Command

Parse the user's intent from the `/banner-fun` arguments:

| Intent | Action |
|--------|--------|
| No args | Render full banner (all 4 modules) |
| `--module weather\|quote\|riddle\|moon` | Render single module |
| `--refresh` | Flush caches, re-fetch |
| `--setup` | Run interactive setup wizard |
| `--answer ID` | Reveal riddle answer |
| `--list-quotes [--topic T]` | List stored quotes |
| `--add-quote` | Interactive quote add |
| `--remove-quote --topic T --index N` | Remove a quote |
| `--edit-quote --topic T --index N [fields]` | Edit a quote |
| `--import-quotes FILE` | Bulk-import from JSON |
| `--list-riddles [--category C]` | List riddles |
| `--add-riddle` | Interactive riddle add |
| `--remove-riddle ID` | Remove riddle by ID |
| `--edit-riddle ID [fields]` | Edit riddle by ID |
| `--import-riddles FILE` | Bulk-import riddles from JSON |

## Phase 2 — Execute

Run the script with appropriate flags:

```bash
/usr/bin/python3 /Users/alcatraz627/Code/Claude/banner-fun/banner-fun.py [ARGS]
```

Print the output directly to the user. No reformatting.

## Phase 3 — Offer Next Steps

After rendering, offer:

```
Options: --refresh (re-fetch), --module <name> (single module),
         --add-quote / --add-riddle, --setup (change location/theme)
```

## README banners (a different job from the daily brief)

When the owner asks for a "/banner-fun banner" on a repo or README, they mean a
**graphic** in this banner's frame language, not the terminal text. An ASCII block
in a code fence was rejected ("svg is fine but a banner buddy a banner").

- **Deliverable:** a 1280x480 SVG at `.github/readme/banner.svg`, shown first in
  the README with `<img width="100%">`. A 16x16 pixel emblem as
  `.github/readme/favicon.svg` sits beside the title. The riddle's answer goes in a
  `<details>` block below the intro.
- **Frame language:** dark card, double accent border, ◆◆ rails, ⊕ TITLE ⊕, a
  quote-of-the-day and riddle card, a ⊙ footer. Keep it recognisably one family;
  rearrange freely.
- **Content comes from the project.** Read the README first. Stats, flows and
  labels are real numbers, commands and names from it. The quote is real and
  correctly attributed. The riddle's answer is a concept specific to this repo.
- **Creative take:** follow `/svg` Phase 1b. Stage the project as a real-life human
  scene built from pixel sprites, and offer three different takes. Three panels
  (facts, flow, quote) suit repos with real numbers and a pipeline; a hero or
  terminal layout suits apps and CLIs. A scene beats all three when the owner
  wants character.
- **Check before handing over:** render with headless Chrome and look at it; no
  internal words (file names, "variants.json") anywhere in the art; the footer
  points at the riddle answer. For a bulk run, use a decision page that shows the
  current banner as a thumbnail beside the candidates.

## Modules

| Module | Data Source | Cache TTL | Notes |
|--------|-------------|-----------|-------|
| weather | wttr.in + Open-Meteo | 1 hour | Current + 12h hourly + 14d forecast |
| quote | Local JSON (data/quotes.json) | None | Date-seeded, 5 topics, 30+ quotes each |
| riddle | Local JSON (data/riddles.json) | None | Date-seeded, 6 categories |
| moon | Pure Python astronomy | 1 hour | Jean Meeus, phase/illumination/distance/zodiac/tides |

## Data Files

- Quotes: `/Users/alcatraz627/Code/Claude/banner-fun/data/quotes.json`
  - Format: `{"topics": {"finance": [...], "technology": [...], ...}}`
  - Each entry: `{"text": "...", "author": "...", "year": YYYY}`
  - Topics: `finance`, `politics`, `technology`, `philosophy`, `math_science`

- Riddles: `/Users/alcatraz627/Code/Claude/banner-fun/data/riddles.json`
  - Format: `[{"id": "r001", "category": "...", "difficulty": "...", ...}]`
  - Categories: `output_quiz`, `find_bug`, `math_trick`, `logic`, `trivia`, `wordplay`
  - Difficulties: `easy`, `medium`, `hard`

- Config: `/Users/alcatraz627/Code/Claude/banner-fun/config.json`

## Performance Profile

```
Startup (interpreter + stdlib imports): ~40–80ms
Weather fetch (network):               200–800ms
Moon compute (CPU, cached):            0.05ms warm / 0.85ms cold
Quote select (CPU, no cache):          0.12ms
Riddle select (CPU, no cache):         0.08ms
Banner render (4 sections):            0.04ms
Parallel fetch wall time:              dominated by weather network
```

**Key insight:** When weather is disabled, parallel ThreadPoolExecutor adds overhead (~1.7ms vs 0.3ms sequential) because Python's GIL prevents true parallelism for pure-Python math. Parallelism only helps when I/O-bound weather module is active.

## First-Run Setup

Location detection is automatic on first render (via ipapi.co). Run `--setup` to manually configure location, enable/disable modules, or change theme.

Themes: `default`, `minimal`, `heavy`, `dots`
