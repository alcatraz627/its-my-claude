---
brief: Genre contract for reports, RCAs, changelogs, review outputs — per finding symptom→impact→path→detail, caveats carry verbatim, semi-informed reader, critic gate before delivery.
triggers:
  - topic:reports
  - topic:rca
  - topic:changelog
  - skill:skeptical-review
  - skill:summarize-changes
  - skill:magi
  - phrase:"write a report"
related: [conventions/doc-writing.md, rules/audience-aware-writing.md, rules/invariant-graduation.md, rules/sub-agent-outputs.md]
tier: 1
category: conventions
updated: 2026-07-16
stale_after_days: 180
---

# Report writing — the genre contract

Reports, RCAs, incident docs, changelogs, audit outputs, and review findings —
wherever they live, including `assets/reports/**` and `.claude/output/**`
(deliberately OUTSIDE `conventions/doc-writing.md` §1's scope; this file covers
that hole). Reference docs keep following doc-writing.md; this contract is for
the artifact whose reader asks "what happened and what should I do about it".

## The reader

A **semi-informed principal**: they know the system's shape, they did not watch
the work, and their time is the scarce resource. Not the unfamiliar-reader modes
of doc-writing.md — this reader needs each finding *connected to the system they
already hold*, not tutorial context and not naked mechanism.

## Per finding: the chain, in order

1. **Symptom in system terms** — what breaks or is wrong, named at the level the
   reader experiences it.
2. **Impact** — why it matters; what happens if unfixed; who/what hits it.
3. **Path** — how the symptom connects to the mechanism (the route from the
   visible thing to the buried thing).
4. **Detail** — the mechanism itself: file:line, the arg-length mismatch, the
   flag. Detail is the END of a finding, never the whole of it.

"Arg length mismatch in a buried function caused ledger overflow" is a 4-only
finding — a true fact with the chain amputated; it fails this contract.

## Report level

- Context before enumeration: what was examined, why, and what the reader
  should do differently for knowing the result — before any finding list.
- **Caveats are content.** A shorter rendering of a claim (summary, abstract,
  recap, commit message) keeps the claim's qualifiers or does not make the
  claim. `UNCONFIRMED`, "not independently reviewed", "true for fresh-register
  only" carry verbatim. Provenance: the claude-ipc away-recaps that compressed
  caveated prose into nine unqualified "hardened/tested/deployed" claims.
- Ground every number and incident to a chaseable source (file, commit, event
  id) — an ungrounded ratio in a report is the same defect as the 4-only
  finding.
- **Review findings end with a Dispositions table**: `finding → fixed |
  deferred (owner) | rejected (reason)`. Undispositioned findings are debt: the
  count rides the Resume Contract's Standing caveats until it reaches zero
  (~50 of 54 findings sat unactioned in the claude-ipc hardening sprint,
  including the one that predicted the fire).

## The gate

Before a `heavy`-tier report (per `style/scope-map.json`) reaches the user or is
filed as a main artifact, dispatch the **readers-advocate** persona
(`personas/readers-advocate.md`, sonnet) against it and apply or consciously
reject its findings. The author cannot see its own noise at any model tier —
this includes reviewers' own reports. The dispatcher logs the pass via
`scripts/style/style-log.sh` (which also writes the voice-passed marker).

## Sub-agent reports inherit this at birth

Dispatch prompts for report-producing sub-agents include one line: "Follow
`~/.claude/conventions/report-writing.md`: per finding symptom → impact → path →
detail; caveats carry verbatim." (See `rules/sub-agent-outputs.md`.)
