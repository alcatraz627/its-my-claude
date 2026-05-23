# Migration 0006 — CLAUDE.md Restructure

**Status:** ✅ Complete (Phase A + Phase B executed 2026-04-24)
**Session:** `impr-cfg-7a`
**Backup:** `~/.claude/assets/reports/20260424-claude-md-restructure/CLAUDE.md.pre-restructure.bak`

## Summary

Split 634-line `~/.claude/CLAUDE.md` into a 122-line thin-router + 27 sub-files organized under new `rules/`, `features/`, `conventions/` directories. Introduced two-axis placement rule (category × tier) at `~/.claude/PLACEMENT.md`, prefixed trigger taxonomy (`tool:`, `topic:`, `phrase:`, `skill:`, `mcp:`), and frontmatter-based staleness tracking.

## Why

CLAUDE.md had drifted past the adherence ceiling — frontier LLMs reliably follow ~150–200 instructions, and Claude Code's own system prompt burns ~50. A 634-line CLAUDE.md meant the tail ⅓ of rules were being silently ignored. Prompt caching makes cost a weak argument, but **adherence** is a real, measurable ceiling.

See `~/.claude/assets/research/20260424-agent-instructions-best-practices.md` (web research) and `~/.claude/assets/reports/20260424-claude-md-restructure/review.md` (local-consolidation review) for the full rationale.

## Scope

Operates strictly within `~/.claude/`. No per-project config touched. The shared library (`~/.claude/skills/shared/`) is left untouched — new sub-files under `features/` and `conventions/` link to canonical shared docs rather than duplicating.

## Label changes

None — no `std::claude::*` labels renamed. Four new clusters added to NAMESPACE.md:

- `std::claude::rules` → `~/.claude/rules/`
- `std::claude::features` → `~/.claude/features/`
- `std::claude::conventions` → `~/.claude/conventions/`
- `std::claude::placement` → `~/.claude/PLACEMENT.md`

## Path moves

| Old path | New path | Mechanism |
|----------|----------|-----------|
| `~/.claude/doc-writing-guidelines.md` | `~/.claude/conventions/doc-writing.md` | Physical move + symlink preserved at old path for per-project ref compat |
| `~/.claude/CLAUDE.md` (section: llm-mini) | `~/.claude/features/llm-mini.md` | Content extracted, brief+pointer remains in CLAUDE.md |
| `~/.claude/CLAUDE.md` (section: WAL) | `~/.claude/features/wal.md` + links to `skills/shared/wal-format.md` | Wrapper pattern |
| `~/.claude/CLAUDE.md` (section: Desktop Automation) | `~/.claude/features/desktop-automation.md` + links to `skills/shared/desktop-automation.md` | Wrapper pattern |
| `~/.claude/CLAUDE.md` (section: Dev Servers) | `~/.claude/features/dev-servers.md` + links to `~/.claude/dev-servers-guide.md` | Wrapper pattern |
| `~/.claude/CLAUDE.md` (section: Doc Naming) | `~/.claude/conventions/doc-naming.md` + links to `skills/shared/doc-naming.md` | Wrapper pattern |
| 20+ other CLAUDE.md sections | `~/.claude/{rules,features,conventions}/*.md` | Content migration |

## Files affected

### Created (29)
- `~/.claude/PLACEMENT.md`
- `~/.claude/rules/{communication,testing,shell,git,corrections}.md` (5)
- `~/.claude/features/{wal,memory,context-retention,proposals,mcp-catalog,llm-mini,hinter-pipeline,shared-library,plugins,desktop-automation,hooks-tui-limits,dev-servers,claudew,shell-memory,fiber-snatcher}.md` (15)
- `~/.claude/conventions/{doc-naming,asset-management,cli-help-design,html-output,ascii-diagrams,doc-writing,scratch-files}.md` (7)
- `~/.claude/scripts/validate-triggers.sh` + `.py`

