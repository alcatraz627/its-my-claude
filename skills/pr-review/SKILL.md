---
name: pr-review
description: Fetches a GitHub PR diff and reviews it against project conventions — auth checks, query patterns, cache invalidation, TypeScript strictness — outputting a structured review with file:line references.
allowed-tools: Read, Bash, Glob, Grep
user-invokable: true
argument-hint: "[pr-number]"
context: fork
disable-model-invocation: true
---

## Brief

Fetches a GitHub PR diff via `gh` and reviews it against this project's specific conventions, producing a structured code review with file:line references. Uses `context: fork` to keep the exploration isolated from the main conversation.

# PR Review

Reviews a GitHub pull request against this project's conventions and patterns. Unlike a generic code reviewer, this skill knows the project's specific patterns: `useQ`/`useM` hook conventions, TanStack Query cache invalidation requirements, NextAuth session handling, Drizzle ORM patterns, and TypeScript strictness expectations.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after.

## Usage

```
/pr-review [pr-number]
```

**Arguments:**
- `pr-number` (optional): GitHub PR number. If not provided, reviews the current branch's open PR.

---

## Phase 1 — Fetch PR Context

**If PR number provided:**
```bash
gh pr view <pr-number> --json title,body,author,baseRefName,headRefName
gh pr diff <pr-number>
```

**If no PR number:**
```bash
gh pr view --json title,body,author,baseRefName,headRefName
gh pr diff
```

Extract:
- PR title and description
- Files changed (count and names)
- Author
- Base branch

If `gh` is not available or no PR is open, print an error and stop.

---

## Phase 2 — Analyze the Diff

Parse the diff and categorize all changed files by type:

| Category | Patterns |
|---|---|
| API routes | `src/app/api/**/*.ts` |
| Server actions / data files | `src/data/**/*.ts`, `*.data.ts` |
| DB schema | `src/db/schema/**/*.ts` |
| React components | `*.tsx` |
| Custom hooks | `src/utils/hooks/**/*.ts` |
| Utility modules | `src/utils/**/*.ts` |
| Config files | `*.config.*`, `drizzle/` |

---

## Phase 3 — Apply Convention Checks

For each changed file, check the relevant conventions. Flag issues as `⚠ Warning` or `✗ Error`.

### Auth Protection (API routes and server actions)

- Every `route.ts` file that handles data mutations must include a session check
- Pattern to look for: `getServerSession(authOptions)`
- **Flag if missing:** `✗ No auth check found in [file] — add getServerSession() guard`

### TanStack Query Cache Invalidation (mutations)

- Every `useM` call that modifies data must invalidate relevant `QueryKeys` in `onSuccess`
- **Flag if missing:** `⚠ Mutation in [file] may be missing QueryKeys invalidation — stale data risk`

### Hook Usage Conventions

- Prefer `useQ` over raw `useQuery` calls
- Prefer `useM` over raw `useMutation` calls
- **Flag if raw hooks used:** `⚠ Use useQ/useM wrappers instead of raw TanStack hooks`

### TypeScript Strictness

- No `any` types without explicit justification comment
- No non-null assertions (`!`) on values that could legitimately be null
- **Flag:** `⚠ any type used at [file]:[line] — add proper type`

### Schema Changes

- If `src/db/schema/**` files are changed, check whether a migration file was also added
- **Flag if missing:** `✗ Schema changed but no new migration file found in drizzle/ — run npm run db:generate`

### Server/Client Boundary

- Check that `'use server'` files don't import from `'use client'` components
- Check that `*.data.ts` files don't appear in client component imports
- **Flag:** `✗ Server-only file imported in client context`

---

## Phase 4 — Output Structured Review

Source gum-tui.sh and render the review using panels:

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_header "PR Review: #<number> — <title>"
gum_info "Author: <author> | Base: <base> ← <head> | Files changed: N"

# Render only if errors exist:
gum_panel "ERRORS (must fix)" \
  "✗ src/app/api/jobs/route.ts:14 — no auth guard" \
  "✗ src/db/schema/users.ts:8 — schema changed, no migration"

# Render only if warnings exist:
gum_panel "WARNINGS (should fix)" \
  "⚠ src/data/jobs.data.ts:42 — mutation missing QueryKeys invalidation" \
  "⚠ src/utils/api.ts:7 — raw useQuery instead of useQ"

# Render only if passing checks exist:
gum_panel "LOOKS GOOD" \
  "✓ Auth checks present on all API routes" \
  "✓ QueryKeys invalidated in all mutations" \
  "✓ No any types introduced"

gum_complete "pr-review" \
  "PR=#<number> <title>" \
  "Errors=N (must fix)" \
  "Warnings=N (should fix)" \
  "Summary=[1-3 sentence overall assessment]"
```

If no issues found: call `gum_success "No convention violations found. Looks good to merge."`

---

## Notes

- This skill is read-only — it never modifies any files.
- Uses `context: fork` to run in an isolated subagent, keeping the main context clean.
- Uses `disable-model-invocation: true` — must be explicitly invoked, never auto-triggered.
- For large PRs (50+ files), focus on the categories listed in Phase 2 and note that a full review was not possible.
- Requires `gh` CLI to be installed and authenticated.
