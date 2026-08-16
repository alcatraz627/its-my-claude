#!/usr/bin/env bash
# resolve-store.sh — answer "which task store belongs to THIS live session?"
#
# THE PROBLEM. The store directory is named for the session that CREATED the
# tasks. A task list survives /clear, so the live session id usually does not
# name its own store: 231 stores exist on this machine and none of
# CLAUDE_CODE_SESSION_ID, CLAUDE_CODE_BRIDGE_SESSION_ID, the /private/tmp session
# dir, or any marker inside the store names the right one. Picking the most
# recently modified store is a race between concurrent sessions, and it rendered
# agents each other's queues (owner report 2026-08-16).
#
# THE FIX IS TO RESOLVE BY CONTENT, NOT BY NAME. Ask which store actually
# contains the tasks this session has been touching. The live transcript records
# every task subject the session created or updated; exactly one store contains
# them. That is self-verifying in a way no id-matching can be: a wrong answer
# would require another session to hold the same task subjects.
#
# Two id-leaking artifacts were considered and REJECTED as primary signals:
#   - subagent ids of the form <agent>@session-<sid8>. In this very session those
#     resolve to 83b4de86, a DIFFERENT session's store, because unmatched
#     harness-internal subagents land in the transcript. Trusting it reproduces
#     the bug with more confidence.
#   - background-task output paths under the store uuid. Correct when present,
#     but only exists if a background task ran this session.
# Content-matching needs neither and is checked against both below.
#
# WHAT THE EXPLAIN FIGURE ACTUALLY MEASURES, established 2026-08-16 by a peer and
# reproduced here. "75 of 75 subjects" looks like a statement about the resolver.
# It is substantially a statement about the TRANSCRIPT'S RECENT CONTENTS, because
# the harness periodically re-echoes the whole task list into the transcript. Every
# echo refreshes every subject, however old, into the 900KB tail. Measured on this
# machine: a task from a PREVIOUS session appeared 4 times in the last 900KB while
# a task created an hour earlier appeared 5. Age does not predict tail presence.
#
# Two consequences. The tail-starvation case (a store whose subjects all predate
# the window) is MASKED by this, not disproven, and a session where the echo is
# quiet gets no replenishment. And a high score is a poor health signal: a
# resolver that could not find old subjects at all would score identically while
# the echo is running.
#
# Usage: resolve-store.sh                  print the store dir, or exit 4
#        resolve-store.sh --explain        show the evidence
#        resolve-store.sh --as-session <sid>
#            Resolve AS IF that session were live. Exists because the starvation
#            case above cannot otherwise be tested: the resolver answers for the
#            live session, and nobody can be a session from June. Also useful for
#            inspecting another session's store without guessing.
set -uo pipefail
export PATH="/opt/homebrew/bin:$PATH"

EXPLAIN=0; AS_SESSION=""
while [ $# -gt 0 ]; do
  case "$1" in
    --explain)    EXPLAIN=1; shift ;;
    --as-session) AS_SESSION="${2:-}"; shift 2 ;;
    *)            shift ;;
  esac
done

G="$HOME/.claude"; TASKS="$G/tasks"; CACHE="$TASKS/.live-session-map"
LIVE="${CLAUDE_CODE_SESSION_ID:-}"

# --as-session substitutes the identity but NOT the cache: a probe of somebody
# else's session must not write into the live session's mapping, and must not be
# answered from it either. Skipping the cache also makes every probe a cold
# derive, which is the only kind worth measuring.
NO_CACHE=0
if [ -n "$AS_SESSION" ]; then
  # Accept a full uuid or an 8-char prefix; expand a prefix to the real id so the
  # transcript glob can find it.
  if [ "${#AS_SESSION}" -le 8 ]; then
    _m=$(fd -e jsonl "^${AS_SESSION}" "$G/projects" 2>/dev/null | head -1)
    [ -n "$_m" ] && AS_SESSION=$(basename "$_m" .jsonl)
  fi
  LIVE="$AS_SESSION"; NO_CACHE=1
fi

LIVE8="${LIVE:0:8}"
[ -n "$LIVE8" ] || { echo "resolve-store: no CLAUDE_CODE_SESSION_ID (and no --as-session)" >&2; exit 4; }

# 1. A store literally named for the live session (rare but free).
if [ -d "$TASKS/session-$LIVE8" ]; then
  [ "$EXPLAIN" = 1 ] && echo "resolved by: live session id names a store" >&2
  printf '%s' "$TASKS/session-$LIVE8"; exit 0
fi

# 2. Cache. Written by step 3, not by hand. Verified before use, because a
#    cached answer that has since been deleted must not silently win.
if [ "$NO_CACHE" = 0 ] && [ -r "$CACHE/$LIVE8" ]; then
  c=$(cat "$CACHE/$LIVE8" 2>/dev/null)
  if [ -n "$c" ] && [ -d "$TASKS/session-$c" ]; then
    [ "$EXPLAIN" = 1 ] && echo "resolved by: cached content-match ($c)" >&2
    printf '%s' "$TASKS/session-$c"; exit 0
  fi
fi

