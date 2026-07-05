<!-- i-dream project brief · 2026-07-05T12:51:37.328470+00:00 · 20 patterns / 1 insights -->
## What this project is about
A frontend/fullstack widget system for Claude instances, with established conventions for environment helpers, boolean semantics, and strict shared-state discipline. Work style is iterative; scope is tightly user-controlled.

## Things to do (or keep doing)
- Always use project-defined constants (`isDevelopment`, `isProduction`, etc.) instead of inlining raw `process.env` comparisons — even in new files
- Treat terse continuations ("next", "done", "go") as authorizing **only** local, reversible work (file edits, scratch files, local builds)
- Read source code before asserting which layer is authoritative for any value (token validity, session state, identity)

## Things to avoid
- **Never commit or push without fresh, per-operation explicit approval** — prior blanket approval from anywhere in the session does not carry forward; this is the highest-severity recurring violation
- Don't inline `process.env.NODE_ENV === "development"` or equivalent raw checks when the codebase already defines a named boolean helper for it
- Don't mix frontend env var semantics (true/false strings) with backend semantics (1/0) across layers
- Don't re-introduce complexity or abstractions the user explicitly removed/deferred — if they deleted it, it stays deleted

## Open questions / known gaps
- Terse continuation signals reliably over-authorize shared-state mutations (commits, pushes); no in-session mechanical gate exists beyond this brief — treat every push as requiring a fresh verbal confirmation
