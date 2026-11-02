# Stage 0 validation: keep-warm arm check (A) and hook audit tool (B)

Verdict: PASS-WITH-NOTES for A, ISSUES-FOUND for B. Nothing touched live state (all runs used temp KEEPWARM_DIR, KEEPWARM_SWITCH, USAGE5H_* and HOOK_AUDIT_* overrides; mutations only on temp copies).

Probe scripts (all under /private/tmp/claude-501/-Users-alcatraz627--claude/f0985c5b-e237-48e3-8496-c2fde05ccb7a/scratchpad/kwv/): probe1-5.py, mutate2.py, an1-10.py, mut_audit.py, rob.py.

Note on the moving target: /Users/alcatraz627/.claude/scripts/hooks/audit/measure.py changed under me at 22:58 (12,825 to 13,465 bytes; a new H8_block_outcomes block, plus new files ledger_coverage.py, no-ledger.txt, run-hook-tests.py). Mutation runs used the 13,465 byte version. The saved baseline JSON predates it, so `measure.py SCAN --compare baseline` now prints one added key, H8_block_outcomes (null -> {...}), and nothing else. Every other baseline number reproduces exactly from /private/tmp/.../scratchpad/scan-baseline.

---

# CHANGE A: keep-warm

## Ranked findings

1. MEDIUM, test gap: the re-ask guards are unpinned. My extra mutations on a temp copy of the keepwarm dir survived the 118-test suite (mutate2.py):
   - `arm_text` no longer pops `job_seen` (keepwarm.py:338). A stale `job_seen` then suppresses every later check after a relink, compact or resume. The owner-return after a /core-dump leaves `job_seen` True (repro: probe4 section E), so only line 338 stops a stale True from hiding a missing job.
   - the block ignores `stopped` (keepwarm.py:944), and ignores the switch file (same line).
   - 8MB window shrunk to 8KB (keepwarm.py:882): no test has a transcript bigger than a few hundred bytes.
   - a CronCreate row with no timestamp counted as "not created" instead of "created" (keepwarm.py:900-901).
   - `hook_start` no longer resets `arm_asks` (keepwarm.py:979).
   - the `oneshot_mode()` exemption removed (keepwarm.py:929).
   - any tool name counts (`name == "CronCreate"` dropped, keepwarm.py:896).
   The stock mutate_arm.py's 10 mutations are all caught (0 survivors).
2. MEDIUM, real bug: `arm_asks` is only reset in hook_start (keepwarm.py:979). A relink through hook_prompt (keepwarm.py:604-607) does not reset it, and a confirmed job does not reset it. Repro (probe4 G): a session that burned 3 asks, then had its job expire (recurring_at 7 days old) and got relinked by the owner's next prompt, is then never checked again. The next Stop printed silent with `arm_asks` still 4. The exact Movies failure (job never created, nothing noticed) comes back for any session that already used its asks once.
3. LOW-MEDIUM, design: task-notification turns spend asks and get blocked. hook_stop cannot tell a task-notification turn from an owner turn (probe4 H: blocked, asks=1). The real Movies session received six task-notification prompts (events.jsonl lines 2908-2913), so a burst can exhaust the 3 asks on non-owner turns. The block there is arguably useful (it arms the job), but it cannot be waved away as silent, and it eats the budget that finding 2 says never comes back.
4. LOW, false block: a CronCreate older than the 8MB tail window is not seen (probe2: CronCreate then 9MB of filler, `since=0` gives False). This needs more than 8MB of transcript between the create and the first Stop that confirms it. `job_seen` is cached on the first confirming Stop, so it needs a single turn of 8MB+ after the create. A 300-tool-call Movies-style turn could do it, but the arm is meant to be the last step. Effect is bounded: at most 3 re-asks, then `arm-failed`.
5. LOW: crashes in job_created_since for malformed rows. Three shapes raise AttributeError (probe3): `message` is a string, `input` is a list, a row that is a JSON array. main() swallows it (keepwarm.py:1022), but hook_stop dies before `save`, so last_activity, answered, ctx and job_seen are not updated for that Stop and every later one. A row must be type assistant (or a top-level list) and contain both tokens, so I could not find a real way to produce it. Fix is a try/except around the loop body or `isinstance` guards.
6. LOW: one-shot mode with a leftover `recurring_at` overwrites `armed_at` with now+40min on every Stop (probe4 C: +2400s). It would mask a broken one-shot chain for up to 50 minutes. Only reachable by toggling the oneshot file mid-session.
7. NOTE: `recurring_at` non-numeric ("abc") cannot occur (only now_s() writes it); with a real CronCreate row present it would TypeError at keepwarm.py:902 and abort the Stop as in finding 5.

