---
name: pr-review
description: Fetches a GitHub PR diff and reviews it against project conventions — auth checks, query patterns, cache invalidation, TypeScript strictness — returning a coverage-first finding list (every finding, tagged confidence + severity) with file:line references.
allowed-tools: Read, Bash, Glob, Grep
user-invokable: true
argument-hint: "[pr-number]"
context: fork
disable-model-invocation: true
---

## Brief

Fetches a GitHub PR diff via `gh` and reviews it against this project's conventions, returning a structured finding list with file:line references. Runs under `context: fork`, so the parent agent parses your return — emit a plain-text finding contract, not terminal-rendered output.

# PR Review

Reviews a GitHub pull request against this project's patterns: `useQ`/`useM` hook conventions, TanStack Query cache invalidation, NextAuth session handling, Drizzle ORM patterns, and TypeScript strictness. The conventions below are heuristics, not a closed checklist — a real codebase mixes patterns, and the goal is to surface anything that diverges with the evidence to verify it, not to match six exact strings.

## Step 0 — Load shared guidelines and runtime context

Read `.claude/skills/GUIDELINES.md` first and apply its rules — forbidden paths, retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file-lock protocol — for the whole run.

Read `.claude/skills/runtime-notes.md` for past run history relevant to this skill. If it doesn't exist, continue without it.

This skill is read-only — it never edits files, so no lock is needed. Investigate the tree; report findings; the human (or a downstream skill) acts.

## Usage

```
/pr-review [pr-number]
```

- `pr-number` (optional): GitHub PR number. Omit it to review the current branch's open PR.

---

## Phase 1 — Fetch PR context

With a PR number:
```bash
gh pr view <pr-number> --json title,body,author,baseRefName,headRefName
gh pr diff <pr-number>
```

Without one (reviews the current branch's PR):
```bash
gh pr view --json title,body,author,baseRefName,headRefName
gh pr diff
```

Extract the title, description, changed-file list (count + names), author, and base branch. If `gh` is unavailable or no PR is open, print the error and stop.

---

## Phase 2 — Map the diff to convention surfaces

Categorize each changed file. The patterns are a routing guide, not a gate — a file that doesn't match a row still gets read if the diff touches behavior.

| Category | Typical paths |
|---|---|
| API routes | `src/app/api/**/*.ts` |
| Server actions / data files | `src/data/**/*.ts`, `*.data.ts` |
| DB schema | `src/db/schema/**/*.ts` |
| React components | `*.tsx` |
| Custom hooks | `src/utils/hooks/**/*.ts` |
| Utility modules | `src/utils/**/*.ts` |
| Config | `*.config.*`, `drizzle/` |

For large PRs (50+ files), prioritize the API-route, data, and schema categories first, and note in the summary that coverage was partial.

---

## Phase 3 — Investigate against the conventions

Read each changed file and reason through the heuristics below. Each is a signal to look for, grounded in a file:line — not a literal string-match. When a convention seems violated, confirm by reading the surrounding code (the import, the wrapper, the sibling handler) before you record it; a name that *looks* like a raw hook may be a project wrapper of the same name.

**Auth protection** — data-mutating route handlers and server actions should establish a session before touching data. The common signal is a `getServerSession(authOptions)` call near the top, but a route may delegate auth to a shared guard or middleware — read for that before flagging. Missing session establishment on a mutation path is high severity.

**Cache invalidation** — a `useM` mutation that changes server data should invalidate the affected `QueryKeys` in `onSuccess`, or the UI shows stale data. Check whether invalidation happens there, in a shared mutation wrapper, or via a manual refetch.

**Hook conventions** — the project wraps TanStack's `useQuery`/`useMutation` as `useQ`/`useM`. A raw `useQuery`/`useMutation` at a callsite is a signal to check why the wrapper was bypassed — sometimes deliberate, usually drift.

**TypeScript strictness** — `any` (explicit or implicit) and non-null assertions (`!`) on values that can legitimately be null erode type safety. Flag each with its file:line; note when a justification comment is present.

**Schema + migration** — a change under `src/db/schema/**` should be accompanied by a generated migration in `drizzle/`. A schema diff with no migration is a deploy hazard (`npm run db:generate` was likely skipped).

**Server/client boundary** — a `'use server'` file or a `*.data.ts` module reaching a client component (or vice versa) crosses the boundary. Trace the import to confirm the direction before flagging.

These six are the known surfaces for this project. If the diff reveals a divergence outside them that you can ground in a file:line, report it too — coverage is not limited to the list.

---

## Phase 4 — Return the findings (coverage-first)

Report every finding you surface, including low-severity and uncertain ones. Do not drop a finding because it feels minor or you're not fully sure — coverage is the job here, not bar-raising. A separate ranking culls; investigation never does. The way to keep the output focused is to *rank* (low-severity and low-confidence sink to the bottom), not to omit.

Tag each finding with a confidence and a severity so the parent can rank and act:

- **confidence** — `high` (read the code, certain) · `med` (likely, one assumption unverified) · `low` (worth a look, couldn't fully confirm)
- **severity** — `high` (correctness/security/data — auth gap, missing migration) · `med` (stale-data risk, boundary crossing) · `low` (style/strictness nit)

Return plain text the parent agent parses — no gum panels, no TTY rendering (this runs forked; rendered output is for terminals, not for a parent to read). Emit one finding per line in this contract, sorted highest combined severity+confidence first:

```
PR #<number> — <title>
Author: <author> | Base: <base> ← <head> | Files: <N>

FINDINGS (<count>):
high | high | src/app/api/jobs/route.ts:14 | mutation handler has no session established before the write | grep the handler for getServerSession / a shared auth guard; confirm none gates the mutation
high | high | src/db/schema/users.ts:8 | schema column added with no matching migration in drizzle/ | ls drizzle/ for a migration newer than this change; run npm run db:generate if absent
med  | high | src/data/jobs.data.ts:42 | useM mutation does not invalidate QueryKeys in onSuccess | check onSuccess and any shared wrapper for an invalidate call on the jobs key
low  | med  | src/utils/api.ts:7 | raw useQuery instead of the useQ wrapper | confirm the wrapper was bypassed deliberately, not by drift
low  | high | src/utils/parse.ts:31 | any type with no justification comment | replace with the concrete type or add a comment explaining the any

CLEAN:
- auth guards present on the other API routes touched
- no server/client boundary crossings found

SUMMARY: <1–3 sentences — overall assessment, highest-severity finding, merge-readiness>
```

Each finding line is `confidence | severity | file:line | issue | how to verify`. The "how to verify" column is mandatory — it's the runnable check the parent (or human) uses to confirm or dismiss the finding, per exercise-based-verification.

If you found nothing, return the header, an empty `FINDINGS (0):` block, the `CLEAN:` list, and a summary saying no convention divergences were found.

---

## Notes

- Read-only — never modifies files.
- `context: fork` keeps the exploration out of the main conversation; the parent reads only your structured return.
- `disable-model-invocation: true` — invoke explicitly; never auto-triggered.
- Requires `gh` installed and authenticated.

## See Also

- `/skeptical-review` — broader adversarial review grounded in the full tree, for changes beyond these six conventions.
- `/arch-qa` — trace a code path to ground a structural claim (who calls this, what's the real auth flow) before asserting it; pairs with `rules/structural-claim-without-reading-code.md`.
- `rules/exercise-based-verification.md` — every finding ships with a runnable check; a claim isn't confirmed until that path is run.
- `/atone` — if the same convention violation recurs across PRs, record it so the pattern graduates to a rule or a hook.
