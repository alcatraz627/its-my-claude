<!-- i-dream project brief · 2026-07-20T11:39:29.286677+00:00 · 20 patterns / 6 insights -->
## What this project is about
A multi-page UI application (likely a dashboard/list-heavy frontend) where the dominant working style is sweep-and-standardize: changes propagate across all pages using a component, not just the one page in view.

## Things to do (or keep doing)
- **Audit the full component surface before writing any code** — when a drawer, sidebar, modal, or list pattern needs a fix, enumerate every page that uses it and patch all of them in the same response
- **Apply sibling patterns without being asked** — if a list page lacks pagination and sibling pages have it, add it; treat existing patterns as implicit requirements
- **Verify CSS class names against the actual stylesheet** — confirm utility classes exist in the project's framework config before use; names that look valid may not be present
- **Surface exact blockers with the command needed to unblock** — when hitting a credential/auth wall, state the exact command and hold; never attempt workarounds

## Things to avoid
- **Don't scope a fix to the named page** — the user's example is always an instance; ask what class it belongs to and fix the class
- **Don't emit zero/false/ALLOW when data is absent** — treat missing or empty results as UNCERTAIN, not as a fabricated default
- **Don't verify in one theme state and call it done** — dark-only or light-only UI checks are partial; scope the claim to what was actually exercised
- **Don't trust names as behavioral contracts** — read the implementation (return statement, class definition, retry handler) before relying on a type annotation, CSS class, or flag mnemonic

## Open questions / known gaps
- Cache invalidation in the test pipeline is a recurring source of false confidence — unclear whether there's a standard cache-bust protocol established for this project
- Deferred decision handoffs repeatedly lack context; no established template for what "enough context" looks like when pausing mid-task for user input
