#!/usr/bin/env python3
"""Says whether the assistant's last turn edited or wrote anything.

A hook that reacts to the owner's reply ("good call") only has something to
react to when the turn before it changed a file. This reads the tail of the
session transcript and exits 0 if that turn used Edit, Write, MultiEdit or
NotebookEdit, 1 if not, 2 when the transcript cannot be read.

Usage: turn-changed.py <transcript.jsonl> [current-prompt-text]
The current prompt may or may not already be in the transcript; when it is, it
is skipped so the turn before it is the one inspected.
"""
import json
import os
import sys

MUTATING = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
TAIL_BYTES = 600_000


def prompt_text(entry):
    msg = entry.get("message") or {}
    if msg.get("role") != "user" or entry.get("isMeta"):
        return None
    content = msg.get("content")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        if any(isinstance(b, dict) and b.get("type") == "tool_result" for b in content):
            return None
        return "".join(b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text")
    return None


def main():
    if len(sys.argv) < 2 or not os.path.isfile(sys.argv[1]):
        return 2
    current = (sys.argv[2] if len(sys.argv) > 2 else "").strip()
    with open(sys.argv[1], "rb") as f:
        f.seek(0, os.SEEK_END)
        size = f.tell()
        f.seek(max(0, size - TAIL_BYTES))
        data = f.read().decode("utf-8", "replace")
    lines = data.splitlines()[1:] if size > TAIL_BYTES else data.splitlines()
    skipped_current = False
    for line in reversed(lines):
        try:
            entry = json.loads(line)
        except Exception:
            continue
        text = prompt_text(entry)
        if text is not None:
            if not skipped_current and current and text.strip() == current:
                skipped_current = True
                continue
            return 1
        msg = entry.get("message") or {}
        if msg.get("role") == "assistant" and isinstance(msg.get("content"), list):
            for b in msg["content"]:
                if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") in MUTATING:
                    return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
