---
name: scaffold
description: Scaffolds new projects with opinionated defaults — wizard-based stack selection, file generation, and a post-scaffold pipeline that calls /git-setup, /readme, and other skills to deliver a ready-to-code project.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
user-invokable: true
argument-hint: "[<stack>] [--name <project>] [--dir <path>] [--minimal] [--no-git] [--no-readme]"
---

## Brief

Project scaffolder that generates a complete, ready-to-code project directory. Supports
multiple tech stacks with battle-tested defaults. Runs a post-scaffold pipeline that
initializes git, generates a README, and optionally runs additional setup commands.

## Step 0: Load Shared Guidelines and Runtime Context

Read `~/.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `~/.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after. Never write to `runtime-notes.md` or any SKILL.md without
> holding its lock.

---

## Usage

```
/scaffold                                    # Interactive wizard — asks what to build
/scaffold nextjs --name my-app               # Next.js project named "my-app"
/scaffold fastapi --name api --dir ~/Code    # FastAPI project in ~/Code/api
/scaffold express --minimal                  # Express with bare minimum files
/scaffold list                               # Show available stacks
```

| Argument | Type | Description |
| -------- | ---- | ----------- |
| `<stack>` | optional | Stack name (see list below). Omit to enter wizard mode. |
| `--name <project>` | optional | Project directory name. Defaults to stack-based suggestion. |
| `--dir <path>` | optional | Parent directory. Defaults to CWD. |
| `--minimal` | optional | Bare minimum — skip optional config, linting, testing setup. |
| `--no-git` | optional | Skip git initialization (default: runs `/git-setup init`). |
| `--no-readme` | optional | Skip README generation (default: runs `/readme`). |

---

## Available Stacks

| Stack | Description | Key Files |
| ----- | ----------- | --------- |
| `nextjs` | Next.js 15 + App Router + TypeScript + Tailwind | `app/`, `next.config.ts`, `tailwind.config.ts` |
| `express` | Express.js + TypeScript + structured routes | `src/`, `tsconfig.json`, route/middleware dirs |
| `fastapi` | FastAPI + Pydantic + SQLAlchemy + Alembic | `app/`, `alembic/`, `pyproject.toml` |
| `react` | Vite + React + TypeScript + Tailwind | `src/`, `vite.config.ts`, `tailwind.config.ts` |
| `python` | Pure Python package with pyproject.toml | `src/<name>/`, `tests/`, `pyproject.toml` |
| `cli` | Node.js CLI tool with TypeScript | `src/`, `bin/`, `tsconfig.json` |
| `monorepo` | Turborepo monorepo with apps + packages | `apps/`, `packages/`, `turbo.json` |
| `static` | Static HTML/CSS/JS with live reload | `index.html`, `styles/`, `scripts/` |

---

## Subcommand: `list`

Print the stacks table above. For each stack, also show:
- Required tools (node, python, etc.)
- Default port assignment (following dev-servers-guide.md conventions — never 3000 or 5000)
- Estimated file count

---

## Phase 1 — Resolve Configuration

### 1.1 Interactive Wizard (no stack argument)

If no stack was provided, gather preferences. Use `mcp__inputs__wizard` if available,
otherwise ask sequentially:

**Step 1: What are you building?**
Options: Web app, API / backend, CLI tool, Library / package, Full-stack (mono), Static site

**Step 2: Language / framework**
Options filtered by Step 1 (e.g., Web app → Next.js, React/Vite, Static HTML)

**Step 3: Project name**
Text input. Validate: lowercase, no spaces, npm-compatible.
Default suggestion based on stack.

**Step 4: Where?**
Path picker. Default: CWD.

**Step 5: Extras**
Multi-select: Linting (ESLint/Ruff), Testing (Jest/Vitest/Pytest), Docker, CI (GitHub Actions), Database (choose type)

Map the wizard answers to the matching stack name and options.

### 1.2 Direct Stack (stack argument provided)

Read the stack definition from `~/.claude/skills/scaffold/stacks/<stack>.md`.
If the file doesn't exist, print available stacks and stop.

### 1.3 Resolve project directory

```
target = <dir>/<name>
```

- If `target` already exists and is non-empty: warn and stop, leaving the existing files untouched.
- If `target` exists and is empty: proceed (common with `mkdir` + `/scaffold`).
- Create `target` if it doesn't exist.

---

## Phase 2 — Generate Files

Read the stack definition file at `~/.claude/skills/scaffold/stacks/<stack>.md`.
Each stack definition contains:

1. **File manifest** — ordered list of files to create with their content
2. **Dependencies** — packages to install (with version constraints)
3. **Scripts** — package.json scripts or Makefile targets
4. **Config files** — tsconfig, eslint, prettier, pyproject.toml, etc.

### Generation Rules

- **Use the Write tool** for each file rather than `echo >` or heredocs
- **Create directories as needed** — `mkdir -p` before writing nested files
- **Apply experienced defaults:**
  - TypeScript: strict mode, path aliases (`@/`)
  - ESLint: flat config format (eslint.config.js)
  - Prettier: printWidth 100, singleQuote, trailingComma "all"
  - Tailwind: content paths configured, default theme extensions
  - Python: pyproject.toml (not setup.py), ruff for linting, pytest for testing
  - Ports: frontend 30xx, backend 50xx (never 3000 or 5000)
- **Keep secrets and credentials out** — use `.env.example` with placeholder values, not real ones
- **Include a `.gitignore`** appropriate to the stack
- **Include a `.env.example`** with documented placeholder values, in place of a real `.env`

### File Order

