---
brief: Never describe the size or nature of work in the source artifact's vocabulary. A design tool's two frames, a spec's two versions, a doc's two revisions all read as "rebuilt" while the change in code is an edit to one file. Size the work by the diff it costs in the thing you will actually change, and say that number.
triggers:
  - topic:scope-estimate
  - topic:figma
  - topic:design-to-code
  - topic:diff-report
  - phrase:"rebuild"
  - phrase:"rewrite"
  - phrase:"from scratch"
  - phrase:"full rework"
  - phrase:"how big is this"
  - phrase:"what would it take"
related:
  - rules/structural-claim-without-reading-code.md
  - rules/right-sized-code.md
  - rules/audit-file-character-before-applying-global-rule.md
  - rules/no-silent-ui-surface-deletion.md
tier: 1
category: rules
updated: 2026-09-01
stale_after_days: 180
---

# Size the change in the target's vocabulary, not the source's

When you compare two versions of a source artifact and then report what the work
costs, report it in the units of the thing you will change. A design file holds
two separately drawn frames, so a restyled section reads as a rebuild. A spec
holds two revisions, so a renamed field reads as a migration. The code holds one
component with a data array, and the honest number is forty lines in one file.

The failure is not an estimate that came out high. It is answering "how big is
this" with a fact about the wrong artifact, stated with the confidence of a fact
about the right one. The owner then prices work that does not exist.

## The rule

Before any word that sizes work (rebuild, rewrite, rework, from scratch, port,
migration, overhaul, or a line count, or a commit plan), answer three questions:

1. **Which artifact is that word describing?** If it is the design file, the
   spec, the ticket, or the old version of a doc, it is not yet an answer.
2. **What is the diff in the artifact I would edit?** Name the files, and for
   each one roughly how much of it moves. Open them first. A word like "rebuild"
   is a claim about code and needs the same grounding as any other claim about
   code (see `rules/structural-claim-without-reading-code.md`).
3. **What already exists that this reuses?** A change that consumes the current
   primitives, tokens and conventions is not a rebuild of them. Say which ones
   survive, because that is usually the reassuring half and it is the half that
   gets dropped.

Then give the number in the target's units, and only then, if it is genuinely
useful, describe how the source artifact differs.

## The inverse counts too

Under-sizing is the same defect wearing the other face, and it is more dangerous
because nobody questions it. "Just a text change" for an edit that reorders a
data array the motion system indexes into, or that orphans CSS elsewhere, buys a
yes for work whose real cost lands later. The obligation is accuracy, not
smallness.

## Check the target before you assume it matches the source

A corollary that fires constantly in design-to-code work. Having diffed v3
against v4, it is tempting to treat every difference as an edit the code needs.
The code is a third artifact with its own history, and it may already hold some
of v4, may deliberately differ from both, and may have house conventions
(punctuation, casing, naming) that the design file does not follow. Diff against
the code, not against your model of it.

## What this rule does NOT mean

- Not a ban on describing the source. Explaining how the design changed is
  useful. It just is not an answer to what the work costs.
- Not a demand for precise line counts on everything. "One file, most of it
  untouched" is a fine answer. "Rebuild" is not, unless it is true.
- Not a reason to hedge. Give a number and be willing to be wrong about it,
  rather than reaching for a vague heavy word.

## Diagnostic signal

You are about to write rebuild, rewrite, or rework, and you have not opened the
file you would be rebuilding. Second signal: the owner asks why a change you
described needs so much work, and your answer starts by explaining the design.

## Provenance

2026-09-01, landing-app. Asked to diff two Figma frames and say what to apply, I
reported the Platform section as a "full rebuild, 122 lines". In Figma it is two
differently drawn frames, one 880px and one 1079px, which is where the word came
from. In code it is one component: reorder a three-item array, swap three
strings, delete one connector, change a card's inner layout from stacked to two
columns. No new components and no new CSS, because the `Card` primitive already
had the variant the new design wanted. The owner had just merged two heavy PRs
reworking that design and reasonably asked why another rebuild was needed. The
answer was that none was, and the word was mine.
