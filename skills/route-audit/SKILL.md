---
name: route-audit
description: Scans all Next.js App Router route files for missing auth guards, missing input validation on mutation handlers, and non-standard response shapes — reports findings with file:line references, confidence, and severity. Project-specific: requires Next.js App Router.
allowed-tools: Read, Glob, Grep
user-invokable: true
argument-hint: "[path]"
context: fork
---

## Brief

Scans `src/app/**/route.ts` files (or a sub-path) for three correctness-and-security gaps in mutation and read handlers: whether each handler **guards auth**, whether mutation handlers **validate their input**, and whether handlers **shape their response consistently**. Reports every handler with a confidence and severity tag plus a file:line reference. Read-only — modifies nothing. Runs forked, so it returns structured plain text, not terminal panels.

# Route Audit

An API-route auditor for this Next.js App Router project. It judges each handler against three intents — guard auth, validate input, shape the response — rather than the presence of one specific function name, because the project's helpers evolve and an audit pinned to a literal string goes stale the moment someone renames the helper.

The audit reports findings; it does not fix them. A human (or `/skeptical-review`) takes the ranked list and decides what to change.

## Coverage-first reporting (read this before judging anything)

Report every handler you examine, including the ones that look fine and the ones you are unsure about. Do not raise the bar and drop low-severity or low-confidence findings during the scan — investigate fully, surface everything, and let the **severity + confidence ranking** push the minor items to the bottom. Dropping a finding because it "probably doesn't matter" hides exactly the gap a reviewer wants to see.

A handler that matches an auth helper still gets reported — as a PASS with the file:line of the guard — so the reader can confirm the guard is real and not, say, a dead import. Never silently pass: a PASS is a finding too, with its evidence.

## Step 0: Load shared guidelines and runtime context

Read `.claude/skills/GUIDELINES.md` and apply its rules — forbidden paths, retry logic, tool preferences, timeouts — for the whole run. Then read `.claude/skills/runtime-notes.md` for prior run history; continue without it if absent.

This skill is read-only: it acquires no locks and modifies no files.

## Usage

```
/route-audit [path]
```

| Argument | Type     | Description                                                                                        |
| -------- | -------- | -------------------------------------------------------------------------------------------------- |
| `path`   | optional | Sub-path to restrict the scan (e.g. `src/app/api/jobs/`). Defaults to all routes under `src/app/`. |

---

## Phase 1 — Discover route files

Find every route file:

```
Glob("src/app/api/**/route.ts")
Glob("src/app/**/route.ts")
```

Deduplicate the results. If a `path` argument was given, keep only files within it. If none remain, return `No route files found at <path>.` and stop.

