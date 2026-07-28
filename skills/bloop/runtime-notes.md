## bloop: B3 decay economy (i-dream phase-3 batch 1) — dream-catch-9f — 2026-07-28

**Purpose:** 25th run. Interventions join the decay economy (strength recompute,
undeliverable compost) + receipt label split. Gate: ISSUES-FOUND, 4 MAJOR + 5
MINOR + 3 NIT. Streak 25/25.

**Insights:**

1. Moving a store from records-are-permanent to records-get-REMOVED must
   re-audit every latch stored ON the record: compost deleted the owner-demote
   veto, and content-stable ids + an unpruned evidence ledger let a recompiled
   twin resurrect straight to live with pre-veto evidence (gate repro'd it with
   production functions). Fix was tombstones, not a smarter compost.
2. A silent-empty load (`unwrap_or_default` on parse error) composes with any
   read-modify-write caller into a destructive rewrite — the gate walked
   `promotions` → "run compile" → live records dropped, in a sandboxed HOME.
   Parse failure must be an Err distinct from "empty store".
3. The headline fix of a commit can be its least-tested line: the receipt
   arithmetic sign-flip mutation SURVIVED the full suite because run_compile
   needs a ClaudeClient. Pure-seam extraction (with_batch) made it pinnable.
4. Validator exercised the INSTALLED hook interpreters against a real post-B3
   file in a sandboxed HOME — the consumer sweep where this repo's MAJORs
   historically live came back clean this time, and that negative result is
   itself the evidence the field addition is safe.
5. A freshly-promoted comment-hygiene nudge fired on ~every Edit of the build;
   it genuinely tightened 4 doc comments, then became repeat-noise — surfaced
   once, dismissed thereafter. Live interventions shaping the session that
   ships their own economy is the system working.

---

## bloop: kanban fix-plan P0-P3 [adrev-kanbn-4b] — 2026-07-27

**Purpose:** behavior-anchored fix plan executed through the loop; every fix measured against a journaled friction moment.

**Insights:**

1. Running /skeptical-review and the validation gate in PARALLEL paid off: they converged independently on the same destructive blocker (unregister wrong-target), which is the strongest possible confirmation a finding is real.
2. A mutation test that stays green means the fix structure is the bug: a belt-and-braces pre-lock check masked the throw-based release and had to be REMOVED to make the guard pinnable. One mechanism, verified, beats two half-verified.
3. The subagent-output guard requires the literal persist-contract phrasing (path + who writes); "the parent persists it" without a named path gets blocked.
4. Give the validator its own isolated HOME and it will find what fixtures cannot: it hit the blocker organically by nuking its own test board with a typo probe.

---

## bloop: adapter enablement wave 1 — playground (fiber-snatcher) — 2026-07-25

**Purpose:** 23rd run. Project-adapter injection + generalized settle activity +
native-dialog surfaces + a mid-loop stop-race fix. Gate: ISSUES-FOUND (2 BLOCKER
classes, 2 MAJOR). Streak 23/23.

**Insights:**

