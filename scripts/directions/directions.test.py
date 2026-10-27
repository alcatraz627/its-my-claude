#!/usr/bin/env python3
"""Drives directions.py against a throwaway repo, goal record and issue list.

Run: python3 ~/.claude/scripts/directions/directions.test.py
The real-file replay (every committed slack-automation version) is recorded in
~/.claude/assets/reports/20261022-directions-lint/DESIGN.md.
"""
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "directions.py")
T = tempfile.mkdtemp(prefix="directions-test-")
REPO = os.path.join(T, "repo")
GOALS = os.path.join(T, "goals")
STATE = os.path.join(T, "state")
for d in (REPO, GOALS, STATE, os.path.join(REPO, "docs", "plan"), os.path.join(REPO, "src")):
    os.makedirs(d, exist_ok=True)
fails = []


def check(name, cond, detail=""):
    print(("ok   " if cond else "FAIL ") + name + ("" if cond else "  " + detail[:300]))
    if not cond:
        fails.append(name)


def git(*a):
    return subprocess.run(["git", "-C", REPO] + list(a), capture_output=True, text=True).stdout.strip()


git("init", "-q")
git("config", "user.email", "t@t")
git("config", "user.name", "t")
open(os.path.join(REPO, "src", "real.py"), "w").write("x = 1\n")
git("add", "-A")
git("commit", "-q", "-m", "seed")
SHA = git("rev-parse", "--short=7", "HEAD")
GID = "abcdef123456"
json.dump({"id": GID, "status": "live", "projects": ["repo"], "outcome": "Things work", "tasks": [
    {"id": "1", "state": "done"}, {"id": "2", "state": "ready"}, {"id": "3", "state": "ready", "blocked_by": ["2"]},
    {"id": "4", "state": "review"}]}, open(os.path.join(GOALS, GID + ".json"), "w"))
json.dump({"id": "999999999999", "status": "live", "projects": ["repo"], "outcome": "Another goal", "tasks": []},
          open(os.path.join(GOALS, "999999999999.json"), "w"))
ENV = dict(os.environ, DIRECTIONS_GOALS_DIR=GOALS, DIRECTIONS_STATE=STATE,
           DIRECTIONS_GH_STATES=json.dumps({"10": "CLOSED", "11": "OPEN"}))
F = os.path.join(REPO, "docs", "plan", "DIRECTIONS.md")

GOOD = """# Directions

## Where things stand today

- One fact.

## Waiting on you

| id | ask | what I need from you | if you say nothing |
| --- | --- | --- | --- |
| `#4` | Look at the new reply | Read the reply on PR 12 and say keep or revert | stays shipped |

## 🧭 Things work

### 🎯 Rows are true

| id | state | task |
| --- | --- | --- |
| `#1` | ✅ | Merged the first change |
| `#2` | 🟢 | Ship the second change |
| `#4` | 🔴 | Look at the reply live |
| `GH#10` | ✅ | The closed issue is fixed |
| `GH#11` | 🟢 | The open issue |
| `A1` | ✅ | A doc-only row with proof |
| `A2` | ✅ | 💭 A row the agent inferred |

## Sources

- Goal record `%s`.
- `A1`: %s, [`src/real.py`](../../src/real.py).
""" % (GID, SHA)


def write(text):
    open(F, "w").write(text)


def lint(text=None):
    if text is not None:
        write(text)
    r = subprocess.run([sys.executable, SCRIPT, "lint", F, "--json"], capture_output=True, text=True, env=ENV)
    return json.loads(r.stdout), r.returncode


def codes(found, level=None):
    return sorted(f["code"] for f in found if level is None or f["level"] == level)


found, rc = lint(GOOD)
check("a true file has no errors", codes(found, "error") == [] and rc == 0, str(found))
check("an uncited live goal for the repo is a warning", codes(found, "warn") == ["goal-uncited"], str(found))


def variant(old, new, want, name):
    found, rc = lint(GOOD.replace(old, new))
    check(name, want in codes(found, "error") and rc == 1, str(codes(found)))


