#!/usr/bin/env bash
# Sum tokens × per-model rates from a magi archive's meta.json.
# Writes totals + cost_usd_est back into the meta.json. Prints JSON summary.
#
# The Agent tool's <usage> block only exposes total_tokens — no input/output
# split. We compute cost via a blended rate using an assumed input/output
# fraction. Override via env IO_SPLIT (e.g. "60/40"). Default 70/30 reflects
# research-heavy runs with cache hits.
#
# Usage: cost-estimate.sh <archive-root>

set -uo pipefail

ARCHIVE="${1:-}"
META="$ARCHIVE/meta.json"
[[ -f "$META" ]] || { printf 'no meta.json at %s\n' "$META" >&2; exit 2; }

IO_SPLIT_RAW="${IO_SPLIT:-70/30}"
IFS='/' read -r IO_IN IO_OUT <<<"$IO_SPLIT_RAW"

python3 - "$META" "$IO_IN" "$IO_OUT" <<'PY'
import json, sys
meta_path, io_in_s, io_out_s = sys.argv[1], sys.argv[2], sys.argv[3]
io_in_frac  = float(io_in_s) / 100.0
io_out_frac = float(io_out_s) / 100.0

with open(meta_path) as f: meta = json.load(f)

RATES = {
  "opus":   {"input": 15.00, "output": 75.00, "cache_read": 1.50},
  "sonnet": {"input": 3.00,  "output": 15.00, "cache_read": 0.30},
  "haiku":  {"input": 0.80,  "output": 4.00,  "cache_read": 0.08},
}

def blended_rate(model):
  # Rate per 1M tokens at the assumed input/output split. Cache is not modeled
  # here — total_tokens conflates everything; the blend approximates.
  r = RATES.get(model, RATES["opus"])
  return r["input"] * io_in_frac + r["output"] * io_out_frac

def cost_of(model, t):
  if t is None:
    return 0.0
  total = t.get("total_tokens")
  if total is not None:
    return total * blended_rate(model) / 1_000_000
  # Back-compat: if separate input/output present, use exact pricing.
  r = RATES.get(model, RATES["opus"])
  return (t.get("input", 0) * r["input"]
        + t.get("output", 0) * r["output"]
        + t.get("cache_read", 0) * r["cache_read"]) / 1_000_000

total_tokens_sum = 0
total_usd = 0.0
by_voter = []
by_model = {}
for v in meta.get("voters", []):
  t = v.get("tokens") or {}
  model = v.get("model", "opus")
  c = cost_of(model, t)
  total_usd += c
  total_tokens_sum += t.get("total_tokens", 0) or 0
  by_voter.append({"id": v.get("id"), "model": model, "usd": round(c, 4)})
  by_model.setdefault(model, 0.0)
  by_model[model] += c

meta.setdefault("totals", {})
meta["totals"].update({
  "total_tokens":  total_tokens_sum,
  "cost_usd_est":  round(total_usd, 4),
  "io_split":      f"{int(io_in_frac*100)}/{int(io_out_frac*100)}",
  "estimation":    "blended rate (total_tokens × weighted input+output); <usage> block lacks split",
})
with open(meta_path, "w") as f:
  json.dump(meta, f, indent=2)

print(json.dumps({
  "total_usd": round(total_usd, 4),
  "total_tokens": total_tokens_sum,
  "io_split": f"{int(io_in_frac*100)}/{int(io_out_frac*100)}",
  "by_model": {k: round(v, 4) for k, v in by_model.items()},
  "by_voter": by_voter,
}, indent=2))
PY

# Phase-11 conformance gate — rides on this MANDATORY cost step so it can't be
# skipped (advisory SKILL.md prose didn't bind; see rules/skill-spec-update-not-
# honored). Prints the verdict after the cost block; exits non-zero on a CRITICAL
# failure (e.g. full-mode voting skipped without --no-voting) so the supervisor
# and user must reckon with it before calling the run done.
CHK="$(dirname "$0")/conformance-check.sh"
if [ -x "$CHK" ]; then
  echo
  bash "$CHK" "$ARCHIVE"; conf_rc=$?
  [ "${conf_rc:-0}" -ge 2 ] && exit "$conf_rc"
fi
