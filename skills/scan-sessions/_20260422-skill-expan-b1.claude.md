# Quick Summary (for LLMs) — 2026-04-22T04:09:49+05:30

> Completed a full 4-phase skill expansion for std::claude::skills. Created 6 new skills (/git-setup, /write-docs, /capabilities, /web-design, /visual-regression, /scaffold), improved 2 existing ones (/create-report, /generate-pdf), and integrated 140+ Apple platform skills as /apple with a router SKILL.md. All 10 tracked tasks are complete. The /scaffold capstone includes 8 stack definitions (nextjs, fastapi, express, react, python, cli, monorepo, static) with full file manifests. No pending items remain — this is a completed initiative.

# Core Dump — 2026-04-22T04:09:49+05:30

## Initial Goal

Expand std::claude::skills with new skills and improvements across 7+1 items: (1) /git-setup for repo init/maintenance, (2) /web-design for professional web UI critique, (3) Apple skills integration, (4) /write-docs for technical documentation, (5) smarter data parsing for /create-report, (6) more versatile /generate-pdf, (7) /scaffold project scaffolder, plus a user-added (8) /capabilities meta-skill. The user specified: copy Apple skills (not symlink), Playwright as a separate /visual-regression skill, expand small-effort items where real gains exist, and the approved build order (Phase 1→4).

## Agent Actions

