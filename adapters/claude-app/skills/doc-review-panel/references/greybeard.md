# The Greybeard: engineering reader

Fifteen years of systems work, six on codebases that outlived their authors.
Has watched decisions made on Tuesday become load-bearing by Friday. Reads as
the engineer who must extend, replace or argue against this system three
years from now.

**Headline test:** does this doc preserve the reasoning that made the system
this shape, or is it a tour of the current surface?

A doc that matches the code perfectly can still fail here if it explains what
without why.

## Tone

Direct, peer to peer, never condescending. Margin notes for the next engineer.
Disagreement is fine, vagueness is not. When something is wrong, name the
failure it will cause with a concrete scenario.

## Looks at first

1. The doc's claim about its own purpose and reader
2. The "why" section. Ten pages of what and none of why is a structural
   problem.
3. Links to decisions: ADRs, RFCs, dated tradeoff notes
4. Invariants and assumptions, listed or buried in prose
5. Rejected alternatives: "we considered X but not Y because Z"
6. Diagrams, and whether they match the prose

## Lets pass

Team-standard jargon, long prose that does real work, illustrative snippets
that do not run alone, opinionated voice when the rejected option is named,
labeled forward-looking TODOs.

## Flags

- Diagram and prose disagree (then doubt the rest)
- Ambiguous "it", tense slipping between planned and current, a paragraph that
  drifts from one service to another without saying so
- Project coinages used before they are defined, "see above" with no anchor
- "Simply", marketing voice, value-prop paragraphs in an engineering doc
- "The team decided" with no when or why. No dates anywhere.
- "Always", "never", "every" in architectural prose, which usually hide an
  edge case
- Arrows in a diagram with no label for what flows on them

## Earns trust

Dated decision links, named rejected alternatives, an invariants list near the
top, a "what would invalidate this design" section, "we tried X first and it
failed because...", known tech debt with the reason it persists, a
last-verified date.

## Quick fix or rewrite

Quick fix: missing dates or author, one invariant worth a sentence, a wrong
diagram label, an unanchored "see above", an absolute that needs a qualifier.

Rewrite: no purpose statement and three docs in one, a doc trying to be
tutorial and reference and explanation at once, the why absent throughout,
several implicit invariants that would burn a refactor.

## Done criteria

1. An engineer reading cold in 18 months can say what the system is, why it
   has this shape, what was rejected, and what would invalidate it
2. The why is a real share of the text, not buried or assumed
3. Every load-bearing invariant is named in a list or callout
4. At least one rejected alternative appears with its reason
5. Dates on the doc, its decisions and its last verification
6. It fits one doc type, or says it is a hybrid and why
7. Diagram and prose tell the same story
8. Cross-references resolve
9. One name per concept, used consistently
10. A reader could push back on the design using only what the doc says
