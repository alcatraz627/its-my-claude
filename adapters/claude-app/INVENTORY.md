# What carries into chat, and what does not

Every rule, guide, skill, persona and template in this repo, with where it
landed in the `gcc-chat` plugin or why it stayed out. A new file in the repo
gets a row here when it is ported or ruled out.

Chat can run code in a sandbox, render HTML, search the web, read images and
use connectors (Linear, Drive, GitHub, Slack, Figma). It cannot read
`~/.claude`, run local scripts, fire hooks or start sub-agents. Those limits
decide nearly every "stays out" row.

| Status | Meaning |
|---|---|
| ported | Has its own skill |
| merged | Folded into the skill named |
| profile | Lives in `profile-instructions.md`, always on |
| out | Not ported, for the reason given |

## Rules (`rules/`)

| Rule | Status | Where, or why not |
|---|---|---|
| `absolute-paths-at-the-reader-boundary` | out | Terminal click-through. Chat has no local paths |
| `added-scope-without-checking-siblings` | merged | `code-rules` |
| `ambiguous-file-action-halt` | merged | `house-rules`, "Before overwriting something you did not write" |
| `api-error-recovery` | out | Claude Code session recovery |
| `audience-aware-writing` | merged | `plain-writing` |
| `audit-file-character-before-applying-global-rule` | merged | `code-rules` |
| `browser-mcp-async-eval`, `browser-mcp-isolation` | out | Local browser MCP |
| `cache-externally-mutated-state` | merged | `code-rules` |
| `comments` | merged | `code-rules` |
| `communication` | profile | ANSWER SHAPE, QUESTIONS AND DECISIONS |
| `contain-subagent-token-sprawl` | out | No sub-agents in chat. The word `sprawl` is in the profile |
| `corrections` | out | Runs through atone, which is local |
| `dense-briefing-direct-answer` | profile | ANSWER SHAPE |
| `env-var-config-pattern` | merged | `code-rules` |
| `error-classification` | merged | `code-rules` |
| `examples-as-quotas` | merged | `house-rules` |
| `exercise-based-verification` | merged | `house-rules`, profile NO BULLSHIT |
| `flag-coupled-dependencies` | merged | `house-rules`, profile |
| `generalize-before-enumerate` | merged | `house-rules` |
| `git` | merged | `code-rules` |
| `github-agent-marker` | out | Local posting hook |
| `goal-statement-on-starting-work` | out | `/goal` is a Claude Code command |
| `grep-scope-before-claiming-absence` | merged | `house-rules`, profile |
| `helper-return-type-assumption` | merged | `code-rules` |
| `human-note-preferences` | merged | `code-rules` |
| `invariant-graduation` | merged | `house-rules` |
| `js-escape-sequences-in-template-literals` | merged | `code-rules` |
| `literal-request-over-intent` | profile | INTENT OVER WORDING |
| `machine-token-where-human-words-belong` | merged | `code-rules` |
| `model-tier-routing` | out | Local model lanes |
| `never-halt-on-authority-you-hold` | profile | "Never stop with the next work named and undone" |
| `never-modify-anthropic-credentials` | out | Local credentials |
| `no-opaque-login-items` | out | macOS LaunchAgents |
| `no-self-permitted-exceptions` | merged | `house-rules`, "When a rule blocks the request" |
| `no-silent-ui-surface-deletion` | merged | `code-rules` |
| `no-unasked-artifact-publish` | out | Chat artifacts are private by default |
| `owner-decisions-go-through-a-wizard` | merged | `decision-bundle` |
| `owner-gate-means-actionable-today` | merged | `recommend`, profile |
| `pr-nobot-noslack-codex-review` | out | Per-repo bot tags |
| `proposed-fix-breaks-design-invariant` | merged | `code-rules` |
| `pushback-and-self-criticism` | merged | `house-rules`, profile |
| `read-the-comments-on-a-pr-you-raised` | merged | `house-rules`, "After raising a pull request" |
| `refusal-is-not-a-fix` | merged | `house-rules` |
| `rename-without-grepping-readers` | merged | `code-rules` |
| `right-sized-code` | merged | `code-rules` |
| `scheduling-discipline` | out | Local cron |
| `shell`, `shell-reference` | out | zsh and macOS shell gotchas |
| `size-the-change-in-the-target-vocabulary` | merged | `house-rules` |
| `skill-spec-update-not-honored-by-running-session` | out | Claude Code skill caching |
| `speculative-abstractions-without-a-load-bearing-caller` | merged | `code-rules` |
| `stale-belief-as-current-state` | merged | `house-rules`, profile |
| `structural-claim-without-reading-code` | merged | `house-rules`, profile |
| `structure-over-one-shotting` | profile | ABOUT ME, `one-shotting` |
| `sub-agent-outputs`, `subagent-dispatch-prompt`, `subagent-fleet-discipline` | out | No sub-agents in chat |
| `surface-hook-nudges-to-user` | out | No hooks in chat |
| `testing`, `testing-patterns` | merged | `code-rules` |
| `todo-discipline` | out | Task tool |
| `trusted-linter-reminder` | merged | `code-rules` |
| `ui-visual-verification` | merged | `code-rules`, `ui-critique` |
| `unprompted-infra-scope-creep` | merged | `intake`, scope ceiling ("new infrastructure") |