1. Planned full skill expansion architecture — identified 4 phases, 10 tasks, dependency order. User approved with modifications (Apple = copy, Playwright = separate skill, scope expansion at discretion).
2. Created `~/.claude/skills/git-setup/SKILL.md` (~280 lines) — 3 subcommands (init wizard, health audit with 10 checks scored 0-10, clean with prune/gc/archive). Uses `mcp__inputs__wizard` for 6-step preferences gathering. 4 built-in gitignore templates.
3. Created `~/.claude/skills/write-docs/SKILL.md` (~300 lines) — 5 modes (api, guide, adr, changelog, onboarding). Critical voice rules section with 17 banned phrases and replacements. Framework detection for API docs (Express/FastAPI/Next.js).
4. Created `~/.claude/skills/capabilities/SKILL.md` (~300 lines) — meta-report skill with `context: fork`. 30+ discovery sources table, fingerprint-based caching (skill_count, mcp_server_count, hook_count, script_count, memory_count), 3 report sizes (small/medium/large). Self-updating discovery manifest.
5. Modified `~/.claude/skills/create-report/SKILL.md` — added Step 1.5: Pre-Parse Structured Data. Detects fenced data blocks (csv/json/yaml), pre-parses via file-tools MCP or Python, replaces with DATA_TABLE markers. Content profile detection (prose-heavy/data-heavy/code-heavy/narrative/formal).
6. Modified `~/.claude/skills/generate-pdf/generate_pdf.py` — major rewrite adding `_parse_args()`, `_load_style_css()`, `_generate_toc()`, `_generate_cover()`, `_highlight_style()`. New constants: `STYLES_DIR`, `AVAILABLE_STYLES`, `STYLE_MARGINS`. Rewrote `main()` for multi-style support with cover/TOC/landscape options.
7. Updated `~/.claude/skills/generate-pdf/SKILL.md` — new description, argument-hint with all flags, styles table, selection guidance, full example commands.
8. Created `~/.claude/skills/generate-pdf/styles/professional.css` — serif headings (Georgia), wider margins (20-22mm), light table headers, blue accent (#1e40af).
9. Created `~/.claude/skills/generate-pdf/styles/academic.css` — LaTeX-inspired: justified text, centered H1, italic H3, github syntax theme, thin borders, 25mm margins.
10. Created `~/.claude/skills/generate-pdf/styles/compact.css` — max density: 9pt body, 10mm margins, 7pt code, 8pt tables, minimal spacing.
11. Created `~/.claude/skills/web-design/SKILL.md` (~320 lines) — 3 subcommands (review, system, page). 60-line experienced defaults section covering typography, spacing, color, interactive states, layout. Review scores 6 dimensions. System extracts design tokens. Page generates 6 layout types.
12. Created `~/.claude/skills/visual-regression/SKILL.md` (~180 lines) — 3 subcommands (baseline, compare, report). Playwright MCP-based screenshot capture + pixel-diff with Pillow fallback. Threshold pass/fail (default 0.1%), JSON report for CI.
13. Copied 405 files (5.2MB) from `~/Code/Claude/claude-code-apple-skills/skills/` to `~/.claude/skills/apple/` — 23 categories (app-store, apple-intelligence, core-ml, design, ios, macos, swift, swiftui, generators with 52 code generators, testing, product, etc.).
14. Copied `SKILLS_INDEX.md` to `~/.claude/skills/apple/` for fast skill lookup.
15. Created `~/.claude/skills/apple/SKILL.md` — router skill dispatching to 23 categories. Supports `/apple list`, `/apple search <query>`, `/apple <category> [sub-skill]`. Generator shortcuts table. Provenance and update instructions.
16. Created `~/Code/Claude/claude-code-apple-skills/WORKING_COPY_NOTE.md` — note in source dir pointing agents to `~/.claude/skills/apple/` as the working version.
17. Created `~/.claude/skills/scaffold/SKILL.md` (~200 lines) — 5-phase scaffolder: resolve config (wizard or direct stack), generate files, install deps, post-scaffold pipeline (git-setup, readme, smoke test), report. 8 stacks, `--minimal`/`--no-git`/`--no-readme` flags. Placeholder templating ({{name}}, {{port}}, {{year}}, {{date}}).
18. Created 8 stack definition files in `~/.claude/skills/scaffold/stacks/`: nextjs.md (Next.js 15 + App Router + TS + Tailwind), fastapi.md (FastAPI + Pydantic + SQLAlchemy + Alembic), express.md (Express 5 + TS), react.md (Vite + React + TS + Tailwind), python.md (pure package with pyproject.toml), cli.md (Commander + TS), monorepo.md (Turborepo), static.md (HTML/CSS/JS + live-server). Each contains Meta, Dependencies, and full Files manifest.
19. Created 2 shared defaults: `scaffold/defaults/editorconfig` and `scaffold/defaults/tsconfig.base.json`.
20. Marked all 10 tasks as completed: #28 (plan), #29 (git-setup), #30 (web-design), #31 (apple), #32 (write-docs), #33 (create-report), #34 (generate-pdf), #35 (scaffold), #36 (capabilities), #37 (visual-regression).

## Current Expectation

User invoked `/core-dump` to checkpoint this completed session. All requested work is done — 6 new skills, 2 improvements, 1 integration (Apple), 1 capstone (scaffold). No further implementation is expected.

## Pending Items

- None — all 10 tasks completed across 4 phases.

## Session Insights

**What worked well:**
- The 4-phase build order (foundations → improvements → design/platform → capstone) kept dependencies clean — /scaffold could reference /git-setup and /readme because they were built first.
- Stack definition files as standalone markdown with full file content (not template engine) made each stack self-contained, auditable, and easy to modify independently.
- The router pattern for /apple and /scaffold keeps prompt tokens low — only the relevant sub-file is loaded per invocation.
- Using the session continuation summary to restore state after compaction was seamless — all tasks, decisions, and file references were preserved.

**What didn't work / watch out for:**
- The Apple skills `shared/` directory could be confused with `~/.claude/skills/shared/` (the global std::claude shared library). The SKILL.md notes this but it's a naming collision to be aware of.
- Stack definitions are large (each ~200-400 lines) and will grow — if more stacks are added, consider a registry pattern instead of flat files.

**Notes for future agents:**
- The `/scaffold` skill is prompt-driven (SKILL.md), not code-driven. There's no `scaffold.py` script — Claude reads the stack definition and generates files via Write tool. This is by design (flexibility over speed).
- `/visual-regression` requires Playwright MCP tools. If they're not connected, only the diff generation works (via Python/Pillow), not screenshot capture.
- The `/capabilities` skill uses `context: fork` — it runs in a sub-agent to protect the main context window.
- Apple skills were copied on 2026-04-22. To update: `cp -R ~/Code/Claude/claude-code-apple-skills/skills/* ~/.claude/skills/apple/` after pulling upstream.

**User preferences observed:**
- Prefers copy over symlink for external skill repos (control over the working version).
- Wants Playwright-specific functionality isolated in dedicated skills.
- Trusts agent judgment on scope expansion for small-effort items.
- Approved bundled delivery (all phases in one session) rather than incremental PRs.

---

_Generated by /core-dump. Resume with /catchup._
