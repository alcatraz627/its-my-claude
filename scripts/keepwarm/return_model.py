#!/usr/bin/env python3
"""Estimates the chance the owner comes back to a session within the next hour.

Learned from their own transcripts: how long they have been away so far and the hour
on this laptop's clock at that moment. Longer away means longer still to come, and the
daily rhythm shifts the odds smoothly, with no hard edge at any hour. keepwarm.py asks
it whether another warm-up is worth paying for.

Usage: return_model.py fit [--dry-run]   refit and report accuracy on held-out data
       return_model.py chance AWAY_MIN [HOUR]
A refit replaces the saved model only if it beats the plain Copernican rule on held-out data.
"""
import datetime as dt
import glob
import json
import math
import os
import sys
import time

HOME = os.path.expanduser("~")
PROJECTS = os.environ.get("KEEPWARM_PROJECTS", os.path.join(HOME, ".claude", "projects"))
MODEL = os.environ.get("KEEPWARM_MODEL", os.path.join(HOME, ".claude", "keepwarm", "return-model.json"))
LOOKBACK_DAYS = 60
NOT_OWNER = ("<task-notification>", "Another Claude session sent", "Stop hook feedback:", "[usage-", "[fleet-watch]",
             "<local-command", "<bash-", "Caveat:", "[Request interrupted", "<command-name>/clear")
CHECKPOINTS = (30, 55, 80, 110, 140, 165, 200, 240, 300, 360, 480, 600, 720)
HORIZON_MIN = 60
# The Copernican rule written in this model's terms: expect to wait about as long
# again as already waited, whatever the hour. Used until a saved model exists, and
# the starting belief every fit is pulled toward.
PRIOR = [0.0, -1.0, 0.0, 0.0, 0.0, 0.0]
PRIOR_STRENGTH = float(os.environ.get("KEEPWARM_PRIOR_STRENGTH", 30))
FOLDS = 5


def absences():
    """Every time the owner was away 5+ minutes: (minutes away, when they left)."""
    rows = []
    since = time.time() - LOOKBACK_DAYS * 86400
    for path in glob.glob(os.path.join(PROJECTS, "*", "*.jsonl")):
        try:
            if os.path.getmtime(path) < since or os.path.getsize(path) < 50000:
                continue
        except OSError:
            continue
        last, ping = None, False
        for line in open(path, errors="replace"):
            if '"isSidechain":true' in line:
                continue
            try:
                o = json.loads(line)
            except ValueError:
                continue
            kind, ts = o.get("type"), o.get("timestamp")
            if not ts or kind not in ("user", "assistant"):
                continue
            t = dt.datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp()
            msg = o.get("message") or {}
            if kind == "assistant":
                if not ping:
                    last = t
                continue
            c = msg.get("content")
            text = c if isinstance(c, str) else ""
            if isinstance(c, list):
                if any(isinstance(x, dict) and x.get("type") == "tool_result" for x in c):
                    continue
                text = " ".join(x.get("text", "") for x in c if isinstance(x, dict))
            text = text.lstrip()
            if o.get("isMeta") or not text:
                continue
            if text.startswith("[keepwarm]"):
                ping = True
                continue
            if text.startswith(NOT_OWNER):
                ping = text.startswith("[usage-carry]")
                continue
            ping = False
            if last and t > last and (t - last) / 60 >= 5:
                rows.append(((t - last) / 60, last))
            last = t
    rows.sort(key=lambda r: r[1])
    return rows


def features(away_min, hour):
    """Time away on a log scale, and the hour as a point on a circle so 23:00 and 00:00 stay neighbours."""
    lg = math.log(max(away_min, 1) / 60.0)
    s, c = math.sin(2 * math.pi * hour / 24), math.cos(2 * math.pi * hour / 24)
    return [1.0, lg, s, c, lg * s, lg * c]


def predict(coef, away_min, hour):
    z = sum(a * b for a, b in zip(coef, features(away_min, hour)))
    return 1 / (1 + math.exp(-max(-30, min(30, z))))


def samples(rows):
    """One training row per checkpoint an absence reached: was the owner back within the hour?"""
    out = []
    for minutes, left in rows:
        for x in CHECKPOINTS:
            if minutes < x:
                break
            moment = dt.datetime.fromtimestamp(left + x * 60)
            out.append((features(x, moment.hour + moment.minute / 60), 1.0 if minutes < x + HORIZON_MIN else 0.0, x, moment.hour))
    return out


