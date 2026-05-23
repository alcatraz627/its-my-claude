#!/usr/bin/env bash
# scripts/magi/aggregate-votes.sh — Aggregate N voter score JSONs into
# matrix.md + bias-matrix.md per design doc § 8.
#
# Reads: <archive>/04-voting/voter-*-scores.json
# Writes: <archive>/04-voting/matrix.md, <archive>/04-voting/bias-matrix.md
# Prints: winner voter_id + score-std-dev on scope axis (for scope-dissent check)

set -uo pipefail

ARCHIVE="${1:-}"
[[ -d "$ARCHIVE/04-voting" ]] || { printf 'archive missing or no 04-voting/: %s\n' "$ARCHIVE" >&2; exit 2; }

python3 - "$ARCHIVE" <<'PY'
import json, os, sys, glob, statistics
arc = sys.argv[1]
vote_dir = os.path.join(arc, "04-voting")
files = sorted(glob.glob(os.path.join(vote_dir, "voter-*-scores.json")))
if not files:
  print("no voter score files found", file=sys.stderr); sys.exit(2)

# Collect all voter IDs (union of voter_ids in score files + own ids)
all_voters = set()
scores = {}  # voter_id -> {target_voter_id -> {axis: val}}
for f in files:
  try:
    with open(f) as fp: d = json.load(fp)
  except Exception as e:
    print(f"skip {f}: {e}", file=sys.stderr); continue
  vid = d.get("voter_id")
  if not vid:
    print(f"skip {f}: no voter_id", file=sys.stderr); continue
  all_voters.add(vid)
  for target, axes in d.get("scores", {}).items():
    all_voters.add(target)
  scores[vid] = d.get("scores", {})

voters = sorted(all_voters)

# Pick axes from first available row
sample = next(iter(next(iter(scores.values()), {}).values()), {})
axes = [k for k in sample.keys() if k != "justification"]

def avg(xs):
  xs = [x for x in xs if x is not None]
  return statistics.mean(xs) if xs else 0.0

# matrix.md — for each (voter, target_voter), weighted-total score
matrix_rows = []
header = ["voter↓ / proposal→"] + voters
matrix_rows.append(header)
for v in voters:
  row = [v]
  for t in voters:
    val = scores.get(v, {}).get(t, {})
    if not val:
      row.append("—")
    else:
      # weighted by equal axes (no rubric weights here; supervisor can re-weight)
      vals = [val.get(a) for a in axes if isinstance(val.get(a), (int, float))]
      row.append(f"{avg(vals):.2f}" if vals else "—")
  matrix_rows.append(row)

# Per-proposal aggregate (across voters)
prop_avgs = {}
for t in voters:
  per_voter = []
  for v in voters:
    val = scores.get(v, {}).get(t, {})
    vals = [val.get(a) for a in axes if isinstance(val.get(a), (int, float))]
    if vals: per_voter.append(avg(vals))
  prop_avgs[t] = avg(per_voter) if per_voter else 0.0

winner = max(prop_avgs.items(), key=lambda kv: kv[1])

# scope-axis analysis (P0-A fix: was measuring voter self-strictness; now measures
# cross-voter disagreement about each proposal's scope, then takes max across proposals).
# Per Q6 — capture BOTH absolute mean AND cross-voter std for each proposal.
scope_std = None  # max across proposals of (cross-voter std on scope axis)
scope_abs = None  # max across proposals of (mean cross-voter score on scope axis)
scope_per_proposal = {}  # {proposal_id: {"mean": x, "pstdev": y}}
if "scope_alignment" in axes:
  for t in voters:  # for each proposal
    peer_scores_for_t = []
    for v in voters:  # for each voter scoring it
      sc = scores.get(v, {}).get(t, {}).get("scope_alignment")
      if isinstance(sc, (int, float)):
        peer_scores_for_t.append(sc)
    if len(peer_scores_for_t) >= 2:
      m = statistics.mean(peer_scores_for_t)
      sd = statistics.pstdev(peer_scores_for_t)
      scope_per_proposal[t] = {"mean": round(m, 3), "pstdev": round(sd, 3)}
  if scope_per_proposal:
    scope_std = max(v["pstdev"] for v in scope_per_proposal.values())
    scope_abs = max(v["mean"] for v in scope_per_proposal.values())

