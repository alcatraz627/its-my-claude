---
brief: The evidence-based taxonomy of this account's surviving prose defects (two-split structure, verdict-first reporting, overclaim, contrastive scaffold) with worked rewrites, detection-rule splits, and the prose-lint.py tool; companion to doc-writing.md and audience-aware-writing
triggers:
  - topic:language-quality
  - topic:slop
  - topic:prose-defects
  - tool:prose-lint.py
  - phrase:"de-slop"
  - phrase:"make this plain"
related:
  - rules/audience-aware-writing.md
  - conventions/doc-writing.md
  - skills/ste-writing/SKILL.md
tier: 2
category: conventions
updated: 2026-07-28
stale_after_days: 365
---

# Language quality — the ratified defect taxonomy

What actually degrades this account's agent prose, measured rather than assumed.
Source: the 2026-07-27 pyramid sweep over 60 days of transcripts (2,106
transcripts, 32,991 assistant messages, 2.5M words), user-ratified via two
decision pages, adversarially vetted. Full artifacts and event log:
`~/.claude/style/sweep/20260727-simple-lang/`, rulings in
`vetted/p7-rulings.json`.

Lint any human-facing draft with
`python3 ~/.claude/scripts/style/prose-lint.py FILE` (stdin works). The score
is weighted violations per 100 words; lower is cleaner. One caveat before you
lint style docs: a file that quotes banned words and defect examples (this
file, the ste-writing skill) scores on its own material, because no regex can
tell mention from use. Read those scores accordingly.

The headline finding: the classic banned-word tells are extinct here (3 hits in
2.5M words). The surviving slop is structural. Its two worst genera are
invisible to any word ban.

## The categories (kept after adversarial vet)

### structure — the two-split chain and the fused sentence

The reader must read a sentence twice. The core defect is fusion: the
two-split pattern (a clause, then a dash-elaboration) overused, stacked
parentheticals interrupting the main clause, several distinct actions welded
into one sentence. The em-dash is the loudest marker, but comma and colon
splices of the same shape count. Length alone never triggers it; a 40-word
sentence that parses linearly is fine. Evidence-density never excuses it
(user rulings D1a and D2a: no report exemption).

> Before: "The review agent is a fable seat named X, now auditing the app
> against the CPRD with a structured brief: extract every user-facing
> capability (numbered, section-cited), verify each adversarially in code
> (file:line) and in the live app at :5101 (read-only, no mutations), classify
> BUILT / PARTIAL / MISSING — with doc-31 supplied so your deliberate changes
> read as divergences, not gaps — then rank what's missing…" (93 words)
>
> After: "The review agent is a fable seat. Its brief has five steps: 1.
> Extract every user-facing capability from the CPRD; number and cite each.
> 2. Verify each in code (file:line) and in the live app at :5101, read-only.
> 3. Classify each item: BUILT, PARTIAL, or MISSING. …"

### verdict-first — the conclusion before the facts

A verdict or done-state placed before the status facts that would justify it,
even when those facts follow and are true. Shapes: a "Done."/"Perfect." opener
with the evidence below; a PASS headline whose own details contradict it; the
agent declaring the overall task done. The done-verdict belongs to the user.
Report what is done, what is not, and what needs their review; then advise,
clearly marked as advice (user rulings D3-D7 and the standing memory
`feedback_verdict-last-status-reports`). Distinguish from overclaim: here the
evidence exists but is placed after the verdict.

> Before: "Perfect! The file has been written. Let me verify it was created
> successfully:"
>
> After: "The write call returned. Now I check that the file exists and is
> complete."

### overclaim — the claim without its evidence

The message asserts what nothing in it shows: a completion claim with no
evidence token anywhere, celebration before the verification has run, a
"should now work" future. It is rare (about 14 clear matches in 33k messages).
The user kept it standalone anyway (ruling A5b). The behavioral rule lives in
`rules/exercise-based-verification.md` and the declared-ready Stop hook; this
category is the prose-level name for the same failure.

> Before: "Updated the config. This should fix the flaky startup."
>
> After: "I updated the config. I have not re-run the startup path, so the
> fix is unverified."

### contrastive-scaffold — "not X, but Y"

The negation frame the thesaurus already bans (thes-20260716-165410-80),
promoted to a category after the vet found it in ~8% of scored messages with
no category home. State what the thing is; drop the "not X" preamble.

> Before: "This isn't a cache problem, but a race in the loader."
>
> After: "The bug is a race in the loader."

## Detection at a glance

