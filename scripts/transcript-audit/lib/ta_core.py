#!/usr/bin/env python3
"""ta_core — the engine behind `ta query` and `ta mine`.

Answers one question fast and correctly: which turns, across the Claude
transcript corpus, match a set of content filters? It leans on two things it
does NOT re-implement:

  - the turn model (what a turn IS, and how to pull the user text, assistant
    text, tools, session id, and timestamp out of one) lives in replay_lib;
  - the "which transcripts exist, filtered by project and recency" layer lives
    in checkpoint/list-transcripts.sh.

This module adds only the middle: a ripgrep pre-filter that narrows 100+ files
to the handful that could possibly match, then a precise per-turn check on those
few. It streams one transcript at a time — it never loads the whole corpus into
memory.
"""

import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone

HOME = os.path.expanduser("~")
HERE = os.path.dirname(os.path.abspath(__file__))

# replay_lib owns the turn model. Import it rather than re-deriving "a turn".
REPLAY_DIR = os.path.join(HOME, ".claude", "scripts", "hooks", "replay")
if REPLAY_DIR not in sys.path:
    sys.path.insert(0, REPLAY_DIR)
import replay_lib as R  # noqa: E402

PROJECTS_DIR = os.path.join(HOME, ".claude", "projects")
LIST_TRANSCRIPTS = os.path.join(
    HOME, ".claude", "scripts", "checkpoint", "list-transcripts.sh"
)


# project-dir name coding (Claude Code's scheme)

def decode_project(encoded):
    """Best-effort human path for an encoded project-dir name. '/' and '.' both
    became '-', so this is lossy (a real hyphen in a folder reads as '/'); use
    it for display only, never for matching."""
    if encoded.startswith("-"):
        return "/" + encoded[1:].replace("--", "/.").replace("-", "/")
    return encoded.replace("--", "/.").replace("-", "/")


# discovery (delegated to list-transcripts.sh)

def _run_list_transcripts(within_days):
    """Ask the canonical discovery script for every transcript within N days,
    as parsed JSON rows. Returns [] if the script is unavailable."""
    try:
        p = subprocess.run(
            ["bash", LIST_TRANSCRIPTS, "--within", str(within_days), "--limit", "100000"],
            capture_output=True, text=True, timeout=60,
        )
    except Exception:
        return []
    rows = []
    for ln in p.stdout.splitlines():
        ln = ln.strip()
        if not ln:
            continue
        try:
            rows.append(json.loads(ln))
        except Exception:
            continue
    return rows


