"""Shared helpers for the core-dump gather and finalize scripts.

Two jobs live here so both scripts read a session the same way: streaming one
session transcript for the owner's own words and the files the agent wrote, and
parsing a checkpoint file into its headings and Resume Contract fields.

Everything is stdlib and streams the transcript line by line. A 1M-token
session file is tens of megabytes, so lines that cannot matter are skipped with
a substring test before any JSON is parsed.

The owner-message filter is a third copy of the one in session-journal.py and
the handoff sweep's pairs.py, with the origin check added. Those two are
scripts with hyphenated names that other tools own, so importing them here
would couple this to files that change independently.
"""
import glob
import json
import os
import re
import sys
from datetime import datetime, timezone

# Opening text of user entries the owner did not type: harness notices, wakes,
# hook injections and compaction summaries.
_NOT_OWNER_PREFIXES = (
    "<task-notification", "<local-command-stdout", "<local-command-caveat",
    "Caveat:", "[keepwarm]", "This session is being continued",
    "<system-reminder", "<user-prompt-submit-hook", "[Request interrupted",
)
_WRITE_TOOLS = ("Write", "Edit", "MultiEdit", "NotebookEdit")
# Tool use that changes the world, for "did the agent keep working after the dump".
_WORK_TOOLS = _WRITE_TOOLS + ("Bash",)
# Commands that run the hand-off itself. They are the owner asking for a dump,
# not the owner talking to the work, so they never count as a new turn.
_HANDOFF_COMMANDS = ("/core-dump", "/catchup", "/clear", "/compact")


def claude_home():
    return os.path.join(os.path.expanduser("~"), ".claude")


