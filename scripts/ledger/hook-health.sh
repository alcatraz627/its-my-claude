#!/usr/bin/env bash
# hook-health.sh — the human lens on how every hook-gate is landing.
#
# Turns the accumulating hook-fire telemetry (~/.claude/hooks/warn-events.jsonl)
# into an at-a-glance per-hook health view: how often each gate fires, in what
# proportion of block/nudge/soft/muted, whether its nudges are being heeded, which
# project trips it most, how fresh the last fire is, and whether it is muted while
# still firing. This is what a human — or a scheduled review session three weeks
# out — runs to answer "which gates are noisy / effective?" as a query, not a dig.
#
# READ-ONLY. Sibling of ledger/efficacy.sh (the slug→gate recurrence lens); this is
# the raw-firing lens. It never writes to the warn stream, never mutates state.
#
# Data model (two line shapes in warn-events.jsonl):
#   fire:  {id?, ts, kind:"warn"?, hook_id, action:"block|nudge|soft|muted"?,
#           heeded, sid, cwd?, project?, target?, detail?}
#   heed:  {id, ts, kind:"heed", hook_id, ref, sid, cwd?}
#   The cwd/project/target/detail fields are NEW + OPTIONAL — a sibling is enriching
#   warn-log now, so most existing lines lack them. Absent → shown as "-". Legacy
#   lines (predating the `kind` field) carry no kind/action; they ARE fires and are
#   counted, with action bucketed as "?". Only kind:"heed" is excluded from fires.
#
# Heed model: heed-rate is computed from kind:"heed" lines joined to fires (per the
# telemetry contract), NOT from the fire's own write-time `heeded` field — that
# field is a placeholder default at fire time ("unknown" new, "false" legacy), a
# real heed OUTCOME only arrives as a later kind:"heed" line. So heed-rate reads "-"
# until heed lines accumulate, then gets real automatically.
#
# Test/isolation:
#   HOOK_HEALTH_WARN        relocate the warn stream (default ~/.claude/hooks/warn-events.jsonl)
#   HOOK_HEALTH_MUTE_ROOT   relocate the mute-file search root (default ~/.claude)
#   HOOK_HEALTH_NOW         fix "now" for deterministic relative ages / windows
set -uo pipefail

WARN="${HOOK_HEALTH_WARN:-$HOME/.claude/hooks/warn-events.jsonl}"
MUTE_ROOT="${HOOK_HEALTH_MUTE_ROOT:-$HOME/.claude}"
NOW="${HOOK_HEALTH_NOW:-$(date -u '+%Y-%m-%dT%H:%M:%SZ')}"

JSON=0; HOOK=""; SINCE=""; WITHIN=""; RECENT=20
while [ $# -gt 0 ]; do case "$1" in
  --json)    JSON=1; shift;;
  --hook)    HOOK="${2:-}"; shift 2;;
  --since)   SINCE="${2:-}"; shift 2;;
  --within)  WITHIN="${2:-}"; shift 2;;
  --recent)  RECENT="${2:-}"; shift 2;;
  -h|--help)
    cat <<'H'
hook-health — per-hook health from warn-events telemetry (read-only)

  hook-health.sh                 table: one row per hook, sorted by fires desc
  hook-health.sh --hook <id>     drill into one hook (recent fires, by-project, mute)
  hook-health.sh --since <ISO>   only fires at/after this UTC timestamp
  hook-health.sh --within <days> only fires in the last N days
  hook-health.sh --recent <N>    with --hook: how many recent fires to show (default 20)
  hook-health.sh --json          machine output

Columns: hook | fires | by-action | heed | top-project | last-fired | MUTED?
  heed  = heeded/(heeded+ignored) from kind:heed lines, or "-" if no heed data yet
  MUTED = the hook's mute file exists AND it is still firing (worth a look)
H
    exit 0;;
  *) shift;;
esac; done

# Empty / missing store → nothing to report.
if [ ! -s "$WARN" ]; then
  if [ "$JSON" = "1" ]; then echo '{"now":"'"$NOW"'","fires":0,"hooks":[],"note":"no telemetry yet"}'
  else echo "no telemetry yet ($WARN)"; fi
  exit 0
fi

python3 - "$NOW" "$WARN" "$MUTE_ROOT" "$JSON" "$HOOK" "$SINCE" "$WITHIN" "$RECENT" <<'PY'
import json, sys, os, datetime
from collections import Counter, defaultdict

