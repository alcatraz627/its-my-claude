#!/usr/bin/env bash
# setup-check.sh — does a /magi run's SETUP actually distribute, or is it an echo?
#
# The deeper root cause behind the 2026-06-13 skipped votes: convergence was
# MANUFACTURED — all voters were fed one shared corpus (the supervisor's own
# digest) with no per-voter evidence partition, so they agreed by construction,
# and "they converged" became the excuse to skip voting. Persona richness is a
# decoy; evidence independence is the load-bearing axis. This check runs
# PRE-DISPATCH (before the expensive voters spend) and flags echo-prone setup so
# the run is fixed before, not audited after.
#
# It reads a per-voter EVIDENCE MANIFEST from meta.json `params.voter_evidence`
# (a list of {voter, slice, model}); init-archive.sh persists it when the
# supervisor supplies one. ADDITIVE + graceful: no manifest → WARN (not block),
# so existing runs don't break — but the warning is loud, because an unmeasurable
# setup is echo-prone by default.
#
# Usage: setup-check.sh <archive-root>
# Exit:  0 = distributes · 1 = warnings · 2 = CRITICAL (echo-prone by construction)

set -uo pipefail
ARCHIVE="${1:-}"
[ -n "$ARCHIVE" ] && [ -d "$ARCHIVE" ] || { echo "setup-check: no archive at '$ARCHIVE'" >&2; exit 2; }

python3 - "$ARCHIVE" <<'PY'
import json, os, sys, glob, math

arc = sys.argv[1]
def p(*a): return os.path.join(arc, *a)
meta = {}
try:
    with open(p("meta.json")) as f: meta = json.load(f)
except Exception: pass
params   = meta.get("params") or {}
manifest = params.get("voter_evidence") or []      # [{voter, slice, model}, ...]
research = (params.get("research") or "").lower()
n_vote   = len(glob.glob(p("03-voter-proposals", "voter-*.md"))) or len(manifest)
breadth  = params.get("task_breadth")              # True for "gather varied findings"
# Heuristic: a full panel (>=5) on an extract/generalize task is breadth unless
# explicitly marked convergent.
if breadth is None: breadth = n_vote >= 5

crit, warn, ok = [], [], []

if not manifest:
    warn.append("NO evidence manifest (params.voter_evidence empty) — setup "
                "independence is UNVERIFIABLE, which is echo-prone by default. "
                "Assign each voter a DISTINCT primary evidence slice (D1) and record "
                "it via `init-archive.sh --params` (the voter_evidence list). Without "
                "it, 'they converged' "
                "cannot be distinguished from 'they all read the same digest'.")
else:
    slices = [ (v.get("slice") or "").strip().lower() for v in manifest ]
    models = [ (v.get("model") or "").strip().lower() for v in manifest ]
    uniq_slices = len(set(s for s in slices if s))
    # CRITICAL: every voter shares one evidence base → convergence by construction
    if uniq_slices <= 1 and len(slices) > 1:
        crit.append(f"ALL {len(slices)} voters share ONE evidence slice "
                    f"({slices[0] or 'unspecified'!r}) — convergence is manufactured, "
                    "not discovered. Partition the evidence (distinct primary slice "
                    "per voter) before dispatching.")
    # CRITICAL: a supervisor-authored digest is the shared substrate (D2)
    # Strong supervisor-artifact terms only — "summary" was too broad (would trip
    # a legit slice like "summary-of-reviews"); keep the unambiguous ones.
    digestish = [s for s in slices if any(k in s for k in
                 ("baseline", "digest", "sweep"))]
    if len(digestish) > 1:
        crit.append(f"{len(digestish)} voters are assigned a supervisor-authored "
                    "interpretive base (baseline/digest/sweep) as their slice — that "
                    "propagates the supervisor's frame to the panel (D2). A shared "
                    "*factual* base is fine; a shared *interpretive* one is the echo.")
    # WARN: weak partitioning
    if crit == [] and uniq_slices < math.ceil(len(slices) / 2):
        warn.append(f"weak partitioning: only {uniq_slices} distinct slices across "
                    f"{len(slices)} voters — most share a base.")
    # WARN: no different-model contrarian (prior-independence lever)
    if len(set(m for m in models if m)) <= 1:
        warn.append("no different-model voter — the one lever proven to produce real "
                    "divergence (a contrarian on a different model) is absent.")
    else:
        ok.append("a different-model voter is present (prior-independence)")
    if uniq_slices >= math.ceil(len(slices) / 2) and crit == []:
        ok.append(f"{uniq_slices} distinct evidence slices across {len(slices)} voters")

# research mode vs breadth
if research == "minimal" and breadth:
    warn.append("research:minimal on a breadth/generalize task — voters can't reach "
                "beyond the shared frame, so any agreement is echo (D3). Require "
                "independent external/raw-source research per voter for breadth asks.")
elif research and research != "minimal":
    ok.append(f"research mode '{research}' supports independent grounding")

print("─" * 56)
print("  /magi setup-independence check (pre-dispatch)")
print("─" * 56)
for c in crit: print("  \033[31m✗ CRITICAL\033[0m " + c)
for w in warn: print("  \033[33m⚠ warn\033[0m     " + w)
for o in ok:   print("  \033[32m✓\033[0m          " + o)
if crit: print("\n  → echo-prone setup. Fix the partition before spending on voters.")
print("─" * 56)
sys.exit(2 if crit else (1 if warn else 0))
PY
