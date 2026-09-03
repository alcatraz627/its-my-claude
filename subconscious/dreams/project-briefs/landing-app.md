<!-- i-dream project brief · 2026-09-02T05:47:53.008883+00:00 · 20 patterns / 2 insights -->
## What this project is about
A Next.js landing application with CSS animation/theming work and multi-agent research workflows. Dominant pattern: high-autonomy sequential execution with strict correctness gates on CSS, env, and agent output provenance.

## Things to do (or keep doing)
- Proceed autonomously through reversible sequential steps without checkpoint confirmations; reserve user turns for genuine scope forks or irreversible decisions only.
- Stop (TaskStop) every sub-agent seat immediately after verifying its output on disk — idle seats get commandeered.
- Re-read and incorporate existing research artifacts before dispatching new sub-agents for overlapping questions.
- When synthesizing multi-agent output, re-confirm the target project scope at synthesis time, not just at dispatch.

## Things to avoid
- Don't claim work is "live" or "complete" without executing the changed code path — the declared-ready gate fires on inspection-only verdicts.
- Don't substitute prose question-lists or chat confirmations for the required decision-wizard surface when multiple owner decisions are needed.
- Don't declare an empty CSS custom property (`--x: ;`) as a default — `var(--x, fallback)` resolves the empty value, not the fallback; omit the declaration entirely.
- Don't treat an agent-generated doc as the authoritative spec for a gap audit; always re-ground against the human-authored upstream source.

## Open questions / known gaps
- Repeated `declared-ready` gate firings suggest runtime exercise is consistently skipped under time pressure — no mechanical habit has taken hold yet.
- CSS property inheritance edge cases (`inherits: false` + pseudo-elements) have caused repeat regressions; no canonical test pattern exists for this project's animation layer.
