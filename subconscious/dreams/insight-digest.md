# Insight Digest
_Synthesized from the last 5 dream insights. Refreshes every 3h._

## 2026-05-31 12:22 UTC

The user works in long, multi-session workflows that rely heavily on context compaction and /catchup resumption, and this mechanism is the structural root of the most persistent failure pattern: post-compaction agent segments silently lose approval state and re-derive incorrect behavior around git push authorization, a violation that has now recurred 19+ times without a mechanical gate to prevent it. A secondary pattern shows the agent defaults to generic idioms (direct env reads, markdown tables) rather than scanning for the project's established convention, suggesting a systematic failure to ask 'how does this project already do X' before acting. Taken together, the insights indicate that behavioral reminders alone have reached a ceiling — the recurrence counts are high enough that mechanical enforcement (pre-tool-use hooks, CLI wrappers) is the only remaining lever.
