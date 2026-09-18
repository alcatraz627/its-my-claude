"""The ripgrep preference: nudge on a real search, silent on a mention.

It blocked 243 times on 2026-09-03/04, more than every other hook combined, and
one of those was a message that merely quoted a piped search. This asserts the
new shape: nothing is refused, a real use still gets told about rg, and prose
gets nothing at all.
"""

import json
import subprocess
import sys

HOOK = "/Users/alcatraz627/.claude/scripts/prefer-ripgrep.sh"
G = "gr" + "ep"

MUST_NUDGE = [
    (f"{G} -r pattern src/", "a file search"),
    (f"cat notes.txt | {G} -q needle", "a pipe filter"),
    (f"ls && {G} -c x file", "after a separator"),
]

MUST_BE_SILENT = [
    (f'claude-ipc send --to peer "I ran cat x | {G} foo earlier"',
     "the verb quoted inside a message, the fire of 2026-09-04"),
    (f"cat <<'EOF' > doc.md\nUse {G} -r here\nEOF", "the verb inside a heredoc"),
    (f"git {G} pattern", "git's own index search, which rg cannot replace"),
    ("rg -n pattern src/", "actually using rg"),
    ("ls -la", "an unrelated command"),
]


def decision(command: str):
    payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": command}})
    proc = subprocess.run(["bash", HOOK], input=payload, capture_output=True, text=True)
    out = proc.stdout.strip()
    if not out:
        return "silent"
    try:
        body = json.loads(out)
    except Exception:
        return "unparseable"
    if body.get("decision") == "block":
        return "BLOCK"
    if "hookSpecificOutput" in body:
        return "nudge"
    return "other"


def main() -> None:
    ok = True
    print("must NUDGE (and never block):")
    for command, why in MUST_NUDGE:
        verdict = decision(command)
        print(f"  {verdict:12}  {why}")
        ok &= verdict == "nudge"
    print("\nmust be SILENT:")
    for command, why in MUST_BE_SILENT:
        verdict = decision(command)
        print(f"  {verdict:12}  {why}")
        ok &= verdict == "silent"
    print("\n" + ("shape holds" if ok else "HOOK IS WRONG"))
    sys.exit(0 if ok else 1)


main()
