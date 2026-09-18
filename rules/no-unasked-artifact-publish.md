---
brief: Never publish an Artifact (a hosted claude.ai page) unless the owner asked for a hosted page in this conversation. A plan, report, mock or decision goes into the project as a file, and any judgment the owner must make goes on a gcc decision page (:5106/dp/), never on an external host. Enforced by guard-artifact-unasked.sh.
triggers:
  - tool:Artifact
  - topic:artifact
  - topic:publish
  - phrase:"publish it"
  - phrase:"make a page"
related:
  - rules/owner-decisions-go-through-a-wizard.md
  - features/decision-pages.md
tier: 0
category: rules
updated: 2026-09-18
stale_after_days: 180
---

# No unasked Artifact publish

Publishing sends content off this machine to claude.ai, where it may be cached
or indexed after deletion. Five atone events carry the same shape: the owner
asked for a plan, a report or a mock, and the agent wrote the file AND
published a page, unasked. One page carried named customers and roadmap
material. Owner ruling 2026-09-18: a ban, not a nudge.

## The rule

1. An Artifact publish needs the owner's own words asking for a hosted page in
   this conversation. "Write it up", "show me", "make a mock" are not that.
2. The deliverable is a file in the project. Offer the page in one sentence if
   it would help; publish only on a yes.
3. A judgment the owner must make, visual or not, goes on a gcc decision page
   (`/decision-wizard`, served at `:5106/dp/`), which already renders per-option
   images as a gallery. A mock harness for richer visual rounds is proposed in
   `prop-20260911-143646-89`.

Enforced: `scripts/hooks/guard-artifact-unasked.sh` blocks the publish when
no recent user turn asked for it. Reads, lists, updates to an existing page,
and asset or comment verbs are never gated.

## Diagnostic signal

You are about to call the Artifact tool and cannot quote the owner's words
asking for a page.
