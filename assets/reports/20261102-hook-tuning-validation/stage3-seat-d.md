# Stage 3, seat D: doc-voice-gate H16 and H17

Files changed (only these two): `/Users/alcatraz627/.claude/scripts/hooks/doc-voice-gate.py`, `/Users/alcatraz627/.claude/scripts/hooks/doc-voice-gate.test.sh`. Not committed.

## What changed

### H16 baseline from the session's pre-edit snapshot
- `snapshot_text()` and `baseline()` (before `worse()`): read `/tmp/claude-presnap-<sid8>/<sha1 of real path>`, the file `snapshot-pre-edit.sh` writes on the first PreToolUse edit (its key is `shasum` of the `pwd -P` path, same as `review-nudge-stop.sh` lines 16-18 read). `DOC_VOICE_SNAP` overrides the dir for tests.
- An empty snapshot means the file did not exist (that script writes an empty baseline for new files), so the baseline is None and the doc is judged whole.
- No snapshot for an existing file (resumed session, snapshotter not wired): fall back to the last committed version, which is the old behaviour. A file with neither is judged whole. Decision and reason: the commit is the best honest "before" left, and judging whole would block every touched old doc in exactly the case H16 describes.
- `post()` and `note_candidate()` now take the baseline through `baseline()` instead of `committed_text()`. The existing `worse()` compares per-measure counts (ledger marks, long cells, long paragraphs, dense, spliced, mechanism, codes, long sentences, flat, tail), so only a finding the baseline did not have, or more of one, holds the turn. The reply-calls-it-better path is untouched.
- Keep-warm population guard near the stop entry: not touched.

### H17 one note per change in the set of faults
- `KIND_MARKERS` and `fault_kinds()`: nine fault kinds read from the note text. Counts and examples are ignored.
- `new_kinds()` (sub-agent path) and the `noted` map in session state (main path): a note goes out only when the kinds differ from the last note for that file. The first note counts. State bookkeeping (docs, baseline) still happens when the note is skipped, so the Stop check is unaffected.
- `forget_noted()`: a doc that reads fine again is cleared, so a later failure is news again.

## Tests (test.sh, `HOOK_TEST=1` kept at line 2)
New cases at the end, 12 in all: touched-only old doc passes at Stop; no snapshot and no commit is judged whole; a doc with one new huge paragraph blocks and names `grown.md`; a new `reader: agent` ledger doc under docs/ blocks; a reply calling a failing doc "clearer" still blocks with the "tells the owner" text; five repeat-note cases (first note, same faults silent, small edit silent, new kind noted, silent again, fixed then failing again noted).
One existing case reused a session id for two identical calls and now correctly gets one note; its second call uses session `s1r`.
Result: all 77 cases pass (full run, not a collect).

## Mutations (scratch copies in the scratchpad `mut/` dir, run through `GATE_UNDER_TEST`)
| Mutation | Result |
|---|---|
| baseline ignores the snapshot | red: "a touched-only old doc passes at Stop" |
| note every edit (suppression off) | red: three repeat-note cases |
| `worse()` always true when failing | red: "a small edit to it does not hold the turn", "a touched-only old doc passes at Stop" |
| real file restored | green |
Not mutated: the empty-snapshot rule. Making it return the empty text instead of None changes nothing observable, because an empty baseline passes and a failing new doc is "worse" either way. Treat it as an equivalent mutant.

## Numbers
Replay of the 524 real PostToolUse notes, in time order, through the set-change rule (`fault_kinds`, run by the real module):

| Key | Files | Before | After |
|---|---|---|---|
| file name only (matches the audit's 117 files) | 117 | 4.48 notes per file | 185 notes, 1.58 per file |
| session + file name (the real state key) | 147 | 3.56 | 200 notes, 1.36 per file |

Target "under 1.5": met on the real key, 1.58 on the audit's key. The two differ only because a file name seen in several sessions is one file there and several here.

## UNCONFIRMED and limits
- Note text is cut at 1,500 characters (22 notes are within 50 of the cut), so a fault kind named late in a long note can be lost; 21 notes show no recognised kind at all and replay as one shared empty set. Both push "after" down a little.
- The replay has no "doc passed again" events, so it never applies `forget_noted`; real runs will note slightly more often than 1.36.
- The file is identified by the name at the start of the note, not its path, which the log does not keep.
- The snapshot path was exercised only through a hand-written snapshot in tests, not a live PreToolUse hook run; whether `snapshot-pre-edit.sh` is wired for every Write/Edit matcher was not checked.
