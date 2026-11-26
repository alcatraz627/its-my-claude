# Document Naming & Session Tagging Reference

> Canonical reference for how Claude names files and tags them with session identity. The quick rule is `~/.claude/conventions/doc-naming.md`; this file is the full spec, and the two agree.
> Referenced by: CLAUDE.md, core-dump, catchup, cogitate, WAL format, GUIDELINES.md

---

## Session ID

Every session gets a short ID derived from the first user prompt.

**Format:** `[keyword]-[keyword]-[2hex]`

| Rule | Detail |
|------|--------|
| Keywords | 1-2 topic words from first prompt (verb + noun preferred) |
| Truncation | Max 5 chars per keyword (`refactor` → `refac`) |
| Hex suffix | Sum of prompt char codes mod 256, formatted as 2-char hex |
| Vague prompts | Use `misc-[2hex]` |
| Announcement | Print `Session: [id]` at session start |

**Examples:**
- "Fix the authentication bug in the login flow" → `fix-auth-7a`
- "Add a bar chart to the dashboard" → `add-chart-f1`
- "hi" → `misc-a3`

---

## Filename Convention

### Datestamped (point-in-time artifacts)

Files created once, rarely edited after. Prefix with `YYYYMMDD-`.

**Format:** `YYYYMMDD-<descriptive-slug>.md`

**Applies to:**

| Category | Location | Example |
|----------|----------|---------|
| Scratchpad plans/learnings | `.claude/scratchpad/` | `20260331-auth-refac-plan.md` |
| Checkpoints / core-dumps | Project root | `_20260331-fix-auth-3b.claude.md` |
| Cogitate topic files | `~/Documents/Claude/Topics/` | `20260331-redis-caching.md` |
| Research / audit outputs | Varies | `20260331-perf-audit-results.md` |
| Architecture decisions | `.claude/scratchpad/` | `20260331-db-schema-decision.md` |
| Postmortems | `.claude/scratchpad/` | `20260331-outage-postmortem.md` |

### Non-datestamped (living documents)

Files updated continuously across sessions. No date prefix.

**Applies to:**

| Category | Example |
|----------|---------|
| WAL | `wal.md` |
| Runtime notes | `runtime-notes.md` |
| Indexes | `MEMORY.md`, `_index.claude.md`, `_insights.claude.md` |
| Configuration | `CLAUDE.md`, `GUIDELINES.md`, `SKILL.md` |
| Registries | `port-registry.md`, `mcp-catalog.json` |
| Memory files | `.claude/projects/.../memory/user_role.md`, `feedback_no-trailers.md`: a type prefix (`user_`, `feedback_`, `project_`, `reference_`) and no date |
| Source code | `*.ts`, `*.js`, `*.py`, etc. |

### Decision rule

> **Would a future reader benefit from knowing _when_ this was written?**
> - Yes → datestamp the filename
> - No, it evolves over time → no datestamp

---

## Session ID Tagging

Embed session provenance in **point-in-time documents** via HTML comments with timestamps. Living documents (the non-datestamped list above, including `LOOKUP.md`, `PLACEMENT.md`, `GLOSSARY.md` and `NAMESPACE.md`) carry no session tag, because their history is in git. Memory files carry none either.

### Format

```
<!-- sessions: fix-auth-3b@2026-03-31, add-chart-f1@2026-03-29 -->
```

Each entry is `session-id@YYYY-MM-DD`: the date is when that session last touched the file.

### Rules

| Scenario | Action |
|----------|--------|
| **New point-in-time document** | Add `<!-- sessions: [id]@[today] -->` on the second line (after title or frontmatter) |
| **Living document** | No tag. If an old tag is there, delete it when touching the file |
| **Existing point-in-time doc, same session** | Update the timestamp if >1 day old: `fix-auth-3b@2026-03-30` → `fix-auth-3b@2026-03-31` |
| **Existing point-in-time doc, new session** | Append: `<!-- sessions: fix-auth-3b@2026-03-31, add-chart-f1@2026-03-29 -->` |
| **Cleanup stale entries** | Remove entries where the timestamp is >3 days old. Do this when touching the file for any other reason: don't make a special pass. |
| **WAL** | Session encoded in `## Session: YYYY-MM-DD HH:MM [session-id]` header: no separate tag |
| **Runtime notes** | Session ID in `## session: [desc] [session-id]: YYYY-MM-DD` heading: no separate tag |
| **Source code** | Never add session tags to `.ts`, `.js`, `.py`, etc. |

### Lifecycle example

```
Day 1: <!-- sessions: fix-auth-3b@2026-03-29 -->
Day 2: <!-- sessions: fix-auth-3b@2026-03-30, add-chart-f1@2026-03-30 -->
Day 3: (fix-auth-3b not touched, stays at 03-30)
Day 4: add-chart-f1 touches file again:
        <!-- sessions: fix-auth-3b@2026-03-30, add-chart-f1@2026-04-01 -->
Day 5: new session touches file, fix-auth-3b is >3 days stale → removed:
        <!-- sessions: add-chart-f1@2026-04-01, new-feat-7c@2026-04-02 -->
```

### Discovering session history

```bash
# Find all artifacts from a specific session
grep -r "fix-auth-3b" ~/.claude/ --include="*.md"

# Find all artifacts touched today
grep -r "@$(date +%Y-%m-%d)" ~/.claude/ --include="*.md"

# Find all artifacts from a specific date
ls -la ~/.claude/scratchpad/**/20260331-*
```

---

## Integration Points

Skills and tools that create documents MUST consult this file:

| Skill/System | How it uses this reference |
|--------------|---------------------------|
| `/core-dump` | Checkpoint filename: `_YYYYMMDD-<session-id>.claude.md` + symlink `_checkpoint.claude.md` |
| `/catchup` | Globs `_*.claude.md`, follows symlinks: datestamped names are compatible |
| `/cogitate` | Topic files in `~/Documents/Claude/Topics/` get `YYYYMMDD-` prefix |
| WAL system | Session header includes `[session-id]` per `wal-format.md` |
| Runtime notes | Session heading includes `[session-id]` |
| Memory system | Memory files keep their type prefix (`user_`, `feedback_`, `project_`, `reference_`), no date and no session tag |
| Scratchpad | Plans and learnings get `YYYYMMDD-` prefix |
