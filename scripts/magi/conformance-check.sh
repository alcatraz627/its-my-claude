#!/usr/bin/env bash
# conformance-check.sh — does a /magi run actually conform to its declared mode?
#
# The 2026-06-13 fable-audit meta-review found all four full-mode runs skipped the
# Phase-6 voting round (every 04-voting/ empty) while citing convergence — i.e. the
# anti-groupthink mechanism was bypassed exactly where it mattered, and the spec's
# mandate was advisory (no enforcement) so nothing caught it. This is that gate.
#
# It is invoked by the MANDATORY Phase-11 finalize (cost-estimate.sh) so the
# verdict rides on a step the supervisor can't skip without losing its required
# cost block — per rules/skill-spec-update-not-honored: enforcement lives at the
# data-write, not in advisory SKILL.md prose.
#
# Usage: conformance-check.sh <archive-root>
# Exit:  0 = conformant · 1 = warnings only · 2 = CRITICAL (voting gate tripped)

set -uo pipefail
ARCHIVE="${1:-}"
[ -n "$ARCHIVE" ] && [ -d "$ARCHIVE" ] || { echo "conformance-check: no archive at '$ARCHIVE'" >&2; exit 2; }

python3 - "$ARCHIVE" <<'PY'
import json, os, sys, glob

arc = sys.argv[1]
def p(*a): return os.path.join(arc, *a)
def nonempty_dir(d): return os.path.isdir(p(d)) and any(os.scandir(p(d)))

meta = {}
try:
    with open(p("meta.json")) as f: meta = json.load(f)
except Exception: pass
params = meta.get("params") or {}

# ── signals ────────────────────────────────────────────────────────────────
mode        = (params.get("mode") or "").lower()
voting_cfg  = params.get("voting", None)            # True/False/None(unrecorded)
no_voting   = params.get("no_voting", False) or voting_cfg is False
proposals   = glob.glob(p("03-voter-proposals", "voter-*.md"))
has_jester  = any("jester" in os.path.basename(x) for x in proposals)
# voting artifacts that prove Phase 6 ran:
voting_ran  = bool(glob.glob(p("04-voting", "*scores*.json"))
                   or glob.glob(p("04-voting", "matrix*.md")))

# Voting is EXPECTED when there's positive evidence of a full/voting run:
#   declared voting:true, declared mode:full, a jester is present, OR >=5 voter
#   proposals (lite=3, full=5/7 per spec — so 5+ ⇒ full ⇒ voting on). The
#   voter-count signal is the robust fallback when params are unrecorded and the
#   jester is numerically named (e.g. voter-5, not voter-jester). Lite/voting-off
#   is exempt.
full_by_count  = len(proposals) >= 5
voting_expected = (voting_cfg is True) or (mode == "full") or has_jester or full_by_count

crit, warn, ok = [], [], []

# ── A1: the voting gate (CRITICAL) ───────────────────────────────────────────
if voting_expected and not voting_ran and not no_voting:
    why = []
    if voting_cfg is True: why.append("meta params voting:true")
    if mode == "full":     why.append("mode:full")
    if has_jester:         why.append("a jester voter is present (⇒ full mode)")
    if full_by_count and not has_jester:
        why.append(f"{len(proposals)} voters (⇒ full mode; lite=3)")
    crit.append("VOTING SKIPPED without --no-voting — " + ", ".join(why) +
                ", but 04-voting/ has no scores/matrix. Phase-6 anonymized voting "
                "+ bias-matrix never ran. If convergence was genuine, run the vote "
                "to PROVE it (it's cheap once proposals exist); if you truly intend "
                "to skip, set --no-voting at dispatch — do not skip mid-run and cite "
                "Phase-8 'pick directly' (that step is POST-voting).")
elif voting_ran:
    ok.append("Phase-6 voting ran (scores/matrix present)")
elif no_voting:
    ok.append("voting intentionally off (--no-voting / voting:false) — exempt")
else:
    ok.append("voting not expected (lite/no-jester run)")

# ── Phase-2: params recorded (WARN) ──────────────────────────────────────────
if not params:
    warn.append("Phase-2 MISS: meta.json params{} empty — mode/voters/voting "
                "unrecorded; the run can't be audited from metadata.")
else:
    ok.append("Phase-2 params recorded")

# ── Phase-4: voter prompts persisted (WARN) ──────────────────────────────────
if not nonempty_dir("02-voter-prompts"):
    warn.append("Phase-4 MISS: 02-voter-prompts/ empty — no dispatched-prompt "
                "trail; anonymization/randomization/evidence-assignment unverifiable.")
else:
    ok.append("Phase-4 voter prompts persisted")

# ── Phase-11: finalized (WARN) ───────────────────────────────────────────────
if not meta.get("finished_at") or not (meta.get("totals") or {}):
    warn.append("Phase-11 MISS: meta.json finished_at/totals not finalized.")
else:
    ok.append("Phase-11 finalized")

# ── report ───────────────────────────────────────────────────────────────────
print("─" * 56)
print("  /magi conformance check")
print("─" * 56)
for c in crit: print("  \033[31m✗ CRITICAL\033[0m " + c)
for w in warn: print("  \033[33m⚠ warn\033[0m     " + w)
for o in ok:   print("  \033[32m✓\033[0m          " + o)
print("─" * 56)

# persist a conformance block into meta.json (best-effort, non-fatal)
try:
    meta["conformance"] = {"critical": crit, "warnings": warn, "passed": ok,
                           "verdict": "critical" if crit else ("warn" if warn else "ok")}
    with open(p("meta.json"), "w") as f: json.dump(meta, f, indent=2)
except Exception: pass

sys.exit(2 if crit else (1 if warn else 0))
PY
