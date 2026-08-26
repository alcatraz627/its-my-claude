"""
aggregate.py — Cross-session analysis from signals.

Queries the signals table to produce ranked findings across sessions.
"""

import json
import os
from collections import Counter, defaultdict

MISTAKE_PATTERNS_FILE = os.path.expanduser("~/.claude/mistake-patterns.md")


def aggregate(conn, session_ids=None):
    """Run cross-session aggregation.

    Args:
        conn: SQLite connection
        session_ids: optional list of session IDs to scope (None = all)

    Returns dict with ranked findings.
    """
    where = ""
    params = ()
    if session_ids:
        placeholders = ",".join("?" * len(session_ids))
        where = f"WHERE s.session_id IN ({placeholders})"
        params = tuple(session_ids)

    # Load existing mistake patterns for novelty detection
    known_patterns = _load_known_patterns()

    results = {
        "summary": _session_summary(conn, session_ids),
        "frustration": _top_frustration(conn, where, params),
        "self_corrections": _top_self_corrections(conn, where, params),
        "tool_reliability": _tool_reliability(conn, where, params),
        "repeated_reads": _top_repeated_reads(conn, where, params),
        "skill_outcomes": _skill_reliability(conn, where, params),
        "novel_patterns": [],
    }

    # Detect novel patterns
    results["novel_patterns"] = _detect_novel_patterns(results, known_patterns)

    return results


def _session_summary(conn, session_ids=None):
    """Basic stats across scanned sessions."""
    if session_ids:
        placeholders = ",".join("?" * len(session_ids))
        row = conn.execute(f"""
            SELECT COUNT(*) as total,
                   SUM(turn_count) as turns,
                   SUM(user_turns) as user_t,
                   SUM(assistant_turns) as asst_t
            FROM sessions WHERE id IN ({placeholders})
        """, tuple(session_ids)).fetchone()
    else:
        row = conn.execute("""
            SELECT COUNT(*) as total,
                   SUM(turn_count) as turns,
                   SUM(user_turns) as user_t,
                   SUM(assistant_turns) as asst_t
            FROM sessions
        """).fetchone()

    signal_row = conn.execute("SELECT COUNT(*) as c FROM signals").fetchone()

    return {
        "sessions_scanned": row["total"],
        "total_turns": (row["user_t"] or 0) + (row["asst_t"] or 0),
        "indexed_entries": row["turns"] or 0,  # includes tool_use/tool_result sub-turns
        "user_turns": row["user_t"] or 0,
        "assistant_turns": row["asst_t"] or 0,
        "total_signals": signal_row["c"],
    }


def _top_frustration(conn, where, params, limit=15):
    """Top frustration events ranked by severity and frequency."""
    rows = conn.execute(f"""
        SELECT s.session_id, s.turn_idx, s.severity, s.payload_json,
               ses.project, ses.started
        FROM signals s
        JOIN sessions ses ON ses.id = s.session_id
        {where.replace('s.session_id', 's.session_id')}
        {'AND' if where else 'WHERE'} s.kind = 'user_frustration'
        ORDER BY
            CASE s.severity WHEN 'high' THEN 0 WHEN 'medium' THEN 1 ELSE 2 END,
            ses.started DESC
        LIMIT ?
    """, params + (limit,)).fetchall()

    results = []
    for r in rows:
        payload = json.loads(r["payload_json"]) if r["payload_json"] else {}
        results.append({
            "session_id": r["session_id"][:12],
            "project": r["project"],
            "severity": r["severity"],
            "text": payload.get("text_preview", "")[:100],
            "subtype": payload.get("subtype", ""),
        })
    return results


def _top_self_corrections(conn, where, params, limit=10):
    """Top self-correction events."""
    rows = conn.execute(f"""
        SELECT s.session_id, s.turn_idx, s.payload_json,
               ses.project
        FROM signals s
        JOIN sessions ses ON ses.id = s.session_id
        {where.replace('s.session_id', 's.session_id')}
        {'AND' if where else 'WHERE'} s.kind = 'self_correction'
        ORDER BY ses.started DESC
        LIMIT ?
    """, params + (limit,)).fetchall()

    results = []
    subtypes = Counter()
    for r in rows:
        payload = json.loads(r["payload_json"]) if r["payload_json"] else {}
        subtype = payload.get("subtype", "")
        subtypes[subtype] += 1
        results.append({
            "session_id": r["session_id"][:12],
            "project": r["project"],
            "subtype": subtype,
            "detail": payload.get("text_preview", payload.get("filepath", ""))[:80],
        })
    return {"events": results, "by_subtype": dict(subtypes)}


