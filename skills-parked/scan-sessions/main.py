#!/usr/bin/env python3
"""
main.py — Entry point for scan-sessions skill.

Usage:
    python3 main.py                          # scan last 7 days
    python3 main.py --since 2026-04-01       # scan from date
    python3 main.py --project frontend       # filter by project
    python3 main.py --rescan                 # force full re-crawl
    python3 main.py --report                 # generate HTML report
    python3 main.py --emit-proposals         # file top findings as proposals
    python3 main.py --limit 50              # limit sessions to process
"""

import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone, timedelta

# Add skill directory to path
sys.path.insert(0, os.path.dirname(__file__))

from crawl import get_db, crawl
from signals import ALL_EXTRACTORS
from aggregate import aggregate


def parse_args():
    p = argparse.ArgumentParser(description="Deep-scan Claude Code sessions")
    p.add_argument("--since", help="Start date (YYYY-MM-DD)")
    p.add_argument("--until", help="End date (YYYY-MM-DD)")
    p.add_argument("--project", help="Filter by project name (substring match)")
    p.add_argument("--rescan", action="store_true", help="Force full re-crawl")
    p.add_argument("--report", action="store_true", help="Generate HTML report")
    p.add_argument("--emit-proposals", action="store_true", help="File top findings as proposals")
    p.add_argument("--limit", type=int, default=100, help="Max sessions to process signals for")
    p.add_argument("--json", action="store_true", help="Output raw JSON")
    return p.parse_args()


def main():
    args = parse_args()
    t0 = time.time()

    # Phase A: Crawl
    conn = get_db()
    new, updated, skipped = crawl(conn, rescan=args.rescan)
    crawl_time = time.time() - t0

    print(json.dumps({
        "phase": "crawl",
        "new_sessions": new,
        "updated_sessions": updated,
        "skipped_unchanged": skipped,
        "elapsed_s": round(crawl_time, 2),
    }), file=sys.stderr)

    # Resolve scope
    session_ids = _resolve_scope(conn, args)

    print(json.dumps({
        "phase": "scope",
        "sessions_in_scope": len(session_ids),
    }), file=sys.stderr)

    # Phase B: Extract signals
    t1 = time.time()
    signal_count = 0

    for sid in session_ids:
        # Clear old signals for this session
        conn.execute("DELETE FROM signals WHERE session_id = ?", (sid,))

        for kind_name, extractor in ALL_EXTRACTORS:
            try:
                signals = extractor(conn, sid)
                for sig in signals:
                    conn.execute("""
                        INSERT INTO signals (session_id, turn_idx, kind, severity, payload_json, created_at)
                        VALUES (?, ?, ?, ?, ?, ?)
                    """, (
                        sig["session_id"],
                        sig["turn_idx"],
                        sig["kind"],
                        sig.get("severity", "info"),
                        json.dumps(sig.get("payload", {})),
                        datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                    ))
                    signal_count += 1
            except Exception as e:
                print(json.dumps({
                    "phase": "signals",
                    "error": f"{kind_name} on {sid[:12]}: {e}",
                }), file=sys.stderr)

    conn.commit()
    signal_time = time.time() - t1

    print(json.dumps({
        "phase": "signals",
        "signals_extracted": signal_count,
        "elapsed_s": round(signal_time, 2),
    }), file=sys.stderr)

    # Phase C: Aggregate
    t2 = time.time()
    results = aggregate(conn, session_ids)
    results["timing"] = {
        "crawl_s": round(crawl_time, 2),
        "signals_s": round(signal_time, 2),
        "aggregate_s": round(time.time() - t2, 2),
        "total_s": round(time.time() - t0, 2),
    }

    # Phase D: Output
    if args.json:
        print(json.dumps(results, indent=2))
    elif args.report:
        from report import generate_report
        report_path = generate_report(results)
        print(f"HTML report: {report_path}", file=sys.stderr)
        _print_report(results)
    else:
        _print_report(results)

    # Emit proposals if requested
    if args.emit_proposals:
        _emit_proposals(results)

    conn.close()


