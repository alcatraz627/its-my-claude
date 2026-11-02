#!/usr/bin/env python3
"""Pull every hook-originated message out of session transcripts, for measuring hooks by what
the model actually saw rather than by what each hook chose to log.

Run on demand; nothing schedules it. Reads ~/.claude/projects, writes one JSONL per message
class into --out, and measure.py turns that folder into numbers.

    scan.py --since 2026-10-25T00:00:00 --until 2026-11-01T14:40:00 --out DIR

Times are compared as text against the transcript's UTC timestamps.
"""
import argparse
import collections
import datetime
import glob
import json
import os
import re

ROOT = os.environ.get("HOOK_AUDIT_PROJECTS", os.path.expanduser("~/.claude/projects"))
# A tool result that a hook stopped, as opposed to one that merely failed.
DENIAL = re.compile(r"hook error|blocked by hook|PreToolUse:|BLOCKED|\[guard")


def text_of(content):
    """The readable text of a message body, whichever shape the transcript stored it in."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        out = []
        for part in content:
            if isinstance(part, dict):
                if part.get("type") == "text":
                    out.append(part.get("text", ""))
                elif part.get("type") == "tool_result":
                    out.append(text_of(part.get("content")))
        return "\n".join(out)
    return ""


def tool_uses(content):
    if not isinstance(content, list):
        return []
    return [p for p in content if isinstance(p, dict) and p.get("type") == "tool_use"]


def scan(root, since, until, out):
    """Write the message classes for one window into out, and return a summary of what was read."""
    os.makedirs(out, exist_ok=True)
    floor = datetime.datetime.fromisoformat(since).timestamp() - 86400
    files = [f for f in glob.glob(f"{root}/**/*.jsonl", recursive=True) if os.path.getmtime(f) >= floor]
    attach_types = collections.Counter()
    sessions = {}
    scanned = 0
    with open(f"{out}/stop_blocks.jsonl", "w") as stop, open(f"{out}/attachments.jsonl", "w") as attach, \
            open(f"{out}/tool_denials.jsonl", "w") as pre, open(f"{out}/stop_summaries.jsonl", "w") as summary:
        for path in files:
            scanned += os.path.getsize(path)
            sub = "/subagents/" in path
            last_assistant = last_tool = last_prompt = ""
            pending = []
            turns = 0
            sid = first_prompt = entrypoint = None
            in_window = False
            with open(path, errors="replace") as handle:
                for raw in handle:
                    try:
                        row = json.loads(raw)
                    except ValueError:
                        continue
                    ts = str(row.get("timestamp", ""))
                    if ts and (ts < since or ts >= until):
                        continue
                    # Bookkeeping rows carry no time, so alone they do not put a session in the window.
                    in_window = in_window or bool(ts)
                    kind = row.get("type")
                    sid = row.get("sessionId") or sid
                    entrypoint = row.get("entrypoint") or entrypoint
                    msg = row.get("message") if isinstance(row.get("message"), dict) else {}
                    base = {"ts": ts, "sid": sid, "cwd": row.get("cwd"), "sub": sub, "file": path}
                    if kind == "assistant":
                        body = text_of(msg.get("content"))
                        if body.strip():
                            last_assistant = body
                        uses = tool_uses(msg.get("content"))
                        if uses:
                            last_tool = json.dumps({"name": uses[-1].get("name"), "input": uses[-1].get("input")})[:600]
                        if body.strip() or uses:
                            for item in pending:
                                item["next_text"] = body[:1200]
                                item["next_tool"] = last_tool if uses else ""
                                stop.write(json.dumps(item) + "\n")
                            pending = []
                    elif kind == "user":
                        body = text_of(msg.get("content"))
                        if isinstance(msg.get("content"), str) and row.get("isMeta") and body.lstrip().startswith("[keepwarm]"):
                            last_prompt = body
                        if not row.get("isMeta") and isinstance(msg.get("content"), str):
                            turns += 1
                            last_prompt = body
                            if first_prompt is None:
                                first_prompt = body[:300]
                        if body.startswith("Stop hook feedback:"):
                            pending.append({**base, "text": body[len("Stop hook feedback:"):].strip()[:2500],
                                            "prev_assistant": last_assistant[-2500:], "turn": turns})
                        elif isinstance(msg.get("content"), list):
                            for part in msg["content"]:
                                if isinstance(part, dict) and part.get("type") == "tool_result":
                                    result = text_of(part.get("content"))
                                    if DENIAL.search(result[:400]):
                                        pre.write(json.dumps({**base, "text": result[:1500], "tool": last_tool,
                                                              "is_error": part.get("is_error")}) + "\n")
                    elif kind == "attachment":
                        att = row.get("attachment") or {}
                        atype = att.get("type")
                        attach_types[atype] += 1
                        if str(atype).startswith("hook"):
                            content = att.get("content") or att.get("stdout") or ""
                            if not isinstance(content, str):
                                content = json.dumps(content)
                            is_prompt = att.get("hookEvent") == "UserPromptSubmit"
                            attach.write(json.dumps({**base, "atype": atype, "hook": att.get("hookName"),
                                                     "event": att.get("hookEvent"), "chars": len(content),
                                                     "text": content[:1500], "prompt": last_prompt[:60000] if is_prompt else "",
                                                     "last_tool": last_tool[:300]}) + "\n")
                    elif kind == "system" and row.get("subtype") == "stop_hook_summary":
                        summary.write(json.dumps({**base, "infos": row.get("hookInfos"), "errors": row.get("hookErrors"),
                                                  "prevented": row.get("preventedContinuation"), "count": row.get("hookCount")}) + "\n")
            for item in pending:
                stop.write(json.dumps(item) + "\n")
            if sid and in_window:
                entry = sessions.setdefault(sid, {"sub": sub, "turns": 0, "cwd": None, "first": None, "entry": None})
                entry["sub"] = entry["sub"] and sub
                entry["turns"] += turns
                if not sub and first_prompt:
                    entry["first"] = first_prompt
                entry["entry"] = entry["entry"] or entrypoint
    with open(f"{out}/sessions.json", "w") as f:
        json.dump(sessions, f)
    with open(f"{out}/window.json", "w") as f:
        json.dump({"since": since, "until": until, "files": len(files)}, f)
    return {"files": len(files), "gb": round(scanned / 1e9, 2), "sessions": len(sessions),
            "attachment_types": attach_types.most_common(8)}


def when(text):
    """A window edge, checked now rather than failing after a long read."""
    try:
        datetime.datetime.fromisoformat(text)
    except ValueError:
        raise argparse.ArgumentTypeError("%r is not a time like 2026-10-25T00:00:00" % text)
    return text


def main():
    parser = argparse.ArgumentParser(description="Extract hook messages from session transcripts.")
    parser.add_argument("--since", required=True, type=when, help="start of the window, UTC, e.g. 2026-10-25T00:00:00")
    parser.add_argument("--until", required=True, type=when, help="end of the window, UTC, exclusive")
    parser.add_argument("--out", required=True, help="folder to write into")
    parser.add_argument("--root", default=ROOT, help="transcript root (default ~/.claude/projects)")
    args = parser.parse_args()
    print(json.dumps(scan(args.root, args.since, args.until, args.out)))


if __name__ == "__main__":
    main()
