#!/usr/bin/env bash
# checkpoint-register.sh — register a Codex handback in the shared checkpoint
# index, so /catchup and /revive can find it the same way they find a Claude
# checkpoint.
#
# Codex writes the handback itself (it is prose, and Codex is good at prose).
# This script writes the POINTER, because hand-composed JSON is how an index
# gets corrupted by a stray quote in a summary line.
#
#   checkpoint-register.sh <handback-path> <summary...>
#
# The pointer lands at ~/.claude/checkpoints/<id>.json with kind="codex", so a
# reader can tell at a glance that this work was done by a different agent under
# weaker guarantees: no WAL, no atone, no hooks.
set -uo pipefail

die() { printf 'checkpoint-register: %s\n' "$1" >&2; exit 1; }

HANDBACK="${1:-}"
[ -n "$HANDBACK" ] || die "usage: checkpoint-register.sh <handback-path> <summary...>"
shift
SUMMARY="$*"
[ -n "$SUMMARY" ] || die "a summary is required; it is what the reader sees in the picker"

# Resolve to absolute — a relative path in the index is unresolvable later, when
# the reader's working directory is somewhere else entirely.
case "$HANDBACK" in
  /*) ;;
  *) HANDBACK="$PWD/$HANDBACK" ;;
esac
[ -f "$HANDBACK" ] || die "no handback at $HANDBACK (write it before registering)"

DIR=$(dirname "$HANDBACK")
ROOT=$(cd "$DIR" && git rev-parse --show-toplevel 2>/dev/null) || ROOT="$DIR"

# codex- prefix keeps these from colliding with Claude session UUIDs and makes
# them greppable as a class.
ID="codex-$(date -u '+%Y%m%dT%H%M%SZ')-$$"
INDEX_DIR="$HOME/.claude/checkpoints"
mkdir -p "$INDEX_DIR" || die "cannot create $INDEX_DIR"
OUT="$INDEX_DIR/$ID.json"

# python3 owns the encoding so quotes, newlines and unicode in the summary
# cannot break the file.
python3 - "$ID" "$ROOT" "$HANDBACK" "$SUMMARY" > "$OUT" <<'PY' || die "failed to write $OUT"
import json, sys, datetime
_id, root, path, summary = sys.argv[1:5]
json.dump({
    "session_id":      _id,
    "session_uuid":    "",
    "project_root":    root,
    "checkpoint_path": path,
    "name":            _id,
    "summary":         summary,
    "kind":            "codex",
    "ts":              datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}, sys.stdout, indent=2)
PY

printf 'registered %s\n  -> %s\n' "$HANDBACK" "$OUT"
