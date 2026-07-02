# Stop-hook replay harness

The ship-gate for changes to any Stop hook in `~/.claude/scripts/hooks/`. Before a
hook change goes live, this harness answers two questions with real evidence:

1. **Corpus replay** (`replay-corpus.py`): how does the changed hook behave on
   every turn in the real transcript corpus under `~/.claude/projects`? Fire
   counts, BLOCK/SOFT/SILENT split, and a JSONL of fires for hand-classification.
2. **Fixture regression** (`run-fixtures.sh`): does the change alter behavior on
   turns whose correct outcome is already pinned? Non-zero exit on any FAIL.

The harness exercises the **real hook scripts** end to end. It never re-implements
hook logic in Python, so there is no port-drift: the numbers it reports are the
numbers the live hook would produce. (This replaced the throwaway
`scratchpad/replay*.py` scripts from the 20260630-s3-gate-leak analysis, which
replayed Python ports of the hook logic.)

## Files

| file | role |
|---|---|
| `replay_lib.py` | shared core: the turn model + faithful hook invocation. One definition of "a turn" for all tools here |
| `replay-corpus.py` | corpus driver: replay every transcript turn through a hook |
| `seed-fixtures.py` | builds `fixtures/declared-ready/` from pinned, hand-classified corpus fires |
| `run_fixtures.py` | fixture runner logic (python; shell stays thin on macOS bash 3.2) |
| `run-fixtures.sh` | the regression gate entrypoint |
| `fixtures/manifest.json` | fixture registry (schema below) |
| `fixtures/declared-ready/*.jsonl` | captured single-turn slices |

## Usage

```bash
# Full-corpus replay of a hook (about 2 min for ~940 transcripts / ~3.1k turns)
python3 replay-corpus.py --hook ~/.claude/scripts/hooks/declared-ready-stop.sh \
  --out /tmp/fires.jsonl

# Quicker iterations
python3 replay-corpus.py --hook <hook> --sample 100        # random 100 transcripts
python3 replay-corpus.py --hook <hook> --limit 50          # first 50
python3 replay-corpus.py --hook <hook> --only 781e356c     # filename substring, repeatable
python3 replay-corpus.py --hook <hook> --main-only         # skip subagents/workflows dirs

# Regression gate (run BEFORE shipping any Stop-hook change)
./run-fixtures.sh ~/.claude/scripts/hooks/declared-ready-stop.sh
./run-fixtures.sh <hook> declared-ready    # restrict to one fixtures subdir
echo $?                                    # non-zero = a pinned outcome changed

# Rebuild the fixture set (idempotent; only needed if the corpus rotates)
python3 seed-fixtures.py
```

`replay-corpus.py` flags: `--hook` (required), `--limit N`, `--sample N` (+
`--seed`), `--cwd` (fallback stakes cwd; each turn prefers the cwd recorded in the
transcript line itself), `--out`, `--keep-slices`, `--main-only`, `--only SUBSTR`,
`--force` (run despite a mute file), `--projects-dir`.

## The turn model

A turn starts at each **real user message**: `type=="user"` whose
`message.content` is a plain string, or an array containing a `text` item. A pure
`tool_result` array is a mid-turn tool return, not a boundary. The turn runs to
the next real user message. Preamble before the first user message is dropped.

For each turn the harness materializes:

- a **slice file** with the turn's raw JSONL lines (byte-faithful; the hook does
  its own `jq` parsing against it),
- the **session edit-list** `/tmp/claude-edited-files-<sid8>`, reconstructed from
  the turn's Edit/Write/MultiEdit `tool_use` file_paths (declared-ready's Gate0
  reads this; in production it is written by `track-edits-session.sh`),
- a **stdin payload** `{"session_id", "transcript_path", "cwd"}` where cwd is the
  turn's own recorded cwd (so `stakes-tier.sh` resolves the same tier the live
  hook would have seen).

Outcome classification from the hook's stdout: `{"decision":"block"}` = BLOCK,
`{"systemMessage":...}` = SOFT, anything else / empty = SILENT.

### Subagent/workflow transcripts are INCLUDED by default

The calibration reference numbers (empirical-declared-ready.md, ~28 fires) came
from a sweep of everything under `projects/`, including `*/subagents/` and
`*/workflows/` subdirectories. The harness matches that by default so its numbers
are comparable. Pass `--main-only` when you only care about main-session behavior.

