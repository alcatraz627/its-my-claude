#!/usr/bin/env bash
# resume-inject.sh: put the checkpoint you just wrote back in front of the agent
# after a /clear in the same window, so a plain /clear resumes without /catchup.
#
# Three cases, by the SessionStart source:
#   clear    full injection, but only when this same Claude process wrote a
#            checkpoint within CLEAR_WINDOW_MIN before the clear. The injected
#            text is the checkpoint's Quick Summary and Resume Contract.
#   startup  at most one line: the newest checkpoint for this folder that was
#            never injected or offered, younger than STARTUP_MAX_AGE_HOURS.
#   resume, compact, fork   nothing (the transcript is already there).
# It never arms a goal and never runs /catchup; it says how to do both.
#
# Runtime contract: a SessionStart injector for sessionstart-inject.sh's list
# (NOT registered anywhere yet). Reads the payload on stdin, prints one
# {hookSpecificOutput} object or nothing, always exits 0.
# Config: ~/.claude/state/resume-inject.conf, KEY=VALUE lines (see defaults below).
# Mute: touch ~/.claude/.no-resume-inject

set -uo pipefail
[ -f "$HOME/.claude/.no-resume-inject" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Defaults; the conf file, then the environment, override them. Tests point the
# paths at a sandbox through the environment.
CLEAR_WINDOW_MIN=30
STARTUP_MAX_AGE_HOURS=24
STARTUP_OFFER=on
MAX_CHARS=8000
CONF="${RESUME_INJECT_CONF:-$HOME/.claude/state/resume-inject.conf}"
if [ -f "$CONF" ]; then
  while IFS='=' read -r k v; do
    case "$k" in
      CLEAR_WINDOW_MIN|STARTUP_MAX_AGE_HOURS|MAX_CHARS) case "$v" in ''|*[!0-9]*) ;; *) eval "$k=\$v" ;; esac ;;
      STARTUP_OFFER) case "$v" in on|off) STARTUP_OFFER="$v" ;; esac ;;
    esac
  done < "$CONF"
fi
INDEX="${RESUME_INJECT_INDEX:-$HOME/.claude/checkpoints/index.jsonl}"
SESSIONS_DIR="${RESUME_INJECT_SESSIONS_DIR:-$HOME/.claude/sessions}"
STATE_DIR="${RESUME_INJECT_STATE_DIR:-$HOME/.claude/state/resume-inject}"
NOW="${RESUME_INJECT_NOW:-$(date +%s)}"

INPUT=$(cat 2>/dev/null || echo '{}')
field() { printf '%s' "$INPUT" | jq -r --arg k "$1" '.[$k] // empty' 2>/dev/null; }
src=$(field source)
sid=$(field session_id)
cwd=$(field cwd)
[ -n "$(field agent_id)" ] && exit 0
[ -n "$sid" ] && [ -n "$cwd" ] || exit 0
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
SEEN="$STATE_DIR/seen.log"

# The Claude process this session runs in: the first ancestor that has a
# sessions/<pid>.json. A /clear keeps the process and changes the session id,
# so the pid is what ties the cleared session to the one before it.
claude_pid() {
  if [ -n "${RESUME_INJECT_CLAUDE_PID:-}" ]; then echo "$RESUME_INJECT_CLAUDE_PID"; return; fi
  local p=$$ n=0
  while [ "$n" -lt 12 ] && [ -n "$p" ] && [ "$p" -gt 1 ]; do
    [ -f "$SESSIONS_DIR/$p.json" ] && { echo "$p"; return; }
    p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
    n=$((n + 1))
  done
}
pid=$(claude_pid)

# The session before this one in the same process, from our own ledger. A
# ledger row older than the process itself belongs to a recycled pid.
prev_sid=""
if [ -n "$pid" ]; then
  ledger="$STATE_DIR/pid-$pid.log"
  started=$(jq -r '((.startedAt // 0) / 1000 | floor)' "$SESSIONS_DIR/$pid.json" 2>/dev/null)
  started=${started:-0}
  if [ -f "$ledger" ]; then
    prev_sid=$(awk -v cur="$sid" -v since="$started" '$2 >= since && $1 != cur { s = $1 } END { print s }' "$ledger")
  fi
  printf '%s %s\n' "$sid" "$NOW" >> "$ledger"