| category | mechanical (prose-lint catches it) | judgment-only (review-time) |
|---|---|---|
| structure | word tiers >25/>35/>50; connective dashes (digit ranges like L15-L36 never count) | parenthetical-interruption severity |
| verdict-first | verdict token opening the first sentence | verdict contradicted by its own details |
| overclaim | the "should now work" phrase family | claim-versus-evidence matching |
| contrastive-scaffold | "not X, but Y" and "— it's" (the bare "not X —" form fires on plain negation; rejected) | none observed |

## Calibrate the metric before you let it steer

Before any score guides an artifact, run it on an ACCEPTED artifact of the same
class from the same repo. If accepted work scores badly, the metric is
disqualified for that class, and you say so rather than optimizing against it.

The failure this prevents is metric capture. On 2026-08-13 a PR description was
driven to 0.20 on prose-lint and rejected anyway; the repo's own MERGED PR scored
6.05 on the same linter. The score was anti-correlated with acceptance for that
class and kept being used regardless.

The mechanism is worth naming because it is not carelessness. Doctrine rightly
demands run-signals over feelings, and a lint is the nearest runnable instrument
to hand, so the demand for evidence quietly promotes whatever can be measured
into an oracle. A calibration run is the cheap defence: one command against work
that already passed the only judge that counts.

Scope: this covers prose-lint here, and any lint, score, or automated rubric
steering a subjective deliverable. The drafting-side companion lives in
`/ste-writing` § Subjective deliverables.

## Merged and demoted (do not re-add as categories)

- **hedge** and **register** merged into thesaurus enforcement: the sweep found
  enforcement gaps of existing bans (filler adverbs, hedged assertions,
  jargon/marketing words), not new classes. The rows live in
  `style/thesaurus.jsonl`; prose-lint carries the aligned lexicons.
- **reference** (ambiguous actors, name-churn: calling one thing "the script",
  "the sim", "the tool") is real but rare and judgment-only. It is a
  review-time check in /skeptical-review's lane, not a linter category. The
  fleet's mechanical proxies for it (sentence-initial this/it counts) were 97%
  noise; treat such counts as unreliable evidence.

## The register this taxonomy protects

Dense, evidenced, code-referenced prose is the house style and is NOT a
defect. The line: each sentence parses in one pass, facts precede conclusions,
the reader never has to guess an antecedent, and no claim outruns its
evidence. Chat replies keep a voice (`rules/audience-aware-writing.md` stays
the router). Strict controlled English (`/ste-writing`, strict mode) is for
docs, error messages, runbooks, and hook text only.

## Coverage map: every surface agent language ships through

| surface | gate | tier |
|---|---|---|
| chat final message | prose-smell-stop.sh (Stop) | hard block since mig 0044 (PROSE_SMELL_ENFORCE=1 in settings env; ≥2 block-tier tells; loop-safe, fires once per message). Promoted on 29d dry-run telemetry: 57 would-blocks, ~2/day |
| commit message trailers | git-hooks/commit-msg + guard-commit-signature | hard block (mig 0040) |
| commit message prose | rules/git.md hygiene bar + prose-lint | rule, advisory |
| PR bodies (gh pr) | guard-commit-signature | hard block: signature + connective dash (mig 0042) |
| prose files (.md .html .txt) | guard-prose-quality + prose-lint | hard block: dash, verdict-first, score>8 (mig 0041) |
| code-file string copy (ts tsx js jsx vue svelte py) | guard-prose-quality + code-copy-lint | hard block: dash, unverified, jargon (mig 0042) |
| code comments | rules/comments.md + style-watch | advisory by choice; dash in comments is an unruled surface |
| test / fixture / mock files | exempt by design (they quote bad prose deliberately) | none |
| style-system docs | exempt (mention-vs-use is regex-undecidable) | none |
| server-side commits and squash-merges | unreachable from machine hooks | ungated; needs CI or branch protection if ever wanted |
| user-facing-copy JSON (decision-pages, locale/i18n/strings/copy.json) | guard-prose-quality + code-copy-lint | hard block: dash, unverified, jargon (mig 0044, scope narrowed after validation: blanket .json blocked mcp-catalog and report caches). Other .json stays ungated by choice; MultiEdit-shaped writes are unmatched (theoretical on this build, which has no MultiEdit tool) |

## Provenance and the method note

The method was recall-first, precision-late. Mechanical scoring ranked the
corpus. A recall-biased local-model fleet flagged candidates at $0. Six
per-category seats confirmed or refuted each sampled flag adversarially. An
opus vet overturned two categories and vetoed six detection rules. Two user
decision pages were the only truth-bearers. The STE kit (asd-ste100.org, the
"cure for AI slop" episode) contributed the sentence-cap and active-voice
core. Its linter was derived from, not adopted: its word list conflicted with
house vocabulary, and it cannot see either of the two worst categories here.
