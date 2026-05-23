---
name: dep-audit
description: Runs npm audit and npm outdated, cross-references key dependencies against known breaking versions, and produces a prioritized upgrade list — separating critical security patches from optional major upgrades. With --fix, applies npm audit fix for patch-level security patches only.
allowed-tools: Read, Bash, Glob
user-invokable: true
argument-hint: "[--fix]"
context: fork
---

## Brief

Runs `npm audit --json` and `npm outdated --json`, focuses on key project dependencies (Next.js, React, Drizzle, TanStack Query, NextAuth), and produces a prioritized upgrade report: critical security patches first, then major-version gaps, then optional updates. With `--fix`, applies `npm audit fix` for patch-level security fixes only — never `--force`.

# Dep Audit

Dependency security and freshness auditor for this Next.js frontend. Knows which libraries are critical to the project's stack and flags when they fall more than one major version behind. Separates must-fix security issues from optional upgrade opportunities.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before any write during `--fix` mode.

## Usage

```
/dep-audit [--fix]
```

| Argument | Type     | Description                                                                                       |
| -------- | -------- | ------------------------------------------------------------------------------------------------- |
| `--fix`  | optional | After the audit report, run `npm audit fix` to apply patch-level security fixes. Never `--force`. |

---

## Phase 1 — Security Audit

### 1.1 — Run npm audit

```bash
npm audit --json 2>&1
```

Parse the JSON output. Extract all vulnerabilities with `severity: "critical"` or `severity: "high"`.

For each vulnerability, record:

- Package name
- Severity level
- CVE / GHSA ID
- Fix available (yes/no via `fixAvailable` field)
- Affected version range

Print: `  npm audit complete — N critical, N high, N moderate, N low.`

### 1.2 — Categorize by fix availability

| Category                | Condition                                                                   |
| ----------------------- | --------------------------------------------------------------------------- |
| **Must fix now**        | critical or high severity, fix available via `npm audit fix`                |
| **Needs manual update** | critical or high severity, no automatic fix (likely a major version update) |
| **Monitor**             | moderate severity — note but don't prioritize                               |

---

## Phase 2 — Outdated Key Dependencies

### 2.1 — Read current versions

Read `package.json` to note installed versions of the key dependencies listed below.

### 2.2 — Run npm outdated

```bash
npm outdated --json 2>&1
```

Parse the JSON. For each outdated package, record: `current`, `wanted` (semver-compatible), `latest`.

### 2.3 — Check key dependencies

These libraries have high impact when outdated — always flag them explicitly:

| Package                      | Why it matters                                                         |
| ---------------------------- | ---------------------------------------------------------------------- |
| `next`                       | Core framework — major updates require App Router compatibility review |
| `react`, `react-dom`         | UI library — major updates require component compatibility review      |
| `@tanstack/react-query`      | Server state — major updates may change QueryKeys/mutation API         |
| `drizzle-orm`, `drizzle-kit` | ORM — migration compatibility must be verified before upgrading        |
| `next-auth`                  | Auth — major updates may change session/adapter API                    |
| `@auth/drizzle-adapter`      | Auth adapter — must stay in sync with next-auth                        |
| `typescript`                 | Type checker — major updates may introduce new strict errors           |

**Flag BREAKING RISK if:** current major version is more than 1 behind latest (e.g., using v4 when v6 is latest).

**Flag MINOR UPDATE if:** current major version matches latest but minor/patch is behind.

---

## Phase 3 — Report

Source gum-tui.sh and render the report using panels. Render only sections that have data — skip empty sections entirely:

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_header "Dep Audit — frontend"

# Render only if critical/high vulns exist:
gum_panel "CRITICAL / HIGH SECURITY" \
  "✗ lodash 4.17.19 — Prototype pollution (GHSA-xxxx)" \
  "  Fix: npm audit fix  (patch available)" \
  "" \
  "✗ axios 1.4.0 — SSRF vulnerability (GHSA-yyyy)" \
  "  Fix: manual update to ≥1.6.0 required"

# Render only if major version gaps exist:
gum_panel "MAJOR VERSION GAPS (breaking risk)" \
  "⚠ next-auth: 4.x → 5.x available" \
  "  Impact: Session API, adapter API changes" \
  "  Action: Review NextAuth v5 migration guide before upgrading"

# Render only if minor/patch updates exist:
gum_panel "MINOR / PATCH UPDATES (optional)" \
  "· react: 19.0.0 → 19.2.3 available  (patch)" \
  "· typescript: 5.3.0 → 5.8.0 available  (minor)"

gum_complete "dep-audit" \
  "Security=N critical/high (N fixable with npm audit fix)" \
  "Breaking risk=N major-version gaps" \
  "Optional=N minor/patch updates available" \
  "Run=npm audit fix (N patch-level fixes available)"
```

If zero issues: call `gum_success "No security vulnerabilities or major version gaps found."`

---

## Phase 4 — Fix Mode (if --fix)

If `--fix` was passed and there are patch-level security fixes available:

```bash
npm audit fix
```

**Never run** `npm audit fix --force` — this can introduce breaking major version changes without warning.

After running, re-run `npm audit --json` to verify the vulnerability count dropped. Print:

```
  ✓ npm audit fix applied — N vulnerabilities resolved.
  Remaining: N (require manual update — see report above)
```

---

## Notes

- Uses `context: fork` — runs in isolated context.
- **Never runs `npm audit fix --force`** — this can silently upgrade major versions and break the app.
- FastAPI backend (`../backend/`) has its own Python dependency audit — this skill covers the frontend only.
- Next.js major upgrades require App Router compatibility review — see the Next.js upgrade guide.
- Drizzle `drizzle-orm` and `drizzle-kit` versions must be kept in sync — upgrading one without the other breaks migration generation.
- `legacy-peer-deps=true` is set in `.npmrc` — this may suppress some peer dependency warnings that are real issues worth investigating.
