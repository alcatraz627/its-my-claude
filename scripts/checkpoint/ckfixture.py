#!/usr/bin/env python3
"""Builds a fake session transcript for the gather and finalize tests.

Usage: ckfixture.py SPEC.json OUT.jsonl
SPEC is a JSON list of events, each one of:
  {"role": "owner", "text": "...", "ts": "2026-10-13T08:00:00Z"}
  {"role": "owner", "text": "...", "ts": "...", "origin": "task-notification"}
  {"role": "owner", "text": "...", "ts": "...", "meta": true}
  {"role": "tool_result", "ts": "...", "bytes": 0}
  {"role": "assistant", "ts": "...", "id": "msg_1", "text": "...", "writes": ["/a"], "edits": ["/b"]}
  {"role": "filler", "bytes": 100000}     (a bookkeeping line the scanner should skip fast)
Lines are written in the harness's compact JSON shape.
"""
import json
import sys


def entry(ev, n):
    ts = ev.get("ts", "2026-10-13T08:00:00Z")
    base = {"parentUuid": None, "isSidechain": False, "timestamp": ts, "sessionId": "fixture"}
    role = ev["role"]
    if role == "owner":
        e = dict(base, type="user", message={"role": "user", "content": ev["text"]})
        if ev.get("meta"):
            e["isMeta"] = True
        e["origin"] = {"kind": ev.get("origin", "human")}
        return e
    if role == "tool_result":
        pad = "x" * ev.get("bytes", 0)
        return dict(base, type="user", message={"role": "user", "content": [
            {"type": "tool_result", "tool_use_id": "toolu_%d" % n, "content": "ok " + pad}]})
    if role == "assistant":
        blocks = []
        if ev.get("text"):
            blocks.append({"type": "text", "text": ev["text"]})
        for p in ev.get("writes", []):
            blocks.append({"type": "tool_use", "id": "toolu_w%d" % n, "name": "Write",
                           "input": {"file_path": p, "content": "x"}})
        for p in ev.get("edits", []):
            blocks.append({"type": "tool_use", "id": "toolu_e%d" % n, "name": "Edit",
                           "input": {"file_path": p, "old_string": "a", "new_string": "b"}})
        for s in ev.get("task_subjects", []):
            blocks.append({"type": "tool_use", "id": "toolu_t%d" % n, "name": "TaskCreate",
                           "input": {"subject": s}})
        return dict(base, type="assistant", message={
            "model": ev.get("model", "claude-opus-5-5"), "id": ev.get("id", "msg_%d" % n),
            "role": "assistant", "content": blocks})
    if role == "filler":
        return {"type": "attachment", "timestamp": ts, "attachment": {"blob": "z" * ev.get("bytes", 0)}}
    raise SystemExit("unknown role %r" % role)


def main():
    spec = json.load(open(sys.argv[1]))
    with open(sys.argv[2], "w") as out:
        for n, ev in enumerate(spec):
            out.write(json.dumps(entry(ev, n), separators=(",", ":")) + "\n")


if __name__ == "__main__":
    main()