now_s, warn_path, mute_root, json_s, hook, since_s, within_s, recent_s = sys.argv[1:9]
as_json  = json_s == "1"
recent_n = int(recent_s) if str(recent_s).isdigit() else 20

def parse_ts(s):
    try: return datetime.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
    except Exception: return None

now = parse_ts(now_s) or datetime.datetime.now(datetime.timezone.utc)

# Effective window start: explicit --since wins; else --within days back from now.
since = parse_ts(since_s) if since_s else None
if since is None and str(within_s).strip():
    try: since = now - datetime.timedelta(days=float(within_s))
    except Exception: since = None

# ─── mute-file resolution ────────────────────────────────────────
# Ground-truth map hook_id → mute file (relative to MUTE_ROOT). None = a hard gate
# with no session mute file (unmuteable by design). Unknown ids fall to a heuristic.
MUTE_MAP = {
    "prefer-tmp-py-over-inline": ".no-inline-py-hint",
    "guard-duplicate-symbol":    ".no-dup-symbol-guard",
    "guard-speculative-export":  ".no-speculative-export-gate",
    "guard-rg-replace-bundle":   ".no-rg-replace-guard",
    "guard-cluster-e-smells":    ".no-cluster-e-nudge",
    "persona-suggest":           "personas/usage/.suggest-off",
    "prefer-glob-over-find":     ".no-find-hint",
    "warn-git-add-enumeration":  "atone/.add-warn-off",
    "guard-env-access":          ".env-access-off",
    "guard-subagent-output":     ".subagent-output-off",
    "warn-kill-9":               ".no-kill-9-hint",
    "guard-comment-verbosity":   ".no-comment-verbosity-gate",
    # hard gates — no per-session mute file:
    "cli-gating":     None, "prefer-ripgrep": None, "safe-delete": None,
    "protect-atone-raw": None, "telemetry-selftest": None,
}
def mute_candidates(hid):
    slugs = [hid]
    for p in ("guard-", "warn-", "prefer-"):
        if hid.startswith(p): slugs.append(hid[len(p):])
    seen, out = set(), []
    for s in slugs:
        for c in (f".no-{s}-gate", f".no-{s}-hint", f".no-{s}-guard",
                  f".no-{s}-nudge", f".{s}-off", f".no-{s}"):
            if c not in seen: seen.add(c); out.append(c)
    return out
def resolve_mute(hid):
    # returns (mute_path_or_None, is_muted, is_hard_gate)
    if hid in MUTE_MAP:
        rel = MUTE_MAP[hid]
        if rel is None: return (None, False, True)
        p = os.path.join(mute_root, rel)
        return (rel, os.path.exists(p), False)
    for c in mute_candidates(hid):
        if os.path.exists(os.path.join(mute_root, c)):
            return (c, True, False)
    cand = mute_candidates(hid)
    return ((cand[0] if cand else None), False, False)

# ─── load telemetry ──────────────────────────────────────────────
fires = []   # each: dict with ts, hook_id, action, project, target, detail, id, heeded
heeds = []   # each: dict with ts, hook_id, ref
malformed = 0
try:
    fh = open(warn_path)
except Exception:
    fh = []
for line in fh:
    line = line.strip()
    if not line: continue
    try: d = json.loads(line)
    except Exception: malformed += 1; continue
    if not isinstance(d, dict): malformed += 1; continue
    t = parse_ts(d.get("ts", ""))
    if t is None: malformed += 1; continue
    kind = d.get("kind")
    hid  = d.get("hook_id") or ""
    if not hid: malformed += 1; continue
    if kind == "heed":
        heeds.append({"ts": t, "hook_id": hid, "ref": d.get("ref", ""),
                      "heeded": str(d.get("heeded", "")).lower()})
        continue
    # any non-heed line with a hook_id is a fire (legacy lines have no `kind`)
    fires.append({"ts": t, "hook_id": hid,
                  "action":  d.get("action") or "?",
                  "project": d.get("project") or "",
                  "target":  d.get("target") or "",
                  "detail":  d.get("detail") or "",
                  "id":      d.get("id") or "",
                  "heeded":  str(d.get("heeded", "")).lower()})

def in_window(ev): return since is None or ev["ts"] >= since
fires_w = [f for f in fires if in_window(f)]
heeds_w = [h for h in heeds if in_window(h)]

