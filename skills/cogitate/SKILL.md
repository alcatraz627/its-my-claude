---
name: cogitate
description: >
  Use when the user wants to research a topic and keep a durable, growing note
  on it — answers a query and files a dated structured response under
  ~/Documents/Claude/Topics/, maintaining _index.claude.md, _insights.claude.md,
  and topic-specific templates. For heavy multi-source fact-checked reports,
  route to /deep-research instead.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch, Agent
argument-hint: "[quickly] <query or direction>"
user-invokable: true
---

## Brief

Interprets a user query, refines it with context, researches online or from
existing topic files, and produces a structured response — saved to a dated
topic file and indexed automatically. Learns over time via `_insights.claude.md`
and a growing library of topic-specific templates.

---

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after. Never write to `runtime-notes.md` or any SKILL.md without
> holding its lock.

---

## Usage

```
/cogitate [quickly] <query or direction>
```

| Argument | Type | Description |
|---|---|---|
| `quickly` | optional flag | Fast mode: make assumptions, skip clarifying questions |
| `<query>` | required | The question, topic, or direction to cogitate on |

**Modes:**
- **Normal** (default) — ask 1–2 targeted questions if the query is genuinely ambiguous
- **Quick** — state all assumptions upfront, proceed without waiting for confirmation
- **Deep** — triggered automatically when broad multi-source research or
  fact-checking is needed; delegates to the `/deep-research` skill rather than
  running cogitate's own researcher (see Phase 2.2)

---

## Working Directory

All topic files live in `~/Documents/Claude/Topics/`.
This directory is created automatically on first run.

**Persistent files in this directory:**

| File | Purpose |
|---|---|
| `_index.claude.md` | Registry of all topic files + template variants |
| `_insights.claude.md` | Prepend-only log of post-run lessons (newest first) |
| `<DD MMM YY> - <Topic>.md` | Individual topic files |

**Skill-local files (in `~/.claude/skills/cogitate/`):**

| Path | Purpose |
|---|---|
| `templates/topic-template.md` | Default topic file skeleton |
| `templates/<variant>-template.md` | Topic-specific template variants |
| `scripts/new-topic.sh` | Creates a dated topic file from a template |
| `scripts/update-index.sh` | Upserts an entry in `_index.claude.md` |
| `scripts/update-insights.sh` | Prepends an entry to `_insights.claude.md` |
| `agents/deep-research.md` | Sub-agent instructions for deep research tasks |

---

## Phase 0 — Session Bootstrap

1. **Ensure working directory exists:**
   ```bash
   mkdir -p ~/Documents/Claude/Topics
   ```

2. **Read `_insights.claude.md`** (last 5–10 entries) — apply any efficiency lessons
   to the current run before doing anything else.

3. **Read `_index.claude.md`** — scan for existing topic files that may be relevant
   to the current query (look for title/summary overlap).

4. **Glob for template variants:**
   ```
   ~/.claude/skills/cogitate/templates/*-template.md
   ```
   Build an awareness map of `{ variant-name → use-case description }` for Phase 1.

---

## Phase 1 — Intent Interpretation

### 1.1 — Parse query and detect mode

- If the query starts with `quickly` (case-insensitive): set **quick mode**. Strip the word.
- If the query contains `deep research`, `investigate thoroughly`, or `full analysis`:
  set **deep mode** — a sub-agent will be spawned in Phase 2.
- Otherwise: **normal mode**.

### 1.2 — Assess ambiguity

Ask yourself: *"Could this query mean two meaningfully different things?"*

- If yes AND NOT in quick mode → ask the user one targeted question. Wait for the answer.
- If yes AND in quick mode → state your interpretation assumption upfront and proceed.
- If no → proceed.

Do not ask more than one clarifying question. Prefer proceeding with a stated assumption
over blocking on confirmation.

### 1.3 — Select template

Review the variant map from Phase 0. Match the topic's category against variant use-cases:

```
If a variant's stated use-case clearly fits this topic:
  → use that variant, announce the choice:
    "Using <variant-name> template (matched: <reason>)."
Else:
  → use default topic-template.md, note it for Phase 3.5 review.
```

**Example categories and their natural variants (once created):**

| Topic type | Template variant to look for |
|---|---|
| CLI tool / command reference | `cli-tool-template.md` |
| Current events / news | `news-event-template.md` |
| Technical architecture / design | `tech-design-template.md` |
| How-to / tutorial | `how-to-template.md` |
| Person / organisation profile | `profile-template.md` |

---

## Phase 2 — Refinement & Research

### 2.1 — List sharpening context

Before researching, briefly state:
- What you already know about this topic
- What the 1–2 most important unknowns are
- What sources you plan to consult

### 2.2 — Research

**For online topics:** use WebSearch → WebFetch on the 2–3 most promising results.

**For local topics:** Glob `~/Documents/Claude/Topics/` for related files, Read the
most relevant ones.

**For deep mode:** delegate to the `/deep-research` skill — the shared harness
for fan-out web search, source fetching, adversarial claim verification, and
cited synthesis. Don't reimplement it here; cogitate's job is to file the result
as a topic note, not to re-run a multi-source pipeline.

```
/deep-research <refined question>
```

