<!-- i-dream project brief · 2026-05-01T11:11:03.797468+00:00 · 15 patterns / 10 insights -->
## What this project is about
A large geopolitical simulation / game theory engine with multi-agent architecture, globe/terrain visualization, scenario modeling (e.g., Iran 2025), and a dark/light UI — built across many sessions with heavy context-boundary crossings.

## Things to do (or keep doing)
- Run `/core-dump` proactively before any session ends; treat WAL + checkpoint as the source of truth on resume
- On terse continuations ("keep going", "more", "next"), reconstruct intent from the last 3-5 WAL actions and execute 10-30 tool calls autonomously before checking in
- After 40+ tool calls, switch to targeted reads (batch greps, fewer exploratory scans) and checkpoint immediately — context compaction is the bottleneck
- Keep responses ≤15 words between tool calls in high-tool-count sessions; verbosity accelerates compaction

## Things to avoid
- Don't expand scope on terse continuation commands — "keep going" means continue exact current task, never implicit permission to add features
- Don't ask clarifying questions after a single-word directive; resume from state, not conversation
- Don't let terrain/globe visualization "look right from code" — known quality issues (blur, resolution) require runtime/browser verification
- Don't batch-verify multiple changes; verify each independently before moving on

## Open questions / known gaps
- Scenario dropdown switching bug is unresolved and actively recurring — any UI work near scenario selection should treat this as a known fragile surface
- Session continuation overhead (WAL restore, /catchup, reorientation) consumes meaningful context before real work begins; no current mitigation beyond earlier checkpointing
