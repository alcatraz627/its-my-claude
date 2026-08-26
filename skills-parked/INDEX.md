# Parked skills — tldr, tags, activation

Not loaded; see README.md for the two-way check. Regenerate: `bash ~/.claude/scripts/parked/parked.sh index`.

| skill | tldr | tags | copy in when |
|---|---|---|---|
| `add-mcp` | Add pre-configured MCP servers from the central catalog (~/.claude/mcp-catalog.json) into the current project's .mcp.json. Avoids re-configu | mcp,setup | a project needs an MCP server from the catalog wired into .mcp.json |
| `apple` | Router for Apple platform development skills — iOS, macOS, watchOS, visionOS, SwiftUI, Swift, App Store, design (Liquid Glass), generators,  | macos,ios,swift,swiftui,xcode | project has *.xcodeproj, Package.swift, or Info.plist; or the ask names iOS/macOS/SwiftUI |
| `archive-notes` | Archives old runtime-notes entries beyond a threshold to a dated archive file, keeping the active notes file lean. Accepts a project path ar | maintenance,runtime-notes | runtime-notes.md exceeds 800 lines or 3 weeks |
| `autocorrect` | Manage the autocorrect typo-correction dictionaries — view/edit mappings, review correction logs, teach new corrections, and check stats. Us | hinter,typos | the autocorrect dictionaries need editing |
| `capabilities` | Generates a report of everything this Claude instance can do — skills, hooks, MCP servers, memory, runtime architecture, widgets, and all st | docs,report | owner asks "what can this Claude do" as a report |
| `clean-html` | Converts HTML files to clean, readable markdown by extracting and downloading embedded media, stripping tags while preserving document hiera | html,scrape,markdown | owner hands an HTML page to turn into readable markdown with media |
| `cogitate` | > | research,notes | a durable topic note under ~/Documents/Claude/Topics is wanted |
| `context-prime` | Loads project index, gotchas, recent git log, and open issues into context at the start of a session — bootstrapping Claude's awareness with | orient,onboarding | a fresh session must orient in an unfamiliar repo (superseded by /router:pick-skill + /arch-qa) |
| `daily-todo` | Scans all project runtime-notes for recent entries, checks todo files for unchecked items, reads MEMORY.md indexes for activity hints — gene | todo,daily | owner asks for a daily todo file again (fell out of use 2026-Q2) |
| `dep-audit` | Runs npm audit and npm outdated, cross-references key dependencies against known breaking versions, and produces a prioritized upgrade list  | npm,security,dependencies | owner asks about outdated or vulnerable deps in a node project |
| `describe` | Analyzes a named Claude skill, MCP server, plugin, or custom feature in depth — reads its prompt, code, and runtime notes, then generates a  | docs,report | owner wants an HTML deep-dive report on one skill or feature |
| `diagram` | Renders terminal diagrams — flowcharts, sequence diagrams, trees, tables, state machines, and architecture layouts — using gum-tui.sh for bo | docs,ascii | a terminal diagram beyond an inline box drawing |
| `forgotten-todos` | Browse the cross-session backlog of unfinished todos surfaced from /core-dump checkpoints. Reads ~/.claude/subconscious/dreams/pending-todos | todo,backlog,checkpoints | owner asks "what did I forget" / cross-session backlog browse |
| `git-setup` | Initializes, audits, and maintains git repositories — sets up .gitignore, branch protection, conventional commits, PR templates, and runs he | git,bootstrap | a new repo needs .gitignore, protection, templates |
| `gotchas-update` | Appends a new dated entry to gotchas.md after a bug fix, architectural discovery, or lesson learned — keeping the project's developer pitfal | maintenance,docs | a project keeps a gotchas.md and a lesson lands |
| `improve-config` | Audits the project's .claude/ directory (or ~/.claude/ for global config) using /user-config context to catalogue instructions and skill pat | config,audit | an audit of a .claude directory is wanted |
| `invalidate-audit` | Scans all useM and useMutation calls in src/ and reports any missing QueryKeys invalidation in their onSuccess callback — catching stale-dat | nextjs,cache,versable | same shape; cache-invalidation sweep |
| `mini` | Fast mini-model query (<1s) using local Ollama or cloud Haiku — for quick lookups, titles, summaries, and command composition | llm,fast-lookup | a sub-second local-model lookup is wanted; `q` on PATH covers most cases |
| `new-migration` | Generates a Drizzle ORM migration from a plain-English schema change description — updates the schema file and runs db:generate to produce t | gcc,migrations | a structural gcc change needs a migration entry (see conventions/gcc-hygiene.md) |
| `past-sessions` | Browse, search, and summarize past Claude Code conversation transcripts from ~/.claude/projects/. Use when the user asks "what did we do las | transcripts,history | owner asks "what did we do last time" beyond what /catchup or WAL holds |
| `project-index` | Scans the project structure, key files, dependencies, and architectural patterns — generates a comprehensive index markdown and optional HTM | orient,index | a project needs a generated structure index; /arch-qa covers most asks |
| `route-audit` | Scans all Next.js App Router route files for missing auth guards, missing input validation on mutation handlers, and non-standard response s | nextjs,versable | same as type-audit; route/handler sweep |
| `scaffold` | Scaffolds new projects with opinionated defaults — wizard-based stack selection, file generation, and a post-scaffold pipeline that calls /g | new-project,bootstrap | a brand-new repo is being started from nothing |
| `scan-sessions` | Deep-scan past Claude Code sessions for patterns, frustration signals, and improvement opportunities | transcripts,analysis | owner asks for a deep scan of past sessions for patterns |
| `shell-mem` | Look up recent shell commands, background process history, or mark background processes as done. Use when asked about recent commands, what' | shell,history | owner asks about recent shell commands or background processes; the MCP covers reads |
| `statusline-config` | Interactively toggle statusline segments and profiles | statusline,config | same as statusline |
| `statusline` |  | statusline,terminal | owner asks to change the statusline itself (conf lives in assets/docs/statusline-dev-guide.md) |
| `sync-api-types` | Reads FastAPI Pydantic models from ../backend/ and diffs their fields against the TypeScript types used in src/ to consume those endpoints — | versable,api,codegen | the versable API repo pair; types drifted between BE and FE |
| `thesaurus` | > | style,ledger | a style verdict must be captured; the style ledger digest |
| `type-audit` | Scans the TypeScript codebase for unsafe type patterns (explicit `any`, implicit `any`, non-null assertions, unsafe casts), reports them wit | nextjs,typescript,versable | Next.js App Router project with the versable shape; owner asks for a type audit |
| `user-config` | Lists and manages all Claude configuration in this project — guidelines, skill definitions, personal settings, and shared utilities. Use /us | config,audit | owner wants the project's .claude config listed or edited interactively |
| `visual-regression` | Captures baseline screenshots via Playwright MCP and compares against later snapshots to detect visual regressions — pixel-diff reports with | ui,screenshots | baseline-vs-later screenshot diffs are wanted |
