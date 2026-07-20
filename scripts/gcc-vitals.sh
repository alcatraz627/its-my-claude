#!/usr/bin/env bash
# gcc-vitals.sh — the gcc's vital signs. DIRECTION, not defects.
#
# The gcc-map is an X-ray: a point-in-time scan for what is broken. This is an EKG:
# a continuous read of which way the living config is MOVING. Each vital prints an
# arrow (up/down/flat) + magnitude + a healthy-range note — never a pass/fail, because
# the number alone never decides whether growth is health or rot. A vital that
# thresholds into FAIL is a battery check; that is the map's job, not this.
#
# READ-ONLY. Computes four families from existing timestamped ledgers:
#   Learning  — atone mistakes/month, cluster drift
#   Metabolic — proposal backlog velocity, retirement-blind rule fraction
#   Growth    — rule count trajectory
#   Churn     — where edit-attention concentrates
#
# Usage: gcc-vitals.sh          human EKG
#        gcc-vitals.sh --json   one machine-readable object (for vitals/timeline.jsonl)
#
# Honest bounds: every "per month" figure is a raw count, not seasonally adjusted;
# a falling mistake rate can mean "learning worked" OR "atone used less" — a vital
# raises the question, it does not answer it. Absolutes are approximate; trust the
# direction, not the third digit.
set -uo pipefail

G="$HOME/.claude"
ATONE="${GCC_VITALS_ATONE:-$G/atone/events.jsonl}"
JSON=0; [ "${1:-}" = "--json" ] && JSON=1
# Heed-trend (from hooks/warn-events.jsonl, WS1's sensor) is a documented LEARNING
# vital, deliberately not computed yet: a trend needs weeks of accumulated heed
# lines, and Phase 1's instrument only just started producing them. Add it here once
# the data spans enough time to read a direction rather than a single noisy point.

# All the number-crunching + date math lives in Python (macOS bash 3.2 has no
# ergonomic date arithmetic). One temp script, per shell-safety + the very
# prefer-tmp-py nudge this arc instrumented.
PY="$(mktemp "${TMPDIR:-/tmp}/gcc-vitals-XXXXXX.py")"
trap 'rm -f "$PY"' EXIT
cat > "$PY" <<'PYEOF'
import json, sys, os, subprocess, re
from collections import Counter, defaultdict
from datetime import datetime, timezone

G = os.path.expanduser("~/.claude")
atone_path = sys.argv[1]; as_json = sys.argv[2] == "1"

def ym(s):  # "mist-YYYYMMDD-..." -> "YYYY-MM"
    m = re.search(r"(\d{4})(\d{2})\d{2}", s or "")
    return f"{m.group(1)}-{m.group(2)}" if m else None

# ---- Learning: atone mistakes/month + cluster drift ------------------------
months, clusters_recent, clusters_prior = Counter(), Counter(), Counter()
atone_rows = []
try:
    for line in open(atone_path):
        try: ev = json.loads(line)
        except Exception: continue
        atone_rows.append(ev)
        mo = ym(ev.get("id",""))
        if mo: months[mo] += 1
except FileNotFoundError:
    pass
month_keys = sorted(months)
last3 = month_keys[-3:]
# cluster drift: most recent month vs the one before
if len(month_keys) >= 2:
    recent_m, prior_m = month_keys[-1], month_keys[-2]
    for ev in atone_rows:
        mo = ym(ev.get("id","")); c = ev.get("cluster")
        if not c: continue
        if mo == recent_m: clusters_recent[c] += 1
        elif mo == prior_m: clusters_prior[c] += 1

# ---- Metabolic: backlog velocity + retirement-blind fraction ---------------
def prop_count(status):
    try:
        out = subprocess.run(["bash", f"{G}/scripts/propose.sh", "list", "--status", status],
                             capture_output=True, text=True, timeout=20).stdout
        return max(0, len([l for l in out.splitlines() if l.strip()]) - 1)  # minus header
    except Exception: return None
p_open, p_done, p_rej = prop_count("open"), prop_count("done"), prop_count("rejected")
metabolized = (p_done or 0) + (p_rej or 0)
total_props = metabolized + (p_open or 0)

# retirement-blind rules: no enforcing hook AND no atone/provenance lineage
def rule_files():
    rd = f"{G}/rules"
    return [f for f in os.listdir(rd) if f.endswith(".md") and f not in ("README.md","00-index.md")] if os.path.isdir(rd) else []
