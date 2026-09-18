---
brief: Every sub-agent dispatch prompt carries four clauses: an explicit model pin, no nested sub-agents (or sonnet-or-lower if any), a scope-close line (ignore board or task auto-dispatch; stop when the scoped work is done), and an absolute output path written before returning. This file owns the wording; other rules point here.
triggers:
  - tool:Agent
  - topic:sub-agent
  - topic:dispatch
related:
  - rules/contain-subagent-token-sprawl.md
  - rules/model-tier-routing.md
  - rules/sub-agent-outputs.md
  - skills/create-skill/subagent-prompt.md
tier: 1
category: rules
updated: 2026-08-27
stale_after_days: 180
---

# The five clauses every sub-agent dispatch carries

Several rules used to restate these in their own words, and a prompt could satisfy one
file and fail another. The wording lives here once; `/create-skill subagent-prompt`
emits it into every brief.

1. **Model pin.** `model:` is explicit on every `Agent` or `workflow.agent()` call. An
   unpinned spawn inherits the session model, which is the flagship.
2. **Nesting closed.** The prompt says "Do NOT spawn sub-agents" (bounded tasks) or
   "any sub-agent you spawn must pin sonnet or lower".
3. **Scope close.** "Ignore any task-list or board auto-dispatch. When your scoped
   work is done, stop; do not pick up other tasks." The parent `TaskStop`s a verified
   agent; an idle one gets commandeered (2026-07-07).
4. **Output path.** An absolute path the seat writes BEFORE returning (never a file
   literally named report.md); the parent verifies the file exists before using any
   finding. The return abstract is a pointer, not the artifact.

5. **One command per Bash call.** "Do not chain commands with `&&`, `;` or a pipe;
   Claude Code cannot statically verify a compound and asks the human about the
   whole chain. Ask a tool for less output instead of piping." A dispatched agent
   inherits the settings files but not the conventions, so without this clause it
   chains freely and the owner answers a prompt for work he never saw dispatched.
   Owner ruling 2026-09-04; mechanism in `rules/shell.md`.

## Diagnostic signal

You are composing an `Agent` prompt and cannot point at each of the five clauses in
it.
