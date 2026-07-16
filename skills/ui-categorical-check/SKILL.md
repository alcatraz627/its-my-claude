---
name: ui-categorical-check
description: Checks a UI change for CATEGORICAL bug-classes — the non-primitive defects that pass every DOM/behavioral assertion and only a human notices (a transparent floating layer, sibling controls at mismatched type scale, a height chain with no definite ancestor so the page overflows instead of scrolling inside, an action with no toast, a ghost-fade where a skeleton belongs). Runs a checklist MINED FROM THE USER'S OWN FEEDBACK HISTORY, not invented heuristics. Use before declaring a UI change done, or when a review keeps missing what the user then catches on sight. Sibling of /ui-gripe (per-screenshot confusion forensics), /designer-reviewer (scored aesthetics), /skeptical-review (grounded code review).
allowed-tools: Read, Bash, Grep, Glob, Agent
user-invokable: true
argument-hint: "[url-or-route] [what changed]"
---

## Brief

Behavioral verification and categorical correctness are **orthogonal**. A transparent
dropdown, a 900px table on a 1500px page, a mismatched font size, a missing toast, an
un-copyable cell — every one of these passes "the modal opens", "the filter filters",
"the chip reads right". They are caught by *measuring* and *comparing*, never by
asserting. This skill runs the measurements, driven by a catalog of the bug-classes
**this user has actually complained about**, so each round of their feedback becomes a
permanent gate instead of a lesson relearned.

# UI Categorical Check

## Usage

```
/ui-categorical-check [url-or-route] [what changed]
```

## Step 0: Load Shared Guidelines

Read `~/.claude/skills/GUIDELINES.md`. Apply all rules for the run. Also read this
skill's `runtime-notes.md` if present.

## Phase 1 — Load the pattern catalog (the checklist is DATA, not prose here)

The catalog lives with the project it was mined from, so it stays close to the feedback
that produced it:

- Versable: `speedway/.claude/output/20260714-ui-categorical/patterns.md` — speedway,
  NOT versable-builder. speedway tracks `.claude/output/`; versable-builder gitignores
  it, so a catalog written there would not survive a clone. speedway is also where the
  UI being checked actually lives.
- Otherwise: `<project>/.claude/output/*-ui-categorical/patterns.md`

Read it. It is a checklist of categorical classes, each carrying: what it looks like ·
why assertions miss it · **the mechanical check that catches it**. If no catalog exists
for this project, say so and offer to mine one (Phase 5) — do not substitute invented
heuristics.

## Phase 2 — Scope the check

Identify the changed surfaces (the diff, or the route the user named). For each, list:
every control added or restyled · every floating layer (dropdown, popover, tooltip,
modal, panel) · every container whose height or scrolling changed · every action that
mutates data · every loading/empty/error state · every place an identifier or key is
rendered.

## Phase 3 — Run the mechanical checks (this is the skill)

Drive the real app. For each catalog class, run its named check. The reusable ones:

- **Computed-style diff against neighbours.** For every control beside another control,
  read `font-size`, `height`, `border-color`, `color`, `background-color` from
  `getComputedStyle` and compare. Mismatched siblings are a finding, not a preference.
- **Opacity of floating layers.** Every popover/dropdown/menu panel must have a
  non-transparent `background-color` AND a border or shadow. Check it **while it overlaps
  content** — a screenshot at rest never shows this.
- **Box-model sanity.** Measure `scrollHeight` vs `clientHeight` on the page container,
  the card, and the intended scroller; measure each element's `bottom` against
  `innerHeight`. The page must not scroll when an inner region was meant to. A
  `height:100%` chain needs a **definite** ancestor height — `min-height:100vh` silently
  makes every child resolve to content-size.
- **Contrast.** Any new fg/bg pair: compute the ratio. Below 4.5:1 for text is a finding
  even when the user asked for those exact colors — surface it, don't ship it silently.
- **Action feedback.** Every mutating action must produce a toast/inline state on
  trigger, success, AND error. Grep the handler for all three paths.
- **Loading identity.** Every route that streams data must render ITS OWN skeleton at
  real sizes; a global fade/opacity on the shell is a finding.
- **Human-readable identity.** Grep the rendered output for raw ids/keys where a name
  exists.
- **Overflow and truncation.** For every text cell with a width: `scrollWidth >
  clientWidth` means it silently ellipsizes — is that intended, or was "it must fit" the
  requirement?

Ground every finding in a measurement or a file:line. Screenshot the failures.

## Phase 4 — Delegate the adversarial pass (the user's standing pattern)

The author cannot see their own categorical blind spots — that is the entire premise.
Dispatch a **separate agent** (a peer session via `claude-ipc`, or an `Agent` sub-agent
pinned to opus for judgment) with: the catalog, the changed surfaces, and exclusive use
of the browser. It runs Phase 3 independently and reports. Its findings outrank the
author's self-check.

## Phase 5 — Mine the catalog (when one is missing or stale)

Synthesize from the user's ACTUAL feedback, never from general heuristics:
transcripts under `~/.claude/projects/*/`, the project's verbatim-feedback docs, the
user's own notes. Extract each piece of feedback → cluster into categorical classes →
for each write name · appearance · why assertions miss it · the mechanical check. Append
new classes as new feedback arrives; a class earns its place by having been *complained
about*, not by being plausible.

## Phase 6 — Report

Ranked findings, each with: the class it belongs to, the measurement that proves it, the
fix. Then update the catalog with any NEW class this round surfaced.

## Notes

- **The catalog is the asset**, not this file. This skill is the runner.
- Complements, does not replace: `/ui-gripe` (why one screen confuses), `/designer-
  reviewer` (aesthetic score), `/skeptical-review` (code-level review). Run this one when
  the question is "will the user immediately spot something I can't".
- Findings are flagged, never auto-fixed silently; a color/contrast conflict with an
  explicit user request is surfaced in one sentence, then their call.
