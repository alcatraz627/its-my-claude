---
brief: Grep the FULL relevant tree (not just one subdir) before claiming a module/function/helper doesn't exist or proposing to create one
triggers:
  - topic:absence-claims
  - topic:before-creating
  - phrase:"no existing"
  - phrase:"proposing to add"
related:
  - rules/structural-claim-without-reading-code.md
  - rules/speculative-abstractions-without-a-load-bearing-caller.md
tier: 1
category: rules
updated: 2026-09-18
stale_after_days: 180
---
# Grep the FULL tree before claiming a thing does not exist

Before "there is no existing module / helper for X" or proposing to create one, the grep must satisfy one of:
1. scope = the full project root (`rg -n "keyword" backend/`), or
2. an explicit multi-directory list with a stated reason for what is excluded.

A single-directory grep is fine for locating a known thing, never for an existence claim. The thing usually lives where the TRIGGER fires, not where the catalog says it belongs; the 30-second wider grep is always cheaper than a duplicate module or a correction round-trip. Search the concept, not just the symbol: `rg -n "(ensure|create|init|setup)_indexe?s?" backend/`.

Diagnostic: a sentence reading "No existing X — proposing to add…" and you grepped one subdirectory.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/grep-scope-before-claiming-absence.md`
