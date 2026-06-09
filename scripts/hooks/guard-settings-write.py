#!/usr/bin/env python3
"""Stops a bad config save before it lands, instead of reporting it next launch.

This is the write-time preventer that the SessionStart validate-settings-hooks.sh
warning never was. It fires as a PreToolUse gate on Write / Edit / MultiEdit
aimed at settings.json, settings.local.json, or .mcp.json. It reconstructs the
content the tool is about to write, parses it as JSON, and blocks the call
(exit 2) if the result would not parse — or if a known structural invariant is
broken (a hooks entry missing its `hooks` array; .mcp.json missing mcpServers).

Runtime contract: reads the PreToolUse JSON payload on stdin
({tool_name, tool_input, ...}); exit 0 = allow, exit 2 = block with a message
on stderr that the agent sees. Anything it cannot evaluate confidently passes
(fail-open) — a guard that blocked legitimate edits would be worse than the gap
it closes. It only ever blocks on a *confirmed* invalid result.

Note: ~/.claude.json is rewritten by Claude Code itself, not via these tools, so
those writes are out of scope here (and already go through validated code paths).
"""
import sys
import os
import json

GUARDED = ("settings.json", "settings.local.json", ".mcp.json")


def block(msg):
    sys.stderr.write("SETTINGS WRITE GATE - blocked to prevent an invalid config save.\n\n")
    sys.stderr.write(msg + "\n")
    sys.exit(2)


def resulting_content(tool, tinput):
    """The content the file would hold after this tool runs, or None if unknown."""
    path = tinput.get("file_path", "") or ""
    if tool == "Write":
        return tinput.get("content", "")
    if tool in ("Edit", "MultiEdit"):
        try:
            with open(path) as f:
                cur = f.read()
        except Exception:
            return None  # can't reconstruct -> fail open
        if tool == "Edit":
            edits = [{
                "old_string": tinput.get("old_string", ""),
                "new_string": tinput.get("new_string", ""),
                "replace_all": tinput.get("replace_all", False),
            }]
        else:
            edits = tinput.get("edits", []) or []
        for e in edits:
            old = e.get("old_string", "")
            new = e.get("new_string", "")
            if e.get("replace_all"):
                cur = cur.replace(old, new)
            else:
                cur = cur.replace(old, new, 1)
        return cur
    return None


def validate(content, base):
    try:
        data = json.loads(content)
    except Exception as ex:
        block("Result would not be valid JSON (%s).\n  File: %s\n"
              "Fix the JSON before saving." % (ex, base))
        return

    if base in ("settings.json", "settings.local.json") and isinstance(data, dict):
        bad = []
        hooks = data.get("hooks", {})
        if isinstance(hooks, dict):
            for ev, arr in hooks.items():
                if not isinstance(arr, list):
                    bad.append("hooks.%s is not an array" % ev)
                    continue
                for i, m in enumerate(arr):
                    if not isinstance(m, dict) or not isinstance(m.get("hooks"), list):
                        bad.append("hooks.%s[%d] missing a 'hooks' array" % (ev, i))
        if bad:
            block("Hook schema invariant violated:\n  " + "\n  ".join(bad) +
                  '\nEach entry must be: { "hooks": [ { "type": "command", '
                  '"command": "..." } ] }')

    if base == ".mcp.json" and isinstance(data, dict):
        if not isinstance(data.get("mcpServers"), dict):
            block('.mcp.json must contain an object "mcpServers" key.')


def main():
    try:
        payload = json.loads(sys.stdin.read())
    except Exception:
        sys.exit(0)
    tool = payload.get("tool_name", "")
    if tool not in ("Write", "Edit", "MultiEdit"):
        sys.exit(0)
    tinput = payload.get("tool_input", {}) or {}
    base = os.path.basename(tinput.get("file_path", "") or "")
    if base not in GUARDED:
        sys.exit(0)
    content = resulting_content(tool, tinput)
    if content is None:
        sys.exit(0)
    validate(content, base)
    sys.exit(0)


if __name__ == "__main__":
    main()
