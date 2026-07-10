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

# Pre-convert the efficacy registry (TOML→JSON) so the embedded python — which has
# no TOML parser (macOS python3 < 3.11, no tomllib) — can read the slug→gate
# mappings. Mirrors the goals/detectors conversion above. The registry path is
# whatever the efficacy detector declares; missing/unparseable → {} (the python
# branch then emits a loud lint finding, never a silent skip).
REG_PATH=$(jq -r '.detector[]? | select(.archetype=="efficacy") | .registry // empty' "$TMP/det.json" 2>/dev/null | head -1)
REG_PATH_EXP="${REG_PATH/#\~/$HOME}"
if [ -n "$REG_PATH_EXP" ] && [ -f "$REG_PATH_EXP" ]; then
  yq -p toml -o json "$REG_PATH_EXP" > "$TMP/efficacy.json" 2>/dev/null || echo '{}' > "$TMP/efficacy.json"
else
  echo '{}' > "$TMP/efficacy.json"
fi

# Same pre-conversion for the acted registry (plug fired→acted mappings).
ACT_PATH=$(jq -r '.detector[]? | select(.archetype=="acted") | .registry // empty' "$TMP/det.json" 2>/dev/null | head -1)
ACT_PATH_EXP="${ACT_PATH/#\~/$HOME}"
if [ -n "$ACT_PATH_EXP" ] && [ -f "$ACT_PATH_EXP" ]; then
  yq -p toml -o json "$ACT_PATH_EXP" > "$TMP/acted.json" 2>/dev/null || echo '{}' > "$TMP/acted.json"
else
  echo '{}' > "$TMP/acted.json"
fi

