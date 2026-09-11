#!/usr/bin/env python3
"""Codex sessions -> i-dream events, including handback outcomes.

One event per Codex session, read from the rollout files under ~/.codex/sessions:
who launched it (originator), how (source: exec, cli, vscode, subagent:*), where
(cwd), and the first user message, truncated. Each file is read only until the
first user message is found, so the 90 MB of rollouts costs a few hundred KB.
Re-emits everything each run; i-dream keeps its own cursor by id.

    extract-events.py [out-path]      default: <this dir>/events.jsonl
    extract-events.py --self-test
"""
import json
import os
import re
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
MAX_LINES = 400  # session_meta is line 1; the first user turn follows within a few lines
VERIFIED_HEADING = re.compile(
    r"^\s*(?:#{1,6}\s+Verified\s*|(?:-\s+)?\*\*Verified\*\*:?)\s*$",
    re.IGNORECASE,
)
SECTION_HEADING = re.compile(
    r"^\s*(?:#{1,6}\s+\S.*|(?:-\s+)?\*\*[^*]+\*\*:?)\s*$"
)
FENCE = re.compile(r"^\s*(`{3,}|~{3,})")


def first_user_text(payload):
    if payload.get("type") != "message" or payload.get("role") != "user":
        return None
    parts = [c.get("text", "") for c in payload.get("content", []) if c.get("type") == "input_text"]
    text = " ".join(p for p in parts if p).strip()
    # Codex prefixes the owner's first turn with instruction blocks; skip those.
    if not text or text.startswith("<"):
        return None
    return text[:240]


def timestamp_seconds(value):
    if not isinstance(value, str):
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.timestamp()


def newest_file(paths, minimum_mtime=None, inclusive=True):
    candidates = []
    for path in paths:
        try:
            mtime = path.stat().st_mtime
        except OSError:
            continue
        if minimum_mtime is None:
            candidates.append((mtime, path))
        elif inclusive and mtime >= minimum_mtime:
            candidates.append((mtime, path))
        elif not inclusive and mtime > minimum_mtime:
            candidates.append((mtime, path))
    return max(candidates, default=(None, None), key=lambda item: item[0])[1]


def earliest_file(paths, minimum_mtime, maximum_mtime=None):
    candidates = []
    for path in paths:
        try:
            mtime = path.stat().st_mtime
        except OSError:
            continue
        if mtime < minimum_mtime:
            continue
        if maximum_mtime is not None and mtime >= maximum_mtime:
            continue
        candidates.append((mtime, path))
    return min(candidates, default=(None, None), key=lambda item: item[0])[1]


def verified_section(path):
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return []
    start = next((i + 1 for i, line in enumerate(lines) if VERIFIED_HEADING.match(line)), None)
    if start is None:
        return []
    end = next(
        (i for i in range(start, len(lines)) if SECTION_HEADING.match(lines[i])),
        len(lines),
    )
    return lines[start:end]


def has_fenced_block(lines):
    opening = None
    for line in lines:
        match = FENCE.match(line)
        if not match:
            continue
        marker = match.group(1)
        if opening is None:
            opening = marker
        elif marker[0] == opening[0] and len(marker) >= len(opening):
            return True
    return False


def non_fenced_line_count(lines):
    opening = None
    count = 0
    for line in lines:
        match = FENCE.match(line)
        if match:
            marker = match.group(1)
            if opening is None:
                opening = marker
            elif marker[0] == opening[0] and len(marker) >= len(opening):
                opening = None
            continue
        if opening is None and line.strip():
            count += 1
    return count


def outcome_fields(cwd, session_ts, next_session_ts=None):
    empty = {
        "handback": None,
        "verified_lines": 0,
        "verified_claims": 0,
        "unconfirmed": 0,
        "checks_pasted": False,
        "review_verdict": None,
        "outcome": "no-handback",
    }
    if not cwd or session_ts is None:
        return empty

    root = Path(cwd).expanduser()
    handback = earliest_file(
        root.glob("_codex-handback-*.claude.md"), session_ts, next_session_ts
    )
    if handback is None:
        return empty

    section = verified_section(handback)
    section_text = "\n".join(section)
    report_root = root / ".claude" / "output"
    report = newest_file(
        report_root.glob("*codex-handback-review/report.md"),
        handback.stat().st_mtime,
        inclusive=False,
    )
    # A review belongs to the session window too (reviewer's note on round 2):
    # a report written after the next session started is that session's.
    if report is not None and next_session_ts is not None and report.stat().st_mtime >= next_session_ts:
        report = None
    review_verdict = None
    if report is not None:
        try:
            with report.open(encoding="utf-8", errors="replace") as fh:
                review_verdict = fh.readline().rstrip("\r\n")
        except OSError:
            pass

    return {
        "handback": str(handback.resolve()),
        "verified_lines": sum(bool(line.strip()) for line in section),
        "verified_claims": non_fenced_line_count(section),
        "unconfirmed": section_text.count("UNCONFIRMED"),
        "checks_pasted": has_fenced_block(section),
        "review_verdict": review_verdict,
        "outcome": "reviewed" if review_verdict is not None else "handed-back",
    }


