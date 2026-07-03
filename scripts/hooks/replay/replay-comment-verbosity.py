#!/usr/bin/env python3
"""replay-comment-verbosity.py — corpus fire-rate estimator for
guard-comment-verbosity.sh.

Walks every transcript under ~/.claude/projects, pulls each Edit/Write/MultiEdit
that targets a TS/JS/Python file, keeps the ones whose ADDED text plausibly holds
a comment block (cheap pre-filter), synthesizes a PostToolUse payload, runs the
REAL hook, and tallies fires. Because the hook only reads the added slice (never
the on-disk tree), this replay is FAITHFUL — the fire it records is exactly the
fire the agent would have seen at write time.

The number that matters: fires / comment-adding-edits. A high rate means the gate
is a mute magnet; tighten the thresholds. The synthetic suite
(fixtures/comment-verbosity/test-comment-verbosity.sh) is the authoritative
acceptance gate; this run is the precision sanity-check.

Usage:
  python3 replay-comment-verbosity.py --sample 400 --main-only
  python3 replay-comment-verbosity.py --out /tmp/cv-fires.jsonl
"""
import argparse
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import replay_lib as rl  # noqa: E402

HOOK = os.path.join(rl.HOME, ".claude", "scripts", "hooks", "guard-comment-verbosity.sh")
SRC_RE = re.compile(r"\.(ts|tsx|js|jsx|mjs|cjs|mts|cts|py)$", re.I)
EDIT_TOOLS = {"Edit", "Write", "MultiEdit"}
TRIPLE = ('"""', "'''")
CMT_LINE = re.compile(r"^\s*(//|#)")
SAMPLE_RE = re.compile(r"\[(docstring|module-docstring|block-comment|comment-run)\] (\d+) prose lines")


def cv_payload_text(ti):
    if ti.get("content"):
        return ti["content"]
    if ti.get("new_string"):
        return ti["new_string"]
    return "\n".join(e.get("new_string", "") for e in (ti.get("edits") or []))


def has_comment_block(text):
    """Cheap pre-filter: a triple-quote, a /* block, or a >=7-line comment run."""
    if any(t in text for t in TRIPLE) or "/*" in text:
        return True
    run = 0
    for line in text.splitlines():
        if CMT_LINE.match(line):
            run += 1
            if run >= 7:
                return True
        else:
            run = 0
    return False


def cv_run_hook(tool, fp, text, sid):
    payload = json.dumps({
        "session_id": sid, "tool_name": tool,
        "tool_input": {"file_path": fp, "content": text},
    })
    env = dict(os.environ)
    env["WARN_LOG_STORE"] = os.path.join(
        os.environ.get("TMPDIR", "/tmp"), f"cv-replay-warn-{os.getpid()}.jsonl")
    try:
        proc = subprocess.run(["bash", HOOK], input=payload.encode("utf-8"),
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              timeout=60, env=env)
        out = proc.stdout.decode("utf-8", "replace")
    except Exception:
        return False, ""
    if "additionalContext" not in out:
        return False, ""
    try:
        msg = json.loads(out).get("hookSpecificOutput", {}).get("additionalContext", "")
    except Exception:
        msg = out
    return True, msg


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sample", type=int, default=0)
    ap.add_argument("--seed", type=int, default=1337)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--main-only", action="store_true")
    ap.add_argument("--out", default="/tmp/cv-fires.jsonl")
    ap.add_argument("--projects-dir", default=rl.PROJECTS_DIR)
    args = ap.parse_args()

    if not os.path.isfile(HOOK):
        print(f"ERROR: hook not found: {HOOK}", file=sys.stderr)
        return 2

    transcripts = sorted(Path(args.projects_dir).rglob("*.jsonl"))
    if args.main_only:
        transcripts = [t for t in transcripts
                       if "/subagents/" not in str(t) and "/workflows/" not in str(t)]
    if args.sample and args.sample < len(transcripts):
        import random
        random.Random(args.seed).shuffle(transcripts)
        transcripts = transcripts[: args.sample]
    if args.limit:
        transcripts = transcripts[: args.limit]

    print(f"[replay-cv] hook={os.path.basename(HOOK)} transcripts={len(transcripts)} "
          f"out={args.out}", file=sys.stderr)

    src_edits = candidates = fires = 0
    by_kind = {}
    idx = 0
    t0 = time.time()
    with open(args.out, "w", encoding="utf-8") as out_fh:
        for n, path in enumerate(transcripts, 1):
            if n % 100 == 0 or n == len(transcripts):
                print(f"[progress] {n}/{len(transcripts)}  src={src_edits} cand={candidates} "
                      f"fires={fires}  {time.time()-t0:.0f}s", file=sys.stderr)
            try:
                lines = rl.load_lines(path)
            except Exception:
                continue
            for _, obj in lines:
                if obj is None or obj.get("type") != "assistant":
                    continue
                content = (obj.get("message") or {}).get("content")
                if not isinstance(content, list):
                    continue
                for it in content:
                    if not (isinstance(it, dict) and it.get("type") == "tool_use"
                            and it.get("name") in EDIT_TOOLS):
                        continue
                    ti = it.get("input") or {}
                    fp = ti.get("file_path")
                    if not fp or not SRC_RE.search(fp):
                        continue
                    src_edits += 1
                    text = cv_payload_text(ti)
                    if not text or not has_comment_block(text):
                        continue
                    candidates += 1
                    sid = f"{idx:08x}" + "cafef00dbeef"
                    idx += 1
                    fired, msg = cv_run_hook(it.get("name"), fp, text, sid)
                    if fired:
                        fires += 1
                        m = SAMPLE_RE.search(msg)
                        kind = m.group(1) if m else "?"
                        by_kind[kind] = by_kind.get(kind, 0) + 1
                        first = msg.split("\n")[1].strip() if "\n" in msg else msg[:120]
                        out_fh.write(json.dumps({
                            "transcript": path.name, "file": fp,
                            "kind": kind, "finding": first,
                        }, ensure_ascii=False) + "\n")

    el = time.time() - t0

    def pct(a, b):
        return f"{100.0*a/b:.1f}%" if b else "n/a"
    print("\n" + "=" * 60, file=sys.stderr)
    print(f"HOOK              : {os.path.basename(HOOK)}", file=sys.stderr)
    print(f"transcripts       : {len(transcripts)}", file=sys.stderr)
    print(f"source edits      : {src_edits}   (TS/JS/Py Edit|Write|MultiEdit)", file=sys.stderr)
    print(f"comment-adding    : {candidates}   (added text holds a comment block)", file=sys.stderr)
    print(f"FIRES             : {fires}", file=sys.stderr)
    print(f"fire / comment-add: {pct(fires, candidates)}", file=sys.stderr)
    print(f"fire / all-edits  : {pct(fires, src_edits)}", file=sys.stderr)
    print(f"by kind           : {by_kind}", file=sys.stderr)
    print(f"elapsed           : {el:.0f}s", file=sys.stderr)
    print(f"fires JSONL       : {args.out}", file=sys.stderr)
    print("=" * 60, file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
