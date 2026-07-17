# 0036 — glossary vocabulary decay: hit ledger, pin tier, dormancy review

## Summary

The injected steering vocabulary gains a usage-measurement and decay loop
(task #24 of the vocab-sweep arc). Three coupled pieces: `hinters/01-glossary.sh`
now appends one line per MATCHED term to `style/glossary-hit-log.tsv`
(`ts<TAB>term<TAB>session`, append-only, failure never breaks hinting) — the
ledger deliberately records a superset of the ≤2 displayed hints, because
usage evidence gated by display slots would show cluster siblings and 3rd+
matches as dormant while in active use (gate 24 finding 2);
`style/glossary-hints.tsv` gains an optional 4th column `pin` (human-set only)
exempting a term from dormancy; `scripts/style/glossary-decay.sh` reports
active/dormant/pinned splits over a trailing window (28d default) and is wired
into `thesaurus.sh review`. Reports only — retirement stays a human decision,
and verdicts are withheld until the ledger covers a full window.

## Why

Vocabulary is not grow-only: without usage evidence, GLOSSARY §User Shorthand
and the hinter table accrete terms whose meanings the user stopped using, and
the hinter's 2-per-prompt budget gets spent on dead words. The sweep that baked
the 2026-07-17 rows gathered recency evidence from the corpus once; this loop
makes recency a continuously-collected signal instead of a one-off mining job.

## Schema change

`glossary-hints.tsv`: `term<TAB>meaning<TAB>pointer` → `term<TAB>meaning<TAB>pointer[<TAB>pin]`.
Backward-compatible: the hinter's awk reads columns 1–2 only; absent col 4 = auto
(decayable). New ledger file `style/glossary-hit-log.tsv` (data, not git-tracked
by the allowlist; travels by rsync like the other ledgers).

## Known limitations (accepted at migration time)

Hinter runs without `CLAUDE_CODE_SESSION_ID` log an empty session field, so
the distinct-session count merges them into one bucket. The ledger append has
no lock (safe on local APFS, not on a network filesystem). Terms must not
contain commas (the hinter's internal join). Env overrides for testing:
`GLOSSARY_HINTS` + `GLOSSARY_HITLOG`, honored by both the hinter and the
decay script.

## Rollback

Revert the three files; delete `style/glossary-hit-log.tsv`. No other readers
of col 4 or the ledger exist as of this migration.
