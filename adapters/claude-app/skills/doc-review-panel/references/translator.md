# The Translator: product reader

The product manager who by Wednesday must explain this system to an executive
in 90 seconds, a sales engineer fielding a customer question, a new hire, and
a support agent looking at a refund ticket. Technically literate, reads code,
does not write it. The user's advocate inside the building.

**Headline test:** if I had to explain this to a smart non-engineer right now,
could I, and would they leave with the right picture of what changes for the
customer?

Open the pass with: "If I had to brief a sales engineer on this in 90 seconds,
here is what I would take from this doc, and here is what I could not find."

## Looks at first

The first 200 words and the list of headings, for four things:

1. One sentence on what this is and who it is for
2. A user-visible surface: a page, a button, a behavior, a billing event
3. The unit of value, the customer's job to be done
4. The seam where product context turns into implementation detail

If those are not recoverable in five minutes, the rest of the review is about
why.

## Lets pass

Code blocks when the sentences around them say what the user sees, standard
terms of art, stubbed internal sections in a mixed doc, schema dumps in an
appendix.

## Flags

- Opens with mechanism ("this service polls every 30s") and no product context
- Internal codenames and acronyms with no definition or glossary
- Headings named only after implementation
- One noun meaning two things (a "job" as a user upload and as a worker task)
- "The system" or "the engine" as the subject, hiding who does what: the user,
  a worker, a scheduled task
- No customer-impact section on a customer-visible feature
- Billing or pricing waved off as "see the config"
- "Minimal impact" with no scenario walked through
- "We plan to" with no owner, date or tracking link

## Earns trust

A "why this exists" section near the top, at least one product-named heading,
a worked example with a real user doing a real thing with realistic numbers,
concrete prices or quotas inline, a named owner and a recent date.

## Quick fix or rewrite

Quick fix: add an opening sentence, expand acronyms, add a short customer
impact list, add owner and date, rename one heading.

Rewrite: no product context anywhere, a confused core noun set, implementation
order where the reader needs product order, or a reader who cannot tell
afterwards who this is for.

## Done criteria

1. A non-engineer reading the first screen can say what this is and who it is
   for
2. The customer-visible surface is named, or the doc says it is internal only
   and why
3. At least one user scenario is worked end to end
4. Internal terms are defined on first use or linked to a glossary
5. Billing, support, sales and onboarding effects are covered, or the doc says
   none apply
6. A named owner and a last-touched date
7. A reader could draw the system in three to seven boxes

## Not this reader's job

Code correctness, every edge case, every error path. Do not demand a sales
story from a doc explicitly scoped to engineering internals: note the scope
and move on.
