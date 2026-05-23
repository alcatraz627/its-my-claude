---
brief: Technical doc guidelines: anti-pattern catalog, STUB/PARTIAL/PLANNED annotations, audience modes
triggers:
  - skill:write-docs
  - topic:docs-work
  - topic:technical-writing
  - phrase:"write docs"
  - phrase:"document this"
related: []
tier: 2
category: conventions
updated: 2026-04-24
stale_after_days: 90
---

# Doc Writing Guidelines

## Overview

Technical docs under `docs/` or `*/docs/` (excluding READMEs, CLAUDE.md files, changelogs, scratchpad). The checklist at a glance:

1. **Audience assumption** — reader is unfamiliar with the system. Support two reading modes: linear (tutorial-style, read top-to-bottom) and lookup (drop-in on any heading and find your answer).
2. **Voice** — direct, specific, no marketing. Avoid a 19-item anti-pattern list: "deceptively," "transactional dance," "hunt for," "and beyond," "seamless," "robust," hedging modifiers ("relatively," "fairly"), meta-commentary ("let's explore," "as we'll see").
3. **Structure** — reader-centric section titles. Tables for structured data (not prose paragraphs). Diagrams annotated, not decorative. Product-context block under any technical-state section so non-implementer readers know WHY it matters.
4. **Annotations** — inline tags for stale or unverified material:
   - `[STUB]` — section exists but is empty, needs writing
   - `[PARTIAL]` — section is incomplete
   - `[PLANNED]` — describes future work, not current behavior
   - `[DEPRECATED]` — retained for history but no longer current
   - `[VERIFY]` — claim needs confirmation (specific number, API shape, etc.)
5. **Pre-handoff check** — run the anti-pattern `rg` command (see §Voice), confirm tables render, diagrams have labels, no unresolved `[VERIFY]` tags remain without justification.

Full rules and examples below. When a project has its own `<project>/.claude/doc-writing-guidelines.md`, apply those on top of these — project rules take precedence on conflict.

---

Ruleset for technical documentation authored by Claude. Built from a 2026-04-23 iteration on a heavily-flagged product doc where the user called out ChatGPT-voice language ("transactional dance," "deceptively load-bearing," "hunt for," "and beyond"), underused tables, weak diagrams, and missing product-context blocks. The rewrite improved from a 78/100 to an 88/100 reviewer score after applying the rules below.

## 1. When this file applies

Load and apply the rules in this file when any of the following is true:

- A task touches a file under `docs/`, `*/docs/`, or any `.md` path outside `.claude/`, `node_modules/`, `_*.claude.md` scratch files, or a repo-root `README.md`.
- The user's request contains any of: "write docs," "document," "rewrite this doc," "technical writing," "reference doc," "product doc," "update the create-\* doc."
- A skill with a `/doc-*` or `/write-docs` name is invoked.

Do not apply these rules to: repo-root `README.md` (different template conventions), `CLAUDE.md` files (agent instructions), scratchpad/checkpoint files, changelogs, release notes, or marketing copy.

## 2. Audience assumption

Assume the reader is **unfamiliar with the system**. They are either:

- **Reading linearly** — trying to learn what this surface does.
- **Looking up a specific detail** — a flag name, an API endpoint, an error condition, a state transition.

A doc that serves both modes does three things: it front-loads the definition, every section is self-contained, and structured content (enums, variants, field tables) uses tables rather than prose.

Do **not** write as if the reader is:

- A peer on the team who already knows the architecture.
- A new hire who will read the doc start to finish, in order.
- A customer browsing marketing material.

## 3. The anti-ChatGPT-voice catalog

A curated list of the writing tics that produce "ChatGPT voice." Each entry has a name, failure mode, and a rewrite pattern.

### 3.1 Narrative setup before the noun

**Fails because:** reference docs should lead with the subject. A dependent clause before the first noun forces the reader to wait for the point.

Before: "Before a customer can configure enhancements, extract attributes, generate images, or run a scrape, they need to tell Versable what file to operate on. Upload handles that handoff."
After: "Upload is the first step of every job. It records the source file and the column mapping used by every downstream module."

### 3.2 Metaphorical framing of mechanical processes

**Fails because:** technical docs describe what code does, not what it "feels like."

Triggers: `dance`, `handoff` (as a noun), `orchestrates a conversation`, `under the hood`, `behind the scenes`, `dives into`.

Before: "Submission is a transactional dance between the frontend, the Python backend, and the credit system."
After: "Submission is a two-phase transaction across the frontend, the FastAPI backend, and the credit ledger."

