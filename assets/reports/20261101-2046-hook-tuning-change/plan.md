# Plan: make hooks measurable, scoped and cheap

This plan catalogues the 31 hook, nudge and inject defects found in the week of 2026-10-25 to 2026-11-01, each with its cause, a structural fix and how to measure it. It is for the owner to rule on, then for `/bloop` to build one stage at a time. Nothing is implemented yet. Evidence is in `/Users/alcatraz627/.claude/assets/reports/20261101-hook-audit/report.md`, and the Claude Code docs facts are in `claude-p-billing.md` beside it.

## Is `claude -p` the problem?

**Half right. The docs show no higher price per token, but this use of it costs about ten times what the judgment needs, and constant validation is the wrong shape for it.**

- **Price per token:** the docs describe no different rate for `-p`. They also do not say whether `-p` draws on the same subscription limits, so that part stays open.
- **Cost per run:** a critic run wrote a median 57,637 tokens to cache and read 41,916, to judge about 3,400 tokens of prompt. At an assumed $3 / $15 / $0.30 / $3.75 per million tokens, that is about $0.26 a run and $129 for the week. A call carrying only the prompt would be about $0.03 a run and $14 for the week.
- **Why so much:** `-p` loads hooks, skills, plugins, MCP and CLAUDE.md like an interactive session. The cache is also tied to the directory and git status, so runs across repos mostly miss each other's cache.
- **`--bare` is not the fix:** it does not read OAuth, so it will not run on your subscription login. `--safe-mode` drops the same context and keeps login, but I have not run it.
- **Wrong shape:** 409 of the 438 fires cite five ledger entries: em-dashes, contrastive "not X but Y", filler adverbs, and two kinds of over-long comment. Most of that can be checked by a script at no cost. Findings arrive as a note on a later prompt, and no finding has been recorded as heeded.

**Recommendation:** take the LLM off the stop path. Run the free checks at Stop, and keep model judgment for an explicit `/cleanup-comments` or PR-time pass.

## Why this is worth doing

Behaviour change. Costs are being paid repeatedly, and hooks contradict their own stated rules.

- Interactive sessions were blocked at 379 of 1,426 stops (27%) by 447 gate messages.
- The style critic cost about $129 a week at the assumed prices, with no recorded effect.
- `review-nudge-stop.sh:5` says retire below 30% heed over 40 fires, and it stands at 1 of 252.
- Tuning reads a ledger that is polluted by tests and has wrong session ids.

## How the catalogue is measured

Every "measure" below comes from one re-runnable scan, not from the ledger: `scan_transcripts.py` and its readers, promoted in H0. All baselines are for the week above, and the interactive population is 68 sessions unless stated. Run it on demand. No new scheduled job is proposed.

## Defect catalogue

### A. Hooks run in sessions they were not written for

| ID | Defect | Cause | Structural fix | How to measure (baseline to target) |
|---|---|---|---|---|
| H1 | Style critic runs with every hook attached and costs about $129 a week | `style-watch-worker.sh:67` calls plain `claude -p` from each Stop | Move the five common entries to `prose-lint.py` and `detect.py` at Stop. Model judgment only on explicit request. If a call stays, use `--safe-mode --tools ""` with a short system prompt | Critic sessions 503 to 0. Replay the critics' recorded quotes through the free checks and report recall |
| H2 | Other headless runs inherit advisory hooks too | No shared check. `dream-insights.sh:246`, `session-end-checkpoint.sh:39` and `atone-stop-gate.sh:61` each roll their own | `hook_should_run` in `hook-common.sh`: advisory hooks and injects exit when `CLAUDE_CODE_ENTRYPOINT` is `sdk-*`. Each hook declares its population | Advisory Stop blocks in headless sessions 157 to 0. Safety denials unchanged |
| H3 | Keep-warm one-word turns get blocked | Stop gates cannot tell a wake from a real turn | `hook_should_run` also skips turns started by `[keepwarm]`, using the marker `keepwarm.py` owns | Blocks on "warm" replies 17 to 0. Wakes still re-arm |
| H4 | Injects fire on automated prompts. Persona, guidance and local-models all fired on this plan's task notifications | The automated-prompt list exists in four copies (`usage5h.py:67`, `session-journal.py:65`, `ckutil.py:27`, `wake-breaker.sh:33`), and injectors use none | One `is_automated_prompt` in the shared library, used by every injector and those four readers | Keyword injects on `<task-notification>` or `[keepwarm]` prompts to 0. Add a baseline count in H0 |

