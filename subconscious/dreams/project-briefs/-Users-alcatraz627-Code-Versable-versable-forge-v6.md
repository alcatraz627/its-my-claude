<!-- i-dream project brief · 2026-09-02T05:44:28.950818+00:00 · 20 patterns / 4 insights -->
## What this project is about
Full-stack product build (Versable Forge v6) with heavy multi-agent orchestration, UI iteration, and data pipeline work. Dominant style: high-autonomy sequential execution with explicit pause gates only for identity/scope-establishing decisions.

## Things to do (or keep doing)
- **Proceed autonomously** on reversible sequential steps and terse continuations; only pause when the decision establishes identity, provenance, or irreversible state the user must own.
- **Show the actual data** when the user says "show me" — present the full result set directly, never a summary or abstraction of it.
- **Run an ignore-transparent search** (`rg --no-ignore` / `fd --no-ignore`) before asserting a file, module, or directory doesn't exist.
- **Batch multiple owner decisions** through `/decision-wizard` (inline menu ≤3 picks, HTML page above that) — never a numbered chat list.

## Things to avoid
- **Don't claim work is live or complete** without runtime verification — absent env vars, unchecked output paths, and idle notifications are not evidence; read the destination state directly.
- **Don't halt mid-task** without a specific blocker only the user can resolve; re-raising the same soft blocker after an explicit "keep going" is unjustified and wastes attention budget.
- **Don't validate against agent-generated docs** — when auditing or synthesizing, re-ground against the human-authored upstream source, not a downstream agent output that may carry authority contamination.
- **Don't produce UI work** without a verification mechanism; acknowledge inability to verify rather than iterating blindly.

## Open questions / known gaps
- Prose drift recurs mid-session: corrections reset behavior momentarily but the generative default reasserts; schedule re-checks every 10–15 tool calls on long sessions.
- Multi-agent synthesis scope bleeds: synthesizing agents must re-confirm target project scope at write time, not only at dispatch time.
