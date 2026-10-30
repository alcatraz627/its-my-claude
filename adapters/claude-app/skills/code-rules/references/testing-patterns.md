# Testing patterns

Each tag below is a test failure that recurred often enough to name. Cite them
by tag in reviews.

- **`[root-cause]`** Do not patch symptoms. When a fix does not work, stop and
  find out why before the next patch. Prove the mechanism with a throwaway
  probe that isolates the one unknown: probe, confirm, fix. Rule out the
  harness before blaming your change. A network, abort or timeout error is
  environmental until shown otherwise, and a stale reload or leftover process
  can pose as a product bug. A filter that removes what a generator produced
  is a symptom patch too. Fix the generator, and keep the filter only as an
  alarm that logs when it fires.
- **`[re-edit-thrash]`** Editing the same block 3 or more times in a row means
  you do not understand it yet. Stop, re-read the context, form a hypothesis,
  then edit once.
- **`[pagination]`** A response that looks complete may be paged or capped.
  Check `next_cursor`, `has_more`, and lengths that hit a round number (50,
  100, 1000).
- **`[truncation]`** Truncated output is silent. A 200-line file shown through
  `head -50` reads as complete. Check the line count or read it in full.
- **`[binary-rebuild]`** A committed fix is not an applied fix. For compiled or
  bundled output, rebuild before calling it done.
- **`[render-before-judge]`** Do not call a value wrong from the number alone.
  Render it, then judge.
- **`[human-note]`** `NOTE(by human)`, `HACK` and `IMPORTANT` mark tested
  choices. Ask before changing one.
- **`[post-compact]`** After the context is compacted, state you held in the
  conversation is gone. Re-check process, file and branch state before acting.
- **`[known-gap-tripwire]`** Ship a known gap as a strict failing marker that
  asserts the desired end state, never as a skip. In pytest that is
  `@pytest.mark.xfail(reason="<tracked item>", strict=True)`. The day the gap
  closes it turns into a failure and forces its own removal. A skip rots.
- **`[test-as-spec]`** A test that simulates a real process (a migration, a
  batch job) should encode the real decision rules and derive its numbers from
  the fixtures (`len([x for x in SEED if x.copies])`, not `== 6`). Its
  docstring must say what it does not model. A fake service is built from a
  recorded real response or the documented limits, with at least one case the
  real service refuses, or the suite stays green while production is down.
- **`[negative-checker-blind-to-omission]`** A validator made only of "must
  not contain" passes on empty or truncated output. Any gate that must hold
  needs one positive assertion (a required field exists, a value is in range).
  A round-trip check proves content survived, not that it has the property
  the reader needs. Assert the property.
- **`[real-input-distribution]`** A gate that blocks or labels data must run
  against real inputs, or a sample that matches production on the axes the
  gate keys on (case, format, field presence, length). A validator failed a
  third of real customer rows while passing hundreds of tests and a review.
  Routing was case-sensitive, the customer column was all uppercase, and the
  fixtures were Title Case. The tell: the person who wrote the check chose the
  fixture. When real inputs are unavailable, name the axes your sample misses.
- **`[computed-then-estimated]`** If a value was already computed, pass it
  through. That same bug traced to a function that formatted the disputed
  years into a note and dropped the numbers, so a later gate guessed a worst
  case. When you catch yourself estimating, look upstream for the exact value.
- **`[instrument-describes-the-wrong-moment]`** A diagnostic can work on the
  path you do not need and go quiet on the one you do. An `--explain` flag
  printed cache hits fine and printed nothing on a fresh run, because a
  blanket `2>/dev/null` swallowed that path. Test the diagnostic on the path it
  exists for, against a case whose answer you already know.
- **`[mutation-test-the-guard]`** A guard is not done until you watch it fail.
  Break exactly what it protects on a copy, confirm that test goes red,
  restore, confirm green. Do each guard alone. A mutation that stays green
  means the test is the bug. Common blind spots: the test calls the helper
  but never the real call site, two fixes cover one case so neither is pinned,
  a drift guard compares a constant to a literal in the same file, or the
  fixture makes the guarded behavior untestable by construction.
- **`[trust-the-tool-not-blind-to-it]`** "Use the tool's output, not your
  memory" guards against paraphrase. It must not also forbid the sanity check
  that catches the tool being wrong. Reproduce the output faithfully, and
  check its header, scope and size against what you expect before passing it on.
- **`[generated-artifact-scan]`** After generating CSS, codegen output or a
  migration, read the output against the code that references it. A green
  build proves the generator ran, not that its output is right.
