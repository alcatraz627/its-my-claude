---
name: git-setup
description: Initializes, audits, and maintains git repositories — sets up .gitignore, branch protection, conventional commits, PR templates, and runs health checks on existing repos.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebFetch
user-invokable: true
argument-hint: "<init | health | clean> [options]"
---

## Brief

Initializes new git repos with proper scaffolding (`.gitignore`, hooks, templates, remote),
audits existing repos for hygiene issues, and performs maintenance operations (prune, gc, archive).
Replaces the manual dance of setting up a repo correctly from scratch.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after. Never write to `runtime-notes.md` or any SKILL.md without
> holding its lock.

---

## Usage

```
/git-setup init [--remote] [--template <name>]
/git-setup health
/git-setup clean [--prune] [--gc] [--archive-stale]
```

| Subcommand | Description |
| ---------- | ----------- |
| `init`     | Initialize a new repository with full scaffolding |
| `health`   | Audit an existing repo and report a health score |
| `clean`    | Maintenance: prune branches, gc, archive stale work |

| Flag | Applies to | Description |
| ---- | ---------- | ----------- |
| `--remote` | `init` | Create GitHub remote via `gh repo create --public` |
| `--template <name>` | `init` | Use a preset template (see Templates section) |
| `--prune` | `clean` | Remove merged local branches and gone remotes |
| `--gc` | `clean` | Run `git gc --auto` and `git prune` |
| `--archive-stale` | `clean` | Archive branches older than 90 days with no recent commits |

---

## Subcommand: `init`

### Phase 1 — Detect Project Context

1. Check if `.git/` already exists:
   - If yes: warn and ask user — "Repo already initialized. Run `/git-setup health` instead? Or reset?" Wait for response.
   - If no: proceed.

