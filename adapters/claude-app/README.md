# gcc-chat: this config for claude.ai chat

A plugin carrying the parts of this config that work without local scripts,
for claude.ai on the web, the desktop app's chat, and Claude Code. It holds
skills only. Claude loads each skill when a conversation matches its
description, or you pick one from the `/` menu.

| Skill | Loads when | Source in this repo |
|---|---|---|
| `house-rules` | Claiming how something works, calling work done, claiming absence, sizing a change, pushing back | `rules/` (11 rules, condensed) |
| `plain-writing` | Drafting or cleaning up docs, READMEs, reports, PR text, emails | `conventions/doc-writing.md`, `skills/ste-writing/` |
| `intake` | Before non-trivial work, or when the last answer missed | `skills/intake/` |
| `probe` | A fix did not work or a cause is a guess | `skills/probe/` |
| `decision-bundle` | Work is blocked on the user's decisions | `skills/gated-plan/` |
| `recommend` | "What now", "what do you need from me" | `skills/recommend/` |
| `skeptical-review` | Reviewing code, a diff, or work someone called done | `skills/skeptical-review/`, `skills/adversarial-review/` |
| `arch-qa` | "How does X work" in a codebase you paste or connect | `skills/arch-qa/` |
| `change-plan` | Planning a code change with a check behind every step | `skills/build-change/` |
| `pr-description` | Writing a PR body from a real diff | `skills/pr-description/` |
| `council` | An architecture or "should we" decision | `skills/magi/`, `personas/` strategic lenses |
| `doc-review-panel` | Reviewing a doc as engineer, PM and on-call reader | `personas/` greybeard, translator, pager-holder |
| `quiz` | Checking you understand something Claude built | `skills/quiz/` |
| `ui-critique` | Critiquing or comparing UI screenshots | `skills/ui-gripe/`, `web-design/`, `designer-reviewer/`, `vis-compare/`, `ui-categorical-check/` |
| `mock-app` | A clickable HTML mock, or variants side by side | `skills/mock-app/`, `skills/ui-direction/` |
| `svg` | An icon, logo or diagram as SVG | `skills/svg/` |
| `code-rules` | Writing or changing code: comments, tests, sizing, errors, env vars, git, renames | 20 rules from `rules/`, `skills/cleanup-comments/` |
| `write-docs` | A README, RCA, ADR, changelog, reference doc or Word-style doc | `skills/write-docs/`, `skills/readme/`, `conventions/` templates |
| `feature-doc-set` | The doc set for a feature PR | `skills/feature-doc-set/` |
| `diagrams` | Explaining a flow, architecture or state machine | `conventions/ascii-diagrams.md`, parked `diagram` |
| `design-reference` | Designing or restyling a visual surface | `conventions/visual-design.md`, `ui-charter.md`, `mobile-ux-pattern-palette.md`, `html-output.md`, `html-assets/` |
| `tool-design` | Designing a CLI, TUI, small dashboard or agent-driven tool | `conventions/cli-help-design.md`, `tui-design.md`, `agent-first-tools.md`, `dashboard-tools.md` |
| `html-report` | A styled HTML report or PDF from markdown or findings | `skills/create-report/` (13 styles), `skills/generate-pdf/` (3 styles) |
| `deck` | An HTML slide deck with presenter notes | `skills/deck/` |
| `persona` | Working in a named mode: researcher, planner, doc writer, art director and others | `personas/` (12) |
| `skill-craft` | Writing or improving a skill for this plugin | `skills/create-skill/`, `improve-skill/`, `GUIDELINES.md` |
| `linear-ops` | Reading or changing Linear through the connector | `skills/linear/` |
| `gdoc` | Publishing markdown as a Google Doc through Drive | `skills/gdoc/` |
| `file-gh-issue` | Filing a small GitHub issue through the connector | `skills/file-gh-issue/` |

`INVENTORY.md` lists every rule, guide, skill and persona in this repo with
where it landed or why it stayed out.

Rules about how answers are shaped (answer first, intent over wording, no
needless halts) are not here. They live in the claude.ai profile Instructions,
which load into every conversation already. The paste-ready text is in
`profile-instructions.md` in this folder.

## Install

1. Open [claude.ai/customize/plugins](https://claude.ai/customize/plugins).
2. Select **Add**, then **Add marketplace**, and enter `alcatraz627/its-my-claude`.
3. Find `gcc-chat` in the list and select **Add**.
4. Turn on **Sync automatically** for the marketplace, so pushes to `main`
   reach your account without another step.

To check it worked, start a new chat, type `/`, then `gcc-chat`. All 29
skills should be listed.

## Turn it off

**Customize > Plugins > gcc-chat**, then the **Disable plugin** toggle. That
applies to your whole account, not one surface.

## Change it

Edit a `SKILL.md` here and push to `main`. Keep each `description` at 200
characters or fewer, because claude.ai cuts longer ones. Check the plugin
before pushing:

```bash
claude plugin validate .
```

Run that from the repo root. A skill that needs `~/.claude/scripts/`, a local
port or a Mac-only tool does not belong here, because chat cannot run it.
