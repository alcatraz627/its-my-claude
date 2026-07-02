#!/usr/bin/env python3
"""
replay-corpus.py — the ship-gate driver for ~/.claude Stop-hook changes.

What it is, in human terms: a way to ask "if I change this Stop hook, how does it
behave on every turn the account has ever actually taken?" It walks the real
transcript corpus, reconstructs each turn the way Claude Code would present it to
a Stop hook, and pipes it through the REAL hook script under test — not a Python
re-implementation. So the numbers it reports are the numbers the live hook would
produce, with no port-drift risk.

Runtime contract: for every .jsonl transcript under ~/.claude/projects, split into
turns (a turn starts at each real user message), reconstruct each turn into the
Stop-hook input shape (slice file + edit-list + unique-sid payload), run the real
hook, and classify the outcome BLOCK / SOFT / SILENT. The turn model and the
faithful invocation live in replay_lib.py.

Output: a tally to stderr + a JSONL of fires (BLOCK/SOFT) to --out, one line per
fire, ready for hand-classification.

Caveats worth knowing (see README.md for the full list):
  - Per-turn edit reconstruction matches the reference replay method
    (empirical-declared-ready.md §1c) and is the conservative under-count
    direction. Production's edit-list is cumulative across the session; a claim in
    a turn that edited nothing but referenced source edited earlier won't fire
    here. Deliberate — it matches the ~28 calibration target.
  - Per-turn isolated slices mean run-detection only sees THIS turn's runs. This
    matches the gate's intent ("did you run it THIS turn"). Production's tail(-400)
    can leak a prior turn's run into a short turn; that direction fires LESS, so
    this harness is the strict side.
"""

import argparse
import json
import os
import random
import sys
import time
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import replay_lib as rl  # noqa: E402


def iter_transcripts(projects_dir, main_only, only_subs):
    for path in sorted(Path(projects_dir).rglob("*.jsonl")):
        p = str(path)
        if main_only and ("/subagents/" in p or "/workflows/" in p):
            continue
        if only_subs and not any(s in path.name for s in only_subs):
            continue
        yield path


