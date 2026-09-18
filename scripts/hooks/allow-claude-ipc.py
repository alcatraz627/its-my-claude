#!/usr/bin/env python3
"""Blanket approval for claude-ipc commands, owner ruling 2026-09-10.

The ask tier matches substrings anywhere in a Bash command, so an ipc message
whose BODY mentions "gcloud run deploy" or "git push" was prompting the owner as
if the agent were about to deploy or push. This hook answers first: a command
whose first word is claude-ipc, with no shell operator outside a quoted string,
is allowed outright. A chained command is left to the other hooks and tiers.
"""
import json
import shlex
import sys

OPERATORS = {"&&", "||", ";", "|", "&"}

try:
    payload = json.load(sys.stdin)
except Exception:  # noqa: BLE001  a malformed payload is somebody else's call
    sys.exit(0)

if payload.get("tool_name") != "Bash":
    sys.exit(0)
command = str((payload.get("tool_input") or {}).get("command") or "")
try:
    tokens = shlex.split(command, posix=True)
except ValueError:
    sys.exit(0)
if not tokens or tokens[0] != "claude-ipc":
    sys.exit(0)
if any(t in OPERATORS for t in tokens):
    sys.exit(0)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "permissionDecisionReason": "claude-ipc is blanket-approved (owner ruling 2026-09-10); "
                                    "a message body is not a command",
    }
}))