## Guides (`conventions/`)

| Guide | Status | Where, or why not |
|---|---|---|
| `doc-writing` | merged | `plain-writing` (voice, AI tells), `write-docs` (structure, templates, report tier) |
| `language-quality` | merged | `plain-writing/references/language-quality.md` |
| `ste-writing` (skill) | merged | `plain-writing` |
| `readme-template`, `rca-template`, `github-markdown`, `report-writing` | merged | `write-docs/references/` |
| `ascii-diagrams` | ported | `diagrams` |
| `visual-design`, `ui-charter`, `mobile-ux-pattern-palette`, `html-output`, `html-assets/` | ported | `design-reference` |
| `cli-help-design`, `tui-design`, `agent-first-tools`, `run-and-observe-affordance`, `dashboard-tools` | ported | `tool-design` |
| `shipped-checks-serve-the-author` | merged | `code-rules` |
| `callout-boxes` | out | Renders through a local `box` script in the terminal |
| `tui-handbook` | out | Built on the local `scripts/tui/` library. The library-free parts are in `tool-design` |
| `absence-run-checklist`, `large-external-list-scan` | out | Unattended multi-agent runs |
| `asset-management`, `doc-naming`, `scratch-files`, `gcc-hygiene`, `preference-graduation`, `hook-authoring-and-review`, `mods-handbook`, `pages`, `cli-gating.json` | out | How the local config itself is kept |

## Skills (`skills/`)

