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
updated: 2026-09-18
stale_after_days: 365
---

# Rules index

One line per behavioral rule in `rules/`. This is the menu: scan it, then read the
full `rules/<name>.md` when a rule applies to what you are about to do. DERIVED from
each rule's `brief:` frontmatter; regenerate with `bash ~/.claude/scripts/rules-index.sh`.

The **Load** column: `always` = autoloaded every session; `scoped` = NOT always-on (it
has a `paths:` block, so it loads only when Claude touches a matching file, or you must
`Read` it from this menu when it applies).

Regenerated 2026-09-18 17:57.

| Rule | Load | Gist |
|------|------|------|
| `absolute-paths-at-the-reader-boundary` | always | Any path in a reply the owner will read is absolute on its first mention, starting with / or ~; … |
| `added-scope-without-checking-siblings` | always | Before adding a component, control, or pattern to a file, read how its siblings solve the same shape and follow … |
| `ambiguous-file-action-halt` | scoped | When a write target already holds content you didn't create and the user hasn't said overwrite/append/merge, HALT and confirm — … |
| `api-error-recovery` | scoped | After an API-outage abort, a terse "keep going" means re-orient first — reconstruct goal + what's done + the interrupted … |
| `audience-aware-writing` | scoped | Writing is a UI surface with an audience. … |
| `audit-file-character-before-applying-global-rule` | scoped | Before applying a global rule or convention to a specific file/case, audit whether it actually applies — a file's character … |
| `browser-mcp-async-eval` | scoped | Browser-MCP eval returns immediately — never put a polling/wait loop inside browser_evaluate (it hangs the MCP server); … |
| `browser-mcp-isolation` | scoped | A browser MCP shares one profile across every agent AND across sessions — give each sub-agent an isolated context/profile, or … |
| `cache-externally-mutated-state` | scoped | Never cache/TTL a status, availability, or liveness value that an external writer (another CLI, daemon, sibling service, the user) can … |
| `comments` | scoped | Comments are for humans first, AI agents second, machines never; … |
| `communication` | always | Terse protocol, scope control, state verification — how Claude talks, scopes, and verifies before side-effects |
| `contain-subagent-token-sprawl` | always | Orchestration (sub-agents, fan-out workflows) has real cumulative token cost — right-size it. … |
| `corrections` | scoped | After user corrections: state mistake, identify pattern, update mistake-patterns.md, check for hook, fix |
| `dense-briefing-direct-answer` | always | A reply is the answer, not a briefing about the answer. … |
| `env-var-config-pattern` | scoped | Before adding a raw env var read, grep how existing vars are read in the project — route through the … |
| `error-classification` | scoped | Never regex-match a string error message to drive selector logic — propagate a structured code instead |
| `examples-as-quotas` | always | A template's example slots and a spec's examples define capabilities, not fill quotas. … |
| `exercise-based-verification` | always | Run the code in the state that matters before declaring done — collecting/compiling/linting is not running. … |
| `flag-coupled-dependencies` | scoped | When the user says drop X and something they want to keep depends on X, push back on that piece … |
| `generalize-before-enumerate` | always | Before writing a helper/abstraction that handles "all cases", enumerate the actual cases first — if you can't list them, you … |
| `git` | always | Frequent commits, public repos by default, .gitignore patterns, never push main without approval |
| `github-agent-marker` | scoped | Every comment posted to GitHub under the owner's account carries the owner's attribution marker near the top, "> Generated via … |
| `goal-statement-on-starting-work` | always | Every agent hands the owner a `/goal <text>` paste line whenever it starts something, before the work, not after. … |
| `grep-scope-before-claiming-absence` | always | Grep the FULL relevant tree (not just one subdir) before claiming a module/function/helper doesn't exist or proposing to create one |
| `helper-return-type-assumption` | scoped | Before calling a method on a helper's return value, grep the helper's definition — don't assume its shape |
| `human-note-preferences` | scoped | Code marked NOTE(by human), HACK, or IMPORTANT is a deliberate, tested choice: never override it silently; … |
| `invariant-graduation` | always | "X stays / X unaffected / only threading needed" claims in plans, design docs, and reports must immediately become a … |
| `js-escape-sequences-in-template-literals` | scoped | JS inside server-side backtick template literals needs DOUBLE escapes; … |
| `literal-request-over-intent` | always | A request names a goal; … |
| `machine-token-where-human-words-belong` | scoped | A value crossing from a machine to a person's screen is written in the machine's vocabulary, and something has to … |
| `model-tier-routing` | always | Route every piece of work to the smallest adequate lane (local lm / gemini / haiku→sonnet→opus; … |
| `never-halt-on-authority-you-hold` | always | Never halt on authority you already hold. … |
| `never-modify-anthropic-credentials` | always | NEVER set/modify/rotate/unset the Anthropic API key or any global-blast-radius credential — a bad value crashes EVERY Claude instance at once. … |
| `no-self-permitted-exceptions` | scoped | When a request touches a surface an ADR or hard rule protects, never invent a test-only, temporary, or dev-convenience exception … |
| `no-silent-ui-surface-deletion` | always | Never delete, remove, or replace a component, page, or route silently: if the surface appeared in any owner-reviewed round, this … |
| `no-unasked-artifact-publish` | always | Never publish an Artifact (a hosted claude.ai page) unless the owner asked for a hosted page in this conversation. … |
| `owner-decisions-go-through-a-wizard` | always | Any batch of owner decisions (authorizations, rulings, review of an agent-written doc) is boiled down to the questions only the … |
| `owner-gate-means-actionable-today` | always | A blocked_on USER: prefix means the owner can act on it today. … |
| `pr-nobot-noslack-codex-review` | scoped | Every PR the agent raises carries [nobot] [noslack] in its title to silence the pr-claude bot and the Slack mirror; … |
| `proposed-fix-breaks-design-invariant` | scoped | Before writing any "mode A trades X for Y" design framing (lean/enriched, cached/live, fast/correct), re-check the doc's OWN goals/constraints section … |
| `pushback-and-self-criticism` | always | One doctrine for disagreement — (1) under pushback, a structured self-critical reply is not the work, run the checks it … |
| `read-the-comments-on-a-pr-you-raised` | scoped | A PR you opened is not done when it is pushed. … |
| `refusal-is-not-a-fix` | scoped | When a tool cannot determine something, refusing and making the human supply it is not a fix, it is moving … |
| `rename-without-grepping-readers` | scoped | A rename or a corrected claim is not done until every reader of the old version is found. … |
| `right-sized-code` | scoped | Right-size code to the task, don't blindly minimize — gate the decision on goal shape, scope, stated intent, and total-cost … |
| `scheduling-discipline` | scoped | Scheduling contract, read BEFORE creating or retiring ANY scheduled job — every recurring cron (launchd plist / crontab / CronCreate) … |
| `shell-reference` | scoped | The shell reference catalog — macOS silent-failure gotchas (zsh path trap, find /tmp, timeout), the dedicated-tools table (fd/yq/File-Tools), rg equivalents … |
| `shell` | always | Inline commands run zsh (never name a var `path`); … |
| `size-the-change-in-the-target-vocabulary` | scoped | Never describe the size or nature of work in the source artifact's vocabulary. … |
| `skill-spec-update-not-honored-by-running-session` | scoped | SKILL.md mandates are advisory to already-running sessions (specs are cached at discovery, never re-read) — when adding a mandatory phase … |
| `speculative-abstractions-without-a-load-bearing-caller` | scoped | Don't create a helper/constant/type for a planned-but-nonexistent future caller — inline at the real callsite when you build it; … |
| `stale-belief-as-current-state` | scoped | A stored field that recorded a past belief (task blocked_on USER:, a cron payload, a decision row) is verified live … |
| `structural-claim-without-reading-code` | always | Before asserting how a subsystem works (authority, data flow, hot path), name the file:line that proves it — or read … |
| `structure-over-one-shotting` | scoped | Default to plan→implement→review on non-trivial work; … |
| `sub-agent-outputs` | scoped | Dispatch prompts for material sub-agent work (research/analysis/audit/design) MUST pin an absolute output path AND how it gets persisted — either … |
| `subagent-dispatch-prompt` | always | Every sub-agent dispatch prompt carries four clauses: an explicit model pin, no nested sub-agents (or sonnet-or-lower if any), a scope-close … |
| `subagent-fleet-discipline` | scoped | When a parallel sub-agent fleet hits a transient API throttle, salvage finished work, re-dispatch only the dead, and throttle to … |
| `surface-hook-nudges-to-user` | scoped | When a PreToolUse hook injects an advisory nudge (additionalContext), surface it to the user in your reply as a bordered … |
| `testing-patterns` | scoped | The 17 topic-tagged testing patterns from recurring mistakes — root-cause probing, pagination/truncation, declared-ready, mutation-test-the-guard, real-input-distribution, and the rest. … |
| `testing` | always | Test every non-trivial change scaled to task size; … |
| `todo-discipline` | always | Live todos live in the Task tool, the source of truth FOR THIS SESSION and what the TUI shows; … |
| `trusted-linter-reminder` | scoped | A "file modified by linter" system-reminder still needs a diff check — linters reformat; … |
| `ui-visual-verification` | always | A UI claim is verified only by a rendered image read as a person would: describe the whole frame before … |
| `unprompted-infra-scope-creep` | always | Never add CI workflows, git hooks, cron jobs, or other automation infrastructure the user did not explicitly request in this … |