def _tool_reliability(conn, where, params):
    """Per-tool error rates from tool_error signals."""
    rows = conn.execute(f"""
        SELECT s.payload_json
        FROM signals s
        {where.replace('s.session_id', 's.session_id')}
        {'AND' if where else 'WHERE'} s.kind = 'tool_error'
    """, params).fetchall()

    by_category = Counter()
    by_tool = Counter()
    for r in rows:
        payload = json.loads(r["payload_json"]) if r["payload_json"] else {}
        by_category[payload.get("category", "unknown")] += 1
        if payload.get("tool_name"):
            by_tool[payload["tool_name"]] += 1

    return {
        "total_errors": sum(by_category.values()),
        "by_category": dict(by_category.most_common(10)),
        "high_error_tools": dict(by_tool.most_common(5)),
    }


def _top_repeated_reads(conn, where, params, limit=10):
    """Files read most frequently across sessions."""
    rows = conn.execute(f"""
        SELECT s.payload_json, s.session_id, ses.project
        FROM signals s
        JOIN sessions ses ON ses.id = s.session_id
        {where.replace('s.session_id', 's.session_id')}
        {'AND' if where else 'WHERE'} s.kind = 'repeated_reads'
        ORDER BY json_extract(s.payload_json, '$.read_count') DESC
        LIMIT ?
    """, params + (limit,)).fetchall()

    results = []
    for r in rows:
        payload = json.loads(r["payload_json"]) if r["payload_json"] else {}
        results.append({
            "filepath": payload.get("filepath", ""),
            "read_count": payload.get("read_count", 0),
            "session_id": r["session_id"][:12],
            "project": r["project"],
        })
    return results


def _skill_reliability(conn, where, params):
    """Per-skill success/failure rates."""
    rows = conn.execute(f"""
        SELECT s.payload_json
        FROM signals s
        {where.replace('s.session_id', 's.session_id')}
        {'AND' if where else 'WHERE'} s.kind = 'skill_outcome'
    """, params).fetchall()

    skills = defaultdict(lambda: {
        "total": 0, "confirmed_success": 0, "implicit_success": 0,
        "error_recovered": 0, "error": 0, "rejected": 0, "unknown": 0,
    })
    for r in rows:
        payload = json.loads(r["payload_json"]) if r["payload_json"] else {}
        name = payload.get("skill_name", "unknown")
        outcome = payload.get("outcome", "unknown")
        skills[name]["total"] += 1
        # Map old "success" to "confirmed_success" for backwards compat
        if outcome == "success":
            outcome = "confirmed_success"
        skills[name][outcome] = skills[name].get(outcome, 0) + 1

    return {
        name: {
            "total": s["total"],
            "success_rate": round(
                (s["confirmed_success"] + s["implicit_success"]) / s["total"], 2
            ) if s["total"] else 0,
            **s,
        }
        for name, s in sorted(skills.items(), key=lambda x: -x[1]["total"])
    }


def _load_known_patterns():
    """Load existing mistake patterns for novelty comparison."""
    patterns = set()
    if os.path.exists(MISTAKE_PATTERNS_FILE):
        try:
            with open(MISTAKE_PATTERNS_FILE, "r") as f:
                for line in f:
                    if line.startswith("## Pattern:"):
                        patterns.add(line.strip().replace("## Pattern:", "").strip().lower())
        except OSError:
            pass
    return patterns


def _detect_novel_patterns(results, known_patterns):
    """Identify patterns not yet in mistake-patterns.md."""
    novel = []

    # Check frustration subtypes
    frustration_types = Counter()
    for f in results["frustration"]:
        frustration_types[f["subtype"]] += 1

    for subtype, count in frustration_types.most_common(5):
        normalized = subtype.lower().replace("_", " ")
        if count >= 3 and normalized not in known_patterns:
            novel.append({
                "type": "frustration_pattern",
                "name": subtype,
                "count": count,
                "suggestion": f"User shows '{subtype}' frustration pattern {count} times across sessions",
            })

    # Check self-correction subtypes
    corrections = results["self_corrections"]
    if isinstance(corrections, dict):
        for subtype, count in corrections.get("by_subtype", {}).items():
            normalized = subtype.lower().replace("_", " ")
            if count >= 3 and normalized not in known_patterns:
                novel.append({
                    "type": "self_correction_pattern",
                    "name": subtype,
                    "count": count,
                    "suggestion": f"Assistant self-correction '{subtype}' appears {count} times",
                })

    return novel
