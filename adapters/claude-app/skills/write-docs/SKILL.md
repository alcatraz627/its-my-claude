---
name: write-docs
description: Writes technical docs from code the user pastes or connects (API reference, guide, ADR, changelog, onboarding, README, RCA). Picks the template by doc type. Not for PR text.
---

# Write docs

Technical documentation written from the code, for a reader who does not know
the system. The code is the source of truth. A plan, a ticket or an older doc
is evidence, and where it disagrees with the code, the code wins and the
disagreement goes to the user.

Voice comes from `plain-writing`. This skill adds the structure: which shape
each doc type takes, how tables and diagrams carry facts, and how to mark what
is unfinished or unverified.

## 1. Pick the doc type and the reader

| Doc type | The reader is asking | Template |
|---|---|---|
| API reference | What does this endpoint accept and return? | `references/reference-doc.md` |
| Guide or how-to | How do I do X? | `references/reference-doc.md` |
| Onboarding | How do I get this running and find my way? | `references/reference-doc.md` |
| README | What is this repo and how do I start? | `references/readme.md` |
| ADR | Why did we choose X? | `references/adr.md` |
| Changelog or release notes | What changed between these versions? | `references/changelog.md` |
| RCA or incident report | What happened and why? | `references/rca.md` |
| Anything else (design note, memo, runbook, spec, status update) | Varies | `references/word-doc-structure.md` |

Read the template before drafting. When the doc will live on GitHub, also read
`references/github-markdown.md` for what renders and what does not.

Mixed requests are common: a design note with a decision inside it, an
onboarding doc that needs an API table. Pick the type of the reader's first
question and host the other as a section. Do not write two documents.

## 2. Gather the sources

- **Code.** Pasted, uploaded, or read through a GitHub connector. Read the
  actual type definitions, route handlers and config, not only usage. For an
  API reference, list every route first and count them, so the finished doc
  can be checked against the count.
- **Existing docs.** Read two or three from the same repo or team. Their
  heading style, sentence length and density are the target, and they
  outrank any default here. With no existing docs, write plain technical prose
  in full sentences.
- **History.** For a changelog or ADR, the commits or merged PRs in range.
  Commit subjects mislead (a revert that reads as a regression, a vague
  subject hiding a user-facing change), so read the diff for anything unclear.
- **Counts come from the source.** Route counts, file lists and version
  numbers come from the code or a command run in the sandbox, not from memory.

## 3. Ask only what the code cannot answer

Batch the questions in one message, two to four at most. Typical gaps: the
base URL and auth method for an API, the audience, routes to skip, tribal
knowledge for onboarding ("what bites new developers first?"), the decision
and its rejected alternatives for an ADR. Everything else is read from the
code.

Stop and ask rather than guess when:

- The doc contradicts the code and it is unclear which is authoritative.
- A section cannot stand alone without duplicating a large block (propose a
  cross-reference).
- A stubbed feature has no tracking reference. Ask for one, never invent one.
- A backend or external system the doc depends on has not been read.
- A section reads flat however it is phrased. The content may be wrong.

## 4. Outline, then draft

For anything longer than a page, show a ten to fifteen line outline first:
doc type and reader's question, the top-level headings with one line each,
which pieces become tables, diagrams or code blocks, and the target length.
The wrong outline, rewritten nicely, is the expensive failure.

Then draft against the template. Rules that hold for every type:

- **The reader is unfamiliar with the system.** Order sections for someone
  reading top to bottom. Write each section so someone landing on it from a
  search can use it alone. Details in `references/reference-doc.md`.
- **First sentence of a section defines its subject.** No setup, no
  transition.
- **Code and data before prose.** Show the type, the command or the table,
  then explain.
- **Tables for three or more items that share fields.** One causal thread
  stays prose.
- **Diagrams carry facts.** Labeled edges, role-tagged nodes, a one-line
  legend above. How to draw them lives in `diagrams`.
- **Headings name what the reader searches for** ("Quota checks", not "What
  happens next").

## 5. Mark what is unfinished or unverified

Inline tags, grep-friendly, from a fixed set:

| Tag | Means |
|---|---|
| `[STUB]` | The section or feature exists but is empty or returns a placeholder |
| `[PARTIAL]` | Some cases work, others do not |
| `[PLANNED]` | Describes future work, not current behavior |
| `[DEPRECATED]` | Still present, slated for removal |
| `[VERIFY: <check>]` | A claim not confirmed from the code. Names the concrete check that would confirm it |

A `[VERIFY]` with no named check ("TODO: check") is not allowed. When unsure,
tag it. Do not hedge in prose instead.

## 6. Self-check before handing over

- [ ] Every section opens with a definition sentence.
- [ ] No heading contains "and beyond", "and more", "deep dive" or a
      rhetorical phrase.
- [ ] Every set of three or more parallel values is a table.
- [ ] Every flow diagram has labeled edges and role-tagged nodes.
- [ ] Every section that documents state has a product-context block (see
      `references/reference-doc.md`).
- [ ] Every uncertain claim carries `[VERIFY]` with a check.
- [ ] Every `[text](#anchor)` link resolves to a real heading.
- [ ] No section depends on "as described above".
- [ ] For an API reference, every route found in step 2 has a section with a
      request and a response example.
- [ ] The draft passes the checks in `plain-writing`.

## 7. Deliver

- Hand the doc over as a markdown file the user can download, or in one
  fenced block when it is short. For a long doc the user will read in the
  browser, an artifact is also fine.
- Look at the rendered result before calling it done: tables render, the H1
  is intact, code fences close, and no anchor is broken. In chat, render it
  as an artifact or read the markdown back with that list in hand.
- End with a short note: what the doc covers, what it leaves out, and every
  open `[VERIFY]` or `[STUB]` tag.
- Never create files in the user's repo, open a PR, or edit a Drive doc
  through a connector unless the user asks for that in so many words.

## 8. Revising

1. Read the whole doc once without editing.
2. Search for the find-and-flag words in `plain-writing`'s
   `references/ai-tells.md` and note each hit.
3. Re-apply the structure rules section by section, then promote any list of
   three or more parallel items to a table.
4. Redraw any diagram whose prose changed.
5. Finish with a pass over section intros only. Voice regresses there first.

A voice cleanup goes best with a fresh reader who did not write the draft (a
new chat, or another person). For a content review by engineer, product and
on-call readers, use `doc-review-panel`.
