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
updated: 2026-07-07
stale_after_days: 365
---

# Rules index

One line per behavioral rule in `rules/`. This is the menu: scan it, then read the
full `rules/<name>.md` when a rule applies to what you are about to do. DERIVED from
each rule's `brief:` frontmatter; regenerate with `bash ~/.claude/scripts/rules-index.sh`.

The **Load** column: `always` = autoloaded every session; `scoped` = NOT always-on (it
has a `paths:` block, so it loads only when Claude touches a matching file, or you must
`Read` it from this menu when it applies).

Regenerated 2026-07-07 06:41.

| Rule | Load | Gist |
|------|------|------|
| `ambiguous-file-action-halt` | always | When a write target already holds content you didn't create and the user hasn't said overwrite/append/merge, HALT and confirm — don't guess |
| `api-error-recovery` | scoped | After an API-outage abort, a terse "keep going" means re-orient first — reconstruct goal + what's done + the interrupted step — then continue, rolling back if the abort left things half-done. |
| `audience-aware-writing` | always | Writing is a UI surface with an audience. Identify the reader (human for comments/docs/PRs, agent for internal notes) and write meaning-first, never default-LLM register. |
| `audit-file-character-before-applying-global-rule` | always | Before applying a global rule or convention to a specific file/case, audit whether it actually applies — a file's character (or a load-bearing local difference) can correctly exempt it. Name the tension, don't silently apply or skip. |
| `cache-externally-mutated-state` | always | Don't cache a value that something outside your process can change — a TTL longer than "now" on externally-mutated state is a staleness bug. |
| `comments` | always | Comments are for humans first, AI agents second, machines never; first sentence of a non-trivial docstring is code-agnostic; keep [claude@] agent-notes separate from human comments; no plan-refs or archeology |
| `communication` | always | Terse protocol, scope control, state verification — how Claude talks, scopes, and verifies before side-effects |
| `contain-subagent-token-sprawl` | always | Orchestration (sub-agents, fan-out workflows) has real cumulative token cost — right-size it. Inline small/mechanical work, reserve fan-out for genuinely large/parallel/verification-heavy work, and watch cumulative spend across a session. Even under ultracode, right-size rather than reflexively orchestrate. |
| `corrections` | always | After user corrections: state mistake, identify pattern, update mistake-patterns.md, check for hook, fix |
| `cron-calendar-companion` | always | Every recurring scheduled job (launchd plist, crontab line, or harness CronCreate) MUST get a companion recurring macOS Calendar event so the human can SEE the automation exists and notice when it silently stops firing. Retiring a cron means removing its event too. |
| `env-var-config-pattern` | scoped | Before adding a raw env var read, grep how existing vars are read in the project — route through the central config module/schema if one exists, don't scatter raw reads |
| `error-classification` | scoped | Never regex-match a string error message to drive selector logic — propagate a structured code instead |
| `exercise-based-verification` | always | Run the code in the state that matters before declaring done — collecting/compiling/linting is not running. Enforced by the declared-ready Stop hook. |
| `generalize-before-enumerate` | always | Before writing a helper/abstraction that handles "all cases", enumerate the actual cases first — if you can't list them, you don't understand the domain well enough to abstract |
| `git` | always | Frequent commits, public repos by default, .gitignore patterns, never push main without approval |
| `grep-scope-before-claiming-absence` | always | Grep the FULL relevant tree (not just one subdir) before claiming a module/function/helper doesn't exist or proposing to create one |
| `helper-return-type-assumption` | always | Before calling a method on a helper's return value, grep the helper's definition — don't assume its shape |
| `js-escape-sequences-in-template-literals` | scoped | JS inside server-side backtick template literals needs DOUBLE escapes; `node --check` won't catch it; verify in a real browser |
| `never-modify-anthropic-credentials` | always | NEVER set/modify/rotate/unset the Anthropic API key or any global-blast-radius credential — a bad value crashes EVERY Claude instance at once. Stop and ask the user to do it by hand. |
| `performative-self-criticism` | always | Under pushback, a structured self-critical reply (ranked table, insight block, named-pattern list) is not the work — it's a description of the work. Run the checks it names before sending, or you're performing thoroughness instead of doing it. |
| `prescribed-flattery-as-fix-for-pushback` | always | Don't prescribe softer agreement as a "fix" for user-perceived pushback unless the user explicitly asked for softer framing — capitulation is the failure, not the fix |
| `proposed-fix-breaks-design-invariant` | always | Treat a design doc's goals/constraints section as a checklist, not background — before writing "mode A trades X for Y" framing, verify no consumer-rendered field diverges against a stated constraint |
| `pushback-honesty` | always | When a user states something demonstrably wrong that would drive a wrong implementation, push back with evidence (file:line / measurement / spec) before complying — don't silently execute on a false premise. The positive-form completion of the prescribed-flattery + performative-self-criticism pair. |
| `right-sized-code` | always | Right-size code to the task, don't blindly minimize — gate the decision on goal shape, scope, stated intent, and total-cost fit, then climb the laziness ladder inside that gate. Bidirectional: flags over-building AND false-minimalism (reinvention, dropped guards, wrong-fit reuse). |
| `scheduling-discipline` | always | Cross-tool scheduling practice — discipline that applies whether you use gcc-schedule, hand-built launchd plists, or other schedulers. Naming, retire-after-fire, secrets, calendar companion, when-to-use-which-scheduler. Distinct from INSTRUCTIONS.md which is gcc-schedule-tool-specific. |
| `shell` | always | Resolve project root before Glob/Grep; trash not rm; non-interactive flags; background task hygiene |
| `skill-spec-update-not-honored-by-running-session` | always | A mid-session SKILL.md change that adds a mandatory phase is advisory-only to sessions started before it — enforce at the data-write CLI, not the spec, or it's silently bypassable |
| `speculative-abstractions-without-a-load-bearing-caller` | always | Don't create a helper/constant/type for a planned-but-nonexistent future caller — inline at the real callsite when you build it; let abstractions crystallize from ≥2 real callsites |
| `structural-claim-without-reading-code` | always | Before asserting how a subsystem works (authority, data flow, hot path), name the file:line that proves it — or read the code first |
| `structure-over-one-shotting` | always | Default to plan→implement→review on non-trivial work; a failed one-shot wastes more than structure would have. One-shotting is fine only for genuinely trivial one-offs. |
| `sub-agent-outputs` | always | Sub-agents producing material content (research, analysis, audit, synthesis) MUST write the full output to disk before returning. Their summary is not a substitute for the artifact. |
| `subagent-fleet-discipline` | scoped | When a parallel sub-agent fleet hits a transient API throttle, salvage finished work, re-dispatch only the dead, and throttle to batches on a second outage. |
| `subagent-model-ceiling` | always | Sub-agents are NEVER dispatched on the session flagship model (Fable/Mythos-class) — Opus is the hard ceiling for any sub-agent at any nesting depth; every dispatch pins model explicitly (sonnet default, opus only for judgment-heavy work) and must gate nested spawns |
| `surface-hook-nudges-to-user` | always | When a PreToolUse hook injects an advisory nudge (additionalContext), surface it to the user in your reply as a bordered callout — it's invisible to them otherwise |
| `testing` | always | Test every non-trivial change scaled to task size; clean-slate checklist; verify each change independently |
| `todo-discipline` | always | Live todos live in the Task tool (source of truth + TUI); session-notes/memory are auto-mirrors, never hand-edited; plans in docs are complementary not the status surface |
| `trusted-linter-reminder` | always | A "file modified by linter" system-reminder still needs a diff check — linters reformat; they don't change runtime semantics |