def _days_since(iso):
    try:
        dt = datetime.fromisoformat(iso.replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return max(0, int((datetime.now(timezone.utc) - dt).total_seconds() // 86400))
    except Exception:
        return 100000


def _subagent_transcripts(primary_row):
    """Sub-agent transcripts for one primary session, at
    <project>/<uuid>/subagents/*.jsonl. Empty when the session ran no agents."""
    tx = primary_row["transcript"]
    stem = os.path.splitext(os.path.basename(tx))[0]
    sub_dir = os.path.join(os.path.dirname(tx), stem, "subagents")
    out = []
    if os.path.isdir(sub_dir):
        for name in sorted(os.listdir(sub_dir)):
            if name.endswith(".jsonl"):
                out.append({
                    "transcript": os.path.join(sub_dir, name),
                    "project": primary_row.get("project", ""),
                    "session_id": "",
                    "mtime": primary_row.get("mtime", ""),
                    "encoded": primary_row.get("encoded", ""),
                    "kind": "subagent",
                })
    return out


def discover(project=None, within_days=30, since_iso=None, all_flag=False,
             include_subagents=False):
    """The candidate transcript set for a query: every primary session
    transcript from list-transcripts.sh, filtered by a project SUBSTRING matched
    against the encoded project-dir name (so a hyphenated folder like
    'enhancement-product' matches literally). Sub-agent transcripts are added
    only when asked for."""
    within = 100000 if all_flag else within_days
    if since_iso and not all_flag:
        within = max(within, _days_since(since_iso) + 1)
    rows = []
    proj = (project or "").lower()
    for r in _run_list_transcripts(within):
        tx = r.get("transcript")
        if not tx:
            continue
        encoded = os.path.basename(os.path.dirname(tx))
        if proj and proj not in encoded.lower():
            continue
        row = {
            "transcript": tx,
            "project": r.get("project", ""),
            "session_id": r.get("session_id", ""),
            "mtime": r.get("mtime", ""),
            "encoded": encoded,
            "kind": "primary",
        }
        rows.append(row)
    if include_subagents:
        extra = []
        for r in rows:
            extra.extend(_subagent_transcripts(r))
        rows.extend(extra)
    return rows


# ripgrep pre-filter (the speed layer)

def _which(name):
    return shutil.which(name)


def _rg_files(pattern, files, is_tool=False):
    """The subset of `files` whose RAW text contains `pattern`. A fast narrowing
    pass — the precise per-turn check runs afterward on the survivors.

    Returns None to mean "could not narrow" (rg missing, or the regex is invalid
    for rg): the caller then treats every file as a candidate. This keeps the
    pre-filter sound — it can only ever shrink the set on a clean match, never
    silently drop a file it failed to evaluate."""
    if not files:
        return set()
    rg = _which("rg")
    if not rg:
        return None
    pat = '"name":"%s"' % pattern if is_tool else pattern
    args = [rg, "-l", "-i", "--no-config", "-e", pat, "--"] + files
    try:
        p = subprocess.run(args, capture_output=True, text=True, timeout=180)
    except Exception:
        return None
    if p.returncode == 2:  # rg usage/regex error → cannot narrow
        return None
    return set(x for x in p.stdout.splitlines() if x)


def _candidate_files(spec, all_files):
    """Files worth parsing. A matching turn must satisfy every filter, and each
    filter's textual signature (the regex, or `"name":"Tool"`) appears in that
    turn's file — so the candidate set is the INTERSECTION of each filter's
    rg-narrowed file set. No pre-filterable filter ⇒ parse everything."""
    if spec.get("no_prefilter"):
        return list(all_files)
    patterns = []
    for key in ("match", "user_match", "assistant_match"):
        if spec.get(key):
            patterns.append((spec[key], False))
    if spec.get("tool"):
        patterns.append((spec["tool"], True))
    if not patterns:
        return list(all_files)
    cand = None
    for pat, is_tool in patterns:
        got = _rg_files(pat, all_files, is_tool)
        if got is None:
            continue  # unnarrowable filter: don't let it shrink the set
        cand = got if cand is None else (cand & got)
    return sorted(cand) if cand is not None else list(all_files)


# matching + snippets

def compile_regexes(spec):
    out = {}
    for key in ("match", "user_match", "assistant_match"):
        if spec.get(key):
            out[key] = re.compile(spec[key], re.IGNORECASE)
    return out


def _snippet(text, span, maxlen):
    """A single-line window of `text` around `span`, ≤ maxlen chars, with … where
    it was clipped. span == (0,0) means 'no specific hit' — return the head."""
    if not text:
        return ""
    s, e = span
    if e <= s:
        window = text[:maxlen]
        pre_ell, post_ell = False, len(text) > maxlen
    else:
        half = max(0, (maxlen - (e - s)) // 2)
        start = max(0, s - half)
        window = text[start:start + maxlen]
        pre_ell = start > 0
        post_ell = start + maxlen < len(text)
    window = re.sub(r"\s+", " ", window).strip()
    return ("…" if pre_ell else "") + window + ("…" if post_ell else "")


def match_turn(turn, spec, regexes):
    """Does this turn satisfy every filter in `spec`? If so return (role, snippet)
    where role is the side the snippet came from; else None. Filters AND together:
    tool membership, role-scoped `match`, and the role-pinned `user_match` /
    `assistant_match`."""
    utext = R.turn_user_text(turn)
    atext = R.turn_assistant_text(turn)
    role = spec.get("role", "any")

    if spec.get("tool"):
        want = spec["tool"].lower()
        if not any(n.lower() == want for n in R.turn_tool_names(turn)):
            return None

    hit_side = hit_span = hit_text = None

    if regexes.get("user_match"):
        m = regexes["user_match"].search(utext)
        if not m:
            return None
        hit_side, hit_span, hit_text = "user", m.span(), utext

    if regexes.get("assistant_match"):
        m = regexes["assistant_match"].search(atext)
        if not m:
            return None
        if hit_side is None:
            hit_side, hit_span, hit_text = "assistant", m.span(), atext

    if regexes.get("match"):
        rgx = regexes["match"]
        if role == "user":
            m = rgx.search(utext)
            if not m:
                return None
            side, span, txt = "user", m.span(), utext
        elif role == "assistant":
            m = rgx.search(atext)
            if not m:
                return None
            side, span, txt = "assistant", m.span(), atext
        else:
            m = rgx.search(utext)
            if m:
                side, span, txt = "user", m.span(), utext
            else:
                m = rgx.search(atext)
                if not m:
                    return None
                side, span, txt = "assistant", m.span(), atext
        if hit_side is None:
            hit_side, hit_span, hit_text = side, span, txt

    # role-only filter (no regex, no tool): require the scoped side be non-empty
    no_regex = not regexes
    if role != "any" and no_regex and not spec.get("tool"):
        if role == "user" and not utext:
            return None
        if role == "assistant" and not atext:
            return None

    if hit_side is None:
        # tool-only or role-only match: snippet from the role-relevant text
        if role == "assistant":
            hit_side, hit_text = "assistant", atext
        else:
            hit_side, hit_text = ("user", utext) if utext else ("assistant", atext)
        hit_span = (0, 0)

    return hit_side, _snippet(hit_text, hit_span, spec.get("snippet_len", 200))


# the query

def run_query(spec):
    """Every matching turn as a list of rows, streaming one transcript at a time.

    Each row: {project, transcript_path, session_id, turn_index, ts, role,
    snippet}. Honors spec['limit'] as a hard cap on rows returned."""
    rows = discover(
        project=spec.get("project"),
        within_days=spec.get("within_days", 30),
        since_iso=spec.get("since"),
        all_flag=spec.get("all"),
        include_subagents=spec.get("include_subagents"),
    )
    by_path = {}
    for r in rows:
        by_path.setdefault(r["transcript"], r)
    all_files = list(by_path.keys())
    cand = _candidate_files(spec, all_files)
    regexes = compile_regexes(spec)
    limit = spec.get("limit")

    results = []
    for path in cand:
        meta = by_path.get(path, {"project": "", "session_id": "", "encoded": ""})
        try:
            lines = R.load_lines(path)
        except Exception:
            continue
        for idx, turn in enumerate(R.split_turns(lines)):
            hit = match_turn(turn, spec, regexes)
            if hit is None:
                continue
            side, snippet = hit
            results.append({
                "project": meta.get("project", "") or decode_project(meta.get("encoded", "")),
                "transcript_path": path,
                "session_id": R.turn_session_id(turn) or meta.get("session_id", ""),
                "turn_index": idx,
                "ts": R.turn_ts(turn),
                "role": side,
                "snippet": snippet,
            })
            if limit and len(results) >= limit:
                return results
    return results


# turn resolution (used by `ta tag`)

def resolve_turn(transcript, turn_idx):
    """Session id + project (the cwd the turn ran in) for one turn — what a
    bookmark needs. Raises IndexError/ValueError on a bad turn index."""
    idx = int(turn_idx)
    lines = R.load_lines(transcript)
    turns = R.split_turns(lines)
    if idx < 0 or idx >= len(turns):
        raise IndexError("turn %d out of range (transcript has %d turns)" % (idx, len(turns)))
    turn = turns[idx]
    sid = R.turn_session_id(turn)
    proj = R.turn_cwd(turn, "") or decode_project(
        os.path.basename(os.path.dirname(transcript))
    )
    return sid, proj


def _cli_resolve(transcript, turn_idx):
    try:
        sid, proj = resolve_turn(transcript, turn_idx)
    except Exception as e:  # noqa: BLE001
        sys.stderr.write(str(e) + "\n")
        sys.exit(2)
    sys.stdout.write("%s\t%s\n" % (sid, proj))


if __name__ == "__main__":
    if len(sys.argv) >= 4 and sys.argv[1] == "resolve":
        _cli_resolve(sys.argv[2], sys.argv[3])
    else:
        sys.stderr.write("ta_core: internal helper — use the `ta` dispatcher\n")
        sys.exit(2)
