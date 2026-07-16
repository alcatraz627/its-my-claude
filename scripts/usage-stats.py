#!/usr/bin/env python3
"""Usage and cost statistics over the Claude session index.

Answers "what did my Claude usage look like" from the local session index
(~/.claude/assets/scan-sessions/index.db, refreshed daily at 05:00): totals,
per-model and per-project breakdowns, daily trend, and week-over-week
comparison — each with an API-equivalent dollar figure.

Costs are cache-aware: cache reads bill at 0.1x the input rate, 5-minute
cache writes at 1.25x, 1-hour writes at 2x (rates per the Claude API docs,
2026-07). Sessions run on a subscription, so dollars here are what the same
tokens WOULD cost on the API — a comparison metric, not a bill.
"""

import argparse
import sqlite3
import sys
from datetime import date, timedelta
from pathlib import Path

DB = Path.home() / ".claude/assets/scan-sessions/index.db"

# (input, output) $ per 1M tokens. Cache rates derive from input:
# read = 0.1x · 5m write = 1.25x · 1h write = 2x.
# Prefix-matched, longest prefix wins. Models not listed are reported
# as "unpriced" rather than guessed.
RATES = {
    "claude-fable-5":    (10.0, 50.0),
    "claude-opus-4-8":   (5.0, 25.0),
    "claude-opus-4-7":   (5.0, 25.0),
    "claude-opus-4-6":   (5.0, 25.0),
    "claude-sonnet-5":   (3.0, 15.0),   # intro $2/$10 through 2026-08-31, see rate_for()
    "claude-sonnet-4-6": (3.0, 15.0),
    "claude-sonnet-4-5": (3.0, 15.0),
    "claude-haiku-4-5":  (1.0, 5.0),
    "<synthetic>":       (0.0, 0.0),
}
SONNET5_INTRO = (2.0, 10.0)
SONNET5_INTRO_END = "2026-09-01"

# Per-turn token columns, summed. Older records carry only the flat
# cache_creation_input_tokens with no TTL split; those count as 1h writes
# (Claude Code's cache TTL).
SUMS = """
  SUM(COALESCE(json_extract(usage_json,'$.input_tokens'),0)),
  SUM(COALESCE(json_extract(usage_json,'$.output_tokens'),0)),
  SUM(COALESCE(json_extract(usage_json,'$.cache_read_input_tokens'),0)),
  SUM(COALESCE(json_extract(usage_json,'$.cache_creation.ephemeral_5m_input_tokens'),0)),
  SUM(CASE WHEN json_extract(usage_json,'$.cache_creation') IS NULL
       THEN COALESCE(json_extract(usage_json,'$.cache_creation_input_tokens'),0)
       ELSE COALESCE(json_extract(usage_json,'$.cache_creation.ephemeral_1h_input_tokens'),0) END)
"""

BASE_WHERE = "turns.usage_json IS NOT NULL AND turns.usage_json != '' AND turns.model IS NOT NULL"


def rate_for(model, post_intro):
    """(input_rate, output_rate) per MTok, or None when the model is unpriced."""
    if model == "claude-sonnet-5" and not post_intro:
        return SONNET5_INTRO
    for prefix in sorted(RATES, key=len, reverse=True):
        if model.startswith(prefix):
            return RATES[prefix]
    return None


def turn_cost(tokens, rates):
    inp, out, cread, c5m, c1h = tokens
    ri, ro = rates
    return (inp * ri + out * ro + cread * ri * 0.1 + c5m * ri * 1.25 + c1h * ri * 2.0) / 1e6


def date_clause(since, until, col="ts"):
    clauses, params = [], []
    if since:
        clauses.append(f"{col} >= ?")
        params.append(since)
    if until:
        clauses.append(f"{col} < ?")
        params.append(until)
    return (" AND " + " AND ".join(clauses) if clauses else ""), params


def accumulate(agg, key, model, post_intro, toks):
    """Fold one (group, model, era) row into agg[key] = [i,o,cr,c5,c1,cost,unpriced]."""
    cur = agg.setdefault(key, [0, 0, 0, 0, 0, 0.0, False])
    toks = [t or 0 for t in toks]
    for i, t in enumerate(toks):
        cur[i] += t
    rates = rate_for(model, post_intro)
    if rates is None:
        cur[6] = True
    else:
        cur[5] += turn_cost(toks, rates)


def grouped(con, group_expr, since=None, until=None, join="", where_extra="", col="ts"):
    """Aggregate tokens by (group_expr, sonnet5-era, model) and price each slice."""
    dc, params = date_clause(since, until, col)
    rows = con.execute(f"""
        SELECT {group_expr}, ({col} >= '{SONNET5_INTRO_END}'), turns.model, {SUMS}
        FROM turns {join}
        WHERE {BASE_WHERE}{where_extra}{dc}
        GROUP BY 1, 2, 3
    """, params).fetchall()
    agg = {}
    for key, post_intro, model, *toks in rows:
        accumulate(agg, key, model, post_intro, toks)
    return agg