Skip these from the audit (note them as INFO, don't flag them):

- `src/app/api/auth/[...nextauth]/route.ts` — NextAuth's own handler, manages its auth internally.
- Any file that only re-exports handlers (`export { GET, POST } from ...`) with no handler body of its own.

For each remaining file, find its exported HTTP handlers and their start lines:

```
Grep("^export (async )?function (GET|POST|PUT|PATCH|DELETE)", file)
```

Record which methods each file exports and the line each starts on.

---

## Phase 2 — Audit each handler

Read each route file in full, then judge each handler against three intent questions. Each question is about **what the handler does**, not which symbol it contains — so a guard implemented through a wrapper, a middleware helper, or an inline session read all count, and a renamed helper doesn't slip through.

For every handler, record: file, line, method, the verdict per check (PASS / WARN / ERROR / UNSURE), a one-line reason, a **confidence** (high / medium / low — how sure you are the verdict is right), and the **file:line of the evidence** that decided it.

### Check A — Does this mutation guard auth?

The question: before this handler does its work, does it establish who the caller is and that they're allowed?

Evidence that it does (any one): a session/identity read in the handler body or a helper it calls (the project's `getServerSession(authOptions)` is the common form, but a custom `requireUser()`, a middleware guard, or an equivalent counts equally); a `// Public route` comment marking a deliberate exception; the handler only re-exports.

- **PASS** — auth is established. Cite the file:line of the guard.
- **ERROR** — a POST / PUT / PATCH / DELETE handler with no auth guard and no `// Public route` marker. This mutates state for an unauthenticated caller; high severity.
- **WARN** — a GET handler with no guard and no `// Public route` marker. It may be intentionally public, but the intent isn't stated — flag it so someone marks it.
- **UNSURE** — auth seems to come from an indirection you couldn't fully trace (a wrapper whose body you didn't read, a middleware you can't see from here). Report it with low confidence and name what you couldn't resolve, rather than guessing PASS or ERROR.

### Check B — Does this mutation validate its input?

For POST / PUT / PATCH / DELETE handlers that read a request body.

The question: when this handler consumes caller-supplied input, does it validate the shape before trusting it?

Evidence that it does: a schema parse on the parsed body (the project uses Zod — `z.object(...)` / `.parse(...)` / `.safeParse(...)` — but any validation that runs before the body is used counts). A handler that never reads a body (no `request.json()`, uses query/path params only) has nothing to validate and passes trivially.

- **PASS** — body is validated, or there is no body to validate. Cite the evidence line.
- **WARN** — the handler reads `await request.json()` but no validation runs on the result before it's used. Medium severity: unvalidated input reaching business logic.
- **UNSURE** — validation might happen inside a helper you didn't trace. Low confidence, name the helper.

### Check C — Does this handler shape its response consistently?

The question: does every return path produce the project's standard HTTP response, or does some path return a bare value that bypasses it?

Evidence of a consistent shape: returns go through `NextResponse.json(...)` or `new Response(...)`. A path that returns a plain object (`return { ... }`) skips the framework's response handling.

- **PASS** — all return paths use a Response wrapper.
- **WARN** — at least one return path returns a bare object or value without a Response wrapper. Low severity; cite the line.

---

## Phase 3 — Return the report (structured plain text)

This skill runs under `context: fork`, so its output is read by the **parent agent**, not a terminal. Return plain structured text the parent can parse and relay. Do not source `gum-tui.sh` or emit terminal panels — their escape codes are noise to the parent.

Order findings by severity (ERROR, then WARN, then UNSURE, then PASS), and within a severity by confidence (high first). Emit every section that has entries; omit empty ones.

```
ROUTE AUDIT — <path or "src/app/**">
Files scanned: N | Handlers examined: N | Skipped (framework): N

ERRORS (auth gap on a mutation)
- src/app/api/payments/route.ts:8  DELETE  no auth guard before mutation  [confidence: high]  evidence: handler body :8-31, no session read
- src/app/api/jobs/route.ts:14     POST    no auth guard before mutation  [confidence: high]  evidence: handler body :14-40, no session read

WARNINGS
- src/app/api/jobs/route.ts:18     POST    reads request.json() but no validation runs on the body  [confidence: high]  evidence: :22 request.json(), no parse before use
- src/app/api/stats/route.ts:3     GET     public read with no // Public route marker  [confidence: medium]  evidence: :3-19, no guard, no marker
- src/app/api/jobs/route.ts:55     POST    one return path returns a bare object, bypassing the Response wrapper  [confidence: high]  evidence: :60 return { ok: true }

UNSURE (could not fully trace)
- src/app/api/admin/route.ts:12    PUT     auth may come from withAdmin() wrapper not read here  [confidence: low]  evidence: :12 export wrapped in withAdmin, body not in this file

PASS
- src/app/api/users/route.ts:9     POST    auth ✓ (:11 getServerSession)  validation ✓ (:15 z.object)  response ✓
- src/app/api/auth/[...nextauth]/route.ts  —  skipped (NextAuth framework route)

SUMMARY
Errors=N  Warnings=N  Unsure=N  Pass=N  Total handlers=N
```

If nothing was flagged, still return the PASS section and a one-line `All examined handlers pass the three checks.` — a clean run is a result, reported, not silence.

---

## Notes

- Read-only — never modifies any file.
- Runs under `context: fork` to keep the main conversation clean; returns parseable plain text, not terminal output.
- The checks are **intent heuristics with file:line evidence**, not literal string equality. A renamed auth helper or a guard reached through a wrapper still counts — and a stale string match never silently passes a handler that no longer guards anything.
- Mark a deliberately public route with `// Public route` to turn its WARN into an intentional PASS.
- `src/app/api/auth/[...nextauth]/route.ts` is always skipped.
- See `.claude/rules/api-routes.md` (if present) for the project's full route convention set.

## See Also

- `/skeptical-review` — hand it this ranked list to deep-dive the findings against the actual tree before acting; it grounds each suspected issue in surrounding code.
- `/arch-qa` — when a finding hinges on how auth or validation actually flows (a wrapper, a middleware chain you couldn't trace from the route file), trace the real path before calling it a gap.
- `rules/error-classification.md` — why these checks judge intent with evidence rather than matching a literal helper name.