## Fixture manifest schema

`fixtures/manifest.json` is `{"fixtures": [entry, ...]}` where each entry is:

```json
{
  "name": "tp-781e356c-t21",
  "hook": "declared-ready-stop.sh",
  "fixture": "fixtures/declared-ready/tp-781e356c-t21.jsonl",
  "expected": "block",
  "desired": "block-or-soft",
  "klass": "TP",
  "cwd": "/Users/alcatraz627/Code/Versable/enhancement-product/backend",
  "source_transcript": "781e356c-....jsonl",
  "turn_in_file": 21,
  "note": "ruff lint substituted for runtime exercise ..."
}
```

Two outcome fields, deliberately distinct:

- **`expected`** is what the CURRENT hook does. `run-fixtures.sh` asserts this;
  a mismatch is a FAIL. It pins today's behavior so any change is a conscious one.
- **`desired`** is what the v2 redesign should do (TPs `block-or-soft`, FPs
  `soft-or-silent`, controls `silent`). It is reported informationally, never
  asserted. When the redesign lands, flip each fixture's `expected` to its
  realized outcome and the same fixtures become the redesign's acceptance suite.

`klass` values: `TP` (justified fire), `FP` (noise fire, per the hand
classification in `assets/reports/20260630-s3-gate-leak/empirical-declared-ready.md`
§2), `CONTROL` (source edited + success claim, but a run was detected, so the hook
correctly stays silent; guards against a redesign that starts over-firing).

## Gotchas (both will silently corrupt a run)

**Mute files.** Each hook honors a `~/.claude/.no-<name>-gate` file and silently
exits 0 when it exists. A muted hook makes the replay report zero fires and LIE.
`replay-corpus.py` rg-scans the hook source for `\.no-[a-z-]*gate` tokens, tests
each, and refuses to run (exit 3) if one is present; `--force` overrides
knowingly. `run-fixtures.sh` warns the same way.

**Unique session ids.** The hooks keep loop-safety mark files in `/tmp` keyed by
`sid[0:8]` (`/tmp/claude-declared-ready-<sid8>`, `/tmp/claude-structural-claim-<sid8>`).
A reused sid makes the second fire for the same claim signature demote from BLOCK
to SOFT/silent, contaminating counts. The harness gives every turn a globally
unique synthetic sid whose first 8 chars are a zero-padded counter
(`00000000`, `00000001`, ...), then removes every mark/edit file it created.
Never re-run a turn with the same sid and expect a BLOCK twice.

Temp state lives under `/tmp/hook-replay-<pid>/` (driver) and
`/tmp/run-fixtures-<pid>/` (runner); both clean up after themselves unless
`--keep-slices` is passed. Cleanup is per-exact-sid, never a glob, so real
sessions' `/tmp/claude-edited-files-*` are untouched.

## Known approximations (all bias toward under-counting fires)

- **Per-turn edit-list.** Production's edit-list accumulates across the whole
  session; the harness rebuilds it from the turn's own edits. A success claim in
  a turn that edited nothing but referenced source edited earlier will not fire
  here. This matches the reference replay method, so calibration is comparable.
- **Per-turn slices.** Production's `tail -n 400` of a live transcript can let a
  prior turn's run bleed into a short turn's window (suppressing a fire). The
  harness gives the hook exactly one turn, the strict reading of "did anything
  run THIS turn".
- **Turn merging.** Reconstruction merges some boundaries (compaction, synthetic
  messages), so the turn count is a floor, not an exact census.

## The ship-gate workflow for a hook change

1. Baseline: `replay-corpus.py --hook <live-hook>` and keep the fires JSONL.
2. Make the change on a copy or branch of the hook script.
3. `./run-fixtures.sh <changed-hook>` must exit 0, or every FAIL must be an
   intended, explained behavior change (then re-pin `expected`).
4. `replay-corpus.py --hook <changed-hook>` over the full corpus; diff fire
   counts and the fires JSONL against the baseline. New fires get hand-classified
   before shipping; a fire-count jump of more than about 2x is a stop-and-debug.
5. Promote genuinely interesting new fires (TP or FP) into `fixtures/` with a
   manifest entry so the suite grows with the corpus.
