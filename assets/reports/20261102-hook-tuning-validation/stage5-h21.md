> Correction: this report's "one ipc Stop block per wake" no longer holds. claude-ipc's Stop hook now honors `--no-reply-expected`, so a wake adds no block. See stage3-5.md finding 13.

# H21: pr-review waits by itself and blocks only on findings

Built and uncommitted. Replaying the baseline through the real hook gives 23 blocks out of 101, and all 23 are findings. The suite passes 107 of 107. All 35 mutants went red and the no-change control stayed green. The live GitHub path is UNCONFIRMED, as expected.

## Decisions for the parent to check

**1. The wake uses `--kind request`, not the command in the brief.** The brief's command sends an inform, and an inform does not wake an idle session. `watch-inbox.sh:14-15` in `/Users/alcatraz627/Code/Claude/claude-ipc/plugin/scripts/` says only query, request and response mail wakes. I measured this with the real watcher on a private broker: an inform printed 0 wake lines, and the gate's request printed one.

The cost is one ipc Stop block per wake. `src/hooks/stop.ts:68-75` blocks once on any unanswered request and ignores `--no-reply-expected`. A short `--ttl` does not clear it: the message was still pending after its 8 s ttl ran out. So each wake can add one "reply to this" turn outside this gate's count. The message body says no reply is needed, but the block still fires. Removing that chore needs a wake-only mail kind in claude-ipc, which is outside these two files.

**2. Two more parts of the brief's wake command would have failed silently.**
- `--to <session id>` fails with `no_peer`, because the broker knows only aliases. The hook now looks up the alias with `peers --by-session` when the wait ends, and prefers a session's successor if it was cleared meanwhile.
- `--from pr-review` fails with `not_registered` in strict mode, so the hook runs `register pr-review --service` first, as the decision-page server does. The first real wake therefore adds a permanent `pr-review` service row to the live roster. It is not there yet.

**3. Merge conflicts no longer block.** The brief says Stop blocks only on findings, and the 23 target leaves no room for conflict rows, so a conflict is now a once-per-head note to the owner. The cost is that the model is no longer told to rebase. A conflict also used to hide findings, so findings are now checked first. If you want the rebase instruction back as a block, it is one branch at `pr-review-gate.py:430`.

**4. A headless run is still blocked on waiting.** This is a narrow exception to "only findings". A headless run exits when Stop lets it, and nothing can wake it, so without the block its findings would never be answered. That is what the comment at the `should_run("no-wake")` line promises. It is capped at 2 blocks and never asks for a retrigger. All 101 baseline rows came from the `cli` entrypoint, so this does not change the count.

## What changed

All lines are in `/Users/alcatraz627/.claude/scripts/hooks/pr-review-gate.py`.

| Where | Change |
|---|---|
| `:170` `fetch`, `:195` `out_of_usage` | Reads Clanky's state from the PR comments it already fetches, so no extra GitHub call |
| `:236` `auto_wait_state`, `:255` `watched_for`, `:264` `ensure_auto_wait` | One detached wait per PR, head and session. It holds none of the hook's streams and runs in its own session (`:284`) |
| `:366` `cmd_stop`, `:404` `note_once` | A Stop can now emit both a block and a note. Notes fire once per head, except "waiting for Clanky", which fires each time a wait starts |
| `:411` `check_pr` | Findings first and the only block for a normal session. Conflict, usage, paused and no-review are notes |
| `:470` `ipc`, `:479` `ipc_address`, `:492` `wake_body`, `:506` `wake_session` | One message per outcome. Failures are logged to `autowait.log` in the gate's state folder and never raise. Sends nothing under a mute, on a closed PR, or on a timeout while out of usage |
| `:545` `cmd_wait`, `:569` `poll_for_review` | `wait` gains `--wake` and `--marker`. A plain `wait` behaves as before |

`/Users/alcatraz627/.claude/scripts/hooks/pr-review-gate.test.sh` goes from 34 to 107 checks, using a stub gh and a stub claude-ipc. I rewrote the old expectations that a wait, a retrigger or a conflict blocks.

**How a stale marker is handled:**
- Findings are checked before any marker is read, so no marker can hide them.
- A wait that dies is restarted once, then left alone.
- A marker past its deadline counts as dead, even if its pid is alive, since the pid may have been reused.
- A wait that ran its limit is not restarted at that head. A new head gets a new wait.

**A wait from another session does not count for this one.** That wait wakes only its own session. My first version counted it, and the suite caught it.

## Clanky paused or out of usage: readable, with limits

| State | How it is read | What the gate does |
|---|---|---|
| Out of usage, no earlier findings | `<!-- pr-claude:review:outcome=review.not_run.out_of_usage -->` and "Claude's usage resets X" in the sticky comment (`ci-kit/review-post.cjs:281`) | Note with the reset time, no retrigger instruction |
| Out of usage, earlier findings kept | "Review stood down on `sha`: Claude usage exhausted" status reply, matched to the head (`ci-kit/review-gate.cjs:96`) | Same note |
| Automatic reviews paused on the PR | The "Automatic reviews are paused on this PR" line (`pr-board/throttle.py:333`) | Note naming the local trigger, which needs the owner's approval |

I checked the outcome marker and the reset wording read-only on walmart-mvp#127. The stand-down and paused wordings come from source only.

**Limits:**
- GitHub comments as fetched carry no edit time, so an old out-of-usage comment can outlive the reset. The note can be stale and would then leave out the retrigger hint. The wait still runs regardless.
- The sticky comment's outcome marker is not tied to a head. On merged walmart-mvp#127 it is still there.
- The paused line reaches GitHub only when the PR has no Slack thread. The usage-held line goes to Slack only, so neither is readable when it was posted only to Slack.
- Firestore `usage/claude` holds the live reading, but reading it needs gcloud, which is too slow for a Stop hook. I did not use it.

