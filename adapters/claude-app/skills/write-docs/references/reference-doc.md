# Reference docs: API reference, guide, onboarding

The shared rules for docs that live under `docs/`, then one template per type.

## The reader

Assume the reader does not know the system. They arrive in one of two modes.

**Linear: learning the surface.** They build a mental model from zero.

- The first paragraph says what the thing is and where it sits, before any
  mechanism.
- Sections follow concept dependency. Nothing uses a concept the doc has not
  introduced, or it links forward.
- Behavior first, then mechanism. A payload dump before the flow loses them.
- Worked scenarios go near the end, after the parts are introduced.

Linear order does not mean tutorial voice: no "let's", no "now that we've
seen", no second-person walkthrough.

**Lookup: finding one fact.** They land mid-page from search with one
question and thirty seconds.

- Every section stands alone. Never "as described above". Define or link a
  term on first use within the section.
- Headings match the question. "Quota checks" wins, "Guard rails" loses.
- Limits, enums and mappings live in tables, so the answer is a cell.
- Heading text is an anchor. Renaming one breaks inbound links, so search for
  the old anchor after any rename.

**Both at once.** Order sections for the linear reader, and write each
section's interior for the lookup reader. When a heavy block (a 200-line
payload) stalls the flow, move it to a trailing reference section and leave a
one-line pointer.

## Structure rules

1. The first sentence of every section defines its subject: subject, verb,
   object.
2. Every section is self-contained.
3. Code and data before prose. Show the type or shape, then the behavior.
4. Parallel sections (three states, three modes) use the same subsection
   order.
5. One topic per section. A section about X, Y and Z is three sections.
6. A section with more than four subsections opens with a two-column "what is
   in this section" table.
7. Section order follows the reader's task (configure, submit, diagnose), not
   the code's call order, unless the doc is a call graph.

## Tables or prose

| Content shape | Use |
|---|---|
| Three or more items sharing two or more attributes | Table |
| The reader's question is "which one" | Table |
| A single causal thread | Prose |
| Each item needs more than 15 words of explanation | A subsection per item |
| A bounded enum that needs framing | A short lead-in, then a table |

Never write a table whose cells are paragraphs. Never write a bullet list
where every bullet is "Term: clause". That is a table in disguise.

## Product context for state

Any section that documents a piece of state (a store field, a URL parameter, a
database flag) carries both the technical shape and what a user sees.

```markdown
### `uploadStatus`

**Shape**
`"idle" | "uploading" | "parsed" | "failed"`

**Where it lives**
Store slice `upload` in `src/store/upload.ts`, kept in the URL as `?step=`.

**Values and UI effect**

| Value | What renders | Actions available |
|---|---|---|
| `idle` | Empty drop zone | Choose file |
| `failed` | Red banner with the parser error | Retry, choose another file |

**How the user sets it**
- Dropping a file sets `uploading`.

**Failure modes the user sees**
- If the parse times out: the banner reads "File took too long to read".
```

## Annotations in detail

```markdown
[STUB: re-verify 2026-11-15] Export to CSV shows the button but returns an empty file. Tracking: ENG-412. Re-check: does `exportRows` call the serializer yet?

Rows insert unordered, so one bad row does not abort the batch. [VERIFY: check the `ordered` flag in `api/jobs/insert.py`.]
```

## API reference template

Group endpoints by resource (Invoices, Customers), never by HTTP method.

````markdown
# Billing API reference

Base URL: `https://api.example.com/v1`
Authentication: Bearer token in the `Authorization` header.

## Invoices

### `POST /invoices`

Creates a draft invoice for one customer.

**Request**

| Parameter | Location | Type | Required | Description |
|---|---|---|---|---|
| `customer_id` | body | string | yes | The customer to bill |

```json
{ "customer_id": "cus_8f2k", "lines": [{ "sku": "seat", "qty": 3 }] }
```

**Response** `201`

```json
{ "id": "inv_31a9", "status": "draft", "total_cents": 4500 }
```

**Errors**

| Status | When |
|---|---|
| 401 | Token missing or expired |
| 422 | A line has an unknown SKU. The body lists the bad lines. |
````

Before handing over: every route found has a section, and every section has
a request and a response example.

## Guide template

Put a code example in the first three lines of every step.

````markdown
# Rotate the signing key

Covers rotating the webhook signing key without dropping deliveries. For
operators with admin access.

## Before you start

- Admin role in the dashboard
- The CLI at version 2.4 or later

## Steps

### 1. Create the new key

```bash
billctl keys create --purpose webhook
```

The old key stays valid until step 3.

## Check it worked

## When it goes wrong

| Problem | Cause | Fix |
|---|---|---|
````

Read it back as a new developer. Flag any step that assumes something the
"Before you start" list does not cover.

## Onboarding template

Ask for the tribal knowledge first: the gotcha that bites every new developer,
the accounts and keys needed, the step the README skips.

````markdown
# Getting started with <project>

## What this is
Two sentences: what it does and who uses it.

## First run
```bash
git clone <repo>
cd <project>
npm install
cp .env.example .env   # fill in DATABASE_URL and STRIPE_TEST_KEY
npm run dev
```
Open http://localhost:3000. The login page should load.

## Architecture
A directory tree of the paths that matter, then three to five sentences.

## Key concepts
## Development workflow
## Gotchas
## Where to find things

| Looking for | Look in |
|---|---|
````

Read it back with zero context. Flag every "configure X" that does not say
how.

## Regressions while iterating

- Over-correcting into telegram prose. Keep full sentences and the product
  context.
- Three sequential steps are a short paragraph, not a three-row table.
- Hedging returns when unsure. Use `[VERIFY]` instead.
- After cleaning one of three sibling sections, bring the other two to the
  same depth.
- When prose about a flow changes, re-read the diagram.
- Converting every flagged sentence into a bullet is its own tell.
