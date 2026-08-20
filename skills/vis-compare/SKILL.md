---
name: vis-compare
description: Judges whether a recreated image faithfully imitates a reference — runs the local `see diff A B` deterministic evidence pack (text/color/hash/shape, zero-cost, fabrication-proof) as ground truth, then a native-vision judgment pass that classifies each divergence against a user-editable taste policy (looks-worse / neutral / improvement / not-worth-chasing) rather than a raw distance score. Use when B is a rebuild/re-render of A and you want "what changed AND whether it matters" — recreate-with-a-freer-hand review, UI-recreation fidelity, icon/logo/theme/chart comparison, or a visual-regression judgment. For a single screenshot's confusion audit use /ui-gripe; for scored aesthetics use /designer-reviewer.
allowed-tools: Read, Bash, Write, Edit
user-invocable: true
argument-hint: "<reference-A> <candidate-B> [focus, in your words]"
context: fork
---

## Brief

Answers "does B faithfully imitate A, and are its departures losses or improvements?"
The local `see diff A B` read produces the deterministic evidence pack — text diff,
palette/ΔE, perceptual hashes, grid-ΔE heatmap, edge/shape grid — plus a contact sheet,
all at zero-cost and built to fabricate nothing. This skill then judges the two images
natively and sorts each real divergence against the taste policy. Division of labor is
fixed and non-negotiable: **scripts measure, Claude judges** — the judge may not invent
a number the pack does not contain, and never disputes one it does.

# Vis-Compare — imitation fidelity for two images

## Usage

```
/vis-compare <reference-A> <candidate-B> [focus...]
/vis-compare --revisit <divergence-id|all> --feedback "..."   # re-judge one slice
/vis-compare --loop <reference-A> <candidate-B>               # drive fix rounds to convergence
```

- `reference-A` / `candidate-B`: image paths. A is the original/reference, B the
  recreation/candidate. Order matters — the judgment is "how well does B imitate A".
- `focus` (optional): what to weigh ("the button styling", "does the data survive").
  Steers ranking; the judge still completes the full pass.
- `--revisit`: re-judge a named divergence (or `all`) with feedback in context — for
  when a verdict was wrong. Patches the verdict; records the re-ruling in the ledger.
- `--loop`: iterate fix → re-render → re-compare with the L3 ledger until converged
  (see "Loop mode" below). For candidates YOU can rebuild (CSS/code in hand).

## Loop mode (--loop) — L3, for Claude-built candidates

The round protocol; the mechanical half lives lm-side (`~/Code/local-models`):

1. **Open a loop dir**: `outputs/see/loops/<slug>/` (lm repo). Round 1 must be a
   comparable pair — the ledger rejects a `comparable: poor` pack outright.
2. **Each round**: apply the fixes the last verdict's `fix_hint`s name (exact values
   are on YOUR side — you built B) → re-render B → run
   `see diff <A> <B-new> --no-read --json` (the loop default: evidence only, ~1s,
   no VLM seat) → judge ONLY at nudged moments (see 4) → feed the ledger:
   `.venv/bin/python lib/vis-ledger.py add outputs/see/loops/<slug>/ <verdict.json> --pack <evidence.json>`
   (bare `python3` also works; `--pack` enables the poor-pair block + score trend).
3. **Obey the signals** in the add/status output: `stop: "policy-pass"` → converged,
   the ledger is the acceptance record. `stall: true` (2 consecutive rounds, zero
   `fixed`) → escalate: run the full native judgment or stop and rethink the fixes.
   `pass-with-notes` → converged is the USER's call; surface it, don't decide it.
4. **Judge sparse** (§5.7 of the design): loop rounds iterate on machine evidence —
   the native-vision judgment (Phase 3 below) fires only on: ledger stall, all
   machine scores under the policy floor (candidate ready for final verdict), or
   an explicit user ask. Announce before each judge invocation, as always.
5. Status words (new/persisting/fixed/regressed) come from the ledger, never from
   you — do not re-derive or dispute them (same contract as extractor numbers).
   Rounds are sequential: one add at a time, no parallel rounds into one loop dir.

## Step 0 — Load guidelines, policy, and memory

Read `~/.claude/skills/GUIDELINES.md` and apply its rules for the whole run (forbidden
paths, tool prefs, verbosity, timeouts, the file-lock protocol, post-run insights).

Then load this skill's own context — all three are load-bearing:

- `~/.claude/skills/vis-compare/policy.md` — the taste policy: the divergence-class
  ladder, the floor, the imitation doctrine, and any per-project overrides. This is the
  rubric you judge against. **Follow what it says, not your own taste.**
- `~/.claude/skills/vis-compare/suppressions.jsonl` — past user overrules. Each line is
  `{fingerprint, pair_context, ruling, ts}`. Hold this list in mind; during Phase 3, any
  divergence whose fingerprint (Phase 5) matches gets pre-classified `suppressed` — one
  collapsed line, not re-argued. Continue if the file is absent (no suppressions yet).