def fmt_tok(n):
    if n >= 1e9:
        return f"{n/1e9:.1f}B"
    if n >= 1e6:
        return f"{n/1e6:.1f}M"
    if n >= 1e3:
        return f"{n/1e3:.0f}K"
    return str(int(n))


def render_table(title, agg, key_header, total_label="total"):
    total_cost = sum(v[5] for v in agg.values())
    print(f"\n{title}")
    print(f"{key_header:<42} {'in':>8} {'out':>8} {'cache-rd':>9} {'cache-wr':>9} {'$ api-eq':>10}")
    print("-" * 92)
    for key, (i, o, cr, c5, c1, dollars, unpriced) in sorted(agg.items(), key=lambda kv: -kv[1][5]):
        d = "unpriced" if unpriced and dollars == 0 else f"${dollars:,.2f}"
        print(f"{str(key)[:42]:<42} {fmt_tok(i):>8} {fmt_tok(o):>8} {fmt_tok(cr):>9} {fmt_tok(c5 + c1):>9} {d:>10}")
    print("-" * 92)
    print(f"{total_label:<42} {'':>8} {'':>8} {'':>9} {'':>9} {f'${total_cost:,.2f}':>10}")


def rangelabel(args):
    since = getattr(args, "since", None)
    until = getattr(args, "until", None)
    if since or until:
        return f" [{since or '…'} → {until or 'now'}]"
    return " [all time]"


def cmd_summary(con, args):
    dc, params = date_clause(args.since, args.until)
    n_sess, n_turns, lo, hi = con.execute(f"""
        SELECT COUNT(DISTINCT session_id), COUNT(*), MIN(date(ts)), MAX(date(ts))
        FROM turns WHERE {BASE_WHERE}{dc}""", params).fetchone()
    agg = grouped(con, "'all'", args.since, args.until)
    tot = agg.get("all", [0, 0, 0, 0, 0, 0.0, False])
    print(f"\nSummary{rangelabel(args)}  ·  {n_sess:,} sessions · {n_turns:,} usage turns · {lo} → {hi}")
    print(f"  input       {fmt_tok(tot[0]):>9}")
    print(f"  output      {fmt_tok(tot[1]):>9}")
    print(f"  cache read  {fmt_tok(tot[2]):>9}   (billed at 0.1x input)")
    print(f"  cache write {fmt_tok(tot[3] + tot[4]):>9}   (5m {fmt_tok(tot[3])} @1.25x · 1h {fmt_tok(tot[4])} @2x)")
    print(f"  API-equivalent cost: ${tot[5]:,.2f}")
    print("  (subscription usage — dollars show what these tokens would cost on the API)")


def cmd_models(con, args):
    render_table("Per-model usage" + rangelabel(args),
                 grouped(con, "model", args.since, args.until), "model")


def cmd_projects(con, args):
    agg = grouped(con, "s.project", args.since, args.until,
                  join="JOIN sessions s ON s.id = turns.session_id", col="turns.ts")
    top = dict(sorted(agg.items(), key=lambda kv: -kv[1][5])[: args.top])
    render_table(f"Per-project usage (top {args.top} of {len(agg)})" + rangelabel(args), top,
                 "project", total_label=f"total (top {len(top)} shown)")


def cmd_daily(con, args):
    since = (date.today() - timedelta(days=args.days)).isoformat()
    agg = grouped(con, "substr(ts,1,10)", since=since)
    print(f"\nDaily usage — last {args.days} days")
    print(f"{'day':<12} {'out-tok':>9} {'$ api-eq':>10}")
    peak = max((v[5] for v in agg.values()), default=1) or 1
    for day, v in sorted(agg.items()):
        bar = "▓" * max(1, int(28 * v[5] / peak))
        print(f"{day:<12} {fmt_tok(v[1]):>9} {f'${v[5]:,.2f}':>10}  {bar}")


def cmd_compare(con, args):
    today = date.today()
    this_start = today - timedelta(days=today.weekday())
    last_start = this_start - timedelta(days=7)

    def week(since, until):
        agg = grouped(con, "'w'", since, until)
        v = agg.get("w", [0, 0, 0, 0, 0, 0.0, False])
        return v[5], v[1]

    c_this, o_this = week(this_start.isoformat(), None)
    c_last, o_last = week(last_start.isoformat(), this_start.isoformat())
    delta = (c_this - c_last) / c_last * 100 if c_last else 0
    hi = con.execute(f"SELECT MAX(date(ts)) FROM turns WHERE {BASE_WHERE}").fetchone()[0]
    print(f"\nWeek-over-week (weeks start Monday · index has data through {hi})")
    print(f"  last week ({last_start} …): ${c_last:,.2f} · ↑{fmt_tok(o_last)} out")
    print(f"  this week ({this_start} …): ${c_this:,.2f} · ↑{fmt_tok(o_this)} out"
          f"  ({delta:+.0f}% vs last, {today.weekday() + 1}/7 days in)")


