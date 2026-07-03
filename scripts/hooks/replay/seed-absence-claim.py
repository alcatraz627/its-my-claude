#!/usr/bin/env python3
"""
seed-absence-claim.py — build the absence-claim regression fixture set.

One REAL corpus capture (the founding 2026-07-03 warn-events turn — session
69aeb3ea, turn 56, an fd -H probe that missed a git-ignored file → "doesn't even
exist / never fired") plus SYNTHETIC single-turn slices with controlled tool
histories for the clear/no-clear branches the corpus can't cleanly provide.

Each entry carries `expected` (what the hook does now — asserted by run-fixtures.sh)
and `desired` (the intended class — reported, not asserted).

Run: python3 seed-absence-claim.py [--hook <path>]   (default: the live hook)
"""

import argparse
import json
import os
import shutil
import sys
from pathlib import Path

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import replay_lib as rl  # noqa: E402

HOOK_NAME = "guard-absence-claim.sh"
FIX_DIR = os.path.join(HERE, "fixtures", "absence-claim")
MANIFEST = os.path.join(HERE, "fixtures", "manifest.json")
RUN_DIR = f"/tmp/seed-absence-{os.getpid()}"
HIGH_CWD = os.path.join(rl.HOME, ".claude")
LOW_CWD = os.path.join(rl.HOME, "Downloads")

# REAL corpus capture: (session-substr, turn, snippet-guard, desired, note)
REAL = [
    ("69aeb3ea-3288-47e0-87e7-d1c639a4c438", 56, "doesn't even exist", "block",
     "FOUNDING event — `warn-log.sh` writes to a file that 'doesn't even exist yet, never "
     "fired', off an `fd -H` probe (hidden, NOT --no-ignore) that skipped the git-ignored "
     "warn-events.jsonl. High-stakes ~/.claude -> BLOCK. The exact recurrence this gate targets."),
]


def _u(cwd, t="go"):
    return {"type": "user", "cwd": cwd, "message": {"role": "user", "content": t}}
def _t(cwd, t):
    return {"type": "assistant", "cwd": cwd, "message": {"role": "assistant", "content": [{"type": "text", "text": t}]}}
def _bash(cwd, c):
    return {"type": "assistant", "cwd": cwd, "message": {"role": "assistant",
            "content": [{"type": "tool_use", "name": "Bash", "input": {"command": c}}]}}
def _read(cwd, fp):
    return {"type": "assistant", "cwd": cwd, "message": {"role": "assistant",
            "content": [{"type": "tool_use", "name": "Read", "input": {"file_path": fp}}]}}


