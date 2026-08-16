#!/usr/bin/env bash
# gcc-explore.sh — sit down with the gcc and look around.
#
# The map is the X-ray (what is broken). Vitals are the EKG (which way it moves).
# This is neither: it is the room itself, rendered so a human can FEEL the shape,
# the movement, and the cycle of the config they live in. It adjudicates nothing.
#
# READ-ONLY, and a CONSUMER by design: it re-scans nothing that /gcc-map already
# scans. SHAPE reads the map plus a cheap live census, MOVEMENT shells out to
# gcc-vitals.sh --json, CYCLE reads the schedulers and ledgers that already exist.
# Where the map is too old to trust, the panel says so and names the refresh
# command rather than quietly printing a stale number.
#
# Usage: gcc-explore.sh                  all three panels
#        gcc-explore.sh --panel shape    one panel (shape|movement|cycle)
#        gcc-explore.sh --json           one machine-readable object
#
# Honest bounds: token figures are chars/4 estimates, not a tokenizer's count.
# "touched since the map" uses mtime, which a reformat trips as readily as a
# rewrite. Every number here is a magnitude to reason with, never a measurement
# to quote to three digits.
set -uo pipefail

G="$HOME/.claude"
JSON=0; PANEL="all"
while [ $# -gt 0 ]; do
  case "$1" in
    --json)  JSON=1; shift ;;
    --panel) PANEL="$2"; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 64 ;;
  esac
done
case "$PANEL" in all|shape|movement|cycle) ;; *) echo "bad --panel: $PANEL" >&2; exit 64 ;; esac

PY="$(mktemp "${TMPDIR:-/tmp}/gcc-explore-XXXXXX.py")"
trap 'rm -f "$PY"' EXIT
cat > "$PY" <<'PYEOF'
import json, os, re, subprocess, sys, time
from datetime import datetime

G = os.path.expanduser("~/.claude")
as_json = sys.argv[1] == "1"
panel = sys.argv[2]
NOW = time.time()

def p(*parts):  return os.path.join(G, *parts)
def mtime(f):
    try: return os.path.getmtime(f)
    except OSError: return None
def age_days(f):
    m = mtime(f)
    return None if m is None else (NOW - m) / 86400.0
def when(f):
    m = mtime(f)
    return "never" if m is None else datetime.fromtimestamp(m).strftime("%d %b %H:%M")
def mds(d):
    try: return [f for f in os.listdir(p(d)) if f.endswith(".md")]
    except OSError: return []
def chars(f):
    try: return len(open(f, encoding="utf-8", errors="replace").read())
    except OSError: return 0

# ---------------------------------------------------------------- SHAPE ------
# What the gcc IS: the always-on channels that land before the user's first word,
# and the on-demand surface those channels can reach.

MAP = p("assets/reports/20260704-gcc-structure-map/MAP.md")

def frontmatter(f):
    """Text between the first two --- fences, or "" when there is no block."""
    try: txt = open(f, encoding="utf-8", errors="replace").read()
    except OSError: return ""
    if not txt.startswith("---"): return ""
    end = txt.find("\n---", 3)
    return txt[3:end] if end > 0 else ""

def rule_split():
    """(always-on, scoped) rule filenames. A rule with a paths: lever loads only
    when Claude touches a matching file; one without it loads every session.
    That split IS the always-on budget, so both panels read it from here."""
    always, scoped = [], []
    for f in sorted(mds("rules")):
        if f in ("README.md", "00-index.md"): continue
        (scoped if re.search(r"^paths:", frontmatter(p("rules", f)), re.M) else always).append(f)
    return always, scoped