Generate files in dependency order:
1. Package manifest (`package.json` / `pyproject.toml`)
2. Configuration files (tsconfig, vite config, tailwind config, etc.)
3. Source files (entry points, routes, components)
4. Test files (at least one example test)
5. Documentation (`.env.example`, basic inline comments)

Print each file as it's created:
```
  + package.json
  + tsconfig.json
  + src/index.ts
  + src/routes/health.ts
  ...
```

---

## Phase 3 — Install Dependencies

After all files are generated:

**Node.js stacks:**
```bash
cd <target> && npm install -y
```

**Python stacks:**
```bash
cd <target> && python3 -m venv .venv && source .venv/bin/activate && pip install -e ".[dev]"
```

If installation fails, print the error but continue — the project is still usable,
just needs manual dependency resolution.

---

## Phase 4 — Post-Scaffold Pipeline

Run these steps in order unless the user opted out:

### 4.1 Git Setup (unless `--no-git`)

Invoke `/git-setup init` equivalent behavior:
- `git init` in the project directory
- Create appropriate `.gitignore` (already done in Phase 2)
- Initial commit: `"chore: scaffold <stack> project"`

### 4.2 README Generation (unless `--no-readme`)

Generate a `README.md` with:
- Project name as H1
- One-line description
- Quick start section (install + run commands)
- Project structure tree (from actual generated files)
- Available scripts/commands
- Environment variables reference (from `.env.example`)

Use the project's actual file structure — do not use a generic template.

### 4.3 Boot Test (run-and-observe, not type-check)

A type-check or import-check confirms the code *parses*, not that the app *runs* —
that is collect-not-run, and `rules/exercise-based-verification.md` flags it. Boot the
scaffolded app once and read its actual startup output. Prefer `/run` (it detects the
project type and start command); otherwise use the stack's run command directly.

- **Node server / Next.js / Express:** start it (`/run`, or `npm run dev`), wait for the
  listening line, then `curl` the health route or the root URL and confirm a real response.
  Stop the process after.
- **CLI:** invoke the entrypoint with `--help` (or a no-op command) and confirm it prints.
- **Python service:** start it (`/run`, or `uvicorn app.main:app`) and hit an endpoint; for a
  pure package, run the example test (`pytest`), not a bare import.
- **Static:** serve `index.html` (`/run`, or `python3 -m http.server <port>`) and fetch the
  page; confirm it returns 200 with the expected title.

Report `✓ Booted: <observed signal>` (the listening line, the HTTP status, the help output)
or `✗ Boot failed: <reason>`. If the app genuinely can't be booted here (missing service,
hardware), report `UNCONFIRMED — <reason>` rather than claiming it passed.

---

## Phase 5 — Report

Print a completion summary:

```
─────────────────────────────────────────────────────
  Project Scaffolded: <name>
─────────────────────────────────────────────────────

  Stack:     <stack>
  Location:  <absolute-path>
  Files:     <count> files created
  Size:      <size>

  Quick Start:
    cd <name>
    <install-command>
    <run-command>

  Next Steps:
    - Review .env.example and create .env with real values
    - <stack-specific suggestions>

─────────────────────────────────────────────────────
```

---

## Stack Definition Format

Stack files live at `~/.claude/skills/scaffold/stacks/<name>.md`. Each file defines
the complete blueprint for one stack type. Format:

```markdown
# <Stack Name>

## Meta
- Runtime: node | python | none
- Default port: <port>
- Install command: <cmd>
- Run command: <cmd>
- Test command: <cmd>

## Dependencies
<package-name>: <version-constraint>
...

## Dev Dependencies
<package-name>: <version-constraint>
...

## Files
### <relative-path>
\```<lang>
<file content>
\```

### <relative-path>
\```<lang>
<file content>
\```
...
```

Placeholders in file content:
- `{{name}}` — project name
- `{{port}}` — assigned port
- `{{year}}` — current year
- `{{date}}` — current date

---

## Defaults Directory

`~/.claude/skills/scaffold/defaults/` contains shared config file templates reused
across stacks:

| File | Used by |
| ---- | ------- |
| `tsconfig.base.json` | All TypeScript stacks |
| `eslint.config.js` | All Node.js stacks |
| `prettier.config.js` | All Node.js stacks |
| `.editorconfig` | All stacks |
| `github-ci.yml` | Stacks with `--ci` flag |

These are copied into the project and customized per-stack rather than symlinked.

---

## Notes

- The `--minimal` flag skips: linting config, testing setup, CI config, Docker. It still creates the core project structure, package manifest, and source files.
- Port assignment follows `~/.claude/dev-servers-guide.md` — frontend 30xx, backend 50xx. The last two digits are auto-assigned based on project name hash to avoid collisions.
- Stack definitions are intentionally verbose (full file content) rather than using a template engine. This makes each stack self-contained and easy to audit or customize.
- This skill creates files in a new directory; it leaves existing projects untouched. To add features to an existing project, use the stack's specific tools directly.
- The monorepo stack creates a Turborepo structure with one `apps/web` (Next.js) and one `packages/ui` (shared components) as starting points.
- Pairs with: `/git-setup` (repo init), `/readme` (docs), `/diagram` (architecture vis), `/add-mcp` (database server setup)

---

## See Also

- `~/.claude/rules/exercise-based-verification.md` — why the boot test in Phase 4.3 runs the
  app instead of type-checking it. A scaffold that only compiles is not a scaffold that boots.
- `/test` — run the generated test suite for the new project once it's scaffolded. Phase 4.3
  boots the app; `/test` exercises its tests.
- `/skeptical-review` — review the generated code before relying on it. Scaffolded defaults are
  templated, not audited; a fresh adversarial pass catches config drift and stale assumptions.
