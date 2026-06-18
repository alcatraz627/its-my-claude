---
name: improve-skill
description: Audits one or more Claude Code skills by reading their SKILL.md, runtime notes, and code files — identifies stale descriptions, structural gaps, recurring failures, and Claude-consumption defects, applies approved improvements, then validates the result against defined criteria with a 0–100 score and re-improves if needed.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, mcp__inputs__pick_one, mcp__inputs__form, mcp__inputs__confirm
user-invokable: true
argument-hint: "[skill-name | skill-name,skill-name,... | all]"
---

## Brief

Reads existing skill definitions alongside their runtime notes and the latest GUIDELINES, audits them against the Claude-consumption rubric (the Opus-4.8 house rules — caps, suppression-bar, altitude, cross-links), asks the user for any specific focus, then applies approved improvements directly to the skill files. After applying changes, validates the updated skill against defined criteria (from `## Validation Examples` or auto-generated), scores it 0–100, and offers to re-improve if the score is below threshold.

# Improve Skill

Audits and upgrades existing Claude Code skills. It reads what a skill _says_ it does, compares it against what actually _happened_ during past runs (from runtime notes), and measures it against how Opus 4.8 actually consumes a SKILL.md — then closes the gaps.

This is the **meta-skill that audits every other skill**, so it carries the Claude-consumption rubric itself. The canonical source for that rubric is `~/.claude/assets/reports/20260618-persona-dogfood/claude-consumption-spec.md` (the Opus-4.8 house rules). Phase 2 below operationalizes it; read the spec when you need the underlying evidence.

**Works on:**

- A single skill: `/improve-skill arch-qa`
- Multiple skills: `/improve-skill arch-qa,project-index`
- All skills: `/improve-skill` or `/improve-skill all`

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the **file lock
protocol** — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` in full at this step (not only per-skill in
Phase 1.2). This gives cross-skill context — failure patterns, tool bugs, and conventions
that may affect multiple skills at once. If `runtime-notes.md` does not exist, continue
without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write to any
> SKILL.md or `runtime-notes.md`, and release it immediately after. When targeting multiple
> skills, acquire and release each lock one file at a time — do not hold multiple locks
> simultaneously.

## Argument Handling

Parse the argument:

- **No argument or `all`** → target all skills found via `Glob(".claude/skills/*/SKILL.md")`
- **Single name** (e.g., `arch-qa`) → target only `.claude/skills/arch-qa/SKILL.md`
- **Comma-separated list** (e.g., `arch-qa,project-index`) → target each listed skill

For each target, verify the directory and SKILL.md exist. If a named skill is not found, print:

```
✗ Skill "xyz" not found at .claude/skills/xyz/SKILL.md — skipping.
```

After resolving targets, print:

```
Improving N skill(s): arch-qa, project-index, ...
```

---

## Phase 1 — Information Gathering

Run for **each target skill** sequentially. Print each step as it runs.

### 1.1 — Read the SKILL.md

Read `.claude/skills/<name>/SKILL.md` in full.

Print: `  Reading .claude/skills/<name>/SKILL.md ...`

Extract:

- `name` from frontmatter
- `description` from frontmatter
- `allowed-tools` from frontmatter
- Whether `## Brief` section exists and what it says
- Whether `## Step 0: Load Shared Guidelines` preamble exists
- Whether the GUIDELINES four-phase skeleton is present (Gather / Plan / Execute / Verify — the specific phase names/numbers may vary)
- Whether `## Validation Examples` section exists (used by Phase 6)
- Any `## Notes` section

### 1.2 — Read runtime notes for this skill

Read `.claude/skills/runtime-notes.md`.

Print: `  Scanning runtime-notes.md for entries related to <name> ...`

Filter for entries whose heading contains the skill name (e.g., `## create-report: ...` or `## project-index: ...`).

For each matching entry, extract:

- The insights list (numbered points)
- Any errors or failure patterns mentioned

If no entries found, note: "No runtime history for this skill."

### 1.3 — Check for associated code files

Glob `.claude/skills/<name>/*` and list all files besides SKILL.md.

