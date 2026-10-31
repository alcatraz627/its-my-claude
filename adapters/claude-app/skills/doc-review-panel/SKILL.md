---
name: doc-review-panel
description: Reviews a technical document through three readers in turn: a veteran engineer, a product manager and an on-call operator, then merges their findings. Use on design docs, READMEs, runbooks.
---

# Doc review panel

One reviewer reads a document with one set of needs and passes everything
that serves them. Three readers who need different things from the same page
catch what each would miss alone:

| Reader | Asks | Tolerates | Reference |
|---|---|---|---|
| Greybeard (engineer) | Does this keep the why, so the next architect can argue with it? | Dense prose, jargon, long form | `references/greybeard.md` |
| Translator (product) | Could I explain this to a smart non-engineer, and what changes for users? | Mechanism hand-waving, if the user-visible effect is crisp | `references/translator.md` |
| Pager-Holder (on-call) | Can I run this at 2am with a customer waiting? | Long theory sections, if the steps are reachable | `references/pager-holder.md` |

The Greybeard reads to argue, the Translator reads to re-narrate, the
Pager-Holder reads to act.

## When to use

- A design doc, ADR, RFC, architecture explainer or README before it ships
- A runbook, onboarding doc or feature explainer that several audiences use
- "Review this doc", "is this doc any good", "what is missing here"

Not for a single docstring, an API reference page, or a doc already queued for
rewrite. For prose style alone, use `plain-writing`.

## Procedure

### 1. Classify the document

Say what kind of document it is: tutorial, how-to, reference or explanation,
or a hybrid. Name its stated or implied audience. This sets the bar for every
reader, since a how-to is judged on steps and an explanation on reasoning.

### 2. Decide which readers run

All three run by default. Drop a reader only when the document gives it
nothing to judge, and say so in one line:

- No architecture or tradeoff at all: the Greybeard gives a short pass
- Explicitly engineering-internal, no user-visible surface: the Translator
  notes the scope and gives a short pass
- No procedure and nothing an operator acts on: the Pager-Holder gives a
  short pass

### 3. Run each reader as its own pass

Read the reader's reference file, then review the whole document as that
reader. Write each pass in full before starting the next, and do not let one
reader adopt another's verdict. Each pass covers:

- **Verdict**: one of ship as is, quick fixes, needs rework, deep rewrite
- **Headline**: the reader's one-sentence test, answered (see each reference)
- **Findings**: each with its location (section heading or a short quote),
  why it fails this reader, and a concrete fix
- **Done criteria**: the reader's checklist, each item met, partial or missing
- **Out of my lane**: what this reader noticed that belongs to another

Cite the document. A finding with no location or quote is cut. Say what
works once, briefly, then move on. No flattery openers.

### 4. Merge

After all three passes:

- **Agreements**: a problem two or three readers raised separately is the
  strongest finding in the review. Put these first.
- **Conflicts**: where readers want opposite things (the Greybeard wants more
  rationale inline, the Pager-Holder wants it moved out of the steps), name
  the conflict and propose the structure that serves both, usually a split or
  a "skip to the steps" anchor.
- **Overall verdict**: the most severe verdict any reader gave on a finding
  that holds up, with the reason.

## Reply shape

1. **Overall verdict and the top three fixes**, first.
2. **Document type and audience**, one line each.
3. **Greybeard pass.**
4. **Translator pass.**
5. **Pager-Holder pass.**
6. **Merged findings**: agreements, conflicts, and the ordered fix list, quick
   fixes separate from structural changes.

## Boundaries

- Suggest the change and its shape. Do not rewrite the document inside the
  review unless the user asks.
- Review this document. Patterns across a docs tree are a separate question.
- None of the readers checks the doc against the code. If a claim looks
  stale, mark it "not checked against the code" and say what would confirm
  it.