PAGE = """<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>data-forge · usage stats</title>
<style>
:root { --bg:#191a21; --surface:#20222b; --text:#d8dae3; --dim:#8a8d99; --border:#31343f; --accent:#4fb6a6; }
:root[data-theme=light] { --bg:#f5f4f0; --surface:#ffffff; --text:#23252c; --dim:#71747f; --border:#ddd9d0; --accent:#0e7a6c; }
body { background:var(--bg); color:var(--text); font:14px/1.5 ui-monospace,SFMono-Regular,Menlo,monospace;
       margin:0; padding:16px; }
h1 { font-size:16px; margin:0 0 2px; } h1 b { color:var(--accent); }
.sub { color:var(--dim); font-size:12px; margin-bottom:14px; }
section { background:var(--surface); border:1px solid var(--border); border-radius:8px;
          padding:10px 14px; margin-bottom:12px; overflow-x:auto; }
pre { margin:0; font-size:12.5px; white-space:pre; }
#themeBtn { position:fixed; top:12px; right:12px; background:var(--surface); color:var(--text);
            border:1px solid var(--border); border-radius:6px; padding:4px 10px; cursor:pointer; }
</style></head><body>
<button id="themeBtn">light</button>
<h1><b>data-forge</b> · claude usage</h1>
<div class="sub">%SUB%</div>
%SECTIONS%
<script>
const r=document.documentElement,b=document.getElementById('themeBtn');
const set=t=>{r.dataset.theme=t;b.textContent=t==='dark'?'light':'dark';try{localStorage.setItem('df-theme',t)}catch(e){}};
set((()=>{try{return localStorage.getItem('df-theme')||'dark'}catch(e){return 'dark'}})());
b.onclick=()=>set(r.dataset.theme==='dark'?'light':'dark');
</script></body></html>"""


def render_page(dbp):
    """One self-contained HTML page: every subcommand's output in a card."""
    import contextlib
    import html
    import io

    con = sqlite3.connect(f"file:{dbp}?mode=ro", uri=True)
    sections = []
    specs = [
        (cmd_summary, argparse.Namespace(since=None, until=None)),
        (cmd_compare, argparse.Namespace()),
        (cmd_daily, argparse.Namespace(days=14)),
        (cmd_models, argparse.Namespace(since=None, until=None)),
        (cmd_projects, argparse.Namespace(since=None, until=None, top=15)),
    ]
    for fn, ns in specs:
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            fn(con, ns)
        sections.append(f"<section><pre>{html.escape(buf.getvalue().strip())}</pre></section>")
    con.close()
    from datetime import datetime
    sub = f"index: {dbp} · rendered {datetime.now():%Y-%m-%d %H:%M} · refreshes daily 05:00"
    return PAGE.replace("%SUB%", sub).replace("%SECTIONS%", "\n".join(sections))


def cmd_serve(con, args):
    """Serve the dashboard over HTTP (bind localhost; expose via tailscale serve)."""
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

    con.close()  # each request opens its own read-only connection (thread safety)
    dbp = args.db

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            try:
                body = render_page(dbp).encode()
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Cache-Control", "no-store")
            except Exception as e:
                body = f"data-forge error: {e}".encode()
                self.send_response(500)
                self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *a):
            pass

    srv = ThreadingHTTPServer((args.bind, args.port), Handler)
    print(f"data-forge serving on http://{args.bind}:{args.port}")
    srv.serve_forever()


def main():
    p = argparse.ArgumentParser(
        prog="usage-stats",
        description="Token + API-equivalent cost stats over the local Claude session index.")
    p.add_argument("--db", default=str(DB), help=f"index path (default {DB})")
    sub = p.add_subparsers(dest="cmd")
    for name, hlp in [("summary", "overall totals + cost"), ("models", "per-model breakdown"),
                      ("projects", "per-project breakdown"), ("daily", "per-day trend"),
                      ("compare", "this week vs last week")]:
        sp = sub.add_parser(name, help=hlp)
        if name in ("summary", "models", "projects"):
            sp.add_argument("--since", help="ISO date, inclusive")
            sp.add_argument("--until", help="ISO date, exclusive")
        if name == "projects":
            sp.add_argument("--top", type=int, default=15)
        if name == "daily":
            sp.add_argument("--days", type=int, default=14)
    sv = sub.add_parser("serve", help="serve the stats as a web page (data-forge)")
    sv.add_argument("--port", type=int, default=5103)
    sv.add_argument("--bind", default="127.0.0.1")
    args = p.parse_args()
    if not args.cmd:
        p.print_help()
        return 0
    dbp = Path(args.db)
    if not dbp.exists():
        print(f"index not found: {dbp} — run refresh-session-index.sh first", file=sys.stderr)
        return 1
    con = sqlite3.connect(f"file:{dbp}?mode=ro", uri=True)
    args.db = str(dbp)
    {"summary": cmd_summary, "models": cmd_models, "projects": cmd_projects,
     "daily": cmd_daily, "compare": cmd_compare, "serve": cmd_serve}[args.cmd](con, args)
    return 0


if __name__ == "__main__":
    sys.exit(main())
