"""The arbiter turns many gates' verdicts into one message, and no gate's failure stops the rest."""
import json
import os
os.environ["HOOK_TEST"] = "1"  # keeps real hooks fired here out of the live ledger
import stat
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "zrecover"))
from testlib import expect, finish  # noqa: E402

ARB = os.path.join(HERE, "stop-arbiter.py")
T = tempfile.mkdtemp(prefix="arbiter-")


def gate(name, body):
    path = os.path.join(T, name)
    with open(path, "w") as f:
        f.write("#!/bin/bash\n" + body + "\n")
    os.chmod(path, os.stat(path).st_mode | stat.S_IXUSR)
    return path


def run(gates, stdin='{"session_id":"s"}', env=None):
    listing = os.path.join(T, "gates.txt")
    with open(listing, "w") as f:
        f.write("# a comment\n\n" + "\n".join(gates) + "\n")
    start = time.time()
    r = subprocess.run([sys.executable, ARB], input=stdin, capture_output=True, text=True,
                       env=dict(os.environ, STOP_ARBITER_GATES=listing, **(env or {})))
    return r, time.time() - start


block_a = gate("a", """echo '{"decision":"block","reason":"first"}'""")
block_b = gate("b", """echo '{"decision":"block","reason":"second"}'""")
note = gate("n", """echo '{"systemMessage":"a note"}'""")
quiet = gate("q", "exit 0")
crash = gate("c", "echo not json at all; exit 1")
exit2 = gate("x", "echo denied by exit two >&2; exit 2")
echo_in = gate("i", """jq -c '{systemMessage: .session_id}'""")
slow = gate("s", "sleep 1; echo '{\"decision\":\"block\",\"reason\":\"slow\"}'")
hang = gate("h", "sleep 30")

r, _ = run([block_a, block_b])
out = json.loads(r.stdout)
expect("two blocks become one", out["decision"] == "block" and "first" in out["reason"] and "second" in out["reason"])
expect("in priority order", out["reason"].index("first") < out["reason"].index("second"))
r, _ = run([block_b, block_a])
expect("the list sets the order", json.loads(r.stdout)["reason"].index("second") < json.loads(r.stdout)["reason"].index("first"))
r, _ = run([slow, block_a])
expect("a slow gate keeps its place", json.loads(r.stdout)["reason"].index("slow") < json.loads(r.stdout)["reason"].index("first"))
r, _ = run([note, block_a])
out = json.loads(r.stdout)
expect("a note travels with a block", out["systemMessage"] == "a note" and out["decision"] == "block")
r, _ = run([note])
expect("a note alone does not block", "decision" not in json.loads(r.stdout))
r, _ = run([quiet])
expect("silence stays silent", r.stdout == "" and r.returncode == 0)
r, _ = run([crash, block_a])
expect("a crashed gate does not silence the rest", json.loads(r.stdout)["reason"] == "first")
r, _ = run([crash])
expect("a crash alone says nothing and exits clean", r.stdout == "" and r.returncode == 0)
r, _ = run([exit2])
expect("exit 2 counts as a block", json.loads(r.stdout)["reason"] == "denied by exit two")
r, _ = run([echo_in])
expect("each gate gets the input", json.loads(r.stdout)["systemMessage"] == "s")
r, took = run([slow, slow, slow])
expect("gates run together", took < 2.5)
r, took = run([hang, block_a], env={"STOP_ARBITER_TIMEOUT": "1"})
expect("a hung gate is cut off and the rest still count", json.loads(r.stdout)["reason"] == "first" and took < 5)
lingers = gate("l", """echo '{"decision":"block","reason":"said before leaving"}'; sleep 20 &""")
r, took = run([lingers])
expect("a background job left by a gate neither delays nor loses its verdict", took < 5 and json.loads(r.stdout)["reason"] == "said before leaving")
r, _ = run(["/no/such/gate", block_a])
expect("a missing gate is skipped", json.loads(r.stdout)["reason"] == "first")
r = subprocess.run([sys.executable, ARB], input="{}", capture_output=True, text=True,
                   env=dict(os.environ, STOP_ARBITER_GATES=os.path.join(T, "absent.txt")))
expect("a missing list warns the owner and never blocks", "cannot read" in json.loads(r.stdout)["systemMessage"] and r.returncode == 0)

# The real list points at real files, with no gate left registered twice.
with open(os.path.join(HERE, "stop-gates.txt")) as f:
    real = [line.strip() for line in f if line.strip() and not line.startswith("#")]
for line in real:
    path = next(os.path.expanduser(p) for p in line.split() if p.endswith((".sh", ".py")))
    expect("listed gate exists: %s" % os.path.basename(path), os.path.exists(path))
with open(os.path.expanduser("~/.claude/settings.json")) as f:
    stop_cmds = [h.get("command", "") for g in json.load(f)["hooks"]["Stop"] for h in g["hooks"]]
expect("the arbiter is registered and not async", any("stop-arbiter.py" in c for c in stop_cmds))
for line in real:
    name = next(os.path.basename(p) for p in line.split() if p.endswith((".sh", ".py")))
    expect("%s runs only through the arbiter" % name, not any(name in c for c in stop_cmds))
finish()
