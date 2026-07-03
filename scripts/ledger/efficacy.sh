#!/usr/bin/env bash
# efficacy.sh — the human lens on gate efficacy (P3.5).
#
# Answers, for every slug→gate mapping in ledger/efficacy.toml: after the gate
# deployed, did the atone slug's recurrence-rate actually drop? Prints a table of
# pre-rate vs post-rate (events per 30 days), the window maturity, a status
# (insufficient-data / improving / flat / regressing), and — where the gate emits
# telemetry — its fire and heed counts in the post window.
#
# READ-ONLY. This is the /doctor + ad-hoc surface; it never writes alerts, never
# mutates state, never files a proposal. The alerting half lives in the
# gate-efficacy archetype of evaluate-detectors.sh, which shares this exact
# pre/post/status math. Keep the two in lockstep if either changes.
#
# Test/isolation:
#   LEDGER_DIR              relocates the registry (default ~/.claude/ledger)
#   LEDGER_NOW              fixes "now" for deterministic windows
#   EFFICACY_ATONE_STREAM   the atone ledger to count on (default the real one; set
#                           in tests so the real protected log is never touched)
#   EFFICACY_WARN_STREAM    the hook warn stream for telemetry enrichment
#
# The atone path is resolved INSIDE this script, never passed on the command line,
# so running `bash efficacy.sh` does not trip protect-atone-raw.sh.
set -uo pipefail

LEDGER_DIR="${LEDGER_DIR:-$HOME/.claude/ledger}"
REGISTRY="$LEDGER_DIR/efficacy.toml"
DETECTORS="$LEDGER_DIR/detectors.toml"
ATONE="${EFFICACY_ATONE_STREAM:-$HOME/.claude/atone/events.jsonl}"
WARN="${EFFICACY_WARN_STREAM:-$HOME/.claude/hooks/warn-events.jsonl}"
NOW="${LEDGER_NOW:-$(date -u '+%Y-%m-%dT%H:%M:%SZ')}"

JSON=0
[ "${1:-}" = "--json" ] && JSON=1

