#!/usr/bin/env python3
"""
seed-structural-claim.py — build the structural-claim regression fixture set.

Two fixture sources, both registered in the shared fixtures/manifest.json (the
declared-ready entries are preserved):

  1. REAL corpus captures — pinned by (agent/transcript id substring, turn ordinal,
     a snippet guard). These are the load-bearing regression guards for the VALUED
     behavior: the design-from-memory authoring fires must keep firing (SOFT), and
     grounded/code-read design turns must stay silent.

  2. SYNTHETIC slices — hand-authored single-turn transcripts with controlled
     tool-histories, for the read-gate branches the corpus can't cleanly provide
     (esp. the blind-authority BLOCK — the corpus has 0). Their prose is faithful
     to the empirical-structural-claim.md classified records (person-owns=rec 32,
     meta=rec 13, backtick-path=rec 33/35/44, blind-authority=rec 36 shape).

Each entry carries `expected` (what the hook does now — asserted by run-fixtures.sh)
and `desired` (the intended class outcome — reported, not asserted).

Run: python3 seed-structural-claim.py [--hook <path>]   (default: the live hook)
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

HOOK_NAME = "guard-structural-claim.sh"
FIX_DIR = os.path.join(HERE, "fixtures", "structural-claim")
MANIFEST = os.path.join(HERE, "fixtures", "manifest.json")
RUN_DIR = f"/tmp/seed-structural-{os.getpid()}"
HIGH_CWD = os.path.join(rl.HOME, ".claude")
LOW_CWD = os.path.join(rl.HOME, "Downloads")

# ── REAL corpus captures: (id-substr, turn, snippet-guard, klass, desired, note)
REAL = [
    ("a280d481049521721", 0, "control-layer", "AUTHORING-NOREAD", "soft",
     "design-from-brief ownership map, no code read -> the valued authoring fire (SOFT)"),
    ("a290b519d80f12b2d", 0, "no codebase reads", "AUTHORING-NOREAD", "soft",
     "'Designing model-first, no codebase reads' -- the canonical design-from-memory fire (SOFT)"),
    ("ae475269eb8be556d", 0, "why each finding matters", "AUTHORING-READ", "silent",
     "code review that READ 10 files this turn -> grounding done -> silent"),
    ("6ec6743c-c045-4612-b3a4-a3cfe285e6ce", 50, "ts:build", "VERIFIED", "silent",
     "ownership diagram in a turn that edited 4 .ts files + ran build -> code_touch/E3 -> silent"),
]


def U(cwd, t="continue"):
    return {"type": "user", "cwd": cwd, "message": {"role": "user", "content": t}}
def T(cwd, text):
    return {"type": "assistant", "cwd": cwd, "message": {"role": "assistant", "content": [{"type": "text", "text": text}]}}
def EDIT(cwd, fp):
    return {"type": "assistant", "cwd": cwd, "message": {"role": "assistant",
            "content": [{"type": "tool_use", "name": "Edit", "input": {"file_path": fp, "old_string": "a", "new_string": "b"}}]}}
def READ(cwd, fp):
    return {"type": "assistant", "cwd": cwd, "message": {"role": "assistant",
            "content": [{"type": "tool_use", "name": "Read", "input": {"file_path": fp}}]}}


def synth():
    out = []
    out.append(("synth-person-owns", "PERSON", "silent", HIGH_CWD, [
        U(HIGH_CWD),
        T(HIGH_CWD, "Flag it to whoever owns the schema separately, but it does not block this merge.")]))
    out.append(("synth-meta", "META", "silent", HIGH_CWD, [
        U(HIGH_CWD),
        T(HIGH_CWD, "The structural-claim gate fires when an assistant message says 'X is the authority on Y' with no tool-call signature.")]))
    out.append(("synth-backtick-path", "AUTHORITY", "silent", HIGH_CWD, [
        U(HIGH_CWD),
        T(HIGH_CWD, "The daemon is the source of truth for the queue -- it consumes `backend/workers/ingest_daemon.py` on boot.")]))
    out.append(("synth-verified-e3", "AUTHORITY", "silent", HIGH_CWD, [
        U(HIGH_CWD),
        T(HIGH_CWD, "Our managed server owns the port now (PID 9383, launchctl list shows it healthy at exit-status 0).")]))
    out.append(("synth-authoring-read", "AUTHORING-READ", "silent", HIGH_CWD, [
        U(HIGH_CWD),
        READ(HIGH_CWD, "/x/output-controls.ts"),
        T(HIGH_CWD, "| 1 FETCH-SHAPING | output-data hook | it owns the fetch; these are the request inputs |")]))
    out.append(("synth-blind-authority-block", "BLIND", "block", HIGH_CWD, [
        U(HIGH_CWD, "how does auth work"),
        EDIT(HIGH_CWD, "/x/worker.py"),
        T(HIGH_CWD, "The Python backend is the source of truth for token validity.")]))
    out.append(("synth-blind-authority-soft", "BLIND", "soft", LOW_CWD, [
        U(LOW_CWD, "how does auth work"),
        EDIT(LOW_CWD, "/x/worker.py"),
        T(LOW_CWD, "The Python backend is the source of truth for token validity.")]))
    return out


def locate_transcript(sub):
    hits = list(Path(rl.PROJECTS_DIR).rglob(f"*{sub}*.jsonl"))
    if sub.count("-") >= 4:  # a full transcript uuid -> exclude subagent/workflow copies
        hits = [h for h in hits if "/subagents/" not in str(h) and "/workflows/" not in str(h)]
    return str(hits[0]) if hits else None


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

    for sub, tif, snip, klass, desired, note in REAL:
        path = locate_transcript(sub)
        if not path:
            print(f"[skip] real: transcript {sub} not in corpus", file=sys.stderr)
            continue
        turns = rl.split_turns(rl.load_lines(path))
        if tif >= len(turns):
            print(f"[skip] real {sub}: only {len(turns)} turns", file=sys.stderr)
            continue
        turn = turns[tif]
        res = rl.run_turn(hook, turn, idx, os.path.join(rl.HOME, ".claude"), RUN_DIR)
        idx += 1
        rl.cleanup_sid(res["sid8"])
        if snip.lower() not in res["final_text"].lower():
            print(f"[WARN] real {sub}: snippet {snip!r} absent -- corpus shifted?", file=sys.stderr)
            continue
        name = f"real-{sub[:12]}-t{tif}"
        with open(os.path.join(FIX_DIR, f"{name}.jsonl"), "w", encoding="utf-8") as fh:
            fh.write("\n".join(raw for raw, _ in turn) + "\n")
        entries.append({
            "name": name, "hook": HOOK_NAME, "fixture": f"fixtures/structural-claim/{name}.jsonl",
            "expected": res["outcome"].lower(), "desired": desired, "klass": klass,
            "cwd": res["cwd"], "source_transcript": os.path.basename(path), "turn_in_file": tif,
            "note": note,
        })
        print(f"[fixture] {name}  ({klass}, expected={res['outcome'].lower()}, desired={desired})", file=sys.stderr)

    for name, klass, desired, cwd, lines in synth():
        slice_path = os.path.join(FIX_DIR, f"{name}.jsonl")
        with open(slice_path, "w", encoding="utf-8") as fh:
            for l in lines:
                fh.write(json.dumps(l) + "\n")
        outcome, rc, err, _ = rl.run_slice(hook, slice_path, idx, cwd, RUN_DIR)
        idx += 1
        entries.append({
            "name": name, "hook": HOOK_NAME, "fixture": f"fixtures/structural-claim/{name}.jsonl",
            "expected": outcome.lower(), "desired": desired, "klass": klass,
            "cwd": cwd, "source_transcript": "SYNTHETIC", "turn_in_file": 0,
            "note": f"synthetic slice (faithful to empirical record) -- controlled tool-history for the {klass} read-gate branch",
        })
        print(f"[fixture] {name}  ({klass}, expected={outcome.lower()}, desired={desired})", file=sys.stderr)

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
    print(f"\nWROTE {len(entries)} structural-claim fixtures (+{len(kept)} preserved) -> {MANIFEST}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
