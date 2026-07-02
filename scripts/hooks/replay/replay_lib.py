#!/usr/bin/env python3
"""
replay_lib.py — shared core for the Stop-hook replay harness.

Holds the turn model (how a transcript is split into turns and how each turn is
reconstructed into the shape a Stop hook receives) plus the hook-invocation and
mute-file-guard primitives. The driver (replay-corpus.py), the fixture seeder
(seed-fixtures.py), and the regression runner (run_fixtures.py) all build on this
so there is one definition of "a turn" across the harness.

Faithfulness contract: this module never re-implements hook logic. It only
prepares inputs (the turn slice, the reconstructed edit-list, the stdin payload)
and pipes them into the REAL hook script, then reads the hook's own stdout.
"""

import json
import os
import re
import secrets
import subprocess
from pathlib import Path

HOME = os.path.expanduser("~")
PROJECTS_DIR = os.path.join(HOME, ".claude", "projects")
SOURCE_EXT_RE = re.compile(
    r"\.(py|ts|tsx|js|jsx|mjs|cjs|go|rs|swift|rb|java|kt|c|cc|cpp|h|hpp|sh)$", re.I
)
EDIT_TOOLS = {"Edit", "Write", "MultiEdit"}
MUTE_RE = re.compile(r"\.no-[a-z-]*gate")


def is_real_user_msg(obj):
    """A turn boundary: a genuine user prompt, not a tool return.

    True for type=="user" whose content is a plain string, or an array that
    carries at least one text item. A pure tool_result array is a mid-turn tool
    return and does NOT start a new turn.
    """
    if obj.get("type") != "user":
        return False
    msg = obj.get("message")
    if not isinstance(msg, dict):
        return False
    content = msg.get("content")
    if isinstance(content, str):
        return content.strip() != ""
    if isinstance(content, list):
        return any(isinstance(it, dict) and it.get("type") == "text" for it in content)
    return False


def load_lines(path):
    """Read a transcript as (raw_line, parsed_obj_or_None) pairs, streaming."""
    out = []
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            if not raw.strip():
                continue
            try:
                obj = json.loads(raw)
            except Exception:
                obj = None
            out.append((raw.rstrip("\n"), obj))
    return out


def split_turns(lines):
    """List of turns; each turn is the (raw_line, obj) span from one real user
    message up to (not including) the next. Preamble before the first real user
    message is dropped."""
    boundaries = [
        i for i, (_, obj) in enumerate(lines) if obj is not None and is_real_user_msg(obj)
    ]
    turns = []
    for n, start in enumerate(boundaries):
        end = boundaries[n + 1] if n + 1 < len(boundaries) else len(lines)
        turns.append(lines[start:end])
    return turns


