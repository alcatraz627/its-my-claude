#!/usr/bin/env bash
# subconscious/scripts/ingest-checkpoint.sh
#
# Parse a /core-dump checkpoint markdown file and extract cross-session-relevant
# subsets into a structured JSON entry under ingest-queue/. The subconscious
# dreaming daemon picks up queue files, runs association/pattern detection,
# and publishes briefings.
#
# Sections extracted (the cross-session-relevant subset):
#   - Session Insights: "What worked well" / "What didn't work" / "Gotchas" /
#     "Notes for future agents" / "User feedback received"
#   - Pending Items (todos that might be forgotten)
#
# Skipped (project-specific, low value for cross-correlation):
#   - Initial Goal (project-specific)
#   - Agent Actions log (project-specific noise)
#   - Current Expectation (transient)
#
# Usage:
#   ingest-checkpoint.sh <checkpoint-path> [--session-id ID] [--project-root PATH]
#
# Writes: ~/.claude/subconscious/dreams/ingest-queue/<ts>-<sid8>.json

set -uo pipefail

CHECKPOINT_PATH=""
SESSION_ID=""
PROJECT_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-id)   SESSION_ID="$2"; shift ;;
    --project-root) PROJECT_ROOT="$2"; shift ;;
    *)              CHECKPOINT_PATH="$1" ;;
  esac
  shift
done

[[ -f "$CHECKPOINT_PATH" ]] || { printf 'checkpoint not found: %s\n' "$CHECKPOINT_PATH" >&2; exit 1; }

QUEUE_DIR="${HOME}/.claude/subconscious/dreams/ingest-queue"
mkdir -p "$QUEUE_DIR"

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
SID_SHORT="${SESSION_ID:0:8}"
OUT="$QUEUE_DIR/${TS//:/}-${SID_SHORT:-unknown}.json"

python3 - "$CHECKPOINT_PATH" "$SESSION_ID" "$PROJECT_ROOT" "$TS" "$OUT" <<'PY'
import json, sys, re, os

ckpt_path, sid, project, ts, out = sys.argv[1:6]

with open(ckpt_path) as f:
    text = f.read()

# Split markdown into sections by H2 headers.
sections = {}
current = None
for line in text.splitlines():
    if line.startswith("## "):
        current = line[3:].strip()
        sections[current] = []
    elif current is not None:
        sections[current].append(line)

def section_text(name_substring):
    for k, lines in sections.items():
        if name_substring.lower() in k.lower():
            return "\n".join(lines).strip()
    return ""

def extract_bullets(s):
    out = []
    for ln in s.splitlines():
        m = re.match(r"^\s*[-*]\s+(.+)$", ln)
        if m:
            out.append(m.group(1).strip())
    return out

def extract_subsection(insight_text, sub_name):
    """Find a **What worked / didn't / ...** style subsection within Session Insights."""
    pattern = re.compile(rf"\*\*{re.escape(sub_name)}.*?\*\*[:\s]*\n?(.*?)(?=\n\*\*|\Z)", re.DOTALL | re.IGNORECASE)
    m = pattern.search(insight_text)
    if not m: return []
    return extract_bullets(m.group(1))

insight_text = section_text("Session Insights") or section_text("Insights")
pending_text = section_text("Pending Items") or section_text("Pending")

worked    = extract_subsection(insight_text, "worked well") or extract_subsection(insight_text, "What worked")
didnt     = extract_subsection(insight_text, "didn't work") or extract_subsection(insight_text, "What didn't")
gotchas   = extract_subsection(insight_text, "Gotcha")
notes     = extract_subsection(insight_text, "Notes for future")
feedback  = extract_subsection(insight_text, "feedback received") or extract_subsection(insight_text, "User feedback")
pending   = extract_bullets(pending_text)

entry = {
    "ts":            ts,
    "session_id":    sid,
    "project_root":  project,
    "checkpoint_path": ckpt_path,
    "insights": {
        "worked":     worked,
        "didnt_work": didnt,
        "gotchas":    gotchas,
        "notes":      notes,
        "feedback":   feedback,
    },
    "pending": pending,
    "tags": [],   # daemon can enrich with auto-tags later
}

with open(out, "w") as f:
    json.dump(entry, f, indent=2)
print(f"wrote: {out}")
print(f"counts: worked={len(worked)} didnt={len(didnt)} gotchas={len(gotchas)} notes={len(notes)} feedback={len(feedback)} pending={len(pending)}")
PY
