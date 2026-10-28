#!/usr/bin/env python3
"""Refuses to end a turn that recorded something for the owner without showing it.

An atone, affirm, pin or proposal created this turn prints its record into the
tool output, which the owner never sees: an "atone recorded" box went unseen on
2026-10-23. The owner asked (2026-10-24) that the reply show the standard box with
the details every time, and that skipping it block the turn.

Stop hook. A turn whose Bash calls created one of these (the command ran
atone.sh/affirm.sh/propose.sh add or i-dream pin add, and its output carries the
new id) must end on a reply that shows a box (a ┌ line) and names each new id.
Blocks once per distinct reply, then becomes a note so a session never wedges.
Telemetry: ~/.claude/logs/creation-box-gate.jsonl. Mute: touch ~/.claude/.no-creation-box-gate
Replay over real transcripts: creation-box-stop.py --replay <dir> [--days N]
"""
import glob
import hashlib
import json
import os
import re
import sys
import time

MUTE = os.path.expanduser("~/.claude/.no-creation-box-gate")
STATE = os.environ.get("CREATION_BOX_STATE", "/tmp")
# The log feeds two weekly reviews, so it lives where a reboot does not clear it.
LOG = os.path.join(os.environ.get("CREATION_BOX_STATE") or os.path.expanduser("~/.claude/logs"),
                   "creation-box-gate.jsonl")

# command shape -> the id its output carries, and the box kind to show it in
CREATORS = [
    (re.compile(r"\batone\.sh\s+add\b"), re.compile(r"\bmist-\d{8}-\d{6}-[0-9a-z]+"), "atone"),
    (re.compile(r"\baffirm\.sh\s+add\b"), re.compile(r"\baff-\d{8}-\d{6}-[0-9a-z]+"), "affirm"),
    (re.compile(r"\bpropose\.sh\s+add\b"), re.compile(r"\bprop-\d{8}-\d{6}-[0-9a-z]+"), "proposal"),
    (re.compile(r"\bi-dream\s+pin\s+add\b"), re.compile(r"\bpin-\d{14}-[0-9a-z]+"), "pin"),
]
BOX = re.compile(r"^\s*┌", re.M)


def turns(tp):
    """Yield (tool_pairs, final_reply) per user turn: tool_pairs is [(command, output)]."""
    pending, pairs, reply = {}, [], ""
    with open(tp, errors="replace") as f:
        for line in f:
            try:
                d = json.loads(line)
            except ValueError:
                continue
            msg = d.get("message") or {}
            parts = msg.get("content")
            if d.get("type") == "user":
                if isinstance(parts, str) or (isinstance(parts, list) and any(
                        isinstance(p, dict) and p.get("type") == "text" for p in parts)):
                    if pairs or reply:
                        yield pairs, reply
                    pending, pairs, reply = {}, [], ""
                    continue
                for p in parts or []:
                    if isinstance(p, dict) and p.get("type") == "tool_result" and p.get("tool_use_id") in pending:
                        c = p.get("content")
                        text = c if isinstance(c, str) else " ".join(
                            x.get("text", "") for x in (c or []) if isinstance(x, dict))
                        pairs.append((pending.pop(p["tool_use_id"]), text))
            elif d.get("type") == "assistant":
                for p in parts or []:
                    if not isinstance(p, dict):
                        continue
                    if p.get("type") == "tool_use" and p.get("name") == "Bash":
                        pending[p.get("id")] = (p.get("input") or {}).get("command", "")
                    elif p.get("type") == "text" and p.get("text", "").strip():
                        reply = p["text"]
    if pairs or reply:
        yield pairs, reply


def created(pairs):
    out = []
    for cmd, text in pairs:
        for verb, idre, kind in CREATORS:
            if verb.search(cmd):
                out += [(kind, i) for i in dict.fromkeys(idre.findall(text))]
    return out


def missing(made, reply):
    if not made:
        return []
    has_box = bool(BOX.search(reply))
    return [(k, i) for k, i in made if not (has_box and i in reply)]


def replay(root, days):
    cut = time.time() - days * 86400
    stats = {"transcripts": 0, "turns_with_creations": 0, "would_block": 0, "examples": []}
    for tp in glob.glob(os.path.join(root, "**", "*.jsonl"), recursive=True):
        if os.path.getmtime(tp) < cut:
            continue
        stats["transcripts"] += 1
        try:
            for pairs, reply in turns(tp):
                made = created(pairs)
                if not made:
                    continue
                stats["turns_with_creations"] += 1
                miss = missing(made, reply)
                if miss:
                    stats["would_block"] += 1
                    if len(stats["examples"]) < 8:
                        stats["examples"].append({"file": tp, "missing": miss, "reply_head": reply[:160]})
        except OSError:
            continue
    print(json.dumps(stats, indent=1, ensure_ascii=False))


def log(row):
    try:
        with open(LOG, "a") as f:
            f.write(json.dumps(row) + "\n")
    except OSError:
        pass


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "--replay":
        days = int(sys.argv[sys.argv.index("--days") + 1]) if "--days" in sys.argv else 30
        return replay(sys.argv[2], days)
    if os.path.exists(MUTE) or os.environ.get("CREATION_BOX_GATE_OFF") == "1":
        return
    try:
        inp = json.load(sys.stdin)
        tp = inp.get("transcript_path")
        last = None
        for last in turns(tp) if tp and os.path.exists(tp) else []:
            pass
    except (ValueError, OSError):
        return
    if not last:
        return
    pairs, reply = last
    miss = missing(created(pairs), reply)
    if not miss:
        return
    sid = str(inp.get("session_id"))[:8]
    sig = hashlib.sha1(reply.encode()).hexdigest()[:16]
    mark = os.path.join(STATE, f"creation-box-{sid}-{sig}")
    names = ", ".join(f"{k} {i}" for k, i in miss)
    if os.path.exists(mark):
        log({"ts": time.time(), "session": sid, "action": "note", "missing": miss})
        print(json.dumps({"systemMessage": f"Creation-box gate: the reply still does not show {names} in a box."}))
        return
    try:
        open(mark, "w").close()
    except OSError:
        pass
    log({"ts": time.time(), "session": sid, "action": "block", "missing": miss})
    # record-box.py draws every one of these kinds from the stored record, so
    # the fix is one command per id; the reason stays one line because the
    # harness clips a block reason.
    cmds = " ; ".join(f"python3 ~/.claude/scripts/box/record-box.py {i}" for _, i in miss)
    print(json.dumps({"decision": "block", "reason": (
        f"This turn recorded {names}, but the reply does not show it (the owner never sees tool output). "
        f"Run {cmds}, then paste each box and the line under it into the reply.")},
        ensure_ascii=False))


if __name__ == "__main__":
    main()
