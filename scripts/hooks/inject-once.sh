#!/usr/bin/env bash
# inject-once.sh: lets an injector say a thing once and stay quiet after that.
#
# Several hooks used to repeat the same text into the model's context on every
# turn, tool call or session. They source this file and ask whether they have
# already spoken for a given key. State is one empty file per key, kept under
# ~/.claude/.inject-once/<scope>/<period>/, so deleting the directory simply
# makes every injector speak once more.
#
#   inject_once_session <sid> <scope> <key>   0 = first time this session, 1 = already shown
#   inject_once_day     <scope> <key>         0 = first time today, 1 = already shown
#   inject_once_changed <scope> <value>       0 = value differs from the last one shown (and stores it)
#   inject_once_reset_session <sid>           forget what this session was shown (after /clear)
#
# Fails open: when the state directory cannot be written the answer is 0, so a
# broken disk makes a hook repeat itself and never go silent.
# Python twin: subconscious/hooks/pre-tool-use.sh keeps the same layout.

INJECT_ONCE_DIR="${INJECT_ONCE_DIR:-$HOME/.claude/.inject-once}"

_inject_once_hash() { printf '%s' "$1" | cksum | awk '{print $1 "-" $2}'; }

inject_once_first() { # <scope> <period> <key>
  local d="$INJECT_ONCE_DIR/$1/$2" h
  h=$(_inject_once_hash "$3")
  [ -e "$d/$h" ] && return 1
  if [ ! -d "$d" ]; then
    mkdir -p "$d" 2>/dev/null || return 0
    # A new period directory is the moment to drop ones older than three days.
    find "$INJECT_ONCE_DIR/$1" -mindepth 1 -maxdepth 1 -type d -mtime +3 -exec rm -rf {} + 2>/dev/null || true
  fi
  : > "$d/$h" 2>/dev/null || return 0
  return 0
}

inject_once_session() { # <sid> <scope> <key>
  local sid8="${1:0:8}"
  inject_once_first "$2" "s-${sid8:-nosid}" "$3"
}

inject_once_day() { # <scope> <key>
  inject_once_first "$1" "d-$(date +%F)" "$2"
}

inject_once_changed() { # <scope> <value>
  local f="$INJECT_ONCE_DIR/$1/last"
  [ "$(cat "$f" 2>/dev/null)" = "$2" ] && return 1
  mkdir -p "$INJECT_ONCE_DIR/$1" 2>/dev/null || return 0
  printf '%s' "$2" > "$f" 2>/dev/null || true
  return 0
}

inject_once_reset_session() { # <sid>
  local sid8="${1:0:8}"
  [ -n "$sid8" ] || return 0
  find "$INJECT_ONCE_DIR" -mindepth 2 -maxdepth 2 -type d -name "s-$sid8" -exec rm -rf {} + 2>/dev/null || true
}
