<!-- i-dream project brief · 2026-05-13T11:29:18.759384+00:00 · 4 patterns / 0 insights -->
## What this project is about
A Notion sync pipeline or dashboard integration project. Working style is iterative, UI-heavy, with strong emphasis on correctness for destructive data operations.

## Things to do (or keep doing)
- Use fiber snatcher as the primary debugging mechanism for any React/Next.js state inspection — it's the established tool here, not a fallback
- Treat fiber snatcher as a living tool: improve it in-session when friction surfaces, don't just work around its limits
- Take screenshots frequently during UI work and show them; screenshot-driven iteration is the preferred feedback loop

## Things to avoid
- Don't delete unassigned or "empty" items without explicit confirmation — deletion of unassigned todos caused user frustration; guard all destructive ops with a confirm step
- Don't describe UI changes in prose when you could show a screenshot instead

## Open questions / known gaps
- Confidence in the full scope of what "notion-sync" covers is low — only one session's signal; verify data flow assumptions before touching sync logic
