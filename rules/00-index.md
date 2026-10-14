---
brief: Compact always-on menu of every behavioral rule (name + load-mode + one-line gist). DERIVED from each rule's brief via scripts/rules-index.sh; the overview layer for progressive disclosure.
triggers:
  - topic:rules-index
  - phrase:"which rule applies"
related:
  - PLACEMENT.md
  - rules/README.md
tier: 0
category: rules
updated: 2026-10-15
stale_after_days: 365
---

# Rules index

One line per rule in `rules/`. Scan it, then Read `rules/<name>.md` when a rule applies.
`always` = loaded every session; `scoped` = not loaded, Read it when it applies.
DERIVED from each rule's `brief:`; regenerate with `bash ~/.claude/scripts/rules-index.sh`.

Regenerated 2026-10-15 01:36.

| Rule | Load | Gist |
|------|------|------|
| `absolute-paths-at-the-reader-boundary` | always | Any path in a reply the owner will read is absolute |
| `added-scope-without-checking-siblings` | always | Before adding a component, control, or pattern to a file, read how |
| `ambiguous-file-action-halt` | scoped | When a write target already holds content you didn't create and the user |
| `api-error-recovery` | scoped | After an API-outage abort, a terse "keep going" means re-orient first |
| `audience-aware-writing` | scoped | Writing is a UI surface with an audience |
| `audit-file-character-before-applying-global-rule` | scoped | Before applying a global rule or convention to a specific file or case |
| `browser-mcp-async-eval` | scoped | Browser-MCP eval returns immediately. Never put a polling or wait loop inside browser_evaluate |
| `browser-mcp-isolation` | scoped | A browser MCP shares one profile across every agent AND across sessions |
| `cache-externally-mutated-state` | scoped | Never cache or TTL a status, availability or liveness value that an external |
| `comments` | scoped | Comments are for humans first, AI agents second, machines never |
| `communication` | always | Terse protocol, scope control and state verification |
| `contain-subagent-token-sprawl` | always | Orchestration (sub-agents, fan-out workflows) has real cumulative token cost, so right-size |
| `corrections` | scoped | After user corrections: state mistake, identify pattern, update mistake-patterns.md, check for hook, fix |
| `dense-briefing-direct-answer` | always | A reply is the answer, not a briefing about the answer |
| `env-var-config-pattern` | scoped | Before adding a raw env var read, grep how existing vars are read |
| `error-classification` | scoped | Never regex-match a string error message to drive selector logic |
| `examples-as-quotas` | always | A template's example slots and a spec's examples define capabilities, not fill quotas |
| `exercise-based-verification` | always | Run the code in the state that matters before declaring done |
| `flag-coupled-dependencies` | scoped | When the user says drop X and something they want to keep depends |
| `generalize-before-enumerate` | always | Before writing a helper/abstraction that handles "all cases", enumerate the actual cases first |
| `git` | always | Frequent commits, public repos by default, .gitignore patterns, never push main without approval |
| `github-agent-marker` | scoped | Every comment posted to GitHub under the owner's account carries the owner's attribution |
| `goal-statement-on-starting-work` | always | Every agent hands the owner a `/goal <text>` paste line whenever it starts |
| `grep-scope-before-claiming-absence` | always | Grep the FULL relevant tree (not just one subdir) before claiming a module/function/helper |
| `helper-return-type-assumption` | scoped | Before calling a method on a helper's return value, grep the helper's definition |
| `human-note-preferences` | scoped | Code marked NOTE(by human), HACK, or IMPORTANT is a deliberate, tested choice |
| `invariant-graduation` | always | "X stays / X unaffected / only threading needed" claims in plans, design |
| `js-escape-sequences-in-template-literals` | scoped | JS inside server-side backtick template literals needs DOUBLE escapes |
| `literal-request-over-intent` | always | A request names a goal; the wording is a sample of it, |
| `machine-token-where-human-words-belong` | scoped | A value crossing from a machine to a person's screen is written |
| `model-tier-routing` | always | Route work to the smallest adequate lane (local lm, gemini, haiku, sonnet, opus) |
| `never-halt-on-authority-you-hold` | always | Never halt on authority you already hold |
| `never-modify-anthropic-credentials` | always | NEVER set/modify/rotate/unset the Anthropic API key or any global-blast-radius credential |
| `no-opaque-login-items` | always | Every LaunchAgent the gcc adds must show in macOS Login Items under |
| `no-self-permitted-exceptions` | scoped | When a request touches a surface an ADR or hard rule protects, never |
| `no-silent-ui-surface-deletion` | always | Never delete, remove, or replace a component, page, or route silently |
| `no-unasked-artifact-publish` | always | Never publish an Artifact (a hosted claude.ai page) unless the owner asked |
| `owner-decisions-go-through-a-wizard` | always | Any batch of owner decisions (authorizations, rulings, review of an agent-written doc) |
| `owner-gate-means-actionable-today` | always | A blocked_on USER: prefix means the owner can act on it today |
| `pr-nobot-noslack-codex-review` | scoped | Every PR the agent raises carries [nobot] [noslack] in its title to silence |
| `proposed-fix-breaks-design-invariant` | scoped | Before writing any "mode A trades X for Y" design framing (lean/enriched, cached/live |
| `pushback-and-self-criticism` | always | One doctrine for disagreement. Run the checks a self-critical reply names before sending |
| `read-the-comments-on-a-pr-you-raised` | scoped | A PR you opened is not done when it is pushed |
| `refusal-is-not-a-fix` | scoped | When a tool cannot determine something, refusing and making the human supply |
| `rename-without-grepping-readers` | scoped | A rename or a corrected claim is not done until every reader |
| `right-sized-code` | scoped | Right-size code to the task, don't blindly minimize |
| `scheduling-discipline` | scoped | Scheduling contract, read BEFORE creating or retiring ANY scheduled job |
| `shell-reference` | scoped | The shell reference catalog: macOS silent-failure gotchas (zsh path trap, find /tmp, timeout) |
| `shell` | always | Inline commands run zsh (never name a var `path`) |
| `size-the-change-in-the-target-vocabulary` | scoped | Never describe the size or nature of work in the source artifact's vocabulary |
| `skill-spec-update-not-honored-by-running-session` | scoped | SKILL.md mandates are advisory to already-running sessions (specs are cached at discovery |
| `speculative-abstractions-without-a-load-bearing-caller` | scoped | Don't create a helper, constant or type for a planned-but-nonexistent future caller |
| `stale-belief-as-current-state` | scoped | A stored field that recorded a past belief (task blocked_on USER:, a cron |
| `structural-claim-without-reading-code` | always | Before asserting how a subsystem works (authority, data flow, hot path), name |
| `structure-over-one-shotting` | scoped | Default to plan→implement→review on non-trivial work |
| `sub-agent-outputs` | scoped | Dispatch prompts for material sub-agent work (research, analysis, audit, design) |
| `subagent-dispatch-prompt` | always | Every sub-agent dispatch prompt carries four clauses |
| `subagent-fleet-discipline` | scoped | When a parallel sub-agent fleet hits a transient API throttle, salvage finished work |
| `surface-hook-nudges-to-user` | scoped | When a PreToolUse hook injects an advisory nudge (additionalContext), surface |
| `testing-patterns` | scoped | The 17 topic-tagged testing patterns from recurring mistakes |
| `testing` | always | Test every non-trivial change scaled to task size |
| `todo-discipline` | always | Live todos live in the Task tool, the agent's checklist FOR THIS SESSION |
| `trusted-linter-reminder` | scoped | A "file modified by linter" system-reminder still needs a diff check |
| `ui-visual-verification` | always | A UI claim is verified only by a rendered image read |
| `unprompted-infra-scope-creep` | always | Never add CI workflows, git hooks, cron jobs, or other automation infrastructure |
