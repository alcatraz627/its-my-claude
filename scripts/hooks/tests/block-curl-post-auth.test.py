"""The curl audit block: exempt loopback, still stop a call that leaves the box.

The must-BLOCK half is the point. The guard exists because an authenticated
mutating call to a real service leaves no audit trail, and an exemption written
by flag rather than by URL would have let a deployed host through in the same
command line.
"""

import json
import subprocess
import sys

HOOK = "/Users/alcatraz627/.claude/scripts/hooks/block-curl-post-auth.sh"
AUTH = '-H "Authorization: Bearer abc123"'

MUST_BLOCK = [
    (f'curl -X POST {AUTH} https://api.example.com/v1/things',
     "a mutating call to a real service"),
    (f'curl -X DELETE {AUTH} https://runner.dev.versable.ai/jobs/1',
     "a deployed host of our own"),
    (f'curl -X POST {AUTH} http://127.0.0.1:5110/jobs https://api.example.com/x',
     "loopback AND a remote host in one line"),
    (f'curl --data @body.json {AUTH} https://api.example.com/v1',
     "a body flag rather than -X"),
]

MUST_PASS = [
    (f'curl -X DELETE {AUTH} http://127.0.0.1:5110/jobs',
     "probing a local service, forge-integration 2026-09-04"),
    (f'curl -X POST {AUTH} http://localhost:5110/jobs -d "{{}}"',
     "the same by name"),
    (f'curl -X POST -H "Authorization: Bearer $TOKEN" https://api.example.com/v1',
     "an unexpanded variable, the pre-existing exemption"),
    ("curl -s http://127.0.0.1:5110/health", "a plain local read"),
    ("curl -s https://api.example.com/health", "a plain remote read"),
]


def blocked(command: str) -> bool:
    payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": command}})
    proc = subprocess.run(["bash", HOOK], input=payload, capture_output=True, text=True)
    return proc.returncode == 2 or "[BLOCK]" in proc.stderr


def main() -> None:
    ok = True
    print("must BLOCK:")
    for command, why in MUST_BLOCK:
        hit = blocked(command)
        print(f"  {'blocked' if hit else 'LET THROUGH':12}  {why}")
        ok &= hit
    print("\nmust PASS:")
    for command, why in MUST_PASS:
        hit = blocked(command)
        print(f"  {'FALSE FIRE' if hit else 'quiet':12}  {why}")
        ok &= not hit
    print("\n" + ("both directions hold" if ok else "GUARD IS WRONG"))
    sys.exit(0 if ok else 1)


main()
