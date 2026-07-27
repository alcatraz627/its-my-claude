<!-- i-dream project brief · 2026-07-18T06:41:13.227754+00:00 · 13 patterns / 4 insights -->
## What this project is about
Data-forge is a multi-session, agent-coordinated development project where concurrent sibling sessions share a single local repository. Work is agentic and parallel-heavy, with IPC messaging between peers as a first-class coordination primitive.

## Things to do (or keep doing)
- **Re-verify all cross-turn state before use** — branch pointer, task status, IPC alias, file contents; parallel work silently invalidates everything.
- **Update the Task tool after each logical unit**, not in batches; a drifted task list is invisible to the TUI and misleads the next session.
- **Run an adversarial review pass** against your own design docs and plans before handing off — motivated reasoning survives self-review; a fresh pass catches it.
- **Leave commits from sibling sessions alone** — identify their authors, don't absorb or push them; coordinate ownership explicitly.

## Things to avoid
- **Don't route low-value decisions through the user** — no polling nudges, no rubber-stamp confirmations, no context-window anxiety below 50% usage; batch autonomous work and interrupt only at genuine decision points.
- **Don't treat a sent IPC message as confirmed** until a round-trip reply arrives; send-side logs are not delivery receipts.
- **Don't use `@`-scoped identifiers in gemini prompts** — the CLI parses them as image-attach tokens and silently corrupts the prompt.
- **Don't propose diverging names** for sibling packages or repos without an explicit justification; default to the existing naming scheme.

## Open questions / known gaps
- IPC alias-to-peer-ID mapping can stale between turns; no established pattern for live alias verification before send.
- Post-parallel-burst state reconciliation is understood in principle but has no project-specific checklist or affordance.