### B. The measurements cannot be trusted

| ID | Defect | Cause | Structural fix | How to measure (baseline to target) |
|---|---|---|---|---|
| H5 | Test runs land in the live ledger | Only about 30 of about 80 hook tests set `WARN_LOG_STORE`. `replay-corpus.py` also fires hooks | `warn-log.sh` refuses the live path when `HOOK_TEST=1`. Test harnesses and replay set it, and a test fails if the live file grows during the suite | `guard-env-dump` ledger against transcript, 274 against 14, to within 10%. Run the suite and the live line count does not change |
| H6 | Session ids in the ledger are wrong | `warn-log.sh:112` falls back to the file `emit-event.sh:78` overwrites at every session start. Hooks do not reliably have `CLAUDE_SESSION_ID` | Hooks pass `--sid` from stdin. Remove the file fallback and write `nosid` when absent | `review-nudge` rows attributed to critics, 238 of 335, to 0. Share of rows with a known session to above 99% |
| H7 | Biggest gates never log. `pr-review`, `goal-paste`, `secret-scan`, `memory-reach`, guidance and `subagent-box` are absent | Logging is voluntary per hook | Add the hook-level logging call to each. Extend `settings-registration.test.sh` so a blocking or injecting hook with no logging call fails | Hooks that fire in transcripts but not the ledger, 6 or more, to 0 |
| H8 | Heed rates mislead | A re-emitted reply counts as heeded (`emdash` 118 of 119, mostly critics). `doc-voice` and `format-gate` rows stay `unknown` | Report heed only where a real later behaviour is checked, and show "unmeasured" otherwise. Split block outcomes into `fixed`, `dismissed`, `no action` | `hook-health.sh` shows the three outcomes. Heed rows from critics to 0 |
| H9 | Retirement rules do nothing | 13 hooks declare `lifecycle` or `retire-if` headers and no reader acts on them. `review-nudge` is past its limit | `hook-health.sh` parses the headers and prints what is past its limit, for the owner to act on | `review-nudge` appears as due. A new breach appears the week it happens |
| H10 | Nothing notices when ledger and truth drift apart | No reconciliation exists | The promoted scan prints ledger against transcript per hook and flags gaps over 25% | Report produced on demand, with a sample run in the PR |

### C. The matcher is wrong

