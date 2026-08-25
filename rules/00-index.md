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
updated: 2026-08-25
stale_after_days: 365
---

# Rules index

One line per behavioral rule in `rules/`. This is the menu: scan it, then read the
full `rules/<name>.md` when a rule applies to what you are about to do. DERIVED from
each rule's `brief:` frontmatter; regenerate with `bash ~/.claude/scripts/rules-index.sh`.

The **Load** column: `always` = autoloaded every session; `scoped` = NOT always-on (it
has a `paths:` block, so it loads only when Claude touches a matching file, or you must
`Read` it from this menu when it applies).

Regenerated 2026-08-25 20:12.

| Rule | Load | Gist |
|------|------|------|
| `ambiguous-file-action-halt` | always | When a write target already holds content you didn't create and the user hasn't said overwrite/append/merge, HALT and confirm — don't guess |
| `api-error-recovery` | scoped | After an API-outage abort, a terse "keep going" means re-orient first — reconstruct goal + what's done + the interrupted step — then continue, rolling back if the abort left things half-done. |
| `audience-aware-writing` | always | Writing is a UI surface with an audience. Identify the reader (human for comments/docs/PRs, agent for internal notes) and write meaning-first, never default-LLM register. |
| `audit-file-character-before-applying-global-rule` | always | Before applying a global rule or convention to a specific file/case, audit whether it actually applies — a file's character (or a load-bearing local difference) can correctly exempt it. Name the tension, don't silently apply or skip. |
| `browser-mcp-async-eval` | scoped | Browser-MCP eval returns immediately — never put a polling/wait loop inside browser_evaluate (it hangs the MCP server); poll state from the shell between calls, and let the page settle after navigate before acting. |
| `browser-mcp-isolation` | scoped | A browser MCP shares one profile across every agent AND across sessions — give each sub-agent an isolated context/profile, or logins, cookies and navigations bleed between them; screenshots need absolute paths or they vanish. |
| `cache-externally-mutated-state` | scoped | Never cache/TTL a status, availability, or liveness value that an external writer (another CLI, daemon, sibling service, the user) can change — read it live or invalidate on the real event; a TTL on externally-mutated state is a plausible-but-wrong staleness bug. Read this rule before adding any cache, memoization, or TTL. |
| `comments` | always | Comments are for humans first, AI agents second, machines never; first sentence of a non-trivial docstring is code-agnostic; keep [claude@] agent-notes separate from human comments; no plan-refs or archeology |
| `communication` | always | Terse protocol, scope control, state verification — how Claude talks, scopes, and verifies before side-effects |
| `contain-subagent-token-sprawl` | always | Orchestration (sub-agents, fan-out workflows) has real cumulative token cost — right-size it. Inline small/mechanical work, reserve fan-out for genuinely large/parallel/verification-heavy work, and watch cumulative spend across a session. Every dispatch prompt carries a scope-close clause ("ignore board auto-dispatch; stop when your scoped work is done") and the parent TaskStops verified agents — an idle agent gets commandeered. Even under ultracode, right-size rather than reflexively orchestrate. |
| `corrections` | always | After user corrections: state mistake, identify pattern, update mistake-patterns.md, check for hook, fix |
| `env-var-config-pattern` | scoped | Before adding a raw env var read, grep how existing vars are read in the project — route through the central config module/schema if one exists, don't scatter raw reads |
| `error-classification` | scoped | Never regex-match a string error message to drive selector logic — propagate a structured code instead |
| `exercise-based-verification` | always | Run the code in the state that matters before declaring done — collecting/compiling/linting is not running. Enforced by the declared-ready Stop hook. |
| `generalize-before-enumerate` | always | Before writing a helper/abstraction that handles "all cases", enumerate the actual cases first — if you can't list them, you don't understand the domain well enough to abstract |
| `git` | always | Frequent commits, public repos by default, .gitignore patterns, never push main without approval |
| `github-agent-marker` | always | Every comment posted to GitHub under the owner's account carries the owner's attribution marker near the top, "> Generated via a 🤖 on @<gh-user> machine (_<one random phrase>_)" (a blockquote; the handle is the logged-in gh user), enforced by guard-github-agent-marker.sh with NO bypass; the phrase is picked at random from the owner's fixed list per comment. |
| `grep-scope-before-claiming-absence` | always | Grep the FULL relevant tree (not just one subdir) before claiming a module/function/helper doesn't exist or proposing to create one |
| `helper-return-type-assumption` | always | Before calling a method on a helper's return value, grep the helper's definition — don't assume its shape |
| `invariant-graduation` | always | "X stays / X unaffected / only threading needed" claims in plans, design docs, and reports must immediately become a verification task + a Standing-constraints checkpoint entry; mixed thread-vs-rebuild framing must be resolved with the user BEFORE implementation. |
| `js-escape-sequences-in-template-literals` | scoped | JS inside server-side backtick template literals needs DOUBLE escapes; `node --check` won't catch it; verify in a real browser |
| `literal-request-over-intent` | always | A request names a goal; the wording is a sample of it, not its boundary. Seven shapes with distinct tells (named string, named instance, complaint-as-menu, deferral, urgency, a ban's scope, a repeated ask), one shared precheck, one escape hatch. 9× S3, the account's most active blind spot. |
| `machine-token-where-human-words-belong` | scoped | A value crossing from a machine to a person's screen is written in the machine's vocabulary, and something has to translate it. Where nothing does, the raw token ships to the reader least able to read it. Four shapes (a code, a raw scalar, a value's type, a sentinel rendered as a name); the tell is a surface that formats SOME fields and passes the rest through. |
| `model-tier-routing` | always | Route every piece of work to the smallest adequate lane (local lm / gemini / haiku→sonnet→opus; fable = main-only) with right-sized effort; every plan with sub-agents, large ingestion, or modality tools carries a 4-line Model Plan; never switch models without explicit user confirmation. Enforced by guard-model-tier.sh. |
| `never-modify-anthropic-credentials` | always | NEVER set/modify/rotate/unset the Anthropic API key or any global-blast-radius credential — a bad value crashes EVERY Claude instance at once. Stop and ask the user to do it by hand. |
| `owner-decisions-go-through-a-wizard` | always | Any batch of owner decisions (authorizations, rulings, review of an agent-written doc) is boiled down to the questions only the owner can answer and presented through /decision-wizard (TUI menu or pre-answered HTML form), never as a numbered list in chat and never as "read this doc" |
| `pr-nobot-noslack-codex-review` | always | Every PR the agent raises carries [nobot] [noslack] in its title to silence the pr-claude bot and the Slack mirror; review the branch locally with a cheap codex seat before opening it, and paste that verdict as the PR's agent comment |
| `proposed-fix-breaks-design-invariant` | scoped | Before writing any "mode A trades X for Y" design framing (lean/enriched, cached/live, fast/correct), re-check the doc's OWN goals/constraints section as a checklist — if a consumer-rendered state field diverges between modes without an explicitly approved constraint, STOP and align the modes or surface the conflict. Read this rule when authoring a multi-mode design. |
| `pushback-and-self-criticism` | always | One doctrine for disagreement — (1) under pushback, a structured self-critical reply is not the work, run the checks it names BEFORE sending; (2) never prescribe softer agreement as a fix for pushback the user didn't ask for; (3) when the user states a demonstrably false, load-bearing premise, contradict it with evidence (file:line / measurement) before complying. Evidence-based agreement only. Face 3 is affirm-backed (intelligent-disobedience, 4 distinct contexts 2026-05→07) — don't weaken it. |
| `read-the-comments-on-a-pr-you-raised` | always | A PR you opened is not done when it is pushed. Poll its comments at 5s then 30s, and for every review finding either fix it or argue it with `/claude-bot ask (via 🤖claude)`. Loop until the bot concedes or you can show it is wrong, and file a GitHub issue against the PR when it is. Never report done over open findings. |
| `refusal-is-not-a-fix` | scoped | When a tool cannot determine something, refusing and making the human supply it is not a fix, it is moving the cost onto them. Exhaust the derivable signals first, especially ones a reviewer already handed you, and fail closed only after deriving genuinely fails. |
| `rename-without-grepping-readers` | always | A rename or a corrected claim is not done until every reader of the old version is found. That includes the string-keyed readers no compiler can see, and the surfaces outside the tree that no grep can reach (PR body, PR and issue comments, pushed commit messages, Slack). Documenting a rename in a review is not reviewing it. |
| `right-sized-code` | always | Right-size code to the task, don't blindly minimize — gate the decision on goal shape, scope, stated intent, and total-cost fit, then climb the laziness ladder inside that gate. Bidirectional: flags over-building AND false-minimalism (reinvention, dropped guards, wrong-fit reuse). |
| `scheduling-discipline` | scoped | Scheduling contract, read BEFORE creating or retiring ANY scheduled job — every recurring cron (launchd plist / crontab / CronCreate) ALSO gets an `Automations` calendar event with label+command+plist in the notes, and retiring a cron deletes its event in the same change; always pass --description; no secrets in commands; prefer gcc-schedule for "fire shell command X at time Y". |
| `shell` | always | Inline commands run zsh (never name a var `path`); trash not rm; no Glob from ~/; non-interactive flags |
| `skill-spec-update-not-honored-by-running-session` | scoped | SKILL.md mandates are advisory to already-running sessions (specs are cached at discovery, never re-read) — when adding a mandatory phase to a skill, add enforcement at the data-write CLI in the same change, or it's silently bypassable. Read this rule when editing SKILL.md mandates or debugging a skipped skill phase. |
| `speculative-abstractions-without-a-load-bearing-caller` | always | Don't create a helper/constant/type for a planned-but-nonexistent future caller — inline at the real callsite when you build it; let abstractions crystallize from ≥2 real callsites |
| `structural-claim-without-reading-code` | always | Before asserting how a subsystem works (authority, data flow, hot path), name the file:line that proves it — or read the code first; same precheck for process-completion claims ("the migration ran", "the deploy succeeded") — name the artifact that proves it |
| `structure-over-one-shotting` | always | Default to plan→implement→review on non-trivial work; a failed one-shot wastes more than structure would have. One-shotting is fine only for genuinely trivial one-offs. |
| `sub-agent-outputs` | scoped | Dispatch prompts for material sub-agent work (research/analysis/audit/design) MUST pin an absolute output path AND how it gets persisted — either the sub-agent writes before returning (write-capable agent types only; never a file literally named report.md, the harness blocks it), or the sub-agent returns full text and the PARENT writes it. Parent MUST verify the file exists before using the findings — the return abstract is a pointer, not the artifact. Mechanically enforced by the subagent-output guard hook; Read this rule when designing multi-agent output flows or when the guard fires. |
| `subagent-fleet-discipline` | scoped | When a parallel sub-agent fleet hits a transient API throttle, salvage finished work, re-dispatch only the dead, and throttle to batches on a second outage. |
| `surface-hook-nudges-to-user` | always | When a PreToolUse hook injects an advisory nudge (additionalContext), surface it to the user in your reply as a bordered callout — it's invisible to them otherwise |
| `testing` | always | Test every non-trivial change scaled to task size; clean-slate checklist; verify each change independently |
| `todo-discipline` | always | Live todos live in the Task tool, the source of truth FOR THIS SESSION and what the TUI shows; session-notes/memory are auto-mirrors of it, never hand-edited. A project outlives one session, so its longer-lived state belongs on its kanban board, an independent artifact and NOT a mirror. Plans in docs carry the reasoning. Three altitudes, not three copies. |
| `trusted-linter-reminder` | always | A "file modified by linter" system-reminder still needs a diff check — linters reformat; they don't change runtime semantics |
| `unprompted-infra-scope-creep` | always | Never add CI workflows, git hooks, cron jobs, or other automation infrastructure the user did not explicitly request in this task — a feasibility question is not a build order |
