#!/usr/bin/env bash
# wal-convert.sh — convert a legacy .claude/wal.md to .claude/wal.jsonl.
#
# Usage:
#   wal-convert.sh <input.md> [--output <path>] [--dry-run]
#
# If --output is omitted, writes to the same directory with a .jsonl extension.
# --dry-run prints JSONL to stdout instead of writing.
#
# The parser is Python (macOS ships python3). See the state machine below.
#
# Real-world wal.md files deviate from the strict spec in skills/shared/wal-format.md.
# This converter is deliberately tolerant of observed patterns:
#   - Session header variations (id—date OR date—description OR date alone)
#   - **Goal:** markdown instead of > Intent:
#   - Bullet actions (- Read foo.ts — outcome) without timestamps
#   - Free-form [HH:MM] text lines (no strict VERB keyword)
#   - Checkpoint terminators: both `===` and `=== END CHECKPOINT ===`

set -uo pipefail

INPUT=""
OUTPUT=""
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --output) OUTPUT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '2,16p' "$0"
      exit 0 ;;
    *) INPUT="$1"; shift ;;
  esac
done

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
  echo "usage: wal-convert.sh <input.md> [--output <path>] [--dry-run]" >&2
  [ -n "$INPUT" ] && echo "not found: $INPUT" >&2
  exit 1
fi

if [ -z "$OUTPUT" ]; then
  OUTPUT="${INPUT%.md}.jsonl"
fi

python3 - "$INPUT" "$OUTPUT" "$DRY_RUN" <<'PYEOF'
import json
import re
import sys
from pathlib import Path

input_path = Path(sys.argv[1])
output_path = Path(sys.argv[2])
dry_run = sys.argv[3] == "1"

text = input_path.read_text(encoding="utf-8", errors="replace")
lines = text.splitlines()

lines_out = []
session = {"id": None, "date": None}

# Strict spec format: ## Session: YYYY-MM-DD HH:MM [id]
re_session_strict = re.compile(r"^##\s*Session:\s*(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s*(?:\[([^\]]+)\])?")
# Real format: ## Session: <id> — YYYY-MM-DD  OR  ## Session: YYYY-MM-DD (desc)  OR  ## Session: YYYY-MM-DD
re_session_loose = re.compile(r"^##\s*Session:\s*(.+?)\s*$")
re_date = re.compile(r"(\d{4}-\d{2}-\d{2})")
re_session_id_token = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)+$")

re_meta_user = re.compile(r"^>\s*User:\s*(.*)")
re_meta_intent = re.compile(r"^>\s*Intent:\s*(.*)")
re_md_goal = re.compile(r"^\*\*Goal:\*\*\s*(.*)")
re_md_intent = re.compile(r"^\*\*Intent:\*\*\s*(.*)")

# Strict action: [HH:MM] VERB target — outcome
re_action_strict = re.compile(r"^\[(\d{2}:\d{2})\]\s+(READ|WRITE|EDIT|BASH|GLOB|GREP|COMMIT)\s+(.*)")
# Loose timestamped: [HH:MM] freeform
re_action_timed_loose = re.compile(r"^\[(\d{2}:\d{2})\]\s+(.*)")
# Bullet action: - Text or - VERB target — outcome
re_action_bullet = re.compile(r"^-\s+(.*)")

re_agent_start = re.compile(r"^\[?(\d{2}:\d{2})?\]?\s*AGENT\(([^)]+)\)\s+\"?([^\"]*?)\"?\s*(?:—\s*(.*))?$")
re_agent_done = re.compile(r"^\[?(\d{2}:\d{2})?\]?\s*AGENT_DONE\(([^)]+)\)\s*(?:—\s*(.*))?$")
re_decision = re.compile(r"^\[?(\d{2}:\d{2})?\]?\s*DECISION:\s*(.*)")

# Checkpoint: === CHECKPOINT [HH:MM]? (anything)? ===
re_ckpt_start = re.compile(r"^===\s*CHECKPOINT(?:\s+\[(\d{2}:\d{2})\])?(?:\s+\([^)]*\))?\s*===\s*$")
# Terminator: === END CHECKPOINT === OR bare ===
re_ckpt_end = re.compile(r"^===\s*(?:END\s+CHECKPOINT\s*===)?\s*$")

# Infer verb from a bullet or timestamped-loose line
KNOWN_VERBS = {
    "read": "read", "readed": "read",
    "wrote": "write", "write": "write", "writing": "write",
    "edit": "edit", "edited": "edit", "editing": "edit",
    "fix": "edit", "fixed": "edit",
    "added": "edit", "add": "edit",
    "removed": "edit", "remove": "edit",
    "reordered": "edit",
    "tightened": "edit",
    "changed": "edit",
    "bash": "bash", "ran": "bash",
    "launched": "bash",
    "commit": "commit", "committed": "commit",
    "glob": "glob", "grep": "grep",
    "catchup": "read",
    "resumed": "read",
}

