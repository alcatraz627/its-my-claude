#!/usr/bin/env bash
# evaluate-detectors.sh — the ledger alert evaluator (v1).
#
# Reads the value-system (goals.toml) and the detectors (detectors.toml), evaluates
# each detector against its subject stream, and appends any actionable to the alert
# ledger (alerts.jsonl). It is stateless across runs except for a small state file
# (per-detector firing/last-fired) and is meant to piggyback an existing cron — it
# never blocks and always exits 0.
#
# Three guards the QA review demanded, all here so no detector can opt out:
#   - SPEC-LINT: a detector with an unknown archetype, a goal_ref not in goals.toml,
#     or a missing subject stream is flagged LOUDLY (a FINDING), never silently
#     ignored. A misconfigured detector must not masquerade as correctly-quiet.
#   - OFFSET-CURSOR LINT: a detector that reads a delta cursor gets its cursor
#     reconciled against the stream — offset past EOF or a shrunk stream is a
#     FINDING (the QA "silent-failure relocated to the cursor" fix). Window-based
#     detectors (burn_rate) carry no cursor, so this is a no-op for them.
#   - STALENESS: each run stamps last_eval per detector; a detector not evaluated in
#     a while (paused cron) is surfaceable, so "the cron stopped" is loud not silent.
#
# The binding rule: an actionable may only reach its requested tier if its goal_ref
# names a goal in goals.toml; the tier is then capped by that goal's tier_ceiling.
#
# Test/isolation: LEDGER_DIR relocates all state (tests point it at a temp dir);
# LEDGER_NOW fixes "now" for deterministic window math.
set -uo pipefail

LEDGER_DIR="${LEDGER_DIR:-$HOME/.claude/ledger}"
GOALS="$LEDGER_DIR/goals.toml"
DETECTORS="$LEDGER_DIR/detectors.toml"
ALERTS="$LEDGER_DIR/alerts.jsonl"
STATE="$LEDGER_DIR/detector-state.json"
LOCK="$LEDGER_DIR/.alerts.lock"
NOW="${LEDGER_NOW:-$(date -u '+%Y-%m-%dT%H:%M:%SZ')}"

# ledger-common is the alert ledger's writer (id-gen + flock append).
# shellcheck disable=SC1091
source "$HOME/.claude/scripts/ledger/ledger-common.sh" 2>/dev/null || true

