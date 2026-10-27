# Adopting from its-my-claude: a guide for agents

You are an AI coding agent. Your user pointed you at this repo because they want to borrow from it. Your job is to find the parts that would actually improve their setup, let them choose, and then add the chosen parts to their config in a form that works on their machine.

This repo is one person's live Claude Code configuration (`~/.claude`). Nothing here is a package. Every file assumes the author's machine, tools and taste, so you translate rather than copy.

## Ground rules

1. **Read the user's config before you read this repo.** You cannot judge what would help until you know what they already have.
2. **Change nothing until the user has picked it and seen the diff.** Their config steers every future session, so a bad edit costs them more than it costs you.
3. **Cut every path and name that belongs to the author.** Absolute paths under `/Users/alcatraz627`, the word "owner" (it means the author), dated "owner ruling" notes, and references to private tools all have to be removed or rewritten for this user.
4. **Bring the idea, not the whole web around it.** Rules link to other rules with `[[name]]`, and scripts source shared helpers. Bring the one piece and either inline what it truly depends on or drop the link.

## Step 1: Learn the user's setup

For Claude Code, read whichever of these exist:

- `~/.claude/CLAUDE.md` and any project `CLAUDE.md` or `.claude/CLAUDE.md`
- `~/.claude/settings.json`, especially its `hooks` and `permissions` blocks
- `~/.claude/skills/*/SKILL.md` and `~/.claude/agents/*.md` (frontmatter only)

For other agents, the equivalents are `AGENTS.md`, `.cursor/rules/`, `GEMINI.md`, `.github/copilot-instructions.md`, or the tool's own config. Note what they lack, what they repeat, and which tools are installed (`rg`, `fzf`, `gum`, `trash`, `jq`, Python, Node).

## Step 2: Survey this repo through its indices

Don't read the whole tree. It holds about 2,700 files. These indices give you most of it cheaply:

| Read | What you get |
| --- | --- |
| `rules/00-index.md` | One line per behavioral rule, marked `always` (loaded every session) or `scoped` |
| `skills/*/SKILL.md`, frontmatter only | Name and one-line description of every slash command |
| `features/README.md` | Index of subsystem docs (memory, checkpoints, hooks, dev servers) |
| `conventions/README.md` | Index of output and writing standards |
| `personas/README.md` | Role prompts for the main agent or for sub-agents |
| `settings.json`, `hooks` block | Which hook script runs on which event; the scripts are in `scripts/hooks/` |
| `GLOSSARY.md` | Definitions when a term is unclear |

Open a full file only once it is a real candidate for this user.

## Step 3: Let the user choose with a wizard

Show choices to pick from instead of asking an open question. In Claude Code, use the `AskUserQuestion` tool. It takes 1 to 4 questions per call, 2 to 4 options per question, and `multiSelect: true` for multiple picks. Other agents can use a numbered list the user answers in one line.

**Round 1: what kinds of things.** One call with three questions:

| Question | Options |
| --- | --- |
| Which agent-behavior pieces interest you? (multi) | Behavioral rules · Hook guardrails · Mistake tracking · Personas |
| Which workflow pieces interest you? (multi) | Slash-command skills · Session continuity · Writing and output standards · Sub-agent dispatch |
| How should picks be added? (single) | Adapt to my setup (recommended) · Copy close to verbatim · Write them as notes only · Show me, apply nothing |

**Round 2: which items.** For each category the user picked, offer the 3 or 4 candidates you judge most useful for this user's gaps. Put your best guess first and say in each option's description what it would change for them. Batch up to four categories per call.

**Round 3: confirm the plan.** List every pick with its target file and size, and get one yes before you write anything.

## Step 4: Add each pick

For every pick, in this order:

1. Read the source file in full.
2. Rewrite it for the user: remove the author's paths, links to rules they are not taking, dated rulings and private tool names. Keep the reasoning that makes the rule persuasive.
3. Show the user a diff against their config.
4. Write the change only after they say yes. Rules go in their `CLAUDE.md` or a file it links to, skills go in `~/.claude/skills/<name>/SKILL.md`, and hooks go in a script plus a `settings.json` entry.
5. For a hook, run it once against a sample input and show the user it fires and exits the way you expect.

Agents without hooks can turn a hook into a written rule. That is weaker than a mechanical check, so tell the user.

## Starter shortlist

These carry the most value with the fewest dependencies. Start here when the user has no strong preference:

| Pick | File | Why it helps |
| --- | --- | --- |
| Run it before you say it's done | `rules/exercise-based-verification.md` | Stops "done" claims backed only by a compile or a lint |
| Cite the code before claiming how it works | `rules/structural-claim-without-reading-code.md` | Cuts confident wrong explanations |
| Search the whole tree before saying something doesn't exist | `rules/grep-scope-before-claiming-absence.md` | Prevents duplicate helpers and modules |
| Serve the goal, not the wording | `rules/literal-request-over-intent.md` | Fewer literal-minded misses |
| Don't stop to ask for permission you already have | `rules/never-halt-on-authority-you-hold.md` | Fewer needless "should I continue?" stops |
| Recoverable deletes | `scripts/safe-delete.sh` | A hook that blocks `rm` and points the agent to the macOS Trash; needs `jq`, and `scripts/hooks/shell-scan.py` for its sharper check |
| Checkpoint and resume | `skills/core-dump/` and `skills/catchup/` | Carries a task across `/clear` and context limits |
| Fresh-eyes code review | `skills/skeptical-review/` | A second agent reviews the diff before it ships |
| Plain writing | `conventions/doc-writing.md` | A checklist that strips AI-sounding prose |

## Things that won't port

- Anything that needs the author's local services: the decision-page server on port 5106, `claude-ipc`, the `i-dream` binary, Switchboard, and the kanban board.
- The `subconscious/`, `*-domain/` and `pinned/` folders. They are the author's learned state, not reusable config.
- Scripts that `source` from `scripts/tui/` or `skills/shared/`. Bring the helper with them or rewrite the few lines they use.

## When you're done

Tell the user what you added and where, what you skipped and why, and anything you could not test. Point them to this repo's `LICENSE` (MIT) if they plan to publish what they copied.
