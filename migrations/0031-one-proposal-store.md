# 0031 — one proposal store, one gate, one decision surface

Date: 2026-07-11 · Session: gcc-resi-b7
Design: `assets/reports/20260711-proposals-pipeline/design.md`

## What changed and why

The improvement backlog had three intake streams but **two stores**, and the gate
that decides what a human ever sees could only read one of them properly. Draining
the backlog surfaced four defects; all four are fixed here.

### D1 — i-dream had its own orphaned store

`scripts/dream/propose-config-from-insights.sh` wrote
`claudew/pending-config-proposals.jsonl`, and `scripts/pending-proposals.sh`
injected its pending rows into **every** SessionStart. Those rows never entered
`proposals.jsonl`, never clustered, never corroborated, never appeared in
`/backlog-triage`. The only lifecycle the injected text offered was "hand-edit the
JSONL". In weeks it produced zero decisions — an advisory surface with no
conversion path.

- Dream insights now file onto `proposals.jsonl` via `propose.sh add`, tagged
  `link:dream:<id>` + `src:dream-consolidation` (`corroborated:human-upvote` when
  the human already thumbs-upped the insight).
- `pending-proposals.sh` is **retired** (inert `exit 0`, kept so a stale reference
  degrades to a no-op) and removed from `sessionstart-inject.sh`.
- The old JSONL is archived read-only as
  `claudew/pending-config-proposals.ARCHIVED-2026-07-11.jsonl`.
- Dream proposals now surface through `backlog-surface.sh` with everything else.
- Fixed while here: the script's insight-id regex expected `_Patterns: <uuid>` but
  `insights.md` emits `_Pattern_: "<text>"`, so the id was silently always empty.
  Identity is now the rule-text hash (stable across runs and format drift).

### D2 — the atone → backlog graduation path was silently dead

`scripts/atone-consolidate/build-proposals.sh` filed with a bare
`atone-prevention <target> <slug>` tag, but `backlog-consolidate.py` builds its
corroboration graph from `link:*` tags **only**. So every atone-graduated proposal
was born uncorroborated, could never cluster with the `gcc-signal-capture`
auto-stub naming the *same slug*, and aged out into DROP-REVIEW as "stale".

- `build-proposals.sh` now files `link:atone:<slug> src:atone-graduation
  target:<target>`.
- Migration `scripts/migrate/0030-atone-link-tags.sh` rewrote **69** existing
  proposals to the protocol shape (backup written; line count asserted unchanged).
- It also **re-opened 4 proposals** that had been rejected earlier the same day for
  a corroboration they were structurally incapable of earning. Rejections made on
  the merits (genuinely superseded) stayed closed.
- Effect: 4 atone proposals immediately became PROMOTE candidates via S3/recurrence
  enrichment that had never been reaching them.

### D3 — clustering was content-blind, so rediscovery scored as noise

Corroboration came only from `link:*` tags a filer had to remember. Two sessions
independently hitting the same friction filed two untagged items that clustered
separately and each stayed at corroboration 1 — so **independent rediscovery, the
strongest signal available, generated zero corroboration**, inverting the gate's own
premise. (Live case: the task-sync nudge bug, filed twice a day apart, never
merged.)

`backlog-consolidate.py` now also draws **content edges**, scoped to items with no
`link:*` edge (content matching is the fallback for what the link graph cannot see;
auto-filed proposals already carry a precise identity and must not be fuzzy-matched).

Two failures shipped and were caught during the build — both are now pinned by
`scripts/tests/test-content-edges.sh`:

- **over-merge**: templated `[atone]` bodies scored 0.81 against each other and
  would have fused every atone slug into one cluster;
- **no-op**: a "rare = appears in ≤1 proposal" cutoff made an edge mathematically
  impossible, so the feature silently did nothing.

Thresholds are measured, not chosen: on this backlog (n=59) the real duplicate pair
scores 0.116 while the two false merges score 0.022 and 0.021. `PHRASE_SUPPORT_MIN
= 0.06` sits clear of both. **Re-measure before moving any threshold**, and re-run
the regression test.

New flags: `--explain` (print every content edge and why) and `--no-content`
(link-only clustering).

### D4 — the machine sidecar silently truncated

`.backlog-triage-latest.json` capped `promote` at 5 rows while the human report
listed all 16, and `/backlog-triage` reads the sidecar. It now carries every
PROMOTE row plus `truncated` / `dropped` fields, and per-row `corroboration` and
`streams`.

## The split of concerns (the invariant to keep)

| Concern | Owner |
|---|---|
| Notice friction | any session, hook, dream, or atone |
| Record it | `propose.sh add` — the ONLY writer |
| Carry provenance | the filer, via `link:*` tags |
| Rank + gate | `backlog-consolidate.py` — read-only, never mutates |
| Decide | the human, at `/backlog-triage` |
| Change state | `propose.sh done` / `propose.sh reject` — the ONLY mutators |

**The consolidator never mutates; the skill never ranks; nothing but `propose.sh`
writes the store.**

## Verification

- `scripts/tests/test-content-edges.sh` — 6/6 pass (TP merges at corroboration 2;
  common-word and templated pairs stay separate; exactly 1 edge; `--no-content`
  disables).
- Migration 0030 dry-run on a copy, then applied: 69 re-tagged, 4 re-opened, 208
  lines intact, zero `atone-prevention` tags remaining.
- Dream bridge exercised against a temp store: files 5, is idempotent on re-run,
  and dedups by rule-hash even after the prior batch is closed.
- SessionStart injector run end-to-end: exits 0, no dream-proposal block, backlog
  surfaces normally.

## Rollback

- Store: `assets/backups/proposals-pre-0030-*.jsonl` (restore over `proposals.jsonl`).
- Re-inject dream proposals: restore `scripts/pending-proposals.sh` from git and
  re-add it to the `INJECTORS` array in `sessionstart-inject.sh`.
- Disable content clustering without a revert: `--no-content`.
