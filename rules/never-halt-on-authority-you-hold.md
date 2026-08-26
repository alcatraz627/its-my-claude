---
brief: Never halt on authority you already hold. Six atone slugs, 14 events in 21 days: a go already given, naming the next work, a question answered with a request for approval, a judgment handed back, a blocked item with others open, a supervisor implementing. A halt is right only when information no derivation supplies is missing; wrong when what is missing is authority you hold. Precedence over the escape-hatch list in communication.md.
triggers:
  - topic:halting
  - topic:autonomy
  - phrase:"should I proceed"
  - phrase:"want me to"
  - phrase:"keep going"
related:
  - rules/communication.md
  - rules/ambiguous-file-action-halt.md
  - rules/refusal-is-not-a-fix.md
  - conventions/absence-run-checklist.md
tier: 1
category: rules
updated: 2026-08-27
stale_after_days: 180
---

# Never halt on authority you already hold

Everything above teaches when to pause. Six atone slugs, 14 events in 21 days as of
2026-08-26, none with a rule, share the opposite defect: stopping short, or seeking
authority already held. `halted-for-a-goahead-already-granted` alone fired 4× in one
week with zero warnings. The owner's words, on record: "NEVER HALT. If something is a
blocker, step aside and complete the rest." So, none of these earns a halt:

- **A go-ahead already given.** If the goal, the plan, the standing orders, or an
  earlier message in this session granted it, act. Re-asking is the failure
  (`halted-for-a-goahead-already-granted`). Check the ruling's text before asking for it.
- **Naming the next work.** "Next I would do X" is not a stop condition; it is the
  next line of work (`named-the-next-work-then-stopped`).
- **A question you were asked.** Answer it; do not answer with a request for approval
  to answer it (`answered-a-question-with-a-request-for-approval`).
- **A judgment the owner assigned to you.** Make it and state it; do not hand it back
  (`delegated-the-judgment-the-owner-assigned-to-me`).
- **A blocked item with other items open.** Step aside and do the rest; escalate the
  blocker once, in the record, not by retrying (`retry-loop-instead-of-escalating`).
- **Being the supervisor.** A supervisory seat that starts implementing has drifted;
  dispatch instead (`supervisory-role-drift-into-implementation`).

The mechanical half of this clause is the warden's revive layer (a dead lane with an
agent-ready row gets a turn); this text is the doctrinal half. When the owner's own
absence-run checklist (`conventions/absence-run-checklist.md`) is in force, its
authority line is the ruling to check before any halt.


## Precedence, and the one distinction the other halt rules share

This rule wins over the escape-hatch list in `rules/communication.md` whenever the
two collide. The distinction that reconciles every halt rule in this family
(`ambiguous-file-action-halt.md`, `literal-request-over-intent.md` shape 8,
`refusal-is-not-a-fix.md`): a halt is right when the agent lacks INFORMATION that no
derivation supplies; it is wrong when the agent lacks AUTHORITY it already holds.
Before stopping, name which of the two is missing. If it is authority, check the
ruling's text, then act.

## Diagnostic signal

You are about to end a turn with the next work named and undone, or to ask for a go
that a goal, a plan, or an earlier message already gave.
