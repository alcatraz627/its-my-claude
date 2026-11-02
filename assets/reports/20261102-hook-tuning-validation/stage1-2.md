# Stage 1 and 2 adversarial validation (hook tuning)

Verdict: PASS-WITH-NOTES. No safety guard was touched and no stdin was lost. Two real defects (S2) and several smaller ones.
Scratch work: /private/tmp/claude-501/s12/ (scripts cmp.sh, run1.sh, wl.sh, mut.sh, hhcmp.sh, worker.sh, lc.py). Live ledger never written by me (grep for my markers: 0).

The tree moved under me: hookpop.py gained `background_live` (stage 3 work from the other seat, not judged). usage5h.py also carries an unrelated `keepwarm_rearm` change (.keepwarm-oneshot), not judged.

## Ranked findings

### S2-1. run-hook-tests.py cannot see a leak from a test that sets its own session id (attack 7)
- Repro: /private/tmp/claude-501/s12/mut.sh built a scratch HOME with three fake suites. The suite that fired warn-log with no HOOK_TEST was caught. The suite that set `CLAUDE_SESSION_ID=mine` wrote a live-path row and was NOT reported (runner reported 3 ok, leaked rows only for the others).
- Cause: /Users/alcatraz627/.claude/scripts/hooks/audit/run-hook-tests.py:23-26 finds leaks only by RUN_ID in the row; warn-log now prefers CLAUDE_SESSION_ID (warn-log.sh:~119), so any override or `env -u` hides the row. Three existing tests do override it (atone-session-key, warn-log, prefer-tmp-py-over-inline), so those suites are blind to leaks.
- Fix idea: also compare total ledger line growth minus rows with a sid not equal to RUN_ID that carry a `cwd`/ts inside the run window, or run each suite with WARN_LOG_STORE pointed at a scratch file and fail if the live file's size changed.
- Also: a fake suite with HOOK_TEST=1 reported as leaked in my scratch only because scratch HOME differs from the "live" home warn-log computes; that is a harness artifact, not a bug.