command -v yq >/dev/null 2>&1 || { echo "evaluate-detectors: yq required, skipping" >&2; exit 0; }
[ -f "$GOALS" ] && [ -f "$DETECTORS" ] || { echo "evaluate-detectors: no goals/detectors at $LEDGER_DIR" >&2; exit 0; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
yq -p toml -o json "$GOALS"     > "$TMP/goals.json"  2>/dev/null || echo '{}' > "$TMP/goals.json"
yq -p toml -o json "$DETECTORS" > "$TMP/det.json"    2>/dev/null || echo '{}' > "$TMP/det.json"
cat "$STATE" 2>/dev/null > "$TMP/state.json" || true
[ -s "$TMP/state.json" ] || echo '{}' > "$TMP/state.json"

# Python computes decisions + lints; emits one JSON object (no id/ts — bash stamps
# those via ledger_id so the alert ids match the ledger format).
RESULT=$(python3 - "$NOW" "$TMP/goals.json" "$TMP/det.json" "$TMP/state.json" <<'PY'
import json, sys, os, datetime

now = datetime.datetime.strptime(sys.argv[1], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
goals = json.load(open(sys.argv[2])).get("goals", {})
dets  = json.load(open(sys.argv[3])).get("detector", [])
state = json.load(open(sys.argv[4]))

KNOWN = {"burn_rate", "we_run_rule", "heartbeat", "robust_outlier"}
TIER_ORDER = ["log", "find", "ticket", "page"]

def expand(p): return os.path.expanduser(p or "")
def parse_ts(s):
    try: return datetime.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
    except Exception: return None
def cap_tier(req, ceiling):
    try:
        return req if TIER_ORDER.index(req) <= TIER_ORDER.index(ceiling) else ceiling
    except ValueError:
        return "log"

alerts, summary = [], []
new_state = dict(state)
nowiso = now.strftime("%Y-%m-%dT%H:%M:%SZ")

for det in dets:
    name = det.get("name", "?")
    st = dict(state.get(name, {"firing": False, "last_fired_ts": None, "last_eval_ts": None}))

    # ---- SPEC-LINT (loud) ----
    problems = []
    if det.get("archetype") not in KNOWN:
        problems.append(f"unknown archetype '{det.get('archetype')}'")
    gref = det.get("goal_ref")
    if gref not in goals:
        problems.append(f"goal_ref '{gref}' not in goals.toml")
    stream = det.get("subject_stream", "")
    if not stream:
        problems.append("no subject_stream")
    elif not os.path.exists(expand(stream)):
        problems.append(f"subject_stream missing: {stream}")
    if problems:
        alerts.append({"detector": name, "tier": "find", "kind": "alert", "goal_ref": gref,
                       "actionable": True, "subject": f"detector-lint: {name}",
                       "instruction": f"detector '{name}' is misconfigured: {'; '.join(problems)}",
                       "idempotence_key": f"lint|{name}|{now.strftime('%Y-%m-%d')}"})
        summary.append(f"LINT-FAIL {name}: {'; '.join(problems)}")
        st["last_eval_ts"] = nowiso
        new_state[name] = st
        continue

    # ---- OFFSET-CURSOR LINT (delta-based detectors only) ----
    cpath = expand(det.get("cursor_path", ""))
    if det.get("cursor_path") and os.path.exists(cpath):
        try:
            cur = json.load(open(cpath))
        except Exception:
            cur = {}
        spath = expand(stream)
        nlines = sum(1 for _ in open(spath)) if os.path.exists(spath) else 0
        bad = None
        off = cur.get("offset")
        if isinstance(off, int) and off > nlines:
            bad = f"cursor offset {off} > stream length {nlines} (past EOF / truncated)"
        last_id = cur.get("last_event_id")
        if last_id:
            ids = {json.loads(l).get("id") for l in open(spath)} if os.path.exists(spath) else set()
            if last_id not in ids:
                bad = f"cursor last_event_id '{last_id}' no longer in stream (rotated/truncated)"
        if bad:
            alerts.append({"detector": name, "tier": "find", "kind": "alert", "goal_ref": gref,
                           "actionable": True, "subject": f"cursor-lint: {name}",
                           "instruction": f"detector '{name}' cursor is broken: {bad}. It would go silently quiet on real events — reset the cursor.",
                           "idempotence_key": f"cursorlint|{name}|{now.strftime('%Y-%m-%d')}"})
            summary.append(f"CURSOR-FAIL {name}: {bad}")
            st["last_eval_ts"] = nowiso
            new_state[name] = st
            continue

    st["last_eval_ts"] = nowiso

    # ---- BURN_RATE eval ----
    if det.get("archetype") == "burn_rate":
        field = det.get("subject_field"); val = str(det.get("subject_value"))
        wdays = int(det.get("window_days", 30)); sdays = int(det.get("short_window_days", 7))
        budget = float(det.get("budget", 4)); fmult = float(det.get("fire_multiple", 2.0))
        smin = int(det.get("short_min", 2)); clear_days = int(det.get("clear_after_days", 7))
        cooldown = int(det.get("cooldown_days", 3))
        long_cut = now - datetime.timedelta(days=wdays)
        short_cut = now - datetime.timedelta(days=sdays)
        clear_cut = now - datetime.timedelta(days=clear_days)
        long_c = short_c = clear_c = 0
        for line in open(expand(stream)):
            line = line.strip()
            if not line: continue
            try: d = json.loads(line)
            except Exception: continue
            if str(d.get(field)) != val: continue
            t = parse_ts(d.get("ts", ""))
            if t is None: continue
            if t >= long_cut: long_c += 1
            if t >= short_cut: short_c += 1
            if t >= clear_cut: clear_c += 1

        fires = (long_c >= budget * fmult) and (short_c >= smin)
        was_firing = st.get("firing", False)
        lf = parse_ts(st.get("last_fired_ts") or "")
        in_cooldown = lf is not None and (now - lf).days < cooldown

        if was_firing:
            if clear_c == 0:
                st["firing"] = False
                summary.append(f"{name}: CLEARED (no {val} in {clear_days}d)")
            else:
                summary.append(f"{name}: still firing (long={long_c} short={short_c})")
        else:
            if fires and not in_cooldown:
                st["firing"] = True
                st["last_fired_ts"] = nowiso
                ceiling = goals[gref].get("tier_ceiling", "log")
                tier = cap_tier(det.get("tier", "ticket"), ceiling)
                alerts.append({"detector": name, "tier": tier, "kind": "alert", "goal_ref": gref,
                               "actionable": True, "subject": f"{name} {field}={val}",
                               "window_count": long_c, "short_count": short_c, "window_days": wdays,
                               "deep_link": stream,
                               "idempotence_key": f"{name}|{now.strftime('%Y-%m-%d')}",
                               "instruction": (f"{val} burn: {long_c} in {wdays}d (budget {int(budget)}), "
                                               f"{short_c} in {sdays}d. {goals[gref].get('statement','')}")})
                summary.append(f"{name}: FIRE tier={tier} (long={long_c}>={budget*fmult:.0f}, short={short_c}>={smin})")
            elif fires and in_cooldown:
                summary.append(f"{name}: condition met but in cooldown ({cooldown}d) -> suppressed (logged, not paged)")
            else:
                summary.append(f"{name}: quiet (long={long_c} short={short_c})")
    else:
        summary.append(f"{name}: archetype '{det.get('archetype')}' not implemented in v1 -> skipped")

    new_state[name] = st

print(json.dumps({"alerts": alerts, "summary": summary, "new_state": new_state}))
PY
)

[ -z "$RESULT" ] && { echo "evaluate-detectors: evaluator produced no output" >&2; exit 0; }

# Append each alert via ledger-common (id stamped here so it matches the ledger format).
mkdir -p "$LEDGER_DIR"
echo "$RESULT" | jq -c '.alerts[]?' 2>/dev/null | while IFS= read -r rec; do
  [ -z "$rec" ] && continue
  aid=$(ledger_id alert)
  line=$(printf '%s' "$rec" | jq -c --arg id "$aid" --arg ts "$NOW" '. + {id:$id, ts:$ts} | {id, ts} + .')
  ledger_append "$ALERTS" "$LOCK" "$line"

  # Route: a graduate-to-mechanism ticket/page auto-files a propose.sh gate
  # candidate — making "a recurring pattern should become a gate" mechanical
  # instead of relying on an agent to remember. Idempotent: skip if an open
  # proposal already carries this alert's idempotence key.
  gref=$(printf '%s' "$rec" | jq -r '.goal_ref // ""')
  tier=$(printf '%s' "$rec" | jq -r '.tier // ""')
  ikey=$(printf '%s' "$rec" | jq -r '.idempotence_key // ""')
  if [ "$gref" = "graduate-to-mechanism" ] && { [ "$tier" = "ticket" ] || [ "$tier" = "page" ]; }; then
    pstore="${PROPOSE_STORE:-$HOME/.claude/proposals.jsonl}"
    if [ -n "$ikey" ] && ! rg -qF "$ikey" "$pstore" 2>/dev/null; then
      instr=$(printf '%s' "$rec" | jq -r '.instruction // ""')
      bash "$HOME/.claude/scripts/propose.sh" add --category hooks --effort medium \
        --title "Graduate a recurring pattern to a gate (ledger alert: $ikey)" \
        --body "Auto-filed by the ledger alert evaluator. $instr Identify the worst recurring slug(s) (atone slugs / atone stats) and add a mechanical gate." \
        --tags "ledger auto-filed graduate-to-mechanism" >/dev/null 2>&1 || true
    fi
  fi
done

# Persist state atomically.
echo "$RESULT" | jq -c '.new_state' > "$STATE.tmp" 2>/dev/null && mv "$STATE.tmp" "$STATE"

# The pull surface: print the summary (read by /doctor + the daily digest).
echo "$RESULT" | jq -r '.summary[]? | "  ledger-alert: " + .'
exit 0
