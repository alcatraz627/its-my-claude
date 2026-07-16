<!-- i-dream project brief · 2026-07-15T18:49:46.677045+00:00 · 12 patterns / 1 insights -->
## What this project is about
Meta-project managing the user's Claude configuration and tooling (`~/.claude`). Work style is multi-agent and IPC-heavy, with frequent context clears, checkpoint artifacts, and cross-session coordination.

## Things to do (or keep doing)
- **Treat state-ledger writes as blocking:** TaskUpdate, IPC reply, and git commit all execute immediately after completing a unit of work — never defer as "bookkeeping."
- **Confirm IPC delivery via round-trip reply,** not by inspecting your own send logs; the peer must respond before you consider the message delivered.
- **After a burst of sub-agent work, explicitly reconcile the task list** — parallelism silently drifts it; force a sync pass before continuing.
- **Capture peer IPC aliases and session IDs in every core-dump/checkpoint** so successor sessions can resume coordination without re-discovery.

## Things to avoid
- **Don't halt for lightweight go-aheads** — batch sequential work and stop only at genuine decision points or critical reviews that require human judgment.
- **Don't strip technical substance when adjusting document tone** — register calibration for audience means vocabulary/formality, not removing engineering detail.
- **Don't assert IPC success from logs** — a send that looks clean in your logs is not a delivery confirmation.

## Open questions / known gaps
- **Interactive MCP tools fail silently in TUI fullscreen mode** — no fallback path is consistently established; prose-only mode needs to be detected and routed before structured prompts are attempted.
- **Document audience calibration is a recurring friction point** — the right balance between accessible prose and technical density is not yet pinned for this project's external artifacts.
