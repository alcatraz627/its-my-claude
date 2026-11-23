---
brief: Menu of every behavioral rule. Scoped rules get the situations that call for them and what they say; always-on rules get one line. DERIVED from each rule's frontmatter via scripts/rules-index.sh.
triggers:
  - topic:rules-index
  - phrase:"which rule applies"
related:
  - PLACEMENT.md
  - rules/README.md
tier: 0
category: rules
updated: 2026-11-23
stale_after_days: 365
---

# Rules index

65 rules in `rules/`: 36 scoped, 29 always-on.
DERIVED from each rule's frontmatter; regenerate with `bash ~/.claude/scripts/rules-index.sh`.
Regenerated 2026-11-23 23:19.

## Scoped rules: not in your context

This table is the only place these rules appear. When the middle column matches
what you are about to do, Read `rules/<name>.md` first. "autoloads on" means the
rule also loads by itself when you touch a matching file; the rest never load unasked.

| Rule | Read it when the work involves | What it says |
|------|--------------------------------|--------------|
| `ambiguous-file-action-halt` | overwrite existing file · `Write` · "what to do with the file" · "already exists" | When a write target already holds content you didn't create and the user hasn't said overwrite/append/merge, HALT and confirm. Don't guess |
| `api-error-recovery` | "keep going" · "proceed" · "recover" · "api error" | After an API-outage abort, a terse "keep going" means re-orient first. Reconstruct the goal, what is done and the interrupted step, then continue |
| `audience-aware-writing` | docs work · pr description · writing · `commit` · `readme` · `write-docs` · "PR description" · autoloads on *.md *.mdx README* *.txt | Writing is a UI surface with an audience. Identify the reader (human for comments/docs/PRs, agent for internal notes) and write meaning-first, never default-LLM register |
| `audit-file-character-before-applying-global-rule` | refactor · file organization · "move X to Y" · "consolidate into" · "extract to" · "per the rule" | Before applying a global rule or convention to a specific file or case, audit whether it actually applies |
| `browser-mcp-async-eval` | browser automation · playwright · browser mcp · `browser_evaluate` · `evaluate_script` · "browser_evaluate" | Browser-MCP eval returns immediately. Never put a polling or wait loop inside browser_evaluate (it hangs the MCP server), poll state from the shell between calls |
| `browser-mcp-isolation` | browser automation · playwright · browser mcp · concurrent validators · "isolatedContext" · "browser profile" | A browser MCP shares one profile across every agent AND across sessions. Give each sub-agent an isolated context or profile, or logins |
| `cache-externally-mutated-state` | caching · stale state · "availability cache" · "cache the status" | Never cache or TTL a status, availability or liveness value that an external writer (another CLI, daemon, sibling service, the user) can change |
| `comments` | docstrings · "docstring" · autoloads on *.ts *.tsx *.js *.jsx *.py +7 | Comments are for humans first, AI agents second, machines never; first sentence of a non-trivial docstring is code-agnostic; keep [claude@] agent-notes separate from human comments |
| `corrections` | user corrections · "revert this" · "why did you" | After user corrections: state mistake, identify pattern, invoke /atone, check for hook, fix |
| `env-var-config-pattern` | env var · configuration · "process.env" · "os.getenv" · "os.environ" · autoloads on *.ts *.tsx *.js *.jsx *.py +2 | Before adding a raw env var read, grep how existing vars are read in the project. Route through the central config module or schema if one exists |
| `error-classification` | error handling · cause routing · "err.message.match" · "cause_message" · "includes(" · autoloads on *.ts *.tsx *.js *.jsx *.py | Never regex-match a string error message to drive selector logic. Propagate a structured code instead |
| `flag-coupled-dependencies` | scope · "drop" · "simplify" · "remove" | When the user says drop X and something they want to keep depends on X, push back on that piece before accepting the broader simplification |
| `github-agent-marker` | github comments · agent attribution · `gh` · "comment on the PR" | Every comment posted to GitHub under the owner's account carries the owner's attribution marker near the top |
| `helper-return-type-assumption` | helper call · type assumption · ".isoformat()" · "helper return" | Before calling a method on a helper's return value, grep the helper's definition. Don't assume its shape |
| `human-note-preferences` | comments · "NOTE(by human)" · "HACK" | Code marked NOTE(by human), HACK, or IMPORTANT is a deliberate, tested choice: never override it silently; ask first with reasoning, then verify the result |
| `js-escape-sequences-in-template-literals` | template literals · server side rendering · "renderPage" · "backtick" · "inline script" · autoloads on *.ts *.tsx *.js *.jsx *.mjs +1 | JS inside server-side backtick template literals needs DOUBLE escapes; `node --check` won't catch it, so verify in a real browser |
| `machine-token-where-human-words-belong` | ui · rendering · error messages · "object Object" · "renders as" · "shows the code" · autoloads on *.tsx *.jsx *.vue *.svelte ** +1 | A value crossing from a machine to a person's screen is written in the machine's vocabulary, and something has to translate it |
| `no-self-permitted-exceptions` | adr · exceptions · "just for testing" · "temporary" | When a request touches a surface an ADR or hard rule protects, never invent a test-only, temporary, or dev-convenience exception the rule does not contain |
| `pr-nobot-noslack-codex-review` | pr · code review · `gh` · "open a PR" · "pull request" · "gh pr create" | The [nobot] [noslack] PR title tags are a per-repo call |
| `proposed-fix-breaks-design-invariant` | design doc · design invariant · "lean vs enriched" · "trades freshness" · "fast vs correct" | Before writing any "mode A trades X for Y" design framing (lean/enriched, cached/live, fast/correct), re-check the doc's OWN goals and constraints section as a checklist |
| `read-the-comments-on-a-pr-you-raised` | pull request · pr review · `gh` · "opened a PR" · "raised a PR" · "PR is up" · "ready for review" | A PR you opened is not done when it is pushed. Poll its comments at 5s then 30s, and for every review finding either fix it or argue |
| `refusal-is-not-a-fix` | resolution · ambiguity · "cannot determine" · "requires the user to specify" · "no reliable way to" · autoloads on *.sh *.py *.js *.cjs *.ts | When a tool cannot determine something, refusing and making the human supply it is not a fix, it is moving the cost onto them |
| `rename-without-grepping-readers` | rename · "renamed" · "rename the" · "breaking rename" · "stale caller" · "fixed everywhere" · "none left" | A rename, a corrected claim or a changed owner ruling is not done until every reader of the old version is found |
| `right-sized-code` | refactor · code simplification · ui build · `skeptical-review` · "simplest solution" · "minimal solution" · "over-engineered" | Right-size code to the task, don't blindly minimize. Gate the decision on goal shape, scope, stated intent, and total-cost fit, then climb the laziness ladder inside that gate |
| `scheduling-discipline` | scheduling · cron · launchd · scheduled job · `CronCreate` · `gcc-schedule` · "schedule this" | Scheduling contract, read BEFORE creating or retiring ANY scheduled job. Every recurring cron (launchd plist / crontab / CronCreate) ALSO gets an `Automations` calendar event with label+command+plist |
| `shell-reference` | shell · bash · zsh · `rg` · `fd` · `yq` · autoloads on *.sh *.bash *.zsh | The shell reference catalog: macOS silent-failure gotchas (zsh path trap, find /tmp, timeout), the dedicated-tools table (fd/yq/File-Tools), rg equivalents plus the legitimate-grep cases, and the prefer-existing-scripts law |
| `size-the-change-in-the-target-vocabulary` | scope estimate · figma · design to code · diff report · "rebuild" · "rewrite" · "from scratch" | Never describe the size or nature of work in the source artifact's vocabulary. A design tool's two frames, a spec's two versions |
| `skill-spec-update-not-honored-by-running-session` | skill loading · spec enforcement · `migrate` · "add a mandatory phase" · "SKILL.md cache" | SKILL.md mandates are advisory to already-running sessions (specs are cached at discovery and never re-read). When adding a mandatory phase to a skill |
| `speculative-abstractions-without-a-load-bearing-caller` | abstraction · helper function · "I'll add a helper" · "for future use" · "reusable" | Don't create a helper, constant or type for a planned-but-nonexistent future caller. Inline at the real callsite when you build it, and let abstractions crystallize from 2 |
| `stale-belief-as-current-state` | blocked on · owner gate · stale state · `task-table.sh` · "needs you" · "waiting on you" · autoloads on ** | A stored field that recorded a past belief (task blocked_on USER:, a cron payload, a decision row) is verified live before it is rendered as current state |
| `structure-over-one-shotting` | multi file change · agentic coding · "one-shot" · "just one-shot it" | Default to plan→implement→review on non-trivial work; a failed one-shot wastes more than structure would have. One-shotting is fine only for genuinely trivial one-offs |
| `sub-agent-outputs` | `Agent` · "dispatch sub-agent" · "research agent" · "opus sub-agent" · "parallel agents" | Dispatch prompts for material sub-agent work (research, analysis, audit, design) MUST pin an absolute output path AND how it gets persisted |
| `subagent-fleet-discipline` | subagent fleet · api error recovery · `Agent` · `Workflow` · "re-dispatch" · "fleet died" | When a parallel sub-agent fleet hits a transient API throttle, salvage finished work, re-dispatch only the dead, and throttle to batches on a second outage |
| `surface-hook-nudges-to-user` | hook nudge · "hook additional context" · "PreToolUse" | When a PreToolUse hook injects an advisory nudge (additionalContext), surface it to the user in your reply as a bordered callout, because it is invisible to them otherwise |
| `testing-patterns` | testing · test patterns · verification · "mutation test" · "flaky test" · autoloads on *test* ** *.spec.* | The 17 topic-tagged testing patterns from recurring mistakes: root-cause probing, pagination/truncation, declared-ready, mutation-test-the-guard, real-input-distribution, and the rest. The catalog half of rules/testing.md, split out 2026-09-01 (prime-demotion-0901 D2a) |
| `trusted-linter-reminder` | linter reminder · "file was modified" · "don't revert" · "intentional" | A "file modified by linter" system-reminder still needs a diff check. Linters reformat, and they don't change runtime semantics |

