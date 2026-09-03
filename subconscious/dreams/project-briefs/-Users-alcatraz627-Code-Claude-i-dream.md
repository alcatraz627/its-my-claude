<!-- i-dream project brief · 2026-08-31T03:33:20.734914+00:00 · 20 patterns / 3 insights -->
## What this project is about
Dream-cycle memory consolidation system for Claude Code sessions — a background agent that reads session transcripts, extracts behavioral patterns, and writes structured insight files. Work style is investigative + review-heavy with frequent peer-agent cross-checks.

## Things to do (or keep doing)
- **Preserve independent outputs as separate artifacts** until the user explicitly requests a merge — peer plans stay side-by-side, never auto-collapsed
- **Grep the full project tree before fixing any single instance** — UI shells, pagination, component patterns are always global concerns
- **Trace claims back to human-authored source** (design mock, spec, actual code) before using them — never treat a Claude-generated doc as ground truth
- **Continue on terse signals** ("proceed", "keep going") without asking for clarification when context is below 70% pressure

## Things to avoid
- **Don't declare UI or runtime fixes done without exercising the running dev server** — visual inspection only; green local tests ≠ CI pass ≠ rendered page verified
- **Don't implement any UI shell component on one page without auditing all sibling pages** for the same component first
- **Don't assert cost or structural claims without reading the source** — "this is cheaper" or "this doesn't exist" requires a file:line citation
- **Don't regress to default-LLM register after a prose-smell hook fires** — rewritten replies must be checked before sending; the same violations recur immediately after correction

## Open questions / known gaps
- Prose-smell hook fires repeatedly but corrections don't stick across turns — the enforcement loop isn't closing; each rewrite needs an explicit self-check before sending
- CI vs local test divergence is a recurring false-green pattern; the project may need a standing "check CI, not just local" checkpoint before any "done" claim
