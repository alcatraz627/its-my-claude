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
# Tag file, ~/.claude/handoffs/tags/<ts>-<slug>.md: one note for the weekly
#   session, markdown with frontmatter (format: features/weekly-tags.md). The
#   session closes each tag it handles with close-tag, which counts down
#   `times`, re-dates it a week out or trashes it, and tells `reply-to`.
#
# Usage:
#   handoff.sh raise <name> <title> <cwd> <model> <prompt-file>
#   handoff.sh done  <name>          mark the card done (the session's last step)
#   handoff.sh tag   "<note>" [--title T] [--kind review|decide|do|fyi] [--after YYYY-MM-DD]
#                    [--times N] [--domain D] [--reply-to ALIAS|PROJECT|MSG] [--ref R]...
#                                    queue a note for the weekly session
#   handoff.sh tags                  queued tags, due ones first, with their fields
#   handoff.sh close-tag <file> "<outcome>"   after handling: count down, re-date or trash, reply
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
    note="${1:?note}"; shift
    title="" kind="review" after="" times=1 domain="" replyto="" refs=""
    while [[ $# -gt 0 ]]; do case "$1" in
      --title) title="$2"; shift 2 ;;
      --kind) kind="$2"; shift 2 ;;
      --after) after="$2"; shift 2 ;;
      --times) times="$2"; shift 2 ;;
      --domain) domain="$2"; shift 2 ;;
      --reply-to) replyto="$2"; shift 2 ;;
      --ref) refs="${refs:+$refs, }$2"; shift 2 ;;
      *) echo "handoff tag: unknown flag $1" >&2; exit 2 ;;
    esac; done
    case "$kind" in review|decide|do|fyi) ;; *) echo "handoff tag: --kind is review, decide, do or fyi" >&2; exit 2 ;; esac
    [[ "$times" =~ ^[1-9][0-9]*$ ]] || { echo "handoff tag: --times is a positive number" >&2; exit 2; }
    [[ -z "$after" || "$after" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { echo "handoff tag: --after is YYYY-MM-DD" >&2; exit 2; }
    [[ -n "$title" ]] || title=$(printf '%s' "$note" | head -n 1 | cut -c1-80)
    # Who tagged it: the ipc alias the session registered, else its session id.
    sid="${CLAUDE_CODE_SESSION_ID:-}"
    by=""
    [[ -n "$sid" ]] && by=$(claude-ipc peers 2>/dev/null \
      | jq -r --arg s "$sid" '[.peers[] | select(.sessionId == $s and (.service | not))][0].alias // empty' 2>/dev/null)
    slug=$(printf '%s' "$title" | tr -cs 'A-Za-z0-9' '-' | cut -c1-40)
    f="$TAGS/$(date +%Y%m%d-%H%M%S)-$slug.md"
    {
      echo "---"
      echo "title: $title"
      echo "kind: $kind"
      [[ -n "$after" ]] && echo "after: $after"
      echo "times: $times"
      [[ -n "$domain" ]] && echo "domain: $domain"
      [[ -n "$sid" ]] && echo "sessions: ${sid:0:8}${by:+ ($by)}"
      [[ -n "$replyto" ]] && echo "reply-to: $replyto"
      [[ -n "$refs" ]] && echo "refs: $refs"
      echo "created: $(now)"
      echo "---"
      echo
      printf '%s\n' "$note"
    } > "$f"
    echo "tagged: $f"
    ;;
  tags)
    today=$(date +%Y-%m-%d)
    found=0
    for f in "$TAGS"/*.md; do
      [[ -f "$f" ]] || continue; found=1
      fm() { awk -v k="$1" 'NR==1&&$0!="---"{exit} NR>1&&$0=="---"{exit} NR>1{ if (index($0, k": ")==1) { print substr($0, length(k)+3); exit } }' "$f"; }
      a=$(fm after); due="due"; [[ -n "$a" && "$a" > "$today" ]] && due="after $a"
      printf '%-12s %-7s x%-2s %-18s %s\n    %s\n' "$due" "$(fm kind)" "$(fm times)" "$(fm reply-to)" "$(fm title)" "$f"
    done
    [[ "$found" = 1 ]] || echo "no tags queued"
    ;;
  close-tag)
    f="${1:?tag file}"; outcome="${2:?outcome}"
    [[ -f "$f" ]] || { echo "handoff: no tag file $f" >&2; exit 1; }
    times=$(awk 'NR>1&&$0=="---"{exit} /^times: /{print $2; exit}' "$f"); times="${times:-1}"
    replyto=$(awk 'NR>1&&$0=="---"{exit} /^reply-to: /{sub(/^reply-to: /,""); print; exit}' "$f")
    title=$(awk 'NR>1&&$0=="---"{exit} /^title: /{sub(/^title: /,""); print; exit}' "$f")
    if [[ "$times" -gt 1 ]]; then
      next=$(date -v+7d +%Y-%m-%d)
      awk -v t="$((times-1))" -v a="$next" -v o="$outcome" -v d="$(date +%Y-%m-%d)" '
        NR==1 {print; next}
        !done && $0=="---" { if (!had) print "after: " a; print; done=1; print ""; print "Session " d ": " o; next }
        !done && /^times: / { print "times: " t; next }
        !done && /^after: / { print "after: " a; had=1; next }
        { print }' "$f" > "$f.tmp" && mv -f "$f.tmp" "$f"
      echo "kept for $((times-1)) more session(s), next after $next: $f"
    else
      trash "$f" 2>/dev/null || mv -f "$f" "$DIR/history-tag-$(basename "$f")"
      echo "closed: $f"
    fi
    # Best effort: tell whoever asked. An alias, a project path or a message id.
    if [[ -n "$replyto" ]]; then
      msg="weekly session handled \"$title\": $outcome"
      case "$replyto" in
        msg-*) claude-ipc reply "$replyto" --from gcc-weekly "$msg" >/dev/null 2>&1 ;;
        /*|~*) claude-ipc send --to-project "${replyto/#\~/$HOME}" --from gcc-weekly --no-reply-expected "$msg" >/dev/null 2>&1 ;;
        *) claude-ipc send --to "$replyto" --from gcc-weekly --no-reply-expected "$msg" >/dev/null 2>&1 ;;
      esac && echo "told $replyto" || echo "could not reach $replyto (left in the report)"
    fi
    ;;
  list)
    for c in "$DIR"/*.json; do
      [[ -f "$c" ]] || continue
      jq -r '"\(if .done_at then "done" else "OPEN" end)  \(.name)  raised \(.raised_at)\(if (.carried // 0) > 0 then "  carried \(.carried)x" else "" end)  \(.title)"' "$c"
    done
    n=$(find "$TAGS" -name '*.md' | wc -l | tr -d ' ')
    echo "tags queued for the next weekly session: $n"
    ;;
  *) echo "usage: handoff.sh raise|done|tag|tags|close-tag|list (see header)" >&2; exit 2 ;;
esac
