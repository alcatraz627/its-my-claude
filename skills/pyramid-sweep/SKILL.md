---
name: pyramid-sweep
description: Runs a pyramid-of-intelligence corpus sweep — mine a large transcript corpus for candidate items with cheap mechanical passes, then refine through progressively smarter (and costlier) model tiers, each phase gate-verified, ending in a human decision surface. Proven on the 2026-07 vocabulary sweep (236 transcripts → 7 baked glossary rows). Use when a question needs breadth over a big corpus first and judgment only on survivors — vocabulary mining, preference harvesting, pattern extraction. For a single-file or known-location question, just search.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, Agent, Workflow
user-invokable: true
argument-hint: "[what to mine, e.g. 'steering vocabulary from the last 60 days']"
---

## Brief

A sweep architecture for questions of the shape "somewhere in this large corpus
are the ~10 items worth human attention." Aggressive recall early with $0
mechanical passes, strict precision late with adversarial vetting; each tier is
allowed to be wrong in exactly one direction, and a gate proves it before the
next tier spends. The instance that proved it: `style/sweep/20260716-gcc-drift-3e/`
(vocab sweep: 236 transcripts → 2,124 pure messages → 500 candidates → 16 keeps
→ 11 proposals → 7 baked rows, ~7.8M tokens all-in, every phase gated).

## The phase ladder

| Phase | What | Lane | Tooling (all in `scripts/style/`) |
|---|---|---|---|
| P0 inventory | manifest the corpus (path, mtime, size, lines per transcript) | inline $0 | inline `fd`/`jq` → `manifest/transcripts.jsonl` |
| P1 extract | pure human text only — strip tool results, hook injections, command scaffolding | inline $0 | `sweep-extract.py <run-dir>` |
| P2 score+cut | lexical metric over all terms, calibration gate, cut to top N | `.venv-sweep` $0 | `.venv-sweep/bin/python sweep-metric.py <run-dir> [--top 300]` |
| P3 classify | per-occurrence semantic labels, control rows planted per shard | sonnet fleet | `sweep-shard.py <run-dir> [--per-shard 180] [--max-occ 30]` → agents |
| P4 gauge | mechanical bucketing + judgment only on real signal | inline + sonnet | `sweep-gauge-prep.py <run-dir>` → agents |
| P5 synthesize | FULL-occurrence read per survivor → complete proposals + recency | sonnet-high | `.venv-sweep/bin/python sweep-synth-prep.py <run-dir>` → agents |
| P6 vet | one adversarial cross-item pass: merge/reject/injection-safety | opus | agent over `synthesis/` → `vetted/` |
| P7 decide+bake | numbered approve/edit/reject surface, human picks, bake, commit | main agent | decision surface in chat; bake per targets below |

Run dir: `~/.claude/style/sweep/<YYYYMMDD>-<session>/` with subdirs
`manifest/ corpus/ candidates/ contexts[-input]/ gauge[d,-input]/
synth-input/ synthesis/ vetted/` and `run-meta.json` (append an event per
phase transition, gate result, halt — it is the run's black box).

## The gates (non-skippable — the ladder is only as true as its gates)

- **P2 calibration:** the metric must re-find the already-known positives
  (baked vocabulary) inside the cut AND reject ultra-common negatives
  outright. Iterate the metric until this passes; the vocab run took 5
  iterations + 1 user re-spec. Items known to be lexically unreachable are
  NOT failures — plant them as P3/P4 tracers instead.
- **P3 controls:** every shard carries 3 planted rows with known labels; the
  answer key lives outside the shard. A shard that misgrades a control is
  redone. Vocab run: 60/60 after one proportional boundary re-audit.
- **P4 tracers + overlap:** planted known-answer terms (both keep-shaped and
  reject-shaped) must classify correctly; a second agent re-gauges a sample
  shard and the overlap is audited (vocab run: 5/5 tracers, 92% overlap).
- **P6 is adversarial:** its job is to merge, reject, and injection-gate the
  survivors — a vet that only blesses is not a vet.
- **P7 is human:** nothing bakes without the user's explicit pick. Show
  recency per item (first/last seen, occurrence count) — vocabulary is not
  grow-only.

## Fleet discipline (what made the run survivable)

- **Done-ledgers on disk.** Every fleet phase writes `<shard>.done.json`
  sentinels; a crash/outage re-runs ONLY the shards without sentinels. An API
  outage killed 1 of 19 P3 shards; recovery cost zero re-spend on survivors.
- **Canary-first.** Run ONE shard at the cheapest plausible lane and grade its
  controls before fan-out. Escalate the lane on failed canaries, never on
  anticipation — haiku failed 3 canary attempts before the lane escalated to
  sonnet; the spec sharpened at each failure.
- **Budget-halt.** A phase projecting >2× its estimate halts for a user
  verdict before spending (fired once at P3: 7-8M projected; user chose
  sampling-halve + effort-raise).
- **Embed prompts in the workflow script, not `args`.** Workflow args
  stringify objects — one agent received literal "undefined" and burned 84k
  tokens (`run-meta.json` event `p3-canary2-pass`).
- **Per-phase token telemetry** goes into `run-meta.json` events — it is what
  makes the next run's estimates honest.

## Bake targets (P7, for a vocabulary-shaped sweep)

Approved rows → `GLOSSARY.md` §User Shorthand · injection-safe terms →
`style/glossary-hints.tsv` (the `01-glossary` hinter reads it directly; respect
per-term injection class: safe / phrase-only / glossary-only) · style-verdict
terms → `scripts/style/thesaurus.sh add` · commit per `~/.claude/COMMIT.md`.
For a non-vocabulary sweep, name the equivalent targets in the plan before P0.

## Known traps

- `sweep-metric.py` and `sweep-synth-prep.py` need `scripts/style/.venv-sweep`
  (wordfreq lives there); the other scripts run on system python3.
- Frequency inflates on self-reference: a term the sweep itself uses (the vocab
  run's own word "sweep", 32 occ) must be weighted down at P6, and the
  deflation noted in the baked row so later decay passes read it honestly.
- P5 must read ALL occurrences, not the P3/P4 sample — the 15-sample view
  missed that `lean`'s dominant sense was ordinary English; the full read
  caught it and produced the run's only reject.
- Cheap sampling for volume tiers, full read for finalists — inverting this
  either starves the finalists of evidence or bankrupts the volume tier.

## Model plan template (mandatory before fan-out — rules/model-tier-routing.md)

```
Model plan:
  P0-P2  → inline + .venv-sweep · $0 mechanical
  P3     → sonnet(-high on canary evidence) · fleet, done-ledger, controls
  P4-P5  → sonnet / sonnet-high · shards + overlap audit
  P6     → opus · medium · adversarial vet seat
  P7     → main agent · decision surface + bake; hold for the user's pick
```

## See also

- `rules/model-tier-routing.md` — lane ladder + budget-halt doctrine
- `rules/contain-subagent-token-sprawl.md` — right-sizing the fleets
- `conventions/preference-graduation.md` — where baked vocabulary flows next
- The proven run's artifacts: `style/sweep/20260716-gcc-drift-3e/` (esp.
  `run-meta.json` and `vetted/clusters.md` — read both before a new run)
