#!/usr/bin/env bash
# Tells a starting session which of its mechanical gates are switched off.
#
# Every hook in this config documents a touch-file mute (~/.claude/.no-<thing> or
# ~/.claude/.<thing>-off), and the always-loaded rules promise the gate as if it
# were running. Nothing listed which mutes were actually present, so an agent
# read "enforced by hook X" while X was silent. gcc-map v4 (2026-09-05) found five
# present, two of them muting always-loaded rules; the owner kept them and asked
# for this line instead (gate 1a).
#
# Runs as one injector inside sessionstart-inject.sh: reads the SessionStart payload
# on stdin (ignored), prints {"additionalContext": "..."} when any sentinel is
# present, nothing otherwise. Always exits 0.
#
# The "mutes" column is derived, not hard-coded: the first script under scripts/ or
# hinters/ that names the sentinel is taken as its owner. Enabler sentinels
# (.allow-*) are not mutes and are not listed. Guard: muted-gates.test.sh.

set -uo pipefail

ROOT="${MUTED_GATES_ROOT:-$HOME/.claude}"
now=$(date +%s)
rows=""

owner_of() {
  # The script that documents the mute ("Mute: touch ~/.claude/<name>") wins; any
  # script that merely mentions the name is the fallback; "?" when nothing does.
  local hit
  hit=$(rg -l --glob '*.sh' -m 1 "Mute:.*$1" "$ROOT/scripts" "$ROOT/hinters" 2>/dev/null | head -1)
  [ -z "$hit" ] && hit=$(rg -l --glob '*.sh' -m 1 -F "$1" "$ROOT/scripts" "$ROOT/hinters" 2>/dev/null | head -1)
  [ -n "$hit" ] && basename "$hit" || echo "?"
}

age_of() {
  local m d
  m=$(stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo "$now")
  d=$(( (now - m) / 86400 ))
  if [ "$d" -eq 0 ]; then echo "today"; elif [ "$d" -eq 1 ]; then echo "1d"; else echo "${d}d"; fi
}

for f in "$ROOT"/.no-* "$ROOT"/.*-off; do
  [ -e "$f" ] || continue
  name=$(basename "$f")
  # The lane's own mute can never be seen from inside the lane; skip the noise.
  [ "$name" = ".no-sessionstart-inject" ] && continue
  rows="${rows}${rows:+ · }${name} ($(age_of "$f"), mutes $(owner_of "$name"))"
done

[ -z "$rows" ] && exit 0

# Plain text, no rails: this is a one-line notice, not a gate (callout-boxes.md).
msg="[muted-gates] Mute sentinels present at ~/.claude, so these hooks are OFF machine-wide and their rules bind as text only: ${rows}. Remove a file to re-arm its gate; an agent never adds one."
jq -cn --arg m "$msg" '{additionalContext: $m}'
exit 0