def shape():
    idx = [f for f in ("CLAUDE.md","LOOKUP.md","NAMESPACE.md","GLOSSARY.md",
                       "PLACEMENT.md","FOLDERS.md") if os.path.exists(p(f))]
    always, scoped = rule_split()

    budget = chars(p("CLAUDE.md")) + sum(chars(p("rules", f)) for f in always)
    budget += sum(chars(p("rules", f)) for f in ("00-index.md",) if os.path.exists(p("rules", f)))

    try:    skills = len([d for d in os.listdir(p("skills")) if os.path.isdir(p("skills", d))])
    except OSError: skills = 0
    try:    hooks = len([f for f in os.listdir(p("scripts/hooks")) if f.endswith(".sh")])
    except OSError: hooks = 0

    # Hook lanes, counted from the live settings.json rather than from any doc.
    lanes = {}
    try:
        cfg = json.load(open(p("settings.json"), encoding="utf-8"))
        for ev, arr in (cfg.get("hooks") or {}).items(): lanes[ev] = len(arr)
    except Exception: pass

    return {
        "indices": idx,
        "rules_always": len(always), "rules_scoped": len(scoped),
        "features": len([f for f in mds("features") if f != "README.md"]),
        "conventions": len([f for f in mds("conventions") if f != "README.md"]),
        "skills": skills, "hooks": hooks,
        "lanes": lanes,
        "always_on_chars": budget, "always_on_ktok": round(budget / 4 / 1000, 1),
        "map_path": MAP, "map_age_days": age_days(MAP), "map_when": when(MAP),
    }

# Freshness: 14 days is the hard line. Between 7 and 14 — or any time a big
# change landed — a shallow probe says HOW MUCH moved, so "stale" is a magnitude
# rather than a boolean. A migration entry or a named subsystem is the
# big-change signal; ordinary doc edits and asset drops are not, by owner ruling.
def freshness(shape_d):
    age, mt = shape_d["map_age_days"], mtime(MAP)
    out = {"age_days": None if age is None else round(age, 1),
           "state": "absent", "big_change": [], "touched_since": 0, "probe": False}
    if age is None: return out
    out["state"] = "stale" if age >= 14 else ("aging" if age >= 7 else "fresh")

    try:
        migs = sorted(f for f in os.listdir(p("migrations"))
                      if re.match(r"^\d{4}-", f) and (mtime(p("migrations", f)) or 0) > mt)
    except OSError: migs = []
    out["big_change"] = migs[-6:]

    n = 0
    for d in ("rules", "features", "conventions"):
        for f in mds(d):
            if (mtime(p(d, f)) or 0) > mt: n += 1
    out["touched_since"] = n
    # Probe whenever the map is aging OR something big landed under it.
    out["probe"] = out["state"] != "fresh" or bool(migs)
    return out

# ------------------------------------------------------------- MOVEMENT ------
# Direction, delegated wholesale to the EKG. This panel re-derives nothing; it
# reads gcc-vitals.sh --json and phrases the arrows.

VITALS = p("scripts/gcc-vitals.sh")

def movement():
    try:
        out = subprocess.run(["bash", VITALS, "--json"], capture_output=True,
                             text=True, timeout=60)
        v = json.loads(out.stdout)
    except Exception as e:
        return {"ok": False, "error": str(e)[:120], "source": VITALS}

    m = v.get("learning", {}).get("mistakes_by_month", {}) or {}
    keys = sorted(m)
    this_month = datetime.now().strftime("%Y-%m")
    complete = [k for k in keys if k != this_month]
    arrow, learn_note = "→", "not enough complete months to read a direction"
    if len(complete) >= 2:
        cur, prev = m[complete[-1]], m[complete[-2]]
        arrow = "↑" if cur > prev * 1.1 else ("↓" if cur < prev * 0.9 else "→")
        learn_note = ("rising: new blind spots outpacing the rules"
                      if arrow == "↑" else
                      "falling: rules landing, OR atone used less. A question, not a verdict"
                      if arrow == "↓" else "flat")

    met = v.get("metabolic", {}) or {}
    frac = met.get("metabolized_frac")
    met_arrow = "→" if frac is None else ("↑" if frac >= 0.6 else ("→" if frac >= 0.4 else "↓"))
    bf = met.get("retirement_blind_frac")
    blind_arrow = "→" if bf is None else ("↓" if bf < 0.2 else ("→" if bf < 0.35 else "↑"))

    return {
        "ok": True, "source": VITALS,
        "mistakes": {k: m[k] for k in keys[-3:]}, "partial_month": this_month,
        "learning_arrow": arrow, "learning_note": learn_note,
        "metabolic_arrow": met_arrow, "open": met.get("open"),
        "metabolized_frac": frac,
        "blind_arrow": blind_arrow, "retirement_blind": met.get("retirement_blind"),
        "rules_total": met.get("rules_total"), "always_on": len(rule_split()[0]),
        "blind_frac": bf,
        "churn": (v.get("churn", {}) or {}).get("top", [])[:4],
    }

