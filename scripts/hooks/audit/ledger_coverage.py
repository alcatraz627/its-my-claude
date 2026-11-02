#!/usr/bin/env python3
"""List hooks that can steer a session but neither write to the ledger nor say why they do not.

A hook with no ledger row is invisible to tuning, however often it blocks. Exempt hooks are
named, with a reason, in no-ledger.txt beside this file.

    ledger_coverage.py [settings.json]
"""
import json
import os
import re
import sys

HOME = os.path.expanduser("~/.claude/")
STEER = re.compile(r"""decision"?\s*[:=]\s*\\?["']?block|additionalContext|\bexit 2\b""")
LOGS = re.compile(r"warn-log|warn_log")


def registered(settings):
    """Every script path the settings file runs as a hook."""
    found = set()
    with open(settings) as f:
        for groups in json.load(f).get("hooks", {}).values():
            for group in groups:
                for hook in group.get("hooks", []):
                    for token in hook.get("command", "").split():
                        if "/" in token and token.endswith((".sh", ".py")):
                            found.add(os.path.expanduser(token))
                            break
    # Gates that run through the arbiter are registered there.
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "stop-gates.txt")) as f:
        for line in f:
            if not line.startswith("#"):
                found.update(os.path.expanduser(t) for t in line.split() if t.endswith((".sh", ".py")))
    return found


def main():
    settings = sys.argv[1] if len(sys.argv) > 1 else HOME + "settings.json"
    exempt = set()
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "no-ledger.txt")) as f:
        for line in f:
            if line.strip() and not line.startswith("#"):
                exempt.add(line.split()[0])
    for path in sorted(registered(settings)):
        if os.path.exists(path):
            with open(path, errors="replace") as f:
                text = f.read()
            name = path.replace(HOME, "")
            if STEER.search(text) and not LOGS.search(text) and name not in exempt:
                print(name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
