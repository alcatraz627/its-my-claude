# Improvement Backlog — from first real run (2026-05-24)

Each item below comes from a specific weakness observed when running the skill on the Versable v5.0 release vs the ad-hoc original (see `_COMPARISON.md` §8 + this session's run). Format: **finding → root cause → fix → effort/priority**.

---

## P0 — fix before next real run

### W1: Flat chunking degenerates on docs-heavy repos
**Finding**: `chunk-files.py` produced 28 chunks all named `flat-NN` instead of semantic names like `be-tests-jobs_p1`. The path-prefix grouping hit the 30-chunk cap and fell through to size-balanced flat partitioning.

**Root cause**: The Versable repo has ~700 small files under `frontend/docs/product/jobs/create-enhancements.images/` (PNG screenshots). Path-prefix-depth-3 produced one group per image dir → far over the 30-chunk cap → triggered flat fallback for ALL chunks (not just the doc tree).

**Fix**:
1. In `chunk-files.py`, run the cap check on the **count of groups that have >MIN_FILES**, not the total group count. Tiny groups become `_misc-<top>` (already coded) without triggering the cap.
2. Add a `--max-files-per-misc` parameter (default 200) so the _misc bucket also splits if it overflows.
3. Treat binary file extensions (`.png`, `.jpg`, `.svg`, `.pdf`) as "skip from chunking" — they bloat byte counts without inventory value.

**Effort**: 30 min. **Priority**: P0 — semantic chunk names materially help the themes phase group correctly.

---

### W2: Sub-agent refusing to write (false "safety restriction")
**Finding**: 1 of 14 inventory sub-agents (chunk 28) replied "I cannot write files directly due to safety restrictions" and provided content inline. The Explore agent CAN write — this was a hallucinated refusal.

**Root cause**: The Explore subagent type has tools restricted (no Edit/Write/NotebookEdit per its description). The chunk-28 agent correctly identified its tool set but incorrectly concluded "cannot write" — actually it should use other means OR I should have dispatched it as `general-purpose`.

**Fix**:
1. **Dispatch inventory sub-agents as `general-purpose`, not `Explore`** — Explore is restricted and prone to this exact failure. Cost trade-off is minor; reliability is worth it.
2. Add retry-on-refusal to the runner: if a sub-agent returns text containing "cannot write" / "safety restriction" / "unable to save", auto-retry once with general-purpose.
3. Document the right subagent_type in `phases/inventory.md`.

**Effort**: 5 min change to runner + 5 min update to phase prompt. **Priority**: P0 — this happened on the first run.

---

### W3: Coverage budget defaults to partial (14/28) without telling user
**Finding**: I cut 14/28 chunks "for cost" but the skill has no mechanism for "run a subset" — I did it ad-hoc. Future user invocations may or may not realize they can subset.

**Root cause**: `depth-runner.sh` doesn't have a `--chunks <N|range|all>` flag. Subsetting requires hand-editing dispatch logic.

**Fix**:
1. Add `--chunks all|<N>|<range>` to the runner. `all` = default. `<N>` = first N. `<range>` = e.g. `1-10,15,20-25`.
2. Wizard prompt (when built): "Process all 28 chunks (~30 min, ~$25) or top N by size?"
3. If subsetting, **automatically annotate the byte-coverage percentage in `themes/THEMES.md`** top-of-doc so the user knows what was skipped.

**Effort**: 1 hour. **Priority**: P0 — defaults to "user surprised by cost" without it.

---

## P1 — fix before promoting from depth-thorough/ subdir into top-level skill

### W4: No human-in-the-loop adaptation when something unusual happens
**Finding**: When chunk-28 refused to write, the skill had no way to surface "this chunk failed, do you want to retry / skip / continue?" — I had to manually save inline content.

**Root cause**: The runner is fire-and-forget for sub-agent dispatches. No mid-flow checkpoint that surfaces individual failures.

**Fix**:
1. Runner reads return abstracts from each Agent dispatch (they're available in tool result).
2. If any abstract contains failure markers (regex on "cannot write", "could not", "refused", "error"), pause + print + ask user: continue / retry-with-different-model / skip-this-chunk.
3. For full automation: `--auto-retry` flag with up to N retries per chunk before skipping.

**Effort**: 2-3 hours (requires the runner to be a real orchestrator, not a bash dispatcher). **Priority**: P1 — paper-cut for now, real risk when running 28+ chunks unattended.

---

### W5: Default excludes drop too much (or not enough — depending on repo)
**Finding**: NEW defaults filtered to 1091 files vs OLD's 599. The difference is `frontend/docs/**` — OLD excluded (Versable convention), NEW didn't (per magi-revised plan §C6 "let users opt in").

**Root cause**: Per-repo conventions about what's "the diff" vs "noise" can't be globally defaulted. The magi-revised "no `**/docs/**` default" is right for docs-as-code repos, wrong for repos where `docs/` is scratchpad.

**Fix**:
1. Add `.discover-excludes` file convention — if present at repo root, the skill reads it as additional excludes.
2. Wizard asks once on first run per repo, saves answer.
3. Document the trade-off clearly in `phases/inventory.md` so users learn before being surprised.

**Effort**: 1 hour. **Priority**: P1 — per-repo state would also enable W3's "last-used depth" memory.

---

### W6: SHA hygiene rule reduced fake SHAs but didn't eliminate them
**Finding**: NEW themes phase had 1 fake SHA caught by verifier (vs OLD's ~38). Improvement, but not zero.

**Root cause**: Themes phase prompt says "if SHA not in commits.tsv, write `(post-cutoff)`" but doesn't *verify* — agent can still hallucinate SHA-shaped strings that happen to look like commits.tsv entries.

**Fix**:
1. Post-process themes output with a script that extracts SHA-shaped strings (`[a-f0-9]{7,12}`) and validates each against commits.tsv.
2. Any SHA not in commits.tsv → automatically replaced with `(post-cutoff)` + flagged in a side log.
3. Removes the SHA-hygiene burden from the verifier entirely (it can focus on other FMs).

**Effort**: 30 min. **Priority**: P1 — automation of a known failure mode.

---

## P2 — quality-of-life improvements

### W7: Progress is invisible during 30-min runs
**Finding**: I dispatched 14 inventory agents in one message and then waited. No live indication of which ones had finished vs in-flight. (For this session it was visible via the agent return order, but the runner script wouldn't have known.)

**Fix**:
1. Each phase's runner appends one line to `_progress.log` on phase start + completion with timestamp + counts.
2. After inventory phase, write `inventory/_summary.json` with per-chunk status (OK / UNDER / MISSING).

**Effort**: 30 min. **Priority**: P2 — operational, not correctness.

---

### W8: Themes phase doesn't know about TaskList state without manual cross-reference
**Finding**: NEW verifier promoted 5 MAYBE→DEFINITELY based on commit-message risk language. But this could be richer if the themes phase itself read TaskList state (in-progress vs completed) as additional signal.

**Fix**:
1. If `~/.claude/projects/<project>/MEMORY.md` or `frontend/.claude/notes/<plan>.md` exists, themes phase reads it as supplementary input.
2. Verifier already reads the inventory + commits; adding "and any project-local task/note files" is a one-line change to the prompt template.

**Effort**: 15 min prompt change + 1 hour to spec where to look. **Priority**: P2 — incremental signal.

---

### W9: No regression test against old artifacts
**Finding**: The magi-revised plan promised `scripts/regress.sh` against PR #177 baseline as a v1 must-have. Skipped for this demo build.

**Fix**:
1. Check the `release-v-5.0/` artifacts into `regression-baseline/`.
2. Write `scripts/regress.sh` that re-runs against the same source range and diffs the outputs (theme count ±10%, all DEFINITELY issues present, ops checklist 80% coverage).
3. Wire into `/loop` to run weekly.

**Effort**: 2 hours. **Priority**: P2 — was promised v1; deferred for demo speed.

---

## P3 — nice-to-have

### W10: Linter markdown emphasis collision (`LOGGER_CRAB_*` → `LOGGER*CRAB*\*`)
**Finding**: A linter on save converted `LOGGER_CRAB_*` to `LOGGER*CRAB*\*` interpreting the underscores as markdown emphasis.

**Fix**: Wrap env-var-shaped tokens in backticks consistently in all phase prompts and synthesize templates.

**Effort**: 10 min. **Priority**: P3 — cosmetic.

---

## Summary table

| ID | Finding | Priority | Effort | Status |
|---|---|---|---|---|
| W1 | Flat chunking on docs-heavy | P0 | 30 min | open |
| W2 | Sub-agent false refusal | P0 | 10 min | open |
| W3 | No subsetting flag | P0 | 1 hour | open |
| W4 | No mid-flow adaptation | P1 | 2-3 hours | open |
| W5 | Per-repo excludes | P1 | 1 hour | open |
| W6 | SHA hygiene post-process | P1 | 30 min | open |
| W7 | Progress visibility | P2 | 30 min | open |
| W8 | TaskList cross-reference | P2 | 15 min + 1 hour | open |
| W9 | Regression test | P2 | 2 hours | open (was v1 must-have) |
| W10 | Linter emphasis collision | P3 | 10 min | open |

**Total v1.1 build budget**: ~9 hours. Run on a representative repo after each P0/P1 ships to validate.
