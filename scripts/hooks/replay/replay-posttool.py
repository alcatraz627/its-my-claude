#!/usr/bin/env python3
"""
replay-posttool.py — corpus fire-rate estimator for a PostToolUse Edit|Write hook.

Standalone companion to the Stop-hook replay harness. It does NOT modify the
Stop-hook replay tools (replay-corpus.py / replay_lib's turn model); it only
imports replay_lib's read helpers. It walks every transcript under
~/.claude/projects, pulls each Edit/Write/MultiEdit tool_use that targets a TS/JS
file AND adds an `export` declaration, synthesizes a PostToolUse payload, runs the
REAL hook in BOTH reference-counting modes (lenient + strict), and tallies fires.

Honest caveat — write-time vs current-tree: the hook greps the CURRENT on-disk
tree, which is post-deletion for the recorded S3 symbols. So this is a write-time
APPROXIMATION. The synthetic suite
(fixtures/speculative-export/test-speculative-export.sh) is the authoritative
acceptance gate; this corpus run is a rate sanity-check only.

Usage:
  python3 replay-posttool.py                 # both modes, whole corpus
  python3 replay-posttool.py --sample 200    # random 200 transcripts
  python3 replay-posttool.py --main-only     # skip subagents/workflows
  python3 replay-posttool.py --out /tmp/specexport-fires.jsonl
"""
import argparse
import glob
import json
import os
import random
import re
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import replay_lib as rl  # noqa: E402

HOOK = os.path.join(rl.HOME, ".claude", "scripts", "hooks", "guard-speculative-export.sh")
TSJS_RE = re.compile(r"\.(ts|tsx|js|jsx|mjs|cjs|mts|cts)$", re.I)
# Cheap pre-filter mirroring the hook's own extraction regex, so we only pay the
# bash+rg cost on edits that actually add an exported declaration.
EXPORT_DECL_RE = re.compile(
    r"export\s+(?:declare\s+)?(?:async\s+)?(?:abstract\s+)?"
    r"(?:function|const|let|var|type|interface|class|enum)\s+[A-Za-z_$]"
)
FIRE_SYM_RE = re.compile(r"▸ `([^`]+)`")  # ▸ `NAME`
EDIT_TOOLS = {"Edit", "Write", "MultiEdit"}


def payload_text(ti):
    if ti.get("content"):
        return ti["content"]
    if ti.get("new_string"):
        return ti["new_string"]
    return "\n".join(e.get("new_string", "") for e in (ti.get("edits") or []))


def run_spec_hook(ti, mode, sid):
    """Invoke the real hook once against a synthesized PostToolUse payload.
    Returns (fired, [symbol names flagged])."""
    payload = json.dumps({"session_id": sid, "tool_input": ti})
    env = dict(os.environ)
    env["SPECEXPORT_MODE"] = mode
    # Isolate telemetry: the hook calls warn-log.sh on every fire; a replay must
    # NOT write those synthetic fires into the live warn-events ledger.
    env["WARN_LOG_STORE"] = os.path.join(
        os.environ.get("TMPDIR", "/tmp"), f"specexport-replay-warn-{os.getpid()}.jsonl")
    try:
        proc = subprocess.run(["bash", HOOK], input=payload.encode("utf-8"),
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              timeout=90, env=env)
        out = proc.stdout.decode("utf-8", "replace")
    except Exception:
        return False, []
    if "additionalContext" not in out:
        return False, []
    try:
        msg = json.loads(out).get("additionalContext", "")
    except Exception:
        msg = out
    return True, FIRE_SYM_RE.findall(msg)


def cleanup_spec_sid(sid8):
    for f in glob.glob(f"/tmp/claude-specexport-{sid8}-*"):
        try:
            os.remove(f)
        except OSError:
            pass


def main():
    ap = argparse.ArgumentParser(description="Corpus fire-rate estimate for guard-speculative-export.sh")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--sample", type=int, default=0)
    ap.add_argument("--seed", type=int, default=1337)
    ap.add_argument("--main-only", action="store_true")
    ap.add_argument("--only", action="append", default=[])
    ap.add_argument("--out", default="/tmp/specexport-fires.jsonl")
    ap.add_argument("--projects-dir", default=rl.PROJECTS_DIR)
    args = ap.parse_args()

    if not os.path.isfile(HOOK):
        print(f"ERROR: hook not found: {HOOK}", file=sys.stderr)
        return 2

    transcripts = sorted(Path(args.projects_dir).rglob("*.jsonl"))
    if args.main_only:
        transcripts = [t for t in transcripts if "/subagents/" not in str(t) and "/workflows/" not in str(t)]
    if args.only:
        transcripts = [t for t in transcripts if any(s in t.name for s in args.only)]
    if args.sample and args.sample < len(transcripts):
        random.Random(args.seed).shuffle(transcripts)
        transcripts = transcripts[: args.sample]
    if args.limit:
        transcripts = transcripts[: args.limit]

    print(f"[replay-posttool] hook={os.path.basename(HOOK)} transcripts={len(transcripts)} "
          f"out={args.out}", file=sys.stderr)

    stats = {m: {"edit_fires": 0, "sym_fires": 0, "distinct": set()} for m in ("lenient", "strict")}
    candidates = 0
    idx = 0
    t0 = time.time()
    used_sids = set()

    with open(args.out, "w", encoding="utf-8") as out_fh:
        for n, path in enumerate(transcripts, 1):
            if n % 100 == 0 or n == len(transcripts):
                print(f"[progress] {n}/{len(transcripts)} transcripts  candidates={candidates}  "
                      f"len_sym={stats['lenient']['sym_fires']} str_sym={stats['strict']['sym_fires']}  "
                      f"{time.time()-t0:.0f}s", file=sys.stderr)
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
                    if not fp or not TSJS_RE.search(fp):
                        continue
                    if not EXPORT_DECL_RE.search(payload_text(ti)):
                        continue
                    candidates += 1
                    for mode in ("lenient", "strict"):
                        sid8 = f"{idx:08x}"
                        sid = sid8 + "cafef00dbeef"
                        idx += 1
                        used_sids.add(sid8)
                        fired, names = run_spec_hook(ti, mode, sid)
                        cleanup_spec_sid(sid8)
                        if fired:
                            stats[mode]["edit_fires"] += 1
                            stats[mode]["sym_fires"] += len(names)
                            for nm in names:
                                stats[mode]["distinct"].add((fp, nm))
                            out_fh.write(json.dumps({
                                "transcript": str(path), "file": fp, "mode": mode,
                                "symbols": names,
                            }, ensure_ascii=False) + "\n")

    for sid8 in used_sids:
        cleanup_spec_sid(sid8)

    el = time.time() - t0
    print("\n" + "=" * 62, file=sys.stderr)
    print(f"HOOK          : {os.path.basename(HOOK)}", file=sys.stderr)
    print(f"transcripts   : {len(transcripts)}", file=sys.stderr)
    print(f"export-adds   : {candidates}   (TS/JS Edit/Write adding an exported decl)", file=sys.stderr)
    for mode in ("lenient", "strict"):
        s = stats[mode]
        print(f"[{mode:7}] edit-fires={s['edit_fires']}  symbol-fires={s['sym_fires']}  "
              f"distinct(file,sym)={len(s['distinct'])}", file=sys.stderr)
    print(f"elapsed       : {el:.0f}s", file=sys.stderr)
    print(f"fires JSONL   : {args.out}", file=sys.stderr)
    print("=" * 62, file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