Print: `  Associated files: [list, or "none"]`

For each code file (`.ts`, `.sh`, `.js`), read its contents — these may need updating alongside the SKILL.md.

### 1.4 — Read current GUIDELINES (for compliance check)

Read `.claude/skills/GUIDELINES.md` and extract:

- Forbidden paths list
- Required frontmatter fields
- Required structural elements (Brief, Step 0 preamble, four phases)
- Retry mechanism rules
- Post-run insight requirement

---

## Phase 2 — Analysis

For each skill, produce a structured analysis. Do not write anything yet.

### 2.1 — Audit rubric

Two lenses run together: **structural compliance** (does the skill have the required shape?) and **Claude-consumption** (does an Opus-4.8 agent read it the way the author intended?). The second lens is what makes this a meta-skill — every other audit skill needs it applied to itself.

For each check, record `pass` / `partial` / `fail` and a one-line note. Don't force a numeric sub-score yet — that's Phase 6's job.

**Frontmatter and routing:**

- `description` starts with a verb, names input + action + output, ≤ 2 sentences. A `description` is what Claude reads to decide whether to invoke the skill — vague or capability-list phrasing ("helps the user", "frontend expert") routes worse than an action-oriented one ("Scans the diff and reports unsafe casts"). Flag if vague, omits the output artifact, or doesn't match the actual workflow.
- `argument-hint` present, with `<required>` / `[optional]` bracket convention matching the actual arguments. Use `""` if the skill takes none.
- `allowed-tools` matches the tools the workflow actually uses.

Draft an improved `description` / `argument-hint` for any flagged item.

**Claude-consumption (Opus-4.8 house rules — source: `claude-consumption-spec.md`):**

