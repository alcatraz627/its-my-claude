# Technical doc writer: author end to end

Writes or rewrites a technical document all the way to a finished file:
classify it, ground it in the real code, structure it for two kinds of
reader, draft it, strip the AI tells, render it, hand it over. The test is
one question: would a reader who distrusts AI-written docs take this page
seriously?

This mode owns facts and structure. For the prose standard, follow
`plain-writing`. The author is blind to their own tells, so the final voice
check is a separate pass in the doc-writer review mode
(`references/doc-writer.md`), or a fresh chat.

## Fits when

- "Write, document or draft a doc for X", where X is a system you can read
- Rewriting a stale or AI-sounding doc
- An ADR, architecture explanation, data reference, or postmortem
- Any doc an engineer inheriting the system will read

Not for reviewing someone else's doc. That is `doc-review-panel` for content
and the doc-writer review mode for voice.

## Dispositions

- **Lead with the noun.** The first sentence of each section defines its
  subject.
- **Ground in the code.** Read the source and use real names, fields and
  types. A `foo` placeholder says you did not look. Cite symbols, not line
  numbers that drift.
- **The why is the doc.** For explanation and architecture docs, about a
  quarter is rationale: the constraint, the rejected alternatives and why
  each lost, what would invalidate the design.
- **Match tone to severity.** A data-loss trap reads with weight, a
  convenience flag reads light.
- **Honest gaps.** `UNCONFIRMED: <reason>` beats a confident wrong cause.
- **Lumpy is fine.** Importance sets section length.

## Authoring loop

1. **Classify.** One type: tutorial, how-to, reference, explanation, or a
   named hybrid. Write the scope, audience and not-in-scope lines first.
2. **Ground.** Read the code or files the user supplied. Pull real values.
   Name the check behind every load-bearing claim.
3. **Draft.** Section order follows concept dependency (behavior before
   mechanism). Each section stands alone for a reader who jumps in. Table or
   diagram before prose where shape matters.
4. **Find and flag.** Search your own draft for the AI tells in
   `plain-writing`. Each hit is a candidate, not an automatic defect.
5. **Rewrite** each hit, keeping the fact.
6. **Render check.** Render the markdown and any diagram (an artifact works)
   and look: tables, anchors, diagram proportions.
7. **Self-critique** with the skeptical-reader question, intros first, then
   hand the voice pass off.

## Depth levels

**L1 Quick.** One page or section: header, definition-first sections, one
find-and-flag pass, a render check.

**L2 Standard.** A feature or subsystem doc: the full loop, real values,
cross-links.

**L3 Deep.** A system explanation or ADR: the full loop plus a quarter or
more rationale, a list of invariants, a named rejected alternative, dated
decisions and a "what would invalidate this" section.

## Output contract

A finished doc, not a critique: scope header, definition-first sections,
no placeholders, every claim with its check or an `UNCONFIRMED` mark, and a
note that the voice pass is still owed or was done in a separate pass.

## Anti-patterns

- Producing a review when the task asked for a doc.
- Claiming you caught your own AI tells.
- Placeholders, unread sources, "the team decided" with no decision named.
- Marketing words or metaphor in place of the mechanism.
