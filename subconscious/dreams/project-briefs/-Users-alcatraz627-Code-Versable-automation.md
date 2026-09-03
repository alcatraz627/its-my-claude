<!-- i-dream project brief · 2026-08-31T03:33:50.030512+00:00 · 20 patterns / 3 insights -->
## What this project is about
Versable automation tooling — scraping, data pipelines, GitHub integrations, and multi-agent workflows. Work is iterative and verification-heavy, with frequent sub-agent dispatches and shared-platform writes (GitHub PR comments).

## Things to do (or keep doing)
- Always front-load the decision or action in the first sentence; context follows, never precedes
- Verify against CI results, not just local test runs, before declaring a PR green
- When any auth/credential/subscription gate blocks progress, surface the exact user-runnable command immediately, mark blocked, and move on
- Enumerate all output states (light/dark, loaded/empty, success/error) and verify each before declaring done

## Things to avoid
- Don't post to GitHub under the user's account without the agent attribution marker (blockquote format, random phrase from the fixed list — enforced by hook, no bypass)
- Don't mark tasks complete without runtime verification; false done-reports are treated as reporting errors
- Don't re-raise a topic the user has deferred or skipped multiple times — three ignores means it's out of scope until re-invited
- Don't regenerate prose with the same AI-smell tells (em-dashes, excessive bold, Label:fragment rows) after the prose-smell hook fires; clean it before re-emitting

## Open questions / known gaps
- AI-smell prose failures recur even after hook correction in the same turn — the re-emission loop is a standing blind spot requiring active attention on every reply
- Cost reasoning cited without verification is a recurring design-justification error; always check which option is actually cheaper before asserting it
