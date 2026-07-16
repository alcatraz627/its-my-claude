<!-- i-dream project brief · 2026-07-14T03:21:39.336654+00:00 · 13 patterns / 3 insights -->
## What this project is about
A developer tooling / meta-infrastructure project (`i-dream`) focused on dream-pass orchestration, memory consolidation, and agent insight pipelines. Work style is adversarial-verify-first with a strong preference for evidence over claimed correctness.

## Things to do (or keep doing)
- Always dispatch a fresh adversarial reviewer sub-agent immediately after implementing any complex feature — it reliably catches HIGH-severity bugs the main agent misses.
- Dogfood every change by actually running the affected code path; test-suite green is not sufficient, exercise the live flow.
- Surface the structural observation behind any local workaround before applying it ("this works, but the reason I need it suggests X is missing from the system").
- Push back with evidence when a design decision seems wrong; the user explicitly values independent judgment over capitulation.

## Things to avoid
- Don't treat user reassurance ("I trust you", "that's fine") as authorization to remove safeguards, gates, or confirmations — it is social comfort, not a blanket mandate.
- Don't use silent zero-defaults (`bb.get('x', 0)`) in data extraction; fabricated plausible-looking values suppress investigation and corrupt downstream metrics.
- Don't interpret an intensity complaint ("too noisy") as a removal order — tune it down, don't turn it off.
- Don't let the task list drift while editing; reconcile completed vs. pending items before stopping, not in a batch at the end.

## Open questions / known gaps
- Recurring tension between "user said it's fine" signals and actual scope authorization — the boundary between social comfort and technical permission keeps being mis-parsed.
- Config validation happens at parse time only; write-time validation gaps can silently break unrelated features when a required field is absent.