- `~/.claude/skills/vis-compare/runtime-notes.md` — past run history; continue without it.

If invoked with `--revisit`, skip to Phase 5.

## Phase 1 — Resolve the inputs

1. Validate both paths exist and are images (`file -b --mime-type`). If one is missing,
   ask for it — do not guess.
2. Restate the comparison in one line as the question being answered ("does the rebuilt
   login page keep the original's information and hierarchy?"). The `focus`, if given,
   names what to weigh most; with no focus the working question is "where does B depart
   from A, and does each departure help or hurt?"

## Phase 2 — Deterministic evidence (zero-cost ground truth)

The evidence layer is model-independent and free; run it first, always.

```bash
command -v see >/dev/null 2>&1 && see diff "<A>" "<B>" --json
```

The `.evidence` object is the **measured truth** (schema: `~/Code/local-models/docs/10-visual-compare-design.md` §5):
`scores` (dhash/ahash/similarity, grid_delta_pct, palette_delta_avg), `text_diff`,
`color.palette_pairs` (each with a `weight` = A-side area share — a low weight means a
few pixels, not a real recolor), `grid_heat` + `heatmap_ascii` (WHERE color diverges),
`edge_shape` (WHERE shape diverges), `meta.comparable`, `meta.skipped_extractors`,
`failures`, and `next` (rerun nudges). The artifact folder (`.evidence.artifact`) holds
`contact.png` — the A│B│ΔE-heat sheet — and `evidence.json`.

- If `meta.comparable == "poor"`: lead with that. Do not manufacture a comparison of
  two things that are not comparable; surface the `next` nudge (the crop command).
- If a `failures` entry says the VLM read or OCR was unavailable, the pack still holds
  the deterministic extractors — proceed on those, note the gap.
- If `see` is not on PATH: look for an existing `evidence.json` the caller points at; if
  none, run native-only and say plainly in the verdict that there is NO machine anchor,
  so every observation is `gestalt` (unmeasured) and lower-confidence.

Save the pack's `next` nudges — surface any that would sharpen the judgment (e.g. a
saturated heatmap → `--grid 32` to localize) at the end of the report.

## Phase 3 — Native judgment (announce before spending)

This is the one expensive seat. Before reading the images, announce it:

> Running the native-vision judge (Claude — the expensive-but-valuable seat). The zero-cost
> machine evidence is already in hand; in a convergence loop where machine scores are
> still improving, this judgment can wait.

Then `Read` A, B, and `contact.png`. Walk every divergence the pack measured, plus what
only native vision can see, and classify each against `policy.md`:

1. **Anchor on the pack.** For each measured divergence (a `text_diff` entry, a
   high-weight `color.palette_pair`, a hot `grid_heat`/`edge_shape` cell), name it,
   locate it in the images, and assign a **class** (the canonical `[slug]` from the
   policy ladder, verbatim — `info-loss`, `hierarchy-shift`, `layout-placement`, …) and a
   **judgment** (looks-worse / neutral / improvement / not-worth-chasing). Cite the pack
   path as evidence (`color.palette_pairs[0]`, `grid_heat.top_cells[1]`).
   **`where.grid` may ONLY hold a cell copied from a cited `grid_heat`/`edge_shape`
   entry.** A text divergence has no measured position: give it `desc` only (for a
   `text_diff.moved`, put its from/to labels in `desc`). Never read a grid number off the
   screenshot — that is the fabrication the layer exists to stop.
2. **Apply the floor.** Low-weight palette pairs, sub-floor spacing, micro-typography —
   not-worth-chasing unless they compound (policy says how). Do not pad the report with
   floored items; collapse them to one line.
3. **Add gestalt, tagged.** Things you can see that the extractors don't measure (a
   shadow reading heavier, a font feeling off) → add them, each marked `gestalt`
   (unmeasured, lower confidence). NEVER attach a fabricated number.
4. **Honor suppressions.** A divergence whose fingerprint matches `suppressions.jsonl`
   is pre-classified `suppressed` — one collapsed line, not a re-argument.
5. **The identical-pair discipline.** If the pack is near-zero everywhere, the verdict
   is "no meaningful divergence" — full stop. Do not hunt for something to flag.

## Phase 4 — The verdict

Write both a human report (prose-first) and the machine `verdict.json`.

**Prose**, in this order:
1. **Overall** — one line: `pass` / `pass-with-notes` / `diverges`, judged against the
   policy, never a numeric threshold alone. Plus the one-sentence why.
2. **What diverges and whether it matters** — the divergences that clear the floor,
   ranked by class. Each: name · class · judgment · evidence (pack path) · a concrete
   fix hint (CSS/value-level when B is web/known). Improvements are called out as wins,
   not fixes.