| ID | Defect | Cause | Structural fix | How to measure (baseline to target) |
|---|---|---|---|---|
| H11 | Guidance notes fire on unrelated words, such as the port note on "report" | `guidance.sh:70` matches substrings and `:66` splits phrases into words | Whole-word match, with phrases kept whole. Move the check to a small tested function | Fires on a real keyword, 64 of 377 (17%), to above 90% |
| H12 | Memory-reach loads the wrong project on "better", "local", "landing" | `memory-reach.py:69` infers the first word of a project name | Explicit alias table, seeded with real ones such as `switchboard`, with no inferred first word | False loads 49 to 0. `switchboard` still loads |
| H13 | Secret scan raises about 1,500 false alarms, and agents now dismiss it | `secret-leak-scan.py:58` scans the whole Edit response, which includes the original file | For Edit and Write scan added text only. Report each fingerprint once per session. Keep an allowlist of fixture fingerprints | Rows 1,588 to under 20. Seeded fake token in Bash output still alerts |
| H14 | Path gate flags bare filenames and suggests wrong paths | `format-gate-stop.sh` `chk_relpath` covers bare names and resolves them into other sessions' `/private/tmp` worktrees | Require a slash, matching ruling D7. Never suggest a path outside the session's own project or scratchpad | Bare-name items 63 of 71 to 0. Wrong-worktree suggestions 11 to 0 |
| H15 | `rg -r` guard denies valid `-r '$1'` | The guard treats any `-r` as a mistake (3 of 5 sampled) | Block only `-rn`-style bundles and a `-r` whose next word is not a replacement | Replay this week's 29 denials. All `-rn` typos stay denied and all `-r '$1'` calls pass |
| H16 | Doc gate blames old text. A merge that only removed conflict markers failed `04-deploying.md` | `doc-voice-gate.py` judges the whole file | Compare against the session's pre-edit snapshot, as `review-nudge-stop.sh` does, and fail only on what got worse | Stop blocks on touched-only docs to 0, proved by a fixture. An agent-written ledger doc still blocks |
| H17 | Doc notes repeat on every edit, 518 notes over 117 files | PostToolUse re-reports the same findings | Note only when the set of findings changes | Notes per file 4.4 to under 1.5 |
| H18 | Persona suggestion rarely lands | Nearly everything reads as "planning" (28 of 32). 1 of 32 heeded | Retire it under its own rule, or restrict it to prompts with an explicit planning verb. Default: retire | Fires 32 to 0 if retired |
| H19 | Gates judge an older message, as with `bare-id` on "warm" | `bare-id-cluster-stop.sh:52` reads the transcript, whose tail lags one message (`goal-proposal-stop.sh:23`). Up to 7 other Stop hooks read the transcript without the reply field and need auditing | Move them to `hook_last_assistant_text` (`hook-common.sh:281`) and lint against direct reads | Fixture with a stale tail. Stop hooks lacking the helper, 8 to 0 or a stated reason |

### D. The remedy costs more than the fault

| ID | Defect | Cause | Structural fix | How to measure (baseline to target) |
|---|---|---|---|---|
| H20 | A misplaced period costs a whole re-sent reply. 153 of 178 format blocks produced a rewrite with no tool call | The gate's only channel is "block and re-emit" | Depends on H26. If systemMessage is visible, print the clickable path directly and stop blocking. If not, note it on the next prompt instead of blocking | Path blocks 116 to 0. Paths reach the owner clickable, checked on screen |
| H21 | `pr-review` hands the model mechanical chores: 78 of 101 are wait or retrigger | Blocking is the only action it has | The hook starts `wait` in the background and wakes the session. It blocks only on findings to disposition. It reads Clanky's paused state and reports it. Automatic retriggers need your approval | Blocks 101 to about 23. Every finding still gets dispositioned before done |
| H22 | Terse cap trips on small overages, and other hooks add text to the reply | Cap is flat at 2,600 chars and counts hook-mandated text | Subtract hook-mandated lines. Warn up to 25% over, block above | Blocks 46 items to under 15. Median reply length does not rise |
| H23 | Decision-page notices demand a reply from the model | `dp-server` sends a request, and `ipc-owed` treats it as owed (7 of 11) | Send as a notice, which the session reads but need not answer | `dp-server` ipc-owed blocks 7 to 0. Answered pages still wake the session |
| H24 | Review nudge goes unread at turn end | Wrong moment: fires at every stop with unreviewed files | Retire it from Stop. Raise the same check when `/validate` runs or a PR opens | Stop messages 322 to 0. Share of PRs with a review marker reported before and after |
| H25 | Subagent boxes go through the model. 531 injects, 577K chars, 216 retyped | `hook-common.sh:123` expects gcc-mods to strip `<owner>` tags, yet the tag reached this session, and I found no code handling it under `mods/` | Find out why the plugin does not act. Then either fix it or show the box through the channel H26 proves | Boxes in model context 531 to 0. Boxes still visible to you |
| H26 | Docs disagree on whether system messages reach you | `surface-hook-nudges-to-user.md:25` says invisible (checked 2026-06-01). `review-nudge` and `secret-scan` rely on them | One on-screen probe, then correct the loser and name the channel in the hook convention | The owner's answer, recorded in `conventions/hook-authoring-and-review.md` |
| H27 | Several gates block one stop: 59 of 379 blocked stops had 2 or more, up to 4 | Each gate decides alone, with no budget across them | Extend the merging `format-gate` already does (`format-gate-stop.sh:7`) into one Stop arbiter: one combined message, highest priority first, one retry | Stops with 2+ messages 59 to 0. Interactive block rate 27% to about 15% |
| H28 | Gates push on while background work is running (`queue`, `doc-voice`, `goal-paste`) | Only `pr-review` knows about live waits (`pr-review-gate.py:178`) | A shared "background work is live" check that these gates consult. Needs a probe first, because the harness signal is not yet identified | Blocks on replies that name live work, counted by the scan, reduced by half |