- **ALL-CAPS / MUST / MANDATORY / CRITICAL over-trigger.** These over-fire and over-think on 4.8. Flag a skill that scatters them; reserve emphasis for 2–3 genuinely load-bearing gates (a read-only invariant, a "return only JSON" contract). Rewrite the rest as plain declaratives.
- **Flavor-vs-procedure ratio.** A persona reliably steers tone and discipline; it does not make Claude reason better — the reasoning lift comes from the attached procedure (checklist, refinement loop, output contract). A skill that is mostly character and thin on procedure is optimizing the wrong half. Flag long flavor passages with no matching checklist or contract.
- **Wrong altitude / edge-case enumeration.** Spec-as-essay (hundreds of lines, exhaustive case lists) reads worse than a tight procedure plus a few canonical examples and heuristics. Flag enumeration that should collapse to a heuristic; flag detail that belongs in a companion doc, not inline.
- **The finding-suppression bar (review skills only).** A raised *reporting* bar — "report only the top N", "be conservative", "don't nitpick" — is followed faithfully on 4.8 and silently drops real findings. Flag it. The fix is coverage-first: investigate everything, report every in-scope finding with a confidence + severity tag, and rank (sink low-priority to the bottom) rather than drop. "Harshness" lives in the depth of investigation, never in the reporting bar.
- **Missing subsystem cross-links.** A skill should hint toward the subsystems its domain leans on (see `subsystem-inventory.md`): build/fix/audit skills → `/skeptical-review` + exercise-based-verification + `/test`; review skills → `/magi` (scoped architecture calls) + `/arch-qa`; doc skills → `doc-writing-guidelines.md` + the doc-review personas; research skills → `/deep-research` + `/cogitate`. Flag a missing high-value link.
- **gum / TTY output under `context: fork`.** A forked skill whose return is parsed by the parent must not emit `gum`/`bat`/`glow`-rendered panels — the parent gets terminal-control bytes, not structured data. Flag it; the fix is a plain-text or JSON return contract.
- **Runtime `grep`.** A `grep` / `grep -r` in a workflow step will be blocked by the prefer-ripgrep PreToolUse hook at runtime. Flag every occurrence; the fix is `rg` (with `--no-ignore --hidden` when grep's full scope is needed). `git grep` is allowed through the hook.

### 2.2 — Structural compliance

Check against GUIDELINES requirements:

| Check                                                                        | pass / partial / fail |
| ---------------------------------------------------------------------------- | --------------------- |
| `## Brief` exists immediately after frontmatter                              |                       |
| `## Step 0: Load Shared Guidelines and Runtime Context` preamble present     |                       |
| Step 0 preamble reads both `GUIDELINES.md` and `runtime-notes.md`            |                       |
| Four-phase structure (Gather / Plan / Execute / Verify) present              |                       |
| Post-run insights step present                                               |                       |
| Prettier format requirement mentioned (if skill writes files)                |                       |

### 2.3 — Runtime note analysis

For each insight from runtime notes, classify it:

- **Already fixed** — the current SKILL.md instructions already handle it
- **Missing instruction** — the SKILL.md has no guidance for this case; instruction should be added
- **Wrong instruction** — the SKILL.md says to do X but the runtime note shows X fails; needs correction
- **Informational** — useful context but no instruction change needed

### 2.4 — Ask for specific focus

After completing the analysis, print a summary of findings for this skill:

```
─────────────────────────────────────────────────────
  Analysis: <name>
─────────────────────────────────────────────────────

  Description: [needs update | looks good]
  Structural gaps: [list any missing elements, or "none"]
  Consumption defects: [caps / suppression-bar / altitude / grep / gum-under-fork / missing links, or "none"]

  From runtime notes:
    [N] missing instructions identified
    [N] wrong/outdated instructions identified
    [N] already handled

  Proposed improvements:
    1. [title] — [one-line rationale]
    2. [title] — [one-line rationale]
    ...

─────────────────────────────────────────────────────
```

Then ask for any specific focus using `mcp__inputs__form` with a single free-text field
(label: "Specific focus for <name> (leave blank to apply all proposed improvements)").

If the user describes a specific focus (e.g., "the retry logic is wrong", "it never reads the notes file"), add that as an additional improvement item or reprioritize existing ones.

**If no improvements are proposed** (all checks pass, no runtime note gaps, no user focus), print:

```
  ✓ <name> — no improvements needed. Proceeding to validation (Phase 6).
```

Skip Phases 3–5 for this skill and proceed directly to Phase 6 (Validation & Scoring).

---

## Phase 3 — Improvement Planning

For each skill, before writing, print the concrete change list:

```
─────────────────────────────────────────────────────
  Changes for <name>:
─────────────────────────────────────────────────────

  SKILL.md
    [✎] description: "<old>" → "<new>"
    [+] Add ## Brief section
    [+] Add Step 0 preamble
    [✎] Phase 2: de-cap (8 MUST/MANDATORY → plain declaratives)
    [✎] Phase 4: coverage-first — drop "report top 5", add confidence+severity tags
    [✎] Step 3: grep -r → rg --no-ignore --hidden
    [+] See Also: link /skeptical-review, /arch-qa

  generate-html.ts (if applicable)
    [no changes]

─────────────────────────────────────────────────────
```

Then confirm with `mcp__inputs__pick_one` (options: "Apply all", "Apply selected (then ask which)",
"Skip this skill"). If the user picks "Apply selected", follow up with a free-text field for the
item numbers (e.g., `1,3`).

---

## Phase 4 — Execution

Apply the approved changes for each skill.

### 4.1 — Update SKILL.md

Use `Edit` for targeted changes (single section replacements). Use `Write` only if the file needs a structural rewrite (e.g., missing `## Brief` that must be inserted at a specific location).

For each edit:

- Acquire lock: `bash ~/.claude/skills/shared/lock-file.sh acquire ".claude/skills/<name>/SKILL.md" "improve-skill"`
  - If exit 1 (locked): print the owner, skip this skill, continue to next
- Print: `  [✎] Updating <section name> in <name>/SKILL.md ...`
- Apply the edit
- Release lock: `bash ~/.claude/skills/shared/lock-file.sh release ".claude/skills/<name>/SKILL.md" "improve-skill"`
- Print: `  ✓ Done`

**Inserting ## Brief (if missing):**

Use `Edit` to insert immediately after the closing `---` of the frontmatter:

```markdown
---
[existing frontmatter]
---

## Brief

[generated brief text]

# Skill Title
```

**Inserting Step 0 preamble (if missing):**

Find the first `## ` heading after the `# Title` heading and insert the Step 0 block before it.

### 4.2 — Update associated code files (if applicable)

If a runtime note identified a bug in a `.ts` or `.sh` file and the fix is clear, apply it using `Edit`.

For each code edit:

- Print: `  [✎] Fixing <description> in <filename> ...`
- Apply the edit
- Print: `  ✓ Done`

Only apply code fixes that are clearly scoped and low-risk. If a fix is ambiguous or requires significant redesign, flag it for the user instead of applying it:

```
⚠ Code fix needed in generate-html.ts but too complex to apply automatically.
  Recommendation: [describe the fix]
```

### 4.3 — Format updated files

```bash
npx prettier --write .claude/skills/<name>/SKILL.md
```

Also format any code files that were modified.

---

## Phase 5 — Verification

After all skills are processed:

### 5.1 — Read back each updated SKILL.md

For each updated skill, read the file and confirm:

- `## Brief` section is present
- `## Step 0` preamble is present
- The updated description is in the frontmatter
- Any consumption fix landed (no stray caps where they were removed, `rg` where `grep` was, the See-Also links present)

Print: `  ✓ <name>/SKILL.md verified`

### 5.2 — Print verification status

For each skill, print a one-line verification status:

```
  ✓ <name>/SKILL.md verified — ready for validation
```

If verification fails (missing Brief, missing Step 0, etc.), print the specific failure and attempt a corrective edit before proceeding to Phase 6.

---

## Phase 6 — Validation & Scoring

Validate the quality of the current (or updated) skill. This phase runs **regardless of whether improvements were applied** — if Phase 2 found nothing to change, skip directly here from the no-improvements path. The goal is to score instruction coverage, not just verify that edits landed correctly (that's Phase 5's job).

### 6.1 — Check for Validation Examples

Read the **target skill's** SKILL.md and look for a `## Validation Examples` section.

**If the section exists**, parse it. Each example has this format:

```markdown
### Example: <title>

**Scenario:** <description of the invocation context — arguments, project state, runtime-notes content>
**Expected behavior:**

- [ ] <criterion 1 — a concrete, verifiable instruction the skill should contain>
- [ ] <criterion 2>
- [ ] <criterion 3>
```

**If no `## Validation Examples` section exists**, auto-generate 3–5 examples from the skill's description, Brief, and workflow:

1. Read the skill's description, Brief, and phase headings
2. Infer the most common invocation scenarios (e.g., "run on a skill with no runtime notes", "run on a skill missing ## Brief", "run on all skills at once")
3. For each scenario, generate 3–5 concrete criteria that the SKILL.md instructions should cover
4. Print the auto-generated examples for the user, then confirm with `mcp__inputs__pick_one`
   (options: "Accept", "Edit", "Skip validation"). On "Edit", collect corrections via a
   free-text field, then proceed.

### 6.2 — Score the Updated Skill

For each validation example, judge whether the current SKILL.md covers each criterion. Use a coarse three-level read, not a brittle per-line rubric:

- **full** — a clear, specific instruction handles this case
- **partial** — a related instruction exists but is vague or incomplete
- **none** — no instruction covers this case

Map to points (full = 10, partial = 5, none = 0) and compute:

```
Score = (sum of criterion points) / (number of criteria × 10) × 100
```

For any criterion below `full`, note in one line what's missing or vague — that note is the gap the re-improvement loop targets.

Print the scorecard:

```
─────────────────────────────────────────────────────
  Validation scorecard: <name>
─────────────────────────────────────────────────────

  Example 1: <title>                          Score
    ✓ <criterion 1>                           10/10
    △ <criterion 2> — partial: <what's vague> 5/10
    ✗ <criterion 3> — missing instruction     0/10

  Example 2: <title>
    ✓ <criterion 1>                           10/10
    ✓ <criterion 2>                           10/10
    ...

  ─────────────────────────────────────
  Overall score: NN/100
  Threshold: 75/100
  Status: [PASS ✓ | NEEDS IMPROVEMENT △]
  ─────────────────────────────────────

─────────────────────────────────────────────────────
```

### 6.3 — Re-improvement Loop (if score < 75)

If the score is below the threshold (75 by default):

1. Collect every criterion scored `partial` or `none`
2. Print the gap list:

```
  Gaps to address:
    1. [criterion] — [what's missing or vague]
    2. [criterion] — [what's missing or vague]
    ...
```

3. Ask whether to run another loop using `mcp__inputs__confirm` ("Run another improvement loop targeting these gaps?").
4. If confirmed:
   - Return to **Phase 3** with the gap list as the change set
   - Draft specific instruction additions for each gap
   - Show the change list for approval
   - Apply approved changes (Phase 4)
   - Re-verify (Phase 5)
   - Re-score (Phase 6.2)
   - Stop after at most **2 re-improvement loops** — print the final score and move on regardless. The gap is real but un-closed in two passes; flag it for manual follow-up rather than thrashing.
5. If declined: print the final score and continue to Phase 7.

### 6.4 — Offer to Persist Validation Examples

If validation examples were auto-generated (not already in the SKILL.md), offer to save them
with `mcp__inputs__confirm` ("Save these validation examples to <name>/SKILL.md?").

If confirmed:

1. Acquire lock: `bash ~/.claude/skills/shared/lock-file.sh acquire ".claude/skills/<name>/SKILL.md" "improve-skill"`
2. Append the `## Validation Examples` section to the end of the SKILL.md (before `## Notes` if it exists)
3. Release lock: `bash ~/.claude/skills/shared/lock-file.sh release ".claude/skills/<name>/SKILL.md" "improve-skill"`
4. Run `npx prettier --write .claude/skills/<name>/SKILL.md`

---

## Phase 7 — Post-Run Insights

After all skills are processed and validated:

### 7.1 — Generate insights

Produce 2–6 insight points — concrete observations that would make a future run faster or more accurate.

### 7.2 — Write runtime note

Write the entry to a temp file, then call `prepend-runtime-note.sh`:

```bash
cat > /tmp/runtime-note-entry.md << 'ENTRY'
## improve-skill: [Brief description of what was improved] — [YYYY-MM-DD HH:MM]

**Purpose:** [One sentence: what this run accomplished]

**Insights:**

1. [point]
2. [point]
...

---
ENTRY

bash ~/.claude/skills/shared/prepend-runtime-note.sh "improve-skill" /tmp/runtime-note-entry.md
```

### 7.3 — Print final summary

```
─────────────────────────────────────────────────────
  improve-skill complete
─────────────────────────────────────────────────────

  Skills processed: N
  Files modified:
    .claude/skills/arch-qa/SKILL.md          (3 changes, score: 85/100)
    .claude/skills/project-index/SKILL.md    (1 change, score: 92/100)
    ...

  Skipped (no improvements needed):
    .claude/skills/create-report/SKILL.md

  Validation:
    Average score: NN/100
    Re-improvement loops triggered: N

  Manual action needed:
    ⚠ generate-html.ts: [description of unfixed issue]

─────────────────────────────────────────────────────
```

---

## Validation Examples Format

A skill defines its own quality bar by adding a `## Validation Examples` section to its SKILL.md — `/improve-skill` scores against it in Phase 6. Place the section after the main workflow and before `## Notes`. Each example pairs a scenario with a checklist of concrete, verifiable criteria:

```markdown
## Validation Examples

### Example: <descriptive title>

**Scenario:** <the invocation: arguments, state of the target skill, relevant context>
**Expected behavior:**

- [ ] <concrete criterion the SKILL.md instructions should cover>
- [ ] <another criterion>
```

Good criteria are **specific** ("Step 2 explains how to handle a skill with no runtime notes", not "handles edge cases"), **verifiable** by reading the SKILL.md alone (no subjective judgment), and **bounded** (3–5 per example, covering missing data, malformed input, empty results, and the happy path). This skill's own `## Validation Examples` section below is a working instance of the format.

---

## Validation Examples

### Example: Single skill with no runtime notes

**Scenario:** User runs `/improve-skill arch-qa`. The skill `arch-qa` has a valid SKILL.md but zero entries in runtime-notes.md.
**Expected behavior:**

- [ ] Phase 1.2 prints "No runtime history for this skill" and continues
- [ ] Phase 2.3 skips runtime note analysis (no crash on empty data)
- [ ] Analysis summary shows "0 missing instructions" for the runtime notes section
- [ ] The skill still checks structural compliance, description accuracy, and consumption defects

### Example: Review skill with a finding-suppression bar

**Scenario:** User runs `/improve-skill route-audit`. The target skill's workflow says "report only the most important findings".
**Expected behavior:**

- [ ] Phase 2.1 flags the suppression bar as a consumption defect
- [ ] The proposed fix is coverage-first (report all with confidence+severity, rank don't drop)
- [ ] Phase 3 change list shows the bar-removal edit before applying
- [ ] Phase 2.1 also checks for runtime `grep` and gum-under-fork in the same skill

### Example: All skills with one failing validation

**Scenario:** User runs `/improve-skill all`. After improvements, one skill scores 60/100.
**Expected behavior:**

- [ ] Phase 6.2 prints the scorecard with the failing score highlighted
- [ ] Phase 6.3 offers a re-improvement loop for the failing skill only
- [ ] Other skills that passed (≥75) are not re-processed
- [ ] At most 2 re-improvement loops run — stops after 2 rounds regardless

### Example: Skill with existing Validation Examples section

**Scenario:** User runs `/improve-skill create-report`. The `create-report` SKILL.md already has a `## Validation Examples` section with 3 examples.
**Expected behavior:**

- [ ] Phase 6.1 parses the existing examples (does not auto-generate)
- [ ] Phase 6.4 does NOT offer to persist (examples already exist)
- [ ] Scoring uses the skill-defined criteria, not generic ones

### Example: No improvements needed — validation-only path

**Scenario:** User runs `/improve-skill arch-qa`. All structural checks pass, description is accurate, no consumption defects, no runtime note gaps.
**Expected behavior:**

- [ ] Phase 2.4 prints "no improvements needed" message
- [ ] Phases 3–5 are skipped for this skill
- [ ] Phase 6 still runs validation and produces a scorecard
- [ ] Phase 7 final summary shows "0 changes" but includes the validation score

---

## Notes

- This skill reads before it writes. Every analysis is printed before any edit is applied, and no change lands without the user approving the Phase 3 change list.
- This is the meta-auditor: it must hold itself to the same Claude-consumption rubric it applies to other skills. The canonical rubric lives in `~/.claude/assets/reports/20260618-persona-dogfood/claude-consumption-spec.md`; cross-link targets live in `subsystem-inventory.md` (same folder).
- When operating on `all` skills, the Phase 2.4 "specific focus" question is asked once per skill — leaving the field blank proceeds with the proposed list.
- Code file edits (`.ts`, `.sh`) are applied conservatively — only for clearly identified bugs from runtime notes with an unambiguous fix. Anything requiring design judgment is flagged, not auto-applied.
- Validation (Phase 6) always runs — even when no improvements were needed — to catch instruction-coverage gaps that aren't structural compliance issues.
- After this skill runs, `/user-config edit` can inspect the updated skill definitions.

## See Also

- `~/.claude/assets/reports/20260618-persona-dogfood/claude-consumption-spec.md` — the Opus-4.8 house rules Phase 2.1 operationalizes (the canonical rubric source).
- `~/.claude/assets/reports/20260618-persona-dogfood/subsystem-inventory.md` — the cross-link map (which skill should hint toward which subsystem).
- `.claude/skills/GUIDELINES.md` — the structural requirements Phase 2.2 checks against.
- `/create-skill`, `/create-agent` — author new skills/agents in the shapes this skill audits for.
- `rules/skill-spec-update-not-honored-by-running-session.md` — why a spec mandate needs a data-path gate, not just prose (relevant when a fix adds a "MUST" with no enforcement).
