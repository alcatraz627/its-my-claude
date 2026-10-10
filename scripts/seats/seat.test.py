"""Exercises the seat tool end to end in a temp folder.

Run: python3 ~/.claude/scripts/seats/seat.test.py
"""
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "zrecover"))
from testlib import expect, finish  # noqa: E402

SEAT = os.path.join(HERE, "seat")
T = tempfile.mkdtemp(prefix="seat-test-")
ENV = dict(os.environ, SEATS_DIR=os.path.join(T, "seats"), SEATS_DOMAIN=os.path.join(T, "domain"))
TARGET = os.path.join(T, "target.py")
with open(TARGET, "w") as f:
    f.write("".join("line %d\n" % i for i in range(1, 40)))
OUT = os.path.join(T, "out", "report.md")

GOOD = """## Goal
Find every way the relay loop can stop while its child is still alive. A fix will not be trusted until every path to that state is known.

## Background
- The loop ended mid-session once on 2026-10-10.
- Its finally block restores the terminal and then waits.
- The cause was a pyte IndexError on an overwritten wide glyph.

## Inputs
%s:10-20 the relay loop and its exit paths
%s the whole file for context on imports

## Constraints
none: this is a read-only investigation with no owner rules attached

## Scope
Do: read the code and run probes against a dummy child.
Do not: edit the file under review.

## Method
1. List each exit path in the loop.
2. Write and run a probe for each path.

## Deliverable
A table of exit paths written to %s

## Done when
- Every exit path is in the table.
- Each row has a probe that was actually run, with its output.

## Return
The row count and any path you could not trigger, and why.
""" % (TARGET, TARGET, OUT)


def run_seat(*args):
    return subprocess.run([sys.executable, SEAT] + list(args), capture_output=True, text=True, env=ENV, cwd=T)


def brief_file(name, text):
    p = os.path.join(T, name)
    with open(p, "w") as f:
        f.write(text)
    return p


thin = brief_file("thin.md", "## Goal\nReview the changes.\n\n## Deliverable\nreport back\n")
r = run_seat("compose", thin, "--role", "reviewer", "--model", "sonnet", "--no-cold-read")
expect("a thin brief is refused", r.returncode == 1)
expect("the refusal names each missing section", "Background: missing" in r.stderr and "Done when: missing" in r.stderr)
expect("a refusal is logged for the weekly review", os.path.exists(os.path.join(T, "seats", "refusals.jsonl")))

good = brief_file("good.md", GOOD)
r = run_seat("compose", good, "--role", "reviewer", "--model", "sonnet", "--persona", "skeptical-reviewer", "--no-cold-read")
expect("a complete brief composes", r.returncode == 0)
p = r.stdout
expect("the prompt opens with the seat header", p.startswith("[seat s-") and "role=reviewer" in p and "output=" + OUT in p)
expect("the persona file is included", "skeptical" in p.lower())
ex = p.split("## Excerpts")[1].split("# Scope")[0] if "## Excerpts" in p else ""
expect("input excerpts are attached at the named lines", "line 10\n" in ex and "line 21\n" not in ex)
expect("the five dispatch clauses are present", "Do NOT spawn sub-agents" in p and "One command per Bash call" in p)
expect("the reviewer playbook is present", "findings ledger" in p)
sid = p.split()[1].rstrip("]")
expect("a record is written", os.path.exists(os.path.join(T, "seats", sid + ".json")))

r = run_seat("compose", good, "--role", "judge", "--model", "sonnet", "--no-cold-read")
expect("a judge does not see the background", "What we already know" not in r.stdout and "pyte IndexError" not in r.stdout)
r = run_seat("compose", good, "--role", "worker", "--model", "sonnet", "--no-cold-read")
expect("a worker without --scope is refused", r.returncode == 2)
r = run_seat("compose", good, "--role", "reviewer", "--model", "gpt-6-sol", "--provider", "codex", "--no-cold-read")
expect("a codex seat prints the codex-gcc command", "codex-gcc exec --no-brief --model gpt-6-sol" in r.stdout)

r = run_seat("land", sid, "--outcome", "ok")
expect("landing without the output file warns and fails", r.returncode == 1 and "output file missing" in r.stdout)
os.makedirs(os.path.dirname(OUT), exist_ok=True)
open(OUT, "w").close()
expect("landing with the output file passes", run_seat("land", sid, "--outcome", "ok").returncode == 0)
run_seat("feedback", sid, "--prompt", "thin", "--persona", "fit", "--note", "brief lacked the test command")
w = json.loads(run_seat("weekly", "--json").stdout)
expect("weekly counts the feedback", w["prompt_quality"].get("thin") == 1 and bool(w["notes"]))
expect("weekly counts the thin sections from refusals", any(x.startswith("Background") for x in w["refusals"]))
ev = [json.loads(l) for l in open(os.path.join(T, "domain", "events.jsonl"))]
expect("i-dream gets dispatch, land and feedback events", {"dispatch", "land", "feedback"} <= {e["kind"] for e in ev})
finish()
