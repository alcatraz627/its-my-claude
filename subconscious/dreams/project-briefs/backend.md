<!-- i-dream project brief · 2026-07-13T00:42:45.489207+00:00 · 15 patterns / 0 insights -->
## What this project is about
Full-stack web application (JSX frontend, backend services) with active tooling/script development. Work spans UI interactions, cache management, GitHub integrations, and agent-driven shell operations.

## Things to do (or keep doing)
- **Split detection from application**: implement deterministic regex/heuristic detection separately from context-dependent agent judgment — produces more reliable and auditable tools
- **Anchor log filters to structural identifiers**: use log-type fields, not broad keyword patterns that match payload content in unrelated lines
- **Read existing scripts before building new hooks**: prior design decisions and removal history directly constrain what's appropriate
- **Make auth checks explicit at each callsite**: never abstract into a named wrapper that appears to "handle auth" — wrapper opacity is a security gap

## Things to avoid
- **Don't auto-apply on selection**: picker/selector UIs must preview only; require explicit save/apply before state changes take effect
- **Don't skip cache invalidation after writes**: after any mutation, explicitly verify client-side caches holding affected data are invalidated
- **Don't replicate surrounding code patterns without verifying applicability**: flag-gated lazy imports, IIFE wrappers, etc. exist for specific reasons that may not apply at the new callsite
- **Don't trust formatter output as semantically inert**: after edits to formatting-sensitive files, inspect the diff — Prettier/Black can silently restructure logic

## Open questions / known gaps
- UI reskin/restyle work consistently ships without full cross-state validation (scroll, backgrounds, responsive, nav flow) — no lightweight checklist or smoke-test ritual has been established yet