HEED_YES = {"yes", "heeded", "true", "1", ""}   # a bare heed line (no verdict) = a heed happened
HEED_NO  = {"no", "ignored", "false", "0"}

def humanize_age(dt):
    secs = (now - dt).total_seconds()
    if secs < 0: secs = 0
    if secs < 90:        return "just now"
    if secs < 3600:      return f"{int(secs//60)}m"
    if secs < 86400:     return f"{int(secs//3600)}h"
    if secs < 7*86400:   return f"{int(secs//86400)}d"
    if secs < 60*86400:  return f"{int(secs//(7*86400))}w"
    return f"{int(secs//(30*86400))}mo"

ACTION_ORDER = ["block", "nudge", "soft", "muted", "?"]
def by_action_str(counter):
    parts = [f"{a}:{counter[a]}" for a in ACTION_ORDER if counter.get(a)]
    for a in sorted(counter):  # any action value we didn't anticipate
        if a not in ACTION_ORDER and counter[a]: parts.append(f"{a}:{counter[a]}")
    return " ".join(parts) if parts else "-"

def heed_rate_for(hook_id, heed_list):
    yes = no = 0
    for h in heed_list:
        if h["hook_id"] != hook_id: continue
        v = h["heeded"]
        if v in HEED_NO: no += 1
        elif v in HEED_YES: yes += 1
    if yes + no == 0: return None, yes, no
    return yes / (yes + no), yes, no

# ─── per-hook aggregation ────────────────────────────────────────
def build_rows(fire_list, heed_list):
    hooks = defaultdict(lambda: {"fires": 0, "actions": Counter(), "projects": Counter(),
                                 "last": None})
    for f in fire_list:
        h = hooks[f["hook_id"]]
        h["fires"] += 1
        h["actions"][f["action"]] += 1
        if f["project"]: h["projects"][f["project"]] += 1
        if h["last"] is None or f["ts"] > h["last"]: h["last"] = f["ts"]
    rows = []
    for hid, h in hooks.items():
        rate, hy, hn = heed_rate_for(hid, heed_list)
        mute_path, muted, hard = resolve_mute(hid)
        top_proj = h["projects"].most_common(1)[0][0] if h["projects"] else "-"
        rows.append({
            "hook": hid, "fires": h["fires"],
            "by_action": dict(h["actions"]),
            "by_action_str": by_action_str(h["actions"]),
            "heed_rate": None if rate is None else round(rate, 2),
            "heed_yes": hy, "heed_no": hn,
            "heed_str": "-" if rate is None else f"{hy}/{hy+hn}",
            "top_project": top_proj,
            "last_ts": h["last"].strftime("%Y-%m-%dT%H:%M:%SZ") if h["last"] else None,
            "last_age": humanize_age(h["last"]) if h["last"] else "-",
            "mute_path": mute_path, "muted": muted, "hard_gate": hard,
        })
    rows.sort(key=lambda r: (-r["fires"], r["hook"]))
    return rows

