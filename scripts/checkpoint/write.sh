#!/usr/bin/env bash
# checkpoint/write.sh — Record a checkpoint event.
#
# Writes:
#   1. ~/.claude/checkpoints/<session-id>.json    — session-keyed pointer
#                                                   (one per active session; safe to refresh)
#   2. ~/.claude/checkpoints/index.jsonl          — chronological log
#                                                   (append OR replace-latest matching line)
#   3. ~/.claude/_last-checkpoint.json            — BACK-COMPAT (deprecated, removed in
#                                                   migration 0008 once readers updated)
#
# Why a directory + index: multiple long-running agents across different projects each
# get their own pointer, no last-writer-wins contention. The index gives /catchup a
# chronological picker.
#
# Usage:
#   write.sh --session-id ID --project-root PATH --checkpoint-path PATH \
#            [--name "human name"] [--summary "1-line summary"] \
#            [--kind core-dump|precompact|retro]     # default core-dump
#            [--mode append|replace-latest]          # default append
#            [--guard-newer-than N]                  # skip if a kind=core-dump entry
#                                                    # exists for this session within
#                                                    # N seconds; pre-compact uses this
#                                                    # to avoid shadowing real dumps
#
# All args required except --name (defaults to session-id), --summary (defaults to
# empty), --kind, --mode, --guard-newer-than.
#
# Atomicity: each file is written via temp + mv. The index update uses flock when
# replacing or when the line might exceed PIPE_BUF.

set -uo pipefail

SESSION_ID="" SESSION_UUID="" PROJECT_ROOT="" CHECKPOINT_PATH="" NAME="" SUMMARY=""
KIND="core-dump" MODE="append" GUARD_SECS="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-id)        SESSION_ID="$2"; shift ;;
    --session-uuid)      SESSION_UUID="$2"; shift ;;
    --project-root)      PROJECT_ROOT="$2"; shift ;;
    --checkpoint-path)   CHECKPOINT_PATH="$2"; shift ;;
    --name)              NAME="$2"; shift ;;
    --summary)           SUMMARY="$2"; shift ;;
    --kind)              KIND="$2"; shift ;;
    --mode)              MODE="$2"; shift ;;
    --guard-newer-than)  GUARD_SECS="$2"; shift ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

[[ -n "$SESSION_ID" && -n "$PROJECT_ROOT" && -n "$CHECKPOINT_PATH" ]] || {
  printf 'usage: %s --session-id ID --project-root PATH --checkpoint-path PATH [opts]\n' "$0" >&2
  exit 2
}

case "$KIND" in core-dump|precompact|retro) ;; *) printf 'invalid --kind %s\n' "$KIND" >&2; exit 2 ;; esac
case "$MODE" in append|replace-latest)      ;; *) printf 'invalid --mode %s\n' "$MODE" >&2; exit 2 ;; esac

NAME="${NAME:-$SESSION_ID}"
CKPT_DIR="${HOME}/.claude/checkpoints"
mkdir -p "$CKPT_DIR"

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
INDEX="$CKPT_DIR/index.jsonl"

# Guard: skip entirely if a kind=core-dump entry exists for this session within
# the guard window. Pre-compact uses this so it doesn't shadow a fresh dump.
if (( GUARD_SECS > 0 )) && [[ -f "$INDEX" ]]; then
  skip=$(python3 - "$INDEX" "$SESSION_ID" "$GUARD_SECS" <<'PY'
import json, sys
from datetime import datetime, timezone
idx, sid, guard = sys.argv[1], sys.argv[2], int(sys.argv[3])
now = datetime.now(timezone.utc)
with open(idx) as f:
    for ln in f:
        ln = ln.strip()
        if not ln: continue
        try: r = json.loads(ln)
        except: continue
        if r.get("session_id") != sid: continue
        if r.get("kind") != "core-dump": continue
        try:
            t = datetime.strptime(r["ts"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
        except: continue
        if (now - t).total_seconds() < guard:
            print("skip"); sys.exit(0)
print("go")
PY
)
  if [[ "$skip" == "skip" ]]; then
    printf 'guard-newer-than: a fresh core-dump entry exists for %s within %ds — skipping index write\n' "$SESSION_ID" "$GUARD_SECS"
    # Still write the session-keyed file + back-compat for local consistency.
    # Just skip the index append/replace.
    SKIP_INDEX=1
  fi
fi

# JSON-escape a value (string only — no nested objects here).
json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.argv[1]), end="")' "$1"
}