# ----------------------------------------------------------------- CYCLE -----
# The loops that keep it alive. Each one is a real scheduler entry or a real
# ledger, and each prints when it last actually ran, so a dead loop shows up as
# a stale timestamp instead of a confident line of prose.

LOOPS = [
    ("nightly",     "dream lanes digest transcripts into SessionStart insights",
     ["i-dream-daily", "i-dream-dreampass", "i-dream-smell"],
     "subconscious/dreams/journal.jsonl"),
    ("per mistake", "atone records it; recurrence graduates it into rules/",
     ["atone-consolidate"], "atone/events.jsonl"),
    ("weekly",      "proposals triaged PROMOTE / DROP, then the backlog walk",
     ["backlog-consolidate"], "proposals.jsonl"),
    ("per session", "WAL, checkpoint, catchup, runtime-notes",
     ["refresh-session-index", "archive-transcripts"], "skills/runtime-notes.md"),
]

def cycle():
    la = os.path.expanduser("~/Library/LaunchAgents")
    try:    installed = {f[len("com.alcatraz."):-len(".plist")]
                         for f in os.listdir(la) if f.startswith("com.alcatraz.")}
    except OSError: installed = set()

    rows = []
    for name, what, jobs, ledger in LOOPS:
        live = [j for j in jobs if j in installed]
        f = p(ledger)
        rows.append({"loop": name, "what": what,
                     "jobs": live, "jobs_missing": [j for j in jobs if j not in installed],
                     "ledger": f, "last": when(f),
                     "age_days": None if age_days(f) is None else round(age_days(f), 1),
                     "lines": count_lines(f)})
    return {"rows": rows, "scheduled_total": len(installed), "launch_agents": la}

def count_lines(f):
    try:
        with open(f, "rb") as fh: return sum(1 for _ in fh)
    except OSError: return None

# ---------------------------------------------------------------- render -----
W = 78
def rule():   print("  " + "─" * (W - 4))
def foot(*paths):
    print(f"  {'└─ sources:':<13}" + f"\n  {'':<13}".join(paths))

def render_shape(s, fr):
    print("◆ SHAPE — what the gcc is")
    print()
    lanes = s["lanes"]
    ss, up = lanes.get("SessionStart", 0), lanes.get("UserPromptSubmit", 0)
    print(f"   {s['rules_always']} always-on rules, {len(s['indices'])} indices and the CLAUDE.md router land")
    print(f"   before your first word: about {s['always_on_ktok']}k tokens of standing instruction.")
    print(f"   {ss} SessionStart lanes and {up} per-prompt injectors add to it at runtime.")
    print()
    print(f"      CLAUDE.md ─┬─ rules/ ({s['rules_always']} always + {s['rules_scoped']} scoped)")
    print(f"                 ├─ features/ ({s['features']})      dream  ─┐")
    print(f"                 ├─ conventions/ ({s['conventions']})   atone  ─┼─ SessionStart ({ss})")
    print(f"                 └─ indices ({len(s['indices'])}):        kanban ─┘")
    print(f"                    " + " · ".join(i[:-3] for i in s["indices"]))
    print()
    print(f"   Reachable on demand: {s['skills']} skills, {s['hooks']} hook scripts across "
          f"{len(lanes)} event lanes.")
    print()
    st = fr["state"]
    if st == "stale":
        print(f"   ! The map is {fr['age_days']:.0f} days old ({s['map_when']}), past the 14-day line.")
        print(f"     Structure above is a LIVE census; the map's own findings are not trusted here.")
    elif st == "aging":
        print(f"   · The map is {fr['age_days']:.0f} days old ({s['map_when']}).")
    if fr["probe"]:
        if fr["big_change"]:
            print(f"     Landed since: {', '.join(m[:4] for m in fr['big_change'])}"
                  f"  ({len(fr['big_change'])} migrations)")
        print(f"     {fr['touched_since']} rule/feature/convention files touched since. "
              f"Refresh with /gcc-map")
    foot(s["map_path"], p("settings.json"), p("rules") + "/  " + p("skills") + "/")

