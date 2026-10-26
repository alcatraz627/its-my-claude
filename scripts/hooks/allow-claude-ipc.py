#!/usr/bin/env python3
"""Blanket approval for claude-ipc commands, owner ruling 2026-09-10.

The ask tier matches substrings anywhere in a Bash command, so an ipc message
whose BODY mentions "gcloud run deploy" or "git push" was prompting the owner as
if the agent were about to deploy or push. This hook answers first: a command
that runs claude-ipc and nothing else is allowed outright. Anything more (a
chain, a pipe, a $( ) or backtick in the message, an unquoted heredoc that
substitutes) is left to the other hooks and tiers, as is anything the shared
parser cannot read.
"""
import importlib.util
import json
import os
import sys

try:
    payload = json.load(sys.stdin)
except Exception:  # noqa: BLE001  a malformed payload is somebody else's call
    sys.exit(0)

if payload.get("tool_name") != "Bash":
    sys.exit(0)
command = str((payload.get("tool_input") or {}).get("command") or "")
try:
    spec = importlib.util.spec_from_file_location("shellparse", os.environ.get(
        "SHELLPARSE_UNDER_TEST", os.path.join(os.path.dirname(os.path.abspath(__file__)), "shellparse.py")))
    sp = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(sp)
    p = sp.parse(command)
except Exception:  # noqa: BLE001  unreadable means no blanket allow
    sys.exit(0)
ran = [c for c in p.commands if c.name]
# A newline is an operator too, but a heredoc needs one; a second command would show in `ran`.
if not p.ok or any(o.op != "\n" for o in p.operators) or len(ran) != 1 or ran[0].name != "claude-ipc" or ran[0].depth != 0:
    sys.exit(0)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "permissionDecisionReason": "claude-ipc is blanket-approved (owner ruling 2026-09-10); "
                                    "a message body is not a command",
    }
}))