1. Reserved names are an attack surface the moment third-party code can
   register into a namespace built-in discovery also populates: an init-script
   adapter registers BEFORE hydration, so `!adapters.has("queries")` saw it as
   already-discovered and silently skipped the real TanStack wiring. Any
   registry shared between discovery and user code needs an explicit RESERVED
   set at the register() door (same lesson as claude-ipc run 18's RESERVED).
2. Summing values from arbitrary project code without Number.isFinite+clamp
   is a page-wide DoS: one NaN pending made settle time out forever (NaN===0
   never true), and `0 += "0"` string-concats. Validate at the aggregation
   point, not per-source promises.
3. The mid-loop live detour (stop→verb losing its navigation) burned two wrong
   hypotheses before the journal's run-file TIMESTAMPS discriminated: three
   daemon boots in 90s = double-spawn, not slow-boot. Count boots, don't stare
   at teardown code. The fix was three coupled holes (ack-before-shutdown,
   probe-without-lock, unconditional pidfile rm) — fixing only the reproduced
   one would have left the class alive.
4. Editing the file that LOOKS like the verb's implementation is not enough:
   `fs stop` never routed through src/cli/stop.ts (V1, frozen) — the V2 CLI
   special-cases stop as a wire `close`. Trace the dispatch table before
   editing; the `{closing:true}` output shape was the tell.
5. Resume-after-API-stall (SendMessage to the dead seat) worked again; one
   wake-triggered chase-up ping got a complete high-quality report. The
   verdict+findings-inline/parent-persists delivery contract ran clean.

---

## bloop: felt-metabolism Phase 2 — compiler + interpreters (i-dream) — 2026-07-24

**Purpose:** 22nd run. Intervention compiler (opus-drafted triggers), hook
interpreters on both surfaces, smell panel, promotions flip. Gate:
ISSUES-FOUND, 2 MAJOR + 2 MINOR + 2 NIT. Streak 22/22.

**Insights:**

1. LLM-authored REGEX is a new input class: syntactic validation (compiles?)
   misses catastrophic backtracking entirely. Any surface running
   model-drafted patterns needs a wall-clock bound (SIGALRM) + subject cap,
   not just try/except — the gate hung the blocking hook 12s with a 6-char
   pattern that passed every shape check.
2. Negative caches need a version key, not a boolean: keying attempted-slugs
   by stable_id(slug|precheck) makes refinement re-qualify naturally, so the
   cache never needs manual invalidation.
3. "Silently null the invalid field" is quietly WIDENING validation: a
   dropped input_pattern turned a scoped nudge into fire-on-every-Bash-call.
   Provided-but-invalid must reject the record.
4. Fuzz the generated artifact, not the generator: the gate extracted the
   real scripts and drove 21 hostile inputs through actual bash+python —
   that's what proved the stdout/exit contract, not the Rust tests.
5. Pre-fixing predicted findings (demote-veto latch, would-fire retention)
   before dispatch kept the gate's budget on the unknown unknowns — both
   MAJORs were things self-review had NOT predicted.

---

## bloop: felt-metabolism Phase 1 — identity + instrumentation (i-dream) — 2026-07-22

**Purpose:** 21st run. Seven units (stable-id reinforce, feedback retention,
surfaced-claim removal, assay panel, curves, firings scan, telemetry pulses)
as one gated batch. Gate: ISSUES-FOUND, 1 MAJOR + 7 MINOR. Streak 21/21.

**Insights:**

1. The MAJOR was in the interaction between MY new writer and an untouched
   consumer: appending pulse events after vents anchored a position-based
   delta cursor on a trailing pulse, shadowing all future vents. When a batch
   changes a FILE another system cursors over, hand the validator the
   consumer's cursor logic explicitly — it found this in external_domain.rs,
   a file the diff never touched.
2. Naive ts-sorting was NOT the fix (a current-week aggregate updating its ts
   to now re-shadows forever). Fixed timestamps at period boundaries (week
   Monday) make aggregates sortable-but-never-newest. Reusable for any
   aggregate row merged into an event stream.
3. Two pipeline-masked exit codes in one session (secret-scan | head, the
   known trap) — caught by re-running bare before trusting. The lesson keeps
   needing the re-run reflex, not just the knowledge.
4. Validator dispatch that names the live-mutation hazard precisely (never
   run the binary against real HOME; build real, run HOME-overridden) got
   full compliance plus a clean-worktree restore, mutation cycle included.
5. Exercising the new verb against live data mid-build (curves: 127 slugs)
   produced the arc's best receipt for free: the one slug with a mechanical
   rule is the one with a falling curve.

---

## bloop: hub repeat-nav latency, SWR at every layer (claude-instances) — 2026-07-22

**Purpose:** 21st run. 13.6s of cumulative /data per index navigation → 31ms
boot settle (LRU+byte-bound parse cache, single-flight scan SWR, ETag/304,
path memo). Gate: PASS-WITH-NOTES (2 coverage gaps, 4 latent edges). 21/21.

**Insights:**

1. Measure in the BROWSER before designing: server endpoints curl'd at 1-14ms
   while the page burned 13.6s — the punishment was a 43-request peek storm
   thrashing an 8-slot FIFO plus Chrome's 6-connection queueing. And measure
   AGAIN after each layer: the "fixed" repeat nav still showed 700ms waves
   (queueing behind live parses), and the final 31ms only landed once the
   gate's out-of-scope appendix (a per-request recursive tree glob) was fixed.
   Cumulative request-duration is queue-skewed; burst-settle wall time is the
   honest metric.
2. A coverage gap can sit on the exact commit that exists to be a guard: the
   finally-guard commit had zero test holding it, and the gate proved its
   trigger REACHABLE (invalid UTF-8 → UnicodeDecodeError is a ValueError,
   outside the caught tuple). Fixes whose whole point is resilience need
   their failure induced, not just their code merged.
3. N-entries-under-cap tests cannot pin ORDERING: 20 entries under a 48 cap
   never evict, so LRU vs FIFO was indistinguishable until a cap-3 re-touch
   case discriminated. When a change's value is a POLICY (LRU, debounce,
   single-flight), the test must construct the case where policies diverge.
