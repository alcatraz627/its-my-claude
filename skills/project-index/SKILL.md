---
name: project-index
description: Scans the project structure, key files, dependencies, and architectural patterns — generates a comprehensive index markdown and optional HTML report. Runs in an isolated forked context to avoid polluting main conversation with hundreds of file reads.
allowed-tools: Read, Write, Glob, Grep, Bash
user-invokable: true
argument-hint: "[latest | output_path]"
context: fork
---

## Brief

Scans the project and writes a comprehensive index — directory structure, key files,
dependencies, architectural patterns, key exports, and representative code snippets — to a
markdown file, then optionally renders it as an HTML report. Runs in an isolated forked
context so hundreds of file reads don't pollute the main conversation; the parent gets a short
structured summary back, not the file dumps.

# Project Index Builder

This skill builds a navigable index of a project's structure so a reader (or a future skill
run, or `/arch-qa`) can answer questions about the codebase without re-reading it. The body
below is stack-agnostic — it detects the project's own conventions and indexes what it finds.
A worked example for one concrete stack lives in the appendix at the bottom.

## Usage

```
/project-index [latest | output_path]
```

**Arguments:**

- `latest` — Skip scanning. Regenerate the HTML report from the last saved index and open it.
  If no previous index exists, say so and ask whether to run a fresh scan.
- `output_path` (optional) — Where to save the index. Defaults to `.claude/project-index.md`.

**Files this skill maintains:**

- `.claude/project-index.md` — the generated index (overwritten each run)
- `.claude/indexing-notes.md` — append-only run log; each entry dated, summarizing what changed
- `.claude/output/<datetime>-project-index/` — timestamped HTML report folder from `/create-report`

## Step 0: Load guidelines and prior context

Read `.claude/skills/GUIDELINES.md` and apply its rules for the whole run — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the **file lock
protocol**. Acquire a lock via `lock-file.sh acquire` before any Edit/Write and release it
immediately after.

Read `.claude/skills/runtime-notes.md` for past run history relevant to this skill (continue
without it if absent).

If `.claude/project-index.md` already exists, read it in full and use it as a baseline — don't
re-discover what's confirmed unchanged. Concentrate scanning effort on what's most likely to
have drifted: new directories, changed dependencies, new routes, new schema files. If
`.claude/indexing-notes.md` exists, read it too — it records what has changed historically and
which areas churn.

## Argument handling

Check the argument before doing anything else.

**If the argument is `latest`:**

1. `ls .claude/project-index.md 2>/dev/null`
2. If the file is absent, print the message below, then stop and wait for confirmation:
   ```
   No previous index found at .claude/project-index.md.
   Would you like to run a full scan now? (Reply "yes" to proceed.)
   ```
3. If the file exists, run `/create-report .claude/project-index.md` (it renders a timestamped
   HTML report under `.claude/output/` and opens it), print `✓ Regenerated HTML report`, and
   stop — run no scan steps.

**Otherwise**, continue to the scan workflow.

---

## Workflow

### Step 1: Discover project root and type

Identify the project's shape before scanning its contents. Look for the manifests and lockfiles
that mark the ecosystem, and infer:

- **Package/build manifest** — `package.json`, `pyproject.toml`/`requirements.txt`, `Cargo.toml`,
  `go.mod`, `pom.xml`/`build.gradle`, `Gemfile`, `composer.json`, etc.
- **Package manager / toolchain** — read the lockfile (`package-lock.json`, `pnpm-lock.yaml`,
  `yarn.lock`, `poetry.lock`, `Cargo.lock`, `go.sum`) and any `packageManager` / engines field.
- **Monorepo markers** — `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`,
  workspace globs in the manifest, or a top-level `packages/` / `apps/` split.
- **Primary framework** — from the dependencies and entry-point files, not from assumption.

Record the ecosystem you detected; it determines which patterns the later steps look for.

### Step 2: Map directory structure

Use Glob to discover the directory tree, then describe each top-level (and important
second-level) directory by what it actually contains — read a few files if a folder's purpose
isn't obvious from its name. Capture the project's naming conventions as you go (kebab vs camel
filenames, `*.server.ts` / `*.client.ts` style suffixes, route-group folders, etc.). Don't
force a generic taxonomy onto the tree; describe the structure the project actually has.

### Step 3: Identify key files

Glob for the files a new reader would open first:

