# std::claude Glossary

<!-- sessions: catcu-std-c0@2026-04-17 -->

> **Living terminology reference** for the Claude config system under `~/.claude/`.
> Future agents: read this when encountering unfamiliar shorthand. Expand it when
> introducing new terms the user adopts.

---

## How to use

- **Agent encounters unknown term**: scan this file first, then NAMESPACE.md
- **User introduces new shorthand**: add it here immediately
- **Term becomes obsolete**: mark it `(deprecated)` with pointer to replacement — don't delete

---

## Abbreviations

| Abbrev | Full form | Notes |
|---|---|---|
| **GCC** | Global Claude Config | The entire `~/.claude/` directory tree — all config, skills, scripts, memory, hooks, and assets that persist across projects and sessions |
| **WAL** | Write-Ahead Log | Append-only session journal (`.claude/wal.jsonl`). JSONL format since v2; legacy markdown `.claude/wal.md` still read by `/catchup` |
| **MCP** | Model Context Protocol | Server protocol for extending Claude's tool access (databases, APIs, services). Config: `.mcp.json` (active) vs `mcp-catalog.json` (available) |
| **TUI** | Terminal User Interface | Styled terminal output via `gum`. Source `gum-tui.sh`; never call raw `gum style` |
| **CWD** | Current Working Directory | The project root from which Claude Code was launched. Determines which per-project memory, WAL, and scratchpad are loaded |

## Namespace Labels

| Term | Meaning | Path(s) |
|---|---|---|
| **std::claude** | Root namespace prefix for all Claude features and add-ons | `~/.claude/` (conceptual, not an import) |
| **std::claude::shared** | Shared utility library (Python + Bash) | `~/.claude/skills/shared/` |
| **std::claude::code** | Reference material: roadmaps, design sketches, templates | `~/.claude/code/` |
| **std::claude::scripts** | Operational executables: hooks, CLIs, daemons | `~/.claude/scripts/` |
| **std::claude::skills** | Custom skill definitions (SKILL.md) | `~/.claude/skills/` |
| **std::claude::plugins** | Marketplace plugin config | `~/.claude/disabled-plugins.json` etc. |
| **std::claude::mcp** | MCP server wiring | Facet: `.mcp.json`, `mcp-catalog.json`, project `.mcp.json` |
| **std::claude::tui** | Terminal UI surface | Facet: `gum-tui.sh`, `banner.py`, `gum-guide.md` |
| **std::claude::vision** | Screen perception + desktop automation | Facet: `scripts/desktop.sh`, `assets/images/` |
| **std::claude::network** | Internet + local network helpers | `scripts/dev-servers/gen-nginx-conf.sh`, `scripts/dev-servers/pm2-register.sh` |
| **std::claude::widgets** | macOS widgets + mini-apps | Facet: `subconscious/dashboard.html` + future `widgets/` |
| **std::claude::assets** | Non-source file registry | `~/.claude/assets/` |
| **std::claude::memory** | Persistent auto-memory | Per-project: `projects/<slug>/memory/` + Global: `memory/global/` |
| **std::claude::scratchpad** | Working memory (plans, learnings) | `~/.claude/scratchpad/` (global + local tiers) |
| **std::claude::todos** | Weekly/monthly task lists | Facet: `weekly-todos.md`, `scripts/weekly-todo.sh` |
| **std::claude::backups** | Revert & recovery artifacts | Facet: `assets/backups/`, root `bak_*` rotation |
| **std::claude::improvement** | Self-correction & learning | Facet: `proposals.jsonl`, `improvement-ideas.md`, `mistake-patterns.md` |
| **std::claude::migrations** | Structural change log | `~/.claude/migrations/` |

## Concepts

