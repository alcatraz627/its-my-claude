---
name: write-docs
description: Scans a codebase to generate focused technical documentation — API references, guides, ADRs, changelogs, or onboarding docs — with anti-fluff voice calibration.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebFetch
user-invokable: true
argument-hint: "<api | guide | adr | changelog | onboarding> [options]"
---

## Brief

Scans a project's code, config, and existing docs, asks focused clarifying questions,
then generates technical documentation that reads like a senior engineer wrote it.
Baked-in anti-fluff rules prevent sycophantic, ChatGPT-style prose.

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
/write-docs <mode> [--out <path>] [--format md|html|pdf] [--audience <who>]
```

| Mode | What it generates |
| ---- | ----------------- |
| `api` | API reference from route files, endpoints, request/response shapes |
| `guide` | How-to guide for a specific feature or workflow |
| `adr` | Architecture Decision Record for a recent or proposed change |
| `changelog` | Release changelog from git history between two refs |
| `onboarding` | New-developer onboarding doc for the project |

| Option | Default | Description |
| ------ | ------- | ----------- |
| `--out <path>` | `.claude/output/docs/` | Where to write the output file |
| `--format` | `md` | Output format: `md` (markdown), `html` (via /create-report), `pdf` (via /generate-pdf) |
| `--audience` | auto-detect | Target reader: `developer`, `user`, `ops`, `stakeholder` |

---

## Voice Rules — MANDATORY

These rules govern all text this skill produces. They are non-negotiable.

### Banned Phrases

Never use these words or phrases in generated documentation:

| Banned | Replace with |
| ------ | ------------ |
| "comprehensive" | (delete — if the doc is comprehensive, the reader will notice) |
| "robust" | specific: "handles X and Y edge cases" |
| "seamless" | specific: "requires no manual step between X and Y" |
| "powerful" | (delete — show, don't tell) |
| "cutting-edge" | (delete entirely) |
| "leverage" | "use" |
| "utilize" | "use" |
| "facilitate" | (rewrite the sentence) |
| "in order to" | "to" |
| "it is important to note that" | (delete — just state the thing) |
| "Welcome to the X documentation" | (delete — start with what the reader needs to do) |
| "This document provides a comprehensive overview" | (delete — the TOC does that) |
| "As you can see" | (delete) |
| "Simply" / "just" / "easily" | (delete — nothing is simple if you have to say it) |

### Voice Principles

1. **Imperative over descriptive.** "Run `npm install`" not "You can install dependencies by running..."
2. **Code before prose.** Show the example first, then explain what it does — not the reverse.
3. **One idea per paragraph.** Max 3 sentences in API docs, 5 in guides.
4. **Answer "what do I do?" not "what is this?"** Every section must answer a concrete question a reader has.
5. **No preamble.** Start with the first useful sentence. No "In this section, we will..."
6. **Specificity over generality.** "Responds with 401 if the JWT is expired" not "Handles authentication errors appropriately"
7. **Match existing voice.** If the project has existing docs, read 2-3 of them and match their tone, sentence length, and heading style. If no existing docs, default to terse-technical.

### Self-Check

After generating each section, re-read it with this lens:
- Would a senior engineer roll their eyes at any sentence? If yes, cut or rewrite it.
- Does every sentence tell the reader something they didn't already know? If not, delete it.
- Is there a code example within the first 3 lines of every "How to" section? If not, add one.

---

## Mode: `api`

### Phase 1 — Scan

1. Detect the API framework:
   - Express/Fastify: scan `src/routes/`, `src/api/`, or files matching `**/route.{ts,js}`
   - FastAPI/Flask: scan `**/routes.py`, `**/views.py`, `app/api/`
   - Next.js App Router: scan `app/**/route.{ts,js}`
   - If unclear, ask user

2. For each route file, extract:
   - HTTP method (GET, POST, PUT, DELETE, PATCH)
   - Path / URL pattern
   - Request body type (Zod schema, Pydantic model, TypeScript interface)
   - Response shape (return type, status codes)
   - Middleware / guards (auth, rate limiting, validation)
   - Query parameters and path parameters

3. Scan for shared types:
   - Grep for `export type`, `export interface`, `class.*BaseModel`, `Schema`
   - Map which types are used by which endpoints

4. Print discovery summary:
   ```
   Found 14 API routes across 6 files
   Frameworks: Next.js App Router + Zod validation
   Auth: JWT middleware on 11/14 routes
   Types: 8 shared schemas in src/lib/schemas/
   ```

### Phase 2 — Clarify

Ask the user 2-4 targeted questions (use `mcp__inputs__form`):

- **Base URL:** "What's the base URL for the API? (e.g., `https://api.example.com/v1`)"
- **Auth method:** "How do clients authenticate? (e.g., Bearer token, API key, session cookie)"
- **Audience:** "Who reads this? (developers integrating the API / internal team / public)"
- **Exclusions:** "Any routes to skip? (e.g., internal admin, health checks)"

