# Hook tuning: what shipped against the plan

This records each row of `/Users/alcatraz627/.claude/assets/reports/20261101-2046-hook-tuning-change/plan.md` as built on 2026-11-02. Replay numbers are this week's inputs through the new code. Live numbers need a new week: run `scripts/hooks/audit/scan.py` and `measure.py --compare scripts/hooks/audit/baselines/20261025-week.json`.

| Row | Result | Evidence |
|---|---|---|
| H0 | Scan, measure, baseline promoted to `scripts/hooks/audit/` | Baseline reproduces the report; 44 checks |
| H1 | Critic model off the stop path, on free checks. `~/.claude/.style-watch-model-on` restores it with `--safe-mode --tools ""` | Free checks catch 25% of its findings (401 of 1,573), so the plan's assumption was wrong. No finding was ever recorded as heeded. Owner's call |
| H2 | `hook_should_run`, 25 advice hooks | 49 checks, safety guards still deny under `sdk-cli` |
| H3 | Keep-warm turns skip advice through a marker | Same suite |
| H4 | One `automated-prompts.txt`, used by injectors, `usage5h`, `session-journal`, `ckutil` | `wake-breaker.sh` keeps its own list: it means something else |
| H5 | Tests cannot write the live ledger | 86 suites, 0 rows leaked |
| H6 | Session id from `CLAUDE_CODE_SESSION_ID`. The old code read a variable that was never set | Probed interactive and headless |
| H7 | 10 hooks log; a test fails a new hook that neither logs nor states why | `audit/no-ledger.txt` lists 33 exemptions |
| H8 | Headless rows left out of `hook-health`; block outcomes in `measure.py` | Outcomes are in `measure.py`, not `hook-health` as the row said |
| H9 | `hook-health` flags `RETIRE-DUE` from a hook's own rule | `review-nudge` flagged. `prose-smell` was a mapping error, fixed with `# ledger-id` |
| H10 | `measure.py` reconciles ledger against transcript | Flags 5 of 7 tracked hooks in the baseline |
| H11 | Whole-word guidance match | 65 of 379 on a real keyword became 65 of 65 |
| H12 | Explicit alias table | False loads 130 to 0 across 605 prompts |
| H13 | Secret scan reads added text for edits; once per fingerprint; allowlist | Replay 1,800 rows to 14. Replay is an estimate: the log keeps no added text |
| H14 | Bare names pass, no other session's worktree suggested | 63 to 0, 11 to 0 on replay |
| H15 | `rg -r` needs a real replacement form | 28 denials to 6, all `-rn` typos |
| H16 | Doc gate judges against the pre-edit snapshot | 77 checks |
| H17 | Notes only when the findings change | 4.5 to 1.36 notes per file per session |
| H18 | Tuned, not retired: the hook's header says the owner keeps it | 32 fires to 5 |
| H19 | Stop hooks read the Stop input's reply | 10 to 0, with 4 stated exceptions |
| H20 | Path findings go to the owner's screen, with no re-sent reply | 101 checks |
| H21 | `pr-review` runs the wait itself and blocks only on findings | Replay 101 to 23, 107 checks. No live GitHub run |
| H22 | Warn to 125% of the cap, exempt lines up to 800 chars | 101 checks |
| H23 | `claude-ipc` Stop honors `--no-reply-expected` | Live: wake-only request silent, control blocks |
| H24 | Off Stop; runs from `/validate` and on `gh pr create` | 17 checks. PostToolUse on-screen display not seen live |
| H25 | Boxes through `systemMessage` | 32 checks |
| H26 | `systemMessage` is visible | Screen checked in tmux from PreToolUse, UserPromptSubmit, Stop; not from SubagentStart or SubagentStop |
| H27 | `stop-arbiter.py` runs 18 gates, one message | 53 checks, live 13 of 13 |
| H28 | Gates read `background_tasks`, which Stop hooks receive | `goal-paste`, `queue`, `doc-voice` |
| H29 | Explanatory plugin off | New sessions only |
| H30 | `attribution` empty. Partial: the harness still asks for `Claude-Session`, and the guard still catches it | Seen live in this session's reminder |
| H31 | `goal-paste` exempts a reply asking the owner | Regex is the report's loose one |

## Not done, and why

- One commit per stage was not possible: the stages edit the same files, so they went in together.
- Validators attacked stage 0 with keep-warm, stages 1 and 2, and stages 3 to 5, rather than one per stage. Reports are beside this file.

## Known limits

- H15: `rg -n -- -r file` still blocks, though `-r` there is the pattern.
- H13: the once-per-session report is shared across tools, so a token first seen in a Read does not alert again from Bash.
- H25: each dispatch from the third on prints a fresh fleet box on screen.
