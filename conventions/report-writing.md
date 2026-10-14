---
brief: Genre contract for reports, RCAs, changelogs and review outputs: per finding symptom→impact→path→detail, caveats carry verbatim, semi-informed reader, critic gate before delivery.
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

# Report writing: the genre contract

This contract covers reports, RCAs, incident docs, changelogs, audit outputs and review findings,
wherever they live, including `assets/reports/**` and `.claude/output/**`
(deliberately OUTSIDE `conventions/doc-writing.md` §1's scope, so this file covers
that hole). Reference docs keep following doc-writing.md. This contract is for
the artifact whose reader asks "what happened and what should I do about it".

## The reader

A **semi-informed principal**: they know the system's shape, they did not watch
the work, and their time is the scarce resource. This reader differs from the unfamiliar-reader modes
of doc-writing.md. They need each finding *connected to the system they
already hold*, without tutorial context and without naked mechanism.

An RCA or incident report for readers outside engineering uses the section template in `conventions/rca-template.md`, and this contract still governs its voice.

## Per finding: the chain, in order

1. **Symptom in system terms.** What breaks or is wrong, named at the level the
   reader experiences it.
2. **Impact.** Why it matters, what happens if unfixed, and who or what hits it.
3. **Path.** How the symptom connects to the mechanism (the route from the
   visible thing to the buried thing).
4. **Detail.** The mechanism itself: file:line, the arg-length mismatch, the
   flag. Detail is the END of a finding and never the whole of it.

"Arg length mismatch in a buried function caused ledger overflow" is a 4-only
finding. It is a true fact with the chain amputated, and it fails this contract.

## Report level

- Context comes before enumeration: say what was examined, why, and what the reader
  should do differently for knowing the result, before any finding list.
- **Caveats are content.** A shorter rendering of a claim (summary, abstract,
  recap, commit message) keeps the claim's qualifiers or does not make the
  claim. `UNCONFIRMED`, "not independently reviewed" and "true for fresh-register
  only" carry verbatim. Provenance: the claude-ipc away-recaps that compressed
  caveated prose into nine unqualified "hardened/tested/deployed" claims.
- Ground every number and incident to a chaseable source (file, commit, event
  id). An ungrounded ratio in a report is the same defect as the 4-only
  finding.
- **Review findings end with a Dispositions table**: `finding → fixed |
  deferred (owner) | rejected (reason)`. Undispositioned findings are debt, and the
  count rides the Resume Contract's Standing caveats until it reaches zero
  (about 50 of 54 findings sat unactioned in the claude-ipc hardening sprint,
  including the one that predicted the fire).

## The gate

Before a `heavy`-tier report (per `style/scope-map.json`) reaches the user or is
filed as a main artifact, dispatch the **readers-advocate** persona
(`personas/readers-advocate.md`, sonnet) against it and apply or consciously
reject its findings. The author cannot see its own noise at any model tier,
and this includes reviewers' own reports. The dispatcher logs the pass via
`scripts/style/style-log.sh` (which also writes the voice-passed marker).

## Sub-agent reports inherit this at birth

Dispatch prompts for report-producing sub-agents include one line: "Follow
`~/.claude/conventions/report-writing.md`: per finding symptom → impact → path →
detail; caveats carry verbatim." (See `rules/sub-agent-outputs.md`.)