def solve(a, b):
    n = len(b)
    m = [row[:] + [v] for row, v in zip(a, b)]
    for i in range(n):
        p = max(range(i, n), key=lambda r: abs(m[r][i]))
        m[i], m[p] = m[p], m[i]
        for r in range(n):
            if r != i and m[i][i]:
                f = m[r][i] / m[i][i]
                m[r] = [u - f * v for u, v in zip(m[r], m[i])]
    return [m[i][n] / m[i][i] if m[i][i] else 0.0 for i in range(n)]


def fit_logistic(data, ridge=PRIOR_STRENGTH, rounds=25):
    """Plain Newton steps, kept free of numpy because hooks run under the system python.
    Pulled toward the Copernican rule, so thin data cannot move the answer far."""
    n = len(data[0][0])
    w = PRIOR[:]
    for _ in range(rounds):
        grad, hess = [0.0] * n, [[0.0] * n for _ in range(n)]
        for x, y, *_ in data:
            z = max(-30, min(30, sum(a * b for a, b in zip(w, x))))
            p = 1 / (1 + math.exp(-z))
            weight = max(p * (1 - p), 1e-6)
            for i in range(n):
                grad[i] += (y - p) * x[i]
                for j in range(n):
                    hess[i][j] += weight * x[i] * x[j]
        for i in range(n):
            grad[i] -= ridge * (w[i] - PRIOR[i])
            hess[i][i] += ridge
        step = solve(hess, grad)
        w = [a + b for a, b in zip(w, step)]
        if max(abs(s) for s in step) < 1e-6:
            break
    return w


def brier(pairs):
    return sum((p - y) ** 2 for p, y in pairs) / max(1, len(pairs))


def evaluate(rows):
    """Score each block of time with a model fitted on the others, against two simple rivals.
    One split alone is too thin: the newest third held only 155 rows and moved the verdict."""
    model, flat_guess, rule = [], [], []
    for k in range(FOLDS):
        a, b = len(rows) * k // FOLDS, len(rows) * (k + 1) // FOLDS
        train, test = samples(rows[:a] + rows[b:]), samples(rows[a:b])
        coef = fit_logistic(train)
        flat = sum(s[1] for s in train) / max(1, len(train))
        for x, y, away, _ in test:
            z = max(-30, min(30, sum(p * q for p, q in zip(coef, x))))
            model.append((1 / (1 + math.exp(-z)), y))
            flat_guess.append((flat, y))
            rule.append((HORIZON_MIN / (away + HORIZON_MIN), y))
    return {"test_rows": len(model), "model": round(brier(model), 4), "flat_guess": round(brier(flat_guess), 4),
            "copernican": round(brier(rule), 4)}


def load():
    try:
        with open(MODEL) as f:
            return json.load(f)["coef"]
    except (OSError, ValueError, KeyError):
        return PRIOR


def chance(away_min, hour):
    """The chance of return within the hour, held away from certainty either way."""
    return max(0.01, min(0.95, predict(load(), away_min, hour)))


def cmd_fit(dry):
    rows = absences()
    if len(rows) < 200:
        print("only %d absences; keeping the current model" % len(rows))
        return 0
    score = evaluate(rows)
    print("absences %d, held-out rows %d: model %.4f, flat guess %.4f, Copernican %.4f (Brier, lower is better)" % (
        len(rows), score["test_rows"], score["model"], score["flat_guess"], score["copernican"]))
    if score["model"] >= score["copernican"]:
        print("no better than the Copernican rule; keeping the current model")
        return 0
    coef = fit_logistic(samples(rows))
    print("coefficients:", [round(c, 4) for c in coef])
    if not dry:
        os.makedirs(os.path.dirname(MODEL), exist_ok=True)
        tmp = MODEL + ".tmp"
        with open(tmp, "w") as f:
            json.dump({"coef": coef, "fitted_at": time.time(), "absences": len(rows), "holdout": score}, f)
        os.replace(tmp, MODEL)
        print("saved", MODEL)
    return 0


def main(argv):
    cmd = argv[0] if argv else ""
    if cmd == "fit":
        return cmd_fit("--dry-run" in argv)
    if cmd == "chance" and len(argv) > 1:
        now = dt.datetime.now()
        hour = float(argv[2]) if len(argv) > 2 else now.hour + now.minute / 60
        print("%.0f%%" % (100 * chance(float(argv[1]), hour)))
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
