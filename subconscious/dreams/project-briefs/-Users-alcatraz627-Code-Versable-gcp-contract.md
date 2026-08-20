<!-- i-dream project brief · 2026-08-18T06:09:52.861066+00:00 · 20 patterns / 0 insights -->
## What this project is about
GCP contract/integration work with heavy multi-agent adversarial review orchestration; sessions mix domain automation with time-pressured presentation prep.

## Things to do (or keep doing)
- Pass `--quiet` on all `gcloud` commands to prevent mid-pipeline interactive prompts from blocking automation
- Verify sub-agent output by reading ballot/output files on disk — idle notifications are unreliable (stale signals and stop/idle crossings recur)
- Include a maximally adversarial "jester" seat in any review panel that challenges the core premise, not just surface quality
- Honor explicit parking directives ("park it as is") immediately without tidying or attempting to finish

## Things to avoid
- Don't scope magi/review panels to the session's current presentation goal; the user expects real product usability gaps, not a rehearsal check
- Don't re-surface work the user has explicitly conditioned on a concrete trigger (e.g., customer demand); wait for the trigger
- Don't present exhaustive review findings as action items — pre-filter by value-to-effort ratio before surfacing
- Don't use escaped dots in `gcloud --format` projection field paths; they silently fail; use an alternative syntax

## Open questions / known gaps
- Sub-agent idle notification handling has no robust resolution pattern: stale signals and stop/idle crossings cause repeated verification failures
- Mid-session deadline reveals (same-day demo) act as full priority resets but the scope-triage discipline isn't yet consistent
