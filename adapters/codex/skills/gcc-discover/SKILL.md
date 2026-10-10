---
name: gcc-discover
description: Find relevant owner guidance or an unlinked Claude skill for a Codex task without loading the whole ~/.claude catalogue.
---

# Discover gcc guidance

Search `/Users/alcatraz627/.claude/skills/00-index.md` and `/Users/alcatraz627/.claude/skills-parked/INDEX.md` by the task's goal and synonyms. Also check the current Codex skill roster. If those are thin, search frontmatter triggers in `/Users/alcatraz627/.claude/rules/`, `features/`, and `conventions/`, then the relevant `LOOKUP.md` rows.

Return a short ranked set of matching paths and explain which instructions Codex can use directly, which need tool substitution, and which depend on Claude-specific hooks, `context: fork`, or the `Skill` tool. Read the full source before applying any rule or skill. Do not symlink a skill merely because it appeared in search; the Codex roster is intentionally curated.

If an index claims a file exists, verify the file on disk. If a search finds no match, say which trees and terms were searched before concluding it is absent. The retrieval pattern comes from `/Users/alcatraz627/.claude/skills/pick-skill/SKILL.md`; Codex can perform it inline without the Claude handoff workflow.

## High-value routes

Use this list as search hints, then read the source before applying it:

| Task | Source to inspect | Codex handling |
|---|---|---|
| UI work reviewed across rounds | `conventions/ui-charter.md`, `skills/ui-categorical-check/SKILL.md`, `rules/ui-visual-verification.md` | Keep project rulings in the charter; use the visual checklist with Codex's available browser or screenshots. |
| Execution-path or deploy change | `skills/deploy-parity-testing/SKILL.md`, `rules/exercise-based-verification.md` | Borrow the parity rows and evidence contract; substitute Codex tools for Claude seat dispatch. |
| Unclear environment or hook failure | `skills/doctor/SKILL.md`, `features/codex-adapter.md` | Run scoped health probes. Avoid Claude WAL and hook assumptions. |
| Critical review | `skills/skeptical-review/SKILL.md`, `skills/adversarial-review/SKILL.md` | Borrow the claim and evidence ledger; do an inline review unless delegation was explicitly requested. |
| Report or agent-facing CLI | `conventions/report-writing.md`, `conventions/agent-first-tools.md` | Use the genre and interface contracts directly. |
| Cheap runtime verification | `conventions/run-and-observe-affordance.md`, `skills/validate/SKILL.md` | Find or provide the smallest real exercise path; use Codex `validate` for the seven checks. |

Claude-only workflows in these sources are examples, not Codex commands. Do not port scheduling, dispatch, or project automation merely because a source mentions it.