### E. Configuration fights itself

| ID | Defect | Cause | Structural fix | How to measure (baseline to target) |
|---|---|---|---|---|
| H29 | Explanatory and Concise styles both inject | `settings.json:1643` enables the plugin and `:1682` sets Concise | Disable the plugin | Explanatory inject in new sessions 265 to 0 |
| H30 | Commits get denied for trailers the harness asks for: 40 denials | The harness adds attribution and `guard-ai-signature` bans it. `settings.json` sets no `attribution` | Set `attribution` to empty, and keep the guard as a backstop. Untested | Denials 40 to 0 or close |
| H31 | `goal-paste` blocks replies that end on a real question | The exemption covers hand-offs only (`goal-proposal-stop.sh:35`) | Add an exemption for a reply ending on a question to the owner | The 6 such cases this week replay as no block. The other 28 still block |

## What the fixes share

Four small pieces replace most of the per-hook patches. Each exists because several rows above need it.

```
hook-common.sh
  hook_should_run <population>   H2 H3   who this hook is for
  is_automated_prompt            H4      human prompt or machine prompt
  hook_last_assistant_text       H19     exists; adopt it everywhere
warn-log.sh
  --sid from stdin, HOOK_TEST    H5 H6   one honest record per fire
stop arbiter (format-gate grown)
  merge gate messages            H27     one block per stop
channel rule (written down)      H20 H21 H24 H25 H26
  1. the hook does it itself
  2. it shows the owner directly
  3. it notes the model on the next prompt
  4. it blocks, only when a model turn is the only remedy
```

No registry or manifest is proposed. `hook_should_run` and the registration test cover the cases listed, and a larger framework has no caller yet.

## How the existing system already does this

| Decision | Current pattern | Evidence | Adopt or deviate |
|---|---|---|---|
| Shared hook helpers | `hook-common.sh` functions | `hook-common.sh:22-308` | Adopt |
| Headless detection | `CLAUDE_CODE_ENTRYPOINT` prefix | `session-end-checkpoint.sh:39` | Adopt, once |
| Merging gate messages | `format-gate` folds six old gates | `format-gate-stop.sh:7` | Adopt, widen |
| Pre-edit comparison | Session snapshot | `review-nudge-stop.sh:16-18` | Adopt for `doc-voice` |
| Test isolation | `WARN_LOG_STORE` | `warn-log.sh:52` | Keep, add a refusal |
| Replay against real inputs | `replay-corpus.py`, `run_fixtures.py` | `scripts/hooks/replay/` | Adopt for matcher changes |
| Retirement metadata | Header comments | `review-nudge-stop.sh:2-5` | Adopt, add a reader |
| Prompt classification | Four hand-kept lists | H4 row | Deviate: one shared function |

## What must keep working

