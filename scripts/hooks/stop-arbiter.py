#!/usr/bin/env python3
"""Run every gate that can hold a turn open, and speak with one voice.

Claude Code runs Stop hooks independently, so a reply could be sent back by four gates at
once, each with its own message and its own paid retry. This runs them together and answers
with one message, the highest priority first. Each gate still decides for itself, and still
keeps its own loop safety and mute file.

Gates are listed in stop-gates.txt, highest priority first. A gate that crashes or times out
is skipped: a bug in one gate must never hold a turn or silence the others.
"""
import json
import os
import shlex
import subprocess
import sys
import tempfile
import threading

HERE = os.path.dirname(os.path.abspath(__file__))
GATES = os.environ.get("STOP_ARBITER_GATES", os.path.join(HERE, "stop-gates.txt"))
# Long enough for the slowest gate's own budget (pr-review-gate.py, 40 s).
TIMEOUT_S = float(os.environ.get("STOP_ARBITER_TIMEOUT", "55"))
# Between gates in the one message, and what the audit splits on to count each gate.
SEPARATOR = "\n\n--- next gate ---\n\n"


def read_gates(path):
    with open(path) as f:
        return [line.strip() for line in f if line.strip() and not line.startswith("#")]


def run_gate(command, stdin_text):
    """One gate's verdict as a dict, or None when it had nothing to say or failed."""
    argv = [os.path.expanduser(part) for part in shlex.split(command)]
    # Files, not pipes: a gate that leaves a background job holding its output must not
    # make this wait for that job, or lose what the gate already said.
    try:
        with tempfile.TemporaryFile("w+") as out_file, tempfile.TemporaryFile("w+") as err_file:
            r = subprocess.run(argv, input=stdin_text, stdout=out_file, stderr=err_file, text=True, timeout=TIMEOUT_S)
            out_file.seek(0)
            err_file.seek(0)
            out, err = out_file.read().strip(), err_file.read().strip()
    except (OSError, subprocess.SubprocessError, ValueError):
        return None
    if r.returncode == 2:
        return {"decision": "block", "reason": err}
    if r.returncode != 0 or not out:
        return None
    try:
        verdict = json.loads(out)
    except ValueError:
        return {"systemMessage": out}
    return verdict if isinstance(verdict, dict) else None


def merge(verdicts):
    """Fold the gates' verdicts, already in priority order, into one answer."""
    reasons = [v["reason"] for v in verdicts if v.get("decision") == "block" and v.get("reason")]
    notes = [v["systemMessage"] for v in verdicts if v.get("systemMessage")]
    context = [v["hookSpecificOutput"]["additionalContext"] for v in verdicts
               if isinstance(v.get("hookSpecificOutput"), dict) and v["hookSpecificOutput"].get("additionalContext")]
    answer = {}
    if reasons:
        answer.update(decision="block", reason=SEPARATOR.join(reasons))
    if notes:
        answer["systemMessage"] = "\n".join(notes)
    if context:
        answer["hookSpecificOutput"] = {"hookEventName": "Stop", "additionalContext": "\n".join(context)}
    return answer


def main():
    stdin_text = sys.stdin.read()
    try:
        gates = read_gates(GATES)
    except OSError as err:
        print(json.dumps({"systemMessage": "stop-arbiter cannot read its gate list, so no gate ran: %s" % err}))
        return 0
    verdicts = [None] * len(gates)

    def work(i):
        try:
            verdicts[i] = run_gate(gates[i], stdin_text)
        except Exception:
            verdicts[i] = None

    threads = [threading.Thread(target=work, args=(i,)) for i in range(len(gates))]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    answer = merge([v for v in verdicts if v])
    if answer:
        print(json.dumps(answer, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
