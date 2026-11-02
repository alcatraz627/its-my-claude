#!/usr/bin/env python3
"""List Stop hooks that tail the transcript for the reply without using the Stop input's copy.

The transcript on disk lags one message when a Stop hook runs, so a hook that reads the
newest assistant row judges the previous reply. Claude Code hands every Stop hook the
real one as last_assistant_message, and hook_last_assistant_text in hook-common.sh reads
it with the transcript as a fallback. A registered Stop hook that mentions transcript_path
must use one of those, or be named with a reason in stop-transcript-exempt.txt (a hook
that reads the transcript for something other than the reply).

    stop_transcript_readers.py [settings.json]
"""
import json
import os
import sys

HOME = os.path.expanduser("~/.claude/")
USES_INPUT_REPLY = ("hook_last_assistant_text", "last_assistant_message")


def stop_scripts(settings):
    """Every script path the settings file registers on the Stop event."""
    found = set()
    with open(settings) as f:
        groups = json.load(f).get("hooks", {}).get("Stop", [])
    for group in groups:
        for hook in group.get("hooks", []):
            for token in hook.get("command", "").split():
                if "/" in token and token.endswith((".sh", ".py")):
                    found.add(os.path.expanduser(token))
                    break
    # Gates that run through the arbiter are registered in its list.
    if any("stop-arbiter.py" in path for path in found):
        with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "stop-gates.txt")) as f:
            for line in f:
                if not line.startswith("#"):
                    found.update(os.path.expanduser(t) for t in line.split() if t.endswith((".sh", ".py")))
    return found


def exempt_names(here):
    names = set()
    with open(os.path.join(here, "stop-transcript-exempt.txt")) as f:
        for line in f:
            if line.strip() and not line.startswith("#"):
                names.add(line.split()[0])
    return names


def main():
    settings = sys.argv[1] if len(sys.argv) > 1 else HOME + "settings.json"
    exempt = exempt_names(os.path.dirname(os.path.abspath(__file__)))
    for path in sorted(stop_scripts(settings)):
        if not os.path.exists(path):
            continue
        with open(path, errors="replace") as f:
            text = f.read()
        name = path.replace(HOME, "")
        if "transcript_path" in text and not any(u in text for u in USES_INPUT_REPLY) and name not in exempt:
            print(name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