| Must still hold | Why | Check that catches its loss |
|---|---|---|
| Safety guards run everywhere, including headless: `safe-delete`, git push, commit, secret read, env dump, credentials | `hook_should_run` must not reach them | Run each guard's test with `CLAUDE_CODE_ENTRYPOINT=sdk-cli`. All still deny |
| Secret scan runs in headless and catches real tokens in Bash and Read output, and in new Write content | Its whole purpose | Test seeds a fake token in each path. All alert |
| An em-dash in an interactive reply still blocks | Your ruling | `format-gate-stop.test.sh` |
| `pr-review` still blocks a PR with undispositioned findings | Its whole purpose | `pr-review-gate.test.sh`, plus a new case for the background wait |
| The doc gate still blocks an agent-written ledger doc, and never lets a reply call a failing doc better | The incident it came from | `doc-voice-gate.test.sh` with a new added-text fixture |
| Every mute file and snooze keeps working | Your escape valve | Each changed hook's test covers its mute |
| Existing ledger rows stay readable by `hook-health.sh`, `efficacy.sh`, `extract-events.sh` | Their readers | Run all three on the old file, with the same totals for old rows |
| Keep-warm wakes still re-arm | Skipping gates must not skip the re-arm | Wake fixture leaves a scheduled job |
| Answered decision pages still wake the waiting session | H23 changes the message kind | Decision-page walk, end to end |
| Atone juror's exception still holds | `atone-stop-gate.sh:61` | `atone-stop-gate.test.sh` |
| Style findings for the owner's ledger are not silently lost | H1 removes the model tier | H1's recall number goes to you before the switch |

## Smallest change that proves it

`hook_should_run` on one gate, `format-gate-stop.sh`. Feed the gate's test the same em-dash reply twice:

```bash
bash ~/.claude/scripts/hooks/format-gate-stop.test.sh
```

With `CLAUDE_CODE_ENTRYPOINT=cli` it must block, with `sdk-cli` it must stay silent, and the `safe-delete` test must still deny under `sdk-cli`. That proves the population check without touching any behaviour you rely on.

## Build order

Each stage is one `/bloop` run with its own commit, and the scan is re-run after it.

| Stage | Rows | Why here |
|---|---|---|
| 0. Instrument | H0: promote the scan to `scripts/hooks/audit/`, save baselines | Everything else is measured by it |
| 1. Honest numbers | H5 H6 H7 H8 H9 H10 | You asked for better tuning, and later stages need a true before and after |
| 2. Right population | H2 H3 H4, then H1 | Removes the largest noise at low risk |
| 3. Right matcher | H11 H12 H13 H14 H15 H16 H17 H18 H19 | Independent, each proved by replay |
| 4. Settings | H29 H30 | One-line changes through the settings guard |
| 5. Right channel | H26 first, then H20 H21 H22 H23 H24 H25 H27 H28 H31 | Riskiest, and they change what you see |

**Model plan**

- Stages 0 to 2 → main agent · opus · medium · shared library changes need care.
- Stage 3 → one seat per matcher · sonnet · high · independent and test-backed. Main agent verifies.
- Stage 4 → main agent · opus · low · trivial.
- Stage 5 → main agent · opus · high · changes owner-facing behaviour.

**Not touched:** safety guards' logic, the owner's policy layer, the harness's own reminders, and keep-warm's schedule.

## Decisions

**Defaults applied, silence means agreement:**

- Take the model off the stop path (H1), showing you recall first.
- Retire `persona-suggest` (H18) and move `review-nudge` to `/validate` (H24).
- Keep `reader: agent` under `docs/` as it is. Your earlier ruling stands, and H16 addresses the touched-file false positives.
- Automatic Clanky retriggers stay off until you approve them (H21).

**Needs you:** do `ℹ review-nudge:` lines appear in your terminal? This decides H20 and H25 and settles H26. It blocks only stage 5.

## Watch, not claims

- The 52 "show me examples" sessions from `sdk-py` have no explanation yet.
- Stop hook time sums to a median 8.4s per stop, and I did not measure wall time.
- The dollar figures use assumed list prices, because I found no Sonnet price table here, and they only approximate subscription usage.

## Goal line for the build

```
/goal The transcript scan is promoted with saved baselines. The ledger uses real session ids and test runs leave it unchanged. Every blocking or injecting hook writes a ledger row. Replaying this week's inputs shows the listed matcher false positives gone.
```