3. **What B got right** — 1–2 things faithfully carried or improved, so a fix pass
   doesn't bulldoze them.
4. **The one thing** — if only one divergence gets addressed, which, and why.
5. **Evidence trail + next** — the artifact folder path, and any `see diff --only …`
   nudge that would sharpen a specific call.

**Self-check BEFORE writing `verdict.json` (mandatory — this is the anti-fabrication
mechanism, not a reminder).** Walk every divergence with `gestalt:false` and confirm each
concrete value it asserts is *traceable to one of its cited `evidence[]` paths*: a
`where.grid` cell must appear in a cited `grid_heat`/`edge_shape` entry; a color/ΔE/size
must appear in a cited `color`/`scores` path; a text change must appear in `text_diff`.
Any value that does NOT trace → drop it (grid: omit; keep `desc`), or if you can genuinely
see it but no extractor measured it, move the whole observation to `gestalt:true`. A
`gestalt:false` divergence with an untraceable number is a fabrication — fix it here, not
after the user catches it.

**`verdict.json`** (write next to the evidence with `Write`, schema §5) — every divergence
carries `id`, `class` (canonical slug), `where` (`desc` always; `grid` ONLY when copied
from a cited grid_heat/edge_shape cell), `evidence` (pack refs), `judgment`, `gestalt`
bool, `confidence` (`high`/`low` — `low` emits the `--revisit` nudge), `fix_hint`,
`status`; plus top-level `overall`, `policy_version`, `suppressed`, and `cost` (copy the
pack's `cost` block through, so Phase C can trend spend across loop iterations).

Do not pad. A faithful recreation with one real loss gets one finding. If B actually
improves on A, say so — the imitation doctrine welcomes deliberate departures. If the
evidence does not support a divergence the caller expected, say that plainly with the
evidence (`rules/pushback-and-self-criticism.md` § 3).

## Phase 5 — Feedback: revisit and suppress

The judge is fallible; make correcting it cheap and durable.

- **`--revisit <id|all> --feedback "..."`** — re-judge only the named divergence(s) with
  the feedback in context (re-Read the relevant region, re-anchor on the pack). Patch
  that entry in `verdict.json`, set its `status` to `revisited`, and note the re-ruling.
- **User overrules a verdict** ("stop flagging the button radius"): append one line to
  `suppressions.jsonl`. The fingerprint is built from STABLE anchors — never a
  judge-recalled grid coordinate, which drifts across re-renders (there is no shared
  letterboxed coordinate space yet — docs/10 §9). Use the canonical class slug plus a
  content anchor that survives a re-render:
  - a **text** divergence → the exact text string (`"Refresh"`);
  - a **color** divergence → the palette-pair hex (`#2563eb`);
  - a **shape** divergence → the extractor + cell it was grounded on (`edge_shape[3,3]`).
  ```json
  {"fingerprint": "<class-slug>|<content-anchor>", "pair_context": "<what A/B are>", "ruling": "not-worth-chasing", "ts": "<iso>"}
  ```
  A future run pre-classifies a divergence `suppressed` when its class slug AND content
  anchor match. Prefer a text-string or palette-hex anchor over a grid cell whenever one
  exists — grid-only fingerprints stay unreliable until E0 letterboxing lands.
- **Graduation**: when the same suppression recurs across pairs, it belongs in
  `policy.md` as a rule (the atone→rules path). Note the candidate; let the user promote.

## Anti-patterns

- Inventing a measurement — a color/size/position number not in the pack. Gestalt only,
  tagged. This is the fabrication the whole L1/L2 split exists to prevent.
- Disputing an extractor ("the pack says ΔE 9 but it looks like more") — that is a
  `--revisit`, not a silent override.
- A single similarity score as the headline — the pack's per-extractor signals plus the
  policy judgment are the answer; one scalar misleads.
- Auto-retrying the judge — it is the expensive seat. On low confidence, emit the
  `--revisit` nudge and let the controlling agent decide.
- Polishing `policy.md` solo — v1 is a draft; its taste is the user's to set.
- Flagging deliberate improvements as regressions — the goal is imitation-with-judgment,
  not pixel identity.

## Post-run

Per GUIDELINES.md, prepend a short entry to `runtime-notes.md` (purpose + 2–4 insights)
when the run surfaced anything reusable — a divergence class the policy handles badly, a
pack signal that kept misleading the judgment, a suppression worth graduating to policy.

## See also

- `~/Code/local-models/docs/10-visual-compare-design.md` — the full design (L1 §3, this
  judge §4, schema §5, model map §5.7, fixtures §6, built-vs-deferred §9)
- `~/Code/local-models/docs/CAPABILITIES.md` §3 — `see diff` and the evidence pack
- `/ui-gripe` — single-screenshot confusion audit (the sibling this skill mirrors)
- `~/.claude/skills/vis-compare/policy.md` — the taste policy you edit
