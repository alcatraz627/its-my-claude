<!--
Agents working inside ~/.claude: this page is for people browsing the repo on GitHub,
and it repeats what you already have. Start from CLAUDE.md and LOOKUP.md instead.
-->

<p align="center">
  <img src=".github/hero-workshop.svg" alt="its-my-claude: a pixel workshop with a rules bookshelf, a skills pegboard, the agent at a desk under a CLAUDE.md orrery, the dream engine asleep on a couch, and a hook guard at the door" width="100%">
</p>

<p align="center">
  A personal Claude Code configuration that learns from its own mistakes.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License: MIT">
  <img src="https://img.shields.io/badge/skills-82-blue" alt="82 skills">
  <img src="https://img.shields.io/badge/rules-67-blue" alt="67 rules">
  <img src="https://img.shields.io/badge/hook%20scripts-198-blue" alt="198 hook scripts">
  <img src="https://img.shields.io/badge/shell-bash%20%7C%20zsh-lightgrey" alt="Shell: bash, zsh">
</p>

---

## What is this?

This is the `~/.claude` directory of one developer, versioned in public. Claude Code reads this folder at the start of every session, so everything here shapes how the agent behaves: what it must always do, what it must never do, which slash commands exist, and which shell hooks watch its tool calls.

The idea that ties it together is a feedback loop. When the agent gets something wrong and gets corrected, the mistake is logged, and a pattern that keeps coming back graduates into a written rule. A rule that still gets broken earns a hook that catches the slip mechanically. Most files in this repo are a step somewhere along that path.

<p align="center">
  <img src=".github/banner-factory.svg" alt="A conveyor belt: a correction drops a red crate, the /atone desk stamps it, a press turns it into a rule, and the hook forge hammers it into a green shield" width="100%">
</p>

## Agent prompt

```text
Clone https://github.com/alcatraz627/its-my-claude to a temp folder.
Follow its ADOPT.md to suggest additions to my agent config.
Change nothing I have not picked.
```

## Architecture

```
   session starts
         │
         ▼
 ┌────────────────┐   always loaded   ┌──────────────────────────┐
 │   CLAUDE.md    │──────────────────▶│ rules/  (always/scoped)  │
 └───────┬────────┘                   └──────────────────────────┘
         │ points to
         ▼
 ┌────────────────┐  on demand  ┌───────────────────────────────┐
 │ LOOKUP.md etc. │────────────▶│ features/  conventions/       │
 └────────────────┘             └───────────────────────────────┘

   every prompt ──▶ hinters/        (UserPromptSubmit nudges)
   every tool call ──▶ scripts/hooks/  (wired in settings.json)
   /slash-command ──▶ skills/<name>/SKILL.md

   correction ──▶ /atone log ──▶ repeated? ──▶ rules/ ──▶ still slips? ──▶ hook
```

Rules say what to do, features say how a subsystem works, conventions say what output should look like. `PLACEMENT.md` is the tiebreaker when something could go in more than one place.

## Quick start

There is nothing to install. This repo is meant to be read and borrowed from.

```bash
git clone https://github.com/alcatraz627/its-my-claude.git   # browse locally
cat its-my-claude/rules/00-index.md                           # one line per rule
ls its-my-claude/skills                                       # one folder per slash command
```

> [!WARNING]
> Do not clone this over your own `~/.claude`. `settings.json` wires about two hundred hook commands to scripts at the author's home path, and several hooks depend on tools and services that live outside this repo (see `PORTABILITY.md`). Copy the individual pieces you want instead.

## By what you came to do

| You want to | Start here |
| --- | --- |
| See the top-level instructions the agent gets | `CLAUDE.md` |
| Browse behavioral rules | `rules/00-index.md`, with the reasoning behind each in `rules-provenance/` |
| Borrow a slash command | `skills/<name>/SKILL.md` (82 active), retired ones in `skills-parked/` |
| See how hooks enforce rules | `scripts/hooks/` and the `hooks` block of `settings.json` |
| Understand a subsystem | `features/README.md` |
| Copy an output or authoring standard | `conventions/README.md` |
| Look up a term you keep seeing | `GLOSSARY.md` |
| Find where anything lives | `LOOKUP.md` and `FOLDERS.md` |

## Documentation

> [!TIP]
> Read in this order: `CLAUDE.md`, then `rules/00-index.md`, then `GLOSSARY.md` for the vocabulary. Everything else is reached from those three.

| Document | What it covers |
| --- | --- |
| [ADOPT.md](ADOPT.md) | How an agent picks pieces of this repo and adapts them to your config |
| [CLAUDE.md](CLAUDE.md) | The always-loaded instructions: core rules, mechanisms, and pointers to everything else |
| [LOOKUP.md](LOOKUP.md) | Address book for scripts, skills, features and data files |
| [NAMESPACE.md](NAMESPACE.md) | Fourteen words for the parts of the system, with a cheat sheet |
| [GLOSSARY.md](GLOSSARY.md) | Terms used across the rules and skills |
| [PLACEMENT.md](PLACEMENT.md) | Where a new rule, feature or convention should go |
| [FOLDERS.md](FOLDERS.md) | Per-folder map: owner, purpose, what belongs there |
| [PORTABILITY.md](PORTABILITY.md) | What the repo tracks, what it leaves out, and what lives in other repos |
| [COMMIT.md](COMMIT.md) | How commits to this repo are made |
| [features/README.md](features/README.md) | Index of subsystem docs |
| [conventions/README.md](conventions/README.md) | Index of output and authoring standards |

## How work happens here

<p align="center">
  <img src=".github/banner-control-room.svg" alt="A terminal beside a hook board: a chained rm command is blocked by a PreToolUse hook, the agent retries with trash, and the Stop checks pass" width="100%">
</p>

The owner's rulings are recorded with dates, and later rulings override earlier ones; the rule files quote them. Structural changes to the folder get a numbered record in `migrations/`. Nothing counts as done until it has been run in the state that matters, which `rules/exercise-based-verification.md` spells out and a Stop hook enforces.

## Repo structure

```
.
├── CLAUDE.md            always-loaded instructions
├── settings.json        Claude Code settings, including every hook binding
├── rules/               behavioral rules, indexed in 00-index.md
├── rules-provenance/    the cases and reasoning behind each rule
├── features/            how each subsystem works
├── conventions/         output and authoring standards
├── skills/              active slash commands, one folder each
├── skills-parked/       retired skills kept whole
├── scripts/             shell and Python tooling, hooks in scripts/hooks/
├── hinters/             per-prompt nudges
├── personas/            working-mode role prompts
├── git-hooks/           global git hooks
├── adapters/            driving non-Claude model seats from this config
├── mods/                Claude Code plugins loaded with --plugin-dir
├── migrations/          numbered records of structural changes
└── subconscious/ ...    curated learned state from the dream engine
```

Everything else in the live folder (transcripts, logs, caches, session state) is excluded by an allowlist `.gitignore` and never reaches this repo.

## License

[MIT](LICENSE). Borrow ideas, copy files, adapt them to your own setup.