def build_absence_slices():
    out = []
    # fd WITHOUT --no-ignore (only -H) -> does NOT clear -> BLOCK (the founding shape)
    out.append(("synth-fd-H-no-clear", "block", HIGH_CWD, [
        _u(HIGH_CWD, "does the telemetry file exist"),
        _bash(HIGH_CWD, "fd -H 'warn-events.jsonl' ~/.claude --max-depth 3"),
        _t(HIGH_CWD, "The file `warn-events.jsonl` does not exist yet — it never fired.")]))
    # absence claim WITH an ignore-transparent search of the subject -> silent
    out.append(("synth-noignore-clears", "silent", HIGH_CWD, [
        _u(HIGH_CWD, "does it exist"),
        _bash(HIGH_CWD, "rg --no-ignore --hidden -l 'warn-events' ~/.claude"),
        _t(HIGH_CWD, "The file `warn-events.jsonl` does not exist yet.")]))
    # absence claim after a direct existence probe (test -f) -> silent
    out.append(("synth-testf-clears", "silent", HIGH_CWD, [
        _u(HIGH_CWD, "does it exist"),
        _bash(HIGH_CWD, "test -f ~/.claude/hooks/warn-events.jsonl && echo yes"),
        _t(HIGH_CWD, "`warn-events.jsonl` does not exist yet.")]))
    # hedged absence claim -> silent (the claim self-flags as unconfirmed)
    out.append(("synth-hedged", "silent", HIGH_CWD, [
        _u(HIGH_CWD, "is there a config loader"),
        _t(HIGH_CWD, "As far as I searched, `src/config_loader.py` does not exist — but I haven't grepped the full tree.")]))
    # Path A: "no existing module for <snake>" with no probe -> BLOCK (high-stakes)
    out.append(("synth-pathA-no-existing-module", "block", HIGH_CWD, [
        _u(HIGH_CWD, "add the payload builder"),
        _t(HIGH_CWD, "There is no existing module for build_widget_payload, so I'll create one.")]))
    # negative control: non-file "does not exist" (mongo collection, weak subject) -> silent
    out.append(("synth-weak-subject-noise", "silent", HIGH_CWD, [
        _u(HIGH_CWD, "check the collection"),
        _t(HIGH_CWD, "The `worker_info` collection does not exist in mongo yet.")]))
    # negative control: multi-line script, unrelated `ls` must NOT clear the claim -> BLOCK
    out.append(("synth-multiline-unrelated-ls", "block", HIGH_CWD, [
        _u(HIGH_CWD, "wire the telemetry"),
        _bash(HIGH_CWD, "echo checking warn-events\nls scripts/hooks/\nrg -l 'warn-events' scripts/"),
        _t(HIGH_CWD, "The file `warn-events.jsonl` does not exist yet, it never fired.")]))
    # a Read of the subject clears (ignore-blind) -> silent
    out.append(("synth-read-clears", "silent", HIGH_CWD, [
        _u(HIGH_CWD, "does it exist"),
        _read(HIGH_CWD, "/Users/alcatraz627/.claude/hooks/warn-events.jsonl"),
        _t(HIGH_CWD, "`warn-events.jsonl` does not exist yet.")]))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--hook", default=os.path.join(rl.HOME, ".claude", "scripts", "hooks", HOOK_NAME))
    args = ap.parse_args()
    hook = args.hook
    os.makedirs(RUN_DIR, exist_ok=True)
    if os.path.isdir(FIX_DIR):
        shutil.rmtree(FIX_DIR)
    os.makedirs(FIX_DIR, exist_ok=True)

    entries = []
    idx = 0

    for sub, tif, snip, desired, note in REAL:
        hits = [h for h in Path(rl.PROJECTS_DIR).rglob(f"*{sub}*.jsonl")
                if "/subagents/" not in str(h) and "/workflows/" not in str(h)]
        if not hits:
            print(f"[skip] real: transcript {sub} not in corpus", file=sys.stderr)
            continue
        path = str(hits[0])
        turns = rl.split_turns(rl.load_lines(path))
        if tif >= len(turns):
            print(f"[skip] real {sub}: only {len(turns)} turns", file=sys.stderr)
            continue
        turn = turns[tif]
        res = rl.run_turn(hook, turn, idx, HIGH_CWD, RUN_DIR)
        idx += 1
        rl.cleanup_sid(res["sid8"])
        if snip.lower() not in res["final_text"].lower():
            print(f"[WARN] real {sub}: snippet {snip!r} absent — corpus shifted?", file=sys.stderr)
            continue
        name = f"real-founding-{sub[:8]}-t{tif}"
        with open(os.path.join(FIX_DIR, f"{name}.jsonl"), "w", encoding="utf-8") as fh:
            fh.write("\n".join(raw for raw, _ in turn) + "\n")
        entries.append({
            "name": name, "hook": HOOK_NAME, "fixture": f"fixtures/absence-claim/{name}.jsonl",
            "expected": res["outcome"].lower(), "desired": desired, "klass": "FOUNDING",
            "cwd": res["cwd"], "source_transcript": os.path.basename(path), "turn_in_file": tif,
            "note": note,
        })
        print(f"[fixture] {name}  (FOUNDING, expected={res['outcome'].lower()}, desired={desired})", file=sys.stderr)

    for name, desired, cwd, lines in build_absence_slices():
        slice_path = os.path.join(FIX_DIR, f"{name}.jsonl")
        with open(slice_path, "w", encoding="utf-8") as fh:
            for l in lines:
                fh.write(json.dumps(l) + "\n")
        outcome, rc, err, _ = rl.run_slice(hook, slice_path, idx, cwd, RUN_DIR)
        idx += 1
        entries.append({
            "name": name, "hook": HOOK_NAME, "fixture": f"fixtures/absence-claim/{name}.jsonl",
            "expected": outcome.lower(), "desired": desired, "klass": "SYNTH",
            "cwd": cwd, "source_transcript": "SYNTHETIC", "turn_in_file": 0,
            "note": f"synthetic controlled-tool-history slice (desired={desired})",
        })
        print(f"[fixture] {name}  (SYNTH, expected={outcome.lower()}, desired={desired})", file=sys.stderr)

    manifest = {"fixtures": []}
    if os.path.isfile(MANIFEST):
        manifest = json.loads(Path(MANIFEST).read_text())
    kept = [e for e in manifest.get("fixtures", []) if e.get("hook") != HOOK_NAME]
    manifest["fixtures"] = kept + entries
    with open(MANIFEST, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

    try:
        shutil.rmtree(RUN_DIR)
    except OSError:
        pass
    print(f"\nWROTE {len(entries)} absence-claim fixtures (+{len(kept)} preserved) -> {MANIFEST}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
