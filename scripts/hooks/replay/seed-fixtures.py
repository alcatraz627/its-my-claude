#!/usr/bin/env python3
"""
seed-fixtures.py — build the declared-ready regression fixture set from the corpus.

A fixture is a captured single-turn transcript slice plus a manifest entry saying
what the hook should do with it. This seeder extracts the specific TP/FP fires
that empirical-declared-ready.md §2 classified — pinned by (transcript id, turn
ordinal within that transcript) so extraction is deterministic — verifies each
still fires the CURRENT hook, saves the turn's slice, and writes manifest.json.

It also auto-selects a couple of SILENT negative controls (source edited + a
success word in the final message, yet the hook correctly stayed silent because a
run was detected) so the suite guards against a redesign that starts over-firing.

Run: python3 seed-fixtures.py   (idempotent; overwrites fixtures/declared-ready/)
"""

import json
import os
import shutil
import sys
from pathlib import Path

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import replay_lib as rl  # noqa: E402

HOOK = os.path.join(rl.HOME, ".claude", "scripts", "hooks", "declared-ready-stop.sh")
FIX_DIR = os.path.join(HERE, "fixtures", "declared-ready")
MANIFEST = os.path.join(HERE, "fixtures", "manifest.json")
RUN_DIR = f"/tmp/seed-fixtures-{os.getpid()}"

# Pinned classified fires. Each: transcript-id substring, turn ordinal within that
# transcript, a snippet that MUST appear in the captured final message (a guard so
# a shifted corpus fails loudly instead of saving the wrong turn), TP/FP class, and
# the human note. desired (what v2 should do) is derived from klass below.
SPEC = [
    ("781e356c", 21, "ruff", "TP",
     "ruff lint substituted for runtime exercise of an async/event-loop perf fix; body self-discloses the runtime effect is NOT verified"),
    ("b40f9d66", 0, "remains unverified", "TP",
     "type-check only on a browser drag-scroll hook; agent flags 'what remains unverified' — the interaction tsc cannot see is never exercised"),
    ("b40f9d66", 1, "Type-checks clean", "TP",
     "'Done. Type-checks clean.' on a drag/modifier hook — the cursor/keyboard interaction a type-check cannot see"),
    ("b40f9d66", 3, "type-check clean", "TP",
     "'both fixes applied, type-check clean' on a cursor-correctness fix; drag interaction unexercised"),
    ("b40f9d66", 4, "Comment pass complete", "FP",
     "comment-only .tsx edit — nothing executable changed; Gate0 cannot tell a comment-only diff from a behavioral one"),
    ("1c86d512", 108, "compiling at every step", "TP",
     "swift menubar rebuild 'complete and compiling at every step' — compile-checked to /tmp, never deployed/run"),
    ("1c86d512", 2, "i-dream widget status", "FP",
     "agent DID run the changed CLI ('Verified by running i-dream widget status'); Det2's allow-list has no i-dream/project-CLI entry"),
    ("1c86d512", 128, "awaiting you", "FP",
     "verifiable half verified live; the remaining half is a user-only observation ('awaiting you') — a hedge, not an over-claim"),
    ("5da7133c", 59, "scenarios pass", "FP",
     "4-scenario smoke test with observed per-row results in assistant prose; the tool_result pass/fail scan missed the table"),
    ("dc7f8071", 1, "What changed", "TP",
     "React stale-useMemo fix; the toggle a screenshot cannot catch was never toggled"),
]

DESIRED = {"TP": "block-or-soft", "FP": "soft-or-silent", "CONTROL": "silent"}


def locate(tid):
    hits = list(Path(rl.PROJECTS_DIR).rglob(f"*{tid}*.jsonl"))
    hits = [h for h in hits if "/subagents/" not in str(h) and "/workflows/" not in str(h)]
    return str(hits[0]) if hits else None


