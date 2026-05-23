---
name: route-audit
description: Scans all Next.js App Router route files for missing auth guards, missing Zod input validation on mutation handlers, and non-standard response shapes — reports findings with file:line references. Project-specific: requires Next.js App Router.
allowed-tools: Read, Glob, Grep
user-invokable: true
argument-hint: "[path]"
context: fork
---

## Brief

Scans all `src/app/**/route.ts` files (or a sub-path) for three security and correctness gaps: missing `getServerSession` auth guards, missing Zod validation on POST/PUT/PATCH/DELETE handlers, and non-standard response shapes. Produces a structured report with file:line references grouped by severity. Read-only — never modifies files.

# Route Audit

An autonomous API security auditor for this Next.js App Router project. Knows the project's specific conventions — NextAuth session guards, Zod validation patterns, `NextResponse.json()` response shapes — and produces a structured findings report without modifying any files.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> This skill is read-only — it acquires no locks and modifies no files.

## Usage

```
/route-audit [path]
```

| Argument | Type     | Description                                                                                        |
| -------- | -------- | -------------------------------------------------------------------------------------------------- |
| `path`   | optional | Sub-path to restrict the scan (e.g. `src/app/api/jobs/`). Defaults to all routes under `src/app/`. |

---

## Phase 1 — Discover Route Files

### 1.1 — Find all route files

```
Glob("src/app/api/**/route.ts")
Glob("src/app/**/route.ts")
```

Deduplicate. If a `path` argument was provided, filter to only files within that path.

Print:

```
  Discovered N route files.
```

If zero: print `"No route files found at <path>."` and stop.

### 1.2 — Skip well-known framework routes

Automatically exclude from audit (print as INFO, not flagged):

- `src/app/api/auth/[...nextauth]/route.ts` — NextAuth handler, manages its own auth
- Any file that only contains `export { GET, POST } from` re-exports (no handler logic)

Print: `  Skipping N framework route(s).`

### 1.3 — Identify HTTP method handlers

For each remaining route file, use Grep to identify exported HTTP handlers:

```
Grep("^export (async )?function (GET|POST|PUT|PATCH|DELETE)", file)
```

Record: which methods are present, starting line number of each.

---

## Phase 2 — Audit Each Route File

Read each file in full. Apply three checks per file.

### Check A — Auth guard

For each handler function (GET, POST, PUT, PATCH, DELETE):

**Pass if any of:**

- `getServerSession(authOptions)` found in the handler body or a called helper function
- `// Public route` comment at the top of the file or above the handler
- Handler only re-exports from another module (no logic)

**Flag ERROR if:**

- Handler is POST / PUT / PATCH / DELETE AND no session check AND no `// Public route` comment

**Flag WARNING if:**

- Handler is GET AND no session check AND no `// Public route` comment (may be intentionally public but should be explicitly marked)

### Check B — Input validation

For POST / PUT / PATCH / DELETE handlers only:

**Pass if any of:**

- `z.object(` or any `z.` Zod usage found in the file
- Handler does not call `request.json()` (uses query params or no body)

**Flag WARNING if:**

- Handler calls `await request.json()` but no Zod pattern found anywhere in the file

### Check C — Response shape

**Pass if:**

- All return statements use `NextResponse.json(` or `new Response(`

**Flag WARNING if:**

- A return statement returns a plain object `return { ... }` without `NextResponse.json()` wrapping

---

## Phase 3 — Output Report

Source gum-tui.sh and render using panels. Render only sections that have data:

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_header "Route Audit: <path or 'src/app/**'>"
gum_info "Files scanned: N | Handlers found: N"

# Render only if errors exist:
gum_panel "ERRORS (must fix)" \
  "✗ src/app/api/jobs/route.ts:14    POST — no auth guard" \
  "✗ src/app/api/payments/route.ts:8 DELETE — no auth guard"

# Render only if warnings exist:
gum_panel "WARNINGS (should fix)" \
  "⚠ src/app/api/stats/route.ts:3   GET — no auth or // Public route comment" \
  "⚠ src/app/api/jobs/route.ts:18   POST — request.json() without Zod validation"

# Render only if clean files exist:
gum_panel "LOOKS GOOD" \
  "✓ src/app/api/users/route.ts       — auth ✓  validation ✓  response ✓" \
  "✓ src/app/api/auth/[...nextauth]/  — skipped (NextAuth framework route)"

gum_complete "route-audit" \
  "Errors=N (auth gaps)" \
  "Warnings=N" \
  "Clean=N" \
  "Total scanned=N"
```

If zero errors and zero warnings: call `gum_success "All route files pass — no convention violations found."`

---

## Notes

- Read-only — never modifies any files.
- Uses `context: fork` — runs in isolated context, keeping main conversation clean.
- Pairs with `pr-review` which checks these same patterns in PR diffs.
- Mark intentionally public routes with `// Public route` comment to suppress auth warnings.
- `src/app/api/auth/[...nextauth]/route.ts` is always skipped.
- See `.claude/rules/api-routes.md` (if it exists) for the full convention set this skill enforces.
