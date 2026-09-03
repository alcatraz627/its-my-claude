<!-- i-dream project brief · 2026-09-02T05:48:48.118640+00:00 · 20 patterns / 1 insights -->
## What this project is about
A multi-page web application (likely React/Next.js) with list views, drawers/sidebars, and a sub-agent research workflow. Work style is iterative with frequent session handoffs and checkpoint-driven continuity.

## Things to do (or keep doing)
- **Audit every sibling before adding anything** — before writing a component, list page, JSX pattern, or filter: enumerate peers, match their pattern exactly, or state in one sentence why this case differs
- **Read existing research artifacts before dispatching new sub-agents** — if prior output exists for an overlapping question, incorporate it first
- **Stop idle sub-agents immediately** after verifying their output; a running seat gets commandeered
- **Exercise the changed code path before claiming done** — the declared-ready gate fires on inspect-only passes; run it, read the result, then report

## Things to avoid
- **Don't present deferred decisions without context** — each item needs the exact prior ruling plus concrete selectable options, or the user has to reconstruct what they already decided
- **Don't treat checkpoint directives as ground truth** — the codebase changes between sessions; verify current state before acting on a prior session's directive
- **Don't verify UI in only one theme** — dark-only sign-offs that ship a broken light theme are a recurring S3; scope claims to what was actually exercised
- **Don't infer synthesis target from agent findings** — confirm which project/domain a synthesis is for before writing; a mismatch produces confident wrong output

## Open questions / known gaps
- Checkpoint staleness is a recurring tension: directives written in session N are acted on in session N+1 against a changed codebase; no established protocol for marking directives as verified-vs-stale
- Decision presentation format remains inconsistent — deferred items sometimes arrive without prior ruling context, forcing re-derivation of already-settled calls
