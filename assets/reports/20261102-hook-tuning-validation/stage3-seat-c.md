# Stage 3 seat C: H14 (path gate) and H19 (stale transcript tail)

Nothing committed. All suites below were green at the end; all mutations were on scratch copies in the session scratchpad (`.../scratchpad/mut/`).

## H14: /Users/alcatraz627/.claude/scripts/hooks/format-gate-stop.sh

Conflict with the plan row, decided in the plan's favour: the file's own header and step-2 comment tagged the relpath bare-name check "(D7)", and tests fgt00018 and fgt00023 pinned "a bare name of a written file blocks". The D7 ruling as stated in CLAUDE.md covers only the trailing-period gate ("a bare filename passes"). I followed the plan row and CLAUDE.md, rewrote the header (lines 22-27) and flipped those two tests. If the owner meant D7 to keep bare names of written files blocking, revert the `(?:...)+` back to `*` in step 2.

Changes:
- `chk_relpath` step 2 (about lines 248-296): a written or edited file is flagged only when the reply names it with a partial path, meaning a slash in the text (regex `(?:[A-Za-z0-9_.@-]+/)+<basename>`, absolute and `~/` forms never match). Bare `notes.md` passes. `./x.md` still counts (it has a slash).
- Suggestion scope: the full path is offered only when the edited file is under the input's `cwd` or under `*/<session_id>/scratchpad/*`. Otherwise the item reads "<mention> -> its absolute path".
- Items with a suggested path are listed first (display step, about line 304), so the 500-char clip cannot drop the path to paste.
- The five items with no suggestion: all were step-1 items (a `docs/` or `assets/` path that does not exist under cwd). Decision: they still block, with "its absolute path". The path has a slash and no absolute form in the reply, which the brief says must keep blocking, and the agent can name it. No change to step 1.

Replay (84 recorded relpath blocks in stop_blocks.jsonl, synthetic transcript rebuilt from each block's own items, old = HEAD hook, new = working hook):

| measure | recorded | old hook replayed | new hook replayed |
|---|---|---|---|
| items shown | 108 | 101 | 52 |
| bare-name items | 63 | 57 | 0 |
| suggestions into /private/tmp | 11 | 9 | 0 |
| items with no suggestion | 5 | 4 | 8 |
| rows still blocked | 84 | 78 | 41 |

The recorded numbers match the plan (63 bare, 11 wrong-worktree). Old replay is lower only because a 90-char-truncated path in the log cannot be fully rebuilt. The no-suggestion count rises 4 to 8 because former wrong-worktree suggestions are now honest "its absolute path" items. They are slash paths, so they still block.

Tests, /Users/alcatraz627/.claude/scripts/hooks/format-gate-stop.test.sh: 78 pass, 0 fail. Added: partial path blocks with no suggestion outside project; bare name passes (plain and backticked); in-project file suggested; scratchpad file suggested; other session's worktree never suggested; em-dash and slash-path-period rows unchanged and green.

Mutations (each alone, scratch copy, test went red on the intended rows, 1 to 3 FAIL rows each):
- slash requirement `+` to `*`: 2 rows red (bare filename passes, backticked bare name passes).
- suggestion scope widened to any path: 3 rows red (outside project, no-suggestion wording, other worktree leaked).
- suggested-first ordering removed: 1 row red (the path to paste survives the 500-char clip).

## H19: Stop hooks that judged the transcript tail

Lint result: registered Stop hooks that read `transcript_path` with no helper and no `last_assistant_message`: 10 before, 0 now (6 moved to the input's reply, 4 named with a reason). The brief said 8; the lint found 10 because it also counts speculative-atone and the three exempt readers.

| hook | judges the reply? | action |
|---|---|---|
| bare-id-cluster-stop.sh | yes | helper (line 52); python gets text via env |
| hand-rendered-tasks-stop.sh | yes for the prose; the "tool consulted this turn" scan still needs the file | helper (line 85) for prose only |
| named-next-work-stop.sh | yes | helper (line 34); sources hook-common beside itself when HOME has none (test homes) |
| credential-ask-stop.sh | yes for text; commands since the last prompt still come from the transcript | helper (line 33), same fallback source |
| owner-ask-content-stop.py | yes | `last_assistant_message` first, transcript fallback (line 188) |
| creation-box-stop.py | yes for the reply; tool pairs still from the transcript | `last_assistant_message` first (line 154) |
| speculative-atone-stop.sh | no, reads the owner's last prompt time via owner-quiet.py | exempt, reason listed |
| auto-continue-stop.sh | no, scans last 6 KB for API error strings | exempt |
| sync-todos/stop-sync.sh | no, rebuilds the task list from tool calls | exempt |
| keepwarm/keepwarm.py | no, token usage, turn times, job-creation calls | exempt |

The `hook_should_run` guards near the top are untouched.

New lint: /Users/alcatraz627/.claude/scripts/hooks/audit/stop_transcript_readers.py with reasons in /Users/alcatraz627/.claude/scripts/hooks/audit/stop-transcript-exempt.txt. It is called from /Users/alcatraz627/.claude/scripts/hooks/settings-registration.test.sh (17 pass, 0 fail), which also has fixtures: a tail-reading Stop hook is flagged, a helper user passes, a non-reader passes.

Stale-tail fixtures added to all six tests (transcript's newest row is an older message, `last_assistant_message` holds the real one; two rows each, offending real reply fires, offending old row stays quiet): bare-id 21 pass, hand-rendered-tasks 7, named-next-work 12, credential-ask 8, owner-ask-content 24, creation-box 11, all 0 fail.

Mutations (call changed to ignore the input's reply, scratch copy): every one went red on exactly its two stale-tail rows and nothing else: bare-id, hand-rendered-tasks, named-next-work, credential-ask, owner-ask-content, creation-box. The lint's own failure case is the "flags a Stop hook that tails the transcript" fixture in settings-registration.test.sh.

## UNCONFIRMED
- Replay is synthetic: each block's transcript was rebuilt from its logged items, so it approximates the real turns. The old-hook replay reproduces 57 of the 63 recorded bare items.
- The lint covers hooks registered directly in settings.json on Stop. Tasks run by `hook-orchestrator/Stop.tasks` (for example atone-stop-check.sh) are not covered.
- Hooks that read the transcript for the reply after hook-common's `hook_should_run` exits (python hooks via `hookpop`) were not changed beyond the reply read.