```
**/*.config.{js,ts,mjs,cjs}    **/tsconfig*.json     **/package.json
**/pyproject.toml              **/Cargo.toml         **/go.mod
**/.env*                       **/README*            **/Dockerfile*
```

For each, note its purpose and any non-default settings. Identify the entry points — the file
the runtime starts from, the root layout/app file, the server bootstrap, the CLI main.

### Step 4: Analyze dependencies

Read the manifest(s) and split production vs dev/build dependencies. Group by the role each
library plays in *this* project (framework, UI/styling, state, data fetching, database/ORM,
auth, infra, utilities, build/test). Infer a group only when you see the dependency; don't list
empty groups. For polyglot or monorepo projects, do this per package.

For each dependency, resolve a canonical link and write it as `[name](url) (version) — purpose`:

1. **npm** → `https://npmjs.com/package/<name>` (npmjs.com accepts unencoded scoped names like
   `@tanstack/react-query`).
2. **PyPI** → `https://pypi.org/project/<name>/`; **crates.io** → `https://crates.io/crates/<name>`;
   **Go** → `https://pkg.go.dev/<module>`.
3. **Well-known GitHub-first packages** — prefer the canonical repo URL when you know it.

Example:

```
- [react](https://npmjs.com/package/react) (^19.2.3) — UI library
- [fastapi](https://pypi.org/project/fastapi/) (^0.115) — async web framework
```

### Step 5: Identify architectural patterns — detect the project's own pattern

The goal is to name how *this* project does state, data access, API calls, and styling — using
evidence from its own files, not a fixed checklist. The method:

1. **From the dependencies (Step 4), form a hypothesis.** A `jotai` dep suggests atom-based
   state; `zustand` suggests a store; neither suggests Context or a custom solution. `drizzle`,
   `prisma`, `sqlalchemy`, `mongoose`, `gorm` each imply a different ORM idiom.
2. **Confirm by reading, not by assuming.** For the top one or two hypotheses, open a file that
   should exemplify the pattern and verify the idiom is actually used there. A dependency in the
   manifest that no source file imports is not a pattern in use.
3. **When no dependency names the approach** (Context-only state, hand-rolled fetch, vanilla
   CSS, a bespoke layer), find the convention by grepping the source for the construct, then
   reading a representative hit. Scope the grep to the source root and the file types the
   project actually uses; let one confirmed example stand for the pattern rather than
   enumerating every call site.

Document, for each axis the project has: **state management**, **API/data communication**,
**database/ORM**, **component organization**, and **styling** — one short paragraph each,
grounded in a named example file. Omit an axis the project doesn't have (a CLI tool has no
component layer; a pure library may have no styling).

### Step 5.5: Document key exports

A file-level index tells you `use-q.ts` exists but not that it exports `useQ`. This step adds a
symbol-level reference table for the modules a consumer imports from most.

1. **Pick the export-heavy modules** — utility/helper dirs, hooks, context factories, public
   API surfaces, shared type modules. These are where cross-cutting symbols live.
2. **Grep for top-level named exports** using the construct for the project's language. Adapt
   the pattern to what you see in the tree — a few examples:
   - TypeScript/JS: `^export (function|const|class|type|interface|enum)` and
     `^export default`
   - Python: `^def `, `^class `, plus names listed in `__all__`
   - Rust: `^pub (fn|struct|enum|trait|const|type)`
   - Go: top-level identifiers with a capitalized first letter
3. For each match capture **symbol**, **file** (relative, trim a common prefix for brevity), and
   a one-line **description** — inferred from the name, or from the first doc-comment above it.