# 1. Session-keyed pointer (refresh in place, atomic).
SAFE_SID=$(printf '%s' "$SESSION_ID" | LC_ALL=C tr -c 'A-Za-z0-9._-' '_')
SESSION_FILE="$CKPT_DIR/$SAFE_SID.json"
TMP=$(mktemp)
cat > "$TMP" <<EOF
{
  "session_id":      $(json_escape "$SESSION_ID"),
  "session_uuid":    $(json_escape "$SESSION_UUID"),
  "project_root":    $(json_escape "$PROJECT_ROOT"),
  "checkpoint_path": $(json_escape "$CHECKPOINT_PATH"),
  "name":            $(json_escape "$NAME"),
  "summary":         $(json_escape "$SUMMARY"),
  "kind":            $(json_escape "$KIND"),
  "ts":              $(json_escape "$TS")
}
EOF
/bin/mv -f "$TMP" "$SESSION_FILE"

# 2. Index update (append OR replace-latest).
if [[ -z "${SKIP_INDEX:-}" ]]; then
  LINE=$(python3 -c '
import json, sys
print(json.dumps({
  "ts":              sys.argv[1],
  "session_id":      sys.argv[2],
  "session_uuid":    sys.argv[3],
  "project_root":    sys.argv[4],
  "checkpoint_path": sys.argv[5],
  "name":            sys.argv[6],
  "summary":         sys.argv[7],
  "kind":            sys.argv[8],
}))
' "$TS" "$SESSION_ID" "$SESSION_UUID" "$PROJECT_ROOT" "$CHECKPOINT_PATH" "$NAME" "$SUMMARY" "$KIND")

  if [[ "$MODE" == "replace-latest" && -f "$INDEX" ]]; then
    # Find latest line matching (session_id, kind); remove it; append new.
    # All-in-one Python pass under flock for atomicity.
    ( command -v flock >/dev/null 2>&1 && flock -x 9 2>/dev/null
      python3 - "$INDEX" "$SESSION_ID" "$KIND" "$LINE" <<'PY'
import json, sys, os, tempfile
idx, sid, kind, new_line = sys.argv[1:5]
keep = []
match_indices = []
with open(idx) as f:
    for i, ln in enumerate(f):
        ln_str = ln.rstrip("\n")
        if not ln_str.strip():
            keep.append(ln_str); continue
        try: r = json.loads(ln_str)
        except:
            keep.append(ln_str); continue
        if r.get("session_id") == sid and r.get("kind") == kind:
            match_indices.append(len(keep))  # remember position
        keep.append(ln_str)
# Drop the LAST matching position (keep older ones for audit trail)
if match_indices:
    keep.pop(match_indices[-1])
keep.append(new_line)
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(idx))
with os.fdopen(fd, "w") as out:
    out.write("\n".join(keep) + "\n")
os.replace(tmp, idx)
PY
    ) 9>"$CKPT_DIR/.index.lock"
  else
    # Plain append. O_APPEND on macOS is atomic for writes < PIPE_BUF (512).
    if (( ${#LINE} < 500 )); then
      printf '%s\n' "$LINE" >> "$INDEX"
    else
      ( command -v flock >/dev/null 2>&1 && flock -x 9 2>/dev/null; printf '%s\n' "$LINE" >> "$INDEX" ) 9>"$CKPT_DIR/.index.lock"
    fi
  fi
fi

# 3. Back-compat single-slot pointer (deprecated; removed in migration 0008).
TMP2=$(mktemp)
cat > "$TMP2" <<EOF
{
  "project_root":    $(json_escape "$PROJECT_ROOT"),
  "checkpoint_path": $(json_escape "$CHECKPOINT_PATH"),
  "session_id":      $(json_escape "$SESSION_ID"),
  "kind":            $(json_escape "$KIND"),
  "ts":              $(json_escape "$TS")
}
EOF
/bin/mv -f "$TMP2" "$HOME/.claude/_last-checkpoint.json"

printf 'wrote: %s\n' "$SESSION_FILE"
[[ -z "${SKIP_INDEX:-}" ]] && printf 'index: %s (%s)\n' "$INDEX" "$MODE" || printf 'index: skipped (guard active)\n'
printf 'back-compat: %s\n' "$HOME/.claude/_last-checkpoint.json"

# 4. Dreams ingestion — only for full /core-dump entries (skip precompact + retro;
#    they're lower-fidelity sources that would dilute cross-session pattern signal).
#    Fire async, never block the writer.
if [[ "$KIND" == "core-dump" && -f "$CHECKPOINT_PATH" ]]; then
  "$HOME/.claude/subconscious/scripts/ingest-checkpoint.sh" "$CHECKPOINT_PATH" \
    --session-id "$SESSION_ID" \
    --project-root "$PROJECT_ROOT" \
    >/dev/null 2>&1 &
  disown 2>/dev/null || true
fi
