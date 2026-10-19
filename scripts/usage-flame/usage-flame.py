#!/usr/bin/env python3
"""A day-or-week view of Claude Code usage as stacked bars and a flame (icicle) graph.

Reads the session transcripts Claude Code already keeps on disk, counts each API
request once, and writes one self-contained HTML page you can filter by model,
platform, subagent, project and more. Nothing runs in the background and no
server or port is involved, so it works the same on any machine with the
transcripts.

    zusage                         build the page for the last 14 days and open it
    zusage --days 30               wider window (first run reads more files)
    zusage --no-open               just write the file and print its path

`zusage` is this script on PATH, registered in zcmd (zcmd which zusage).

Technical notes: a streamed reply writes one transcript record per content block,
all carrying the same message id, so records are deduped by message id and the
largest output count wins. Resumed sessions can repeat history across files, so
the dedupe is global. Per-file results are cached by (mtime, size) under
.cache/, which makes later runs near-instant. Cost reuses RATES and turn_cost
from ../usage-stats.py and is an API-equivalent figure, not a bill.
"""

import argparse
import importlib.util
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import quote

HERE = Path(__file__).resolve().parent
ROOT = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude"))
CACHE = HERE / ".cache" / "requests.json"
DEFAULT_OUT = ROOT / "assets" / "reports" / "usage-flame" / "index.html"
BUCKET = 300  # seconds; the page re-bins from this
CACHE_VERSION = 1

# Request tuple layout, shared by the cache and the aggregation step.
TS, MODEL, ENT, SIDE, AGENT, SKILL, PROJ, SESS, EFF, TIN, TOUT, TCR, TC5, TC1 = range(14)


