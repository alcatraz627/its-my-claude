<!-- i-dream project brief · 2026-06-17T17:09:36.718696+00:00 · 20 patterns / 0 insights -->
## What this project is about
Local LLM tooling and infrastructure (`~/Code/local-models`). Work is exploratory — research, persona design, CLI setup, script authoring — with strong emphasis on evidence-based verification over declaration.

## Things to do (or keep doing)
- **Show actual output when testing.** Surface raw results for the user to inspect; never assert success without evidence — the user judges correctness, not you.
- **Execute `/atone` immediately when invoked.** If the user calls it mid-correction, run it before any other work — skipping while being corrected is a compounded failure.
- **Use the Task tool for todos.** "Update your todos" always means `TaskCreate`/`TaskUpdate`, never a file. The TUI must stay live.
- **Write RCA files with `---` YAML frontmatter on line 1.** Omitting it causes `atone.sh` to exit with error 2 and the event goes unrecorded silently.

## Things to avoid
- **Don't deliver peripheral work before the primary deliverable.** Bonus features, research, and enhancements must not displace the stated core goal — the user treats a missing primary as total failure regardless of surrounding quality.
- **Don't use `rm`.** Use `trash`. The hook blocks it; attempting it anyway signals the rule wasn't internalized.
- **Don't write essay-length comments.** One terse sentence on WHY only when non-obvious; the user pushes back on over-explained code.
- **Don't skip mandatory skill invocations.** If a skill is explicitly named, acknowledge it by running it — deferral after explicit invocation requires explicit user permission.

## Open questions / known gaps
- Recurring atone gate failures (missing YAML frontmatter) suggest RCA template isn't being followed consistently — consider adding a frontmatter snippet to the write step.
- Tension between exploratory multi-subtask sessions and core deliverable priority; no clear session-start contract pattern yet.
