<!-- i-dream project brief · 2026-09-03T09:01:50.732127+00:00 · 20 patterns / 3 insights -->
## What this project is about
GCP infrastructure and tooling work (deployments, multi-agent orchestration, shared directories) with a heavy emphasis on rigor around state verification, artifact citation, and attention-budget discipline.

## Things to do (or keep doing)
- Always run `rg --no-ignore` before claiming a file, route, or code path doesn't exist — default search ignores .gitignore'd paths
- Read every file before writing it, especially in shared multi-agent dirs where peer agents may have modified it since last read
- When the user asks a scoping/delegation question, enumerate only the owner-only blockers — brief, not operational rundown
- Verify numbered artifacts (PRs, issues) actually exist in the repo before referencing them

## Things to avoid
- Don't treat `--dry-run` output as confirmation of a real deploy; it prints commands, it does not execute them
- Don't halt mid-task unless the blocker is genuine and only the user can resolve it — re-raising soft blockers after an explicit "keep going" is a known failure mode here
- Don't substitute a curated summary when the user asked for raw data; deliver the full result set
- Don't re-raise items the user has explicitly ruled closed — record the ruling durably and never surface it again

## Open questions / known gaps
- Orchestrating agent tends to spend turns relaying IPC instead of doing substantive work; the boundary between orchestration and delegation is an ongoing tension
- State surfaces (task list, agent roster) drift without live reconciliation — treat every status as potentially stale before acting on it
