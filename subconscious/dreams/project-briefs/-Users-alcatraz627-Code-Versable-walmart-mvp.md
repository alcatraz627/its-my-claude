<!-- i-dream project brief · 2026-08-19T19:52:43.266508+00:00 · 16 patterns / 1 insights -->
## What this project is about
A multi-agent orchestrated Walmart MVP build where several peer agents coordinate via IPC; the dominant working style is parallel delegation with a human owner who reviews at explicit gates, not continuously.

## Things to do (or keep doing)
- Always identify agent-generated content explicitly when posting to shared platforms (GitHub PR comments, team channels) under the user's account — include an attribution marker in the message body, not just a footer
- Treat multi-clause stop/goal conditions as strict conjunctions — every clause must independently hold before declaring done; if one clause requires owner action, surface that blockers and wait
- Propagate naming corrections proactively across all peer agents when one agent or the user corrects a naming error that affects the whole multi-agent system
- Preserve load-bearing constraints verbatim in checkpoints and context summaries — never let a line cap silently drop them

## Things to avoid
- Don't act as a pure IPC relay; an orchestrating agent that only passes messages between peers without doing substantive work of its own is wasting a seat — either merge the relay function into a peer or do real work
- Don't treat bot findings on a PR as dismissable; every CI/review-bot flag must be either fixed or argued against with cited evidence
- Don't scope deployment work beyond what the user specified — "CI or auto-deploy only" means implement automation triggers, not production promotion
- Don't build diagnostics that return identical output for distinct failure states (e.g., "tool absent" vs "tool present, no match") — silent-success on a real failure is worse than no diagnostic

## Open questions / known gaps
- The authority-chain inversion is a recurring blind spot: agent-created artifacts (naming conventions, formalized specs, IPC schemas) get treated as primary sources; always verify provenance before citing something as authoritative
- Unanswered peer-agent IPC queries within a turn are a broken contract — the stop hook reminds but the pattern recurs; build explicit query-drain into turn-end discipline