## Claim by claim

1. Sync Stop hook cost: PASS. Real subprocess, 111MB transcript (/Users/alcatraz627/.claude/projects/-Users-alcatraz627-Code-better-file-browser/f889a4e4-fa3a-40fc-820e-9d147aada8eb.jsonl is the largest real file, 111MB, not 200MB), unconfirmed job: 0.077s and 0.086s, blocked correctly. Synthetic 207MB file with 8MB of worst-case tail (every line holds both tokens inside tool_result rows): job_created_since 0.045s. The scan runs on every unconfirmed Stop but `job_seen` makes it one scan after confirmation. Failure modes are bounded: OSError (missing file, directory, "") returns True (no block); None as path raises TypeError (the hook uses `or ""`, so unreachable). No settings timeout is set (default applies), irrelevant at these speeds.
2. Re-entry paths (probe4, UNCONFIRMED where noted):
   - /clear: hook_start sets stopped, keeps recurring_at and job_seen, so no relink and no block (E/F). With a new session id the new state has no recurring_at, the owner prompt relinks with the "delete any [keepwarm] job, then CronCreate" text, and the Stop blocks only if the model reuses the old job without calling CronCreate (3 asks max).
   - /compact and --resume: hook_start re-arms (arm_text pops job_seen), so the model is told to delete and recreate. A job that survived compaction is deleted and recreated or the model gets up to 3 blocks. Harmless, bounded.
   - switch off, headless (sdk-cli), one-shot: no block (C).
   - wake turn: in_wake returns before the job check (keepwarm.py:920), so it is silent; the next owner turn blocks if the job is missing (D). That is correct.
   - dump turn: `recurring_at` popped, no block; owner return relinks (E).
   - resumed_turn: the first block uses arm_text (sets recurring_at, pops job_seen); the continuation Stop (`stop_hook_active`) is silent; the next owner Stop can block (I: asks 3). No loop. In recurring mode the resumed_turn block only fires if `chain_broken` (recurring_at None or older than 6.5 days), so it rarely fires; the normal path handles it.
   - double block: the resumed_turn block and the stop-check block cannot both fire in one Stop (the first returns). Another Stop hook blocking first sets `stop_hook_active`, which silences keepwarm's ask for that stop (acceptable).
   - UNCONFIRMED: whether the model, after a block in a turn where the owner had just asked something, re-sends its answer. Cannot be exercised without a live claude session. The block text says "end the turn... without mentioning it".
3. hook_stop order: the Movies case passes. `resumed_turn` (False normally) and `in_wake` (False on an owner turn) are skipped, then `recurring_at` is set by hook_start, `job_seen` absent, and job_created_since is False, so `job_missing` becomes True and the block fires (probe4 A: blocked at stops 1-3, silent at stop 4, `arm-failed` logged once). A wake that never reaches Stop leaves `in_wake` True until the next owner prompt pops it (keepwarm.py:595). `return` before job_missing only happens for in_wake and resumed_turn, both correct.
4. Malformed input: non-dict message content returns False without raising (content-string, content-dict, list of strings all False). Missing or int or garbage timestamp returns True (treated as created, so no block; deliberate). Non-string prompt is False. Binary garbage line is skipped (UnicodeDecodeError is a ValueError). Directory path: IsADirectoryError is an OSError, returns True. Raises: finding 5.
5. A live job told to create a second one: only through the designed delete-then-create text (keepwarm.py:339). No path asks for a second job without the delete instruction.
6. Mutation test: see finding 1.
7. Replay: job_created_since on /Users/alcatraz627/.claude/projects/-Users-alcatraz627-Movies/97e805c3-2944-4ca1-8774-2c88c65db93a.jsonl (3,471,405 bytes) with since=0 returns False in 0.005s, and with since=now also False. The real-transcript positive control also works on Python 3.9.6 (/usr/bin/python3, the interpreter the hook runs): four real CronCreate rows with 3-digit-ms Z timestamps give True at since-5s and False at since+5000s where the row is the only one.
   The live state file for that session shows `recurring_at` set 17 minutes before `last_activity` and `armed_at` still promised, which matches the diagnosis.

