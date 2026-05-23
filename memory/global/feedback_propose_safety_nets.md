---
name: Proactively propose safety nets — over-suggesting is fine, missing is regrettable
description: When a project lacks safety nets that would prevent regrettable damage (idempotency, dry-runs, diff previews, undo, commit rules), surface ASAP — even on existing projects. User explicitly tolerates over-reach in this domain.
type: feedback
---

**Direct quote from user (2026-05-07):**
> "Safety nets are very much important. Doesn't have to be a first PR, but
> it has to be called out as soon as possible, even if it's an existing
> old project and you notice it doesn't have the safety nets that could
> help prevent something regrettable. Even if you overdo it or overreach,
> just confirm with the user and they will correct you if needed, which
> you use to improve your global + local pattern matching for such things
> in claude notes."

## How to apply

When working in any project:

1. INDEX existing safety nets: commit rules, test suite, CI checks,
   idempotency, dry-run modes, diff previews, undo, backups, rate limits,
   confirmation prompts, feature flags.
2. Compare against the project's risk profile (see
   `feedback_proactive_question_ownership.md` for project-ceiling check).
3. If a relevant safety net is missing, surface it explicitly. Examples:
   - "I notice this script edits files in-place — should it have a dry-run flag?"
   - "This refactor touches 40 files; want me to gate behind a feature flag?"
   - "We're running mutations against shared data; want me to add an
     idempotency check so re-runs are no-ops?"
   - "There's no commit rule documented for this project — should I avoid
     committing without explicit per-change approval?"
4. Ask whether to add it. User may say "skip", "add later", or "yes now".
   All fine — surfacing is the value.
5. Save the user's response to project memory so future sessions inherit
   the preferences.

## Risk profiles by project type (calibration examples)

- **Org product, real customers, shared codebase** (e.g., enhancement-product):
  - Required: absolute commit rule, CI checks, automated tests
  - Mostly enforce existing safety; flag gaps if any user-facing surface
    lacks reversibility
- **One-off sync script with machine-generated output** (e.g., notion-sync):
  - Desired: idempotency, pull-sync (auto-revert), confirmation prompt,
    diff preview before push
  - "YOLO with built-in safety" — high freedom, high reversibility
- **Production data-handling tool** (e.g., logger-crab-class):
  - Required: input validation, structured logging, error boundaries,
    rollback path
- **Internal personal tooling** (e.g., i-dream-class):
  - Lighter safety, but: legible diagnostics, self-explanatory state files,
    since user explicitly doesn't deeply review the code

## Cross-references

- `feedback_proactive_question_ownership.md` (global) — pair with this
- Project-level: `feedback_propose_safety_nets.md` (in project memory)
- Pairs with: `feedback_ambitious_vs_maximalist.md`
