#!/usr/bin/env python3
"""Decides whether a new backlog filing is a new need or more evidence for an open one.

The backlog used to fill with the same need in different words: a weekly lm
self-audit refiled seven times in two days, a monthly ledger alert refiled every
month, and auto-stubs nobody fleshed out. propose.sh asks this script before it
files anything.

  propose_intake.py key   STORE TITLE TAGS     -> "<key>\t<open id or ->\t<hold|file>"
  propose_intake.py hold  EVIDENCE KEY TITLE SESSION
                                               -> "<count>\t<sightings, one per line>"
  propose_intake.py mark  EVIDENCE KEY ID      the held sightings became proposal ID
TAGS is the tag string propose.sh received, split on any whitespace.
"""
import hashlib
import json
import re
import sys
import time

# Restatements of an atone slug with no concrete change in them wait for this many
# sightings before a proposal exists. hook-feedback is not held: its producer files
# each finding once and never sends a second sighting.
HOLD_TAGS = ("src:auto-stub",)
HOLD_AT = 3


def norm_title(title):
    """The words of a title, without the parts that change between refiles of one need.

    Run counts ("× 14"), dates, "last 7d" windows, proposal ids and hex ids that
    contain a digit are dropped; other numbers stay, because "port 5106" and
    "port 5107" are different needs.
    """
    t = title.lower()
    t = re.sub(r"\bprop-[\w-]+", " ", t)
    t = re.sub(r"\b(?=[0-9a-f]*\d)[0-9a-f]{6,}\b", " ", t)
    t = re.sub(r"\d{4}-\d{2}(-\d{2})?", " ", t)
    t = re.sub(r"[×x]\s*\d+\b", " ", t)
    t = re.sub(r"\blast\s+\d+\s*[dhw]\b", " ", t)
    t = re.sub(r"[^\w]+", " ", t)
    words = " ".join(t.split())
    # A title with nothing left (punctuation only) must never merge with another.
    return words or "raw-" + hashlib.sha1(title.encode()).hexdigest()[:12]


def tag_value(tags, prefix):
    return next((t[len(prefix):] for t in tags if t.startswith(prefix)), None)


def key_for(title, tags):
    tags = tags.split() if isinstance(tags, str) else list(tags or [])
    if "src:idream-reader" in tags:
        cluster = tag_value(tags, "idream-cluster:")
        if cluster:
            return f"idream:{cluster}"
    if any(t in tags for t in HOLD_TAGS):
        slug = tag_value(tags, "link:atone:")
        if slug:
            return f"atone:{slug}"
    return "title:" + norm_title(title)


def open_match(store, key):
    last = {}
    with open(store) as f:
        for line in f:
            try:
                r = json.loads(line)
            except ValueError:
                continue
            if isinstance(r, dict) and r.get("id"):
                last[r["id"]] = r
    slug = key[len("atone:"):] if key.startswith("atone:") else None
    for r in last.values():
        if r.get("status") != "open":
            continue
        tags = r.get("tags") or []
        if (r.get("key") or key_for(r.get("title", ""), tags)) == key:
            return r["id"]
        # An open proposal of any kind about the same atone slug already covers a stub.
        if slug and f"link:atone:{slug}" in tags:
            return r["id"]
    return None


def cmd_key(store, title, tags):
    key = key_for(title, tags)
    hold = "hold" if any(t in tags.split() for t in HOLD_TAGS) else "file"
    try:
        match = open_match(store, key)
    except OSError:
        match = None
    print(f"{key}\t{match or '-'}\t{hold}")


def cmd_hold(evidence, key, title, session):
    with open(evidence, "a") as f:
        f.write(json.dumps({"ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "key": key,
                            "title": title, "session": session}) + "\n")
    seen = []
    with open(evidence) as f:
        for line in f:
            try:
                r = json.loads(line)
            except ValueError:
                continue
            if not isinstance(r, dict) or r.get("key") != key:
                continue
            if r.get("filed"):
                seen = []  # sightings already turned into a proposal do not count again
            else:
                seen.append(r)
    print(f"{len(seen)}\t" + "\n".join(f"- {r.get('ts')} session {r.get('session') or '?'}: {r.get('title')}" for r in seen))


def cmd_mark(evidence, key, pid):
    with open(evidence, "a") as f:
        f.write(json.dumps({"ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "key": key, "filed": pid}) + "\n")


if __name__ == "__main__":
    a = sys.argv[1:]
    if a[:1] == ["key"] and len(a) == 4:
        cmd_key(*a[1:])
    elif a[:1] == ["hold"] and len(a) == 5:
        cmd_hold(*a[1:])
    elif a[:1] == ["mark"] and len(a) == 4:
        cmd_mark(*a[1:])
    else:
        sys.exit(__doc__)
