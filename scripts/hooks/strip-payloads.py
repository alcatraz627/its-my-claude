#!/usr/bin/env python3
"""Reduce a shell command to the part the shell would actually execute.

A guard that greps the raw command string cannot tell a command from a mention
of one, so it blocks a heredoc that documents a verb, a JSON list that contains
it, and an IPC message that reports it. Four such false fires happened in one
session on 2026-09-04: an index guard fired on a Python list holding permission
patterns, a secret guard fired on a message naming a config file, and a
verification command was refused for quoting the very strings it was checking
were absent.

Heredoc bodies and quoted strings hold prose, not commands. Stripping them
leaves the executable structure, and a verb then only counts at a command
position: start of input, or just after a separator. So `--reason "git push"`
and a backticked mention inside a sentence stay quiet, while a real
`foo && git push` is still seen.

Two ways to use it:

    printf '%s' "$CMD" | strip-payloads.py            # prints the stripped text
    printf '%s' "$CMD" | strip-payloads.py 'git\\s+push' 'pm2\\s+stop'

With patterns, it prints the first one that matches AT A COMMAND POSITION and
exits 0; with no match it prints nothing and exits 1, so a hook can branch on
the exit status. A failure inside this script exits 0 with no output, which
opens the gate rather than blocking everything on a broken scanner.

Lifted from the gcp project's cmd-scan.py, which was written after a gate
blocked a heredoc within ten minutes of shipping.
"""

import re
import sys

SEPARATOR = r"(?:^|[\n;&|(]|&&|\|\||\bthen\b|\bdo\b|\belse\b)\s*"


def strip_heredocs(cmd: str) -> str:
    """Blank heredoc bodies only, leaving quoted strings intact.

    For a guard that must still see a quoted path: a heredoc body is stdin,
    never an argument, so a filename in one is always a mention.
    """
    for match in re.finditer(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1", cmd):
        terminator = match.group(2)
        end = re.search(rf"^\s*{re.escape(terminator)}\s*$", cmd[match.end():], re.M)
        stop = match.end() + (end.start() if end else len(cmd))
        cmd = cmd[: match.end()] + " " * (stop - match.end()) + cmd[stop:]
    return cmd


def strip_payloads(cmd: str) -> str:
    """Remove heredoc bodies and quoted strings, keeping executable structure."""
    for match in re.finditer(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1", cmd):
        terminator = match.group(2)
        end = re.search(rf"^\s*{re.escape(terminator)}\s*$", cmd[match.end():], re.M)
        stop = match.end() + (end.start() if end else len(cmd))
        cmd = cmd[: match.end()] + " " * (stop - match.end()) + cmd[stop:]
    cmd = re.sub(r"'[^']*'", "''", cmd)
    cmd = re.sub(r'"(?:[^"\\]|\\.)*"', '""', cmd)
    return cmd


def first_match(cmd: str, patterns) -> str | None:
    stripped = strip_payloads(cmd)
    for pattern in patterns:
        if re.search(SEPARATOR + pattern, stripped):
            return pattern
    return None


def main() -> int:
    try:
        cmd = sys.stdin.read()
    except Exception:
        return 0
    patterns = sys.argv[1:]
    if patterns and patterns[0] == "--heredocs-only":
        sys.stdout.write(strip_heredocs(cmd))
        return 0
    if not patterns:
        sys.stdout.write(strip_payloads(cmd))
        return 0
    hit = first_match(cmd, patterns)
    if hit is None:
        return 1
    print(hit)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
