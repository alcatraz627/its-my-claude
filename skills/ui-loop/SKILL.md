---
name: ui-loop
description: Drives a UI change to convergence through the local-models loop, where scripts measure, Claude judges, the ledger tracks, and `see reshoot` re-captures. Use for iterative UI fix rounds against a live page or a reference pair, when a one-shot /ui-gripe or /vis-compare is not enough.
allowed-tools: Read, Bash, Grep, Glob, Edit, Write
user-invocable: true
argument-hint: "<url-or-image-pair> [claims-or-reference]"
---

## Brief

The driver for the vision lane's convergence loop. One loop dir per run holds a capture recipe, evidence rounds, and the ledger. The agent's only judgment seat is step 2; every other step is a dumb tool. Status words (fixed, persisting, regressed, new) come from `lib/vis-ledger.py` set math, never from a model.

## Step 0: Load shared guidelines

Read `~/.claude/skills/GUIDELINES.md` and this skill's `runtime-notes.md` if present. The tools live in `~/Code/local-models` (on PATH). Read `~/.claude/rules/ui-visual-verification.md`; its whole-frame rule binds step 2.

## The loop

1. **Open the loop.** `LOOP=~/Code/local-models/outputs/see/loops/<slug>`; `mkdir -p "$LOOP"`. Write `$LOOP/recipe.json`:
   - live page: `{"kind":"web","url":"...","viewport":"1280x720","wait_ms":1500}`
   - reference pair whose candidate gets re-rendered in place: `{"kind":"static","b":"/abs/path/candidate.png"}`
2. **Round 1 capture.** `see reshoot "$LOOP"` prints `{round_img}`. On `not_comparable` or `capture_failed`, fix what the error names before anything else.
3. **Measure, $0.** Against a reference: `see diff <A> <round_img> --no-read --json`, keep `.evidence` as `$LOOP/round-N-pack.json`. No reference: `see <round_img> --ui --json` plus `see <round_img> --ocr` for exact strings.
4. **Judge (the one paid seat, yours).** Describe the whole frame first, in one sentence, before any prepared question. Then produce `$LOOP/round-N-verdict.json`:
   - imitation fidelity: run `/vis-compare` over the pack (its native shape, `divergences`)
   - claims: `lm ui-verify <round_img> "claim"...`; failed or unsure claims become `{"items":[{"id":"<claim-slug>","class":"claim-fail","judgment":"fail"}]}`
   - confusion findings from `/ui-gripe` map the same way, one item per finding, stable ids.
5. **Ledger.** `~/Code/local-models/.venv/bin/python ~/Code/local-models/lib/vis-ledger.py add "$LOOP" round-N-verdict.json --pack round-N-pack.json`. Read `signals`: `stop: policy-pass` or `pass-with-notes` ends the loop; `stall` after 2 zero-fixed rounds means stop and rethink, not retry.
6. **Fix.** Edit the code. You are the only seat that edits.
7. **Re-round.** `see reshoot "$LOOP"` and back to step 3. Scores are not progress; only the ledger's transitions are (the tool says so in-band).

## Validation

- Every round's verdict cites its pack or inventory by path; a verdict with no evidence file is not a round.
- The loop ends only on a ledger signal (`policy-pass`, `pass-with-notes`, `stall`), never on "it looks done".
- On a `stall`, the report to the user names the persisting ids and what was tried, not a promise to keep looping.

## Post-run (MANDATORY, every run)

`bash ~/.claude/scripts/skill-log.sh record ui-loop --task "<target>" --outcome <ok|revised|failed> --corrections <n> --note "rounds=<n> stop=<signal> open=<n>"`

## See also

- `/vis-compare` (the L2 judge and its policy), `/ui-gripe` (confusion forensics), `lm ui-verify` (claim gate)
- `~/Code/local-models/docs/10-visual-compare-design.md` §10 for the L3 semantics
