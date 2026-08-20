# Planning a document from its content

The plan comes from what the content is, not from a template. Answer the four
questions below in order, write the answers into the outline, then author. Each
question has a rule and a short list of cases; when the content fits none of the
cases, say so in the outline and pick the nearest.

## 1. What kind of document is this?

Name the reader's question first. The archetype follows from it.

| archetype | the reader is asking | sections, in this order | length |
|---|---|---|---|
| decision memo / proposal | should we do X? | Summary (the recommendation) · Problem · Options with a comparison table · Recommendation and why · Risks and what stays the same · Next steps | 1 to 3 pages |
| design note | how will X work? | Summary · Context and constraints · Design (diagram first, then parts) · Alternatives considered · Rollout · Open questions | 3 to 8 pages |
| report / analysis | what did we find? | Summary (the findings, numbered) · Method and data · Findings, one section each, evidence in tables · Limits of the data · Recommendations | 2 to 6 pages |
| guide / how-to | how do I do X? | What this gets you · Before you start · Steps, numbered, one outcome each · Check it worked · When it goes wrong | as long as the steps |
| runbook / procedure | what do I do right now? | When to use this · Preconditions · Procedure (numbered, imperative, one action per step) · Rollback · Contacts | 1 to 3 pages |
| RCA / post-mortem | what happened and why? | Summary (impact, duration, cause in three sentences) · Timeline (table) · Root cause · What we are changing · What went well | 2 to 4 pages |
| reference (API, config, CLI) | what does X accept? | Overview · One section per item, same shape each · Examples · Errors | as long as the surface |
| status update | where are we? | What changed since last time · Numbers (table) · Blocked on · Next | 1 page |
| spec / requirements | what must it do? | Purpose · Scope and non-goals · Requirements, numbered and testable · Acceptance checks · Glossary | 2 to 10 pages |
| explainer / essay | help me understand X | The one-sentence idea · Why it matters · The mechanism, built up · An example · Where it breaks | 2 to 5 pages |

Mixed content is common: a design note with a decision inside it, a report that
ends in a proposal. Pick the archetype of the reader's FIRST question and host the
other as a section. Do not write two documents.

## 2. How deep is the hierarchy?

- Level-1 headings are the stops a reader navigates to. Three to seven of them.
  Fewer than three means the document is a memo, use no level-1 headings at all
  below the summary. More than seven means two of them are one.
- Level 2 holds parts of a section. Level 3 is rare and only when level 2 has
  three or more children that each need their own heading. Level 4 is a list
  that grew a heading; turn it back into a list.
- A heading with exactly one sub-heading is a level too many. Fold it in.
- A heading with no text under it before its first sub-heading is a label, not a
  section. One sentence saying what the section is for, or drop the level.
- Headings name the content, not the document part: "The queue bound is load
  bearing", not "Details". "Summary", "Appendix" and "References" are the
  exceptions; they are where a reader expects them.
- Past six pages or eight headings, the document gets a contents list
  (`toc: true`). Under that, it does not.

## 3. What shape does each piece of content take?

Decide per piece, never per document. The same fact can be a table in one
section and a sentence in the next.

| the content is | make it a | never a |
|---|---|---|
| three or more items that share two or more attributes | table, one row per item, attributes as columns, six columns at most | paragraph of "X has A and B, Y has C and D" |
| three to seven parallel items with no attributes | bullet list, each one line | table with one column |
| a sequence the reader performs or that happened in order | numbered list, one action or event per number | bullets, prose with "then" |
| reasoning, a trade-off, a judgement | prose, short paragraphs, the conclusion in the first sentence | bullets (they hide the logic) |
| a flow, a topology, a state machine, a pipeline | diagram, box drawing, 78 columns max, a caption that states what it shows | a paragraph walking left to right |
| the exact text a machine reads or produces | code block with a language tag, 40 lines max, one idea per block, a caption when the text refers back to it | a screenshot, prose with inline fragments |
| one sentence the reader must not skim past | callout (NOTE for context, TIP for the better way, WARNING for the cost of getting it wrong, IMPORTANT for the thing that gates everything), one per page at most | bold, ALL CAPS, a second callout |
| numbers that support a claim | the number in the sentence, the full set in a table with a caveat column | "significantly", "most", "a lot" |
| the document's own structure | the contents list the renderer makes | a hand-written list of sections |

Two rules that override the table. A table cell holds a phrase, not a paragraph;
past about twelve words, the content wants a section, not a table. And an
appendix exists for material the argument needs but the reader does not: raw
logs, full listings, the third table. If the body cannot be read without it, it
is not appendix material.

## 4. What opens and closes it?

- Title: a noun phrase naming the subject, under eight words. Subtitle: what
  the document is and for whom ("Decision memo for the Q3 platform review").
- Anything over one page opens with a Summary that gives the answer in three to
  six sentences: the recommendation, the finding, the cause. A reader who stops
  there leaves with the point. No "this document describes".
- A change document carries "What stays the same", because what survives the
  change is the part a reviewer cannot see in the diff.
- The last section is what the reader does next, or what is still open. A
  document that ends on a table trails off.
- Date and author in the frontmatter. A version or status line ("Draft for
  review", "Approved 2026-08-19") as the subtitle's second half when it matters.

## The outline you write before authoring

Ten to fifteen lines in the reply, not a document. Archetype and reader's
question; the level-1 headings with one line each saying what goes in them;
which pieces become tables, diagrams, code, callouts; whether there is a
contents list and an appendix; the length you are aiming for. Stop there on
`--outline`. Otherwise author `DOC.md` against it.

## Voice

Plain, at the reader's altitude: `rules/audience-aware-writing.md`. Facts first,
conclusion after, in anything that reports status or findings. Numbers, not
adjectives. One sentence does one thing; thirty words is the ceiling. No em
dashes, no label-colon fragments as prose, no rule-of-three adjectives. The lint
in `~/.claude/scripts/word-doc/lint.py` names the mechanical subset of this; the
rest is reading it back as the reader.