**Include:** exported functions/hooks with meaningful names; exported enums/constants that act
as reference tables (route maps, query-key factories, param-name enums); factory functions;
broadly-used type aliases. **Skip:** file-internal helpers, re-exports (they belong to the
source module's row), trivially-named or boilerplate exports.

Emit a `## Key Exports` markdown table (`Symbol | File | Description`). Prioritize the
most-imported modules; aim for ~15–35 rows — a useful lookup table, not an exhaustive dump.

### Step 6: Document component / module structure

For projects with a UI layer, map the component hierarchy by directory (layout / common /
feature folders, or whatever grouping the project uses). For non-UI projects, map the analogous
unit — packages in a monorepo, services in a backend, command modules in a CLI. Use Glob to
enumerate, then group by directory.

### Step 6.5: Collect key code snippets

Extract 6–10 short, representative snippets from the most architecturally significant files —
the ones that show the project's core patterns, not boilerplate. Good candidates: the root
provider/bootstrap, the data-model/schema definition, the data-access or query-client setup, a
context/factory, one non-trivial example of the dominant pattern (a hook, an atom, a service),
and one entry point.

Rules: capture **10–25 lines** per snippet (use Read `offset`+`limit` to slice the meaningful
section); prefer the start of a file (imports + first exported declaration) unless a later
section is more revealing; skip generated files, config boilerplate, and pure re-export
barrels. Place them in a `## Key Code Snippets` section, each a fenced block under a
`### path/to/file — one-line description` heading.

### Step 7: Generate the index document

Write the markdown to the output path with this structure (omit sections the project doesn't
have; lumpy is fine):

````markdown
# Project Index

**Generated:** [timestamp]   **Project:** [name]   **Location:** [absolute path]

## Overview
- **Framework / Runtime:** …   **Language:** …   **Package Manager:** …   **Type:** …

## Directory Structure
<!-- indented bullet tree — create-report converts these to expandable tree blocks -->

## Key Files
### Configuration
### Entry Points

## Dependencies
### Production    <!-- [name](url) (version) — purpose -->
### Development

## Architectural Patterns
### State Management   ### API / Data   ### Database/ORM   ### Components   ### Styling

## Routes / Entry Points        <!-- if the project has them -->

## Key Exports                  <!-- table from Step 5.5: Symbol | File | Description -->

## Key Code Snippets            <!-- 6–10 fenced blocks from Step 6.5 -->

## Notes
- [special patterns, conventions, technical debt, unique decisions]
````

### Step 8: Save, print, report

Save the index, then `cat` it to the terminal so the user can read it inline. Also print a
concise run summary: directories discovered, new directories/files since last run (or "first
run"), dependencies added/removed, notable architectural changes.

### Step 9: Append to indexing-notes.md

After saving the index, append a dated entry to `.claude/indexing-notes.md` (append-only —
never overwrite). Read the file first; create it with the header below if absent, else append.

```markdown
---
## Run: [YYYY-MM-DD HH:MM] — [one-line summary]
### What was scanned
- [full vs incremental, scope]
### Changes since last run
- [new/removed dirs, files, modules; dependency changes; schema changes; or "No changes detected"]
### Notable findings
- [patterns, anomalies, architectural shifts, debt to watch]
### Files updated this run
- `.claude/project-index.md` — [overwritten / created]
- `.claude/indexing-notes.md` — [this entry appended]
```

Header when creating the file fresh:

```markdown
# Indexing Notes

Append-only log of every `/project-index` run. Newest entries at the bottom.

---
```

### Step 10: Generate the HTML report via /create-report

Feed the saved index to `/create-report .claude/project-index.md`. It reads the markdown,
writes a timestamped HTML report to `.claude/output/<datetime>-project-index/` (three files:
`index.html`, `styles.css`, `report.js`), and opens it. Don't run a separate `open` command —
`create-report` handles it.

If `/create-report` is unavailable, skip this step and tell the user:

> "Note: /create-report skill not found. Install it to auto-generate an HTML report."

### Step 11: Post-run insights (GUIDELINES §7)

Generate 2–6 insights that would make the next run faster or more accurate (which directories
changed and why; which grep patterns found the project's patterns fastest; unexpected files or
naming inconsistencies; how many snippets were collected and which files were most useful).
Print them, then write the entry and call `prepend-runtime-note.sh`:

```bash
cat > /tmp/runtime-note-entry.md << 'ENTRY'
## project-index: [short summary] — [YYYY-MM-DD HH:MM]

**Purpose:** [one sentence]

**Insights:**

1. [point]
2. [point]
ENTRY

bash ~/.claude/skills/shared/prepend-runtime-note.sh "project-index" /tmp/runtime-note-entry.md
```

## Return contract (parent-facing)

This skill runs in a forked context, so the parent agent never sees the file reads — only what
you return. Return a short structured summary, not the index itself:

```
WROTE: <absolute path to project-index.md> (<line count>)
REPORT: <html report path, or "skipped — create-report unavailable">
STACK: <one line — framework / language / package manager / project type>
PATTERNS: <state · data · db · styling, one phrase each — the detected approaches>
CHANGES: <new/removed dirs + dependency deltas since last run, or "first run">
NOTES: <0–3 bullets — anomalies, debt, or things the parent should know>
```

The file on disk is the artifact; this summary is the pointer. Keep it under ~12 lines.

## Anti-patterns

- Listing a dependency as a "pattern in use" without confirming a source file imports it.
- Forcing a generic taxonomy onto the tree instead of describing the structure that's there.
- Dumping every export or every call site — the tables are lookup aids, not exhaustive logs.
- Returning the whole index to the parent instead of the structured summary above.

## Use cases

Onboarding (a fast overview of an unfamiliar codebase) · living documentation · architecture
reviews · refactor planning · dependency audits. Pair with `/arch-qa` to answer specific
questions about the indexed structure. Run periodically (e.g. weekly, or after a major
refactor) to keep the index current.

---

## Example (Versable stack)

A concrete run on the `enhancement-product` repo, kept as a reference for what a filled-in index
looks like. The body above is stack-agnostic; the patterns below are this one project's, not
defaults — verify every path against the tree before reusing.

**Detected stack:** Next.js 16 (App Router), React 19, TypeScript · Python FastAPI backend ·
Jotai (global atoms) + React Context (`createKeyedContext`) + TanStack Query (server state) ·
Drizzle ORM + PostgreSQL · NextAuth v4 + `@auth/drizzle-adapter` · Tailwind v3 + DaisyUI ·
Lexical editor · Stripe · AWS S3/SES, Sentry, ioredis · Playwright E2E.

**How Step 5's detection played out here:** the `jotai` dep was confirmed by reading an atom
file; `@tanstack/react-query` by the `useQ`/`useM` wrapper hooks; `drizzle-orm` by the
`src/db/schema/` definitions; styling by `tailwind.config` + DaisyUI classes in components.

**Discovered conventions:** `data/*.data.ts` (Server-Component data access) split from `db/`
(raw ORM); per-feature folders under `core/`; route groups `(home-v2)`/`(v2)`/`(debug)`;
versioned routes (`/v2/` current, `/v1/` legacy); a `/lab/*` sandbox; Node credit worker
(`credit-worker/`) plus Python `backend/worker/`; TanStack Query persisted to localStorage
(24h TTL, invalidated on hydration); `*.server.ts`/`*.client.ts` split; `gotchas.md` of known
pitfalls.

**Key exports table (this project):**

| Symbol               | File                                   | Description                                                        |
| -------------------- | -------------------------------------- | ------------------------------------------------------------------ |
| `useQ`               | `src/utils/hooks/use-q.ts`             | Shorthand `useQuery` wrapper — preferred over raw TanStack import  |
| `useM`               | `src/utils/hooks/use-m.ts`             | Shorthand `useMutation` wrapper with built-in toast feedback       |
| `useData`            | `src/utils/hooks/use-data.ts`          | Generic typed data fetch hook                                      |
| `useLoadingState`    | `src/utils/hooks/use-loading-state.ts` | 4-state loading machine (idle/pending/success/error)               |
| `useLocalStorage`    | `src/utils/hooks/use-storage.ts`       | Typed localStorage hook with `StorageKey` enum                     |
| `QueryKeys`          | `src/utils/react-query.ts`             | Typed factory for all TanStack Query cache keys                    |
| `getQueryClient`     | `src/utils/react-query.ts`             | Singleton accessor for the TanStack Query client                   |
| `Routes`             | `src/utils/routing.ts`                 | Enum of all app route path strings                                 |
| `QueryParams`        | `src/utils/url.ts`                     | Enum of URL search parameter name strings                          |
| `withServer`         | `src/utils/with-server.ts`             | Server-only module guard — throws if imported client-side          |
| `createKeyedContext` | `src/core/context/global-context.tsx`  | Generic typed React Context factory                                |
| `resolveGetter`      | `src/utils/iter.ts`                    | Polymorphic value resolver (value / function / function-with-args) |
| `listToMap`          | `src/utils/iter.ts`                    | Converts an array to a keyed Map                                   |
| `clamp`              | `src/utils/iter.ts`                    | Clamps a number within [a, b]                                      |
| `toggleArrayValue`   | `src/utils/iter.ts`                    | Immutably toggles a value in/out of an array                       |

**Snippet candidates that worked well here:** `src/app/layout.tsx` (root providers),
`src/db/schema/index.ts` (data model), `src/core/query/query-client-provider.tsx` (Query +
persistence), `src/core/context/global-context.tsx` (`createKeyedContext`), a `*.data.ts` (SC
data access), an atom file, a non-trivial hook from `src/utils/hooks/`, a `drizzle/` migration.
