## bloop: item 15 tail — first-prompt dream lane (gcc) — 2026-07-14

**Purpose:** Twelfth run. Gate: ISSUES-FOUND (2 real bugs + a TOCTOU race) on a
sync UserPromptSubmit hook. Streak 12/12.

**Insights:**

1. **API-crashed validator → SendMessage resume worked.** The seat died on a
   server error mid-response; a resume message (it keeps its transcript) plus
   one delivery chase-up recovered a complete report — cheaper than
   re-dispatch. Order: resume-ping on `failed`, chase-up on `available`,
   fresh seat only third.
2. **Validator housekeeping swept the PARENT's scratch fixtures** (my hermetic
   HOME died with its cleanup, silently breaking my re-exercise runs with
   false failures). Namespace parent fixtures outside anything the dispatch
   invites the validator to use, or rebuild before reuse.
3. **Hermetic HOME-override testing is itself an attack probe**: it exposed the
   wrapper resolving its engine path via $HOME (same split-resolution class as
   the item-12 blocker) before the validator ever ran. Script-dir resolution
   (BASH_SOURCE) is the pattern.
4. **"Did I already deliver this" checks must be keyed by the receiving
   session.** The gate's best find: a global-last dedupe silently starves
   concurrent sessions — sid-scope the ledger scan, and make the upstream
   writer stamp sid so there is something to scope by.

---
## bloop: F6 products redesign + poll sweep (versable) — 2026-07-13

**Purpose:** Twelfth run. Gate: ISSUES-FOUND — a pre-existing bug (server
"prefix" search was exact-match) that the new UI made load-bearing. Streak 12/12.

**Insights:**

1. **Gates catch bugs the DIFF didn't introduce.** The major was in untouched
   code (`endAt(X + "")` — an EMPTY string where \uf8ff belonged); F6's
   escalation link turned it into a broken promise. Attack prompts should name
   the promises the UI makes, not just the lines the diff changed. Corollary:
   during the build I "preserved exactly" what I assumed was an invisible
   \uf8ff — preserving code faithfully preserves its bugs; verify suspicious
   literals with a hexdump instead of assuming.
2. **Store-driven kit modals match on elementId AND modalKey** — a keyless
   `<Modal>` instance never renders when opened with a key. Every code path
   "looked right" (handler fired, store updated); only a DOM probe (zero
   `<dialog>` elements) exposed it. For invisible-until-open components,
   probe the DOM, not the logic.
3. **Red-proof before claiming resilience:** reverting to the pre-fix poll and
   watching offline nuke the page to the ErrorBoundary (then green with the
   hook) is cheap (~2 min) and turns "should survive" into "watched it fail
   and survive." Also: the triage's proposed fetcher.load fix was WRONG
   (fetcher errors also reach boundaries) — verify a teammate's mechanism
   claim before building on it; probe-gated revalidation was the honest fix.
4. **Shared-branch merges land mid-loop.** The coworker's usage work hit the
   branch between my commit and push; the merge wanted a file where the
   OWNER'S uncommitted fix lived. Pattern: stash theirs with a named message,
   merge, re-apply their intent as an attributed commit, leave the stash as
   the receipt.
5. Python-heredoc regex swaps across N route files work well for identical
   effect blocks, but import-list surgery needs all three positions (own-line,
   leading/middle, trailing) and a per-file "did I orphan a hook use" count
   check — my revert broke useEffect for two legit consumers by over-removing.

---
## bloop: F3.1 speedway dashboard (versable) — 2026-07-13

**Purpose:** Eleventh run. Gate: ISSUES-FOUND — 1 major + 3 smaller, all
found after a browser self-review that felt complete. Streak now 11/11.

**Insights:**

1. **Quote the owner's verbatim requirement in the attack claim.** The major
   (label ellipsized at grid-floor margins) surfaced because the dispatch said
   "owner demanded FIT, not truncate" — the validator then width-swept
   scrollWidth vs clientWidth over stepped container widths and found five
   truncating windows my fixed-viewport review never landed on. That sweep is
   a cheap reusable truncation detector.
2. **React Router single-fetch: delaying the whole .data request can NEVER
   show a Suspense skeleton** — the router stays on the previous page until
   the loader returns; the skeleton's only window is the deferred stream.
   Exercise it with a TEMP server-side delay + goto waitUntil:'commit'.
   Bonus: the deferred stream hard-times-out ~5s → error boundary, so keep
   test delays under that.
