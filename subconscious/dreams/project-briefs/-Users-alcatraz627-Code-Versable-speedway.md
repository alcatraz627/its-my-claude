<!-- i-dream project brief · 2026-09-02T05:43:58.520819+00:00 · 20 patterns / 2 insights -->
## What this project is about

A Next.js/TypeScript frontend project (Versable Speedway) with multi-agent orchestration work. Dominant style: high-autonomy sequential execution with structured fan-out research and CSS/UI work.

## Things to do (or keep doing)

- **Execute sequential steps autonomously** without checkpoint confirmations between them; pause only on genuine decision points (scope forks, authorizations, irreversible ops).
- **TaskStop idle sub-agents immediately** after verifying their output file exists on disk — an idle seat gets commandeered by board auto-dispatchers.
- **Re-read prior sub-agent outputs from disk** before dispatching duplicate research; check `~/.claude/output/` for the session's existing findings first.
- **Re-ground synthesis against the human-authored source doc**, never against a downstream agent-generated doc or sibling-project findings.

## Things to avoid

- **Don't claim work complete without running the changed code path** — the declared-ready gate will fire; exercise the path before saying done.
- **Don't silently pick a branch after an either/or question** when the user responds with a bare affirmative — re-state what you're about to do once, then proceed.
- **Don't mix planned/done/in-progress work in a single prose status** — separate them as three flat lists.
- **Don't declare a CSS empty custom property as a default** (`--x: ;` is not a fallback; omit the declaration entirely). Also: `inherits: false` on a registered property makes it invisible to pseudo-elements.

## Open questions / known gaps

- Autonomy policy is two-axis: high on reversible sequential steps, strict confirmation on identity/scope/projection decisions — the line between the two still misfires under multi-agent conditions.
- `node_modules/.cache` must be cleared explicitly for a fully clean dev state; `.next/cache` alone is insufficient.