def main():
    os.makedirs(RUN_DIR, exist_ok=True)
    if os.path.isdir(FIX_DIR):
        shutil.rmtree(FIX_DIR)
    os.makedirs(FIX_DIR, exist_ok=True)

    # cache each transcript's turns once
    turns_by_tid = {}
    for tid in {s[0] for s in SPEC}:
        path = locate(tid)
        if not path:
            print(f"[skip] transcript not found in corpus: {tid}", file=sys.stderr)
            continue
        turns_by_tid[tid] = (path, rl.split_turns(rl.load_lines(path)))

    entries = []
    idx = 0
    used_transcripts = set()
    for tid, tif, snippet, klass, note in SPEC:
        if tid not in turns_by_tid:
            print(f"[skip] {tid} tif={tif} — transcript gone", file=sys.stderr)
            continue
        path, turns = turns_by_tid[tid]
        if tif >= len(turns):
            print(f"[skip] {tid} tif={tif} — only {len(turns)} turns", file=sys.stderr)
            continue
        turn = turns[tif]
        res = rl.run_turn(HOOK, turn, idx, os.path.join(rl.HOME, ".claude"), RUN_DIR)
        idx += 1
        rl.cleanup_sid(res["sid8"])
        ftext = res["final_text"]
        if snippet.lower() not in ftext.lower():
            print(f"[WARN] {tid} tif={tif}: snippet {snippet!r} not in final text — corpus shifted?", file=sys.stderr)
            continue
        if res["outcome"] != "BLOCK":
            print(f"[WARN] {tid} tif={tif}: expected BLOCK, got {res['outcome']} — skipping", file=sys.stderr)
            continue
        name = f"{klass.lower()}-{tid}-t{tif}"
        fixture_file = os.path.join(FIX_DIR, f"{name}.jsonl")
        with open(fixture_file, "w", encoding="utf-8") as fh:
            fh.write("\n".join(raw for raw, _ in turn) + "\n")
        entries.append({
            "name": name,
            "hook": "declared-ready-stop.sh",
            "fixture": f"fixtures/declared-ready/{name}.jsonl",
            "expected": "block",
            "desired": DESIRED[klass],
            "klass": klass,
            "cwd": res["cwd"],
            "source_transcript": os.path.basename(path),
            "turn_in_file": tif,
            "note": note,
        })
        used_transcripts.add(tid)
        print(f"[fixture] {name}  ({klass}, expected=block)", file=sys.stderr)

    # auto-select up to 2 SILENT negative controls from the same transcripts:
    # source edited + a success word in the final message, yet the hook stayed
    # silent (a run was detected) — the case a redesign must NOT start blocking.
    controls = 0
    success_words = ("done", "works", "fixed", "passing", "passes", "verified", "complete")
    for tid in sorted(used_transcripts):
        if controls >= 2:
            break
        path, turns = turns_by_tid[tid]
        for tif, turn in enumerate(turns):
            if controls >= 2:
                break
            res = rl.run_turn(HOOK, turn, idx, os.path.join(rl.HOME, ".claude"), RUN_DIR)
            idx += 1
            rl.cleanup_sid(res["sid8"])
            ft = res["final_text"].lower()
            if (res["outcome"] == "SILENT" and res["edited_source"]
                    and any(w in ft for w in success_words) and len(res["final_text"]) > 40):
                name = f"control-{tid}-t{tif}"
                with open(os.path.join(FIX_DIR, f"{name}.jsonl"), "w", encoding="utf-8") as fh:
                    fh.write("\n".join(raw for raw, _ in turn) + "\n")
                entries.append({
                    "name": name,
                    "hook": "declared-ready-stop.sh",
                    "fixture": f"fixtures/declared-ready/{name}.jsonl",
                    "expected": "silent",
                    "desired": "silent",
                    "klass": "CONTROL",
                    "cwd": res["cwd"],
                    "source_transcript": os.path.basename(path),
                    "turn_in_file": tif,
                    "note": "negative control: source edited + success claim, but a run was detected so the hook correctly stays silent — a redesign must not start blocking this",
                })
                controls += 1
                print(f"[fixture] {name}  (CONTROL, expected=silent)", file=sys.stderr)

    with open(MANIFEST, "w", encoding="utf-8") as fh:
        json.dump({"fixtures": entries}, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

    try:
        shutil.rmtree(RUN_DIR)
    except OSError:
        pass

    n_tp = sum(1 for e in entries if e["klass"] == "TP")
    n_fp = sum(1 for e in entries if e["klass"] == "FP")
    n_ctl = sum(1 for e in entries if e["klass"] == "CONTROL")
    print(f"\nWROTE {len(entries)} fixtures ({n_tp} TP, {n_fp} FP, {n_ctl} control) -> {MANIFEST}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
