---
brief: Standard RCA (incident report) template for readers outside engineering; named facts, plain headings, labelled references at the end.
triggers:
  - topic:rca
  - topic:postmortem
  - topic:incident-report
  - phrase:"write an RCA"
  - phrase:"incident report"
  - skill:gdoc
related: [conventions/report-writing.md, rules/audience-aware-writing.md]
tier: 2
category: conventions
updated: 2026-10-05
stale_after_days: 180
---

# RCA template

The standard shape for an incident report, owner-approved 2026-10-05 (worked example: Versable `frontend/docs/team/postmortems/2026-10-05-extractor-blank-jobs.md`). It extends `conventions/report-writing.md`, which still governs voice and grounding. Section order follows the public Google SRE, Atlassian and PagerDuty templates.

## Writing rules

- **Name everything the evidence names.** Customers, job or ticket numbers, people, systems (Sentry, QC, the service's real name), counts and times. Never swap a concrete fact for a paraphrase, never invent an actor ("Operations", "engineering"), and write "Not recorded" when the record has no actor.
- **Plain, neutral statements of fact.** "No error monitoring (Sentry or error logs) fired" beats "nothing alerted on it". No euphemism, no reassurance prose, no corporate headings ("What we are changing so it does not happen again").
- **Non-technical means no code in the body, not vague.** Technical detail (files, functions, deploy ids) lives only in References.
- **Labels are self-identifying and code-formatted:** `` `[PR-305]` ``, `` `[RELEASE-v5.6]` ``, `` `[JOB-349]` ``, `` `[SLACK-2026-10-03]` ``, `` `[CODE-get_items]` ``, `` `[CI-scraper-e2e]` ``, `` `[LOG-...]` ``, `` `[DOC-...]` ``. One label, one thing; never an ordinal like `[C2]`. The sentence must read without the label.
- **Times** in UTC plus the teams' zones (Versable: IST and PT, noting PDT vs PST by date).
- **Caveats carry.** What is unverified is stated with the same weight as what is verified.
- A fresh reader-review seat may tighten wording, but cannot override these rules.

## Sections

````markdown
---
emoji: 🔍
audience: <who reads this>
status: <resolved | monitoring | open>
last_updated: YYYY-MM-DD
---

# Incident report: <what broke, in plain words>, <date range>

## Summary
3 to 5 sentences: the window (all time zones), who was affected (named), whether results
were delivered, the cause in one sentence with its label, the fix and how it was verified.

## Impact
Table, one row per affected unit (customer, job, site, counts, submitted, first automatic
result, manual intervention Yes/No + time, status, final outcome). Under it: why the final
numbers look the way they do (e.g. only because of manual re-runs), how long the work
normally takes vs how long it took, and what any metric in the table means.

## Timeline
Table: UTC | <zone> | <zone> | Event | Who | Type. Types: Change, First impact, Masked
signal, Missed signal, Response, Detection, Cause identified, Fix, Fix live, Verified.

## Cause
What changed (label), what depended on it, why the failure produced no error.

## Detection
Table: Layer | What it checks | What happened here | Why it did not stop it. One row per
layer that could have caught it (code, monitoring, automation, QC, runbooks, tests). Then
the one signal that was distinctive, and a subsection "Catching this class of failure
without relying on a person": checks that catch the class, not only this cause.

## <Manual workaround / response section, when one existed>
Who was on call, what they did, whether a runbook covered it, what signals they had, and
why it did or did not escalate.

## Resolution
What is fixed and since when; how it was verified (named test, counts); what is still
unverified.

## Structural gaps
Bulleted: the conditions that remain after the fix. Each one has an action item.

## Action items
| Change | Action | How it prevents a repeat |
- Change: a 3 to 7 word phrase for the behaviour change; prefix ✅ when done.
- Undecided designs go as a final "<br>Suggestion: ..." line in the How cell, never as a
  committed action.

## References
| Label | What it is | Link or location |

### Evidence
| Claim | Source |
````

## Publishing

Versable RCAs go to the repo's `frontend/docs/team/postmortems/` (dated filename, a line in `_index.md`) and to the shared "RCA docs" Drive folder via `/gdoc`, one `.gdoc.json` per RCA. Keep wide tables under about 8 columns, or the Google Docs render breaks words mid-cell.