pending_session_end = False

def ts(hhmm: str) -> str:
    if session["date"] and hhmm:
        return f"{session['date']}T{hhmm}:00Z"
    if session["date"]:
        return f"{session['date']}T00:00:00Z"
    return ""

def emit(obj: dict) -> None:
    obj = {k: v for k, v in obj.items() if v not in ("", None, [])}
    lines_out.append(json.dumps(obj, ensure_ascii=False, separators=(",", ":")))

def parse_session_loose(body: str):
    """Extract (id, date) from a loose session header body, both optional."""
    date_match = re_date.search(body)
    date = date_match.group(1) if date_match else None
    # Remove date from body to find id
    remainder = body
    if date_match:
        remainder = (body[:date_match.start()] + body[date_match.end():]).strip(" —-–\t")
    # Try to find a session-id-like token. Only split on whitespace, em/en-dash,
    # parens — NOT on regular hyphen, since hyphens are part of session IDs.
    sid = None
    for tok in re.split(r"[\s\u2014\u2013()]+", remainder):
        tok = tok.strip().strip("-")
        if re_session_id_token.match(tok):
            sid = tok
            break
    return sid, date

def infer_verb_from_text(text: str) -> str:
    first_word = re.split(r"\s+", text.strip(), maxsplit=1)[0].lower().strip(":,.")
    return KNOWN_VERBS.get(first_word, "note")

def emit_action_from_text(hhmm: str, text: str):
    text = text.strip()
    if not text:
        return
    verb = infer_verb_from_text(text)
    target = text
    outcome = ""
    parts = re.split(r"\s+—\s+", text, maxsplit=1)
    if len(parts) == 2:
        target, outcome = parts[0].strip(), parts[1].strip()
    # If verb was inferred from first word and it was a known verb, strip it from target
    first_word = re.split(r"\s+", target, maxsplit=1)[0].lower().strip(":,.")
    if first_word in KNOWN_VERBS:
        parts2 = re.split(r"\s+", target, maxsplit=1)
        if len(parts2) == 2:
            target = parts2[1].strip()
    emit({
        "ts": ts(hhmm),
        "kind": "action",
        "session_id": session["id"] or "unknown",
        "verb": verb,
        "target": target,
        "outcome": outcome,
    })

