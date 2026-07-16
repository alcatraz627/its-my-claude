#!/usr/bin/env bash
# Sum tokens × per-model rates from a magi archive's meta.json.
# Writes totals + cost_usd_est back into the meta.json. Prints JSON summary.
#
# The Agent tool's <usage> block only exposes total_tokens — no input/output
# split. We compute cost via a blended rate using an assumed input/output
# fraction. Override via env IO_SPLIT (e.g. "60/40"). Default 70/30 reflects
# research-heavy runs with cache hits.
#
# Usage: cost-estimate.sh <archive-root> [--io-split A/B]
#   --io-split A/B   assumed input/output percentages (also: IO_SPLIT env)

set -uo pipefail

ARCHIVE=""
IO_SPLIT_RAW="${IO_SPLIT:-70/30}"

# The magi spec (SKILL.md Phase 4.2) tells callers to override the split with
# --io-split A/B. That flag was documented but never parsed: the script read only
# $1, so the flag landed in $2 and was discarded without a word, and the caller got
# default-split numbers while believing it had asked for something else. Accept it,
# keep IO_SPLIT working, and refuse anything unrecognized rather than ignore it.
while [[ $# -gt 0 ]]; do
  case "$1" in
    # Guard the value's presence before `shift 2`: with one arg left the shift
    # fails, and without `set -e` the loop simply never advances — a bare
    # trailing --io-split hangs forever instead of complaining.
    --io-split)
      [[ $# -ge 2 ]] || { printf -- '--io-split needs a value like 70/30\n' >&2; exit 2; }
      IO_SPLIT_RAW="$2"; shift 2 ;;
    --io-split=*) IO_SPLIT_RAW="${1#*=}"; shift ;;
    -h|--help) printf 'Usage: cost-estimate.sh <archive-root> [--io-split A/B]\n'; exit 0 ;;
    -*) printf 'unknown option: %s\n' "$1" >&2; exit 2 ;;
    *) [[ -z "$ARCHIVE" ]] && ARCHIVE="$1" || { printf 'unexpected argument: %s\n' "$1" >&2; exit 2; }; shift ;;
  esac
done

META="$ARCHIVE/meta.json"
[[ -f "$META" ]] || { printf 'no meta.json at %s\n' "$META" >&2; exit 2; }

case "$IO_SPLIT_RAW" in
  [0-9]*/[0-9]*) ;;
  *) printf 'bad --io-split %s — want two numbers like 70/30\n' "$IO_SPLIT_RAW" >&2; exit 2 ;;
esac
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
n_voters = 0
n_unmeasured = 0
for v in meta.get("voters", []):
  t = v.get("tokens") or {}
  model = v.get("model", "opus")
  c = cost_of(model, t)
  total_usd += c
  total_tokens_sum += t.get("total_tokens", 0) or 0
  # A voter whose usage never reached us contributes 0 to both sums above. That
  # is arithmetic, not evidence: a run whose voters all went unmeasured priced
  # itself at $0.00, which reads as "this was free" rather than "nobody looked".
  # Count them so the totals can say which one it is.
  n_voters += 1
  if t.get("total_tokens") is None:
    n_unmeasured += 1
  by_voter.append({"id": v.get("id"), "model": model, "usd": round(c, 4),
                   "measured": t.get("total_tokens") is not None})
  by_model.setdefault(model, 0.0)
  by_model[model] += c

measured = n_voters - n_unmeasured
if n_unmeasured == 0:
  coverage = "complete"
elif measured == 0:
  coverage = "none — every voter unmeasured; the cost below is NOT a real number"
else:
  coverage = f"partial — {measured}/{n_voters} voters measured; cost is a floor"

meta.setdefault("totals", {})
meta["totals"].update({
  "total_tokens":  total_tokens_sum,
  "cost_usd_est":  round(total_usd, 4),
  "io_split":      f"{int(io_in_frac*100)}/{int(io_out_frac*100)}",
  "estimation":    "blended rate (total_tokens × weighted input+output); <usage> block lacks split",
  "voters_measured":   measured,
  "voters_unmeasured": n_unmeasured,
  "coverage":          coverage,
})
with open(meta_path, "w") as f:
  json.dump(meta, f, indent=2)

print(json.dumps({
  "total_usd": round(total_usd, 4),
  "total_tokens": total_tokens_sum,
  "io_split": f"{int(io_in_frac*100)}/{int(io_out_frac*100)}",
  "coverage": coverage,
  "voters_measured": measured,
  "voters_unmeasured": n_unmeasured,
  "by_model": {k: round(v, 4) for k, v in by_model.items()},
  "by_voter": by_voter,
}, indent=2))

if n_unmeasured:
  print(f"\n!! {n_unmeasured}/{n_voters} voters reported no usage — the cost above "
        f"is a floor, not the bill.", file=sys.stderr)
  if measured == 0:
    print("!! Every voter went unmeasured, so this run priced itself at $0.00. It was "
          "not free.\n!! Usual cause: voters dispatched as background teammates or over "
          "the mailbox.\n!! The magi spec dispatches voters with parallel Agent tool "
          "calls (SKILL.md Phase 4/6), whose\n!! <usage> block is what carries the "
          "tokens; a teammate transport exposes none.", file=sys.stderr)
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
exit 0   # clean/warn finalize succeeds — without this the trailing test would leak exit 1