Existing suite: python3 keepwarm-recurring.test.py gives 118/118 on this tree.

---

# CHANGE B: audit tool

## Ranked findings

1. HIGH: the saved baseline cannot support a before/after claim for the window, because `compare` ignores the window (measure.py:223 skips the `window` key). Re-run on a shorter or different window prints every count as "improved". There is also no guard that the scan covered any files: an empty folder gives all zeros (rob.py: scan of an empty root returns 0 files, measure returns exit 0 with zeros), and comparing that to the baseline prints a "fixed" line for every row. Fix: refuse `--compare` when the windows differ or when `files == 0`.
2. HIGH: text signs that go to zero for the wrong reason.
   - H15 (measure.py:175): the regex `rg.{0,40}-r\b|guard-rg` matches only because the denial text begins "rg -r IS --replace" (guard-rg-replace-bundle.sh:90). The `guard-rg` branch never matches (0 of 29 rows contain it). Rewording the message ("ripgrep's -r flag...", no "rg" within 40 chars) makes H15 read 0 with the guard still firing. Also 1 of 29 is a false hit (a Read of a file quoting the message, `tool` is Read), so H15 overcounts by 1 (3%).
   - H23 (measure.py:189): the ipc-owed gate is keyed on the literal "request you haven't". The emitter is not in any ~/.claude or claude-ipc source I could grep, so the wording can drift unseen, and a "query" variant already escapes it: "bfb sent you a query you haven't answered" is bucketed as `other` (one row in the 22-row `other` bucket). H23 additionally needs the literal "dp-server" in the first 2,500 chars.
   - H4 (measure.py:106-109): `AUTOMATED` lists "[keepwarm]", which can never match because keep-warm wake prompts are `isMeta: true` rows (307 of 307 in the window) and scan.py:96 skips isMeta rows for `last_prompt`. So H4 sees only task-notification turns, plus keep-warm turns that happen to follow one. My independent recount of keyword injects: 188 on task-notification turns and 8 on keep-warm turns; the baseline's 196 equals 188 + 8, which I could not explain from the code (UNCONFIRMED how the 8 get in). When the keyword hooks stop firing on keep-warm turns this measure cannot show it.
   - H20 (measure.py:178): counts a block only by its first tell, so a path tell in second position is missed (same method as the report).
   - H3, H5, H21, H22, H30, H31 signs were all checked against the current hook source and still match. `[glossary]` is not in any source (built dynamically) but appears 541 times in transcripts, so it is fine.
3. MEDIUM: the stacked-stop measures disagree with the report and the cause is the dedupe key. Baseline `interactive_blocked_stops` 369 and `H27_stops_with_2plus_messages` 64 against the report's 379 blocked stops. Using (sid, turn, last-200-chars) merges separate stops: 5 of the 64 "stacked" groups span more than 5 seconds. Grouping by (sid, second) gives 380 blocked stops (matches the report's 379) and 59 stacked. So H27 is overcounted by about 8 percent and blocked stops undercounted by about 3 percent. The disagreement is not explained in the baseline.
4. MEDIUM: mutation survivors in measure.test.py (mut_audit.py, 21 mutations, 11 survived):
   - scan.py `since` bound removed (`ts < since`) stays green; only the `until` bound is exercised. Same for the secret-log `since` bound.
   - population split: sdk-cli headless, show-me-examples and the subagent flag are untested.
   - H27 threshold `>= 2` changed to `>= 1` stays green; the stack key ignoring `turn` stays green.
   - H4 human filter, H15, H23 and H24 have no test at all.
   Caught: until bound, bookkeeping rows, ledger since bound, PostToolUse double-count filter, per-message stack key, critic split, H4 automated prefix, the denial regex, the mtime floor. The window filter and double-count filter are therefore only half-pinned (the double-count and until-side are red, the since-side is green).
