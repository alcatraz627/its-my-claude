# Planning a document from its content

For any doc type without its own template. The plan comes from the content,
not from a template. Answer the four questions in order, write the answers
into the outline, then draft.

## 1. What kind of document is this?

Name the reader's question first. The archetype follows from it.

| Archetype | The reader asks | Sections, in order | Length |
|---|---|---|---|
| Decision memo or proposal | Should we do X? | Summary (the recommendation), problem, options with a comparison table, recommendation and why, risks and what stays the same, next steps | 1 to 3 pages |
| Design note | How will X work? | Summary, context and constraints, design (diagram first, then parts), alternatives considered, rollout, open questions | 3 to 8 pages |
| Report or analysis | What did we find? | Summary (numbered findings), method and data, one section per finding with evidence in tables, limits of the data, recommendations | 2 to 6 pages |
| Guide or how-to | How do I do X? | What this gets you, before you start, numbered steps with one outcome each, check it worked, when it goes wrong | As long as the steps |
| Runbook | What do I do right now? | When to use this, preconditions, numbered imperative steps, rollback, contacts | 1 to 3 pages |
| RCA | What happened and why? | Use `rca.md` | 2 to 4 pages |
| Reference | What does X accept? | Use `reference-doc.md` | As long as the surface |
| Status update | Where are we? | What changed since last time, numbers in a table, blocked on, next | 1 page |
| Spec or requirements | What must it do? | Purpose, scope and non-goals, numbered testable requirements, acceptance checks, glossary | 2 to 10 pages |
| Explainer | Help me understand X | The one-sentence idea, why it matters, the mechanism built up, an example, where it breaks | 2 to 5 pages |

Mixed content is common. Pick the archetype of the reader's first question
and host the other as a section.

## 2. How deep is the hierarchy?

- Top-level headings are the stops a reader navigates to. Three to seven of
  them. Fewer than three means a memo with no top-level headings below the
  summary. More than seven means two of them are one.
- A second level holds parts of a section. A third level is rare: only when
  the second level has three or more children that each need a heading. A
  fourth level is a list that grew a heading. Turn it back into a list.
- A heading with exactly one sub-heading is a level too many. Fold it in.
- A heading with no text before its first sub-heading is a label. Add one
  sentence saying what the section is for, or drop the level.
- Headings name the content ("The queue bound limits throughput"), not the
  document part ("Details"). Summary, Appendix and References are the
  exceptions.
- Past six pages or eight headings, add a contents list.

## 3. What shape does each piece take?

Decide per piece, never per document.

| The content is | Make it a | Never a |
|---|---|---|
| Three or more items sharing two or more attributes | Table, six columns at most | Paragraph of "X has A, Y has B" |
| Three to seven parallel items with no attributes | Bullet list, one line each | One-column table |
| A sequence performed or that happened in order | Numbered list, one action or event per number | Prose with "then" |
| Reasoning, a trade-off, a judgment | Short paragraphs, conclusion first | Bullets, which hide the logic |
| A flow, topology, state machine or pipeline | Diagram (see `diagrams`) with a caption | A paragraph walking left to right |
| Exact text a machine reads or writes | Code block with a language tag, 40 lines at most | A screenshot |
| One sentence the reader must not skip | One callout, at most one per page | Bold, capitals, a second callout |
| Numbers that support a claim | The number in the sentence, the full set in a table | "Significantly", "most" |

A table cell holds a phrase. Past about twelve words, the content wants a
section. An appendix holds what the argument needs but the reader does not:
raw logs, full listings. If the body cannot be read without it, it is not
appendix material.

## 4. What opens and closes it?

- **Title:** a noun phrase under eight words. Subtitle: what the doc is and
  for whom ("Decision memo for the Q3 platform review").
- **Summary:** anything over a page opens with the answer in three to six
  sentences. A reader who stops there leaves with the point.
- **What stays the same:** a change document carries it, because what
  survives the change is what a reviewer cannot see in the diff.
- **The ending** is what the reader does next, or what is still open. A doc
  that ends on a table trails off.
- **Date, author and status** ("Draft for review") near the top.

## The outline

Ten to fifteen lines in the reply, not a document: the archetype and the
reader's question, the top-level headings with one line each, which pieces
become tables, diagrams, code or callouts, whether there is a contents list
or appendix, and the target length.
