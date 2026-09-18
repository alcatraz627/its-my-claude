"""The index guard must block commands and ignore mentions of them.

A guard nobody has watched fail is not a guard, and this one had never been
watched succeeding either: it blocked prose. Both directions are asserted here,
because fixing a false positive by weakening a guard is the failure next to the
one being fixed.
"""

import json
import subprocess
import sys

HOOK = "/Users/alcatraz627/.claude/scripts/hooks/prevent-unsolicited-index-manipulation.sh"
G = "g" + "it"

MUST_BLOCK = [
    (f"{G} reset HEAD frontend/", "the original incident"),
    (f"{G} stash", "a bare stash"),
    (f"cd /tmp && {G} restore --staged foo.py", "after a separator"),
    (f"{G} rm --cached secrets.env", "un-staging a tracked file"),
]

MUST_PASS = [
    (f'python3 -c "patterns = [\'{G} stash list\', \'{G} reset\']"',
     "the verbs inside a quoted Python list, the fire of 2026-09-04"),
    (f"claude-ipc send --to peer 'I ran {G} stash earlier, FYI'",
     "a report of the verb in a message"),
    (f"cat <<'EOF'\nRunbook: {G} reset HEAD is forbidden here\nEOF",
     "documentation inside a heredoc"),
    (f"rg -n '{G} stash' docs/", "searching for the verb"),
    (f"{G} status", "an ordinary read"),
    (f"{G} stash list", "listing is not stashing"),
]


def fires(command: str) -> bool:
    payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": command}})
    proc = subprocess.run(["bash", HOOK], input=payload, capture_output=True, text=True)
    return proc.returncode == 2


def main() -> None:
    ok = True
    print("must BLOCK:")
    for command, why in MUST_BLOCK:
        hit = fires(command)
        print(f"  {'blocked' if hit else 'LET THROUGH':11}  {why}")
        ok &= hit
    print("\nmust PASS:")
    for command, why in MUST_PASS:
        hit = fires(command)
        print(f"  {'FALSE FIRE' if hit else 'quiet':11}  {why}")
        ok &= not hit
    print("\n" + ("both directions hold" if ok else "GUARD IS WRONG"))
    sys.exit(0 if ok else 1)


main()
