<!-- i-dream project brief · 2026-08-18T17:50:20.047251+00:00 · 20 patterns / 1 insights -->
## What this project is about
Slack automation and fan-out scraping pipelines with multi-platform data aggregation. Work style is iterative with strong session-continuity needs and external-platform integrations requiring explicit agent attribution.

## Things to do (or keep doing)
- Route raw scraping/collection steps to sonnet-high or gemini; reserve higher-tier models for analysis only
- Always read a sub-agent's output file before treating its work as done — the completion notice is a pointer, not the artifact
- When correcting any pattern instance (prose, code, UI), grep for sibling instances of the same class before declaring done
- Verify task list session scope before displaying — showing the wrong session's list is treated as a hard error

## Things to avoid
- Don't resurface work the user has explicitly parked on a concrete trigger condition (e.g., "only if customer demand"); the deferral stands until explicitly lifted
- Don't name tasks as "unblocked" or "mine" in closing text without executing them in that same turn — naming and deferring is not execution
- Don't assess context pressure by tool count or turn count; only ctx-pressure hook notifications (70/80/90%) are valid instruments
- Don't apply hard line caps to checkpoint summaries; load-bearing constraints must be preserved verbatim regardless of length

## Open questions / known gaps
- AI-smell prose (em-dashes, bold spans) resurfaces repeatedly after correction within the same session — correction loop is not landing; treat prose regeneration after a block as requiring a full rewrite pass, not incremental edits
- Per-source filter coverage in multi-platform data UIs is consistently incomplete at first pass; explicitly audit all actively-scraped sources against the filter UI before calling the feature done
