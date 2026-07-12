<!-- i-dream project brief · 2026-07-12T04:39:09.475368+00:00 · 13 patterns / 0 insights -->
## What this project is about
Data pipeline and document tooling ("data-forge") with a web UI, GitHub PR integration, and multi-agent orchestration workflows. Work spans backend processing, frontend UI state, config management, and customer-facing document generation.

## Things to do (or keep doing)
- **Check `git log` before implementing** any new ID-storage, config retrieval, or version change — deliberate decisions are frequently already committed; reinvention wastes rounds.
- **Sequence edits to the same file** — parallel `Edit` calls silently clobber each other; both return success but only one survives.
- **Use fenced ` ```diff ` blocks** in GitHub PR comment bodies — ANSI escape codes do not render there.
- **Clarify "runtime variables"** before proceeding — confirm whether the user means deploy-time env vars or on-the-fly application globals; they are treated as distinct here.

## Things to avoid
- **Don't claim UI or server changes are working** without navigating to the actual URL and exercising the primary flow; the user treats unverified success claims as a critical failure.
- **Don't auto-apply on selection** in picker/selection UIs — selection must preview only; an explicit save/apply action commits the change.
- **Don't launch expensive multi-agent workflows** until prerequisite research, docs, and user Q&A are complete; running a debate over incomplete inputs wastes budget.
- **Don't fabricate stub doc content** — scaffold with goal statement and `TODO(human)` placeholders only; never fill sections with invented body text.

## Open questions / known gaps
- "User-facing utility" vs "hardware/throughput metrics" is a recurring miss when augmenting personal tools — confirm the user's actual dimension of value before designing augmentations.
