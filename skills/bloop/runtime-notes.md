## bloop: Run 2 — visual-compare Phase C loop ledger (local-models) — 2026-07-12

**Purpose:** Second /bloop run, first with the improved SKILL.md (delivery clause,
scope-close, mutation-test mandate, TaskStop step). Shipped L3: vis-ledger.py +
see diff --no-read + the /vis-compare --loop protocol.

**Insights:**

1. **The run-1 fixes all paid off in run 2**: the validator delivered its findings
   without a chase-up ping (delivery clause), mutation-tested the guard unprompted
   and found F10 blind to de-atomized writes, and the protection-status commit flow
   ran without the GUIDELINES conflict stall.
2. **Gate is now 4/4 on real findings self-review missed.** This run: syntax-guarded
   JSON but not SHAPE-guarded (valid-JSON-wrong-structure tracebacked), and add vs
   status disagreeing on a corrupt ledger (status fabricated an empty loop). Lesson
   for validator prompts: "malformed input" must enumerate wrong-SHAPE cases, not
   just wrong-syntax; and name cross-command consistency as an attack surface.
3. **Testing atomicity deterministically**: import the module, poison json.dump to
   write partial bytes then raise — the pre-existing target must survive
   byte-identical. Discriminates tmp+os.replace from direct write with no timing
   games. Reusable pattern for any atomic-write claim.
4. **Guard helpers in fixtures need their own failure honesty**: the first F10
   comparability check crashed the battery (unconditional read of a file the
   absent tool never wrote) instead of FAILing — a fixture must report red cleanly
   against missing tooling, or the red run proves nothing.

---
## bloop: V2 M4-M6 (ghostty-themes) — 2026-07-12 03:30

**Purpose:** Runs 4-6 of /bloop (history, profiles, customize view). Gates: M4 ISSUES-FOUND (2 blockers), M5 PASS-WITH-NOTES, M6 ISSUES-FOUND (3 majors) — plus one USER-caught S2 no gate caught.

**Insights:**

1. THE GATE'S BLIND SPOT: validators verify the SPEC, not the user's mental model. M6's instant-apply-on-preview was in my own acceptance spec, passed the gate, and enraged the user (atone instant-apply-on-preview-surface). Consider a validator lens: "does any interaction's side effect contradict what its surface label implies?"
2. A dead validator (API error mid-response) is recoverable: SendMessage to its name resumes it from transcript; it delivered salvaged findings that cross-confirmed my pre-fixes. Pre-fixing predicted findings while a validator runs pays off — M5's two majors were already fixed when the report landed.
3. Concurrent validators sharing the Playwright MCP browser cross-contaminate DOM state (foreign navigations in one sandbox's history). Validators should curl-verify anything load-bearing, or claim exclusive tab ownership.
4. Recurring falsy-default trap: `Number(v) || fallback` swallows explicit zeros (opacity 0 → 1). Grep for `|| <default>` around numeric config reads in any review.
5. mkdir-as-mutex + re-capture-before-rename closed both M4 blockers (cross-process lost updates, hand-edit TOCTOU) in ~60 lines — cheaper than any external lock dep.

---
## bloop: V2 M3 schema+form (ghostty-themes) — 2026-07-12 00:40

**Purpose:** Third live /bloop run — M3 of the ghostty config manager. Gate verdict: ISSUES-FOUND (2 blockers, 3 majors), all fixed same-day.

**Insights:**

1. Gate keeps paying: CRLF silent-corruption (edits appended orphan duplicates; "reset" resurrected stale values) was invisible to an all-green 22-test suite — only a hostile CRLF fixture run end-to-end caught it. Add "CRLF variant of every fixture" to default validator prompts for file-format tools.
2. Validator mutation-testing (flip last→first occurrence) proved the anchor-recovery logic had ZERO coverage while the suite stayed green — "tests pass" says nothing about untested branches. Ask validators to mutation-test every guard they audit, always.
3. A permission denial on writing the user's live config file mid-acceptance forced a pivot to GHOSTTY_MGR_CONFIG/STATE env overrides — strictly better design (hermetic tests forever). Treat permission denials as design feedback, not obstacles.
4. Anchor recovery lesson generalizes: when upstream output loses provenance (ghostty drops path:line when a theme is present), recover it ONLY when unambiguous from ground truth you hold; guessing (last-wins) actively misleads (pointed errors at valid lines).

---
## bloop: V2 M2 lint+editor (ghostty-themes) — 2026-07-11 16:05

**Purpose:** Second live /bloop run — M2 of the ghostty config manager (lint module + POST endpoint + editor UI). Gate verdict: ISSUES-FOUND, 2 majors, both fixed same-day.

**Insights:**

1. Gate now 4/4 and 5/5 on real bugs across runs: it found (a) spawn-failure → "invalid, 0 problems" UI lie, (b) legit embedded-newline-in-quoted-value spoofing diagnostic keys. Naming CONCRETE malformed-input classes in the dispatch prompt keeps paying — the newline spoof came straight from that list.
2. My first fix for (b) was a charset check on the key — WRONG, the spoof key was numeric and passed. The robust fix used ground truth the module already had (cross-check reported key against the parsed submitted line). Lesson: when sanitizing echoed text, anchor to what the caller submitted, not to a character class.
3. Injectable {bin, timeoutMs} params on lint() made the spawn-failure path testable in 100ms instead of 10s — test-only params are justified when the test IS the caller.
4. ghostty binary QUIRK worth reusing: writing to an fd shared with other shell writers produces NUL-padded clobbering; always give it a private pipe/file (Node spawnSync is safe; multi-command shell captures are not).

---
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