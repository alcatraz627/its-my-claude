---
brief: The standard README structure for this account's projects — banner + badges, What is this, Architecture diagram, Quick start, By-what-you-came-to-do table, Documentation with GFM callouts, How work happens here, Repo structure. Promoted 2026-08-25 from versable-builder's README via the kanban rewrite.
triggers: ["skill:readme", "topic:readme", "phrase:\"write a readme\""]
related: [skills/readme]
tier: 2
category: conventions
updated: 2026-08-25
stale_after_days: 180
---

# The standard README shape

Promoted by the owner 2026-08-25: versable-builder's README is the structural
template, the kanban README is the first application. Follow the SHAPE, never
the words: a 1:1 copy is plagiarism of a layout meant to be re-derived from
the project's own facts.

## The sections, in order

1. **Banner + badges** (centered). A small ASCII/box-drawn banner naming the
   project and its one-line identity; shields.io badges for runtime, server,
   store, tests. `/banner` or `/banner-fun` can generate the art.
2. **What is this?** Two paragraphs max, the reader's altitude: what the
   thing does for its owner, then the one structural idea that explains it.
3. **Architecture.** One fenced box-drawing diagram of the real data flow,
   with the load-bearing invariant as a caption line (one writer, one
   registry, whatever it is).
4. **Quick start.** Runnable commands only, each with a trailing comment.
5. **By what you came to do.** A two-column table routing intents to
   surfaces/paths. This replaces long prose orientation.
6. **Documentation.** Link the docs index; name the reading order.
7. **How work happens here.** Rulings, queues, verification bar: how a new
   agent behaves, three sentences.
8. **Repo structure.** A fenced tree with one-phrase annotations.

## GFM callouts, used sparingly and semantically

- `> [!NOTE]` the one conceptual clarification a skimmer must not miss.
- `> [!IMPORTANT]` an invariant that corrupts data if violated.
- `> [!TIP]` the recommended reading/usage order.
- `> [!WARNING]` stale/archived material or a known trap.
Budget: roughly one of each per README. A page of callouts is a page of
noise wearing highlighter.

## The bar

Every claim in a README is checkable (badge numbers match the suites; paths
exist; commands run). A README is the first thing a design or review agent
reads, so it is part of the project's finish level, not decoration.