def turn_edit_paths(turn):
    """File paths this turn's Edit/Write/MultiEdit tool_use calls touched (deduped,
    order-preserved)."""
    paths = []
    for _, obj in turn:
        if obj is None or obj.get("type") != "assistant":
            continue
        content = (obj.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        for it in content:
            if isinstance(it, dict) and it.get("type") == "tool_use" and it.get("name") in EDIT_TOOLS:
                fp = (it.get("input") or {}).get("file_path")
                if fp:
                    paths.append(fp)
    return list(dict.fromkeys(paths))


def has_source_edit(paths):
    """True if any edited path is a source/test file (the Gate0 condition). Each
    path is matched independently — the hook's rg check is per-line."""
    return any(SOURCE_EXT_RE.search(p) for p in paths)


def turn_final_text(turn):
    """The last assistant message's joined text — what the hook keys its claim on."""
    last = None
    for _, obj in turn:
        if obj is not None and obj.get("type") == "assistant":
            content = (obj.get("message") or {}).get("content")
            if isinstance(content, list) and any(
                isinstance(it, dict) and it.get("type") == "text" for it in content
            ):
                last = content
    if last is None:
        return ""
    return "\n".join(
        it.get("text", "") for it in last if isinstance(it, dict) and it.get("type") == "text"
    ).strip()


def turn_cwd(turn, default_cwd):
    """Faithful stakes resolution: use the cwd the transcript recorded for this
    turn (present on most lines), falling back to the configured default."""
    for _, obj in reversed(turn):
        if obj is not None:
            c = obj.get("cwd")
            if isinstance(c, str) and c:
                return c
    return default_cwd


def new_sid(idx):
    """A unique synthetic session_id whose first 8 chars are a zero-padded index,
    so the /tmp mark/edit files keyed on sid[0:8] never collide across turns."""
    sid8 = f"{idx:08x}"
    return sid8, sid8 + secrets.token_hex(12)


def write_edit_list(sid8, paths):
    """Reconstruct the session edit-list the Stop hook reads. Returns the path if
    written (paths non-empty), else None."""
    if not paths:
        return None
    f = f"/tmp/claude-edited-files-{sid8}"
    with open(f, "w", encoding="utf-8") as fh:
        fh.write("\n".join(paths) + "\n")
    return f


def cleanup_sid(sid8):
    """Remove every /tmp mark/edit file keyed by a sid8 the harness created."""
    for f in (f"/tmp/claude-edited-files-{sid8}",
              f"/tmp/claude-declared-ready-{sid8}",
              f"/tmp/claude-structural-claim-{sid8}"):
        try:
            os.remove(f)
        except OSError:
            pass


def classify_outcome(stdout):
    """Map the hook's stdout to BLOCK / SOFT / SILENT."""
    s = (stdout or "").strip()
    if not s:
        return "SILENT"
    try:
        obj = json.loads(s)
    except Exception:
        return "SILENT"
    if isinstance(obj, dict):
        if obj.get("decision") == "block":
            return "BLOCK"
        if "systemMessage" in obj:
            return "SOFT"
    return "SILENT"


def run_hook(hook_path, payload, timeout=45):
    """Pipe a Stop stdin payload into the real hook; return (stdout, rc, err)."""
    try:
        proc = subprocess.run(
            ["bash", hook_path],
            input=payload.encode("utf-8"),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
        )
        return proc.stdout.decode("utf-8", "replace"), proc.returncode, None
    except subprocess.TimeoutExpired:
        return "", -1, "timeout"
    except Exception as e:  # noqa: BLE001
        return "", -1, str(e)


def run_turn(hook_path, turn, idx, default_cwd, run_dir):
    """Reconstruct one turn into a Stop invocation and run the hook against it.

    Materializes the turn slice, rebuilds the edit-list, synthesizes a unique
    payload, invokes the hook, and returns a dict describing the outcome. This is
    the single faithful unit of replay reused by the driver, the seeder, and the
    fixture runner. Caller owns /tmp cleanup via cleanup_sid(sid8)."""
    sid8, sid = new_sid(idx)
    slice_path = os.path.join(run_dir, f"slice-{sid8}.jsonl")
    with open(slice_path, "w", encoding="utf-8") as sfh:
        sfh.write("\n".join(raw for raw, _ in turn) + "\n")
    paths = turn_edit_paths(turn)
    write_edit_list(sid8, paths)
    cwd = turn_cwd(turn, default_cwd)
    payload = json.dumps({"session_id": sid, "transcript_path": slice_path, "cwd": cwd})
    stdout, rc, err = run_hook(hook_path, payload)
    return {
        "sid8": sid8,
        "slice_path": slice_path,
        "outcome": classify_outcome(stdout),
        "exit": rc,
        "err": err,
        "cwd": cwd,
        "edit_paths": paths,
        "edited_source": has_source_edit(paths),
        "final_text": turn_final_text(turn),
        "stdout": stdout,
    }


def run_slice(hook_path, slice_path, idx, cwd, run_dir=None):
    """Run the hook against an already-materialized turn slice file (a fixture).

    Rebuilds the edit-list from the slice's own Edit/Write tool_use so Gate0
    resolves exactly as it did during capture, uses a fresh unique sid so the
    loop-safe mark file never pre-exists, and returns the classified outcome."""
    lines = load_lines(slice_path)
    turn = lines
    sid8, sid = new_sid(idx)
    write_edit_list(sid8, turn_edit_paths(turn))
    payload = json.dumps({"session_id": sid, "transcript_path": slice_path, "cwd": cwd})
    stdout, rc, err = run_hook(hook_path, payload)
    cleanup_sid(sid8)
    return classify_outcome(stdout), rc, err, stdout


def check_mute_files(hook_path):
    """A muted hook silently exits 0 and the replay lies. Return (honored_tokens,
    present_files) so callers can warn loudly before trusting a run."""
    text = Path(hook_path).read_text(encoding="utf-8", errors="replace")
    tokens = sorted(set(MUTE_RE.findall(text)))
    present = [os.path.join(HOME, ".claude", t) for t in tokens
               if os.path.isfile(os.path.join(HOME, ".claude", t))]
    return tokens, present