fi

# Index rows a resume can use: real dumps, not the shell-only snapshots.
rows() { [ -f "$INDEX" ] && tail -n 400 "$INDEX" | jq -c 'select(.kind != "precompact" and .kind != "session-end" and (.checkpoint_path // "") != "")' 2>/dev/null; }
epoch_of() { printf '%s' "$1" | jq -r '.ts | sub("\\.[0-9]+"; "") | sub("Z$"; "") | strptime("%Y-%m-%dT%H:%M:%S") | mktime' 2>/dev/null; }
seen() { [ -f "$SEEN" ] && awk -v p="$1" '$0 == p { f = 1 } END { exit !f }' "$SEEN"; }

# One heading's section of a checkpoint: from the heading to the next heading
# of the same or higher level.
section() {
  awk -v want="$2" '
    /^#+ / { lvl = index($0, " ") - 1
             if (on && lvl <= keep) on = 0
             if (!on && index($0, want) > 0) { on = 1; keep = lvl } }
    on { print }' "$1"
}

emit() { jq -nc --arg c "$1" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'; }

case "$src" in
  clear)
    [ -n "$prev_sid" ] || exit 0
    best="" best_at=0
    while IFS= read -r row; do
      [ -n "$row" ] || continue
      at=$(epoch_of "$row"); at=${at:-0}
      [ $((NOW - at)) -le $((CLEAR_WINDOW_MIN * 60)) ] || continue
      ckp=$(printf '%s' "$row" | jq -r '.checkpoint_path')
      [ -f "$ckp" ] || continue
      owner=$(printf '%s' "$row" | jq -r '[.session_uuid // "", .session_id // ""] | join(" ")')
      case " $owner " in *" $prev_sid "*) ;; *) continue ;; esac
      [ "$at" -ge "$best_at" ] && { best="$ckp"; best_at="$at"; }
    done <<EOF
$(rows)
EOF
    [ -n "$best" ] || exit 0
    body=$(section "$best" "Quick Summary"; echo; section "$best" "Resume Contract")
    [ "${#body}" -gt "$MAX_CHARS" ] && body="${body:0:$MAX_CHARS}"$'\n… (cut; the file has the rest)'
    echo "$best" >> "$SEEN"
    mins=$(( (NOW - best_at) / 60 ))
    emit "Resumed after /clear from the checkpoint this window wrote ${mins}m ago: $best

$body

This is the checkpoint's own summary and resume contract, not a fresh check. Before acting on it, run /catchup $best if git, PRs, ipc or the goal record may have moved. If it names a goal, offer the /goal line to the owner; do not run goal.sh set or gs link yourself. Carry its standing authorizations as written."
    ;;
  startup)
    [ "$STARTUP_OFFER" = on ] || exit 0
    best="" best_at=0 name=""
    while IFS= read -r row; do
      [ -n "$row" ] || continue
      [ "$(printf '%s' "$row" | jq -r '.project_root')" = "$cwd" ] || continue
      at=$(epoch_of "$row"); at=${at:-0}
      [ $((NOW - at)) -le $((STARTUP_MAX_AGE_HOURS * 3600)) ] || continue
      ckp=$(printf '%s' "$row" | jq -r '.checkpoint_path')
      [ -f "$ckp" ] || continue
      seen "$ckp" && continue
      [ "$at" -ge "$best_at" ] && { best="$ckp"; best_at="$at"; name=$(printf '%s' "$row" | jq -r '.name // "checkpoint"'); }
    done <<EOF
$(rows)
EOF
    [ -n "$best" ] || exit 0
    echo "$best" >> "$SEEN"
    hrs=$(( (NOW - best_at) / 3600 ))
    emit "A checkpoint from this folder, written ${hrs}h ago and not offered before: $name ($best). Mention it to the owner in one line; /catchup $best resumes it. Do not resume it unasked."
    ;;
  *) exit 0 ;;
esac
exit 0