# ─── --hook drill-down ───────────────────────────────────────────
if hook:
    hf = [f for f in fires_w if f["hook_id"] == hook]
    mute_path, muted, hard = resolve_mute(hook)
    rate, hy, hn = heed_rate_for(hook, heeds_w)
    proj = Counter(f["project"] for f in hf if f["project"])
    recent = sorted(hf, key=lambda f: f["ts"], reverse=True)[:recent_n]
    if as_json:
        print(json.dumps({
            "hook": hook, "now": now_s, "since": since.strftime("%Y-%m-%dT%H:%M:%SZ") if since else None,
            "fires": len(hf), "by_action": dict(Counter(f["action"] for f in hf)),
            "heed_rate": None if rate is None else round(rate, 2), "heed_yes": hy, "heed_no": hn,
            "mute_path": mute_path, "muted": muted, "hard_gate": hard,
            "by_project": dict(proj),
            "recent": [{"ts": f["ts"].strftime("%Y-%m-%dT%H:%M:%SZ"), "action": f["action"],
                        "project": f["project"] or "-", "target": f["target"] or "-",
                        "detail": (f["detail"] or "-")} for f in recent],
        }, indent=2))
        sys.exit(0)
    win = f"since {since.strftime('%Y-%m-%d %H:%M')}Z" if since else "all time"
    if not hf:
        print(f"hook: {hook}  —  no fires ({win})")
        if hard: print("mute: (hard gate — no session mute file)")
        elif mute_path: print(f"mute: ~/.claude/{mute_path}  ({'EXISTS → MUTED' if muted else 'not present'})")
        sys.exit(0)
    print(f"hook: {hook}   ·   {len(hf)} fires   ·   {win}   ·   last {humanize_age(hf and max(hf,key=lambda x:x['ts'])['ts'])}")
    ba = Counter(f["action"] for f in hf)
    print(f"by-action:  {by_action_str(ba)}")
    if hard:            print(f"mute:       (hard gate — no session mute file)")
    elif muted:        print(f"mute:       ~/.claude/{mute_path}  ⚠ MUTED (file exists) — still firing")
    elif mute_path:    print(f"mute:       ~/.claude/{mute_path}  (not present → active)")
    print(f"heed:       " + ("no heed data yet" if rate is None else f"{hy}/{hy+hn} = {round(rate*100)}%  (from {hy+hn} heed lines)"))
    print()
    print("by-project:")
    if proj:
        for p, c in proj.most_common():
            print(f"  {c:>4}  {p}")
    else:
        print("  -  (no project field on any fire yet)")
    print()
    print(f"recent fires (last {min(recent_n, len(hf))}):")
    print(f"  {'ts':<20} {'action':<8} {'project':<16} {'target':<20} detail")
    for f in recent:
        tgt = (f["target"] or "-"); det = (f["detail"] or "-")
        if len(tgt) > 20: tgt = tgt[:19] + "…"
        if len(det) > 40: det = det[:39] + "…"
        pj = (f["project"] or "-")
        if len(pj) > 16: pj = pj[:15] + "…"
        print(f"  {f['ts'].strftime('%Y-%m-%dT%H:%M:%SZ'):<20} {f['action']:<8} {pj:<16} {tgt:<20} {det}")
    sys.exit(0)

# ─── default table ───────────────────────────────────────────────
rows = build_rows(fires_w, heeds_w)

if as_json:
    print(json.dumps({
        "now": now_s, "since": since.strftime("%Y-%m-%dT%H:%M:%SZ") if since else None,
        "total_fires": len(fires_w), "total_hooks": len(rows),
        "malformed_skipped": malformed,
        "muted_but_firing": [r["hook"] for r in rows if r["muted"]],
        "hooks": rows,
    }, indent=2))
    sys.exit(0)

if not rows:
    win = f" since {since.strftime('%Y-%m-%d')}" if since else ""
    print(f"no fires in window{win}")
    sys.exit(0)

def cell(v, w, right=False):
    s = "" if v is None else str(v)
    if len(s) > w: s = s[:w-1] + "…"
    return s.rjust(w) if right else s.ljust(w)

HK, FR, BA, HD, PJ, LF, MU = 28, 5, 22, 6, 14, 8, 6
hdr = (cell("hook", HK) + "  " + cell("fires", FR, True) + "  " + cell("by-action", BA) + "  " +
       cell("heed", HD) + "  " + cell("top-project", PJ) + "  " + cell("last", LF, True) + "  " + cell("mute", MU))
win = since.strftime('%Y-%m-%d %H:%M') + "Z → now" if since else "all time"
print(f"hook health  ·  now={now.strftime('%Y-%m-%d %H:%M')}Z  ·  window={win}  ·  {len(fires_w)} fires across {len(rows)} hooks")
print(f"heed = heeded/(heeded+ignored) from kind:heed lines (\"-\" = none yet)  ·  MUTED = mute file exists while still firing")
print(hdr)
print("-" * len(hdr))
for r in rows:
    mflag = "MUTED" if r["muted"] else ""
    print(cell(r["hook"], HK) + "  " + cell(r["fires"], FR, True) + "  " +
          cell(r["by_action_str"], BA) + "  " + cell(r["heed_str"], HD) + "  " +
          cell(r["top_project"], PJ) + "  " + cell(r["last_age"], LF, True) + "  " + cell(mflag, MU))
print("-" * len(hdr))
n_muted = sum(1 for r in rows if r["muted"])
hottest = rows[0]["hook"] if rows else "-"
extra = f"  ·  {malformed} malformed skipped" if malformed else ""
mnote = f"  ·  {n_muted} MUTED-but-firing" if n_muted else ""
print(f"{len(rows)} hooks  ·  {len(fires_w)} fires  ·  hottest: {hottest} ({rows[0]['fires']}){mnote}{extra}")
PY