### Phase 3 — Generate

Structure the API doc as:

```markdown
# <Project> API Reference

Base URL: `<url>`
Authentication: <method>

## Endpoints

### <Group Name>

#### `METHOD /path`

<One sentence: what this does>

**Request**

| Parameter | Location | Type | Required | Description |
| --------- | -------- | ---- | -------- | ----------- |

```json
// Request body example
```

**Response** `200`

```json
// Response example
```

**Errors**

| Status | When |
| ------ | ---- |
| 401 | Token expired or missing |
| 422 | Validation failed — see body for field errors |
```

Group endpoints by resource (Users, Posts, etc.), not by HTTP method.

### Phase 4 — Verify

1. Count: every discovered route has a corresponding section
2. Check: every endpoint has at least a request and response example
3. Validate: no banned phrases leaked through
4. If `--format html`: pipe to `/create-report` with `data-table` style
5. If `--format pdf`: pipe to `/generate-pdf`

---

## Mode: `guide`

### Phase 1 — Scope

Ask the user: "What feature or workflow should this guide cover?"
Then ask: "Who is the reader and what are they trying to accomplish?"

### Phase 2 — Scan

Trace the feature through the codebase:
1. Find the entry point (UI component, API route, CLI command)
2. Follow the call chain: component → hook → API call → handler → database
3. Note configuration files, environment variables, and dependencies involved

### Phase 3 — Generate

Structure:

```markdown
# How to <do the thing>

<One paragraph: what this guide covers and who it's for>

## Prerequisites

- <what must be installed/configured first>

## Steps

### 1. <First action>

```code
example
```

<Why this step matters — one sentence>

### 2. <Next action>

...

## Troubleshooting

| Problem | Cause | Fix |
| ------- | ----- | --- |

## Related

- [Link to related guide or API doc]
```

### Phase 4 — Verify

Walk through the guide mentally as a new developer. Flag any step that assumes knowledge not covered in Prerequisites.

---

## Mode: `adr`

### Phase 1 — Gather

Ask the user (use `mcp__inputs__form`):
- **Decision:** "What architectural decision was made?"
- **Context:** "What problem triggered this? What constraints exist?"
- **Alternatives:** "What other options were considered?"
- **Consequences:** "What trade-offs does this create?"

If the user is vague, scan recent git history for relevant commits and ask focused follow-ups.

### Phase 2 — Generate

Follow the Michael Nygard ADR format:

```markdown
# ADR-<NNN>: <Decision Title>

**Date:** <YYYY-MM-DD>
**Status:** Accepted | Proposed | Superseded by ADR-XXX

## Context

<What forces are at play. 2-4 sentences. No opinions — just facts.>

## Decision

<What we decided and why. Be specific about what changes.>

## Alternatives Considered

### <Alternative 1>
<Why it was rejected. 1-2 sentences.>

### <Alternative 2>
<Why it was rejected. 1-2 sentences.>

## Consequences

### Positive
- <benefit>

### Negative
- <trade-off>

### Neutral
- <thing that changes but isn't better or worse>
```