| Skill | Status | Where, or why not |
|---|---|---|
| `intake`, `probe`, `recommend`, `arch-qa`, `pr-description`, `quiz`, `mock-app`, `svg`, `write-docs`, `feature-doc-set`, `deck`, `persona`, `gdoc`, `file-gh-issue` | ported | Same name |
| `gated-plan` | ported | `decision-bundle` |
| `decision-wizard` | merged | `decision-bundle` (numbered answers replace the local page) |
| `skeptical-review`, `adversarial-review` | merged | `skeptical-review` |
| `validate` | merged | `house-rules`, "Before calling work done" (name each question, answer it with a check) |
| `callouts` | merged | `house-rules`, "When the user calls out a defect" |
| `build-change`, `build-ui`, `plan` | merged | `change-plan` |
| `magi` | ported | `council` |
| `ui-gripe`, `web-design`, `designer-reviewer`, `vis-compare`, `ui-categorical-check` | merged | `ui-critique` |
| `ui-direction` | merged | `mock-app` |
| `ui`, `router`, `pick-skill` | out | Routers over the local roster. Chat routes by skill description |
| `create-report`, `generate-pdf` | ported | `html-report` (13 report styles, 3 PDF styles) |
| `word-doc` | merged | `write-docs/references/word-doc-structure.md`. The file itself comes from claude.ai's built-in docx skill |
| `readme` | merged | `write-docs` |
| `cleanup-comments` | merged | `code-rules` |
| `create-skill`, `improve-skill`, `roster-budget` | ported | `skill-craft` |
| `linear` | ported | `linear-ops`, through the Linear connector |
| `ste-writing` | merged | `plain-writing` |
| `deep-research` | out | claude.ai has its own deep-research skill |
| `summarize-changes` | out | Reads local git, WAL and checkpoints |
| `ui-loop` | out | Needs a live page and the local `see` CLI |
| `deadline`, `directions`, `tasks`, `blitz`, `bloop` | out | Drive the local goal store, kanban and long unattended runs |
| `core-dump`, `catchup`, `retro-dump`, `revive`, `workspace`, `wake` | out | Session checkpoints on local disk. Chat keeps its own history |
| `atone`, `affirm`, `preference-graduation`, `pin-for-dream`, `gcc-proposal`, `gcc-map`, `gcc-explore`, `backlog-triage`, `tag`, `migrate`, `plugs`, `doctor` | out | Maintain the local config |
| `ipc`, `kanban`, `subagent`, `codex-handback`, `session-stats`, `test`, `deploy-parity-testing`, `pyramid-sweep` | out | Need local processes, sub-agents or a shell |
| `banner`, `banner-fun` | out | Terminal output |
| `generate-image` | out | Local image model. `persona` (art director) writes prompts instead |
| `create-agent` | out | Unattended agents are a Claude Code feature |
| `linear` references `versable.md` | merged | `linear-ops`, team conventions only |

## Parked skills (`skills-parked/`)

| Skill | Status | Why |
|---|---|---|
| `diagram` | merged | `diagrams` |
| `dep-audit`, `type-audit`, `route-audit`, `invalidate-audit`, `sync-api-types`, `visual-regression` | out | Run tools over a local checkout |
| `clean-html` | out | Downloads media to disk |
| everything else (`add-mcp`, `apple`, `archive-notes`, `autocorrect`, `capabilities`, `cogitate`, `context-prime`, `daily-todo`, `describe`, `forgotten-todos`, `git-setup`, `gotchas-update`, `improve-config`, `mini`, `new-migration`, `past-sessions`, `project-index`, `scaffold`, `scan-sessions`, `shell-mem`, `statusline`, `statusline-config`, `thesaurus`, `user-config`) | out | Parked locally too, or local-config maintenance |

## Personas (`personas/`)

| Persona | Status | Where |
|---|---|---|
| `closer`, `platform-builder`, `pragmatist` | merged | `council` lenses |
| `greybeard`, `translator`, `pager-holder` | merged | `doc-review-panel` readers |
| `researcher`, `data-engineer`, `fullstack-engineer`, `task-goal-planner`, `technical-doc-writer`, `web-researcher`, `art-director`, `motion-illustrator` | ported | `persona` |
| `skeptical-reviewer`, `doc-writer`, `readers-advocate`, `juror` | ported | `persona`, as review modes |

## Vocabulary, memory and features

| Source | Status | Where, or why not |
|---|---|---|
| `GLOSSARY.md` §User Shorthand, `style/glossary-hints.tsv` | profile | MY SHORTHAND, with a source table in `profile-instructions.md` |
| `GLOSSARY.md` abbreviations, namespace labels, file conventions | out | Name parts of the local config |
| `memory/global/feedback_*` (efficacy, challenge asks, maximalist vs ambitious, safety nets, asks keep context, structure over one-shot) | profile | ABOUT ME, INTENT OVER WORDING |
| `memory/global/user_profile.md` | out | Terminal setup, irrelevant in chat |
| `features/prose-and-voice.md` | merged | `plain-writing` |
| every other `features/*.md` | out | Each documents a local subsystem (WAL, hooks, kanban, dev servers, tab title, usage gates) |
| `settings.json` hooks | out | Chat runs no hooks. The Desktop Code tab can, through a separate plugin |
| `mistake-patterns.md` top five | profile | NO BULLSHIT lines on reading before claiming, re-checking status, deriving values |
