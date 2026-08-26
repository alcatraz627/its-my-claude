<!-- i-dream project brief · 2026-08-21T23:41:51.322710+00:00 · 20 patterns / 2 insights -->
## What this project is about
CLI/automation tooling for managing kanban-style task boards within Claude Code sessions. Work pattern is autonomous-heavy with frequent UI and documentation generation tasks.

## Things to do (or keep doing)
- Always enumerate what was actually checked when a sweep or scrape returns zero/few results — list pages, endpoints, or sources examined, not just the count
- Prefer async non-blocking deploy flows; pre-establish credentials before any autonomous session that could hit OAuth gates
- Technical planning docs must include visual hierarchy: tables, JSON payload shapes, ASCII diagrams — prose-only is a format failure
- Update task status after each logical unit of work during autonomous runs; don't let the task list drift from actual work done

## Things to avoid
- Don't halt mid-task without a genuine blocker only the user can resolve; "keep going" means the prior pause was unjustified — don't re-raise the same soft blocker
- Don't author a constraint rule (style ban, UI invariant) and then immediately violate it in the same session's output
- Don't use AI-smell prose (em-dashes, excessive bold, literary phrasing) in technical output — stop-hook warnings are not optional
- Don't ground feature gap audits or reviews in agent-authored downstream docs; trace claims to the original user-authored spec

## Open questions / known gaps
- No graceful degradation when model rate limits hit mid-autonomous-session; the session stalls silently rather than surfacing the failure and switching models
- UI completeness verification is systematically incomplete: single-mode sign-offs (dark only, one state) ship as "done" when multi-state exercise was required
