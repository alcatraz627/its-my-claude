<!-- i-dream project brief · 2026-07-13T00:42:03.311497+00:00 · 15 patterns / 0 insights -->
## What this project is about
Frontend web application development (React/JSX), with recurring focus on UI component behavior, cache consistency, and tooling correctness. Working style is iterative with strong UX and code-style enforcement signals.

## Things to do (or keep doing)
- **Picker/selector UIs**: selection must preview only — require an explicit save/apply action before state commits; never auto-apply on selection change
- **After any mutation or write op**: explicitly verify client-side caches holding affected data are invalidated — staleness after writes is a recurring bug class
- **Separate detection from application**: deterministic regex/heuristic detection belongs in its own pass; context-dependent judgment runs after, not mixed in
- **Before building a new hook or nudge**: read existing scripts serving similar concerns — prior design decisions and removal history directly constrain what to build

## Things to avoid
- **Don't copy surrounding code patterns without verifying they apply**: flag-gated lazy imports, IIFE wrappers, and similar idioms exist for specific reasons; replicating them blindly in new locations is a recurring smell
- **Don't use IIFE wrappers in JSX** where sibling elements use inline props or plain `const` declarations — conform to the established style already present
- **Don't anchor log filters to broad keywords** — overly wide patterns match irrelevant payload content; use structural log-type identifiers
- **Don't call a UI reskin done without E2E UX validation** — scroll behavior, background colors across states, responsive layout, and navigation flow all require explicit verification

## Open questions / known gaps
- Formatters (Prettier etc.) can silently restructure logic-sensitive files during edits — no consistent post-edit inspection discipline established yet
- Auth/authz abstraction boundary is unresolved: wrapper functions that appear to "handle auth" have historically masked unprotected callsites; explicit per-callsite checks are preferred but not uniformly enforced
