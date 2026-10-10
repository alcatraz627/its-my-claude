#!/usr/bin/env python3
"""Search local Codex rollouts and Claude Code transcripts by message text."""

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

HOME = Path.home()
CODEX_ROOTS = (HOME / ".codex/sessions", HOME / ".codex/archived_sessions")
CLAUDE_QUERY = HOME / ".claude/scripts/transcript-audit/ta"
CLAUDE_PROJECTS = HOME / ".claude/projects"


def text_blocks(content):
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""
    return "\n".join(
        block.get("text", "") for block in content
        if isinstance(block, dict) and block.get("type") in ("input_text", "output_text", "text")
    )


def codex_messages(path):
    session_id = path.stem.rsplit("-", 5)[-5:]
    session_id = "-".join(session_id) if len(session_id) == 5 else path.stem
    project = ""
    subagent = False
    with path.open(errors="replace") as stream:
        for line_no, line in enumerate(stream, 1):
            try:
                record = json.loads(line)
            except ValueError:
                continue
            payload = record.get("payload") or {}
            if record.get("type") == "session_meta":
                session_id = payload.get("id") or payload.get("session_id") or session_id
                project = payload.get("cwd") or project
                subagent = isinstance(payload.get("source"), dict) and "subagent" in payload["source"]
            if record.get("type") != "response_item" or payload.get("type") != "message":
                continue
            role = payload.get("role")
            if role not in ("user", "assistant"):
                continue
            message = text_blocks(payload.get("content"))
            if message and not message.startswith("# AGENTS.md instructions"):
                yield {
                    "source": "codex", "project": project, "session_id": session_id,
                    "transcript_path": str(path), "line": line_no,
                    "ts": record.get("timestamp"), "role": role, "text": message,
                    "subagent": subagent,
                }


def codex_query(query, project, role, days, session, include_archived, include_subagents):
    roots = CODEX_ROOTS if include_archived else CODEX_ROOTS[:1]
    files = [p for root in roots if root.exists() for p in root.rglob("rollout-*.jsonl")]
    if session:
        files = [p for p in files if session in p.name]
    if days is not None:
        cutoff = datetime.now(timezone.utc) - timedelta(days=days)
        files = [p for p in files if datetime.fromtimestamp(p.stat().st_mtime, timezone.utc) >= cutoff]
    if not files:
        return []
    command = ["rg", "-l", "-i", "-F", "--no-config", "--", query, *(str(p) for p in files)]
    found = subprocess.run(command, capture_output=True, text=True)
    if found.returncode not in (0, 1):
        raise RuntimeError(f"rg failed: {found.stderr.strip()}")
    hits = []
    needle = query.casefold()
    for name in found.stdout.splitlines():
        for row in codex_messages(Path(name)):
            if row.pop("subagent") and not include_subagents:
                continue
            if project and project.casefold() not in row["project"].casefold():
                continue
            if role != "any" and row["role"] != role:
                continue
            if needle not in row["text"].casefold():
                continue
            offset = row["text"].casefold().find(needle)
            row["snippet"] = row.pop("text")[max(0, offset - 80):offset + len(query) + 120].replace("\n", " ")
            hits.append(row)
    return hits


def claude_query(query, project, role, days, session, include_subagents):
    command = ["bash", str(CLAUDE_QUERY), "query", "--all", "--match", re.escape(query),
               "--role", role, "--format", "jsonl", "--limit", "0"]
    if project:
        command += [f"--project={project}"]
    if days is not None:
        command += ["--since", (datetime.now(timezone.utc) - timedelta(days=days)).date().isoformat()]
        command.remove("--all")
    if include_subagents:
        command.append("--include-subagents")
    run = subprocess.run(command, capture_output=True, text=True)
    if run.returncode:
        raise RuntimeError(f"Claude transcript query failed: {run.stderr.strip()}")
    rows = []
    for line in run.stdout.splitlines():
        row = json.loads(line)
        if session and session not in row.get("session_id", "") and session not in row.get("transcript_path", ""):
            continue
        row["source"] = "claude"
        rows.append(row)
    return rows


def raw_query(query, source, project, days, session, include_archived, include_subagents):
    roots = []
    if source in ("both", "codex"):
        roots.extend(CODEX_ROOTS if include_archived else CODEX_ROOTS[:1])
    if source in ("both", "claude"):
        roots.append(CLAUDE_PROJECTS)
    needle = query.casefold()
    cutoff = datetime.now(timezone.utc) - timedelta(days=days) if days is not None else None
    rows = []
    for root in roots:
        if not root.exists():
            continue
        command = ["rg", "-l", "-i", "-F", "--no-config", "-g", "*.jsonl", "--", query, str(root)]
        found = subprocess.run(command, capture_output=True, text=True)
        if found.returncode not in (0, 1):
            raise RuntimeError(f"rg failed: {found.stderr.strip()}")
        for name in found.stdout.splitlines():
            path = Path(name)
            is_claude = root == CLAUDE_PROJECTS
            if is_claude and not include_subagents and len(path.relative_to(root).parts) > 2:
                continue
            cwd = ""
            if not is_claude:
                with path.open(errors="replace") as stream:
                    first = stream.readline()
                try:
                    meta = json.loads(first).get("payload") or {}
                except ValueError:
                    meta = {}
                if not include_subagents and isinstance(meta.get("source"), dict) and "subagent" in meta["source"]:
                    continue
                cwd = meta.get("cwd") or ""
            if session and session not in path.name:
                continue
            if cutoff and datetime.fromtimestamp(path.stat().st_mtime, timezone.utc) < cutoff:
                continue
            if project:
                if is_claude:
                    if project.casefold().replace("/", "-").replace(".", "-") not in str(path.parent).casefold():
                        continue
                elif project.casefold() not in cwd.casefold():
                    continue
            with path.open(errors="replace") as stream:
                for line_no, line in enumerate(stream, 1):
                    offset = line.casefold().find(needle)
                    if offset < 0:
                        continue
                    try:
                        record = json.loads(line)
                    except ValueError:
                        record = {}
                    rows.append({
                        "source": "claude" if is_claude else "codex", "project": project or "",
                        "session_id": path.stem, "transcript_path": str(path), "line": line_no,
                        "ts": record.get("timestamp"), "role": "raw",
                        "event_type": record.get("type"),
                        "snippet": line[max(0, offset - 80):offset + len(query) + 120].replace("\n", " "),
                    })
    return rows