### Modified
- `~/.claude/CLAUDE.md` — rewritten to 122-line router (from 634)
- `~/.claude/LOOKUP.md` — added 3 new category tables + PLACEMENT.md row
- `~/.claude/NAMESPACE.md` — added 4 new cluster definitions + session tag

### Symlinked
- `~/.claude/doc-writing-guidelines.md` → `conventions/doc-writing.md`

### Unchanged (canonical)
- `~/.claude/skills/shared/*.md` — still authoritative; new sub-files link to them

## Phases

| Phase | Description | Date | Notes |
|-------|-------------|------|-------|
| A | Structure: PLACEMENT, dirs, stubs with frontmatter, validator | 2026-04-24 | Zero mutation of CLAUDE.md |
| B | Content migration + CLAUDE.md rewrite + symlink + LOOKUP refresh + proposals filed | 2026-04-24 | Validator green: 0 errors, 4 intentional collisions, 27 files |

## Recovery

If a reference to one of the extracted sections no longer resolves:

1. Check `~/.claude/LOOKUP.md` — find the sub-file under `rules/`, `features/`, or `conventions/`
2. Update the reference in place
3. For content that linked to specific CLAUDE.md line numbers: those are gone; link to the named section in the new sub-file instead

If rollback is ever needed:

```bash
cp ~/.claude/assets/reports/20260424-claude-md-restructure/CLAUDE.md.pre-restructure.bak ~/.claude/CLAUDE.md
# Trash the sub-files and PLACEMENT.md if reverting fully:
# trash ~/.claude/{rules,features,conventions,PLACEMENT.md}
# trash ~/.claude/doc-writing-guidelines.md  # symlink
# Restore original doc-writing-guidelines from backup if needed
```

Backup MD5: `ac024bbd83d561875660a47645240e5d`.

## Follow-up (this session, post-restructure)

Additional edits based on your review on 2026-04-24:

### Git split (per user decision — 2b option)
- New file: `~/.claude/features/git-commands.md` (Tier 2 — load when user is working with git)
- Trimmed: `~/.claude/rules/git.md` to keep rules + dangerous-command list + skill refs only

### Other surgical edits
- `rules/communication.md` — added escape-hatch criteria
- `rules/shell.md` — added script-preference rule, Glob/Grep/Read preference, anti-pattern reminder
- `rules/testing.md` — added topic-tagged rules from mistake-patterns.md
- `conventions/asset-management.md` — promoted `~/.claude/.claude/` anti-pattern
- `conventions/cli-help-design.md` — added man-pages + stdio note
- `conventions/doc-writing.md` — prepended overview section
- `conventions/ascii-diagrams.md` — added 3 gum-tui examples + link to gum-rendering-examples.md
- `conventions/scratch-files.md` — added lookup commands + scratchpad link
- `conventions/html-output.md` — expanded with tailwind/daisyui + promotion workflow + TODO

## Cross-references

- **Post-migration watchpoints:** `~/.claude/assets/reports/20260424-claude-md-restructure/post-migration-watchpoints.md` — **check during the 2-week transition window**
- **Plan v3:** `~/.claude/assets/reports/20260424-claude-md-restructure/plan-v3.md`
- **Review (Agent B):** `./review.md` (same dir)
- **Web research (Agent A):** `~/.claude/assets/research/20260424-agent-instructions-best-practices.md`
- **Usage patterns scan:** `./usage-patterns.md`
- **Structure reference:** `./STRUCTURE.md`
- **Handoffs:** `./phase-a-handoff.md`, `./phase-b-complete.md`
- **Filed proposals:** `prop-20260424-112406-bd`, `-112416-e5`, `-112426-13`, `-112433-52`
- **Weekly todos:** `~/.claude/weekly-todos.md` (2026-04-27 soak check, 2026-05-18 3-week review)

## Related migrations

- **0001** — Namespace introduction (this builds on `::rules / ::features / ::conventions` as new clusters)
- **0007** (planned) — Scripts folder cleanup; gated on user greenlight
