---
brief: A blocked_on USER: prefix means the owner can act on it today. A prerequisite mislabelled USER: renders as an owner gate and gets read back as a real ask by the agent that wrote it. The check that needs no label: of the things about to go in front of the owner, which can they act on today? Anything waiting on other work is blocked-by that work.
triggers:
  - topic:owner-gate
  - topic:blocked_on
  - phrase:"needs you"
related:
  - rules/owner-decisions-go-through-a-wizard.md
  - skills/tasks/SKILL.md
tier: 1
category: rules
updated: 2026-08-27
stale_after_days: 180
---

# `USER:` means the owner can act on it today

A `blocked_on: USER:` prefix is the board's marker for an owner gate, so a
prerequisite mislabelled `USER:` renders under GATES (you) and is then read back
as a real ask, by the same agent that wrote it, with the confidence a renderer
lends. gcp-watcher, 2026-08-26 (`mist-20260826-125403-68`, S3): led an owner recon
with a password rotation the owner had ruled, an hour earlier, happens only after
the auth module lands. The cheap check that needs no label to be right: of the
things about to go in front of the owner, which can they act on today? Anything
waiting on other work is `blocked-by` that work, whoever eventually decides it.

## A UI is a medium, not an exemption

Owner ruling, 2026-08-26, verbatim: **"a decision SET is presented as ONE
decision page (the format that already works), never N rows."**

Everything above names chat replies and docs offered for review, because that is
where the rule was first paid for. Those are its examples. Its scope is its
reason, which is the owner's attention, and attention is spent the same way by a
list of rows on a screen. A surface that puts six questions in front of him is
the same act as a reply that lists six questions.

The lived case, and it is this rule's own subject failing to bind: the kanban
Decisions view listed six agent questions as six rows. The rule was always-loaded
throughout. A peer asked, an hour before the owner complained, how he should
discover and answer decisions, which is precisely this rule's topic, and the
answer never cited it. Six rows in a web UI matched neither written example, so
it was read past (`mist-20260826-124410-0a`, S3).

**The check, whatever you are building or writing:** count what the surface asks
the owner to answer. More than one, and this rule governs it.

## The pick was never the hard part

The same evening supplies the design half, and it is the more useful finding.
Seven decisions were ruled. On every one where an agent had stated a pick, the
owner took that pick (`1a`, `2a`, `3a`, `4a`, `D1a`). Not one option choice
changed an outcome. What carried content was prose he typed: "the note is the
real ruling", "in that order", and a standing ruling he added that no option
offered.

So a decision surface built as pre-answered options with a small note box under
them is tuned for the half nobody disputes and cramped for the half that decides
what the work means. That is why a chat box beat it: chat is a cursor.

When you build or review any surface that collects the owner's rulings, the
sentence is the ruling and the options are optional shorthand that seed it. Size
the surface accordingly. And read this next to step 2 above: a question arriving
with the agent's own pick already attached, which the owner then simply agrees
with, is usually a question that should have been defaulted and recorded rather
than asked (`mist-20260826-130050-ff`, S3).

