---
name: invalidate-audit
description: Scans all useM and useMutation calls in src/ and reports any missing QueryKeys invalidation in their onSuccess callback — catching stale-data risks with file:line references. Project-specific: requires TanStack Query with useM/useMutation pattern.
allowed-tools: Read, Glob, Grep
user-invokable: true
argument-hint: "[path]"
context: fork
---

## Brief

Finds every `useM(` and `useMutation(` call in the codebase and checks whether its `onSuccess` (or `onSettled`) callback includes a `queryClient.invalidateQueries` call. Reports mutations with missing cache invalidation — the most common source of stale UI data. Read-only, never modifies files.

# Invalidate Audit

Prevents stale UI data by catching missing TanStack Query cache invalidation at development time. Scans all mutation hooks in the codebase and reports any that mutate data without subsequently invalidating the relevant query cache key.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> This skill is read-only — it acquires no locks and modifies no files.

## Usage

```
/invalidate-audit [path]
```

| Argument | Type     | Description                                                                      |
| -------- | -------- | -------------------------------------------------------------------------------- |
| `path`   | optional | Sub-path to restrict the scan (e.g. `src/app/jobs/`). Defaults to all of `src/`. |

---

## Phase 1 — Find All Mutation Hooks

### 1.1 — Grep for mutation calls

Scan `src/` (or `path` if provided) for mutation hook usage:

```
Grep("useM\(", glob="src/**/*.{ts,tsx}", output_mode="files_with_matches")
Grep("useMutation\(", glob="src/**/*.{ts,tsx}", output_mode="files_with_matches")
```

Deduplicate the file lists. Print:

```
  Found N files containing mutation hooks.
```

### 1.2 — Locate each call within its file

For each file found, run:

```
Grep("useM\(|useMutation\(", file, output_mode="content", -n=true)
```

Record every line number where a mutation hook call starts.

---

## Phase 2 — Check for Cache Invalidation

For each mutation call found:

### 2.1 — Read surrounding context

Read the file from the mutation's start line through approximately 50 lines later. This window captures the full mutation configuration object including `onSuccess`, `onError`, `onSettled`, and `mutationFn`.

### 2.2 — Classify the mutation

| Finding                                                               | Classification                                       |
| --------------------------------------------------------------------- | ---------------------------------------------------- |
| `// no-invalidate` comment inside the mutation                        | **SKIP** — intentionally suppressed                  |
| `onSuccess` or `onSettled` with `invalidateQueries` or `resetQueries` | **PASS** — cache properly invalidated                |
| `onSettled` with `invalidateQueries` (instead of `onSuccess`)         | **PASS** — acceptable pattern                        |
| `onSuccess` present, no `invalidateQueries` or `resetQueries`         | **WARNING** — stale data risk                        |
| No `onSuccess` or `onSettled` callback at all                         | **WARNING** — mutations should invalidate on success |

### 2.3 — Extract mutation identifier for the report

Try to identify the mutation by:

- The `mutationFn` value (e.g., `async (data) => api.createJob(data)` → `createJob`)
- The variable name the hook is assigned to (`const { mutate } = useM(...)`)
- Fall back to `file:line` if no name is extractable

---

## Phase 3 — Output Report

Source gum-tui.sh and render using panels. Render only sections that have data:

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_header "Invalidate Audit: <path or 'src/'>"
gum_info "Mutations scanned: N"

# Render only if warnings exist:
gum_panel "WARNINGS (stale data risk)" \
  "⚠ src/app/jobs/components/job-form.tsx:42" \
  "  Mutation: createJob — onSuccess present but no invalidateQueries" \
  "" \
  "⚠ src/app/users/hooks/use-update-user.ts:18" \
  "  Mutation: updateUser — no onSuccess callback"

# Render only if suppressed mutations exist:
gum_panel "SUPPRESSED (// no-invalidate)" \
  "ℹ src/app/analytics/use-track-event.ts:7" \
  "  Mutation: trackEvent — intentionally fire-and-forget"

# Render only if clean mutations exist:
gum_panel "CLEAN" \
  "✓ src/app/jobs/hooks/use-create-job.ts:11   — invalidateQueries(QueryKeys.jobs)" \
  "✓ src/app/users/hooks/use-delete-user.ts:8  — invalidateQueries(QueryKeys.users)"

gum_complete "invalidate-audit" \
  "Warnings=N (missing invalidation)" \
  "Suppressed=N (// no-invalidate)" \
  "Clean=N" \
  "Total=N mutations scanned"
```

If all mutations are clean: call `gum_success "All mutations have proper cache invalidation."`

---

## Notes

- Read-only — never modifies any files.
- Uses `context: fork` — runs in isolated context.
- Add `// no-invalidate` comment inside a `useM()` or `useMutation()` call to suppress the warning for fire-and-forget mutations (e.g., analytics pings, logging calls, one-way notifications).
- `useM` is the project-preferred wrapper over raw `useMutation`. Raw `useMutation` calls are also scanned — flag them as a secondary concern.
- `onSettled` with `invalidateQueries` is treated as equivalent to `onSuccess` — both invalidate the cache on completion.
