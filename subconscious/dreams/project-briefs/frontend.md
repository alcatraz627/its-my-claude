<!-- i-dream project brief · 2026-07-23T00:59:10.005597+00:00 · 20 patterns / 10 insights -->
## What this project is about
Multi-agent frontend development with heavy IPC coordination between parallel sessions; the dominant pattern is concurrent work on shared surfaces requiring explicit ownership negotiation and consumer-side verification.

## Things to do (or keep doing)
- **Ground first**: explore and map the codebase, surface a recommendation, then touch code — jumping to edits without grounding wastes a round-trip
- **Breadth before depth**: complete a v1 pass across all surfaces before polishing or validating any individual item; the user will redirect if scope narrows prematurely
- **Batch sequential work**: halt only at genuine decision points or blockers; supply enough context in decision questions for the user to answer in one response without follow-up
- **Verify from the consumer side**: confirm IPC delivery via round-trip reply, not send-side logs; confirm UI changes in the user's mode (light+dark), not just dev mode

## Things to avoid
- **Don't emit plausible defaults from absent input**: when a lookup, gate, or probe returns empty/unknown, emit UNCERTAIN or DENY — never synthesize a zero, false, or ALLOW from missing data
- **Don't use `rg -rn`**: `-r` is `--replace`, not recursive; use `rg -n` for line numbers; recursive search is the default
- **Don't patch the instance**: when the user cites a specific CLI, page, or field as an example, grep the full tree for the class before scoping the fix
- **Don't use backticks in IPC message bodies**: shell consumes them; pass the body via a heredoc or escaped argument

## Open questions / known gaps
- TaskUpdate discipline degrades under high parallel velocity — state sync is being deferred exactly when it's most needed
- Access-gate default posture (DENY vs ALLOW for unrecognized commands) has been a recurring structural miss; confirm gate default on any new permission surface