2. Detect project language/framework by scanning the current directory:
   - Look for: `package.json` (Node/JS/TS), `requirements.txt`/`pyproject.toml` (Python), `Cargo.toml` (Rust), `go.mod` (Go), `Gemfile` (Ruby), `pom.xml`/`build.gradle` (Java), `*.sln`/`*.csproj` (C#), `Makefile` (C/C++)
   - If multiple detected, note all of them
   - If none detected, ask user: "What language/framework is this project?"

3. Detect existing configuration files:
   - `.editorconfig`, `.prettierrc`, `.eslintrc*`, `tsconfig.json`, etc.
   - Note what's already in place to avoid duplicating

### Phase 2 — Gather User Preferences

Use `mcp__inputs__wizard` with these steps:

**Step 1: Confirm language detection**
```
Detected: [language/framework]. Correct?
Options: [detected option] / Other (specify)
```

**Step 2: .gitignore scope**
```
Generate .gitignore for:
☑ [detected language] defaults
☐ macOS (.DS_Store, ._*)
☐ IDE files (.idea/, .vscode/)
☐ Environment (.env, .env.*)
☐ Build artifacts (dist/, build/, out/)
```
Pre-check macOS + IDE + Environment by default.

**Step 3: Conventional commits**
```
Set up conventional commits (commitlint + husky)?
This enforces commit message format: feat: / fix: / docs: / etc.
Options: Yes (recommended) / No
```

**Step 4: Branch strategy**
```
Default branch name:
Options: main (recommended) / master / other
```

**Step 5: PR & issue templates**
```
Add GitHub templates?
☐ Pull request template
☐ Issue templates (bug, feature)
☐ CONTRIBUTING.md
☐ None
```

**Step 6: Remote (if --remote)**
```
Repository visibility:
Options: Public (default per CLAUDE.md) / Private
```

### Phase 3 — Execute Setup

Execute in this order. Print each step as it happens.

#### 3.1 — Initialize git
```bash
git init -b <branch-name>
```

#### 3.2 — Generate .gitignore

Fetch the official GitHub gitignore template for the detected language:
```bash
curl -sL "https://raw.githubusercontent.com/github/gitignore/main/<Language>.gitignore"
```

Merge with user selections (macOS, IDE, env). Deduplicate entries. Write to `.gitignore`.

Always include these regardless of selection:
```
# Claude Code
**/.playwright-mcp/
_*.claude.md
.claude/_*.claude.md
```

#### 3.3 — Generate .editorconfig (if not present)

Write a sensible `.editorconfig`:
```ini
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.md]
trim_trailing_whitespace = false

[*.py]
indent_size = 4

[Makefile]
indent_style = tab
```

#### 3.4 — Set up conventional commits (if selected)

For Node.js projects:
```bash
npm install -y --save-dev @commitlint/cli @commitlint/config-conventional husky
npx husky init
echo 'npx --no -- commitlint --edit "$1"' > .husky/commit-msg
```

Write `commitlint.config.js`:
```js
export default { extends: ['@commitlint/config-conventional'] };
```

For non-Node projects, create a simple commit-msg hook:
```bash
mkdir -p .git/hooks
# Write a shell-based conventional commit validator
```

#### 3.5 — Add PR / Issue templates (if selected)

Create `.github/` directory with:
- `pull_request_template.md` — checklist format: description, changes, testing, screenshots
- `ISSUE_TEMPLATE/bug_report.md` — steps to reproduce, expected vs actual
- `ISSUE_TEMPLATE/feature_request.md` — problem, proposed solution, alternatives
- `CONTRIBUTING.md` — fork workflow, branch naming, commit format, PR process

Templates should be concise — no boilerplate essays. Each file < 30 lines.

#### 3.6 — Create initial commit

Stage all generated files:
```bash
git add .gitignore .editorconfig
# Add other generated files as appropriate
```

Ask user before committing:
```
Ready to create initial commit with:
  - .gitignore (N lines)
  - .editorconfig
  - [other files]
Proceed? (yes / no)
```

Commit with conventional format:
```bash
git commit -m "chore: initialize repository with git-setup"
```

#### 3.7 — Create remote (if --remote)

```bash
gh repo create <dirname> --public --source . --push
```

If `gh` is not authenticated, instruct the user to run `! gh auth login`.

### Phase 4 — Verify

1. Run `git status` — should be clean
2. Run `git log --oneline -1` — should show the initial commit
3. If remote: `git remote -v` — should show the GitHub URL
4. Print the final file tree of generated files

---

## Subcommand: `health`

Audit an existing repository and produce a health score.

### Checks (each scored 0-10)

| Check | What it examines | Deduction |
| ----- | --------------- | --------- |
| `.gitignore` coverage | Are `node_modules/`, `.env`, `dist/`, `.DS_Store` excluded? | -2 per missing critical pattern |
| Tracked secrets | `git ls-files` matching `*.env*`, `*.pem`, `*.key`, `credentials*` | -5 per tracked secret file |
| Stale branches | Local branches merged into default but not deleted | -1 per stale branch (max -5) |
| Gone remotes | Remote tracking branches where upstream is deleted | -1 per gone remote |
| Large files | Files > 5MB in the working tree | -2 per large file |
| Missing templates | No `.github/pull_request_template.md` | -1 |
| Missing `.editorconfig` | Inconsistent formatting without it | -1 |
| Uncommitted changes | Dirty working tree | -2 |
| Default branch | Not using `main` | -1 (informational) |
| Recent activity | Last commit > 30 days ago | -1 (informational) |

### Output

```
─────────────────────────────────────────────────────
  Git Health Report: <repo-name>
─────────────────────────────────────────────────────

  Score: 87/100

  ✓ .gitignore covers critical patterns
  ✓ No tracked secrets
  ✗ 3 stale branches (merged but not deleted)
  ✗ Missing .editorconfig
  ✓ No large files tracked
  ...

  Recommendations:
  1. Delete merged branches: git branch -d <names>
  2. Add .editorconfig: run /git-setup init --template editorconfig
  3. ...

─────────────────────────────────────────────────────
```

For each failed check, provide the exact command or action to fix it.

---

## Subcommand: `clean`

Maintenance operations. Each is opt-in via flags, or all run if no flags specified.

### --prune
1. Find merged branches: `git branch --merged <default-branch>`
2. Exclude the default branch and current branch
3. List branches to delete and ask confirmation
4. `git branch -d <each>` (safe delete — won't delete unmerged)
5. `git fetch --prune` to clean gone remotes

### --gc
1. Print current `.git/` size: `du -sh .git/`
2. Run `git gc --auto`
3. Run `git prune`
4. Print new `.git/` size and space saved

### --archive-stale
1. Find branches with no commits in 90+ days: check `git log -1 --format='%ci'` per branch
2. List candidates with last commit date
3. Ask user which to archive (creates tags `archive/<branch-name>` before deleting)
4. Archive selected branches

---

## Templates

Built-in presets for `--template`:

| Template | What it sets up |
| -------- | --------------- |
| `node` | Node.js defaults: `.gitignore` (node), `commitlint`, `husky`, `.nvmrc` |
| `python` | Python defaults: `.gitignore` (python), `.python-version`, `pyproject.toml` scaffold |
| `minimal` | Just `.gitignore` + `.editorconfig` — no hooks or templates |
| `full` | Everything: `.gitignore`, `.editorconfig`, hooks, PR templates, CONTRIBUTING.md |

---

## Notes

- This skill never force-pushes, never uses `--force`, never runs `rm`
- GitHub repos are created **public** by default (per CLAUDE.md mandatory rule)
- The skill detects but does not modify existing `.gitignore` files — it warns about gaps and offers to append
- Conventional commit setup is recommended but never forced — the user always chooses
- If `gh` CLI is not available for remote operations, the skill provides manual instructions
- Chains well with `/scaffold` which calls `/git-setup init` as part of its post-scaffold pipeline
- ⚠️ **README images: file-first, not inline.** When generating or auditing a README that needs hero/cover/diagram art, write SVG/PNG to `assets/` and reference via `<img src="assets/foo.svg">` — do NOT paste raw `<svg>` markup into README.md. Inline SVG renders on github.com but is stripped to bare `<text>` nodes by IDE previews, terminal markdown viewers, npm/crates pages, and AI readers, producing an unreadable wall of words.