| Term | Definition |
|---|---|
| **Facet** | A namespace whose artifacts are deliberately distributed across multiple directories. Marked `[facet]` in NAMESPACE.md. Never "consolidate" a facet into one directory — the distribution is intentional |
| **Surface type** | One of four artifact kinds: **Reference** (docs/specs), **Executable** (scripts/hooks), **Behavior** (SKILL.md/CLAUDE.md rules), **State** (JSONL logs, registries). Each cluster leans toward one surface type |
| **Two-artifact threshold** | Naming convention: don't create a namespace until at least 2 files want the label. Prevents speculative taxonomy |
| **Migration** | A documented structural change (path move, label rename, directory restructure). Tracked in `~/.claude/migrations/MIGRATIONS.md` with zero-padded 4-digit IDs |
| **Phase** | A discrete step within a migration. Migrations are split into phases so low-risk work (additive) can land independently of higher-risk work (renames, moves) |
| **Global memory tier** | Cross-project memories at `~/.claude/memory/global/`. Loaded via CLAUDE.md instruction. Complements the harness-controlled per-project memory |
| **Per-project memory** | Memory stored at `~/.claude/projects/<slug>/memory/`. Auto-loaded by the Claude Code harness based on CWD. Path is not user-configurable |
| **Promote (memory)** | Copy a per-project memory to the global tier when it proves universally applicable. Originals stay in place |
| **Harness** | The Claude Code CLI runtime that injects system prompts, memory paths, and tool definitions. User controls behavior via CLAUDE.md and settings.json but not the harness internals |
| **Skill** | A structured prompt definition (SKILL.md) invoked via `/slash-command`. Lives under `~/.claude/skills/<name>/`. Has its own guidelines, tools, and argument hints |
| **Hook** | A shell script registered in `settings.json` that runs on specific events (SessionStart, PostToolUse, etc.). Executes in the harness, not in Claude's tool sandbox |
| **Runtime note** | A post-session insight entry prepended to `.claude/skills/runtime-notes.md`. Captures what was learned for future sessions |
| **Checkpoint** | A `_*.claude.md` file or WAL `checkpoint` entry capturing session state (goal, done, current, next, blockers) at a point in time. Used by `/catchup` to restore context |
| **Core dump** | The `/core-dump` skill output — a checkpoint file that condenses an entire session into a resumable format |
| **Proposal** | An improvement idea filed to `~/.claude/proposals.jsonl` via `propose.sh`. Part of the `::improvement` namespace |
| **Session ID** | A short identifier (`keyword-keyword-2hex`) generated at session start from the user's first prompt. Used in WAL headers, checkpoints, and file tags |
| **Slug** | The path-based project identifier used by the harness for per-project storage. Derived from CWD with `/` replaced by `-` (e.g., `-Users-alcatraz627-Code-Claude`) |

## File Conventions

| Term | Definition |
|---|---|
| **CLAUDE.md** | Per-project or global instructions file, auto-loaded by the harness every session. The primary behavior control surface |
| **LOOKUP.md** | Address book / index for all config files under `~/.claude/`. The "where does this rule live?" reference |
| **NAMESPACE.md** | Conceptual tree of `std::claude::*` labels. The "what is this thing called?" reference |
| **GLOSSARY.md** | This file — the "what does this term mean?" reference |
| **GUIDELINES.md** | Mandatory rules for all skills (at `~/.claude/skills/GUIDELINES.md`) |
| **SKILL.md** | Prompt definition for a skill — title, steps, tools, argument hints |
| **MEMORY.md** | Index file for a memory tier (one per project, one for global). One-line entries pointing to individual memory files |
| **runtime-notes.md** | Per-project session history file. Entries prepended at session end |
| **wal.jsonl** | Write-Ahead Log in JSONL format. Session timeline of actions, decisions, checkpoints |
| **events.jsonl** | Global event timeline. One line per hook firing across all sessions and projects |
| **proposals.jsonl** | Cross-session improvement backlog. Filed via `propose.sh`, triaged via `list`/`show`/`done`/`reject` |

## User Shorthand

| Term | Meaning | Context |
|---|---|---|
| **GCC** | `~/.claude/` — the global Claude config directory | Used when distinguishing global config from per-project `.claude/` |

---

## Adding new terms

When the user or an agent introduces a new term:
1. Add it to the appropriate table above
2. If it's a namespace label, also update NAMESPACE.md
3. If it's an abbreviation the user uses casually, add it to "User Shorthand"
4. Keep definitions under 2 sentences — point to the canonical doc for details