### S2-2. retire_state calls persona-suggest RETIRE-DUE against its own header (attack 9)
- hook-health.sh:234-245 counts ALL-TIME heed lines (6/238 = 2.5%). persona-suggest.sh:6 says `retire-if: heed-rate < 5% over 200 fires (counted from 2026-10-19; owner keeps it, tune before retiring)`. The regex ignores the "counted from" qualifier and the owner-keeps note, so the flag fires on pre-10-19 data. Also the `fires_n` argument is unused: the "over N fires" threshold is tested against heed-line count (yes+no), not fires.
- review-nudge RETIRE-DUE is correct against its rule (1/528, rule 30% over 40).
- prose-smell is NOT a false flag: hook-health scans only scripts/hooks/*.sh, never retired/, and retired/prose-smell-stop.sh is skipped. Its output shows lifecycle empty.

### S3-3. Hook id mapping takes the first `--hook` in the file (attack 9)
- Repro: /private/tmp/claude-501/s12/lc.py. format-gate-stop.sh (emits format-gate, prose-smell, terse-reply) maps to `prose-smell`, so its `retire-if: <50% over 100` is measured on prose-smell only (452/854, so not due). format-reminder-ups.sh maps to `format-gate`, the id the stop gate itself also emits. A rule can attach to the wrong hook's rows. No wrong flag today, but one is possible.

### S3-4. Free-path style notes are mangled (attack 10)
- Repro: /private/tmp/claude-501/s12/worker.sh with a temp HOME and a doc full of tells. prose-lint `snippet` contains raw newlines, so the worker's `free-<tell>|<snippet>|line N` splits across lines. The note reads `top: free-em-dash|# Notes: act or dismiss...`: truncated to the first line of the snippet (a heading, not the offending text), and the line number is lost. `n` counts lines starting `free-`, so the lint-score-block pseudo finding ("score 24.17/100w (block line 8)") counts as a finding (reported "2 ledger finding(s)" for one em-dash).
- Fix idea: use `.text` or `.context` and `gsub("\n";" ")` in the jq at style-watch-worker.sh:~70.
- Good: a file that passes screen0 but yields no non-score findings (worker2.sh, " basically ") produces no note and logs judge-clean. jq handles the empty case. A clean file logs screen-clean.
- Model path: `claude --help` (the real binary at /Users/alcatraz627/.local/bin/claude, since `claude` here is a zrecover alias) lists `--safe-mode` and `--tools ""` ("Use \"\" to disable all tools"). UNCONFIRMED: that a stdin body plus a positional prompt parses with `--tools ""` as run (no model call made). `--tools <tools...>` is variadic; it is followed by `--model` so it should stop there.

### S3-5. Typed owner prompts that start with the new bare prefixes read as machine text (attack 5)
- automated-prompts.txt now holds `Wake check`, `Heartbeat`, `Caveat:`, `This session is being continued`, `[Request interrupted` without a closing delimiter. Python `lstrip().startswith` and the bash twin both match a typed "Heartbeat monitor: how should it work?". Effect: injectors skip that prompt; usage5h no longer lets it cancel a hibernation; ckutil/session-journal drop it from owner text. usage5h.test.py: all passed; checkpoint tests not run to completion (only usage5h run).
- Impact is low (a missed nudge) but the usage5h and journal effect is silent. Suggest requiring `Heartbeat:`-style or a bracket.

### S3-6. warn-log live-path refusal compares strings (attack 7)
- Repro: /private/tmp/claude-501/s12/wl.sh (scratch copy with the live home faked). `WARN_LOG_STORE=<live>/.claude/./hooks/warn-events.jsonl` and `<live>//.claude/...` both bypass the HOOK_TEST refusal and write rows (dot-path 1, double slash 2). Nobody does this today; canonicalise before comparing.
- `eval echo "~$(id -un)"` is fine in practice (user name comes from the account database; if `id` failed it becomes `~`, which expands to HOME).
- Inverse risk: if HOOK_TEST=1 were ever inherited by a real session, ledger rows drop silently AND hook_should_run returns "run" always (hook-common.sh:37), so population guards switch off. Nothing sets it globally (rg of settings.json, keepwarm, replay: only replay_lib.py:263 sets it for children). Only guard-ghostty.test.sh launches claude in tests.

### S4-7. Wake marker (attack 4)
- keepwarm.py clears the marker only at the next UserPromptSubmit (hook_prompt, line 589) before any not-owner check, so a task notification or owner prompt after a wake clears it. Stop hooks of the owner's next turn run after UPS, so they see it cleared. Good.
- Residual: UPS hooks run in parallel, so on an owner's first prompt after an interrupted wake an injector can read the marker before keepwarm clears it and skip once. Cosmetic. A marker file also lingers in /tmp after the last wake of a session (harmless).
- Skipped hooks' bookkeeping: I read the guard sites only; the guards sit before any state write in every file I opened (counter-gate, credential-ask, format-gate, queue-stop, ui-callouts, persona, plan-gate, hint-injector, dream-insights-prompt), so a skipped hook skips its heed arm too. That matches intent (no advice, no heed expected). Not traced for declared-ready, speculative-atone, style-watch (UNCONFIRMED beyond the guard line).

## Attacks that held

1. Bash 3.2 (attack 1): `/bin/bash` 3.2.57. `HOOK_STDIN=$(cat); exec 0< <(printf '%s' ...)` round-tripped a 1,048,576 byte payload intact, an empty stdin under `set -u`, and plan-gate-ups ran a 1.6MB payload to rc=0 with output size 0 both interactive and `sdk-cli` (/private/tmp/claude-501/s12/run1.sh). Whitespace trim `${p#"${p%%[![:space:]]*}"}` works on 3.2 (tab and spaces). Closed-fd stdin (`<&-`) hung in this tool harness before reaching the code, so UNCONFIRMED; the same `cat` is the first line of the old script too.
   - Realistic payload old vs new (cmp.sh, HEAD copies via `git show`): plan-gate-ups and format-reminder-ups identical (empty). persona-suggest and hint-injector identical JSON once the once-per-session /tmp dedup markers were cleared (first run differences were my markers, not the change).
   - Mutation: HEAD persona-suggest fires under `CLAUDE_CODE_ENTRYPOINT=sdk-cli` (320 bytes), the guarded one stays silent (0 bytes), so the guard does the work.
2. Placement (attack 2): guards land after the header comments and before `set -uo pipefail` in every shell hook I opened. hook-common.sh has no top-level `set`, `trap` or assignments (rg), so double sourcing (persona-suggest sources it again at line 30) is harmless.
3. Early exit before reading stdin (attack 3): UNCONFIRMED on the harness side (not exercisable without a live session). Not new: the old mute lines (`[ -f ... ] && exit 0`) already exit before `cat`.
4. Safety (attack 6): `hook_should_run` appears in no PreToolUse guard. The only `guard-*` files with it are guard-structural-claim.sh and guard-absence-claim.sh, both Stop-time advice gates ("GROUNDING GATE"), not safety. credential-ask-stop.sh (reply says "go mint a token") and ui-callouts-gate.sh are advisory Stop gates too. hook-population.test.sh passes 49/49, including six guards with no population check and four deny cases under sdk-cli, but covers only 6 guards by name; my rg over every guard and safe-delete file for ENTRYPOINT found none.
5. warn-log tests (attack 7): warn-log.test.sh 11/11. No suite outside retired/ lacks HOOK_TEST (rg --files-without-match).
6. Old ledger rows (attack 8): hook-health old HEAD script vs new, on a copy of the live 40,759-fire ledger: total 40759 = 40759 (default and `--headless`), no hook differs in fires or heed, new key only `retire_due`/lifecycle. efficacy.sh runs. heed joins: heed-writeback resolve takes the sid from stdin and writes with it; warn-log's sid now equals it, so the new join is more accurate. Old rows with wrong stale-file sids still join no better than before. I did not run extract-events.sh, gcc-vitals or dream-insights on the old file (UNCONFIRMED).

## Artifacts I could not remove
- /private/tmp/claude-501/s12/ (my scratch, inside the session scratchpad, including a 1.6MB big.json and a ledger copy). Leaving it for the harness.
- Pre-existing /tmp leftovers from other suites (claude-agentbox-*, claude-declared-ready-*, claude-ctxsig-* directories by the hundreds) are not mine; they suggest tests leave /tmp markers.
- The /tmp dedup markers I created (abc12345, zzz99999) were trashed.