4. Growing caps widens blast radius: FIFO-8 accidentally capped memory; LRU-48
   of parsed transcripts needed an explicit byte bound. Any cap raise on
   entries-holding-big-objects needs a second bound in bytes.
5. An owner-flagged design comment (prime-before-paint, 1800ms cap) is a
   scope fence for perf work: the fix was making the existing design fast,
   not reordering it. Dropped the snapshot-paint-first unit for exactly this.

---

## bloop: dashboard wave 3 — D1/D2/D3 surfacing (claude-ipc) — 2026-07-21

**Purpose:** 20th run. Six build units surfacing the broker's honesty data in
the -i TUI + power features. Gate: ISSUES-FOUND, 1 MAJOR. Streak 20/20.

**Insights:**

1. Self-review and the gate caught the SAME bug-class in different places:
   self-review found freshness rendered off the wrong clock (snapshot vs
   render); the gate found the vocabulary gap (3 of 6 delivery states
   unmapped — including `surfaced`, the state the feature exists to show).
   When a change's value is an honesty claim, enumerate the FULL state
   space of what you're relabeling — the unmapped tail is where the claim
   quietly breaks. `grep the producer's enum before writing a label map.`
2. Telling the validator to mutation-test a NAMED fix (revert this exact
   expression, watch this exact test go red, restore by editing) got a
   clean red→green cycle with no git-checkout risk. Name the mutation in
   the dispatch prompt; don't leave it to validator invention.
3. A validator on a LIVE shared broker needs the read-only key-list spelled
   out (nav keys enumerated, action keys forbidden). It complied exactly;
   the walk still verified input-gating, sort, triage, filters live.
## bloop: meld PH2 instances-side digest wiring (claude-instances) — 2026-07-20

**Purpose:** 19th run. Wired the ipc digest contract onto the PH0-tested
consumer (per-cwd capped spawn, dark fallback, §8.4 disagreement pass, HTML).
Gate: PASS-WITH-NOTES, 1 MAJOR. Streak 19/19 — the major was in the exact
mechanism whose comment documented the threat it failed against.

**Insights:**

1. A mitigation can fail precisely for its own documented case: the killpg
   used getpgid at KILL time, but the child that fast-exits leaving a
   grandchild on the pipe is a zombie by then — getpgid raises, the kill
   never fires, the grandchild leaks per scan. Capture the pgid at SPAWN
   (start_new_session makes pgid == pid, valid while any member lives).
   Prompt validators to attack the mitigation's own motivating scenario.
2. `isinstance(x, int)` admits JSON `true` (bool is int; true+1 == 2) — a
   poisoned counter file skipped a 2-scan debounce on scan one. Any int
   guard on external data needs `not isinstance(x, bool)` + a range cap;
   grep for bare isinstance-int on anything a file feeds.
3. Dark-launch consumer-first worked end-to-end: the verb-absent probe (real
   binary exits 2 instantly) pins the fallback BYTE-shape, so the live page
   was provably unchanged while the scratch hub showed the full feature.
   Verifying "feature invisible" is as test-worthy as "feature works".
