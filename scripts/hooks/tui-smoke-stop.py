#!/usr/bin/env python3
"""Refuses a reply that calls a terminal screen built or working when it was never opened
the way its owner opens it.

The failure it stops: an agent builds an fzf screen, runs its tests from the source folder,
and reports it done. The owner starts the tool by its installed name and gets an empty frame.
That happened on the first real use of `zterminal look` (2026-11-10, atone
test-harness-bypasses-production-entry-path), and the owner's words were that it happens every
time an agent builds one. The handbook's check (conventions/tui-handbook.md §5) was advisory.

Stop hook. Blocks once per distinct set of files when all three hold in the current turn:
a file that runs an fzf screen, or builds one with tuikit, was edited; no command naming
`tui/smoke.sh` ran after the last such edit; and the final reply claims it is built, done,
working, fixed or ready. Saying the smoke check was not run is the honest way through.
After its one block it speaks as a note to the owner only.

Mute: touch ~/.claude/.no-tui-smoke-gate
"""
import hashlib
import json
import os
import re
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
try:
    import hookpop  # noqa: E402
    if not hookpop.should_run():
        sys.exit(0)
except ImportError:
    pass

HOME = os.path.expanduser("~")
STATE = os.environ.get("TUI_SMOKE_GATE_STATE", os.path.join(tempfile.gettempdir(), "claude-tui-smoke-gate"))
if os.path.exists(os.path.join(HOME, ".claude", ".no-tui-smoke-gate")):
    sys.exit(0)

sys.path.insert(0, os.path.join(HOME, ".claude", "scripts", "tui"))
try:
    from lint import SCREEN  # the kit's own test for "this file runs a screen"
except ImportError:
    sys.exit(0)

CLAIM = re.compile(r"\b(done|built|works|working|fixed|ready|shipped|finished|complete|is in|are in|now opens|passes)\b", re.I)
# An UNCONFIRMED line excuses the claim only when it is about opening the screen: a reply
# that owned up to load order and reload speed still left the owner a blank pane (bbc94e51).
OWNED_UP = re.compile(r"smoke (check|test|run)?\s*(was |is )?(not|never) (run|done)|not smoke|without the smoke"
                      r"|UNCONFIRMED[^\n]{0,120}\b(smoke|installed|entry (path|point)|by (its|the) (installed )?name|from a prompt)", re.I)
EDITS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}


def is_screen(path):
    """Whether a file runs an fzf screen or draws one with the shared kit."""
    try:
        if os.path.getsize(path) > 400_000 or path.endswith((".md", ".json", ".txt")):
            return False
        with open(path, errors="replace") as f:
            text = f.read()
    except OSError:
        return False
    if os.path.join(".claude", "scripts", "tui") in path or os.path.join("scripts", "hooks") in path:
        return False
    return bool(SCREEN.search(text)) or bool(re.search(r"^\s*(from|import) tuikit\b", text, re.M))


def this_turn(transcript):
    """The tool calls and the last reply since the owner last spoke, in order."""
    events, reply = [], ""
    try:
        with open(transcript, errors="replace") as f:
            lines = f.readlines()
    except OSError:
        return events, reply
    for raw in lines:
        try:
            row = json.loads(raw)
        except ValueError:
            continue
        if row.get("isSidechain"):
            continue
        content = (row.get("message") or {}).get("content")
        blocks = content if isinstance(content, list) else []
        if row.get("type") == "user":
            spoke = isinstance(content, str) or (blocks and not any(b.get("type") == "tool_result" for b in blocks if isinstance(b, dict)))
            if spoke:
                events, reply = [], ""
        elif row.get("type") == "assistant":
            for b in blocks:
                if not isinstance(b, dict):
                    continue
                if b.get("type") == "tool_use":
                    events.append((b.get("name") or "", b.get("input") or {}))
                elif b.get("type") == "text" and b.get("text", "").strip():
                    reply = b["text"]
    return events, reply


def main():
    try:
        inp = json.load(sys.stdin)
    except ValueError:
        return 0
    if not isinstance(inp, dict) or inp.get("stop_hook_active"):
        return 0
    events, reply = this_turn(inp.get("transcript_path") or "")
    reply = inp.get("last_assistant_message") or reply
    edited, last_edit = [], -1
    for n, (name, args) in enumerate(events):
        path = args.get("file_path") or args.get("notebook_path") or ""
        if name in EDITS and path and is_screen(path):
            edited.append(path)
            last_edit = n
    if not edited:
        return 0
    smoked = any(name == "Bash" and "tui/smoke.sh" in (args.get("command") or "") for name, args in events[last_edit + 1:])
    if smoked or not CLAIM.search(reply) or OWNED_UP.search(reply):
        return 0
    names = sorted({os.path.basename(p) for p in edited})
    words = ("This turn changed a terminal screen (%s) and the reply calls it done, but the screen was not opened "
             "the way its owner opens it. Run: bash ~/.claude/scripts/tui/smoke.sh -- <the tool, by the name typed at a "
             "prompt>, and once more with --keys for each screen a key opens. Read what it prints. If you cannot run "
             "it, say in the reply that the smoke check was not run. (conventions/tui-handbook.md §5)" % ", ".join(names))
    mark = os.path.join(STATE, "%s-%s" % ((inp.get("session_id") or "none")[:8], hashlib.sha1("|".join(names).encode()).hexdigest()[:10]))
    if os.path.exists(mark):
        print(json.dumps({"systemMessage": "tui-smoke: %s changed again with no smoke run after it." % ", ".join(names)}))
        return 0
    try:
        os.makedirs(STATE, exist_ok=True)
        open(mark, "w").close()
    except OSError:
        pass
    print(json.dumps({"decision": "block", "reason": words}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