command -v yq >/dev/null 2>&1 || { echo "efficacy: yq required" >&2; exit 1; }
[ -f "$REGISTRY" ] || { echo "efficacy: no registry at $REGISTRY" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
yq -p toml -o json "$REGISTRY"  > "$TMP/reg.json" 2>/dev/null || echo '{}' > "$TMP/reg.json"
yq -p toml -o json "$DETECTORS" > "$TMP/det.json" 2>/dev/null || echo '{}' > "$TMP/det.json"

python3 - "$NOW" "$TMP/reg.json" "$TMP/det.json" "$ATONE" "$WARN" "$JSON" <<'PY'
import json, sys, os, datetime

now   = datetime.datetime.strptime(sys.argv[1], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
reg   = json.load(open(sys.argv[2]))
det   = json.load(open(sys.argv[3]))
atone_path = sys.argv[4]
warn_path  = sys.argv[5]
as_json    = sys.argv[6] == "1"

# Pull the shared params from the gate-efficacy detector so the lens and the
# alerting detector agree by construction; fall back to the documented defaults.
eff_det = next((d for d in det.get("detector", []) if d.get("archetype") == "efficacy"), {})
MIN_WINDOW = int(eff_det.get("min_window_days", 21))
PRE_DAYS   = int(eff_det.get("pre_window_days", 90))
MARGIN     = float(eff_det.get("margin", 0.15))

def parse_ts(s):
    try: return datetime.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
    except Exception: return None
def parse_date(s):
    if not s: return None
    try: return datetime.datetime.strptime(str(s), "%Y-%m-%d").replace(tzinfo=datetime.timezone.utc)
    except Exception: return None

atone_ev = []
if os.path.exists(atone_path):
    for line in open(atone_path):
        line = line.strip()
        if not line: continue
        try: d = json.loads(line)
        except Exception: continue
        t = parse_ts(d.get("ts", ""))
        if t is None: continue
        atone_ev.append((t, d.get("slug"), d.get("cluster")))
warn_ev = []
if os.path.exists(warn_path):
    for line in open(warn_path):
        line = line.strip()
        if not line: continue
        try: d = json.loads(line)
        except Exception: continue
        # Fires only: kind:"heed" resolutions share the hook_id but are responses
        # to a fire, not fires — counting them would double every heeded event.
        if d.get("kind") != "warn": continue
        t = parse_ts(d.get("ts", ""))
        if t is None: continue
        warn_ev.append((t, d.get("hook_id", "") or "", d.get("heeded", "unknown")))

HEED_YES = {"yes", "heeded", "true", "1"}
HEED_NO  = {"no", "ignored", "false", "0"}
rows = []
for m in reg.get("mapping", []):
    slug = m.get("slug", "?"); gate = m.get("gate", "?")
    conf = (m.get("confidence", "high") or "high").lower()
    mfield = m.get("match_field", "slug"); mval = m.get("match_value", slug)
    dep = parse_date(m.get("deployed")); redep = parse_date(m.get("redeployed"))
    if dep is None:
        rows.append({"slug": slug, "gate": gate, "confidence": conf, "deployed": m.get("deployed"),
                     "status": "lint:bad-deployed", "pre_rate_30d": None, "post_rate_30d": None,
                     "window_days": None, "gate_fires_post": 0, "gate_heeded_post": "?"})
        continue
    eff = redep if (redep and redep > dep) else dep

    def matches(ev, _mf=mfield, _mv=mval):
        return (ev[2] == _mv) if _mf == "cluster" else (ev[1] == _mv)

    pre_start = dep - datetime.timedelta(days=PRE_DAYS)
    pre_c  = sum(1 for ev in atone_ev if pre_start <= ev[0] < dep and matches(ev))
    post_c = sum(1 for ev in atone_ev if ev[0] >= eff and matches(ev))
    post_days = (now - eff).days
    pre_rate  = pre_c / PRE_DAYS * 30.0
    post_rate = (post_c / post_days * 30.0) if post_days > 0 else 0.0

    wprefix = m.get("warn_prefix", "")
    g_fires = g_heeded = g_known = 0
    if wprefix:
        for (t, hid, heeded) in warn_ev:
            if t >= eff and hid.startswith(wprefix):
                g_fires += 1
                hl = str(heeded).lower()
                if hl in HEED_YES: g_heeded += 1; g_known += 1
                elif hl in HEED_NO: g_known += 1
    heed_str = f"{g_heeded}/{g_known}" if g_known else "-"

    if post_days < MIN_WINDOW:
        status = "insufficient-data"
    elif post_c == 0:
        status = "improving"
    elif pre_rate == 0:
        status = "regressing" if post_c > 0 else "flat"
    elif post_rate <= pre_rate * (1 - MARGIN):
        status = "improving"
    elif post_rate >= pre_rate:
        status = "regressing"
    else:
        status = "flat"

    would_alert = (status == "regressing" and post_days >= MIN_WINDOW and conf == "high")
    rows.append({"slug": slug, "gate": gate, "confidence": conf, "deployed": m.get("deployed"),
                 "redeployed": m.get("redeployed"), "effective": eff.strftime("%Y-%m-%d"),
                 "pre_rate_30d": round(pre_rate, 2), "post_rate_30d": round(post_rate, 2),
                 "pre_count": pre_c, "post_count": post_c, "window_days": post_days,
                 "status": status, "would_alert": would_alert,
                 "gate_fires_post": g_fires, "gate_heeded_post": heed_str,
                 "match_field": mfield, "match_value": mval})

if as_json:
    print(json.dumps({"now": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
                      "params": {"min_window_days": MIN_WINDOW, "pre_window_days": PRE_DAYS, "margin": MARGIN},
                      "rows": rows}, indent=2))
    sys.exit(0)

# ---- human table ----
def cell(v, w, right=False):
    s = "" if v is None else str(v)
    if len(s) > w: s = s[:w-1] + "…"
    return s.rjust(w) if right else s.ljust(w)

SLUG_W, GATE_W = 40, 26
hdr = (cell("slug", SLUG_W) + "  " + cell("gate", GATE_W) + "  " + cell("cf", 4) + "  " +
       cell("effective", 11) + "  " + cell("pre", 5, True) + "  " + cell("post", 5, True) + "  " +
       cell("win", 4, True) + "  " + cell("status", 17) + "  " + cell("fires", 5, True) + "  " + cell("heed", 5))
print(f"gate efficacy  ·  now={now.strftime('%Y-%m-%d')}  ·  min_window={MIN_WINDOW}d  pre_window={PRE_DAYS}d  margin={MARGIN}")
print(f"rates are events per 30 days  ·  effective=post-window start (max of deploy/redeploy; * = redeploy overrode)")
print(f"[P]=provisional (informational, never alerts)  ·  (!)=would alert")
print(hdr)
print("-" * len(hdr))
order = {"regressing": 0, "flat": 1, "insufficient-data": 2, "improving": 3}
for r in sorted(rows, key=lambda x: (order.get(x["status"], 9), x["slug"])):
    cf = "P" if r["confidence"] != "high" else " "
    st = r["status"] + (" (!)" if r.get("would_alert") else "")
    effc = (r.get("effective") or r.get("deployed") or "")
    if r.get("redeployed"): effc += "*"
    print(cell(r["slug"], SLUG_W) + "  " + cell(r["gate"], GATE_W) + "  " + cell(cf, 4) + "  " +
          cell(effc, 11) + "  " + cell(r["pre_rate_30d"], 5, True) + "  " +
          cell(r["post_rate_30d"], 5, True) + "  " + cell(r["window_days"], 4, True) + "  " +
          cell(st, 17) + "  " + cell(r["gate_fires_post"], 5, True) + "  " + cell(r["gate_heeded_post"], 5))

n_alert = sum(1 for r in rows if r.get("would_alert"))
n_imm   = sum(1 for r in rows if r["status"] == "insufficient-data")
print("-" * len(hdr))
print(f"{len(rows)} mappings  ·  {n_alert} would-alert (regressing+mature+high)  ·  {n_imm} insufficient-data")
PY
