#!/usr/bin/env python3
"""ta query — the content-query surface the transcript corpus lacks.

Find the turns that match a set of content filters and print them as jsonl, a
table, a count, or the bare list of files that contain them. The heavy lifting
(discovery, ripgrep pre-filter, per-turn matching) lives in ta_core; this file
is the CLI over it.
"""

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ta_core as C  # noqa: E402


def add_query_args(ap):
    """The shared query flag surface, reused verbatim by `ta mine`."""
    scope = ap.add_argument_group("scope")
    scope.add_argument("--project", metavar="PATH|SUBSTR",
                       help="substring matched against the encoded project-dir name")
    scope.add_argument("--within", type=int, default=30, metavar="DAYS",
                       help="only transcripts modified within N days (default 30)")
    scope.add_argument("--since", metavar="ISO", help="only transcripts since an ISO date")
    scope.add_argument("--all", action="store_true", help="the whole corpus, no date bound")
    scope.add_argument("--include-subagents", action="store_true",
                       help="also scan sub-agent transcripts (default: primary sessions only)")

    filt = ap.add_argument_group("turn filters (AND together)")
    filt.add_argument("--role", choices=["user", "assistant", "any"], default="any",
                      help="which side --match applies to (default any)")
    filt.add_argument("--tool", metavar="NAME",
                      help="turns that invoked a tool_use of this name (e.g. Bash)")
    filt.add_argument("--match", metavar="REGEX", help="regex over the role-scoped text")
    filt.add_argument("--user-match", metavar="REGEX", help="regex over the user text")
    filt.add_argument("--assistant-match", metavar="REGEX", help="regex over the assistant text")
    filt.add_argument("--no-prefilter", action="store_true",
                      help="skip the ripgrep pre-filter (slower, but exact for regexes "
                           "that depend on escaped control chars)")

    ap.add_argument("--limit", type=int, default=0, help="cap rows returned (0 = no cap)")


def spec_from_args(a):
    return {
        "project": a.project,
        "within_days": a.within,
        "since": a.since,
        "all": a.all,
        "include_subagents": a.include_subagents,
        "role": a.role,
        "tool": a.tool,
        "match": a.match,
        "user_match": a.user_match,
        "assistant_match": a.assistant_match,
        "no_prefilter": a.no_prefilter,
        "limit": a.limit or None,
    }


def _short_project(p, width=30):
    if len(p) <= width:
        return p
    return "…" + p[-(width - 1):]


def print_table(rows):
    if not rows:
        print("(no matching turns)")
        return
    print("  %-30s %-9s %-4s %-16s %-5s %s" %
          ("PROJECT", "SESSION", "TURN", "WHEN", "ROLE", "SNIPPET"))
    for r in rows:
        proj = _short_project(r["project"])
        sid = (r["session_id"] or "")[:8]
        when = (r["ts"] or "")[:16].replace("T", " ")
        snip = r["snippet"]
        if len(snip) > 90:
            snip = snip[:89] + "…"
        print("  %-30s %-9s %-4s %-16s %-5s %s" %
              (proj, sid, r["turn_index"], when, r["role"], snip))


def main(argv=None):
    ap = argparse.ArgumentParser(prog="ta query", add_help=True,
                                 description="query the Claude transcript corpus by turn content")
    add_query_args(ap)
    ap.add_argument("--format", choices=["jsonl", "table", "count", "files"],
                    default="table", help="output shape (default table)")
    a = ap.parse_args(argv)

    rows = C.run_query(spec_from_args(a))

    if a.format == "count":
        print(len(rows))
    elif a.format == "files":
        for p in dict.fromkeys(r["transcript_path"] for r in rows):
            print(p)
    elif a.format == "jsonl":
        for r in rows:
            print(json.dumps(r, ensure_ascii=False))
    else:
        print_table(rows)
    return 0


if __name__ == "__main__":
    sys.exit(main())