def render_movement(mv):
    print("◆ MOVEMENT — which way it is drifting")
    print()
    if not mv["ok"]:
        print(f"   ! vitals unavailable: {mv['error']}")
        foot(mv["source"]); return
    ms = "  ".join(f"{k.split('-')[1]}:{n}" + ("*" if k == mv["partial_month"] else "")
                   for k, n in mv["mistakes"].items())
    print(f"   {mv['learning_arrow']} learning    mistakes/month  {ms}   (* = partial)")
    print(f"                  {mv['learning_note']}")
    print()
    frac = mv["metabolized_frac"]
    fs = "n/a" if frac is None else f"{frac*100:.0f}% metabolized, {mv['open']} open"
    print(f"   {mv['metabolic_arrow']} metabolic   proposals       {fs}")
    print(f"                  the backlog is the config's working digestion; healthy is 60%+")
    print()
    bf = mv["blind_frac"]
    bs = "n/a" if bf is None else f"{mv['retirement_blind']}/{mv['rules_total']} ({bf*100:.0f}%) unmeasurable"
    print(f"   {mv['blind_arrow']} metabolic   retirement-blind  {bs}")
    print(f"                  rules with no hook and no atone lineage cannot be judged for value")
    print()
    print(f"   → growth      rules            {mv['rules_total']} total, {mv['always_on']} of them always-on")
    print(f"                  every always-on rule is paid for on every session, forever")
    print()
    print(f"   → churn       where the edits land (last 200 commits)")
    for d, n in mv["churn"]:
        print(f"                  {n:>4}  {d}")
    foot(mv["source"] + " --json", p("atone/events.jsonl"), p("proposals.jsonl"))

def render_cycle(cy):
    print("◆ CYCLE — the loops that keep it alive")
    print()
    for r in cy["rows"]:
        jobs = ", ".join(r["jobs"]) if r["jobs"] else "no scheduler entry"
        print(f"   {r['loop']:<12} {r['what']}")
        line = f"                {jobs}"
        if r["lines"] is not None:
            line += f"  ·  {r['lines']} entries"
        print(line)
        stale = "" if (r["age_days"] or 0) < 3 else "   ! quiet"
        print(f"                last write {r['last']}{stale}")
        if r["jobs_missing"]:
            print(f"                ! not installed: {', '.join(r['jobs_missing'])}")
        print()
    print(f"   {cy['scheduled_total']} scheduled jobs installed in total.")
    foot(cy["launch_agents"] + "/com.alcatraz.*.plist",
         *[r["ledger"] for r in cy["rows"]])

# ------------------------------------------------------------------ main -----
s  = shape()   if panel in ("all", "shape")    else None
fr = freshness(s) if s else None
mv = movement() if panel in ("all", "movement") else None
cy = cycle()    if panel in ("all", "cycle")    else None

if as_json:
    print(json.dumps({k: v for k, v in
                      (("shape", s), ("freshness", fr), ("movement", mv), ("cycle", cy))
                      if v is not None}))
    sys.exit()

first = True
for name, data, fn in (("shape", s, lambda: render_shape(s, fr)),
                       ("movement", mv, lambda: render_movement(mv)),
                       ("cycle", cy, lambda: render_cycle(cy))):
    if data is None: continue
    if not first: print()
    first = False
    fn()
PYEOF

python3 "$PY" "$JSON" "$PANEL"
