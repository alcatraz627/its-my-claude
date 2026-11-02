# Stage 3 seat B: H13 (secret-scan) and H15 (rg -r guard)

Both fixes built and tested. Nothing committed. Scratch files (replays, mutated copies) are in
/private/tmp/claude-501/-Users-alcatraz627--claude/f0985c5b-e237-48e3-8496-c2fde05ccb7a/scratchpad/

## H13: /Users/alcatraz627/.claude/scripts/hooks/secret-leak-scan.py

What changed
- `scan_text` (line 74): Edit, Write, MultiEdit and NotebookEdit scan only what the call added
  (`added_text`, line 61: new_string, content, new_source, edits[].new_string). The response and
  old_string are not scanned. Bash, Read and every other tool still scan input and output.
- `new_for_session` (line 91): each fingerprint reports once per session. State lives in
  ~/.claude/logs/.secret-scan-seen/<session>.
- `find` (line 48): one row per fingerprint, so the sk-ant value that fits both the Anthropic and
  OpenAI patterns reports once (as Anthropic).
- `allowed()` (line 82) reads the new /Users/alcatraz627/.claude/scripts/hooks/secret-leak-scan.allow.
- Never blocks: main still wrapped, exit 0 always (tested with garbage stdin and odd input shapes).

Allowlist (confirmed from the data, not guessed)
- Log fingerprints joined to source by hashing the matches in slack-automation files. The four token
  fingerprints dc920184, 86bab3b3 (GitHub), 046706a4 (Slack), 457643f4 (AWS) all come from
  pr-board/exercise_app.py (two also from ci-kit/gh-read.test.cjs). Shapes confirm fakes: the GitHub
  ones are a single repeated character, the Slack one is xoxb-1111-2222-..., the AWS one is a fixed
  example. Seeded.
- 8bcac790 (424 rows, the biggest) is the "BEGIN PRIVATE KEY" header only. It also matches
  slack-automation/pr-board/pr-review-automation.private-key.pem, which looks like a real key file.
  A header fingerprint cannot tell fake from real, so it is deliberately NOT allowlisted; the
  added-text rule removes its Edit noise anyway.

Replay of ~/.claude/logs/secret-leaks.jsonl (read-only, 1,800 rows; 1,769 Edit, 17 Bash, 10 Read, 4 Write)
- Before: 1,800. After: 14. Dropped: 1,773 Edit/Write rows (response no longer scanned), 5 allowlisted,
  8 per-session repeats.
- Remaining 14 are Bash/Read hits (13 on the PEM header, 1 Linear key), which still alert.
- UNCONFIRMED: the log stores no added text, so the replay treats every Edit/Write row as response-only
  noise. If some Edit's new_string held a real token, that row would still fire live; the log cannot show it.
  The 4 sk-ant/OpenAI rows (07274566) were Edit rows, so they drop from the replay on the same basis.

Test: /Users/alcatraz627/.claude/scripts/hooks/secret-leak-scan.test.py (new; none existed). 33 checks, uses
a throwaway HOME, HOOK_TEST=1 and a redirected warn ledger, so no live log is touched. Covers: Bash output,
Bash input, Read output, Write content, Edit new_string, MultiEdit edits, PEM header in new_string all alert;
token only in old_string/response of Edit and Write stays quiet; once per session and again in a new session;
sk-ant reported once; allowlist honoured and unlisted still alerts; garbage stdin exits 0 silently.
`SCAN_UNDER_TEST` points it at a mutated copy.

Mutations (scratch copies), each went red:
| Mutation | Result |
|---|---|
| Edit scans response again | 2 fail |
| Edit scans nothing | 4 fail |
| edits list ignored | 1 fail (MultiEdit) |
| no session dedup | 3 fail |
| allowlist ignored | 2 fail |
| sk-ant reported twice | 1 fail |
Restored script: 33 pass. (A first sk-ant fake was too short to match the OpenAI pattern, so that mutation
stayed green; I lengthened the fake and re-ran, now red.)

Side note: the live secret-scan fired once on my test file because it holds the literal PEM header string
(a header, no key). Expected, not a leak.

## H15: /Users/alcatraz627/.claude/scripts/hooks/guard-rg-replace-bundle.sh

Rule (from the data)
- Block a bundle where r is followed by more letters (-rn, -ri, -rl, -nrn): line 122.
- For an r that ends a token (-r, -nr, -nor), the next word must be a replacement: an empty quote pair,
  a quoted word holding a `$` reference, or a bare word holding `$` (`starts_with_replacement`, line 78).
  Anything else is blocked (`rg -r pattern src/`, `rg -r 'pattern' src/`, `rg foo -r`). `-r=VALUE` passes.
- Quoted spans are blanked by the shared skeleton, so a marker is put back where the original had `$`
  inside a blanked span (line 66 on). Skipped if the blanker changed the length, which fails toward blocking.
- Message unchanged; "rg -r IS --replace" is kept (test asserts it).

Replay of the 29 rows containing "rg -r IS --replace" (28 Bash + 1 Read row, skipped as not a command)
- Before 28 blocked, after 6 blocked.
- Still blocked, all `-rn` typos: row 4 (`rg -rn "def ipc_peers"`), 7, 14, 18, 20, 27.
- Now allowed, 22 rows, each checked to carry a real replacement: `-r '$0'` (rows 1, 6, 8, 11, 12, 13, 16, 17,
  19, 21, 22, 26 and others), `-r '$1'` / `-r "$1"` / `-r '$1$2'` (0, 3, 10, 15), `-r ''` / `-r ""` (2, 5, 9, 25, 28 area), `-r "$0"` (24, 28).
  Per-row old/new verdicts are in the replay output in the scratchpad (replay_rg.py).
- UNCONFIRMED: a literal non-empty replacement with no `$` (e.g. `-r 'X'`) is still blocked; none occurred in the 29 rows.

Test: /Users/alcatraz627/.claude/scripts/hooks/guard-rg-replace-bundle.test.sh extended from 24 to 45 checks
(11 new allow cases, 11 new block cases, 1 message-phrase check). Passes.

Mutations (scratch copies), each red:
| Mutation | Fails |
|---|---|
| bundle rule removed | 9 |
| every next word counts as replacement | 13 |
| no next word counts as replacement | 10 |
| `$` marker merge skipped | 7 |
| empty quote not a replacement | 2 |
| bare `$` not a replacement | 1 |
| trailing-r loop removed | 13 |
| message phrase changed | 1 |
The committed guard run against the new test: 11 fail, so the new cases do bite.

Note: hook-common.sh changed on disk mid-task (another session); both suites were re-run after and pass.
Not checked: measure.test.py was not run; I only confirmed the literal phrase is kept.
