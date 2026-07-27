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
updated: 2026-07-27
stale_after_days: 365
---

# Language quality — the ratified defect taxonomy

What actually degrades this account's agent prose, measured rather than assumed.
Source: the 2026-07-27 pyramid sweep over 60 days of transcripts (2,106
transcripts, 32,991 assistant messages, 2.5M words), user-ratified via two
decision pages, adversarially vetted (full artifacts and event log:
`~/.claude/style/sweep/20260727-simple-lang/`). Lint any human-facing draft
with `python3 ~/.claude/scripts/style/prose-lint.py FILE` (or pipe stdin);
score is weighted violations per 100 words, lower is cleaner.

The headline finding: the classic banned-word tells are extinct here (3 hits in
2.5M words). The surviving slop is structural, and its two worst genera are
invisible to any word ban.

## The categories (kept after adversarial vet)

### structure — the two-split chain and the fused sentence
The reader must read a sentence twice. The core defect is fusion: the two-split
pattern (a clause, then a dash-elaboration) overused, stacked parentheticals
interrupting the main clause, several distinct actions welded into one
sentence. The em-dash is the loudest marker, but comma and colon splices of the
same shape count. Length alone never triggers it; a 40-word sentence that
parses linearly is fine. Evidence-density never excuses it (user ruling D1a/D2a:
no report exemption).

Real instance, and the rewrite shape:
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

Detection: mechanical for the length tiers (>25/>35/>50 words) and connective
dashes (spaced or letter-joined only; digit ranges like L15-L36 never count);
judgment for parenthetical-interruption severity.

### verdict-first — the conclusion before the facts
A verdict or done-state placed before the status facts that would justify it,
even when those facts follow and are true. Shapes: a "Done."/"Perfect." opener
with the evidence below; a PASS headline whose own details contradict it; the
agent declaring the overall task done. The done-verdict belongs to the user:
report what is done, what is not, what needs their review, then advise,
clearly marked as advice (user rulings D3-D7 + the standing memory
`feedback_verdict-last-status-reports`). Distinguish from overclaim: here the
evidence exists but is placed after the verdict.

> Before: "Perfect! The file has been written. Let me verify it was created
> successfully:"
>
> After: "The write call returned. Now I check that the file exists and is
> complete."

Detection: mechanical opener check (verdict token in the first sentence) at
good precision; the verdict-contradicted-by-details case is judgment-only.

### overclaim — the claim without its evidence
Kept standalone by user ruling (A5b) despite rarity (~14 clear matches in 33k
messages): completion claims with no evidence token anywhere, celebration
before the verification has run, "should now work" futures. Owned behaviorally
by `rules/exercise-based-verification.md` and the declared-ready Stop hook;
this category is its prose-level name.

Detection: the future-phrase list is mechanical; claim-versus-evidence matching
is judgment-only.

### contrastive-scaffold — "not X, but Y"
The negation frame the thesaurus already bans (thes-…-80), promoted to a
category after the vet found it in ~8% of scored messages with no category
home. State what the thing is; drop the "not X" preamble. Detection:
mechanical for the two validated high-precision forms ("not X, but Y" and
"— it's"); the bare "not X —" form was tested and rejected (fires on plain
negation).

## Merged and demoted (do not re-add as categories)

- **hedge** and **register** merged into thesaurus enforcement: the sweep found
  enforcement gaps of existing bans (filler adverbs, hedged assertions,
  jargon/marketing words), not new classes. The rows live in
  `style/thesaurus.jsonl`; prose-lint carries the aligned lexicons.
- **reference** (ambiguous actors, name-churn: calling one thing "the script",
  "the sim", "the tool") is real but rare and judgment-only; it is a
  review-time check in /skeptical-review's lane, not a linter category. The
  fleet's mechanical proxies for it were 97% noise; do not trust naked-this
  counts as evidence of it.

## The register this taxonomy protects

Dense, evidenced, code-referenced prose is the house style and is NOT a defect.
The line: each sentence parses in one pass, facts precede conclusions, the
reader never has to guess an antecedent, and no claim outruns its evidence.
Chat replies keep a voice (`rules/audience-aware-writing.md` stays the
router); strict controlled English (`/ste-writing`, strict mode) is for docs,
error messages, runbooks, and hook text only.

## Provenance and the method note

Built recall-first, precision-late: mechanical scoring over the corpus, a
recall-biased local-model flagging fleet ($0), per-category adversarial
confirm seats, an opus vet that overturned two categories and vetoed six
detection rules, and two user decision pages as the only truth-bearers. The
STE kit (asd-ste100.org, the "cure for AI slop" episode) contributed the
sentence-cap and active-voice core; its linter was derived from, not adopted
(its word list conflicted with house vocabulary, and it cannot see either of
the two worst categories here).