# 3. Content-match against the live transcript, then cache the result.
# stderr is dropped normally so a python traceback cannot corrupt the answer, but
# --explain has to let it through: the explain line is printed on stderr from
# inside the heredoc, so a blanket 2>/dev/null meant --explain could only ever
# describe a CACHED hit and went silent on the fresh content-match it exists to
# describe. Found 2026-08-16 while verifying the peer's case.
[ "$EXPLAIN" = 1 ] && PYERR=/dev/stderr || PYERR=/dev/null
OUT=$(LIVE="$LIVE" TASKS="$TASKS" EXPLAIN="$EXPLAIN" python3 - <<'PY' 2>"$PYERR"
import json, os, pathlib, re, subprocess, sys
live = os.environ["LIVE"]; tasks = pathlib.Path(os.environ["TASKS"])
explain = os.environ["EXPLAIN"] == "1"
# Find the transcript in ANY project, not just this one. The path used to be
# hardcoded to projects/-Users-alcatraz627--claude, so content-matching worked
# only for sessions whose cwd was ~/.claude and returned nothing for the other
# 83 project directories on this machine. A peer in
# projects/-Users-alcatraz627-Code-Versable-automation hit it on 2026-08-16:
# their store held 75 tasks and was findable by content, but the resolver never
# looked at their transcript. Glob, then take the newest if a session id somehow
# appears twice.
projects = pathlib.Path.home()/".claude"/"projects"
cands = sorted(projects.glob(f"*/{live}.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True)
if not cands: sys.exit(1)
tx = cands[0]
# Read the WHOLE transcript. This used to be a 900KB tail, on the theory that
# recent task activity is enough and a transcript can be megabytes. Both halves
# of that theory were wrong, and measuring took one command.
#
# Cost: on the largest transcript on this machine, 55MB, a full scan and a 900KB
# tail both complete in 0.02s. The window bought nothing, because this is a
# linear scan and the file is not large by scanning standards.
# Benefit: the same 55MB file yields 109 unique subjects whole against 66 from
# the tail. The window was discarding 40% of the available evidence.
#
# What made the loss invisible: the harness periodically re-echoes the entire
# task list into the transcript, so old subjects keep reappearing in the tail and
# a score can look perfect while real subjects are being dropped. Measured across
# 12 sessions before this change, every transcript at or above 12MB was losing
# subjects (18MB scored 62/67) while the score still read as healthy.
blob = tx.read_text(errors="replace")

# UNESCAPE the transcript side before comparing. The two sides of this comparison
# read the same string through different decoders: the transcript is scraped with
# a regex, so a subject arrives with its JSON escapes intact (\" and \\), while
# the store side goes through json.load, which resolves them. A subject
# containing a quote therefore never matched itself.
#
# This was mis-diagnosed once and the wrong diagnosis was expensive, so it is
# worth naming: the symptom was "N of M subjects" where M-N grew with transcript
# size, which looks exactly like a tail-window starving the scrape. It was not.
# Removing the window made the miss count go UP, because reading more transcript
# surfaced more quote-bearing subjects that could not match. The number was
# measuring escape mismatches the whole time.
# This is rules/testing.md [escaped-selector-grep-false-negative] in the wild.
def _unescape(s):
    try:
        return json.loads('"' + s + '"')
    except Exception:
        # Truncated mid-escape by the {12,60} bound; fall back to the common pair.
        return s.replace('\\"', '"').replace('\\\\', '\\')

subs = {_unescape(s)[:60] for s in re.findall(r'"subject":"((?:[^"\\]|\\.){12,60})', blob)}
if len(subs) < 2: sys.exit(1)          # too little evidence to be decisive
scores = []
for d in tasks.glob("session-*"):
    have = set()
    for f in d.glob("*.json"):
        try: s = (json.load(open(f)).get("subject") or "")[:60]
        except Exception: continue
        if s: have.add(s)
    if not have: continue
    hits = sum(1 for s in subs if any(s[:40] in h or h[:40] in s for h in have))
    if hits: scores.append((hits, d.name))
scores.sort(reverse=True)
if not scores: sys.exit(1)
top = scores[0]
runner = scores[1][0] if len(scores) > 1 else 0
# Decisive means: a real number of matches AND at least double the runner-up.
# A near-tie is exactly the ambiguity that produced the original bug, so it
# fails closed rather than picking one.
if top[0] < 2 or top[0] < 2 * max(runner, 1) and runner > 0: sys.exit(1)
if explain:
    print(f"resolved by: content-match, {top[0]} of {len(subs)} subjects, runner-up {runner}", file=sys.stderr)
print(top[1].replace("session-", ""))
PY
)
if [ -n "$OUT" ] && [ -d "$TASKS/session-$OUT" ]; then
  [ "$NO_CACHE" = 0 ] && { mkdir -p "$CACHE" 2>/dev/null && printf '%s' "$OUT" > "$CACHE/$LIVE8" 2>/dev/null || true; }
  printf '%s' "$TASKS/session-$OUT"; exit 0
fi

# 4. Nothing decisive. Fail closed, but SAY SO on stderr.
#
# This used to exit 4 with empty stdout and empty stderr. task-table.sh prints a
# good refusal of its own, so the silence was invisible until a peer called this
# script directly on 2026-08-16 and got nothing at all back. Failing closed is
# right; failing closed WITHOUT A WORD leaves the caller unable to tell a refusal
# from a crash, and `STORE=$(resolve-store.sh)` then builds ~/.claude/tasks//
# out of an empty variable. A refusal owes the caller its reason.
echo "resolve-store: no decisive match for session ${LIVE8}." >&2
echo "  Content-matching needs >=2 task subjects in this session's transcript and one" >&2
echo "  store holding at least double the runner-up. A store INHERITED from a previous" >&2
echo "  session will not match, because nothing typed this session names it." >&2
echo "  Pin it directly:  task-table.sh --session <sid8>   ·  stores: ls ~/.claude/tasks/" >&2
exit 4
