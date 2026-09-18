---
brief: "X stays / X unaffected / only threading needed" claims in plans, design docs, and reports must immediately become a verification task + a Standing-constraints checkpoint entry; mixed thread-vs-rebuild framing must be resolved with the user BEFORE implementation.
triggers:
  - topic:design-doc
  - topic:architecture-change
  - topic:refactor
  - skill:core-dump
  - skill:catchup
  - phrase:"only threading"
  - phrase:"unaffected"
  - phrase:"stays as is"
related: [rules/structural-claim-without-reading-code.md, features/context-retention.md, rules/testing.md]
tier: 1
category: rules
updated: 2026-09-01
stale_after_days: 180
---

# Invariant graduation — a "stays unchanged" claim is a constraint, not a sentence

When a plan, design doc, or report written this session asserts that something
existing survives the change ("the UI stays, only threading needed", "endpoint X
is unaffected", "most surfaces are reused"), that sentence binds nobody until it
is promoted. Promote it immediately, in the same turn it is written:

1. **A Task-tool task** — "verify <X> unaffected after implementation", so the
   claim has a consequence that blocks "done".
2. **A Standing-constraints entry** in the Resume Contract (`/core-dump` §2.6),
   copied VERBATIM with the check that would catch its loss (parity ledger,
   baseline screenshots, a named flow). A parity ledger's rows are SURFACES (this
   page, this table's width, this input's position, this card), not behaviours:
   a ledger that lists behaviours and not surfaces lets a rebuild pass every row
   and look worse (gcp-docs, 2026-08-26, after the owner refused a restructure
   that passed its ledger). Verbatim matters: paraphrase is where
   laundering starts, and the constraint must survive every later checkpoint.

## The mixed-framing clause

When the doc mixes framings — "thread the existing surfaces" in one section,
"rebuilt" in another — that is not a license to pick one silently. Resolve the
ambiguity into an explicit parity-or-rebuild statement WITH THE USER before
implementation. Checkpoint summarization otherwise resolves it toward whichever
reading has momentum: the implementing session's checkpoint restates rounds as
build items ("jobs list page NEW"), and by resume time the plan *is* new pages.

## Why this gets a rule

Doc-22 (versable-builder `docs/plan/22-job-siloed-catalog.md`, commit 3669c11):
three days of owner-reviewed UI was rebuilt-then-purged across two rounds because
the doc's threading language (lines 26-27, 38, 163) never became a constraint,
no Resume Contract carried it, and every gate verified the new flows — no
artifact represented the old UX, so nothing could fail on its absence. Atone
`rebuild-replaced-accumulated-ux-without-parity-audit`
(`mist-20260716-074938-54`, juror: very-wrong). The mirror case: the claude-ipc
hardening sprint's honest caveats ("8 commits, none independently reviewed")
were dropped by a successor's resume briefing — "checkpoint compression
laundered the debt" (RCA,
`~/Code/Claude/claude-ipc/.claude/output/20260716-rca/RCA.md`). One engine, two
directions: constraints and caveats are exactly what summarization drops while
task momentum survives.

## The UI surface purge gate

Extracted 2026-08-27 to `rules/no-silent-ui-surface-deletion.md`: before deleting a component, page, or route that appeared in any owner-reviewed round, a parity entry or owner approval in this turn; zero importers is not evidence.

## What this rule does NOT mean

- Not every sentence in a plan is an invariant. The bar: a claim that existing
  behavior, UX, or an accumulated asset survives the change.
- Not a freeze on deleting UI. It is a freeze on deleting it *silently*. A named
  parity entry or one line of owner approval clears the gate.
- Not a ban on rebuilds. A rebuild is fine once stated explicitly and paired
  with a parity checklist the user has seen.
- A halt under this rule needs a genuinely missing thing — information no derivation supplies, or authority not yet granted. Holding both, the rule does not apply: act (`never-halt-on-authority-you-hold.md`).

## Diagnostic signal

You are writing "X stays / unaffected / just threading" into a doc, or reading
one during implementation, and X appears in no task and no Standing-constraints
entry. Stop and promote it. Second signal: you are about to delete zero-importer
code that this same work stream orphaned — quarantine, prove parity against the
constraint's check, then delete.
