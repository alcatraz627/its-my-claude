# RCA and incident report

The shape for an incident report a reader outside engineering can follow.
Section order follows the public Google SRE, Atlassian and PagerDuty
templates.

## The reader

Someone who knows the system's shape, did not watch the incident, and has
little time. They need each finding tied to the system they already know,
without tutorial context and without bare mechanism.

## Every finding is a chain

1. **Symptom** in the terms the reader experiences it.
2. **Impact.** Why it matters, what happens if unfixed, who hits it.
3. **Path.** How the visible symptom connects to the buried cause.
4. **Detail.** The mechanism: the file, the flag, the mismatch. Detail ends a
   finding and is never the whole of it.

"An argument-length mismatch in a helper caused ledger overflow" is detail
alone. It is true and it fails, because the reader cannot connect it to
anything they saw.

## Writing rules

- **Name everything the evidence names.** Customers, ticket numbers, people,
  systems, counts, times. Never swap a fact for a paraphrase, never invent an
  actor ("Operations"), and write "Not recorded" when the record has none.
- **Neutral statements of fact.** "No error monitoring fired" beats "nothing
  alerted on it". No reassurance prose and no corporate headings.
- **Non-technical means no code in the body, not vague.** Files, functions and
  deploy IDs go only in References.
- **Labels identify themselves:** `[PR-305]`, `[RELEASE-v5.6]`,
  `[TICKET-349]`, `[LOG-2026-10-03-api]`. One label per thing, never an
  ordinal like `[C2]`. The sentence must read without the label.
- **Times** in UTC plus the zones of the teams involved.
- **Caveats carry.** What is unverified gets the same weight as what is
  verified. A summary keeps the qualifiers of the claim it shortens.
- **Every number points to a source** the reader can check.

## Sections

````markdown
# Incident report: <what broke, in plain words>, <date range>

## Summary
Three to five sentences: the window in every relevant time zone, who was
affected (named), whether results were delivered, the cause in one sentence
with its label, the fix and how it was verified.

## Impact
Table, one row per affected unit: customer, job, counts, submitted, first
automatic result, manual intervention (yes or no, and when), final outcome.
Under it: why the final numbers look the way they do, and how long the work
normally takes against how long it took.

## Timeline
| UTC | <zone> | Event | Who | Type |
Types: Change, First impact, Masked signal, Missed signal, Response,
Detection, Cause identified, Fix, Fix live, Verified.

## Cause
What changed (label), what depended on it, why the failure produced no error.

## Detection
| Layer | What it checks | What happened here | Why it did not stop it |
One row per layer that could have caught it: code, monitoring, automation,
QA, runbooks, tests. Then the one distinctive signal, and checks that would
catch this class of failure without relying on a person.

## Response
Who was on call, what they did, whether a runbook covered it, why it did or
did not escalate. Only when a manual response happened.

## Resolution
What is fixed and since when, how it was verified, what is still unverified.

## Structural gaps
The conditions that remain after the fix, each with an action item.

## Action items
| Change | Action | How it prevents a repeat |
Change is a three to seven word phrase. Undecided designs go as a final
"Suggestion:" line in the third column, never as a committed action.

## References
| Label | What it is | Link or location |

### Evidence
| Claim | Source |
````

Keep tables under about eight columns. Wider tables break words mid-cell in
Google Docs and on narrow screens.

## Reviews and audits

The same chain applies to review findings and audit reports. Say what was
examined and why before any finding. A review ends with a dispositions table:
each finding marked fixed, deferred (with an owner) or rejected (with the
reason).