### 3.3 Editorial hedging with "deceptively," "surprisingly," "interestingly"

**Fails because:** editorializing importance rather than establishing it with facts.

Before: "Upload is deceptively load-bearing."
After: "Upload produces no user-visible output. It writes two records every downstream step depends on."

### 3.4 Cause-and-effect parallelism ("A sloppy X... a clean Y")

**Fails because:** rhetorical symmetry is a persuasive-writing device. Reference docs list what is true; they do not argue.

Before: "A sloppy configuration shows up as garbled enhancements four steps later; a clean configuration makes every subsequent step trivial."
After: "Misconfigured column mappings are not caught at this step. They appear as incorrect output in downstream modules."

### 3.5 Colloquialisms and idioms

**Fails because:** register mismatch.

Triggers: `hunt for`, `cover the gap`, `staged`, `yesterday's output`, `read as`, `feels instant`.

Before: "The customer doesn't need to hunt for the right template twice."
After: "The template dropdown surfaces previously-applied templates at the top."

### 3.6 Vague scope qualifiers in titles

**Fails because:** section titles are navigation targets. "And beyond" tells the reader nothing about where the section ends.

Triggers in headings: `and beyond`, `and more`, `...`, `deep dive`, `walk through`, `putting it all together`, `a deeper look at`.

Before: `## Reconfigure mode (Upload and beyond)`
After: `## Reconfigure mode` (scope specifics in the body, not the heading)

### 3.7 Filler adverbs and intensifiers

**Fails because:** zero information; often condescending ("simply" implies the reader should already know).

Triggers: `simply`, `just`, `essentially`, `basically`, `actually`, `really`, `quite`, `obviously`.

Before: "The user simply clicks upload and the file is essentially validated."
After: "The user clicks Upload; the file is validated client-side before the request fires."

### 3.8 Hedged assertions

**Fails because:** if the behavior is conditional, document the condition. If it is not, drop the hedge. Hedging is the strongest LLM signal.

Triggers: `typically`, `generally`, `usually`, `in most cases`, `tends to`.

Before: "Files are typically processed within a few seconds, though this can vary."
After: "Files under 10 MB complete parsing in under 3 seconds (p95)."

### 3.9 "It's worth noting" / "It's important to note"

**Fails because:** meta-commentary padding.

Before: "It's worth noting that `fileSelectionMode` has three possible values."
After: "`fileSelectionMode` has three values. Each renders a different picker: <table>."

### 3.10 Abstract nominalizations

**Fails because:** verbs turned into nouns plus prepositions lengthen sentences and drain them of actors.

Before: "The validation of the column map is the responsibility of the submission endpoint."
After: "`POST /api/jobs/create` validates the column map."

### 3.11 Marketing vocabulary

**Fails because:** promise words belong on a pricing page.

Triggers: `seamless`, `robust`, `powerful`, `intuitive`, `elegant`.

Before: "A seamless, intuitive experience with robust error handling."
After: "Three error states — network, parse, validation — each rendered as an inline banner with a retry action."

### 3.12 Redundant pairs

**Fails because:** bloat.

Triggers: `each and every`, `various different`, `first and foremost`, `one and the same`.

### 3.13 "This allows us to" / "This enables"

**Fails because:** capability framing instead of behavior description.

Before: "Storing the column map on the job record allows us to reuse it during reconfigure."
After: "On reconfigure, `job.columnMap` is loaded into the form as the default."

### 3.14 Lecture-voice transitions

**Fails because:** reference docs are navigated, not read in sequence.

Triggers: `Now that we've covered X, let's look at Y`, `In this section, we'll walk through`, `We'll now dive into`.

Before: "Now that we've seen the upload path, let's dive into the column map."
After: `## Column map` (new heading, no transition)

### 3.15 Over-explained obvious steps

**Fails because:** condescending to readers who know the stack.

Before: "When the user clicks Submit, an onClick handler is fired which calls a mutation which sends a POST request..."
After: "Submit calls `useCreateJobMutation` → `POST /api/jobs/create`."

### 3.16 Sentence-initial "Essentially" / "Basically" / "Importantly"

**Fails because:** same as 3.7, at the most visible position.

### 3.17 "Not just X, but Y" escalation

**Fails because:** persuasive-essay rhetoric.

Before: "The column map is not just a mapping — it's a contract."
After: "The column map is the schema contract between the frontend and downstream modules."

### 3.18 Explaining what the doc is about to do

**Fails because:** meta-commentary. The section heading already tells the reader.

Before: "In this section, we'll walk through the submission flow step by step."
After: (delete the sentence; start with step 1)