variant("| `#2` | 🟢 |", "| `#2` | ✅ |", "done-but-open", "✅ on a goal row still open is caught")
variant("| `#1` | ✅ |", "| `#1` | 🟢 |", "open-but-done", "open on a goal row already done is caught")
variant("| `GH#11` | 🟢 |", "| `GH#11` | ✅ |", "done-but-open", "✅ on an open issue is caught")
variant("| `GH#10` | ✅ |", "| `GH#10` | 🟢 |", "open-but-done", "open on a closed issue is caught")
variant("- `A1`: %s, [`src/real.py`](../../src/real.py)." % SHA, "", "done-unproven", "✅ with nothing in Sources is caught")
variant("- `A1`: %s, [`src/real.py`](../../src/real.py)." % SHA, "- `A1`: deadbee, `src/gone.py`.", "proof-broken",
        "✅ whose proof does not exist is caught")
variant("| A doc-only row with proof |", "| A row with %s in it |" % SHA, "proof-in-row", "a commit in a row is caught")
variant("| Ship the second change |", "| %s |" % ("word " * 25), "row-long", "a paragraph in a row is caught")
variant("| stays shipped |", "| \u2014 |", "ask-no-default", "an ask with no default is caught")
found, rc = lint(GOOD.replace("| Read the reply on PR 12 and say keep or revert |", "| \u2014 |"))
check("an ask with an empty need is an error", "ask-no-need" in codes(found, "error") and rc == 1, str(codes(found)))
found, rc = lint(GOOD.replace("| id | ask | what I need from you | if you say nothing |\n| --- | --- | --- | --- |\n"
                              "| `#4` | Look at the new reply | Read the reply on PR 12 and say keep or revert | stays shipped |",
                              "| id | ask | if you say nothing |\n| --- | --- | --- |\n| `#4` | Look at the new reply | stays shipped |"))
check("a Waiting on you table without the need column is an error", "ask-no-need" in codes(found, "error") and rc == 1, str(codes(found)))
found, rc = lint(GOOD.replace("| `#4` | Look at the new reply |", "| `#4`, `A1`, `A2`, `#2` | Look at the new reply |"))
check("an entry bundling more than three ids is a warning", "ask-bundled" in codes(found, "warn"), str(codes(found)))
found, rc = lint(GOOD.replace("| `#2` | 🟢 | Ship the second change |", "| `#2` | 🔴 | Ship the second change |"))
check("a 🔴 row with no Waiting on you entry is an error", "needs-you-unlisted" in codes(found, "error"), str(codes(found)))
LK = "[`src/real.py`](../../src/real.py)"
found, rc = lint(GOOD.replace(LK, "`src/real.py`"))
check("a repo path left as plain code is a warning", "unlinked-ref" in codes(found, "warn") and rc == 0, str(codes(found)))
write(GOOD.replace(LK, "`src/real.py`") + "\nSee `GH#7` and pr-claude-testbed#35.\n")
out = subprocess.run([sys.executable, SCRIPT, "link", F], capture_output=True, text=True, env=ENV).stdout
text = open(F).read()
check("link turns a repo path into a relative link", LK in text, out)
check("link turns a cross-repo PR into a GitHub link",
      "[`pr-claude-testbed#35`](https://github.com/versable-git/pr-claude-testbed/issues/35)" in text, out)
check("link leaves GH#n alone when the repo has no GitHub origin", "`GH#7`" in text and "issues/7" not in text, out)
before = text
subprocess.run([sys.executable, SCRIPT, "link", F], capture_output=True, text=True, env=ENV)
check("link run twice changes nothing more", open(F).read() == before)
found, rc = lint(GOOD.replace("| Ship the second change |", "| Ship [`GH#9`](https://github.com/o/r/issues/9) and more words |"))
check("a link's URL does not count toward a row's length", "row-long" not in codes(found), str(codes(found)))
variant("| `#4` | Look at the new reply |", "| `#1` | Look at the new reply |", "ask-stale",
        "an ask already done at its source is caught")
variant("| `#4` | Look at the new reply |", "| `#3` | Look at the new reply |", "ask-blocked",
        "an ask waiting on open work is caught")
variant("| Look at the new reply |", "| %s |" % ("word " * 25), "ask-long", "a long ask is caught")
variant("| Look at the new reply |", "| Rule on R1 to R3 |", "ask-bare", "an ask that names only ids is caught")
found, _ = lint(GOOD)
check("an ask written out in words is not bare", "ask-bare" not in codes(found), str(codes(found)))

