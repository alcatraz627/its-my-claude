"""The secret guard must still block every read, and stop blocking mentions.

The must-BLOCK list is the point: a false-positive fix that lets a real leak
through is worse than the false positive. Every entry here emits file CONTENTS.
"""

import json
import subprocess
import sys

HOOK = "/Users/alcatraz627/.claude/scripts/hooks/guard-secret-file-read.sh"
ENV = ".e" + "nv"

MUST_BLOCK = [
    (f"cat backend/{ENV}", "the plain read"),
    (f'cat "$HOME/{ENV}"', "a quoted path, why quotes are not blanked"),
    (f"ls -la {ENV} && cat {ENV}", "a benign verb in front of a read"),
    (f'echo "$(cat {ENV})"', "a read smuggled into an echo"),
    (f'claude-ipc send --to peer "$(cat backend/{ENV})"', "a read smuggled into a message"),
    (f"claude-ipc send --to peer \"$(< backend/{ENV})\"", "the same via a redirect"),
    (f"rg -o '.*' {ENV}", "the emitter wearing a safe flag"),
    ("cat deploy/key.pem", "a private key"),
    (f"cat <<'EOF' > x\nprose\nEOF\ncat backend/{ENV}",
     "a real read on the line AFTER a heredoc"),
]

MUST_PASS = [
    (f'claude-ipc send --to peer "the DB url in backend/{ENV} points at a shared host"',
     "naming the file in a message, the fire of 2026-09-04"),
    (f'echo "check backend/{ENV} for the var names"', "naming it in an echo"),
    (f"rg -c '^[A-Z_]+=' backend/{ENV}", "counting the vars"),
    (f"wc -l backend/{ENV}", "its size"),
    (f"shasum -a 256 backend/{ENV}", "its fingerprint"),
    (f"rg -o '^[A-Z_]+' backend/{ENV}", "the names only"),
    (f"git check-ignore -v backend/{ENV}", "confirming it is ignored"),
    (f"python3 - <<'EOF'\ntext = 'see backend/{ENV} for the names'\nEOF",
     "a heredoc that names the file, forge-brains 2026-09-04"),
    (f"cat > doc.md <<'EOF'\nThe URL lives in backend/{ENV}\nEOF",
     "writing a doc that names it"),
]


def blocked(command: str) -> bool:
    payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": command}})
    proc = subprocess.run(["bash", HOOK], input=payload, capture_output=True, text=True)
    return '"permissionDecision":"deny"' in proc.stdout.replace(" ", "")


def main() -> None:
    ok = True
    print("must BLOCK (a leak here is worse than any false positive):")
    for command, why in MUST_BLOCK:
        hit = blocked(command)
        print(f"  {'blocked' if hit else 'LEAKED':11}  {why}")
        ok &= hit
    print("\nmust PASS:")
    for command, why in MUST_PASS:
        hit = blocked(command)
        print(f"  {'FALSE FIRE' if hit else 'quiet':11}  {why}")
        ok &= not hit
    print("\n" + ("both directions hold" if ok else "GUARD IS WRONG"))
    sys.exit(0 if ok else 1)


main()
