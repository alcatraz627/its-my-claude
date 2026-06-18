---
name: type-audit
description: Scans the TypeScript codebase for unsafe type patterns — explicit `any`, implicit `any`, non-null assertions (`!`), and unsafe casts — reports them with file:line references, and offers targeted fixes.
allowed-tools: Read, Bash, Glob, Grep, Edit
user-invokable: true
argument-hint: "[--fix] [path]"
---

## Brief

Scans the TypeScript codebase (or a sub-path) for unsafe type patterns: explicit `any`, implicit `any` (missing return/parameter types), non-null assertions (`!`), and unsafe casts (`as unknown as`). Reports all findings with file:line references grouped by severity, then offers to apply targeted fixes for straightforward cases.

# Type Audit

A TypeScript safety audit skill that finds and optionally fixes common unsafe type patterns in this Next.js + Drizzle + TanStack Query codebase. Knows which patterns are acceptable (e.g., `as const`, framework-required `any` in dynamic route params) versus genuinely risky.

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
/type-audit [--fix] [path]
```

**Arguments:**
- `--fix` (optional): After reporting, attempt to auto-fix straightforward issues (explicit `any` with inferable types, missing obvious return types). Requires user confirmation per file.
- `path` (optional): Restrict scan to this path (e.g. `src/app/jobs/`, `src/utils/`). Defaults to entire `src/`.

---

## Phase 1 — Parse Arguments and Plan the Scan

Extract from the invocation:
- `--fix` flag → set `FIX_MODE=true`
- Remaining token → set `SCAN_PATH` (default: `src/`)

Print:
```
  Scanning: <SCAN_PATH>
  Fix mode: yes / no
```

---

## Phase 2 — Run TypeScript Compiler Checks

Run the TypeScript compiler in no-emit mode to collect implicit-any and other type errors:

```bash
npx tsc --noEmit --strict 2>&1 | head -200
```

This surfaces:
- Implicit `any` on parameters (TS7006)
- Missing return types caught by strict mode
- Type assignment errors masked by `any`

Store output for Phase 4 analysis.

---

## Phase 3 — Pattern Grep Scan

Run targeted searches across `SCAN_PATH`:

**3.1 — Explicit `any`:**
```bash
rg -n ": any" src/ -g "*.ts" -g "*.tsx" | rg -v "// any-ok"
rg -n "as any" src/ -g "*.ts" -g "*.tsx" | rg -v "// any-ok"
```

**3.2 — Non-null assertions:**
```bash
rg -n "[^!]![^=]" src/ -g "*.ts" -g "*.tsx" | rg -v "// nonnull-ok"
```

**3.3 — Unsafe double casts:**
```bash
rg -n "as unknown as" src/ -g "*.ts" -g "*.tsx"
```

**3.4 — `@ts-ignore` and `@ts-nocheck`:**
```bash
rg -n "@ts-ignore|@ts-nocheck" src/ -g "*.ts" -g "*.tsx"
```

---

## Phase 4 — Classify Findings

For each finding, classify as:

| Severity | Pattern | Rationale |
|---|---|---|
| `error` | `as any` without comment | Bypasses type safety; unsafe |
| `error` | `@ts-ignore` without comment | Silences errors; should be fixed |
| `warning` | `: any` on function params | Often inferable; should be typed |
| `warning` | `!` on values that could be null | Risk of runtime crash |
| `warning` | `as unknown as X` | Double cast defeats type system |
| `info` | `@ts-ignore // reason` | Documented suppression; acceptable if reason is clear |
| `info` | `as const` | Safe pattern; skip |

**Acceptable patterns (do NOT flag):**
- `params: { [key: string]: string }` — Next.js App Router dynamic route params
- `// eslint-disable-next-line @typescript-eslint/no-explicit-any` with an explanatory comment
- Test files (`*.test.ts`, `*.spec.ts`) — flag as `info` only

---

## Phase 5 — Report

Source gum-tui.sh and render findings grouped by severity. Render only sections that have data:

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_header "Type Audit: <SCAN_PATH>"

# Render only if errors exist:
gum_panel "ERRORS (must fix)" \
  "✗ src/utils/api.ts:42      — \`as any\` cast with no comment" \
  "✗ src/app/jobs/route.ts:18 — @ts-ignore with no explanation"

# Render only if warnings exist:
gum_panel "WARNINGS (should fix)" \
  "⚠ src/data/jobs.data.ts:71  — non-null assertion on query result" \
  "⚠ src/utils/hooks/useQ.ts:9 — param typed as \`any\` — consider generic"

# Render only if info items exist:
gum_panel "INFO (review if needed)" \
  "ℹ src/app/jobs/[id]/page.tsx:5 — Next.js params pattern (ok)"

gum_complete "type-audit" \
  "Errors=N" \
  "Warnings=N" \
  "Info=N" \
  "Files scanned=N"
```

If zero errors and zero warnings: call `gum_success "No unsafe type patterns found in <SCAN_PATH>."`

---

## Phase 6 — Fix Mode (if --fix)

If `FIX_MODE=true` and there are errors or warnings:

```
Apply fixes? (yes / select / no)
  yes    — attempt all auto-fixable issues
  select — list fixable issues and let you choose
  no     — exit without changes
→
```

Wait for input.

**Auto-fixable patterns:**
- `as any` where the type is obvious from context → replace with the actual type
- `!` on a `.find()` result → replace with `?? defaultValue` or add a null guard
- Missing explicit return type on a simple function → infer and add

**Non-auto-fixable (report only):**
- `@ts-ignore` suppressions — require developer judgment
- Complex double casts — require understanding of intent

For each fix:
1. Acquire lock: `bash ~/.claude/skills/shared/lock-file.sh acquire "<file>" "type-audit"`
2. Read the file
3. Apply the Edit
4. Release lock
5. Print: `  ✓ Fixed: <file>:<line> — <description of change>`

After all fixes:

```
  Re-run tsc to verify fixes resolved the errors? (yes / no)
```

If yes: re-run `npx tsc --noEmit 2>&1 | head -100` and show diff in error count.

---

## Notes

- Never modifies `.d.ts` files or files in `node_modules/`.
- Use `// any-ok` or `// nonnull-ok` comments to permanently suppress specific findings — the rg patterns exclude these.
- Drizzle query results (`.findFirst()`, `.findMany()`) returning `undefined` are the most common source of `!` assertions — prefer null guards or explicit `?? throw new Error(...)`.
- For TanStack Query hooks, `useQ` and `useM` wrappers already handle the common `data` being possibly undefined pattern — flag raw `useQuery` calls that use `!` on `data`.