Save to `docs/adr/` or `docs/decisions/` (create the directory if needed). Number sequentially based on existing ADRs.

---

## Mode: `changelog`

### Phase 1 — Scan

1. Determine the range: ask for two git refs, or default to `<last-tag>..HEAD`
2. Get commits: `git log --oneline --no-merges <range>`
3. If conventional commits are used, parse prefixes: `feat:`, `fix:`, `docs:`, `chore:`, etc.
4. If not conventional, categorize by files touched:
   - `src/components/` → UI changes
   - `src/api/` → API changes
   - `tests/` → Testing
   - `package.json` → Dependencies

### Phase 2 — Generate

```markdown
# Changelog — <version or date range>

## New Features
- <description> ([commit-hash])

## Bug Fixes
- <description> ([commit-hash])

## Breaking Changes
- <description> — **Migration:** <what to do>

## Other
- <description>
```

Collapse trivial commits (typo fixes, linting). Expand user-facing changes with enough context to understand the impact.

---

## Mode: `onboarding`

### Phase 1 — Deep Scan

Scan everything a new developer needs:
1. **Setup:** `package.json` scripts, `Makefile`, `docker-compose.yml`, `.env.example`
2. **Architecture:** directory structure, framework choice, state management
3. **Conventions:** naming patterns, file organization, import style
4. **Testing:** test framework, test location, how to run
5. **Deployment:** CI/CD config, hosting platform, environment management
6. **Key files:** the 5-10 files a new developer should read first

### Phase 2 — Clarify

Ask:
- "Any tribal knowledge that isn't in the code?" (e.g., "always restart Redis after schema changes")
- "What's the biggest gotcha for new developers?"
- "Any services/accounts needed? (e.g., Stripe test keys, database access)"

### Phase 3 — Generate

```markdown
# Getting Started with <Project>

## What This Is

<2 sentences. What the project does and who uses it.>

## Setup

### Prerequisites

- Node.js >= <version>
- <database>
- <other>

### First Run

```bash
git clone <repo>
cd <project>
<install command>
cp .env.example .env  # Then fill in: <list specific vars>
<start command>
```

Open <url> — you should see <what>.

## Architecture

```
<directory tree of important paths>
```

<3-5 sentences explaining the structure>

## Key Concepts

### <Concept 1>
<2-3 sentences>

### <Concept 2>
<2-3 sentences>

## Development Workflow

1. Create a branch: `git checkout -b feat/<name>`
2. Make changes
3. Test: `<test command>`
4. PR: `<pr process>`

## Gotchas

- <thing that will bite you>
- <another thing>

## Where to Find Things

| Looking for... | Look in... |
| -------------- | ---------- |
| API routes | `src/api/` |
| Components | `src/components/` |
| Types | `src/types/` |
| Tests | `__tests__/` |
```

### Phase 4 — Verify

Read the onboarding doc as if you have zero context. Flag any step that says "configure X" without saying how.

---

## Output & Integration

- Default output: write to `--out` path as markdown
- `--format html`: generate markdown first, then invoke `/create-report` on it (auto-select style based on content type)
- `--format pdf`: generate markdown first, then invoke `/generate-pdf` on it
- Always print the absolute path to the generated file

---

## Notes

- This skill reads code but never modifies it — documentation only
- Voice calibration reads existing project docs before generating. If no docs exist, falls back to terse-technical baseline
- The anti-fluff rules are checked after every section is generated, not just at the end
- For `api` mode: the skill prefers reading actual type definitions over inferring from usage
- For `changelog` mode: if the repo uses conventional commits, parsing is automatic; otherwise it falls back to file-path heuristics
- Chains with: `/create-report` (html output), `/generate-pdf` (pdf output), `/readme` (project overview)
