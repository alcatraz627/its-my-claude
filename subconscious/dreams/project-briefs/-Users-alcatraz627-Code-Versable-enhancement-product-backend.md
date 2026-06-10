<!-- i-dream project brief · 2026-05-31T19:29:45.769932+00:00 · 12 patterns / 10 insights -->
## What this project is about
Python backend for a B2B SaaS product (Versable enhancement); work is stateful, multi-session, and context-exhaustion-prone with heavy emphasis on data integrity, optional integrations, and production-safe migrations.

## Things to do (or keep doing)
- Run `/core-dump` proactively at milestones and before risky ops — treat it as a standard workflow step, not a user-requested one
- After any `catchup` or context reconstruction, re-read key files before acting — treat recalled state as unverified
- Design optional feature modules (telemetry, profilers, integrations) to fail gracefully across all failure modes: exception, missing env var, import error
- Log costs as a first-class concern; design storage schemas to capture them from the start

## Things to avoid
- Don't assume env vars present in dev are set in prod — verify at implementation time that the module degrades gracefully when absent
- Don't let migration scripts bypass explicit review for data-destructive edge cases; missing these while flagging lower-priority issues is a critical reviewer failure
- Don't expand response length during high-tool-count sessions — keep inter-tool narration ≤15 words to delay compaction

## Open questions / known gaps
- Widget text truncation is a recurring regression — no systematic rendering verification step exists in the workflow yet
- Context exhaustion is a structural pressure: sessions routinely exceed 50–100 tool calls; the checkpoint cadence (every ~25 tools) is established but not yet enforced mechanically
