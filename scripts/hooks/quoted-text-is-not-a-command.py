#!/usr/bin/env python3
"""A word inside a quoted string or a heredoc is not a command.

The ask and deny tiers match substrings anywhere in a Bash command, so an ipc
message body, a commit message, an echo, or a heredoc that mentions "gcloud run
deploy" or "git push" prompts the owner as if the agent were deploying. Owner
ruling 2026-09-10: the classifier must not trip on word mentions.

This hook re-reads the ask and deny globs from the global and project settings,
strips every quoted string and heredoc body from the command, and matches the
globs against what is left. If a glob matched the full command but none matches
the stripped command, the only match was inside quoted text, and the command is
allowed. In every other case the hook stays silent and the tiers decide as
before, so a real deploy, a chained deploy, or a deploy hidden behind a pipe is
untouched.
"""
import fnmatch
import json
import os
import re
import sys

HOME = os.path.expanduser("~")


def load_globs(cwd: str) -> list[str]:
    files = [os.path.join(HOME, ".claude", "settings.json")]
    if cwd:
        files += [os.path.join(cwd, ".claude", "settings.json"),
                  os.path.join(cwd, ".claude", "settings.local.json")]
    globs: list[str] = []
    for f in files:
        try:
            with open(f) as fh:
                perms = json.load(fh).get("permissions", {}) or {}
        except Exception:  # noqa: BLE001  an unreadable file adds nothing
            continue
        for tier in ("ask", "deny"):
            for entry in perms.get(tier, []) or []:
                if isinstance(entry, str) and entry.startswith("Bash(") and entry.endswith(")"):
                    globs.append(entry[5:-1])
    return globs


def glob_matches(glob: str, command: str) -> bool:
    "The tier's own reading: `X:*` and `X *` anchor at the start, `*X*` matches anywhere."
    if ":" in glob and not glob.startswith("*"):
        head = glob.split(":", 1)[0]
        return command == head or command.startswith(head + " ")
    return fnmatch.fnmatchcase(command, glob)


HEREDOC = re.compile(r"<<-?\s*(['\"]?)(\w+)\1\n.*?\n\s*\2\b", re.S)
SINGLE = re.compile(r"'[^']*'")
DOUBLE = re.compile(r'"(?:[^"\\]|\\.)*"')


def strip_quoted(command: str) -> str:
    out = HEREDOC.sub(" ", command)
    out = SINGLE.sub(" ", out)
    out = DOUBLE.sub(" ", out)
    return out


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:  # noqa: BLE001
        return
    if payload.get("tool_name") != "Bash":
        return
    command = str((payload.get("tool_input") or {}).get("command") or "")
    if not command:
        return
    globs = load_globs(str(payload.get("cwd") or os.getcwd()))
    hit_full = [g for g in globs if glob_matches(g, command)]
    if not hit_full:
        return
    stripped = strip_quoted(command)
    hit_stripped = [g for g in globs if glob_matches(g, stripped)]
    if hit_stripped:
        return
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": (
                "the tier pattern(s) " + ", ".join(hit_full[:3]) + " matched only inside a "
                "quoted string or heredoc; a word mention is not a command (owner ruling 2026-09-10)"),
        }
    }))


main()
