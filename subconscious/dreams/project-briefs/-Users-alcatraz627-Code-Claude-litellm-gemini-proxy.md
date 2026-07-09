<!-- i-dream project brief · 2026-07-09T14:04:08.626587+00:00 · 2 patterns / 0 insights -->
## What this project is about
A LiteLLM-based proxy for routing requests to Gemini models. Working style: low signal volume — likely early-stage or infrequently touched.

## Things to do (or keep doing)
- When printing file paths in terminal output, always follow the path with a space, comma, or restructure so the path is never the last token before a sentence period — Ghostty auto-links swallow trailing periods
- Verify file path formatting in multi-line output blocks proactively, not reactively

## Things to avoid
- Don't end sentences with a bare file path followed by a period (e.g., `` `proxy.py`. ``) — restructure to `` `proxy.py` was updated`` or similar
- Don't assume documenting the rule is sufficient; the hook fires regardless, so restructure the sentence structure itself

## Open questions / known gaps
- No domain-specific patterns yet — too few sessions to extract proxy config, routing logic, or auth conventions
