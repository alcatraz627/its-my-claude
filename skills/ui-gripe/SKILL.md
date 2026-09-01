---
name: ui-gripe
description: Diagnoses WHY a UI feels stupid, confusing, or frustrating — runs the local see --ui structural inventory as $0 ground truth, then a native-vision judgment pass to name what is fighting the user, ranked by damage, each finding tied to visible evidence and a concrete fix. Use when the user vents about a UI ("this is so confusing", "why is this dashboard stupid"), when a review agent needs a confusion audit rather than an aesthetic score, or before redesigning a screen that "feels wrong". For scored aesthetic critique against the terminal-dashboard fingerprints, use /designer-reviewer instead.
allowed-tools: Read, Bash
user-invocable: true
argument-hint: "[screenshot-path] [the gripe, in the user's words]"
context: fork
---

## Brief

Turns "this UI is stupid" into a named, evidenced diagnosis. The local `see --ui` read
enumerates what is actually on screen (regions, elements, states, hierarchy — at $0, no
API spend); the skill then judges the screenshot natively and explains what is fighting
the user, ranked by damage, each cause tied to evidence from the inventory and paired
with a concrete fix. Division of labor is fixed: **local vision enumerates, Claude
judges** — never the reverse.

# UI Gripe — confusion forensics for a screenshot

## Usage

```
/ui-gripe [screenshot-path] [gripe...]
```

- `screenshot-path` (optional): PNG/JPEG/WebP of the offending UI. If omitted, ask for
  one — or offer `see --menubar` capture if the gripe is about something on screen now.
- `gripe` (optional): the complaint in the user's own words ("I can never find the save
  button", "everything looks clickable", "it's just stupid"). Even a vague gripe steers
  the diagnosis; no gripe means a general confusion audit.

## Step 0: Load Shared Guidelines and Runtime Context

Read `~/.claude/skills/GUIDELINES.md`. Apply all rules — forbidden paths, retry logic,
tool preferences, verbosity, timeouts, post-run insights, and the file lock protocol —
for the entire duration of this skill run before proceeding.

Also read `~/.claude/skills/ui-gripe/runtime-notes.md` for past run history relevant to
this skill. If it does not exist yet, continue without it.

## Phase 1 — Resolve the inputs

1. Validate the screenshot path exists and is an image. If no path was given, ask for
   one (or, when the gripe is about the live screen, offer to capture: full display via
   `screencapture -x`, or `see --menubar` for the top strip).
2. Restate the gripe in one line as a testable frustration ("user cannot locate the
   primary action" / "user cannot tell what state the app is in"). If there is no gripe,
   the working question is "what would confuse a first-time user most?"

## Phase 2 — Local structural inventory ($0 ground truth)

If `see` is on PATH (the local-models vision tool), run both:

```bash
command -v see >/dev/null 2>&1 && see "<screenshot-path>" --ui
```

This returns the sectioned inventory: KIND / LAYOUT / HIERARCHY / ELEMENTS / ICONS /
PATTERNS / PALETTE. Treat it as the **enumeration layer**: it is measured to fabricate
nothing, but its exact strings are good-but-verify (near-miss OCR substitutions happen).
When the gripe points at one area, also grab a focused read — crops read near-perfectly:

```bash
see "<screenshot-path>" --region <top|bottom|left|right|center> --ui
```

Each read lands an artifact folder (`see open -1`) — cite it in the report so the
evidence is revisitable. Record intermediate observations with `see note "..."`.
Skip this phase silently if `see` is not installed (the diagnosis then rests on the
native read alone; say so in the report).

Two more evidence lanes; reach for whichever the case calls for:

- **Exact text (any pixels):** `see <shot> --ocr` — Apple Vision verbatim text,
  ~300ms, no model. Run it before quoting any label/value in a finding: the `--ui`
  read's strings are good-but-verify, OCR is the verifier.
- **Native Mac apps (the gripe is about a RUNNING app, not a web page/screenshot):**
  the accessibility tree is exact and semantic — `ax tree --app <Name> -d 6 --json`
  for structure, `lm ui-verify --app <Name> "claim"` to rule on specific facts
  (element present, state, label). Prefer it over pixels whenever the app exposes a
  real AX tree; fall back to screenshot lanes when it doesn't (many Electron/web
  views expose little).