def owner_words(e):
    """The owner's own words in a user entry, or None for tool results and injections."""
    if e.get("type") != "user" or e.get("isMeta") or e.get("isSidechain"):
        return None
    origin = e.get("origin")
    if isinstance(origin, dict) and origin.get("kind") not in (None, "human"):
        return None
    c = e.get("message", {}).get("content")
    if isinstance(c, list):
        if any(isinstance(b, dict) and b.get("type") == "tool_result" for b in c):
            return None
        c = " ".join(b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text")
    if not isinstance(c, str) or not c.strip():
        return None
    t = c.strip()
    if t.startswith(_NOT_OWNER_PREFIXES):
        return None
    m = re.search(r"<command-name>(/[^<]+)</command-name>", t)
    if m:
        args = re.search(r"<command-args>(.*?)</command-args>", t, re.S)
        return (m.group(1) + " " + (args.group(1).strip() if args else "")).strip()
    return t


def is_handoff_command(text):
    parts = text.split()
    return bool(parts) and parts[0] in _HANDOFF_COMMANDS


def iso_to_epoch(ts):
    try:
        return datetime.strptime(ts[:19], "%Y-%m-%dT%H:%M:%S").replace(tzinfo=timezone.utc).timestamp()
    except (ValueError, TypeError):
        return None


def session_transcript_path(uuid, cwd):
    """This session's transcript: the cwd-derived path first, then any project dir."""
    if not uuid:
        return None
    proj = os.path.join(claude_home(), "projects")
    fast = os.path.join(proj, re.sub(r"[/.]", "-", cwd or ""), uuid + ".jsonl")
    if os.path.isfile(fast):
        return fast
    hits = glob.glob(os.path.join(proj, "*", uuid + ".jsonl"))
    return hits[0] if hits else None


def scan_transcript(path):
    """Stream a transcript once and return what the dump needs.

    Keys: first_ts and last_ts (epoch), owner (list of (epoch, text)),
    assistant_msgs (distinct API messages), files (written or edited, in
    first-touch order), dumps (checkpoint files the agent wrote), last_model,
    work (epochs of assistant tool use that changes things, leaving out replies
    to a keep-warm wake, which only exist to write the dump).
    """
    out = {"first_ts": None, "last_ts": None, "owner": [], "assistant_msgs": 0,
           "files": [], "dumps": [], "last_model": "", "work": []}
    in_keepwarm = False
    seen_msgs = set()
    seen_files = set()
    ts_re = re.compile(r'"timestamp":\s*"([0-9T:\-]{19})')
    id_re = re.compile(r'"id":\s*"(msg_[A-Za-z0-9_]+)"')
    model_re = re.compile(r'"model":\s*"([^"]+)"')
    with open(path, errors="replace") as fh:
        for line in fh:
            is_user = '"type":"user"' in line or '"type": "user"' in line
            is_asst = '"type":"assistant"' in line or '"type": "assistant"' in line
            if not (is_user or is_asst):
                continue
            m = ts_re.search(line)
            ts = iso_to_epoch(m.group(1)) if m else None
            if ts is not None:
                if out["first_ts"] is None:
                    out["first_ts"] = ts
                out["last_ts"] = ts
            if is_asst:
                mid = id_re.search(line)
                if mid:
                    seen_msgs.add(mid.group(1))
                mm = model_re.search(line)
                if mm and mm.group(1) != "<synthetic>":
                    out["last_model"] = mm.group(1)
                if "tool_use" in line and any(('"name":"%s"' % t in line) or ('"name": "%s"' % t in line)
                                              for t in _WORK_TOOLS):
                    _collect_writes(line, out, seen_files, ts, in_keepwarm)
                continue
            # A tool result carries no owner words; skip it before parsing.
            if '"tool_result"' in line:
                continue
            try:
                e = json.loads(line)
            except ValueError:
                continue
            t = owner_words(e)
            if t is None:
                if _raw_text(e).startswith("[keepwarm]"):
                    in_keepwarm = True
                continue
            in_keepwarm = False
            ets = iso_to_epoch(e["timestamp"]) if e.get("timestamp") else ts
            out["owner"].append((ets, t))
    out["assistant_msgs"] = len(seen_msgs)
    return out


def _raw_text(e):
    """First text of a user entry, whatever the content shape, or ''."""
    c = e.get("message", {}).get("content")
    if isinstance(c, list):
        c = " ".join(b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text")
    return c.strip() if isinstance(c, str) else ""


def _collect_writes(line, out, seen_files, ts=None, in_keepwarm=False):
    try:
        e = json.loads(line)
    except ValueError:
        return
    if e.get("isSidechain"):
        return
    for b in e.get("message", {}).get("content", []) or []:
        if not (isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") in _WORK_TOOLS):
            continue
        if ts is not None and not in_keepwarm:
            out["work"].append(ts)
        if b.get("name") not in _WRITE_TOOLS:
            continue
        inp = b.get("input") or {}
        fp = inp.get("file_path") or inp.get("notebook_path")
        if not fp:
            continue
        if fp not in seen_files:
            seen_files.add(fp)
            out["files"].append(fp)
        base = os.path.basename(fp)
        if b.get("name") == "Write" and base.startswith("_") and base.endswith(".claude.md"):
            out["dumps"].append(fp)


def read_text(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def section(text, heading):
    """Body of an exact `## heading` section, or ''."""
    m = re.search(r"^## " + re.escape(heading) + r"[ \t]*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    return m.group(1) if m else ""


def quick_summary(text):
    m = re.search(r"^# Quick Summary[^\n]*$(.*?)(?=^# |\Z)", text, re.M | re.S)
    return m.group(1) if m else ""


_FIELD_RE = re.compile(r"^[ \t]*-[ \t]+\*\*([^*\n]+?):\*\*", re.M)


def contract_fields(text):
    """Resume Contract fields as {label: (value_text, start, end)}.

    value_text includes continuation lines (indented bullets) up to the next
    field label. start and end are absolute offsets in `text`, so a caller can
    rewrite the value in place.
    """
    m = re.search(r"^## Resume Contract[ \t]*$", text, re.M)
    if not m:
        return {}
    body_start = m.end()
    nxt = re.search(r"^## ", text[body_start:], re.M)
    body_end = body_start + nxt.start() if nxt else len(text)
    body = text[body_start:body_end]
    fields = {}
    labels = list(_FIELD_RE.finditer(body))
    for i, lm in enumerate(labels):
        vstart = body_start + lm.end()
        vend = body_start + (labels[i + 1].start() if i + 1 < len(labels) else len(body))
        label = lm.group(1).strip()
        if label not in fields:
            fields[label] = (text[vstart:vend], vstart, vend)
    return fields


def bullets(body):
    """Top-level list items (bulleted or numbered) of a section body."""
    items = []
    for ln in body.splitlines():
        m = re.match(r"^(?:[-*]|\d+[.)])[ \t]+(.*\S)", ln)
        if m:
            items.append(m.group(1).strip())
    return items


def first_sentence(text, limit=80):
    t = re.sub(r"\s+", " ", text).strip()
    m = re.match(r"(.+?[.!?])(\s|$)", t)
    s = m.group(1) if m else t
    return s if len(s) <= limit else s[:limit - 1].rstrip() + "…"


def norm(s):
    """Whitespace-, case- and quote-style-insensitive form for verbatim matching."""
    s = s.replace("\u2018", "'").replace("\u2019", "'").replace("\u201c", '"').replace("\u201d", '"')
    s = s.replace("\u2013", "-").replace("\u2014", "-")
    return re.sub(r"\s+", " ", s).strip().casefold()


def wordset(s):
    return set(re.findall(r"[a-z]+", s.lower()))


def prev_snapshot(uuid, sid):
    """Where gather keeps a copy of today's dump before the Write overwrites it; finalize reads the same key."""
    safe = re.sub(r"[^A-Za-z0-9._-]", "_", sid or "unknown")
    return os.path.join(claude_home(), "checkpoints", ".prev", "%s-%s.md" % ((uuid or "nouuid")[:8], safe))


# A grant: "<owner words>" (<date ...>) · target: <where> · one-shot|standing
AUTH_SHAPE_RE = re.compile(
    r'^(?P<unv>UNVERIFIED:\s*)?["“](?P<words>[^"”]+)["”]\s*\(\s*\d{4}-\d{2}-\d{2}[^)]*\)'
    r'\s*·\s*target:\s*(?P<target>\S.*?)\s*·\s*(?:one-shot|standing)\b[^"“]*$')
_AUTH_SEP = re.compile(r"\s·\s|\n[ \t]*[-*][ \t]+")


def flat(s):
    return re.sub(r"\s+", " ", s or "").strip()


def auth_entries(value):
    """(start, end) offsets in `value` of each Standing authorizations entry.

    A segment that does not open with a quote or UNVERIFIED: continues the entry
    before it, so `target:` and `one-shot` stay with their grant.
    """
    segs, pos = [], 0
    for m in _AUTH_SEP.finditer(value):
        segs.append((pos, m.start()))
        pos = m.end()
    segs.append((pos, len(value)))
    entries = []
    for s, e in segs:
        raw = value[s:e]
        s2, e2 = s + len(raw) - len(raw.lstrip()), s + len(raw.rstrip())
        if e2 <= s2:
            continue
        if not entries or value[s2:e2].startswith(('"', "“", "UNVERIFIED:")):
            entries.append([s2, e2])
        else:
            entries[-1][1] = e2
    return [tuple(x) for x in entries]


def judge_quote(words, haystack):
    """(ok, reason): are these quoted words substantive and said by the owner in ONE message, in order."""
    pieces = [p for p in (norm(x) for x in re.split(r"\.\.\.|…", words)) if p]
    counts = [len(re.findall(r"\w+", p)) for p in pieces]
    if sum(counts) < 4:
        return False, "too short to verify"
    if len(pieces) > 3 or (len(pieces) > 1 and min(counts) < 3):
        return False, "stitched from fragments"
    for msg in haystack:
        i = 0
        for p in pieces:
            j = msg.find(p, i)
            if j < 0:
                break
            i = j + len(p)
        else:
            return True, ""
    return False, "not said"


def eprint(*a):
    print(*a, file=sys.stderr)
