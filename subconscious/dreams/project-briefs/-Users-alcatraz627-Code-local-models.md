<!-- i-dream project brief · 2026-07-14T03:22:45.304149+00:00 · 13 patterns / 3 insights -->
## What this project is about
Local LLM suite (`~/Code/local-models`) — model runners, UI, data pipelines, and agent harness tooling. Work style is iterative with high emphasis on runtime correctness and safeguard integrity.

## Things to do (or keep doing)
- **Run the affected code path after every non-trivial change** — test suites (even 99+ tests) miss bugs that live execution catches; dogfood before claiming done
- **Dispatch an adversarial reviewer sub-agent immediately after implementing complex features** — it reliably surfaces HIGH-severity bugs the implementing agent misses
- **Restate the exact scope of any user signal before acting on it** — `'you said X, which I interpret as Y but not Z'` — social comfort ("I trust you") is never authorization to remove a gate; intensity complaints ("too noisy") set a ceiling, not a kill switch
- **Surface the structural observation behind a local workaround** — inline CSS signals a UI kit gap, a silent zero-default signals missing data; name the systemic issue before applying the fix

## Things to avoid
- **Don't use `dict.get('key', 0)` or similar zero-defaults when data may be absent** — fabricated zeros produce plausible-looking downstream values that suppress investigation
- **Don't let the task list drift across many turns of editing** — reconcile completed/abandoned items before stopping; a stale list is fiction
- **Don't add a new library dependency silently** — surface the constraint, offer a within-existing-deps alternative first, wait for approval

## Open questions / known gaps
- Config validation only at parse time silently breaks unrelated features when fields are missing; no systematic write-time validation in place yet
- Plausible-but-wrong state (fabricated values, passing-but-not-running tests) is the project's highest-recurrence failure class — no automated ground-truth verification gate exists