## Always-on rules: already loaded in full

| Rule | Gist |
|------|------|
| `absolute-paths-at-the-reader-boundary` | Any path in a reply the owner will read is absolute on its first mention, starting with / or ~ |
| `added-scope-without-checking-siblings` | Before adding a component, control, or pattern to a file, read how its siblings solve the same shape and follow them |
| `communication` | Terse protocol, scope control and state verification: how Claude talks, scopes, and verifies before side-effects |
| `contain-subagent-token-sprawl` | Orchestration (sub-agents, workflows, eval runs) has real cumulative token cost, so right-size it and say the estimated cost first |
| `dense-briefing-direct-answer` | A reply is the answer, not a briefing about the answer. Three shapes with distinct tells |
| `examples-as-quotas` | A template's example slots and a spec's examples define capabilities, not fill quotas. Produce the slot when the case earns |
| `exercise-based-verification` | Run the code in the state that matters before declaring done. Collecting, compiling and linting are not running. Enforced by the declared-ready Stop hook |
| `generalize-before-enumerate` | Before writing a helper/abstraction that handles "all cases", enumerate the actual cases first. If you can't list them, you don't understand the domain well enough |
| `git` | Frequent commits, public repos by default, .gitignore patterns, never push main without approval |
| `goal-statement-on-starting-work` | Every agent hands the owner a `/goal <text>` paste line whenever it starts something, before the work, not after |
| `grep-scope-before-claiming-absence` | Grep the FULL relevant tree (not just one subdir) before claiming a module/function/helper doesn't exist or proposing to create one |
| `invariant-graduation` | "X stays / X unaffected / only threading needed" claims in plans, design docs, and reports must immediately become a verification task + a Standing-constraints checkpoint |
| `literal-request-over-intent` | A request names a goal; the wording is a sample of it, not its boundary. Seven shapes with distinct tells |
| `model-tier-routing` | Smallest adequate lane, a Model Plan for sub-agent plans, no model switch without confirmation |
| `never-halt-on-authority-you-hold` | Never halt on authority you already hold. Six atone slugs, 14 events in 21 days: a go already given, naming the next work |
| `never-modify-anthropic-credentials` | NEVER set/modify/rotate/unset the Anthropic API key or any global-blast-radius credential. A bad value crashes EVERY Claude instance at once |
| `no-opaque-login-items` | Every LaunchAgent the gcc adds must show in macOS Login Items under a name that says what |
| `no-silent-ui-surface-deletion` | Never delete, remove, or replace a component, page, or route silently: if the surface appeared in any owner-reviewed round |
| `no-unasked-artifact-publish` | Never publish an Artifact (a hosted claude.ai page) unless the owner asked for a hosted page in this conversation |
| `owner-decisions-go-through-a-wizard` | Any batch of owner decisions (authorizations, rulings, review of an agent-written doc) is boiled down to the questions only the owner can answer and presented through |
| `owner-gate-means-actionable-today` | A blocked_on USER: prefix means the owner can act on it today. A prerequisite mislabelled USER: renders as an owner gate and gets read back |
| `pushback-and-self-criticism` | One doctrine for disagreement. Run the checks a self-critical reply names before sending it; never prescribe softer agreement; contradict a false load-bearing premise |
| `shell` | Inline commands run zsh (never name a var `path`); trash not rm; no Glob from ~/; non-interactive flags |
| `structural-claim-without-reading-code` | Before asserting how a subsystem works (authority, data flow, hot path), name the file:line that proves it, or read the code first |
| `subagent-dispatch-prompt` | Every sub-agent dispatch prompt carries five clauses. They are a model pin, no nested seats, a scope close, an output path written before returning |
| `testing` | Test every non-trivial change scaled to task size; clean-slate checklist; verify each change independently |
| `todo-discipline` | Live todos live in the Task tool, the agent's checklist FOR THIS SESSION and what the TUI shows |
| `ui-visual-verification` | A UI claim is verified only by a rendered image read as a person would: describe the whole frame before answering any prepared question |
| `unprompted-infra-scope-creep` | Never add CI workflows, git hooks, cron jobs, or other automation infrastructure the user did not explicitly request in this task |
