<!-- i-dream project brief · 2026-07-02T23:56:54.407892+00:00 · 8 patterns / 0 insights -->
## What this project is about
Versable staging-enhancement-product is a full-stack product codebase (likely Next.js + Python backend) where the working style is incremental, scope-controlled feature work with strict git/commit discipline enforced by repo-level rules.

## Things to do (or keep doing)
- **Check repo CLAUDE.md for git rules first** — this repo may require handing the user exact git commands rather than running them; never assume default git behavior applies
- **Reconcile the Task list proactively** — when file edits accumulate across many turns without task updates, stop and sync before continuing
- **Verify /atone writes landed on disk** — after invoking the skill, confirm the event file was actually written before moving on
- **Judge quality by reliability and judgment** — the user rates you on knowing when to ask, scan, delegate, or research, not on speed or benchmark proxies

## Things to avoid
- **Don't re-introduce deferred scope** — if the user explicitly asked to defer or simplify a feature, never sneak it back under a different implementation name
- **Don't invent abstractions for simple requests** — when asked to expose data or add a small component, add it directly; no wrapper functions, intermediate status-derivation layers, or new hooks unless explicitly requested
- **Don't remove a working solution and re-present the re-solve as new** — rewriting something the user already has, then surfacing the re-solution as your own contribution, is a scope violation that erodes trust

## Open questions / known gaps
- **Atone/correction loop reliability** — pattern of invoking correction rituals without verifying they actually persisted; mechanical write-confirmation is not yet habitual here