def show(argv):
    parser = argparse.ArgumentParser(prog="transcript-search show")
    parser.add_argument("path", type=Path, help="absolute transcript_path returned by query")
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument("--line", type=int, help="Codex JSONL line number")
    target.add_argument("--turn", type=int, help="Claude turn_index")
    target.add_argument("--raw-line", type=int, help="JSONL line number from --raw search")
    parser.add_argument("--max-chars", type=int, default=12000)
    args = parser.parse_args(argv)
    path = args.path.resolve()
    roots = CODEX_ROOTS if args.line else ((CLAUDE_PROJECTS, *CODEX_ROOTS) if args.raw_line else (CLAUDE_PROJECTS,))
    if not any(path.is_relative_to(root.resolve()) for root in roots) or not path.is_file():
        parser.error("path must be an existing local transcript under the selected source")
    if args.max_chars < 1:
        parser.error("--max-chars must be positive")
    if args.raw_line:
        if args.raw_line < 1:
            parser.error("--raw-line must be positive")
        with path.open(errors="replace") as stream:
            for line_no, line in enumerate(stream, 1):
                if line_no == args.raw_line:
                    print(f"JSONL {path}:{line_no}")
                    print(line[:args.max_chars])
                    return 0
        parser.error("raw line is past end of transcript")
    if args.line:
        if args.line < 1:
            parser.error("--line must be positive")
        for row in codex_messages(path):
            if row["line"] == args.line:
                print(f'{row["role"]} {row["ts"]} {path}:{args.line}')
                print(row["text"][:args.max_chars])
                return 0
        parser.error("line is not a user or assistant message")
    if args.turn < 0:
        parser.error("--turn must be nonnegative")
    replay = HOME / ".claude/scripts/hooks/replay"
    sys.path.insert(0, str(replay))
    import replay_lib
    turns = replay_lib.split_turns(replay_lib.load_lines(path))
    if args.turn >= len(turns):
        parser.error(f"turn out of range (0 through {len(turns) - 1})")
    turn = turns[args.turn]
    print(f"Claude turn {args.turn} {path}")
    print("USER\n" + replay_lib.turn_user_text(turn)[:args.max_chars])
    print("ASSISTANT\n" + replay_lib.turn_assistant_text(turn)[:args.max_chars])
    return 0


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "show":
        return show(sys.argv[2:])
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("query", help="literal, case-insensitive phrase")
    parser.add_argument("--source", choices=("both", "codex", "claude"), default="both")
    parser.add_argument("--role", choices=("any", "user", "assistant"), default="any")
    parser.add_argument("--project", help="project path substring")
    parser.add_argument("--session", help="full or partial session ID")
    parser.add_argument("--days", type=int, help="limit by transcript modification time")
    parser.add_argument("--include-subagents", action="store_true", help="include subagent transcripts")
    parser.add_argument("--raw", action="store_true", help="search all JSONL events, including tool calls and results")
    parser.add_argument("--no-archived", action="store_true", help="exclude archived Codex sessions")
    parser.add_argument("--format", choices=("table", "jsonl", "files", "count"), default="table")
    parser.add_argument("--limit", type=int, default=20, help="maximum returned rows; 0 means all")
    args = parser.parse_args()
    if args.days is not None and args.days < 0:
        parser.error("--days must be nonnegative")
    if args.limit < 0:
        parser.error("--limit must be nonnegative")
    rows = []
    try:
        if args.raw:
            if args.role != "any":
                parser.error("--role applies to message search; omit it with --raw")
            rows = raw_query(args.query, args.source, args.project, args.days, args.session, not args.no_archived, args.include_subagents)
        elif args.source in ("both", "codex"):
            rows += codex_query(args.query, args.project, args.role, args.days, args.session, not args.no_archived, args.include_subagents)
        if not args.raw and args.source in ("both", "claude"):
            rows += claude_query(args.query, args.project, args.role, args.days, args.session, args.include_subagents)
    except RuntimeError as exc:
        parser.exit(1, f"transcript-search: {exc}\n")
    rows.sort(key=lambda row: row.get("ts") or "", reverse=True)
    if args.limit:
        rows = rows[:args.limit]
    if args.format == "count":
        print(len(rows))
    elif args.format == "files":
        for path in dict.fromkeys(row["transcript_path"] for row in rows):
            print(path)
    elif args.format == "jsonl":
        for row in rows:
            print(json.dumps(row, ensure_ascii=False))
    else:
        for row in rows:
            location = row["transcript_path"]
            if row.get("line"):
                location += f':{row["line"]}'
            print(f'{row["source"]} {row["role"]} {row.get("ts") or ""} {location}')
            print("  " + (row.get("snippet") or "")[:220])
    return 0


if __name__ == "__main__":
    sys.exit(main())
