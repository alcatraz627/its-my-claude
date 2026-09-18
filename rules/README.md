
# `~/.claude/rules/`: behavioral rules

Rules say what Claude MUST do. Write here for a process rule with measurable adherence, a hard guardrail with a known failure mode, or a correction graduated from the atone ledger after recurrence. Not for how a script works (`features/`), how output looks (`conventions/`), or a one-project preference (its local `.claude/rules/`).

Shape: YAML frontmatter (`brief`, `triggers:`, `related`, `tier`, `category`, `updated`, `stale_after_days`; `paths:` makes a rule scoped). Validate with `validate-triggers.sh`; regenerate `00-index.md` with `rules-index.sh`. Refine a similar rule rather than adding a near-duplicate. A rule that gates or budgets an action names the inaction it could license.

**Two caps, both mechanical (owner D1a, 2026-09-18).** An always-loaded rule holds its directive and precheck only, at most 2,200 bytes; provenance, lived cases and reasoning live verbatim in `~/.claude/rules-provenance/<name>.md`, which is never loaded. And text is not the fix for a slug over 20 events: a proposal adding rule text for such a slug is rejected unless it says why text will work where the injections did not; past 20 events a slug is a hook candidate or nothing.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/README.md`
