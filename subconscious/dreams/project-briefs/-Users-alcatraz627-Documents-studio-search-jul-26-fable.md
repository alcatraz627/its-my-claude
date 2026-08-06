<!-- i-dream project brief · 2026-08-06T03:50:16.068568+00:00 · 11 patterns / 0 insights -->
## What this project is about
A search-focused UI project (studio/search, Jul-26) built with React/JSX, using a deliberate two-agent mutual peer-review workflow where independent agents produce and grade each other's plans.

## Things to do (or keep doing)
- **Honor the peer-review protocol**: when given another agent's blueprint to grade, produce a side-by-side contrast table — never collapse into a merged recommendation
- **Respect "good enough" signals**: when the user says get it to a good enough state, stop at a functional baseline and skip exhaustive edge-case handling
- **Design optional services with idle-off**: local background services (Redis, Ollama) should start explicitly and auto-off after an idle threshold — not always-on
- **Triage dead peer outputs selectively**: when incorporating an unavailable agent's work, cherry-pick only the valuable parts rather than wholesale adopting it

## Things to avoid
- **Don't merge when asked to compare**: a side-by-side contrast and a synthesized recommendation are distinct operations — never substitute one for the other silently
- **Don't add unprompted warm-up infra**: scheduled pre-load jobs (e.g. ollama warm-morning) without explicit user request are scope creep
- **Don't use IIFE/scope-wrappers in JSX**: when siblings use inline props or plain const declarations, conform to that pattern instead
- **Don't skip the round-tracking entry**: after completing a multi-round work cycle, write the board/tracking entry before moving on — this step is consistently missed at session end

## Open questions / known gaps
- Round-tracking discipline is a recurring gap — the board entry is frequently deferred and left pending at session end
