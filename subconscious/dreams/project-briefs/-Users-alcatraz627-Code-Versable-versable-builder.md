<!-- i-dream project brief · 2026-07-13T00:42:20.375780+00:00 · 20 patterns / 0 insights -->
## What this project is about
A professional web application builder (likely SaaS/B2B) with customer-facing documents and complex UI state. Work style is iterative with heavy emphasis on runtime verification and document quality.

## Things to do (or keep doing)
- Always navigate to the actual URL and exercise the primary flow before claiming a UI or server-side change works — inspection is not verification
- Sequence all edits to the same file; parallel Edit calls silently clobber each other
- Check recent git log before introducing any new mechanism to store/retrieve IDs or config — the pattern may already exist
- After any mutation/write, explicitly verify client-side caches for the affected data are invalidated

## Things to avoid
- Don't start expensive multi-agent review (magi/debate) until all prerequisite research, docs, and user Q&A is complete — early consensus over incomplete material wastes tokens and misleads
- Don't suggest version changes (upgrades, reverts) without scanning git history for deliberate version decisions first
- Don't produce AI-register prose in customer-facing docs — strip openers like "Good news first:", reflexive apologies, leading-question closers, and "The User" capitalizations
- Don't replicate surrounding code patterns without verifying they apply in the new location — IIFE wrappers, flag-gated lazy imports, and JSX scope-wrappers are context-specific, not defaults

## Open questions / known gaps
- "Runtime variables" vs "deploy-time env vars" is a recurring ambiguity — always clarify before implementing
- UI reskins need end-to-end UX validation (scroll, backgrounds, responsive, navigation) not just mechanical style application; this has shipped incomplete before
