---
name: ui-critique
description: Critiques a UI from screenshots. Says why it confuses or looks off, gives CSS fixes, compares a rebuild to a reference, checks known bug classes. Use when the user shares a UI or vents about one.
---

# UI critique

Four jobs on one rule: judge the rendered pixels, never the markup or a number
alone. A UI claim is verified only by looking at a rendered image.

| Mode | The user says | You answer |
|---|---|---|
| Gripe | "this is so confusing", "why is this stupid" | What is fighting the user, ranked by damage |
| Review | "critique this", "make this look right" | Findings by severity, each with a CSS fix |
| Compare | "does B match A", "how close is my rebuild" | Each divergence, and whether it helps or hurts |
| Categorical | "check this before I ship", "what will I miss" | Bug classes that pass every test and fail on sight |

Pick the mode from the ask. A vent about confusion is a gripe, not a score.

## Inputs and how to see

- Uploaded screenshots are the main input. Look at them yourself.
- No image yet: ask for one concrete thing ("a screenshot of the settings page
  with the dropdown open"). Never write an empty report.
- A page you built as an artifact: render it, then ask the user for a
  screenshot of what they see, or rasterize the HTML in the sandbox if a
  headless browser is installable there, and view the PNG.
- Exact text: zoom into the region (crop with PIL in the sandbox) before you
  quote a label. Small text misreads easily.
- Numbers: sample pixel colors from the screenshot in the sandbox to compute
  contrast or compare colors. Anti-aliased edges lie, so sample solid fills.
  A number you did not measure is "looks like", never a fact.
- A screenshot shows one state. Hover, open menus, loading and errors are
  invisible unless someone captured them. Say which states you did not see.

## Mode 1: Gripe (confusion forensics)

1. **Translate the gripe** into a testable frustration: "the user cannot find
   the primary action", "the user cannot tell what state the app is in". With
   no gripe, ask what would confuse a first-time user most.
2. **Walk the rubric**, starting at the item the gripe points to, then finish
   the walk. The named symptom is often downstream of a different cause.
   - **Hierarchy fight**: more than one element dominates, so the eye has no
     entry point. Count the peers at the top visual level.
   - **Accent dilution**: the accent color means selected and destructive and
     decorative, so it means nothing.
   - **Affordance ambiguity**: things that look clickable and are not, or the
     reverse.
   - **State legibility**: can the user tell the mode, and what happened last?
     Look for missing selected, saved, loading and stalled cues.
   - **Pattern breaks**: places the UI violates its own conventions. Internal
     inconsistency costs more than any single bad choice.
   - **Label opacity**: jargon, icon-only controls with unclear glyphs,
     truncated labels.
   - **Density mismatch**: crowded where the user needs calm, empty where they
     need information.
3. **Report**, prose first, no scores:
   - The gripe, translated, in one sentence.
   - What is fighting the user: the top two to four causes, ranked by damage.
     Each has a name, one sentence of mechanism, the visible evidence (where on
     the screen), and a concrete fix (a CSS, layout or copy change, never
     "improve hierarchy").
   - What to keep: one or two things that work, so the fix does not bulldoze
     them.
   - The one change that unblocks the gripe if only one gets made.

A UI with one real problem gets one finding. If the evidence does not support
the gripe, say so plainly and show why.

## Mode 2: Review (critique with CSS fixes)

Score six dimensions from 1 to 10 when the user wants a score: visual
hierarchy, spacing consistency, typography, color and contrast, interactive
states, responsive readiness. Then list issues by impact, HIGH to LOW. Every
issue carries a concrete fix in CSS, token or HTML form:

```
1. [HIGH] No focus indicator on nav links
   Fix: nav a:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
```

Rules for the review:

- **Report everything you see, tagged by confidence.** Finding and filtering
  are separate jobs. A low-confidence finding the user dismisses in a glance
  costs less than one they never see. Rank critical and high-confidence first.
- **End with what works.** Three to six things to keep, so the next pass does
  not "fix" what is intentionally right.
- **Contrast from a screenshot is a suspicion** until measured. Sample the
  pixels or ask for the CSS values, then compute the ratio against WCAG AA
  (4.5:1 body text, 3:1 large text and UI parts).
- **The project's own tokens win.** If the user's code or design system sets a
  font, scale or palette, critique against that. The defaults in
  `references/defaults.md` fill only the gaps.
- **Partial screenshots get partial reviews.** Say what you could not assess
  rather than guess at the rest.

### Developer tools: the user's default taste

For dashboards, admin panels, monitoring and debugging UIs (not marketing or
consumer apps), the user's stated taste is dark, dense and terminal-like.
Review those against these fingerprints unless the user says otherwise:

- **Dark by default**: muted charcoal (#1a1a1a to #2d2d2d), not true black,
  not navy.
- **Tokens for every color**: `--bg`, `--surface`, `--text`, `--text-dim`,
  `--accent`, `--ok`, `--warn`, `--danger`. No hardcoded hex on elements.
- **Monospace for data**: numbers, ids, commands, timestamps, ports and logs in
  a mono face. Sans only for chrome (labels, nav, prose).
- **Terminal density**: a 4, 8, 16 px rhythm, data rows at 32 px or less, no
  generous card padding on tables.
- **Semantic color only**: green ok, amber warn, red danger, blue or accent for
  active, gray for inactive. Color with no meaning is a defect.

## Mode 3: Compare (rebuild against reference)

The question is never "is B pixel-identical to A". It is "does B keep what
matters in A, and is each departure a loss or an improvement".

1. Confirm which image is the reference (A) and which is the rebuild (B).
   Order matters. If the two are framed so differently that they cannot be
   compared (different crop, zoom or state), say so first and ask for a
   matched pair.
2. Gather evidence. In the sandbox, resize both to the same size and compute a
   per-region difference grid and the dominant colors of each. That shows
   where B departs. Treat it as a pointer, not a verdict. Do not go hunting
   when the measured difference is near zero.
3. Walk each divergence and give it a class from the ladder in
   `references/divergence-ladder.md` (information loss ranks highest, texture
   lowest) and a judgment: looks-worse, neutral, improvement, or not worth
   chasing.
4. Report: an overall `pass`, `pass with notes` or `diverges` with one
   sentence why, then each divergence with class, judgment, where it is, and a
   fix. Call improvements wins, not fixes. Name one or two things B got right,
   and the one divergence to fix first.

A number in the report must come from a measurement you ran. Anything you see
but did not measure is marked "seen, not measured". When the user overrules a
call ("stop flagging the radius"), drop that class of divergence for the rest
of the conversation.

## Mode 4: Categorical check (before calling a UI done)

Some defects pass every behavioral test and the user catches them on sight: a
transparent dropdown over content, two side-by-side controls at different
type sizes, a page that scrolls when an inner panel was meant to. They are
caught by measuring and comparing, never by asserting that a feature works.

1. List the changed surfaces: every control added or restyled, every floating
   layer, every container whose height or scrolling changed, every action that
   changes data, every loading, empty and error state.
2. Run each class in `references/categorical-classes.md` against them. Each
   class carries the check that catches it. When the UI runs on the user's
   machine, hand them the console snippet and say what each output means.
3. Report findings ranked, each with its class, the measurement that proves
   it, and the fix.
4. When the user reports a new defect of this kind, name it as a class (what
   it looks like, why tests miss it, the check) and add it to the list for the
   rest of the conversation.

You cannot see your own blind spots. If a fresh reviewer is available (a new
chat with only the screenshots and the class list), their findings outrank
your self-check.

## Boundaries

- Read-only. Report and propose. Change code only when asked.
- Fixes reference only what is visible or given. Do not invent component names
  or file paths.
- A requested color that fails contrast is surfaced in one sentence, then it
  is the user's call.
- Diagnosis without a fix is not a finding.