Pass the refined question and what you already know. When it returns its cited
report, carry that into Phase 2.3 (Synthesise) and Phase 3 (file it as the topic
response). The legacy `agents/deep-research.md` sub-agent is retained only as a
fallback for when `/deep-research` is unavailable.

### 2.3 — Synthesise

Combine research findings into a coherent answer. For multi-part questions, handle each
part in order. Flag anything you couldn't verify.

---

## Phase 3 — Execution

### 3.1 — Create topic file

```bash
SKILL_DIR="$HOME/.claude/skills/cogitate"
TEMPLATE="$SKILL_DIR/templates/<selected-template>.md"
TOPICS_DIR="$HOME/Documents/Claude/Topics"

bash "$SKILL_DIR/scripts/new-topic.sh" \
  "<Topic Title>" \
  "<Category>" \
  "$TEMPLATE" \
  "$TOPICS_DIR"
```

If the script fails: manually derive the filename (`DD MMM YY - <Title>.md`), copy
the template content, and write the file with the Write tool.

### 3.2 — Fill the topic file

Write the research output into the file following the template structure.
Fill every section; mark sections that don't apply as `N/A` rather than leaving them blank.

**After every subsequent user message in this session:** update the topic file with the
new exchange — append to the relevant sections (Answer/Findings, Sources, Open Questions).
Increment the `Interactions:` counter in the frontmatter.

### 3.3 — Update index

```bash
bash "$SKILL_DIR/scripts/update-index.sh" \
  "<filepath>" \
  "<one-line summary of the topic>" \
  "$TOPICS_DIR"
```

If the script fails: manually Edit `_index.claude.md` to add or update the row.

---

## Phase 3.5 — Template Variant Review

After writing the topic file, assess structural fit:

**Evaluate:**
- Were any template sections skipped entirely because they didn't make sense?
- Were any significant sections invented that aren't in the template?
- Would a different section order have been more natural?

**Decision:**

```
If the default template was a natural fit (minor tweaks only):
  → No action. Note it as confirmation in the insights entry.

If 2+ sections were wrong/missing/invented:
  → A new template variant is warranted.
```

**Creating a variant:**

1. Derive a skeleton from the actual structure used in this run.
2. Show it to the user inline:
   ```
   This topic is a <category>. The default template didn't fit well — here's a
   proposed variant based on what we actually used:

   ---
   [skeleton preview]
   ---

   Save this as `<variant-name>-template.md`? (yes / no / edit first)
   ```
3. On approval: write `templates/<variant-name>-template.md`. Include a header block:
   ```markdown
   ---
   template: <variant-name>
   use-case: <one sentence describing when to use this over the default>
   created: <date>
   ---
   ```
4. Add the variant to `_index.claude.md`'s Template Registry table.

---

## Phase 4 — Insights + Verification

### 4.1 — Write insights entry

Compose a run entry for `_insights.claude.md`:

```markdown
## <Topic Title> — <DD MMM YY HH:MM>
**Category:** <query type>
**Template used:** <name> [new variant created: yes/no]
**What worked:** <1–3 bullet points — what research path / tools were efficient>
**What to improve:** <1–2 bullet points — what was slow, redundant, or surprising>
**Rule for next time:** <one actionable sentence for a future run on this topic type>
---
```

Save to `/tmp/cogitate-insights-entry.md`, then:

```bash
bash "$SKILL_DIR/scripts/update-insights.sh" \
  "/tmp/cogitate-insights-entry.md" \
  "$TOPICS_DIR"
```

If the script fails: manually prepend the entry to `_insights.claude.md` using Edit.

### 4.2 — Print run summary

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_complete "cogitate" \
  "Topic file=~/Documents/Claude/Topics/<filename>" \
  "Template=<name used>" \
  "Interactions=<N>" \
  "Index=updated" \
  "Insights=updated" \
  "New variant=<name> | none"
```

### 4.3 — Offer /create-report

If the topic file is substantive (>300 words, multiple sections with real content):

```
Want an HTML report of this topic? Run /create-report on the topic file.
```

---

## Notes

- **Quick mode** must state all assumptions before the first tool call — never silently assume.
- **Template variant creation** always requires user approval. Never auto-save silently.
- **Fallback rule:** if any script fails, attempt the equivalent operation manually using
  Write/Edit tools. Never fail the run because a script errored.
- **Session continuity:** within one session, `/cogitate` may handle multiple follow-up
  questions on the same topic. All exchanges update the same topic file. A new file is
  only created for a genuinely new topic.
- **Working dir scope:** never write outside `~/Documents/Claude/Topics/` except when
  chained skills (`/create-report`) write their own output.

---

## See Also

- **`/deep-research`** — the multi-source fact-checking research harness. Deep mode
  routes here (Phase 2.2) instead of re-running its own pipeline.
- **`~/.claude/personas/web-researcher.md`** — the cited, adversarial open-web
  research disposition. Adopt it when a query needs rigorous sourcing before it
  becomes a cogitate topic note; cogitate then files the result.
- **scratchpad MCP** (`mcp__scratchpad__sp_*`) — inter-skill working memory. Use it
  to hand off intermediate research notes when chaining cogitate with
  `/deep-research`, web-researcher, or `/create-report`, rather than passing large
  blobs through the conversation.
- **`/create-report`** — turns a substantive topic file into a standalone HTML
  report (offered in Phase 4.3).