### 3.19 Diagram meta-commentary

**Fails because:** "Each node shows X" / "Edges carry the payload" / "Read this as a call graph" are instructions about the diagram, not content. If the diagram needs instructions, fix the diagram.

Before: "Edges in the diagram carry the payload where non-obvious; nodes tagged with their role so the reader can see what runs where."
After: (delete; add a one-line legend above the diagram instead, e.g., "Role tags: `[FE]` = frontend, `[API]` = server action, `[Py]` = FastAPI backend.")

## 4. Find-and-flag string list

Run this `rg` pattern against every draft. Every hit is a candidate rewrite. Not every hit is wrong, but every hit deserves a second look.

```bash
rg -n "seamless|robust|powerful|intuitive|simply|just |essentially|basically|actually|typically|generally|under the hood|behind the scenes|it's worth noting|allows us to|let's |dive into|walk through|deep dive|deceptively|surprisingly|not just |hunt for| dance |handoff|and beyond|and more |load-bearing|In this section|cross-cutting" path/to/doc.md
```

If the result is non-empty, plan a targeted cleanup pass.

## 5. Reader-centric structural rules

**R1. First sentence of every section is the definition sentence.** Subject → verb → object. No setup, no transition, no motivation.

**R2. Every section is self-contained.** A reader landing from a search result should not need to read previous sections. Never "as described above." Define or link terms on first use within the section.

**R3. Code and data before prose.** When documenting state, show the type/shape first, then describe the behavior. The reader can skip the prose if the shape answers their question.

**R4. Stable heading slugs.** Avoid titles that depend on prose flow. If you rename a heading, grep the doc for the old anchor and fix it.

**R5. Consistent ordering within parallel sections.** If three sibling sections describe three states/modes/phases, use the same subsection order across all three. Parallelism aids lookup.

**R6. One topic per section.** If a section describes X and Y and Z, it is three sections masquerading as one.

**R7. Jump tables at the top of dense sections.** If a section has more than four subsections, start it with a two-column "what's in this section" table.

## 6. Tables vs. prose decision rules

| Content shape                            | Use                                                        |
| ---------------------------------------- | ---------------------------------------------------------- |
| 3+ items sharing 2+ attributes           | Table                                                      |
| Reader's question is "which one"         | Table                                                      |
| Single causal thread                     | Prose                                                      |
| Each item needs >15 words of explanation | Promote each item to a subsection; don't cram into a table |
| Bounded enum with framing context        | Table + short lead-in paragraph                            |

Do not:

- Make prose tables (tables with paragraph-length cells).
- Make table-shaped prose (bulleted lists where every bullet starts with a noun + colon + clause — use a table).

## 7. Diagram rules

**Edges must carry:**

- A payload label (what flows down the edge): `{ fileId, columnMap }`, `job: Job`, `HTTP POST`.
- A condition label for branching edges: `if allowed`, `else`, `on retry`.
- A transport label where non-obvious: `HTTP POST`, `Jotai atom write`, `Mongo insert`.

**Nodes must carry:**

- A role tag: `[FE]`, `[API]`, `[Py]`, `[Mongo]`, `[Worker]`.
- For state-transition diagrams: the data shape at that node (`File (absent)` → `File (uploaded, unparsed)`).

**For relationship diagrams:**

- Cardinality on every edge (`1:N`, `N:1`, `N:M`).
- FK field named on the edge (`file_id`, `job_id`).

**Legend above the diagram, one line.** Do not caption-commentary-explain the diagram.

## 8. Technical-state sections need a paired product-context block

Any section documenting a piece of state (a Jotai atom, a React reducer field, a URL param) must include both:

1. **Technical shape** — the type, where it lives, how it is read/written.
2. **Product context** — user-visible trigger, user-visible effect, entry points, failure visibility, edge cases.

Template:

```markdown
### `<stateName>`

**Shape**
`<typescript type>`

**Where it lives**
Jotai atom `<atomName>` in `<path>` — persisted in `<sessionStorage | URL | none>`.

**Values and UI effect**

| Value | Rendered UI | Available actions |
| ----- | ----------- | ----------------- |
| ...   | ...         | ...               |

**How the user sets it**

- <action> → sets to `<value>`

**How the user observes it**
<brief description of visual cues>

**Failure modes (user-visible)**

- If stale: ...
- If invalid: ...
- If missing: ...

**Related state**

- Set together with `<otherFlag>` when `<condition>`.
```

## 9. Stub / pending / deprecated annotation convention

Mark unfinished or deprecated features with a grep-friendly tag. Pattern:

```markdown
[STUB — re-verify YYYY-MM-DD] One-sentence current state. Tracking: <ref>. Re-check: <concrete question>.
```

**Tag variants (one of four, nothing else):**

- `[STUB]` — UI present, backend not implemented or returns placeholder.
- `[PARTIAL]` — some cases work, others don't.
- `[PLANNED]` — documented for completeness; no implementation yet.
- `[DEPRECATED]` — still present but slated for removal.

**Additionally**, add an HTML comment so future Claude sessions can find and re-verify:

```html
<!-- claude: re-check in next review session: is <feature> wired yet? Search `<symbol>` in `<file>`. -->
```

**Find all stubs:** `rg '\[(STUB|PARTIAL|PLANNED|DEPRECATED)\b' docs/`

## 10. `[VERIFY]` inline tags

When writing a claim you're not sure of (because you didn't read the code authoritatively), flag it inline:

```markdown
Items are inserted unordered so a single failing document does not abort the batch. [VERIFY — grep `ordered` in `backend/lib/jobs/__init__.py`.]
```

Every `[VERIFY]` should name the concrete check a future session can run. Do not use vague markers like `TODO: check`.

## 11. Self-check before handoff

Before presenting a doc as finished:

- [ ] First sentence of every section is a definition sentence.
- [ ] No heading contains "and beyond," "and more," "deep dive," or a rhetorical phrase.
- [ ] Every enum of 3+ values is a table.
- [ ] Every flow diagram has role-tagged nodes and labeled edges.
- [ ] Every technical-state section has a paired product-context block.
- [ ] All stubs use the `[STUB]` / `[PARTIAL]` / `[PLANNED]` / `[DEPRECATED]` convention.
- [ ] Every uncertain claim has a `[VERIFY]` tag with a concrete check.
- [ ] Find-and-flag pass run (§4); every hit either justified or rewritten.
- [ ] Every anchor `[text](#slug)` resolves to an actual heading in the doc.
- [ ] No section relies on "as described above."
- [ ] No sentence exceeds 25 words without justification.
- [ ] No metaphors for mechanical processes.

## 12. Common failure modes during iteration

Voice regression tends to happen at predictable seams. Watch for:

- **Over-correcting to terse-to-the-point-of-cryptic.** The fix for purple prose is not telegram prose. Keep complete sentences; add the product-context back if the rewrite removed it.
- **Replacing one cliché with another.** "At its core" is not better than "under the hood." Every replacement should name an actual thing.
- **Tables that should be prose.** Three sequential steps are a short paragraph, not a three-row table.
- **New hedging creeping in when uncertain.** Don't hedge — use `[VERIFY]`.
- **Stale cross-references after renaming sections.** Grep for old anchors after every rename.
- **Inconsistent depth across parallel sections.** After cleaning one of three siblings, apply the same depth to the others.
- **Diagram drift.** If you change prose describing a flow, re-read the diagram.
- **Voice returning at section intros.** Middles stay clean; intros regress. Final pass should focus on intros only.
- **Losing the factual kernel when deleting ChatGPT voice.** "A sloppy configuration shows up as garbled enhancements four steps later" is bad voice but contains a real fact. Preserve the fact in the rewrite.
- **Reusing one fix pattern mechanically.** Don't convert every flagged sentence into a bullet list.

## 13. Iteration workflow

1. Read the current doc top to bottom without editing.
2. Run the find-and-flag string list (§4). Record every hit with line numbers.
3. For each section, apply §5 (reader-centric rules) and §2 (audience test).
4. Identify every enum of 3+ items; promote to tables.
5. Add product-context blocks (§8) where state sections lack them.
6. Re-title every section against §5/R4.
7. Mark every stubbed or uncertain claim (§9, §10).
8. Redraw every diagram against §7.
9. Run the self-check list (§11).
10. Final pass focused only on section intros (the highest-risk regression point).

Budget: roughly 1.5× the time the first draft took. A doc flagged for systemic voice issues needs a full pass, not spot fixes.

## 14. Escalation — when to ask

Pause and ask the user rather than guessing, if:

- The doc contradicts the code and you are not sure which is authoritative.
- A section cannot be made self-contained without duplicating significant content (propose a cross-reference).
- A stubbed feature has no tracking reference (ask for one; do not invent).
- A backend or external-system behavior is load-bearing to the doc and you have not read that system.
- A section reads flat no matter how you phrase it — the underlying content may be wrong, not the voice.

---

_Written 2026-04-23. Source of rules: iteration on `docs/product/jobs/create-upload.md`, R0 sub-agent coaching guide, R1 (78/100) and R2 (88/100) review passes._
