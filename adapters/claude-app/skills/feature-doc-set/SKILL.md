---
name: feature-doc-set
description: For a feature PR being raised or reviewed. Writes the owner brief, engineering guide, team brief, PR text and a review contract from the code. Not for a lone PR body (use pr-description).
---

# Feature doc set

The documents a feature PR owes each of its readers, written from the code on
the branch rather than from the plan that came before it. Alongside them, a
review contract lists the behaviors only a running build can prove.

Unit tests and a green build show the code does what the code says. The
contract says what the feature must do for a person, row by row, and which
rows someone has driven on a running build.

## 1. Inputs

1. **The feature's reach.** Get the diff (pasted, uploaded, or through a
   GitHub connector by PR number or branch), base to head from the merge base.
   List every file it touches, then the callers and callees of the changed
   functions. The doc set describes the feature's reach, not only its diff.
2. **The behavior authority.** In order: a committed behavior spec for this
   feature, the user's recorded decisions for the work, the proposal that
   started it. Where a working doc disagrees with the code, the code wins and
   the disagreement goes in the README's superseded table.
3. **The checks that exist.** Test files, smoke scripts and end-to-end suites
   that mention the changed symbols. These decide which contract rows are
   suite-backed and which are open.
4. **One batched question, only when needed.** Ask the user only when a ruling
   the docs need is absent: a billing rule with two live readings, a control
   that is staff-only in one file and customer-facing in another. Everything
   else is read from the code.

## 2. The read pass

Build the behavior inventory before writing a sentence. Each entry is a thing
a person can do or a thing that happens to them, with the file and line that
decides it. Sweep these in order, because the later ones are what a diff
review misses:

- What a user can now do, and what stops going wrong.
- Every state the feature introduces and every transition, including the
  transient ones a screen shows for a few seconds.
- Every number the product counts or guarantees that the feature changes
  (counters, receipts, prices, quotas, limits), with its idempotence rule:
  counted once per what, keyed by what.
- Cross-surface effects: a count on one page fed by a filter on another, a
  badge, a sidebar, an admin view, an export, an email.
- Controls: which appear, which hide, for whom (customer, staff), in which
  state, and what each confirms before it fires.
- Refusals: what the feature says no to, with the exact copy.
- Edges: what was already true when the feature ran (values already present,
  a billing cycle boundary), reruns, retries, a worker that dies mid-way.
- What the feature deliberately does not do, and where the plan said
  otherwise.

Then list the surfaces it touches (pages, tables, modals, banners, emails) and
the conditions each must be read in: light and dark theme, phone width,
customer and staff.

## 3. The review contract, first

Write `review-contract.md` before the prose docs. The docs cite it.

| Column | Holds |
|---|---|
| Do | An action a person or a script can take against a running build |
| Expect | What is visible and what the data must say, never only a status badge |
| Verified | Exactly one of: `preview` with the date and build it was driven on, `suite` with the test that asserts it, or `UNCONFIRMED` |

- A row is never marked from memory. A row marked `preview` on an older build
  than the one under review is reopened, in writing.
- Every read-pass category with anything in it produces at least one row:
  transient states, idempotence, counted numbers, cross-surface effects,
  hidden controls, refusals, edits on a stopped thing, both themes and phone
  width for touched surfaces, staff-only paths. An empty category is left
  out, not padded.
- A "Rows that need attention" section follows the table: open rows, rows
  with stale evidence, and anything no suite and no hand pass covers.
- A closing paragraph states what a failure means (the contract is the
  product behavior, and a build that contradicts a row fails) and names any
  ruling still open.

When the user asks for the contract alone (a re-verification pass), rebuild
the rows from the code and carry each existing Verified value forward only
when its build is the current one.

## 4. The four documents

Each has its own reader and register. The section shapes stay fixed, so a
reader of one feature's set can read the next without relearning it.

| Document | Reader | Register | Sections |
|---|---|---|---|
| `owner-brief.md` | The product owner | Plain words, no code references, what a customer sees and pays | The controls a customer has, what each does, what is charged and what never is, allowances and prices, edge cases worth knowing, what was decided since the first draft |
| `engineering-guide.md` | A developer changing this later | Dense, file and line, contracts and invariants | One section per mechanism (state machine, settle rule, idempotence, counting rules), where each piece lives, running the checks, deploying a preview, what to know before changing this |
| `team-brief.md` | The wider team | Two minutes to read | What shipped, what changed from the proposal and why, what is open, where the detail lives |
| `pr-description.md` | The PR reviewer | The author briefing the reviewer | What a user can now do, decisions a reviewer must ratify, the verification boundary with a verdict line, how to read the diff, follow-ups not in this PR |

The PR description follows `pr-description`: the behavioral inventory is the
source, never commit subjects, and the body is handed over for the user to
paste.

A `README.md` indexes the folder: what each doc is for, what it replaces,
where the code disagreed with the working docs, and a release readiness
verdict with its evidence. The verdict comes last, after the facts that
support it.

## 5. The prose pass

Before delivery, on every file:

1. Strip local machine paths, session IDs and screenshot locations. A doc
   names repo-relative paths and file and line pointers only.
2. Apply `plain-writing`, including its AI-tells check. Zero em-dashes.
3. Offer a voice pass by a fresh reader who did not write the docs (a new
   chat, or another person). For a content review by engineer, product and
   on-call readers, `doc-review-panel` fits.
4. Re-read the Verified column one last time. A claim without a named test or
   a dated build becomes `UNCONFIRMED`.

## 6. Deliver

- The six files as downloads, or as one zip from the sandbox, named as above.
- A short message: the count of contract rows by Verified value, the open rows
  by name, and one line offering to walk the open rows if the user can share
  a preview build or screenshots.
- Never commit, push, deploy or edit the PR through a connector unless the
  user asks for that in so many words.

## Boundaries

- Never mark a contract row verified without naming the test or the build it
  ran on.
- Never write a doc from the plan when the code disagrees. The code wins and
  the disagreement is recorded.
- Never carry the user's words into a doc as if they were the spec. A ruling
  is cited as a ruling, with its date.
- Calibrate on an earlier set if the user has one. Do not copy its sections
  where this feature has nothing for them.