## Replay

Every one of the 101 "PR review gate" rows in `stop_blocks.jsonl` went through the real hook, with a stub gh rebuilt from the row's text. No row disagreed with the expected branch, and no block mentions a retrigger.

| Row held | Rows | Now |
|---|---|---|
| findings | 17 | blocks |
| findings + retrigger | 3 | blocks |
| findings + wait | 3 | blocks |
| wait | 30 | background wait, no block |
| retrigger | 39 | note, no block |
| retrigger + wait | 7 | no block |
| conflict | 2 | note, no block |
| **Total** | **101** | **23 blocked, 78 not** |

The real number could reach 25: the 2 conflict rows never showed whether those PRs also had open findings, and those would now block.

The replay counts this gate's blocks only. Each wake also adds the ipc block described in decision 1, and that block is not in the table.

## Mutation results

Each guard was broken on a scratch copy (`GATE_UNDER_TEST`), never on the real file: 35 mutants plus a no-change control. The control stayed green and all 35 went red.

- **First run thrown out.** The first full run showed every mutant red, and so did the control. The copy was missing `automated-prompts.txt`, so it died on import. I fixed the harness and ran everything again.
- **Unpinned guard found and fixed.** While a wait runs, two layers each stop a second start, so disabling either one alone left "starts no second wait" green. I added a test for a wait still starting up, which pins the marker's live arm. A mutant with both layers off turns "starts no second wait" red.

| Requirement | Mutant | Red test |
|---|---|---|
| Wait started once, not twice | marker's live arm ignored; both layers off | a wait still starting up is not started twice; and starts no second wait |
| No block while waiting | waiting blocks again | and does not block |
| Findings block | findings no longer block; a marker hides findings; conflict hides findings | undispositioned findings block; findings on a conflicted PR still block |
| One ipc message | wake not limited to one | a second wait reaching the same review sends nothing more |
| The wake really wakes | sent as inform; sender not registered; raw session id | it asks...; the sender was registered first...; the wait's end sends one message |
| ipc failure does not raise | ipc failure raises; refused send not logged | a missing claude-ipc does not raise; and is logged |
| Mute | ignored at Stop; ignored at the wake | a mute file is silent; a wait that ends under a mute sends nothing |
| Dead wait | counts as live; restarts forever; deadline ignored | a wait that died is started again; not restarted forever; a marker past its deadline... |
| Hook returns at once | wait inherits stdout and stderr; stays in the hook's process group | Stop returns at once...; the wait leads its own process group |
| No retrigger | retrigger blocks again; timeout message instructs a retrigger | stale push names the local trigger...; and leaves the retrigger to the owner |

The other mutants were also red: usage state unread, stand-down on any head, reset time dropped, paused state unread, timeout on a spent account wakes, closed PR wakes, headless treated like a session, keep-warm not excused, note repeats, ended wait restarted, successor ignored, another session's wait counts, own live wait not recognised.

The suite also asserts that every gh call in the run was a `pr view`, so nothing posted to GitHub.

## End-to-end run

I ran the real hook, the real claude-ipc CLI and the real `watch-inbox.sh` on a private broker (`CLAUDE_IPC_HOME` under `/tmp`, because a unix socket path under the scratchpad is too long), with only gh stubbed. The folders have since been trashed. The sequence was:

1. A push is tracked.
2. Stop prints the "waiting for Clanky" note and returns.
3. The stubbed review lands.
4. The watcher prints one wake line naming the PR and the finding count.
5. The next Stop blocks on the finding.

The watcher shows only the first 120 characters of the body, so the wake line cuts off partway through the summary command. The PR and the count fit, and the next Stop's block lists the findings in full.

The live gate state has no `autowaits` folder, no wait is left running, and the live broker has no `pr-review` token.

## UNCONFIRMED

- **A live GitHub run.** Not possible here. Real Clanky comments were only read, on one PR.
- **That a watcher line starts a turn in a real session.** I saw the line printed. Turning it into a turn is the harness's job, and I did not exercise that.
- **That the Stop hook's `PATH` includes `claude-ipc`** (`~/.local/bin`). If it does not, the wake logs "did not run" and the next Stop still blocks on findings.
- **The stand-down and paused wordings on real comments.** Both are read from source, as noted above.

## Known limits

- The background wait uses the existing 6-minute limit. Baseline rows show reviews arriving later than that (one row reads 60 min). When that happens the session gets one "no review" wake, and the later review is picked up only at the next Stop, so an idle session is not woken for it. Nothing is lost, but the owner may see the findings later. Passing a longer limit is a one-line change at `AUTO_WAIT_S`, at the cost of more polling.
- `autowaits` markers and `autowait.log` in the state folder are never cleaned up. They grow by small amounts per head, like the `sessions` folder beside them.

## Hook nudge

```
┌─ env-access nudge (PreToolUse:Edit) ─────────────────────────────────┐
│ New env reads in pr-review-gate.py: route through the convention in  │
│ /Users/alcatraz627/.claude/conventions/env-access.md                 │
└──────────────────────────────────────────────────────────────────────┘
```

I read the convention and no change is needed. It asks for a direct read with its default in a block near the top of the file, under the tool's prefix, and the new `PR_REVIEW_GATE_*` reads do that.

The diff also carries another session's uncommitted work in these two files (the `hookpop` import, `warn_log`, `HOOK_TEST`). I kept it.