## Phase 3 — Native judgment read

`Read` the screenshot yourself. The inventory says WHAT is there; you decide what it
MEANS. Walk the confusion-forensics rubric against both:

1. **Hierarchy fight** — does any single element dominate? Count the elements competing
   at the top visual level (the inventory's HIERARCHY tree gives the census). More than
   one dominant = the user's eye has no entry point.
2. **Accent dilution** — what carries the accent color, and how many different meanings
   does it carry? (PALETTE + ELEMENTS give the census.) An accent that means
   selected AND destructive AND decorative means nothing.
3. **Affordance ambiguity** — which elements look interactive but are not, and which are
   interactive but look static? (ELEMENTS states vs visual treatment.)
4. **State legibility** — can the user tell what mode/state the app is in right now, and
   what just happened? Look for missing feedback: selected-vs-hover, saved-vs-dirty,
   loading-vs-stalled.
5. **Pattern breaks** — where does the UI violate its own conventions? (PATTERNS section
   vs the outliers.) Internal inconsistency costs more than any single bad choice.
6. **Label opacity** — jargon, icon-only controls with non-obvious glyphs (ICONS
   section), truncated labels the user must guess.
7. **Density mismatch** — crowded where the user needs calm, empty where they need
   information. Tie to LAYOUT region shares.

The gripe picks the entry point: start the walk at the rubric item the complaint points
to, but complete the walk — the named symptom is often downstream of a different cause.

## Phase 4 — The diagnosis report

Output in this order, prose-first, no scores:

1. **The gripe, translated** — one sentence: what the user is actually unable to do.
2. **What's fighting you** — the top 2–4 causes, ranked by damage. Each cause: a name
   (from the rubric), one sentence of mechanism, the evidence (cite the inventory line
   or region — "HIERARCHY shows three peers at level 1", "ELEMENTS lists 6 accent
   buttons with different verbs"), and the fix (concrete: a CSS/layout/copy change, not
   "improve hierarchy").
3. **What to keep** — 1–2 things that are working, so the fix doesn't bulldoze them.
4. **The one change** — if only one thing gets fixed, which, and why it unblocks the
   gripe.
5. **Evidence trail** — the `see` artifact folder path(s) for revisiting.

Do not pad: a UI with one real problem gets one finding. If the gripe is not supported
by the evidence (the UI is fine, the user is tired), say that plainly — with the
evidence — rather than inventing findings. See `rules/pushback-and-self-criticism.md` § 3.

## Anti-patterns

- Scoring aesthetics — that is /designer-reviewer's job; this skill answers "why is it
  confusing", not "how pretty is it".
- Trusting the inventory's exact strings without verifying load-bearing ones natively
  (local OCR near-misses; verify before quoting a label in a finding).
- Letting the local read do judgment ("see said the hierarchy is unclear") — see
  enumerates; the judgment and its justification are yours.
- Diagnosis without a fix. Every named cause carries a concrete change.

## Post-run

MANDATORY, every run (unlogged usage is invisible to the adoption audits; the
2026-08-10 review nearly retired this lane on missing telemetry):

```bash
bash ~/.claude/scripts/skill-log.sh record ui-gripe \
  --task "<surface griped, one line>" --outcome <ok|revised|failed> --corrections <n> \
  --note "findings=<n> surface=<path-or-url>"
```

Per GUIDELINES.md, also prepend a short entry to `~/.claude/skills/ui-gripe/runtime-notes.md`
(purpose + 2–4 insights) when the run surfaced anything reusable — a rubric item that
keeps firing, a see read that needed a crop, a gripe class this skill handles badly.

## See also

- `/designer-reviewer` — scored aesthetic critique against the user's fingerprints
- `/web-design` — generation + systematization, with the same see --ui pre-pass
- `~/Code/local-models/docs/CAPABILITIES.md` — the see/q/lm command menu

## Findings the owner confirms become callout rows

A finding that stays prose regresses unseen. When the owner confirms a finding (or
made it themselves), record it:
`bash ~/.claude/scripts/callouts/callouts.sh add "<their words>" --surface <s> --check "<re-verify how>"`.
The next done-claim on that surface must pass `callouts.sh gate <s>` (see /callouts).