3. **Idle-without-delivery: 3rd occurrence, same cure.** Treat the idle
   notification as the ping trigger; the chase-up produced a complete
   high-quality report within one message.
4. **Shared-browser handback protocol works:** IPC-ask the holding session to
   browser_close (wake-on-message), then take over; killing its chrome is
   classifier-blocked as cross-agent interference. Budget ~5 min for the
   handback; verify with a cheap resize call.
5. Validators given "no residue" constraints innovate honestly: markup-proxy
   probes (inject the literal source class string, measure, remove) verified
   a surface no fixture data could render, correctly labeled as proxy.

---
## bloop: item 12 — janitor accountability re-gate (i-dream) — 2026-07-13

**Purpose:** Eleventh run; re-gate after the first validator hung 20 min and was
killed. Gate: ISSUES-FOUND — 1 BLOCKER, 4 HIGH, 2 MAJOR; streak now 11/11.

**Insights:**

1. **Second consecutive idle-without-delivery** despite the verbatim delivery
   clause; one chase-up ping again recovered a complete, high-quality report.
   Two-for-two says: stop treating the clause as sufficient — ping on the idle
   notification as standard procedure (or build the auto-nudge; proposal-worthy
   if it happens a third time).
2. **The fix pass found a defect the gate missed** (restore-dir tokens for
   file-target retention rules named `<file>/_archived/<date>`, which never
   exists — live since the insight-feedback rule shipped). Reading code to FIX
   a finding is itself a discovery pass; budget a real read per finding, not
   just the patch.
3. **Re-run the gate's own failed mutation after adding the fixture.** The
   validator proved idempotence-guard deletion stayed green; after
   tests/revert_autonomous.rs the same mutation goes red. "Fixture added" is
   unverified until the original mutation has been watched failing.
4. **lm pre-gate cumulative: 9 valid-location opinions, 0 real** across two
   diffs. Its value is cheap negative confirmation plus naming the surfaces to
   read closely — the three clusters it flagged were exactly where the paid
   gate's real findings clustered (same files, different defects).

---
## bloop: F5 speedway files restructure (versable) — 2026-07-13

**Purpose:** Tenth run. Gate: PASS-WITH-NOTES — 2 minors found after a full
browser self-review that felt complete.

**Insights:**

1. **Gate streak now 10/10.** Both minors were "default else branch" blind
   spots: a param-sync effect whose else-chain never handled the
   unresolvable-id case, and an empty state whose copy assumed one cause for
   rows.length===0. Prompting validators with concrete malformed inputs
   (garbage id, cross-workspace id, headers-only CSV) is what surfaced both.
2. **Validators that exercise data-mutating UIs leave durable residue** — this
   one uploaded 4 attack files into a live test workspace (no delete
   affordance exists). Add to such dispatch prompts: "list every artifact you
   created that you could not remove" — got that for free this time via its
   housekeeping note; make it mandatory next time.
