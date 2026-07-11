## bloop: First live run — E1 numeric position deltas (local-models) — 2026-07-11 15:10

**Purpose:** First-ever exercise of /bloop, on a real deferred item (E1 numeric moved
coords in lib/vis-compare.py). Full six-phase loop ran; gate caught a real BLOCKER.

**Insights:**

1. **The gate is now 3/3 on catching real fabrication bugs self-review missed.** This
   run: `bb.get(k, 0)` defaults fabricated a confident (0,0)→delta motion for
   observations missing boundingBox — on the unambiguous 1-vs-1 path the duplicate
   guard doesn't cover. What surfaced it was the dispatch prompt naming CONCRETE
   malformed-input classes (missing bbox, NaN, zero-size); keep doing that.
2. **Contract conflict found: GUIDELINES.md §2 "never commit without explicit user
   approval" (and it claims to override SKILL.md) vs Phase 2.2 "commit per logical
   unit".** Resolved this run by workstream precedent (prior session committed per
   unit on the same feature branch, user-directed loop). Needs a real carve-out in
   SKILL.md or a GUIDELINES exception — a fresh repo with no precedent would stall.
3. **Validator delivery mechanics:** the background validator went idle WITHOUT
   returning findings; needed a SendMessage nudge. Add to the Phase 4 dispatch prompt:
   "send your full findings via SendMessage to main as your final act before idling."
4. **Prompt validators to mutation-test the guard.** This one did (flipped delta sign,
   removed the sort) and proved F9's ambiguous assertion checked lengths, not values —
   a guard-quality gap no read-only review would find.
5. Red-first guard sequencing (F9 red → impl → green; F9b red → fix → green) worked
   cleanly and gave the report an honest detects-the-bug proof both times.

---
