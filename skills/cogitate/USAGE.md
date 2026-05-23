# /cogitate — Usage Guide

## What it does

Interprets a query or direction, refines context, researches online or from existing
topic files, and saves a structured dated response to `~/Documents/Claude/Topics/` —
updating the index and insights log after every run.

## Usage

```
/cogitate [quickly] <query or direction>
```

| Argument | Type | Description |
|---|---|---|
| `quickly` | optional | Fast mode: state assumptions and skip clarifying questions |
| `<query>` | required | The question, topic, or direction |

## Examples

### Example 1: Factual research

```
/cogitate why was Air India Express IX-1062 delayed on March 17 2026
```

Researches the flight delay, finds the Iran war connection, writes
`18 Mar 26 - Air India IX-1062 Delay Analysis.md`, updates index and insights.

### Example 2: Quick mode

```
/cogitate quickly best Python ORM for FastAPI in 2026
```

Makes reasonable assumptions (async, PostgreSQL, greenfield project), skips
confirmation, returns a comparison immediately. States all assumptions in the
first paragraph of the topic file.

### Example 3: Deep research

```
/cogitate deep research impact of Iran war 2026 on Indian aviation
```

Spawns a sub-agent (see `agents/deep-research.md`) to do exhaustive web research,
then synthesises findings into a comprehensive topic file. Likely triggers a
`news-event-template.md` variant creation if one doesn't exist.

### Example 4: Follow-up in same session

```
/cogitate  ← first run, creates the topic file
user: also check what the DGCA said about pilot duty extensions
```

Follow-up exchanges update the same topic file rather than creating a new one.
Interaction count increments in the file frontmatter and index.

## Template system

On each run, `/cogitate` checks `templates/` for a variant that matches the topic type:

- If a match is found → uses it, announces the choice
- If no match → uses `topic-template.md` (default) and evaluates fit post-run
- If fit was poor → proposes a new variant, waits for approval before writing

Template variants grow over time and are registered in `_index.claude.md`'s
Template Registry table.

## Persistent files

| File | Location | Purpose |
|---|---|---|
| `_index.claude.md` | `~/Documents/Claude/Topics/` | File registry + template registry |
| `_insights.claude.md` | `~/Documents/Claude/Topics/` | Post-run efficiency lessons |
| Topic files | `~/Documents/Claude/Topics/` | One per topic, named `DD MMM YY - Title.md` |

## Caveats

- A new topic file is only created for a genuinely new topic — follow-ups update
  the existing file.
- Template variant creation always requires user approval — never auto-saved silently.
- Deep mode spawns a sub-agent that may take longer; normal and quick modes are fast.
- Scripts in `scripts/` are helpers; if any fail, the skill falls back to manual
  Write/Edit operations and continues.

## Dependencies

| Dependency | Type | Notes |
|---|---|---|
| `GUIDELINES.md` | Shared rules | Read at start of every run |
| `scripts/new-topic.sh` | Shell script | Creates dated topic file; fallback: Write tool |
| `scripts/update-index.sh` | Shell script | Updates index; fallback: Edit tool |
| `scripts/update-insights.sh` | Shell script | Updates insights log; fallback: Edit tool |
| `agents/deep-research.md` | Sub-agent prompt | Used only in deep mode |
| `templates/topic-template.md` | Default template | Always present |

## Tips

- Use `quickly` when you just want an answer fast and don't need interactive refinement.
- After several runs on similar topics, the template library grows — `/cogitate` gets
  better at picking the right structure automatically.
- Combine with `/create-report` for a polished HTML view of any topic file.
- The `_insights.claude.md` file is worth reading manually — it accumulates genuinely
  useful patterns about how to research different topic types efficiently.