def _resolve_scope(conn, args):
    """Resolve session IDs matching the scope filters."""
    clauses = []
    params = []

    if args.since:
        clauses.append("started >= ?")
        params.append(args.since)
    else:
        # Default: last 7 days
        week_ago = (datetime.now(timezone.utc) - timedelta(days=7)).strftime("%Y-%m-%d")
        clauses.append("started >= ?")
        params.append(week_ago)

    if args.until:
        clauses.append("started <= ?")
        params.append(args.until)

    if args.project:
        clauses.append("project LIKE ?")
        params.append(f"%{args.project}%")

    where = "WHERE " + " AND ".join(clauses) if clauses else ""
    query = f"SELECT id FROM sessions {where} ORDER BY started DESC LIMIT ?"
    params.append(args.limit)

    rows = conn.execute(query, params).fetchall()
    return [r["id"] for r in rows]


def _print_report(results):
    """Print a human-readable summary."""
    s = results["summary"]
    print(f"\n{'='*60}")
    print(f"  SCAN-SESSIONS REPORT")
    print(f"{'='*60}")
    print(f"  Sessions: {s['sessions_scanned']}  |  Turns: {s['total_turns']:,}  |  Signals: {s['total_signals']}")
    t = results.get("timing", {})
    print(f"  Time: {t.get('total_s', '?')}s (crawl {t.get('crawl_s', '?')}s, signals {t.get('signals_s', '?')}s)")
    print()

    # Frustration
    frust = results.get("frustration", [])
    if frust:
        print(f"  FRUSTRATION SIGNALS ({len(frust)} found)")
        print(f"  {'-'*56}")
        for f in frust[:8]:
            sev = {"high": "!!", "medium": " !", "low": "  "}[f["severity"]]
            text = f["text"][:60].replace("\n", " ")
            print(f"  {sev} [{f['project'][:15]:<15}] {text}")
        print()

    # Self-corrections
    corr = results.get("self_corrections", {})
    if isinstance(corr, dict) and corr.get("events"):
        by_sub = corr.get("by_subtype", {})
        print(f"  SELF-CORRECTIONS ({len(corr['events'])} events)")
        print(f"  {'-'*56}")
        for subtype, count in sorted(by_sub.items(), key=lambda x: -x[1])[:5]:
            print(f"    {subtype:<20} {count}x")
        print()

    # Tool reliability
    tools = results.get("tool_reliability", {})
    if tools.get("total_errors"):
        print(f"  TOOL ERRORS ({tools['total_errors']} total)")
        print(f"  {'-'*56}")
        for cat, count in sorted(tools.get("by_category", {}).items(), key=lambda x: -x[1]):
            print(f"    {cat:<20} {count}x")
        print()

    # Repeated reads
    rr = results.get("repeated_reads", [])
    if rr:
        print(f"  REPEATED READS (top {len(rr)})")
        print(f"  {'-'*56}")
        for r in rr[:5]:
            fp = r["filepath"]
            if len(fp) > 45:
                fp = "..." + fp[-42:]
            print(f"    {r['read_count']}x  {fp}")
        print()

    # Skill outcomes
    skills = results.get("skill_outcomes", {})
    if skills:
        print(f"  SKILL RELIABILITY ({len(skills)} skills)")
        print(f"  {'-'*56}")
        for name, data in list(skills.items())[:8]:
            rate = f"{data['success_rate']*100:.0f}%" if data['total'] else "?"
            print(f"    {name:<25} {data['total']:>3} uses  {rate} success")
        print()

    # Novel patterns
    novel = results.get("novel_patterns", [])
    if novel:
        print(f"  NOVEL PATTERNS ({len(novel)} new)")
        print(f"  {'-'*56}")
        for n in novel:
            print(f"    * {n['suggestion']}")
        print()

    print(f"{'='*60}\n")


def _emit_proposals(results):
    """File top findings as proposals via propose.sh."""
    import subprocess

    novel = results.get("novel_patterns", [])
    for pattern in novel[:3]:
        try:
            subprocess.run([
                "bash", os.path.expanduser("~/.claude/scripts/propose.sh"), "add",
                "--title", pattern["suggestion"][:80],
                "--body", f"Auto-detected by scan-sessions. Type: {pattern['type']}, count: {pattern['count']}.",
                "--category", "config",
                "--effort", "small",
                "--tags", "auto-scan session-analysis",
            ], capture_output=True, text=True, timeout=5)
        except (subprocess.TimeoutExpired, OSError):
            pass


if __name__ == "__main__":
    main()
