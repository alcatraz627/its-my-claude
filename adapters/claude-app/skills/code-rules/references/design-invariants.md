# A proposed design must not break the doc's own constraints

When a design has two modes that return the same fields differently (lean
and enriched, cached and live, fast and correct), re-read the doc's goals and
constraints section as a checklist before writing any "mode A trades X for
Y" framing.

## Example

A jobs-list design proposed that enriched mode skip a join and derive total
and processed counts live from tasks, while lean mode read a stored
`processed_count` that could lag. The pitch: "Lean trades freshness for cost,
enriched is always correct."

That broke constraint 4 in the same doc: lean and enriched must never show a
different state for the same job. Different total and processed values would
classify the same job differently. The constraint was written by the same
author, in the same doc, and never re-checked against the proposal. The
implementation later used the join in both modes, so no bad code shipped. The
proposal was still the mistake: a design doc that contradicts its own
constraints misleads the next reader, and catching it later was luck.

## The check

Before writing a "mode A versus mode B" comparison:

1. Does the divergence touch any field the consumer renders state from?
2. If yes, did the user explicitly approve that divergence?
3. If not approved and the values diverge, stop. Align the modes on those
   fields, or put the conflict to the user before committing to the framing.

## What this does not mean

- Modes may differ on additive fields: extra aggregates, extra detail. The
  rule fires only on fields that drive a state or classification the
  consumer shows.
- Performance versus cost framing is fine when no rendered-state field
  differs.

## Diagnostic

You are about to write "mode A is faster, mode B is more correct" and have
not checked whether the consumer derives state from a field that differs
between them.