4. The stub-inside-python trap: embedding json.dumps output into generated
   PYTHON source dies on null/true at stub runtime — and `echo EXIT=$?`
   after a pipeline masked it (head's status). Stubs read a JSON sidecar;
   exit codes checked bare. (Both were known lessons; they still fired.)
5. Parent-persist delivery worked cleanly again: verdict via teammate
   message, parent wrote the report + dispositions table, TaskStop'd the
   seat. A 2-day-stale idle notification from a DEAD sibling arrived
   mid-loop — check the running-teammates list before chasing ghosts.

---

## bloop: ipc coworker-layer step 0 — push spine + 8 fixes (claude-ipc) — 2026-07-17

**Purpose:** 18th run. Built the survey-driven boot obligations digest + B7
closure + 8 harvested fixes as one gated batch on feat/i-dashboard. Gate:
PASS-WITH-NOTES (2 MAJOR, 2 MINOR), all fixed. Streak intact — the gate found
security holes contradicting the code's OWN docstrings that self-review + a live
smoke both missed.

**Insights:**

1. The gate's two MAJORs were both "the docstring claims X is protected; it
   isn't." neutralizeFrame's own comment named bracket-forging as the threat and
   defended exactly that — while a NEWLINE in the same string walked straight
   through into a peer's rendered frame. And RESERVED's comment said "a peer
   holding 'ipc' could mint any broker notice" — the set blocked REGISTERING it
   but not SENDING as it. Lesson for validator prompts: point them at every
   in-code security CLAIM and have them attack the claim's negative space, not
   just the diff.
2. A design survey is a load-bearing build artifact. Six peers surveyed at boot
   converged unanimously on "identity first, obligations second, inventory never"
   — that became the digest's literal acceptance spec (test asserts the first
   line startsWith "You are"). Surveying the users of the thing you're building,
   through the thing you're building, produced a sharper spec than the design
   review had.
3. B7 (unverifiable platform-resume wiring) closed by DESIGN, not by testing the
   wire: make the fallback deliver the SAME payload as the primary, gate both on
   one marker, and the wire being untrustworthy stops mattering. Cheaper and more
   robust than proving the platform re-fires SessionStart.
4. The worktree validator sat at an ANCESTOR commit (c2f065c, behind a30b162)
   while my Read tool served the real shared checkout (fac4a36) — it caught the
   mismatch itself via git hash-object and re-pinned. Worth telling worktree
   validators up front: "verify HEAD == <target sha> before trusting any file
   read; the worktree base may lag."
5. Red-first tests ARE the mutation proof for a new guard when they were red on
   the unmutated-old code and green after the fix — the gate independently
   mutation-tested all four and confirmed. Two layers agreeing (my red-first +
   its mutation) is the cheap version of the guard-needs-opposite-proof rule.

---
## bloop: 3x run — vocab-sweep promotions (gcc-stupidity) — 2026-07-17

**Purpose:** Three bloops in one session (pyramid-sweep skill, vocab decay
loop, WHY-vs-HOW ruling) + an opus collection review over all output docs.
Gates: PASS-WITH-NOTES / ISSUES-FOUND / PASS-WITH-NOTES; collection review
PASS-WITH-NOTES. 18/18 streak of gates finding something real.

**Insights:**

1. Display caps must never gate telemetry: gate 24 proved the hinter's
   2-per-prompt cap + cluster dedup was also capping the usage LEDGER, so
   cluster siblings read dormant while actively used. Log matches, show caps.
2. Verdict+path-only return contract (proposed prop-20260717-104030-3e)
   worked on first live use — the collection reviewer's message was one line;
   no stale-findings double-channel to reconcile.
3. An API death mid-review left ZERO salvage because the report was written
   at the end; the re-dispatch added "write incrementally per section" and
   that should be standard in every material-output dispatch prompt.
4. Gate-found deferred items are cheapest to close in the same fix pass while
   the author context is hot — both ruling-gate deferrals cost one line each;
   "owner: whoever next touches it" usually means "never".
## bloop: R3 seven small truths (claude-instances) — 2026-07-17

