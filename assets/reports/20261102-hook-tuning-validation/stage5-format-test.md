# Stage 5: format-gate-stop.test.sh update

File changed: /Users/alcatraz627/.claude/scripts/hooks/format-gate-stop.test.sh (only this file; not committed).

## Result

Final run: pass=98 fail=2. The 2 failures are the one thing I could not make pass, and they point at a hook gap (below).

## What changed

- filename-dot tests: all detections now assert `.systemMessage` contains "paths, clickable: <span>" and no `.decision`. Added checks that the warn log has `filename-dot soft` and never `filename-dot block`.
- relpath tests: all detections assert "full paths: <mention> -> <abs>" (or "its absolute path") in `.systemMessage`, no `.decision`; in-project, scratchpad and other-worktree cases kept. Added `relpath soft` logged, never `relpath block`.
- terse-reply: `long` is now 3500 chars (old 3150 no longer reaches the 3250 line). New cases: 2860 (10 percent over) is advisory with "terse-reply WARN"; 3380 (30 percent over) blocks; 3200 is still advisory. A long box, a long `/goal ` line, a `secret-scan` line and a `/core-dump` line do not block; two controls (same text on plain lines) do block.
- Merged block: now emdash + terse-reply + prose-smell (policy enforce stub). Asserts the reason lists all three, lists no path class, the tripped file has emdash and terse-reply and no path class, and per-class block rows plus a format-gate row are logged. The `run_pol` helper and policy stubs moved up so this test can use them.
- Path-with-block: asserts an em-dash reply with a partial path blocks with the em-dash fragment in `.reason` and no path class there, and that `.systemMessage` carries the path. Worst-case reply asserts the em-dash fragment survives the 500-char clip and the path is in systemMessage. Added "a path note never carries `.decision`" over three path forms.
- Heed test: its second class is now terse-reply (filename-dot no longer opens a block).
- Fixed an old typo: `run fgt00028'Run cat ...'` was missing a space, so the "command position is exempt" test never exercised the input. It passes with the fix.

## Could not make pass (hook gap, not fixed)

Two assertions fail: "path missing from the block output" and "the path to paste is missing from systemMessage".

Cause: /Users/alcatraz627/.claude/scripts/hooks/format-gate-stop.sh line 493 emits `{decision:"block", reason}` only. On a block, `$ADV` (which holds the "full paths" and "paths, clickable" notes) is never put in the output; only the no-block and step-aside paths emit systemMessage. So a path detected in the same reply as a block is dropped, and the owner never gets the path to paste. Fix would be to add `systemMessage:$ADV` to the block emit when `$ADV` is non-empty.

## Other hook observation (not asserted)

A single mention can produce a duplicate entry: for `docs/structure.md` the note reads "docs/structure.md -> its absolute path ; docs/structure.md -> its absolute path" (the REL_PAT pass and the turn-file pass both add it).

Merged reason with three classes is exactly 500 chars; prose-smell survives only just.

## Mutation proof (scratch copies under /private/tmp/claude-501/-Users-alcatraz627--claude/f0985c5b-e237-48e3-8496-c2fde05ccb7a/scratchpad/mut/hooks/, run via FORMAT_GATE_HOOK)

| Mutation | Result |
|---|---|
| old `$plen -ge $TLIMIT` | red: 10 percent over and 3200 cases (fail=4 incl. the 2 above) |
| old `add_block relpath` | red: 15 failures across relpath notes, log row, path-class-in-reason, no-decision loop |
| old `add_block filename-dot` | red: 12 failures across filename-dot notes, log row, merged-reason, tripped file |
| box/goal/secret-scan/core-dump exclusion removed | red: 4 exclusion cases (fail=6 incl. the 2 above) |

Real hook restored untouched; no git checkout, stash or clean used.