i = 0
while i < len(lines):
    line = lines[i].rstrip()
    stripped = line.strip()

    # --- Session headers (strict first, then loose) ---
    m = re_session_strict.match(line)
    if m:
        if pending_session_end and session["id"]:
            emit({"ts": ts("23:59"), "kind": "session_end", "session_id": session["id"]})
        date, hhmm, sid = m.group(1), m.group(2), m.group(3) or ""
        session["date"] = date
        session["id"] = sid or f"unknown-{date}"
        user_msg, intent = "", ""
        j = i + 1
        while j < len(lines) and (lines[j].lstrip().startswith(">") or lines[j].lstrip().startswith("**")):
            lstripped = lines[j].lstrip()
            for pat, target in ((re_meta_user, "user_msg"),
                                (re_meta_intent, "intent"),
                                (re_md_goal, "intent"),
                                (re_md_intent, "intent")):
                mm = pat.match(lstripped)
                if mm:
                    if target == "user_msg":
                        user_msg = mm.group(1).strip()
                    else:
                        intent = mm.group(1).strip()
            j += 1
        emit({
            "ts": f"{date}T{hhmm}:00Z",
            "kind": "session_start",
            "session_id": session["id"],
            "user": user_msg,
            "intent": intent,
        })
        pending_session_end = True
        i = j
        continue

    m = re_session_loose.match(line)
    if m:
        body = m.group(1)
        sid, date = parse_session_loose(body)
        if pending_session_end and session["id"]:
            emit({"ts": ts("23:59"), "kind": "session_end", "session_id": session["id"]})
        if date:
            session["date"] = date
        session["id"] = sid or (f"unknown-{date}" if date else "unknown")
        user_msg, intent = "", ""
        j = i + 1
        while j < len(lines):
            lstripped = lines[j].lstrip()
            if not lstripped:
                j += 1
                continue
            if lstripped.startswith(">") or lstripped.startswith("**"):
                for pat, target in ((re_meta_user, "user_msg"),
                                    (re_meta_intent, "intent"),
                                    (re_md_goal, "intent"),
                                    (re_md_intent, "intent")):
                    mm = pat.match(lstripped)
                    if mm:
                        if target == "user_msg":
                            user_msg = mm.group(1).strip()
                        else:
                            intent = mm.group(1).strip()
                j += 1
                continue
            break
        emit({
            "ts": ts("00:00"),
            "kind": "session_start",
            "session_id": session["id"],
            "user": user_msg,
            "intent": intent,
        })
        pending_session_end = True
        i = j
        continue

    # --- Checkpoint block ---
    m = re_ckpt_start.match(line)
    if m:
        hhmm = m.group(1) or ""
        ckpt = {
            "ts": ts(hhmm),
            "kind": "checkpoint",
            "session_id": session["id"] or "unknown",
            "goal": "",
            "done": [],
            "current": "",
            "next": "",
            "blockers": [],
            "learnings": [],
        }
        j = i + 1
        while j < len(lines):
            cline = lines[j].strip()
            if re_ckpt_end.match(cline):
                j += 1
                break
            if cline.lower().startswith("goal:"):
                ckpt["goal"] = cline.split(":", 1)[1].strip()
            elif cline.lower().startswith("done:"):
                raw = cline.split(":", 1)[1].strip()
                ckpt["done"] = [p.strip(" -•\t") for p in re.split(r"[,;]|\s+-\s+", raw) if p.strip(" -•\t")]
            elif cline.lower().startswith("current:"):
                ckpt["current"] = cline.split(":", 1)[1].strip()
            elif cline.lower().startswith("next:"):
                ckpt["next"] = cline.split(":", 1)[1].strip()
            elif cline.lower().startswith("blockers:"):
                raw = cline.split(":", 1)[1].strip()
                if raw.lower() not in ("", "none"):
                    ckpt["blockers"] = [p.strip(" -•\t") for p in re.split(r"[,;]|\s+-\s+", raw) if p.strip(" -•\t")]
            elif cline.lower().startswith("learnings:"):
                raw = cline.split(":", 1)[1].strip()
                if raw:
                    ckpt["learnings"] = [p.strip(" -•\t") for p in re.split(r"[,;]|\s+-\s+", raw) if p.strip(" -•\t")]
            j += 1
        emit(ckpt)
        i = j
        continue

    # --- Agent / Decision (may or may not have timestamp prefix) ---
    m = re_decision.match(stripped)
    if m:
        hhmm, body = m.group(1) or "", m.group(2).strip()
        choice, why = body, ""
        paren = re.match(r"^(.*?)\s*\((.*)\)\s*$", body)
        if paren:
            choice, why = paren.group(1).strip(), paren.group(2).strip()
        emit({"ts": ts(hhmm), "kind": "decision", "session_id": session["id"] or "unknown", "choice": choice, "why": why})
        i += 1
        continue

    m = re_agent_start.match(stripped)
    if m:
        hhmm, agent, task = m.group(1) or "", m.group(2), (m.group(3) or "").strip()
        emit({"ts": ts(hhmm), "kind": "agent_start", "session_id": session["id"] or "unknown", "agent": agent, "task": task})
        i += 1
        continue

    m = re_agent_done.match(stripped)
    if m:
        hhmm, agent, result = m.group(1) or "", m.group(2), (m.group(3) or "").strip()
        emit({"ts": ts(hhmm), "kind": "agent_done", "session_id": session["id"] or "unknown", "agent": agent, "result": result})
        i += 1
        continue

    # --- Strict action: [HH:MM] VERB target ---
    m = re_action_strict.match(line)
    if m:
        hhmm, verb, rest = m.group(1), m.group(2).lower(), m.group(3).strip()
        target, outcome = rest, ""
        parts = re.split(r"\s+—\s+", rest, maxsplit=1)
        if len(parts) == 2:
            target, outcome = parts[0].strip(), parts[1].strip()
        emit({"ts": ts(hhmm), "kind": "action", "session_id": session["id"] or "unknown", "verb": verb, "target": target, "outcome": outcome})
        i += 1
        continue

    # --- Loose timestamped freeform: [HH:MM] text ---
    m = re_action_timed_loose.match(line)
    if m:
        hhmm, rest = m.group(1), m.group(2).strip()
        emit_action_from_text(hhmm, rest)
        i += 1
        continue

    # --- Bullet action: - text ---
    m = re_action_bullet.match(line)
    if m and session["id"]:
        rest = m.group(1).strip()
        emit_action_from_text("", rest)
        i += 1
        continue

    i += 1

# Flush final session_end
if pending_session_end and session["id"]:
    emit({"ts": ts("23:59"), "kind": "session_end", "session_id": session["id"]})

body = "\n".join(lines_out) + ("\n" if lines_out else "")
if dry_run:
    sys.stdout.write(body)
else:
    output_path.write_text(body, encoding="utf-8")
    print(f"[wal-convert] wrote {len(lines_out)} lines -> {output_path}", file=sys.stderr)
PYEOF
