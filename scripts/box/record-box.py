#!/usr/bin/env python3
"""Draws the box for something just recorded for the owner: an atone, an affirm,
a proposal or an i-dream pin.

The agent used to compose these by hand, so each one came out different and the
atone box rarely showed the defense or the juror's ruling. This reads the stored
record and draws the same box every time, with the command that shows the full
record printed bare under it.

Usage: record-box.py <id>
  mist-…  atone event (joined to its juror judgment)
  judg-…  a juror judgment with no event: the juror cleared the agent
  aff-…   affirm      prop-…  proposal      pin-…  i-dream pin
Exit 1 when the id is unknown or not found.
"""
import json
import os
import re
import subprocess
import sys

HOME = os.path.expanduser("~/.claude")
BOX = os.path.join(os.path.dirname(os.path.realpath(__file__)), "box.sh")
ROOT = os.environ.get("RECORD_BOX_ROOT", HOME)


def records(path):
    try:
        with open(path, errors="replace") as f:
            for line in f:
                try:
                    yield json.loads(line)
                except ValueError:
                    continue
    except OSError:
        return


def find(path, rid, key="id"):
    hit = None
    for r in records(path):
        if r.get(key) == rid:
            hit = r
    return hit


def count(path, slug):
    return sum(1 for r in records(path) if r.get("slug") == slug)


def gist(text, cap=120):
    """The first sentence of a stored paragraph, cut on a word if still long."""
    t = " ".join((text or "").split())
    m = re.search(r"(?<=[.!?])\s", t)
    if m:
        t = t[:m.start()]
    if len(t) > cap:
        t = t[:cap].rsplit(" ", 1)[0].rstrip(",;:") + " …"
    return t


def draw(kind, name, rows, attr="", count_n=0, copies=()):
    cmd = ["bash", BOX, kind, name]
    if attr:
        cmd += ["--attr", attr]
    if count_n > 1:
        cmd += ["--count", str(count_n)]
    for role, text in rows:
        if text:
            cmd += ["--row", role, text]
    for c in copies:
        if c:
            cmd += ["--copy", c]
    out = subprocess.run(cmd, capture_output=True, text=True)
    sys.stdout.write(out.stdout)
    sys.stderr.write(out.stderr)
    return out.returncode


def atone(rid):
    ev = find(os.path.join(ROOT, "atone/events.jsonl"), rid)
    if not ev:
        return None
    j = find(os.path.join(ROOT, "atone/judgments.jsonl"), ev.get("judgment_id")) or {}
    verdict = ev.get("juror_verdict") or j.get("verdict") or ""
    juror = ", ".join(x for x in (verdict, j.get("confidence")) if x)
    if j.get("reasoning"):
        juror += ": " + gist(j["reasoning"], 80)
    rows = [
        ("blocked:slip", gist(ev.get("title") or ev.get("issue"))),
        ("info:defense", gist(j.get("agent_defense"))),
        ("juror", juror),
        ("next:fix", gist(j.get("should_have_done") or ev.get("what_not_to_do"))),
    ]
    rca = os.path.join(ROOT, "atone/rca", "%s.md" % ev.get("rca_id")) if ev.get("rca_id") else ""
    attr = " · ".join(x for x in (ev.get("severity"), verdict) if x)
    n = count(os.path.join(ROOT, "atone/events.jsonl"), ev.get("slug"))
    return draw("atone", ev.get("slug", rid), rows, attr, n,
                ["bash ~/.claude/scripts/atone.sh show %s" % rid, rca if rca and os.path.exists(rca) else ""])


def cleared(rid):
    j = find(os.path.join(ROOT, "atone/judgments.jsonl"), rid)
    if not j:
        return None
    slugs = j.get("related_atone_slugs") or [rid]
    juror = ", ".join(x for x in (j.get("verdict"), j.get("confidence")) if x)
    if j.get("reasoning"):
        juror += ": " + gist(j["reasoning"], 80)
    rows = [
        ("note:callout", '"%s"' % gist(j.get("user_callout"), 120)),
        ("info:defense", gist(j.get("agent_defense"))),
        ("juror", juror),
        ("you", "say overrule, with why, and the event is recorded anyway"),
    ]
    return draw("atone", slugs[0], rows, "juror cleared you", 0, [j.get("verdict_path", "")])


def affirm(rid):
    a = find(os.path.join(ROOT, "affirm/events.jsonl"), rid)
    if not a:
        return None
    rows = [
        ("done:call", gist(a.get("title") or a.get("behavior"))),
        ("info:why", gist(a.get("why_good"))),
        ("next:use", gist(a.get("instruction"))),
    ]
    n = count(os.path.join(ROOT, "affirm/events.jsonl"), a.get("slug"))
    return draw("affirm", a.get("slug", rid), rows, "", n,
                ["bash ~/.claude/scripts/affirm.sh show %s" % rid])


def proposal(rid):
    p = find(os.path.join(ROOT, "proposals.jsonl"), rid)
    if not p:
        return None
    links = [t.split(":", 2)[-1] for t in p.get("tags", []) if t.startswith("link:")]
    rows = [
        ("next:what", gist(p.get("title") or p.get("body"))),
        ("ref:links", " · ".join(links)),
    ]
    attr = " · ".join(x for x in (p.get("category"), p.get("effort")) if x)
    return draw("proposal", rid, rows, attr, 0,
                ["bash ~/.claude/scripts/propose.sh show %s" % rid])


def pin(rid):
    p = find(os.path.join(ROOT, "pinned/events.jsonl"), rid)
    if not p:
        return None
    files = [os.path.basename(f.get("path", "")) for f in (p.get("context") or {}).get("files", [])]
    rows = [
        ("info:insight", gist(p.get("text"))),
        ("ref:files", " · ".join(f for f in files if f)),
    ]
    return draw("pin", rid, rows, p.get("framing") or "", 0,
                ["i-dream pin show %s" % rid])


def main():
    if len(sys.argv) != 2:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    rid = sys.argv[1]
    for prefix, fn in (("mist-", atone), ("judg-", cleared), ("aff-", affirm),
                       ("prop-", proposal), ("pin-", pin)):
        if rid.startswith(prefix):
            rc = fn(rid)
            if rc is None:
                print("record-box: %s not found" % rid, file=sys.stderr)
                return 1
            return rc
    print("record-box: unknown id shape: %s (want mist-, judg-, aff-, prop- or pin-)" % rid, file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
