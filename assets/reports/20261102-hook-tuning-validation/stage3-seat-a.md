# Stage 3 seat A: H11, H12, H18

All three fixes built, each test file green, each guard shown red under a scratch-copy mutation. Nothing committed. Replays used `scan-baseline/attachments.jsonl` (human sessions only, same population as `audit/measure.py`).

## H11 guidance whole-word match

Changed:
- `/Users/alcatraz627/.claude/scripts/guidance.sh:25` new `scope_matches` (whole word or phrase, comma separated scopes kept whole, case folded, `all` always). `:88` `relevant` calls it. `:17` `GUIDANCE_NOTES` env override added for tests. `:41` `GUIDANCE_SOURCE_ONLY=1` returns before the case so a test can source the function.
- New `/Users/alcatraz627/.claude/scripts/guidance.test.sh` (27 checks: report vs port, "port 5100", "port," and "(port)", case, next dev as a phrase only, dev-server, hyphen/underscore edges, literal dot, empty prompt, end to end through `relevant`).

Replay (379 real guidance note fires, old script reproduces 312 of them today since notes changed since):
- Before: 379 fires, 65 on a real keyword (17%).
- After: 65 fires, 65 on a real keyword (100%). Lost fires: 314, of which 0 had a real whole-word keyword by `measure.py`'s own `\b` test. Sample of lost: "Looks good, commit and push...", "commit", "1a..." task-notification prompts, "the issues in the report" (port in report). No real match was lost.

Mutations (scratch copies in `/private/tmp/claude-501/-Users-alcatraz627--claude/f0985c5b-e237-48e3-8496-c2fde05ccb7a/scratchpad/mut/`):
- substring match: 5 FAIL. Left edge boundary removed: 3 FAIL. Phrase split into words: 3 FAIL. Real file: 27/27 green.

## H12 memory-reach aliases

Changed: `/Users/alcatraz627/.claude/scripts/hooks/memory-reach.py:36-41` `ALIASES` table (`better-file-browser: bfb`, `switchboard-mac: switchboard`); `:77` `mentioned` uses full name, name with spaces, or alias, no first-word inference. Evidence for aliases: "bfb" 41 real prompts, "switchboard" 11. Rejected as not true aliases: "clanky" (a PR bot), "ghostty", "slack", "enhancement", "foundry" (ambiguous with forge/foundry pairs), "ipc" (plausible, unverified as a load trigger, left out).
Extended `/Users/alcatraz627/.claude/scripts/hooks/memory-reach.test.sh` (now 19 checks; `MEMORY_REACH_BIN` override at line 6).

Replay on 605 distinct real prompts (false = neither full name, spaced name nor alias):

| project | old loads | old false | new loads | new false |
|---|---|---|---|---|
| better-file-browser | 78 | 44 | 60 | 0 |
| local-models | 31 | 31 | 0 | 0 |
| landing-app | 11 | 11 | 0 | 0 |
| slack-automation | 122 | 27 | 95 | 0 |
| enhancement-product | 15 | 9 | 6 | 0 |
| ghostty-themes | 7 | 4 | 3 | 0 |
| documents-* (2 projects) | 4 | 4 | 0 | 0 |
| switchboard-mac | 11 | 0 | 11 | 0 |
| claude-ipc, csync, i-dream, speedway, versable-builder, versable-foundry | unchanged | 0 | unchanged | 0 |

Total false: 130 to 0 (once per session: 76 to 0; the three named projects 51 to 0 at once-per-session, matches the plan's 49 in kind). Every full-name load is retained (new loads equal the full-name count per project). `switchboard` still loads. Note: better-file-browser dropped 78 to 60 because 18 of the old loads were "better"/"browser" alone.

Pre-existing, unchanged: speedway misses 2 prompts where the name is hyphen-adjacent ("speedway-foo") in both old and new.

Mutations: first-word inference restored: 4 FAIL. Alias table emptied: 2 FAIL. Spaced form removed: 1 FAIL.

## H18 persona-suggest

Read of how it classified: the planning cue matched the bare word `plan` anywhere, plus `sequence`, `decompose`, `roadmap`, so "docs/plan/x.md" and "where are we in the plan" fired it.

Changed `/Users/alcatraz627/.claude/scripts/hooks/persona-suggest.sh:54-61` (`PLAN_ASK`) and `:70`: planning now needs a verb use ("lets/help me/can you/we should ... plan|decompose|sequence"), plan as a leading imperative, a request to make one ("make/come up with/draft ... a plan"), "break this down", or "how should we approach". `roadmap` dropped. The four other persona cues are untouched.
New `/Users/alcatraz627/.claude/scripts/hooks/persona-suggest.test.sh` (20 checks incl. dedup, short prompt, skill-named prompt, strategic-triad still fires).

Replay of the 32 real fires through the hook, with stage 2 in place: 32 to 16 from stage 2 alone (task-notifications, command wrappers, short, skill-named), then to 5 with this change.
Still fire: 4 planning ("come up with the best plan and proceed", "split this plan into two ... thoroughly plan", "help me plan and build and test", "lets make a plan for this") plus 1 web-research fire.
Dropped planning fires include nouns only ("where are we in the plan", "your plan file", "Refactor Plan is good", "docs/plan/...").
Lost arguably-real: "we'll review and plan a fixing session" (verb after "and", not matched).

Mutations: old regex restored: 6 FAIL. Make-a-plan clause removed: 2 FAIL. Leading-imperative clause removed: 1 FAIL.

## UNCONFIRMED / left

- The one remaining non-planning fire is the web-research cue; its greedy `compare .*options` matched a long prompt ("compare the relative cost/impact of all the options"). I did not touch it (outside the planning ask). Say if you want it tightened or the non-planning cues removed so the hook fires only on planning.
- Heed rate after the change is not measurable until new fires accrue; only the fire count was replayed.
- H11 "fires" in the baseline counts note lines per injection, and my replay shares that definition; the live hook's output for a given prompt today uses today's notes file.
- Test for persona-suggest writes a short-lived `/tmp/claude-personasuggest-<sid8>` sentinel and cleans it up; heed markers go to a temp `TMPDIR`.
