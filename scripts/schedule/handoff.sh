#!/bin/bash
# Hand a job to the owner instead of opening a terminal for it.
#
# A scheduled job that needs the owner (an audit, a weekly session) raises a
# card: a small JSON file the owner copies a prompt from and runs when they have
# time. The card stays up until the session that ran it marks it done, so a busy
# week never loses it. Switchboard reads ~/.claude/handoffs/*.json; until it
# renders them, a single macOS notification says a card is waiting.
#
# Card file, ~/.claude/handoffs/<name>.json:
#   name, title, prompt, cwd, model, raised_at, carried (times re-raised while
#   still open), done_at (absent while open)
# Tag file, ~/.claude/handoffs/tags/<ts>-<slug>.md: one note for the next
#   weekly session to pick up; the session deletes each tag it handles.
#
# Usage:
#   handoff.sh raise <name> <title> <cwd> <model> <prompt-file>
#   handoff.sh done  <name>          mark the card done (the session's last step)
#   handoff.sh tag   "<note>"        queue a note for the next weekly session
#   handoff.sh list                  open cards and queued tags
set -uo pipefail

DIR="${HANDOFF_DIR:-$HOME/.claude/handoffs}"   # override for tests
TAGS="$DIR/tags"
HIST="$DIR/history.jsonl"
mkdir -p "$TAGS"

write_meta() { [[ -n "${GCC_SCHED_META:-}" ]] && printf '%s\n' "$@" > "$GCC_SCHED_META"; return 0; }
now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

cmd="${1:-list}"; shift || true
case "$cmd" in
  raise)
    name="${1:?name}"; title="${2:?title}"; cwd="${3:?cwd}"; model="${4:?model}"; pfile="${5:?prompt file}"
    [[ -f "$pfile" ]] || { echo "handoff: prompt file not found: $pfile" >&2; write_meta "outcome=failed" "reason=no_prompt"; exit 1; }
    card="$DIR/$name.json"
    carried=0
    if [[ -f "$card" ]] && ! jq -e '.done_at' "$card" >/dev/null 2>&1; then
      carried=$(( $(jq -r '.carried // 0' "$card") + 1 ))
    fi
    jq -n --arg name "$name" --arg title "$title" --arg cwd "$cwd" --arg model "$model" \
          --rawfile prompt "$pfile" --arg at "$(now)" --argjson carried "$carried" \
      '{name:$name, title:$title, prompt:$prompt, cwd:$cwd, model:$model, raised_at:$at, carried:$carried}' \
      > "$card.tmp" && mv -f "$card.tmp" "$card"
    jq -nc --arg ev raised --arg name "$name" --arg at "$(now)" --argjson carried "$carried" \
      '{ev:$ev, name:$name, at:$at, carried:$carried}' >> "$HIST"
    msg="$title is waiting. Copy its prompt from Switchboard, or run: handoff.sh list"
    [[ "$carried" -gt 0 ]] && msg="$title is still waiting (carried over $carried time(s))."
    [[ -n "${HANDOFF_QUIET:-}" ]] || osascript -e "display notification \"$msg\" with title \"Needs you\"" >/dev/null 2>&1 || true
    write_meta "outcome=ok" "reason=handed_off" "detail=carried_$carried"
    echo "raised: $card"
    ;;
  done)
    name="${1:?name}"; card="$DIR/$name.json"
    [[ -f "$card" ]] || { echo "handoff: no card named $name" >&2; exit 1; }
    jq --arg at "$(now)" '.done_at = $at' "$card" > "$card.tmp" && mv -f "$card.tmp" "$card"
    jq -nc --arg ev done --arg name "$name" --arg at "$(now)" '{ev:$ev, name:$name, at:$at}' >> "$HIST"
    echo "done: $name"
    ;;
  tag)
    note="${1:?note}"
    slug=$(printf '%s' "$note" | tr -cs 'A-Za-z0-9' '-' | cut -c1-40)
    f="$TAGS/$(date +%Y%m%d-%H%M%S)-$slug.md"
    printf '%s\n' "$note" > "$f"
    echo "tagged: $f"
    ;;
  list)
    for c in "$DIR"/*.json; do
      [[ -f "$c" ]] || continue
      jq -r '"\(if .done_at then "done" else "OPEN" end)  \(.name)  raised \(.raised_at)\(if (.carried // 0) > 0 then "  carried \(.carried)x" else "" end)  \(.title)"' "$c"
    done
    n=$(find "$TAGS" -name '*.md' | wc -l | tr -d ' ')
    echo "tags queued for the next weekly session: $n"
    ;;
  *) echo "usage: handoff.sh raise|done|tag|list (see header)" >&2; exit 2 ;;
esac