def load_usage_stats():
    """Pricing helpers from the sibling usage-stats script, or None if unavailable."""
    path = HERE.parent / "usage-stats.py"
    try:
        spec = importlib.util.spec_from_file_location("usage_stats", path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return mod
    except Exception as exc:  # pricing is optional; tokens still chart
        print(f"warning: no cost figures ({exc})", file=sys.stderr)
        return None


def parse_ts(text):
    return datetime.fromisoformat(text[:19]).replace(tzinfo=timezone.utc).timestamp()


def read_file(path, cutoff):
    """{message_id: request tuple} for one transcript, newest-complete record per id."""
    out = {}
    with open(path, errors="replace") as fh:
        for line in fh:
            if '"usage"' not in line:
                continue
            try:
                rec = json.loads(line)
                msg = rec.get("message") or {}
                usage = msg.get("usage")
                model = msg.get("model")
                if not usage or not model or model == "<synthetic>":
                    continue
                ts = parse_ts(rec["timestamp"])
            except (ValueError, KeyError, TypeError):
                continue
            if ts < cutoff:
                continue
            cc = usage.get("cache_creation")
            if cc is None:
                c5, c1 = 0, usage.get("cache_creation_input_tokens") or 0
            else:
                c5 = cc.get("ephemeral_5m_input_tokens") or 0
                c1 = cc.get("ephemeral_1h_input_tokens") or 0
            side = 1 if rec.get("isSidechain") else 0
            cwd = rec.get("cwd") or ""
            row = [
                ts, model, rec.get("entrypoint") or "unknown", side,
                rec.get("attributionAgent") or "-", rec.get("attributionSkill") or "-",
                os.path.basename(cwd.rstrip("/")) or "-",
                (rec.get("sessionId") or "")[:8], rec.get("effort") or "-",
                usage.get("input_tokens") or 0, usage.get("output_tokens") or 0,
                usage.get("cache_read_input_tokens") or 0, c5, c1,
            ]
            mid = msg.get("id") or rec.get("uuid")
            prev = out.get(mid)
            if prev is None or row[TOUT] >= prev[TOUT]:
                out[mid] = row
    return out


def collect(days, rebuild):
    """Every request in the window, deduped across files. Updates the cache."""
    cutoff = time.time() - days * 86400
    cache = {}
    if CACHE.exists() and not rebuild:
        try:
            blob = json.loads(CACHE.read_text())
            if blob.get("v") == CACHE_VERSION and blob.get("cutoff", 0) <= cutoff + 3600:
                cache = blob["files"]
        except (ValueError, KeyError):
            cache = {}
    files = {}
    for p in (ROOT / "projects").rglob("*.jsonl"):
        try:
            st = p.stat()
        except OSError:
            continue
        if st.st_mtime < cutoff:
            continue
        files[str(p)] = (st.st_mtime_ns, st.st_size)
    fresh, reread = {}, 0
    for path, (mtime, size) in files.items():
        hit = cache.get(path)
        if hit and hit["m"] == mtime and hit["s"] == size:
            fresh[path] = hit
            continue
        fresh[path] = {"m": mtime, "s": size, "r": read_file(path, cutoff)}
        reread += 1
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    CACHE.write_text(json.dumps({"v": CACHE_VERSION, "cutoff": cutoff, "files": fresh}))
    merged = {}
    for entry in fresh.values():
        for mid, row in entry["r"].items():
            prev = merged.get(mid)
            if prev is None or row[TOUT] > prev[TOUT]:
                merged[mid] = row
    print(f"{len(files)} transcripts ({reread} re-read), {len(merged)} requests", file=sys.stderr)
    return [r for r in merged.values() if r[TS] >= cutoff]


def aggregate(requests, stats):
    """Dictionary-encode requests into 5-minute rows the page can re-bin."""
    names = {k: [] for k in ("model", "plat", "kind", "agent", "skill", "proj", "sess", "eff")}
    index = {k: {} for k in names}

    def ident(dim, value):
        idx = index[dim]
        if value not in idx:
            idx[value] = len(names[dim])
            names[dim].append(value)
        return idx[value]

    grouped = {}
    unpriced = set()
    for r in requests:
        bucket = int(r[TS] // BUCKET) * BUCKET
        key = (
            bucket, ident("model", r[MODEL]), ident("plat", r[ENT]),
            ident("kind", "subagent" if r[SIDE] else "main"), ident("agent", r[AGENT]),
            ident("skill", r[SKILL]), ident("proj", r[PROJ]), ident("sess", r[SESS]),
            ident("eff", r[EFF]),
        )
        cost = 0.0
        if stats:
            rates = stats.rate_for(r[MODEL], True)
            if rates is None:
                unpriced.add(r[MODEL])
            else:
                cost = stats.turn_cost((r[TIN], r[TOUT], r[TCR], r[TC5], r[TC1]), rates)
        cur = grouped.setdefault(key, [0, 0, 0, 0, 0, 0, 0.0])
        cur[0] += r[TIN]
        cur[1] += r[TOUT]
        cur[2] += r[TCR]
        cur[3] += r[TC5] + r[TC1]
        cur[4] += 1
        cur[6] += cost
    rows = [list(k) + v[:5] + [round(v[6], 5)] for k, v in sorted(grouped.items())]
    return {"names": names, "rows": rows, "unpriced": sorted(unpriced), "built": time.time()}


def head_tags(stamp, icon):
    """Replacement for the kit's bare <title>: dated title, favicon from the page icon, and meta tags."""
    desc = "Claude Code usage by model, platform and subagent, built from local session transcripts."
    # A favicon has no page CSS, so the icon's currentColor becomes the brand blue, readable on light and dark tabs.
    fav = "data:image/svg+xml," + quote(icon.replace("currentColor", "#3987e5"))
    title = f"Usage | {stamp}"
    return (
        f"<title>{title}</title>\n"
        f'<link rel="icon" type="image/svg+xml" href="{fav}">\n'
        f'<meta name="description" content="{desc}">\n'
        '<meta name="application-name" content="Claude Usage">\n'
        '<meta name="generator" content="zusage">\n'
        '<meta name="robots" content="noindex, nofollow">\n'
        '<meta name="color-scheme" content="dark light">\n'
        '<meta name="theme-color" content="#0b0e13" media="(prefers-color-scheme: dark)">\n'
        '<meta name="theme-color" content="#f7f8fa" media="(prefers-color-scheme: light)">\n'
        f'<meta property="og:title" content="{title}">\n'
        f'<meta property="og:description" content="{desc}">'
    )


def render(data, out):
    sys.path.insert(0, str(ROOT / "scripts" / "pages"))
    import pagekit

    try:
        icon = (HERE / "icon.svg").read_text()
    except OSError:
        icon = ""
    blob = json.dumps(dict(data, icon=icon), separators=(",", ":")).replace("<", "\\u003c")
    body = (
        '<div id="app"><p class="uf-loading">Loading usage data…</p></div>\n'
        f'<script id="uf-data" type="application/json">{blob}</script>'
    )
    html = pagekit.page(
        "Usage", body,
        extra_css=(HERE / "view.css").read_text(),
        extra_js=(HERE / "view.js").read_text(),
    )
    stamp = datetime.fromtimestamp(data["built"]).strftime("%a %d %b %Y, %H:%M")
    html = html.replace("<title>Usage</title>", head_tags(stamp, icon), 1)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(html)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--days", type=int, default=14, help="window to include (default 14)")
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--no-open", action="store_true", help="write the file, do not open it")
    ap.add_argument("--rebuild", action="store_true", help="ignore the cache and re-read everything")
    args = ap.parse_args()

    started = time.time()
    data = aggregate(collect(args.days, args.rebuild), load_usage_stats())
    render(data, args.out)
    print(f"{args.out} ({len(data['rows'])} rows, {time.time() - started:.1f}s)")
    if not args.no_open and sys.platform == "darwin":
        subprocess.run(["open", str(args.out)], check=False)


if __name__ == "__main__":
    main()