found, _ = lint(GOOD.replace("| `A2` | ✅ | 💭", "| `A2` | ✅ |"))
check("✅ with no proof passes only while marked 💭", "done-unproven" in codes(found, "error"), str(codes(found)))
found, _ = lint(GOOD.replace("| `#2` | 🟢 | Ship the second change |", "| `#2` | 🟢 | Move it to `ops/cloudrun/` |"))
check("a folder named as the task is not proof in a row", "proof-in-row" not in codes(found), str(codes(found)))
found, _ = lint(GOOD.replace("| `#4` | 🔴 | Look at the reply live |", "| `#4` | 🟢 | Look at the reply live |"))
check("an ask whose row is not 🔴 is a warning", "ask-row-state" in codes(found, "warn"), str(codes(found)))
many = "\n".join("| `B%d` | 🟢 | Row %d |" % (i, i) for i in range(9))
found, _ = lint(GOOD.replace("| `A2` | ✅ | 💭 A row the agent inferred |", many))
check("more than eight rows under a goal is a warning", "too-many-rows" in codes(found, "warn"), str(codes(found)))
found, _ = lint(GOOD.replace("| `#4` | Look at the new reply | Read the reply on PR 12 and say keep or revert | stays shipped |", "| `#2 to #3` | Look | Say which | \u2014 |"))
ids = [f["ids"] for f in found if f["code"] == "ask-no-default"]
check("a range inside one pair of backticks reads as each id", ids == [["#2", "#3"]], str(ids))

# sync: forward only
write(GOOD.replace("| `#1` | ✅ |", "| `#1` | 🟢 |").replace("| `#2` | 🟢 |", "| `#2` | ✅ |"))
out = subprocess.run([sys.executable, SCRIPT, "sync", F], capture_output=True, text=True, env=ENV).stdout
text = open(F).read()
check("sync marks a row done when its source is done", "| `#1` | ✅ |" in text and "#1" in out, out)
check("sync never flips a ✅ back", "| `#2` | ✅ |" in text)
check("the rest of the file is untouched", text.count("\n") == GOOD.count("\n"))

# the gate: only errors this turn added hold the turn
write(GOOD.replace("| `#2` | 🟢 |", "| `#2` | ✅ |"))   # a pre-existing error, committed
git("add", "-A")
git("commit", "-q", "-m", "doc")


def hook(cmd, data):
    r = subprocess.run([sys.executable, SCRIPT, cmd], input=json.dumps(data), capture_output=True, text=True, env=ENV)
    return r.stdout.strip()


S = {"session_id": "sess0001", "cwd": REPO}
hook("hook-post", dict(S, tool_name="Edit", tool_input={"file_path": F}))
check("an edit that adds nothing new lets the turn end", hook("hook-stop", S) == "")
hook("hook-post", dict(S, tool_name="Edit", tool_input={"file_path": F}))
write(open(F).read().replace("| stays shipped |", "| \u2014 |"))
out = hook("hook-stop", S)
check("an error this turn added holds the turn", '"block"' in out and "owner says nothing" in out, out)
check("and the old error is not blamed on it", "goal record says" not in out, out)
check("it holds twice at most", '"block"' in hook("hook-stop", S))
out = hook("hook-stop", S)
check("then the owner is told instead", "systemMessage" in out and '"block"' not in out, out)
write(GOOD.replace("| `#2` | 🟢 |", "| `#2` | ✅ |"))

# auto-sync after a goal-record close
write(GOOD.replace("| `#1` | ✅ |", "| `#1` | 🟢 |"))
out = hook("hook-post", dict(S, tool_name="Bash", tool_input={"command": "gs close %s 1 --by 'true: x'" % GID}))
check("closing a row in the goal record syncs the doc", "| `#1` | ✅ |" in open(F).read() and "#1" in out, out)
write(GOOD.replace("| `#1` | ✅ |", "| `#1` | 🟢 |"))
hook("hook-post", dict(S, tool_name="Bash", tool_input={"command": "gs close 000000000000 1 --by x"}))
check("a close on a goal the doc does not cite leaves it alone", "| `#1` | 🟢 |" in open(F).read())

r = subprocess.run([sys.executable, SCRIPT, "hook-stop"], input="not json", capture_output=True, text=True, env=ENV)
check("bad hook input never blocks", r.returncode == 0 and "block" not in r.stdout)

print("\n%s" % ("all passed" if not fails else "%d failed" % len(fails)))
sys.exit(1 if fails else 0)
