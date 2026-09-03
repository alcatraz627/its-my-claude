<!-- i-dream project brief · 2026-09-02T05:45:30.190004+00:00 · 20 patterns / 0 insights -->
## What this project is about
Local LLM suite management on macOS (`~/Code/local-models`), covering model orchestration, agent tooling, and multi-agent workflows. Work style is autonomous, breadth-first, fleet-heavy.

## Things to do (or keep doing)
- **Ground first, then edit**: explore the existing codebase and surface a recommendation before touching any file; the user expects grounding, not reflexive edits.
- **Breadth-first sweeps**: complete a full pass across all surfaces before polishing individual items; pausing mid-sweep to perfect one area is a pattern failure here.
- **Fleet over depth**: for large review coverage, prefer many lower-cost agents over fewer expensive ones; coverage beats depth on this project.
- **Stop idle agents immediately**: after verifying a sub-agent's output, `TaskStop` it; seats left running get commandeered by board auto-dispatchers.

## Things to avoid
- **Don't declare done without running the path**: the declared-ready gate has fired multiple times in one session here; exercise the changed code before claiming completion.
- **Don't use shell `timeout` on macOS**: it silently orphans child processes; use Python-based or process-group kill approaches instead.
- **Don't assume IPC send = delivered**: a round-trip reply is the only confirmation; send-side logs are not evidence of receipt.
- **Don't raise context-window anxiety below 70%**: the ctx-pressure hook fires at 70/80/90%; suppress that concern until it fires.

## Open questions / known gaps
- Multi-agent task ownership coordination via IPC is fragile; overlapping claims without pre-negotiation produce muddy state — no robust solution established yet.
- File placement rules (agent working docs vs. durable shared docs) have been silently violated across sessions; the boundary isn't consistently enforced.
