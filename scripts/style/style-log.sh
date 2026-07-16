#!/usr/bin/env bash
# style-log.sh — one appender for style-quality telemetry (critic passes,
# watcher fires, user-caught misses). Records land in
# ~/.claude/logs/style-watch.jsonl; the critic-pass record doubles as the
# voice-passed marker the async watcher checks (keyed by artifact sha256).
#
# Usage:
#   style-log.sh --kind critic-pass|watcher-fire|watcher-skip|user-caught \
#                [--surface <class/tier>] [--artifact <path>] [--model <m>] \
#                [--tokens N] [--findings N] [--entry <thes-id>] [--heeded yes|no|unknown]
#   style-log.sh --check <path>     # exit 0 if a critic-pass exists for the
#                                   # file's CURRENT sha256 (watcher dedupe)
set -uo pipefail
LOG="${STYLE_WATCH_LOG:-$HOME/.claude/logs/style-watch.jsonl}"
mkdir -p "$(dirname "$LOG")"
command -v jq >/dev/null 2>&1 || exit 0

sha() { shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1; }

if [ "${1:-}" = "--check" ]; then
  f="${2:-}"; [ -f "$f" ] || exit 1
  s=$(sha "$f"); [ -n "$s" ] || exit 1
  [ -f "$LOG" ] || exit 1
  jq -e --arg s "$s" 'select(.kind=="critic-pass" and .sha==$s)' "$LOG" >/dev/null 2>&1
  exit $?
fi

kind=""; surface=""; artifact=""; model=""; tokens=0; findings=0; entry=""; heeded="unknown"
while [ $# -gt 0 ]; do
  case "$1" in
    --kind) kind="$2"; shift 2 ;;
    --surface) surface="$2"; shift 2 ;;
    --artifact) artifact="$2"; shift 2 ;;
    --model) model="$2"; shift 2 ;;
    --tokens) tokens="$2"; shift 2 ;;
    --findings) findings="$2"; shift 2 ;;
    --entry) entry="$2"; shift 2 ;;
    --heeded) heeded="$2"; shift 2 ;;
    *) shift ;;
  esac
done
[ -n "$kind" ] || { echo "--kind required" >&2; exit 2; }

s=""; [ -n "$artifact" ] && [ -f "$artifact" ] && s=$(sha "$artifact")
jq -cn --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg kind "$kind" \
  --arg sid "${CLAUDE_CODE_SESSION_ID:-}" --arg surface "$surface" \
  --arg artifact "$artifact" --arg sha "$s" --arg model "$model" \
  --argjson tokens "${tokens:-0}" --argjson findings "${findings:-0}" \
  --arg entry "$entry" --arg heeded "$heeded" \
  '{ts:$ts, kind:$kind, sid:$sid, surface:$surface, artifact:$artifact, sha:$sha,
    model:$model, tokens:$tokens, findings:$findings, entry:$entry, heeded:$heeded}' >> "$LOG"