# Write matrix.md
with open(os.path.join(vote_dir, "matrix.md"), "w") as f:
  f.write("# Vote matrix\n\n")
  f.write("| " + " | ".join(matrix_rows[0]) + " |\n")
  f.write("|" + "---|" * len(matrix_rows[0]) + "\n")
  for row in matrix_rows[1:]:
    f.write("| " + " | ".join(row) + " |\n")
  f.write("\n## Per-proposal weighted average\n\n")
  for t, sc in sorted(prop_avgs.items(), key=lambda kv: -kv[1]):
    f.write(f"- **{t}** — {sc:.2f}\n")
  f.write(f"\n**Winner:** {winner[0]} ({winner[1]:.2f})\n")

# Write bias-matrix.md
bias = []
for v in voters:
  self_score = prop_avgs.get(v, 0.0)  # peers + self avg
  # peer_only = mean of OTHER voters' scores of v
  peer_vals = []
  for vv in voters:
    if vv == v: continue
    val = scores.get(vv, {}).get(v, {})
    vals = [val.get(a) for a in axes if isinstance(val.get(a), (int, float))]
    if vals: peer_vals.append(avg(vals))
  own_score_of_self = avg([scores.get(v, {}).get(v, {}).get(a) for a in axes if isinstance(scores.get(v, {}).get(v, {}).get(a), (int, float))])
  peer_avg = avg(peer_vals) if peer_vals else 0.0
  delta = own_score_of_self - peer_avg
  bias.append((v, own_score_of_self, peer_avg, delta))

with open(os.path.join(vote_dir, "bias-matrix.md"), "w") as f:
  f.write("# Self-bias asymmetry matrix\n\n")
  f.write("| Voter | Own→Self | Peers→Voter | Self-bias (Δ) | Read |\n")
  f.write("|---|---|---|---|---|\n")
  for v, own, peer, d in bias:
    if d > 1.5:    read = "🟥 HIGH — defensive OR unique insight; supervisor must cite specific reasoning"
    elif d > 0.5:  read = "🟨 moderate"
    elif d < -0.5: read = "🟦 humble — likely well-calibrated"
    else:          read = "⬜ normal"
    f.write(f"| {v} | {own:.2f} | {peer:.2f} | {d:+.2f} | {read} |\n")
  f.write("\nDelta > +1.5 = potential defense or unique insight. Delta < -0.5 = humble; high-info if peer scores high. Supervisor MUST cite reasoning when ruling in favor of a high-bias voter.\n")

# Voter-drop reporting (P0-B fix: was silent; now explicit)
voters_expected = len(voters)
voters_scored = len(scores)
voters_dropped = voters_expected - voters_scored

# Report
out = {
  "winner": winner[0],
  "winner_score": round(winner[1], 3),
  "voters_expected": voters_expected,
  "voters_scored": voters_scored,
  "voters_dropped": voters_dropped,
  "scope_axis_pstdev_max": round(scope_std, 3) if scope_std is not None else None,
  "scope_axis_abs_max": round(scope_abs, 3) if scope_abs is not None else None,
  "scope_per_proposal": scope_per_proposal,
  "scope_dissent_flagged": scope_std is not None and scope_std > 1.5,
  "matrix_path": os.path.join(vote_dir, "matrix.md"),
  "bias_matrix_path": os.path.join(vote_dir, "bias-matrix.md"),
  "warnings": (["DROPPED %d voter(s) — see stderr" % voters_dropped] if voters_dropped else []),
}
print(json.dumps(out, indent=2))
PY