rules = rule_files()
blind = 0
signal_re = re.compile(r"enforced by|mechanically|hook.*block|guard-.*\.sh|-stop\.sh|graduated from atone|atone slug|Provenance", re.I)
for f in rules:
    try: txt = open(f"{G}/rules/{f}").read()
    except Exception: txt = ""
    if not signal_re.search(txt): blind += 1

# ---- Growth: rule count (trajectory needs history; report level + known map points)
rule_count = len(rules)

# ---- Churn: where edit-attention concentrates (last 200 commits) ------------
churn = Counter()
try:
    out = subprocess.run(["git","-C",G,"log","--oneline","-200","--name-only","--pretty=format:"],
                         capture_output=True, text=True, timeout=30).stdout
    for line in out.splitlines():
        line = line.strip()
        if not line: continue
        d = line.rsplit("/",1)[0] if "/" in line else "(root)"
        churn[d] += 1
except Exception: pass
top_churn = churn.most_common(5)

def arrow(cur, prev):
    if prev is None or cur is None: return "→"
    if cur > prev * 1.1: return "↑"
    if cur < prev * 0.9: return "↓"
    return "→"

if as_json:
    print(json.dumps({
        "learning": {"mistakes_by_month": dict((k, months[k]) for k in last3),
                     "cluster_recent": dict(clusters_recent), "cluster_prior": dict(clusters_prior)},
        "metabolic": {"open": p_open, "done": p_done, "rejected": p_rej,
                      "metabolized_frac": round(metabolized/total_props, 3) if total_props else None,
                      "rules_total": rule_count, "retirement_blind": blind,
                      "retirement_blind_frac": round(blind/rule_count, 3) if rule_count else None},
        "growth": {"rules": rule_count},
        "churn": {"top": top_churn},
    }))
    sys.exit()

# ---- human EKG -------------------------------------------------------------
def line(label, arrow_s, body, note):
    print(f"  {arrow_s} {label:<26} {body}")
    if note: print(f"      {note}")

print("─"*66)
print("  gcc vitals — direction, not defects (the map is the X-ray; this is the EKG)")
print("─"*66)

print("\n▸ LEARNING — is the config getting smarter?")
if len(last3) >= 2:
    vals = [months[k] for k in last3]
    a = arrow(vals[-1], vals[-2])
    line("mistakes / month", a, "  ".join(f"{k.split('-')[1]}:{months[k]}" for k in last3),
         "rising = new blind spots · falling = rules landing OR atone used less (a question, not a verdict)")
if clusters_recent or clusters_prior:
    rising = [c for c in clusters_recent if clusters_recent[c] > clusters_prior.get(c,0)]
    falling = [c for c in clusters_prior if clusters_prior[c] > clusters_recent.get(c,0)]
    line("cluster drift", "→", f"rising: {','.join(rising) or '—'}   falling: {','.join(falling) or '—'}",
         "which failure CLASSES dominate now vs last month")

print("\n▸ METABOLIC — is ingested material flowing or piling up?")
if total_props:
    frac = metabolized/total_props
    a = "↑" if frac >= 0.6 else ("→" if frac >= 0.4 else "↓")
    line("backlog throughput", a, f"{metabolized}/{total_props} metabolized ({frac*100:.0f}%), {p_open} open",
         "healthy ≳60% · proposals are the config's WORKING metabolic organ")
if rule_count:
    bf = blind/rule_count
    a = "↓" if bf < 0.2 else ("→" if bf < 0.35 else "↑")
    line("retirement-blind rules", a, f"{blind}/{rule_count} ({bf*100:.0f}%) have no signal",
         "rules with no hook + no atone lineage — cannot be evaluated for value. rising = adding unmeasurable prose")

print("\n▸ GROWTH — is the surface area sustainable?")
line("rules count", "→", f"{rule_count}  (map: v2=35 → v3=41 → now {rule_count})",
     "the recent dip = absorption happened. per-agent token cost rides this")

print("\n▸ CHURN — where is edit-attention actually going?")
for d, n in top_churn:
    print(f"    {n:>4}  {d}")
print("      the hottest surface. auto-generated learned-state here = code-history pollution (WS4)")
print()
PYEOF

python3 "$PY" "$ATONE" "$JSON"
