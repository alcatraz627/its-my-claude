<!-- i-dream project brief · 2026-07-11T04:41:31.483236+00:00 · 6 patterns / 0 insights -->
## What this project is about
Personal developer tooling and dashboard work (`i-dream` insight pipeline, tab-title/status systems, session analytics). Work style is iterative, preference-heavy, and correctness-gated — the user runs the UI and verifies live, not via tests alone.

## Things to do (or keep doing)
- Always navigate to the actual URL and exercise the primary flow before reporting a UI or server change as working; the user treats unexercised claims as critical failures
- Check `git log` for recent commits before introducing any new mechanism to store or retrieve an ID/config value — reinventing something committed in the same week is an automatic correction
- Check `git log` for deliberate version decisions before suggesting any version change (upgrade, revert, new dep); a recent revert is a load-bearing choice, not a candidate for re-reverting

## Things to avoid
- Don't place file paths immediately before sentence-terminating periods in replies — Ghostty auto-links paths and a trailing period breaks the link (use a space, comma, or restructure the sentence)
- Don't default to hardware/throughput metrics when the user asks for workflow-relevant augmentations to a personal tool — ask what utility dimension they actually care about before proposing
- Don't use AI-register phrasing in any user-facing or professional output: no `Good news first:`, no reflexive apologies, no leading-question closers

## Open questions / known gaps
- Tension between autonomous execution and the user's expectation of live verification — the agent consistently over-claims readiness without running the affected path