3. **Idle-without-delivery happened again despite the verbatim delivery
   clause.** One SendMessage chase-up ("deliver now, mark unexercised claims
   UNCONFIRMED") resumed it and the report was complete and high-quality.
   Treat the idle notification as a prompt to ping, not a failure.
4. **The optional lm pre-gate silently no-ops on macOS** — `timeout` doesn't
   exist, so the pipe fed empty stdin to findings-gate. Guard with
   `command -v timeout` or drop the cap; the paid gate is unaffected.

---
## bloop: item 13 — rejection memory (i-dream) — 2026-07-13

**Purpose:** Ninth run. Gate: ISSUES-FOUND — the strongest gate result yet: it
invalidated the parent's own acceptance test, not just the code.

**Insights:**

1. **Acceptance replays against historical data are tautology-prone**: my
   date-only cutoff admitted rejection records written by the replayed batch's
   own review (23:24 the night before), so every proposal "matched itself" at
   1.0 and I claimed acceptance met. Cut replay memory at the exact write
   INSTANT of the event under test, and have the validator check the cutoff.
2. **When true and false positives score 0.332 vs 0.330, stop tuning the
   threshold — the feature is missing a signal.** The discriminator was
   structural (shared unsplit kebab compound), not statistical. Corollary:
   hyphen-splitting tokenizers MANUFACTURE false overlap between different
   slugs ("literal-request-over-intent" vs "over-corrected-tuning-request-…"
   share 3 fragment words).
3. **A mutation that stays green means the fixture is too rich** — my reworded
   fixture also cleared the sim path, so killing the slug clause changed
   nothing. The discriminating guard needs a case ONLY the clause under test
   can catch (shared slug + low overlap).
4. Validators told "the work is uncommitted, rsync a copy, main checkout
   read-only" complied perfectly and even declined to run the binary because
   dry-run writes a real audit log — instruction-level safety scoping works.

---
## bloop: item 14 — graduation-yield SLO (i-dream) — 2026-07-13

**Purpose:** Eighth run, same session as item 16. Gate: PASS-WITH-NOTES, 1 HIGH.

**Insights:**

1. **Tolerant-vs-strict JSONL readers are a standing attack surface**: any
   evaluate/verdict path that reads a ledger via a strict reader +
   unwrap_or_default turns ONE malformed line into "no history" — which silently
   flips whatever mode the history was holding. Ask validators to poison one
   line of every ledger a verdict reads.
2. **Free-hand writers named in an LLM prompt need an exact example line + a
   parse-back step** in the prompt itself; schema prose alone invites the
   malformed line from insight 1.
3. **isolation:worktree can land in the WRONG repo** (its-my-claude instead of
   the project; doubly-nested dot-claude path) — validators should verify repo
   identity first and build their own worktree if wrong (proposal filed).
4. Telling the validator about known pre-existing breakage (uncommitted module)
   plus the exact unblock recipe saved the whole run from stalling on cargo.

---
## bloop: item 16 tail — down-vote routing (i-dream) — 2026-07-13

**Purpose:** Seventh live run: docs/25 item 16 tail (stale/known/wrong down-vote
routing) + deploy. Gate: PASS-WITH-NOTES — 1 blocker + 3 majors self-review missed.

**Insights:**

1. **Worktree isolation doubles as a free clean-checkout build test.** The gate's
   BLOCKER (grounding.rs never committed; repo unbuildable from history since 4
   commits back) was invisible in the main checkout — untracked files masked it.
   Every validator run in a worktree checks this class for free.
2. **Timestamp-blind exoneration is a reusable attack shape**: any "mark X, then
   treat matching events specially" design must order the mark against the event
   (graduation-before-down). The validator found it by replaying old downs with
   new marks in one catch-up batch.
3. **In Rust, omission-mutations can be compile errors** (exhaustive enums) — pick
   BEHAVIORAL mutations (re-apply penalty inside the skip arm) or the red-test
   proof never runs.
4. **The subagent-output guard wants its persistence clause verbatim** even when
   bloop's Phase 4.4 parent-persists pattern applies — use the guard's own
   read-only wording ("return FULL findings; I will persist to <path>") in the
   dispatch prompt from the start.
5. prefix-matching a provenance tag (starts_with("graduation")) is an immunity
   hole — allowlist exact sources for anything that gates a penalty.

---
## bloop: 5-capability wave (local-models) — 2026-07-13

**Purpose:** Five capabilities in one session, each through the loop: asset-verify,
findings-gate, the fleet routing experiment, the E8 web lane, the imagegen loop.

**Insights:**

1. **The gate is 8/8 on real defects self-review missed** — and this wave's were the
   scariest yet: a FALSE NEGATIVE (E8 dropped alpha, so transparent→opaque black read
   as "negligible"), a fail-OPEN security gate (findings-gate let `/etc/hosts` validate
   as evidence), and a lazy-decode traceback. Self-review never catches these.
2. **A guard that cannot fail is worse than no guard.** TWICE this wave a validator
   deleted a load-bearing mechanism and the battery stayed green: F11's fixture was
   alpha=255 everywhere (so compositing was untestable), F10 had no torn-write test.
   Always ask a validator to MUTATE the code the guard protects — a passing suite says
   nothing until you've seen it go red.
3. **Live > synthetic, every time.** The E8 fixture passed clean; the first real browser
   run immediately exposed two defects it structurally could not (a phantom border-color
   divergence from currentColor, and silent coverage gaps). Drive the real thing once
   before believing a green fixture.
4. **When a tool's own nudge tells you what to do, follow it** — E8's coverage note said
   "mark them to include them"; doing so surfaced the third planted divergence. That's
   the agent-first-tools contract paying off in the loop it was built for.
5. **Diagnose stalls, don't wait them out.** A 38-minute "generation" at 2% CPU was a
   half-downloaded model re-fetching from HuggingFace, not slow math. One bounded
   diagnostic found it; the fix was a ~0s cache check in verify.sh, not patience.

---
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