5. LOW-MEDIUM: measure.py crashes on truncated or blank JSONL (rob.py): a truncated last attachments row gives `JSONDecodeError` exit 1; a blank line does too; a folder with missing files gives `FileNotFoundError`. Loud, not wrong, but a killed scan.py leaves exactly that state. An empty-but-valid folder works (all zeros). `scan.py --since yesterday` gives a raw ValueError.
6. LOW: `sub` flag in sessions.json (scan.py:130) is set by whichever file the glob reaches first. Subagent files carry the parent's sessionId (300 of 300 checked). In this run 0 of 630 sessions were flagged sub, so order was main-first, but nothing guarantees it, and a subagent-first order would drop the whole interactive session from `human`.
7. LOW: ordering assumption: 6 of 664 sampled UserPromptSubmit attachments appear before their own user row, so they inherit the previous prompt (task-notification pairs in a1ee5007). Tiny.
8. LOW: H14 counts at most 2 items per block, because format-gate prints 2 and then "+N more" (format-gate-stop.sh:277-281). 71 items is a floor.
9. NOTE: `H8` is now two things: H8_emdash_heed_rows_from_critics (118) and the new H8_block_outcomes. The outcome buckets use a loose dismissal regex (measure.py:125, "leaving", "as it is", "not mine"); it mirrors the report's "loose regex" caveat but is not a tested measure.

## Baseline against the report (same window)

Matches exactly: sessions 68/503/52/7, H1 503, H2 157 (= 156 critic blocks + 1 other-headless), H3 17, H5 274 and 14, H13 1,588, H21 101 = 23 findings + 78 wait/retrigger, H22 46 / median 0.09 / 32 under 15 percent, H23 7 of 11, H30 40, H31 34, gate counts for pr-review 101, doc-voice 83, relpath 54, goal-paste 34, terse 27, task-stale 17, bare-id 12, queue 12, ipc-owed 11, ui-verified 9, H12 29/14/6, H18 32, H8 118.

Disagreements:
| Row | Baseline | Report | Explained? |
|---|---|---|---|
| interactive stops | 1,434 | 1,426 | No. All 1,434 are unique (sid, ts) main-session rows, no duplicates, so it is not double counting. |
| blocked stops | 369 | 379 | Yes by me: dedupe key (finding 3). Not explained in the baseline. |
| block messages | 448 | 447 | No (off by one). |
| filename-dot | 63 | 62 | No (H20 117 vs the report's 116). |
| guidance fires / real keyword | 379 / 66 | 377 / 64 | No (2 each). |
| doc-note count | 524, 4.5 per file | 518, 4.4 | No. |
| box injects | 535, 581,719 chars | 531, 577K | No. |
| review-nudge ledger rows | 342 | 335 | No (window end). |
| H24 | 342 | n/a | Equals the ledger total; it is not a double count: 342 distinct (sid, ts) transcript rows, all in human sessions, which also shows 238 critic-attributed ledger rows are wrong sids. |

The window itself is not in the report text (ends 11-01); the baseline's `until` of 2026-11-01T14:40:00 is plausibly the cause of the small count gaps (about 0.6 percent) but nothing records that.

The mtime floor misses nothing: 11,522 files below the floor were checked by their last timestamp, 0 had a timestamp inside the window. Latent only for files whose mtime was reset after a copy.

---

## Artifacts made and not removed

- Probe and mutation scripts left in /private/tmp/claude-501/-Users-alcatraz627--claude/f0985c5b-e237-48e3-8496-c2fde05ccb7a/scratchpad/kwv/ (including an5.py.bak). Those are intentional.
- The existing test suites (keepwarm-recurring.test.py, measure.test.py, run through mutation harnesses) each leave an unremoved `tmp*` directory under /var/folders/t8/k_k3y4h95qqfmnhp3k3fgqkh0000gn/T/ per run (they call tempfile.mkdtemp without cleanup). I ran about 35 such runs; I cannot tell my directories from other sessions' in that listing, so I did not delete any. My own kwv-* temp dirs were trashed.
- No writes to ~/.claude/keepwarm, hooks/warn-events.jsonl or settings.json.
