#!/usr/bin/env python3
"""Triage a sub-agent fleet after an API outage — what survived, what to re-run.

After a transient 429 kills part of a parallel Agent fleet, the dispatching
parent needs to know which agents finished, which died, and — crucially —
which DIED but already wrote a usable output file (so they need NOT be re-run).
This reads the parent session's subagents/ directory and classifies each agent.

Usage:
  fleet-triage.py <parent-transcript.jsonl | parent-session-uuid | subagents-dir>
  fleet-triage.py --latest [project-substr]   # newest parent session w/ subagents

Output (human table + a JSON block the parent can act on):
  DONE        finished cleanly (last turn is a real assistant reply with text)
  SALVAGED    died BUT wrote an ABSOLUTE output path that exists on disk → reuse
  REDISPATCH  died with no usable artifact → re-run this one
  EMPTY       zero-row / corrupt transcript → re-run (folded into redispatch)

"died" = the transcript does NOT end in a finished assistant reply: a synthetic
API-error turn, a dangling tool_result (died mid-tool), or a bare tool_use. The
action JSON lists `redispatch` (REDISPATCH + EMPTY) and `salvaged` (agent ->
absolute reuse paths). Relative output paths can't be verified from here (they'd
resolve against this tool's CWD, not the agent's) and are surfaced as
unverifiable rather than trusted.
"""
import json, os, sys, glob

ROOT = os.path.expanduser("~/.claude/projects")

def load(f):
    out = []
    for line in open(f, errors="replace"):
        line = line.strip()
        if not line:
            continue
        try:
            out.append(json.loads(line))
        except Exception:
            pass
    return out

def find_subagents_dir(arg):
    # explicit dir
    if os.path.isdir(arg) and arg.rstrip("/").endswith("subagents"):
        return arg
    # parent transcript path -> sibling <uuid>/subagents
    if os.path.isfile(arg) and arg.endswith(".jsonl"):
        base = arg[:-len(".jsonl")]
        d = os.path.join(base, "subagents")
        if os.path.isdir(d):
            return d
    # bare uuid -> search (recursive ** already spans the session-uuid level)
    for d in glob.glob(os.path.join(ROOT, "**", "subagents"), recursive=True):
        if arg in d:
            return d
    return None

def latest_subagents_dir(substr=""):
    dirs = glob.glob(os.path.join(ROOT, "**", "subagents"), recursive=True)
    dirs = [d for d in dirs if substr in d]
    if not dirs:
        return None
    return max(dirs, key=lambda d: os.path.getmtime(d))

def _meaningful(o):
    # a real conversation turn, not a system/snapshot/meta record
    return o.get("type") in ("assistant", "user") and not o.get("isMeta")

def classify(agent_file):
    rows = load(agent_file)
    if not rows:
        return {"status": "EMPTY", "outputs": [], "existing": [], "rel": [], "died": True}

    # An agent COMPLETED only if its last real turn is a finished assistant reply
    # (real model + a text block = the return value). Anything else means it
    # stopped mid-flight — a synthetic error turn, a dangling tool_result with no
    # summarizing reply (died mid-tool, no error line written), or a tool_use with
    # no result. We classify all of those as died and bias toward re-dispatch:
    # re-running a borderline agent is cheap; silently dropping a dead one is not.
    last = next((o for o in reversed(rows) if _meaningful(o)), None)
    completed = False
    if last is not None and last.get("type") == "assistant":
        m = last.get("message") or {}
        if m.get("model") not in (None, "<synthetic>"):
            c = m.get("content")
            completed = isinstance(c, list) and any(
                isinstance(x, dict) and x.get("type") == "text" for x in c)
    died = not completed

    # Files the agent wrote (Write/Edit/NotebookEdit) + any "WROTE: <path>" lines.
    outputs = []
    for o in rows:
        c = (o.get("message") or {}).get("content")
        if not isinstance(c, list):
            continue
        for x in c:
            if not isinstance(x, dict):
                continue
            if x.get("type") == "tool_use" and x.get("name") in ("Write", "Edit", "NotebookEdit"):
                fp = (x.get("input") or {}).get("file_path")
                if fp:
                    outputs.append(fp)
            elif x.get("type") == "text":
                for ln in x.get("text", "").splitlines():
                    ln = ln.strip()
                    if ln.startswith("WROTE:"):
                        p = ln[len("WROTE:"):].strip().split()[0]
                        if p:
                            outputs.append(p)
    outputs = sorted(set(outputs))

    # Salvage is only trustworthy for ABSOLUTE paths — a relative path in a
    # transcript would be resolved against THIS tool's CWD, not the agent's, so
    # existence there is meaningless. (sub-agent-outputs.md mandates absolute
    # paths; we surface any relative ones as unverifiable rather than guessing.)
    abs_outputs = [p for p in outputs if os.path.isabs(os.path.expanduser(p))]
    rel = [p for p in outputs if not os.path.isabs(os.path.expanduser(p))]
    existing = [p for p in abs_outputs if os.path.exists(os.path.expanduser(p))]

    if not died:
        status = "DONE"
    elif existing:
        status = "SALVAGED"
    else:
        status = "REDISPATCH"
    return {"status": status, "outputs": outputs, "existing": existing,
            "rel": rel, "died": died}

def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__); sys.exit(2)
    if args[0] == "--latest":
        d = latest_subagents_dir(args[1] if len(args) > 1 else "")
    else:
        d = find_subagents_dir(args[0])
    if not d:
        print("No subagents/ directory found for:", args[0]); sys.exit(1)

    files = sorted(glob.glob(os.path.join(d, "agent-*.jsonl")))
    results = []
    for f in files:
        r = classify(f)
        r["agent"] = os.path.basename(f)
        results.append(r)

    counts = {}
    for r in results:
        counts[r["status"]] = counts.get(r["status"], 0) + 1

    # Header: show the dir relative to the projects root, but fall back to the
    # absolute path for a dir passed from outside the tree (relpath would emit a
    # nonsense ../../.. string otherwise).
    header = d
    if os.path.abspath(d).startswith(os.path.abspath(ROOT) + os.sep):
        header = os.path.relpath(d, ROOT)
    print(f"# Fleet triage — {header}")
    print(f"# {len(results)} agents | " +
          " ".join(f"{k}={v}" for k, v in sorted(counts.items())))
    print()
    for r in results:
        out = ""
        if r["status"] == "SALVAGED":
            # absolute paths — what the parent actually needs to open
            out = "  reuse: " + ", ".join(os.path.expanduser(p) for p in r["existing"])
        elif r["status"] == "REDISPATCH" and r["outputs"]:
            out = "  (wrote, not found on disk: " + ", ".join(r["outputs"]) + ")"
        if r.get("rel"):
            out += "  [unverifiable relative paths: " + ", ".join(r["rel"]) + "]"
        print(f"  {r['status']:11s} {r['agent']}{out}")

    # EMPTY (zero-row / corrupt agent file) is lost work too — re-dispatch it.
    redispatch = [r["agent"] for r in results if r["status"] in ("REDISPATCH", "EMPTY")]
    salvaged = {r["agent"]: [os.path.expanduser(p) for p in r["existing"]]
                for r in results if r["status"] == "SALVAGED"}
    print("\n--- ACTION (machine-readable) ---")
    print(json.dumps({"redispatch": redispatch, "salvaged": salvaged,
                      "counts": counts}, indent=1))

if __name__ == "__main__":
    main()