def main():
    ap = argparse.ArgumentParser(description="Replay the real transcript corpus through a Stop hook.")
    ap.add_argument("--hook", required=True, help="Path to the Stop hook script under test.")
    ap.add_argument("--limit", type=int, default=0, help="Max transcripts to process (0=all).")
    ap.add_argument("--sample", type=int, default=0, help="Random sample of N transcripts (0=off).")
    ap.add_argument("--cwd", default=os.path.join(rl.HOME, ".claude"),
                    help="Fallback cwd for stakes when a turn has no recorded cwd.")
    ap.add_argument("--out", default="", help="Fire JSONL output path (default: /tmp run dir).")
    ap.add_argument("--keep-slices", action="store_true", help="Do not delete the temp slice dir.")
    ap.add_argument("--main-only", action="store_true",
                    help="Skip subagents/workflows transcripts (default: include, matches reference sweep).")
    ap.add_argument("--only", action="append", default=[],
                    help="Restrict to transcripts whose filename contains this substring (repeatable).")
    ap.add_argument("--seed", type=int, default=1337, help="RNG seed for --sample.")
    ap.add_argument("--force", action="store_true", help="Run even if a mute file is present.")
    ap.add_argument("--projects-dir", default=rl.PROJECTS_DIR, help="Corpus root (default ~/.claude/projects).")
    args = ap.parse_args()

    hook_path = os.path.abspath(args.hook)
    if not os.path.isfile(hook_path):
        print(f"ERROR: hook not found: {hook_path}", file=sys.stderr)
        return 2

    tokens, present = rl.check_mute_files(hook_path)
    print(f"[guard] hook honors mute files: {tokens or '(none)'}", file=sys.stderr)
    if present:
        print("\n" + "!" * 72, file=sys.stderr)
        print("!! MUTE FILE PRESENT — this hook will silently exit 0 for EVERY turn.", file=sys.stderr)
        print("!! The replay would report 0 fires and LIE about the hook's behavior.", file=sys.stderr)
        for f in present:
            print(f"!!   present: {f}", file=sys.stderr)
        print("!! Remove the mute file (or pass --force to run anyway, knowingly).", file=sys.stderr)
        print("!" * 72 + "\n", file=sys.stderr)
        if not args.force:
            return 3

    run_dir = f"/tmp/hook-replay-{os.getpid()}"
    os.makedirs(run_dir, exist_ok=True)
    out_path = args.out or os.path.join(run_dir, "fires.jsonl")

    transcripts = list(iter_transcripts(args.projects_dir, args.main_only, args.only))
    if args.sample and args.sample < len(transcripts):
        random.Random(args.seed).shuffle(transcripts)
        transcripts = transcripts[: args.sample]
    if args.limit:
        transcripts = transcripts[: args.limit]

    hook_name = os.path.basename(hook_path)
    print(f"[replay] hook={hook_name}  transcripts={len(transcripts)}  "
          f"main_only={args.main_only}  out={out_path}", file=sys.stderr)

    tally = {"BLOCK": 0, "SOFT": 0, "SILENT": 0}
    n_turns = n_files = errors = 0
    used_sids = set()
    global_idx = 0
    t0 = time.time()

    with open(out_path, "w", encoding="utf-8") as out_fh:
        for path in transcripts:
            n_files += 1
            if n_files % 50 == 0 or n_files == len(transcripts):
                el = time.time() - t0
                print(f"[progress] {n_files}/{len(transcripts)} transcripts  {n_turns} turns  "
                      f"fires B/S={tally['BLOCK']}/{tally['SOFT']}  {el:.0f}s", file=sys.stderr)
            try:
                lines = rl.load_lines(path)
            except Exception:
                errors += 1
                continue
            for turn_in_file, turn in enumerate(rl.split_turns(lines)):
                res = rl.run_turn(hook_path, turn, global_idx, args.cwd, run_dir)
                global_idx += 1
                used_sids.add(res["sid8"])
                n_turns += 1
                if res["err"]:
                    errors += 1
                tally[res["outcome"]] += 1

                if res["outcome"] in ("BLOCK", "SOFT"):
                    out_fh.write(json.dumps({
                        "transcript": str(path),
                        "turn_in_file": turn_in_file,
                        "global_turn": n_turns - 1,
                        "sid8": res["sid8"],
                        "decision": res["outcome"],
                        "exit": res["exit"],
                        "cwd": res["cwd"],
                        "edited_source": res["edited_source"],
                        "final_text": res["final_text"][:600],
                    }, ensure_ascii=False) + "\n")

                if not args.keep_slices:
                    try:
                        os.remove(res["slice_path"])
                    except OSError:
                        pass

    for sid8 in used_sids:
        rl.cleanup_sid(sid8)
    if not args.keep_slices:
        try:
            os.rmdir(run_dir)
        except OSError:
            pass

    el = time.time() - t0
    fires = tally["BLOCK"] + tally["SOFT"]
    print("\n" + "=" * 60, file=sys.stderr)
    print(f"HOOK       : {hook_name}", file=sys.stderr)
    print(f"transcripts: {n_files}", file=sys.stderr)
    print(f"turns      : {n_turns}", file=sys.stderr)
    print(f"BLOCK      : {tally['BLOCK']}", file=sys.stderr)
    print(f"SOFT       : {tally['SOFT']}", file=sys.stderr)
    print(f"SILENT     : {tally['SILENT']}", file=sys.stderr)
    print(f"TOTAL FIRES: {fires}   ({100*fires/max(n_turns,1):.2f}% of turns)", file=sys.stderr)
    print(f"errors     : {errors}", file=sys.stderr)
    print(f"elapsed    : {el:.0f}s", file=sys.stderr)
    print(f"fires JSONL: {out_path}", file=sys.stderr)
    print("=" * 60, file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