# Python computes decisions + lints; emits one JSON object (no id/ts — bash stamps
# those via ledger_id so the alert ids match the ledger format).
RESULT=$(python3 - "$NOW" "$TMP/goals.json" "$TMP/det.json" "$TMP/state.json" "$TMP/efficacy.json" "$TMP/acted.json" <<'PY'
import json, sys, os, datetime

now = datetime.datetime.strptime(sys.argv[1], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
goals = json.load(open(sys.argv[2])).get("goals", {})
dets  = json.load(open(sys.argv[3])).get("detector", [])
state = json.load(open(sys.argv[4]))
# The efficacy registry (slug→gate mappings), pre-converted TOML→JSON by bash.
# Absent for a run with no efficacy detector; the efficacy branch lints if empty.
efficacy_reg = json.load(open(sys.argv[5])) if len(sys.argv) > 5 and os.path.exists(sys.argv[5]) else {}
# The acted registry (plug fired→acted conversion mappings), same convention.
acted_reg = json.load(open(sys.argv[6])) if len(sys.argv) > 6 and os.path.exists(sys.argv[6]) else {}

KNOWN = {"burn_rate", "we_run_rule", "heartbeat", "robust_outlier", "efficacy", "acted"}
TIER_ORDER = ["log", "find", "ticket", "page"]

def expand(p): return os.path.expanduser(p or "")
def parse_date(s):
    if not s: return None
    try: return datetime.datetime.strptime(str(s), "%Y-%m-%d").replace(tzinfo=datetime.timezone.utc)
    except Exception: return None
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

# ---- GOALS-LINT (loud) ----
# The anti-drift guard goals.toml promises in its own header: a goal is a value
# claim, and value claims rot. Two mechanical checks, one optional:
#   - review_after past due → the goal must be re-justified or retired.
#   - a provenance entry that is an explicit repo path (contains "/" before any
#     annotation and ends in a known extension) but no longer exists → the
#     encoding drifted. Prose refs ("live intention …", bare filenames with
#     commentary) are exempt — resolving them reliably isn't possible, and a
#     false "missing" here would teach readers to ignore the lint.
#   - reviewed_on (optional field): an existing provenance file modified after
#     the last review → flag for a re-check.
GOAL_EXT = (".md", ".sh", ".toml", ".py", ".json", ".jsonl")
for gname, g in goals.items():
    gproblems = []
    ra = parse_date(g.get("review_after"))
    if ra is None:
        gproblems.append("missing/unparseable review_after")
    elif now >= ra:
        gproblems.append(f"review_after {g.get('review_after')} is past due — re-justify or retire the goal")
    reviewed = parse_date(g.get("reviewed_on"))
    for ref in str(g.get("provenance", "")).split(";"):
        tok = ref.strip().split()[0] if ref.strip() else ""
        if "/" not in tok or not tok.endswith(GOAL_EXT):
            continue
        cand = os.path.expanduser(tok if tok.startswith(("~", "/")) else os.path.join("~/.claude", tok))
        if not os.path.exists(cand):
            gproblems.append(f"provenance file missing: {tok}")
        elif reviewed is not None:
            mtime = datetime.datetime.fromtimestamp(os.path.getmtime(cand), tz=datetime.timezone.utc)
            if mtime > reviewed:
                gproblems.append(f"provenance {tok} changed after reviewed_on {g.get('reviewed_on')} — re-check the goal still matches")
    if gproblems:
        alerts.append({"detector": "goals-lint", "tier": "find", "kind": "alert", "goal_ref": gname,
                       "actionable": True, "subject": f"goals-lint: {gname}",
                       "instruction": f"goal '{gname}' is drifting: {'; '.join(gproblems)}",
                       "idempotence_key": f"goalslint|{gname}|{now.strftime('%Y-%m-%d')}"})
        summary.append(f"GOALS-LINT {gname}: {'; '.join(gproblems)}")

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
                # A detector's own instruction (remediation guidance in detectors.toml)
                # rides the alert so the reader gets the specific fix, not just the goal.
                det_instr = str(det.get("instruction") or "").strip()
                alerts.append({"detector": name, "tier": tier, "kind": "alert", "goal_ref": gref,
                               "actionable": True, "subject": f"{name} {field}={val}",
                               "window_count": long_c, "short_count": short_c, "window_days": wdays,
                               "deep_link": stream,
                               "idempotence_key": f"{name}|{now.strftime('%Y-%m-%d')}",
                               "instruction": (f"{val} burn: {long_c} in {wdays}d (budget {int(budget)}), "
                                               f"{short_c} in {sdays}d. {goals[gref].get('statement','')}"
                                               + (f" || {det_instr}" if det_instr else ""))})
                summary.append(f"{name}: FIRE tier={tier} (long={long_c}>={budget*fmult:.0f}, short={short_c}>={smin})")
            elif fires and in_cooldown:
                summary.append(f"{name}: condition met but in cooldown ({cooldown}d) -> suppressed (logged, not paged)")
            else:
                summary.append(f"{name}: quiet (long={long_c} short={short_c})")

    # ---- EFFICACY eval (registry-driven) ----
    # For every slug→gate mapping, does the slug's recurrence-rate DROP after the
    # gate deployed? pre = events/30d over the 90d before deploy; post = events/30d
    # since max(deployed, redeployed). A mature window still recurring at/above the
    # pre rate is "regressing" — a gate that isn't working, which under
    # graduate-to-mechanism is itself a thrash loop. Only HIGH-confidence mappings
    # alert; provisional ones are informational. Idempotent per (slug, gate, month).
    elif det.get("archetype") == "efficacy":
        mappings = efficacy_reg.get("mapping", []) if isinstance(efficacy_reg, dict) else []
        if not mappings:
            alerts.append({"detector": name, "tier": "find", "kind": "alert", "goal_ref": gref,
                           "actionable": True, "subject": f"efficacy-lint: {name}",
                           "instruction": f"efficacy detector '{name}' has no readable registry mappings (registry '{det.get('registry')}' missing/empty/unparseable). It would go silently quiet — fix the registry.",
                           "idempotence_key": f"efflint|{name}|{now.strftime('%Y-%m-%d')}"})
            summary.append(f"{name}: LINT no registry mappings")
        else:
            min_window = int(det.get("min_window_days", 21))
            margin     = float(det.get("margin", 0.15))
            pre_days   = int(det.get("pre_window_days", 90))
            ceiling    = goals[gref].get("tier_ceiling", "log")
            req_tier   = det.get("tier", "ticket")
            month      = now.strftime("%Y-%m")

            # Load the atone ledger (subject_stream) and warn stream once.
            atone_ev = []  # (ts_dt, slug, cluster)
            for line in open(expand(stream)):
                line = line.strip()
                if not line: continue
                try: d = json.loads(line)
                except Exception: continue
                t = parse_ts(d.get("ts", ""))
                if t is None: continue
                atone_ev.append((t, d.get("slug"), d.get("cluster")))
            warn_ev = []  # (ts_dt, hook_id, heeded)
            wpath = expand(det.get("warn_stream", ""))
            if wpath and os.path.exists(wpath):
                for line in open(wpath):
                    line = line.strip()
                    if not line: continue
                    try: d = json.loads(line)
                    except Exception: continue
                    # Fires only: kind:"heed" resolutions share the hook_id but
                    # are responses to a fire, not fires — don't double-count.
                    if d.get("kind") != "warn": continue
                    t = parse_ts(d.get("ts", ""))
                    if t is None: continue
                    warn_ev.append((t, d.get("hook_id", "") or "", d.get("heeded", "unknown")))

            fired_months = dict(st.get("fired_months", {}))
            HEED_YES = {"yes", "heeded", "true", "1"}
            HEED_NO  = {"no", "ignored", "false", "0"}

            for m in mappings:
                slug = m.get("slug", "?"); gate = m.get("gate", "?")
                conf = (m.get("confidence", "high") or "high").lower()
                mfield = m.get("match_field", "slug"); mval = m.get("match_value", slug)
                dep = parse_date(m.get("deployed")); redep = parse_date(m.get("redeployed"))
                if dep is None:
                    summary.append(f"{name} {slug}/{gate}: LINT bad/absent deployed date")
                    continue
                eff = redep if (redep and redep > dep) else dep

                def matches(ev, _mf=mfield, _mv=mval):
                    return (ev[2] == _mv) if _mf == "cluster" else (ev[1] == _mv)

                pre_start = dep - datetime.timedelta(days=pre_days)
                pre_c  = sum(1 for ev in atone_ev if pre_start <= ev[0] < dep and matches(ev))
                post_c = sum(1 for ev in atone_ev if ev[0] >= eff and matches(ev))
                post_days = (now - eff).days
                pre_rate  = pre_c / pre_days * 30.0
                post_rate = (post_c / post_days * 30.0) if post_days > 0 else 0.0

                # gate telemetry in the post window (informational)
                wprefix = m.get("warn_prefix", "")
                g_fires = g_heeded = g_known = 0
                if wprefix:
                    for (t, hid, heeded) in warn_ev:
                        if t >= eff and hid.startswith(wprefix):
                            g_fires += 1
                            hl = str(heeded).lower()
                            if hl in HEED_YES: g_heeded += 1; g_known += 1
                            elif hl in HEED_NO: g_known += 1
                heed_str = f"{g_heeded}/{g_known}" if g_known else "?"

                if post_days < min_window:
                    status = "insufficient-data"
                elif post_c == 0:
                    status = "improving"
                elif pre_rate == 0:
                    status = "regressing" if post_c > 0 else "flat"
                elif post_rate <= pre_rate * (1 - margin):
                    status = "improving"
                elif post_rate >= pre_rate:
                    status = "regressing"
                else:
                    status = "flat"

                mature = post_days >= min_window
                cflag = "" if conf == "high" else f" [{conf}]"
                summary.append(f"{name} {slug}/{gate}: {status}{cflag} (pre={pre_rate:.1f} post={post_rate:.1f}/30d, win={post_days}d, fires={g_fires} heeded={heed_str})")

                # Alert only on a regressing, mature, HIGH-confidence mapping — and
                # only once per (slug, gate, month). Provisional mappings never
                # ticket (their attribution is too fuzzy to auto-file a gate).
                if status == "regressing" and mature and conf == "high":
                    mkey = f"{slug}|{gate}"
                    if fired_months.get(mkey) == month:
                        summary.append(f"{name} {slug}/{gate}: regressing but already alerted this month -> suppressed")
                    else:
                        tier = cap_tier(req_tier, ceiling)
                        det_instr = str(det.get("instruction") or "").strip()
                        alerts.append({"detector": name, "tier": tier, "kind": "alert", "goal_ref": gref,
                                       "actionable": True,
                                       "subject": f"gate not reducing recurrence: {slug} / {gate}",
                                       "slug": slug, "gate": gate,
                                       "pre_rate_30d": round(pre_rate, 2), "post_rate_30d": round(post_rate, 2),
                                       "window_days": post_days, "gate_fires_post": g_fires,
                                       "gate_heeded_post": heed_str, "deep_link": det.get("registry", ""),
                                       "idempotence_key": f"{name}|{slug}|{gate}|{month}",
                                       "instruction": (f"{slug} still recurs at {post_rate:.1f}/30d after {gate} deployed "
                                                       f"{eff.date()} (pre {pre_rate:.1f}/30d, {post_days}d window, "
                                                       f"gate fires={g_fires}). {goals[gref].get('statement','')}"
                                                       + (f" || {det_instr}" if det_instr else ""))})
                        fired_months[mkey] = month
                        summary.append(f"{name} {slug}/{gate}: ALERT regressing tier={tier}")
            st["fired_months"] = fired_months

    # ---- ACTED eval (registry-driven) ----
    # The other half of plug efficacy: FIRED is already measured (plug-events,
    # warn-events); this asks whether anything ACTS on a fire. Per mapping:
    # sessions where the plug fired in the window vs those with ≥1 same-session
    # acted event. A mature, high-volume mapping with ZERO conversions means the
    # injection spends attention/context for nothing — that's an attention-
    # scarcity finding, not a badge. Sessions are joined on the first 8 chars of
    # the session id (streams disagree on full-vs-short ids). Idempotent per
    # (plug, month).
    elif det.get("archetype") == "acted":
        mappings = acted_reg.get("mapping", []) if isinstance(acted_reg, dict) else []
        if not mappings:
            alerts.append({"detector": name, "tier": "find", "kind": "alert", "goal_ref": gref,
                           "actionable": True, "subject": f"acted-lint: {name}",
                           "instruction": f"acted detector '{name}' has no readable registry mappings (registry '{det.get('registry')}' missing/empty/unparseable). It would go silently quiet — fix the registry.",
                           "idempotence_key": f"actlint|{name}|{now.strftime('%Y-%m-%d')}"})
            summary.append(f"{name}: LINT no registry mappings")
        else:
            ceiling  = goals[gref].get("tier_ceiling", "log")
            req_tier = det.get("tier", "find")
            month    = now.strftime("%Y-%m")
            fired_months = dict(st.get("fired_months", {}))

            def stream_events(path, field, value, kind, ts_key, sess_key, cutoff):
                """Yield session-id-prefix8 of matching events after cutoff."""
                p = expand(path)
                if not p or not os.path.exists(p):
                    return None
                out = []
                for line in open(p):
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        d = json.loads(line)
                    except Exception:
                        continue
                    if kind and d.get("kind") != kind:
                        continue
                    if str(d.get(field)) != str(value):
                        continue
                    t = parse_ts(d.get(ts_key, ""))
                    if t is None or t < cutoff:
                        continue
                    out.append(str(d.get(sess_key) or "")[:8])
                return out

            for m in mappings:
                plug = m.get("plug", "?")
                wdays = int(m.get("window_days", 30))
                min_fires = int(m.get("min_fires", 10))
                conf = (m.get("confidence", "high") or "high").lower()
                cutoff = now - datetime.timedelta(days=wdays)

                fired = stream_events(m.get("fired_stream", ""), m.get("fired_field", ""),
                                      m.get("fired_value", ""), m.get("fired_kind"),
                                      "ts", m.get("fired_session_key", "sid"), cutoff)
                acted = stream_events(m.get("acted_stream", ""), m.get("acted_field", ""),
                                      m.get("acted_value", ""), None,
                                      "ts", m.get("acted_session_key", "session"), cutoff)
                if fired is None or acted is None:
                    summary.append(f"{name} {plug}: LINT fired/acted stream missing")
                    continue

                fired_sessions = {s for s in fired if s}
                acted_sessions = {s for s in acted if s}
                converted = fired_sessions & acted_sessions
                ratio = f"{len(converted)}/{len(fired_sessions)}"
                cflag = "" if conf == "high" else f" [{conf}]"
                summary.append(f"{name} {plug}: fires={len(fired)} sessions={len(fired_sessions)} converted={ratio}{cflag} ({wdays}d)")

                if len(fired) >= min_fires and not converted and conf == "high":
                    if fired_months.get(plug) == month:
                        summary.append(f"{name} {plug}: zero-conversion but already alerted this month -> suppressed")
                    else:
                        tier = cap_tier(req_tier, ceiling)
                        det_instr = str(det.get("instruction") or "").strip()
                        alerts.append({"detector": name, "tier": tier, "kind": "alert", "goal_ref": gref,
                                       "actionable": True,
                                       "subject": f"plug fires, nothing acts: {plug}",
                                       "plug": plug, "fires": len(fired),
                                       "fired_sessions": len(fired_sessions), "converted": 0,
                                       "window_days": wdays, "deep_link": m.get("fired_stream", ""),
                                       "idempotence_key": f"{name}|{plug}|{month}",
                                       "instruction": (f"{plug} fired {len(fired)}x across {len(fired_sessions)} sessions "
                                                       f"in {wdays}d with ZERO same-session conversions. "
                                                       f"{goals[gref].get('statement','')}"
                                                       + (f" || {det_instr}" if det_instr else ""))})
                        fired_months[plug] = month
                        summary.append(f"{name} {plug}: ALERT zero-conversion tier={tier}")
            st["fired_months"] = fired_months
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

# The pull surface: print the summary (read by /doctor step 5.7 + ledger.sh).
echo "$RESULT" | jq -r '.summary[]? | "  ledger-alert: " + .'
exit 0