def event_for(path):
    meta, prompt = None, None
    try:
        with path.open(encoding="utf-8", errors="replace") as fh:
            for i, line in enumerate(fh):
                if i >= MAX_LINES:
                    break
                try:
                    rec = json.loads(line)
                except json.JSONDecodeError:
                    continue
                p = rec.get("payload", {})
                if rec.get("type") == "session_meta" and meta is None:
                    meta = {
                        "id": p.get("id") or p.get("session_id"),
                        "ts": p.get("timestamp") or rec.get("timestamp"),
                        "cwd": p.get("cwd"),
                        "slug": p.get("source") or "unknown",
                        "originator": p.get("originator") or "unknown",
                        "cli_version": p.get("cli_version") or "",
                        "first_prompt": None,
                    }
                elif meta is not None and rec.get("type") == "response_item":
                    prompt = first_user_text(p)
                    if prompt:
                        break
    except OSError:
        return None
    if not meta or not meta["id"] or not meta["ts"]:
        return None
    meta["first_prompt"] = prompt
    return meta


def enrich_outcomes(events):
    by_cwd = {}
    for event in events:
        session_ts = timestamp_seconds(event["ts"])
        if event["cwd"] and session_ts is not None:
            by_cwd.setdefault(event["cwd"], []).append((session_ts, event))

    for sessions in by_cwd.values():
        sessions.sort(key=lambda item: item[0])
        for index, (session_ts, event) in enumerate(sessions):
            # Sessions sharing a start (a seat and its guardian sub-agent) share
            # a window; the bound is the next DIFFERENT start. Validator major 1.
            next_session_ts = next((ts for ts, _ in sessions[index + 1:] if ts > session_ts), None)
            event.update(outcome_fields(event["cwd"], session_ts, next_session_ts))

    for event in events:
        if "outcome" not in event:
            event.update(outcome_fields(event["cwd"], timestamp_seconds(event["ts"])))


def extract(sessions, out):
    events = []
    if sessions.is_dir():
        for path in sorted(sessions.rglob("rollout-*.jsonl")):
            ev = event_for(path)
            if ev:
                events.append(ev)
    enrich_outcomes(events)
    tmp = out.with_suffix(".tmp")
    with tmp.open("w", encoding="utf-8") as fh:
        for ev in events:
            fh.write(json.dumps(ev, ensure_ascii=False) + "\n")
    tmp.replace(out)
    return events


def self_test():
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        codex_home = root / "codex-home"
        sessions = codex_home / "sessions"
        sessions.mkdir(parents=True)
        cwd = root / "workspace"
        cwd.mkdir()
        session_rows = [
            ("self-test-session-1", "2026-01-01T00:00:00Z"),
            ("self-test-gap-session", "2026-01-01T00:00:50Z"),
            ("self-test-session-2", "2026-01-01T00:01:40Z"),
        ]
        for index, (session_id, session_ts) in enumerate(session_rows, start=1):
            rollout = sessions / f"rollout-test-{index}.jsonl"
            records = [
                {
                    "timestamp": session_ts,
                    "type": "session_meta",
                    "payload": {
                        "id": session_id,
                        "timestamp": session_ts,
                        "cwd": str(cwd),
                        "source": "exec",
                        "originator": "self-test",
                        "cli_version": "test",
                    },
                },
                {
                    "type": "response_item",
                    "payload": {
                        "type": "message",
                        "role": "user",
                        "content": [{"type": "input_text", "text": "Test outcomes"}],
                    },
                },
            ]
            rollout.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )

        start = timestamp_seconds(session_rows[0][1])
        handbacks = [
            cwd / "_codex-handback-stale.claude.md",
            cwd / "_codex-handback-first.claude.md",
            cwd / "_codex-handback-second.claude.md",
        ]
        for handback in handbacks:
            handback.write_text(
                "**Verified**\nClaim.\n```text\nUNCONFIRMED\n```\n**State now**\nReady.\n",
                encoding="utf-8",
            )
        for handback, offset in zip(handbacks, (-10, 10, 110)):
            os.utime(handback, (start + offset, start + offset))

        out = root / "events.jsonl"
        extract(sessions, out)
        events = [
            json.loads(line)
            for line in out.read_text(encoding="utf-8").splitlines()
        ]
        expected = {
            "verified_lines": 4,
            "verified_claims": 1,
            "unconfirmed": 1,
            "checks_pasted": True,
            "review_verdict": None,
            "outcome": "handed-back",
        }
        expected_events = {
            "self-test-session-1": {"handback": str(handbacks[1].resolve()), **expected},
            "self-test-gap-session": {
                "handback": None,
                "verified_lines": 0,
                "verified_claims": 0,
                "unconfirmed": 0,
                "checks_pasted": False,
                "review_verdict": None,
                "outcome": "no-handback",
            },
            "self-test-session-2": {"handback": str(handbacks[2].resolve()), **expected},
        }
        actual_ids = {event["id"] for event in events}
        if actual_ids != set(expected_events):
            print(
                "self-test: FAIL: event ids: "
                f"expected {set(expected_events)!r}, got {actual_ids!r}"
            )
            return 1
        for event in events:
            event_expected = expected_events[event["id"]]
            for field, value in event_expected.items():
                if event.get(field) != value:
                    print(
                        f"self-test: FAIL: {event['id']} {field}: "
                        f"expected {value!r}, got {event.get(field)!r}"
                    )
                    return 1
        if any(event["handback"] == str(handbacks[0].resolve()) for event in events):
            print("self-test: FAIL: stale handback was attributed")
            return 1
    print("self-test: ok")
    return 0


def main():
    if sys.argv[1:] == ["--self-test"]:
        return self_test()
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "events.jsonl"
    sessions = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")) / "sessions"
    events = extract(sessions, out)
    print(f"{len(events)} events -> {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