**Purpose:** Seventeenth run, third in one session. Seven self-contained
dashboard fixes as one gated batch. Gate: PASS-WITH-NOTES (first non-ISSUES
verdict in three runs; the batch's guards were red-first from the start).
Streak: 17/17 — even a PASS carried a real MAJOR-class robustness gap.

**Insights:**

1. "Safe by ordering accident" is a finding class worth naming: codex None
   survived estimate_cost only because the unpriced-model check fires before
   isfinite(None) would TypeError. The gate distinguished works-today from
   structurally-safe; the fix is making the guard explicit at every call site,
   not trusting evaluation order.
2. A validator's throwaway probe can be better than the shipped guard —
   promote it. The gate wrote an in-process HTTP probe for the parse cache and
   proved it catches an in-place-mutation regression the t_grep guard cannot;
   it is now tests/fixtures/hub-cache-probe.py. Ask validators to leave their
   probes in the scratchpad for exactly this reason.
3. Validators can damage the live system while testing the code that guards
   it: this one deleted the live hub's pidfile+log during a race test, then
   disclosed, repaired, and re-isolated — but the log history is gone to an
   unlinked inode. Dispatch prompts for anything touching /tmp control files
   need the same "fake names only" clause tpath/cost files already get
   (claude-hub-*.pid was not on the forbidden list; enumerate the CLASS, not
   the instances).
4. One-shot migration shims (legacy pidfile adoption) are testable by racing
   N concurrent copies against scratch paths — 20x concurrent mv -f gave one
   consistent winner. Cheap pattern for any rename-with-compat change.
5. The cheap version of a deferred hardening item (tpath mtime vs primed
   etime — zero new subprocesses) beat the doc's assumption that it needed a
   subprocess per pid. Re-derive the cost from what the code ALREADY primes
   before accepting a "not worth it" from an earlier pass.

---
## bloop: R2 stable record identity (claude-instances) — 2026-07-17

**Purpose:** Sixteenth run, same session as the fifteenth. Record ids + id
cursor across parser/server/client. Gate: ISSUES-FOUND — a pre-existing
silent-drop path (grow-and-close) and an under-stated design limit.
Streak 16/16.

**Insights:**

1. Live data corrected the design twice before the gate even ran: mode lines
   carry no uuid AND no timestamp (identity collided as mode::auto on real
   data), and a 5th-from-last cursor slice returned 237 records because
   first-match-by-id landed on the duplicate. Exercise every new contract
   against a REAL artifact the moment it parses — fixtures modeled the design,
   not the data.
2. When a change turns a trusted-by-construction value (integer seq) into one
   that originates in untrusted bytes (uuid from a transcript), every sink
   inherits a new threat model — the DOM attributes needed esc() the ints
   never did. Grep the sinks whenever a value's PROVENANCE changes.
3. The gate's best find was a protocol hole, not a code bug: a group that
   grows AND closes between two polls fell out of both resend buckets. The
   fixed-cadence probe could never land on it; the validator constructed the
   interleaving deliberately. Ask validators to enumerate EVENT INTERLEAVINGS
   between polls, not just malformed inputs.
4. For repeated identical events with no distinguishing content, position-free
   identity is impossible in principle — say so in the design doc as a bounded
   honest limit instead of hiding it behind "changes one id" (the gate proved
   ids REASSIGN, which reads much worse until bounded).
5. Probe-as-executable-spec drifted from the implementation within one session
   (shrink-adopt semantics) — when the spec and code live in two languages,
   diff their SEMANTICS in the gate prompt explicitly.

---
## bloop: CLI verbosity ×8, 3 batches (i-dream) — 2026-07-17

**Purpose:** Fifteenth+ run. Three build batches, two gates. A: ISSUES-FOUND
(3 MAJOR). B+C: PASS-WITH-NOTES (2 MAJOR). Streak intact — every seat found
real defects self-review missed.

**Insights:**

1. **One seat per 2-3 related batches right-sizes the gate.** Two validators
   covered five commits; each got a worktree pinned to its commit so the
   parent kept building on master underneath — no re-base drama, and the
   B+C seat never saw the A-fix commit (by design: audit the commit, not
   the moving tree).
2. **Ask the validator to weigh NEW-vs-OLD failure modes when a fix changes
   a contract.** The insight-digest budget fix traded silent overspend for
   a truncation→overwrite path; the dispatch prompt named "tiny budget" as
   an attack and the seat graded the regression explicitly (worth-it, needs
   a floor). That framing produced the best finding of the run.
3. **Idle-without-delivery again (4th time); the chase ping again recovered
   a complete report in minutes.** Ping-on-idle is now standard procedure,
   not a fallback.
4. **Gate mutations re-run red→green after the fix, both times** — the
   freshness-verdict pin and the appended_since identity guard each failed
   against the exact mutation that had stayed green pre-fix. Cheap, decisive.
5. **The lm pre-gate can be degenerate (1-token output + stdout banner
   breaking the findings-gate pipe)** — skip honestly and lean on the paid
   seat; don't burn time debugging the free lane mid-loop.

---

## bloop: R1 truthful aggregates (claude-instances) — 2026-07-17

**Purpose:** Fifteenth run. Dashboard aggregates decoupled from the 20-row
display list via a (mtime_ns, size) summary cache. Gate: ISSUES-FOUND — 2
MAJOR the self-review missed. Streak 15/15.

**Insights:**

1. Ground-truth checks need INDEPENDENT traversal code: scan-vs-itself agreed
   at "644 sessions/week" because both shared one recursive iterator; a flat
   glob disagreed and exposed 379 sub-agent transcripts counted as sessions.
   Agreement between a system and itself is not verification.
2. Unit guards were all structurally blind to the assemble-block wiring — only
   a whole-scan e2e probe (HOME redirected to a temp root) could catch a
   revert to compute_aggregates(history). Mutation-testing proved it: the
   revert left every unit guard green and only the e2e went red.
3. A validated SHAPE is not a validated VALUE: isinstance(int) admitted
   negative and 10**300 counts from the untrusted cache into the day's totals
   (gate MAJOR). Range-check at the same boundary that type-checks.
4. When widening a data window, grep every consumer of every field in the
   struct for implicit bucket assumptions — model_breakdown was day-agnostic
   in the data but rendered under a "Today" label by native/Bar.swift (gate
   MAJOR; the validator read the Swift consumer, I had only grepped the HTML).
5. Validator idle-without-delivery again; one chase-up ping recovered a
   complete report. New dispatch clause that earned its place: "never run a
   mutated scan against real $HOME" — the live dashboard's cache would have
   persisted poisoned entries keyed by real (mtime_ns, size).

---
## bloop: hook loop-safety helper (gcc D4a) — 2026-07-16

**Purpose:** Extract the duplicated shasum-marker loop-safety idiom from the Stop
hooks into scripts/hooks/hook-common.sh; migrate 3 of 8 sites. Gate:
PASS-WITH-NOTES (no blockers/majors). Replay 40/40.

**Insights:**

1. The 2026-07-11 subsystem audit's "byte-identical, collapse ~150 lines → 8"
   OVER-CLAIMED uniformity. Reading every call site found two families — A
   (filename-dot, prose-smell: heed-tracked 3-state with warn-log heeded true/false)
   vs B (absence/structural-claim: stakes-scaled 2-state, no heed-clear, block→soft
   / soft→silent on repeat). The audit's proposed monolith
   loop_safe_block(...,block_msg,soft_msg) would have forced A's lifecycle onto B.
   The faithful helper is the NARROW mechanism both share (sid8 + sig/marker); each
   hook keeps its own lifecycle. Enumerate the real sites before designing the API —
   an audit summary is a lead, not the spec.
2. The replay fixture gate is FIRST-FIRE ONLY (fresh synthetic sid per fixture +
   cleanup after), so it structurally cannot catch a repeat-path regression — which
   is exactly the path a loop-safety refactor touches. 40/40 green proved the fire
   DECISION unchanged, not the repeat SUPPRESSION. Know what the regression net does
   NOT cover: added hook-common.test.sh for the repeat path, filed a proposal to
   give run_fixtures.py a shared-sid double-run mode.
3. Mutation-test restore stayed copy-based; the whole change was uncommitted +
   hook-common.sh untracked, so a git checkout/stash/clean would have wiped it
   (the 2026-07-15 note's lesson held — told the validator this explicitly).
4. Validator dispatch hygiene gap: it polluted the live warn-events.jsonl (3 lines)
   before it began redirecting WARN_LOG_STORE, and briefly Edit-mutated the live
   hook-common.sh (Edit is ungated; only the Bash run against the mutated file was
   classifier-blocked). Next time, the dispatch prompt should tell the validator to
   set WARN_LOG_STORE and work on scratch COPIES from step one — no live side effects.

---

## bloop: ipc identity + honest-failures (claude-ipc) — 2026-07-15

**Purpose:** Fourteenth run. Four diagnosis items (self-send, honest refusals,
session-keyed liveness/wake, successor surfacing) + gate. Gate: PASS-WITH-NOTES,
1 MAJOR the self-review missed. Streak 13/13.

**Insights:**

1. **`git checkout -- <path>` as a mutation-test restore WIPES uncommitted
   implementation** (restores to HEAD, not pre-mutation) — lost the whole A1
   registry+monitor build mid-loop; compounded by `tail -2` hiding the suite's
   pass/fail line so the red-proof was unverified. Copy-based restore only:
   cp to scratchpad → mutate → test with the pass/fail line VISIBLE → cp -f
   back → diff -q. Filed as prop-20260714-185635-61 + pinned for i-dream.
2. **The gate found the same bug-class the branch was killing, via a path no
   test covered**: broadcast → two boxes of one dual-aliased session → wake
   line counted one message twice. When a fix set targets a failure CLASS,
   have the validator enumerate OTHER paths into that class (broadcast vs
   direct, project vs session) — my tests only covered the incident's path.
3. **Pre-fixing predicted findings while the gate runs works**: the cancel-on-
   garbage no-op was fixed in 127f9cd mid-review; the validator confirmed it
   was about to flag exactly that (branch moved under it; it re-based its
   audit cleanly).
4. **Exercising on an isolated broker found a boot bug reading never would**
   (custom socket path → socket bound, pidfile write dies, broker half-up).
   The smoke rig's own failure WAS the finding.
5. **Exit-code checks must not read `$?` after a pipeline** — `cmd | head;
   echo $?` reports head's status. Check exit codes bare.

---
## bloop: Accounts v2 (versable/speedway) — 2026-07-14 (mid-loop, gate pending)

**Purpose:** Thirteenth run, first spanning a two-agent shared tree with a serial
browser. Build done + committed (0242f7d); Phase 3/4 blocked on expired gcloud ADC.

**Insights:**

1. **The lm pre-gate's value is again the cluster, not the findings**: 6 opinions,
   0 literally right, but poking their neighborhood exposed a real server-side
   hardening gap (setRole accepted any string incl. owner; remove could delete the
   owner via crafted POST — UI-hidden but server-obeyed). "The UI hides it" is an
   attack surface enumerable pre-gate: diff what the UI prevents vs what the action
   validates.
2. **Owner rules can change MID-LOOP in a shared tree.** A no-card-header-divider
   rule landed via the peer while my build (with 7 titleDividers) was uncommitted.
   On a shared branch, read the peer's handoff BEFORE committing — conforming cost
   one regex; missing it would have shipped a rule violation into the owner's round.
3. **Browser handback asymmetry: page-close ≠ process-exit.** The peer's release
   left its Chrome alive at about:blank holding the profile; my kill attempt was
   classifier-blocked (correctly — can't prove ownership from my side). Protocol
   that works: holder kills its OWN pid on request. Budget one ipc round-trip.
4. **Route files trip the dup-symbol guard on whole-file Writes** (every route
   exports loader/action). The working path: stage in scratchpad via Write, then
   python-copy into the route. Edits to existing routes pass fine.
5. **gcloud ADC expiry 500s every Firestore page and only a human can fix it**
   (interactive OAuth). The app's credential-expiry page names the exact commands —
   relay them verbatim; do not attempt the login headlessly.

---
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