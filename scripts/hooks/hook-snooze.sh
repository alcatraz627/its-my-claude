#!/usr/bin/env bash
# hook-snooze.sh — an expiring, scoped, reasoned off-switch for a hook.
#
# Replaces the machine-wide, no-expiry sentinel files for the tune-able hooks.
# Ledger: ~/.claude/hooks/snooze.jsonl, one row per snooze:
#   {id, hook, scope:"global"|"project:<abs path>"|"session:<sid8>", until, by, reason, ts}
#
# Authority (owner D4 note, 2026-09-18): "Always owner approved (Ask tool),
# agent must mention scope, duration and the reason." So `add` requires
# --approved-by owner; the agent calls it only after an AskUserQuestion whose
# option text carried all three. The row records who asked (--by <sid8>).
# The general-window STRONG tier is snoozable at session scope only (D5 note).
#
#   hook-snooze.sh add <hook|group> --for <1h|3d|30d> --scope global|project|session
#                  --reason "…" --approved-by owner [--by <sid8>] [--project <abs>] [--session <sid8>]
#   hook-snooze.sh check <hook> [--project <abs>] [--session <sid8>]   exit 0 = snoozed (prints the row)
#   hook-snooze.sh list            live rows; expired rows are dropped on read
#   hook-snooze.sh lift <id>
# Groups: reviews · fable · atone · prose (see SNZ_GROUPS below).
# Test overrides: SNOOZE_LEDGER, SNOOZE_NOW (epoch).
set -uo pipefail
LEDGER="${SNOOZE_LEDGER:-$HOME/.claude/hooks/snooze.jsonl}"
NOW="${SNOOZE_NOW:-$(date +%s)}"
command -v jq >/dev/null 2>&1 || exit 0
SNZ_GROUPS='{"reviews":["review-gate","codex-review","skill-lint-nudge"],
         "fable":["model-tier-fable"],
         "fable-restrict":["fable-restrict-subagents","fable-restrict-delegation"],
         "atone":["speculative-atone-hint","speculative-atone-stop","atone-circuit-breaker"],
         "prose":["prose-smell","reply-lede","dense-briefing-shapes"]}'
iso() { date -u -r "$1" +%FT%TZ 2>/dev/null || date -u -d "@$1" +%FT%TZ; }
dur_s() { case "$1" in *h) echo $(( ${1%h} * 3600 ));; *d) echo $(( ${1%d} * 86400 ));; *m) echo $(( ${1%m} * 60 ));; *) return 1;; esac; }
live() { # prints live rows (json lines), dropping expired
  [ -f "$LEDGER" ] || return 0
  jq -c --argjson now "$NOW" 'select((.until_epoch // 0) > $now)' "$LEDGER" 2>/dev/null
}

cmd_add() {
  local target="${1:-}"; shift || true
  local dur="" scope="" reason="" approved="" by="${CLAUDE_CODE_SESSION_ID:-agent}" project="$PWD" session="${CLAUDE_CODE_SESSION_ID:-}"
  while [ $# -gt 0 ]; do case "$1" in
    --for) dur="$2"; shift 2;; --scope) scope="$2"; shift 2;; --reason) reason="$2"; shift 2;;
    --approved-by) approved="$2"; shift 2;; --by) by="$2"; shift 2;;
    --project) project="$2"; shift 2;; --session) session="$2"; shift 2;; *) shift;; esac; done
  [ -n "$target" ] && [ -n "$dur" ] && [ -n "$scope" ] && [ -n "$reason" ] || { echo "hook-snooze add: <hook|group> --for <dur> --scope <global|project|session> --reason <text> --approved-by owner" >&2; exit 2; }
  [ "$approved" = "owner" ] || { echo "hook-snooze add: refused, a snooze is owner-approved (AskUserQuestion with scope, duration and reason), pass --approved-by owner after the yes" >&2; exit 3; }
  [ ${#reason} -ge 12 ] || { echo "hook-snooze add: reason under 12 chars is not a reason" >&2; exit 2; }
  local secs; secs=$(dur_s "$dur") || { echo "hook-snooze add: --for takes 30m, 4h, 3d" >&2; exit 2; }
  case "$scope" in
    global) ;; project) scope="project:$project";; session) [ -n "$session" ] || { echo "no session id" >&2; exit 2; }; scope="session:${session:0:8}";;
    *) echo "scope is global, project or session" >&2; exit 2;; esac
  local hooks; hooks=$(printf '%s' "$SNZ_GROUPS" | jq -r --arg t "$target" '.[$t] // [$t] | .[]')
  mkdir -p "$(dirname "$LEDGER")"
  local until=$(( NOW + secs )) id="snz-$(date -u +%Y%m%d-%H%M%S)-$(printf '%04x' $((RANDOM)))"
  for h in $hooks; do
    jq -cn --arg id "$id" --arg h "$h" --arg s "$scope" --argjson ue "$until" --arg u "$(iso "$until")" \
      --arg by "${by:0:8}" --arg r "$reason" --arg ts "$(iso "$NOW")" --arg g "$target" \
      '{id:$id, hook:$h, group:$g, scope:$s, until:$u, until_epoch:$ue, by:$by, approved_by:"owner", reason:$r, ts:$ts}' >> "$LEDGER"
  done
  echo "snoozed: $target ($hooks) $scope until $(iso "$until") · $reason · id $id"
}

cmd_check() {
  local hook="${1:-}"; shift || true
  local project="$PWD" session="${CLAUDE_CODE_SESSION_ID:-}"
  while [ $# -gt 0 ]; do case "$1" in --project) project="$2"; shift 2;; --session) session="$2"; shift 2;; *) shift;; esac; done
  [ -n "$hook" ] || exit 2
  local row
  row=$(live | jq -c --arg h "$hook" --arg p "$project" --arg s "session:${session:0:8}" '
    select(.hook == $h)
    | select(.scope == "global" or .scope == $s or ((.scope | startswith("project:")) and (.scope[8:] as $pre | $p | startswith($pre))))' | head -1)
  [ -n "$row" ] || exit 1
  printf '%s' "$row" | jq -r '"\(.hook) snoozed by \(.by) until \(.until): \(.reason)"'
  exit 0
}

cmd_list() {
  local n=0
  while IFS= read -r row; do
    [ -n "$row" ] || continue; n=$((n+1))
    printf '%s' "$row" | jq -r '"  \(.id)  \(.hook)  \(.scope)  until \(.until)  by \(.by): \(.reason)"'
  done < <(live)
  [ "$n" -eq 0 ] && echo "no live snoozes"
}

cmd_lift() {
  local id="${1:-}"; [ -n "$id" ] && [ -f "$LEDGER" ] || exit 2
  local tmp="$LEDGER.tmp"
  jq -c --arg id "$id" 'select(.id != $id)' "$LEDGER" > "$tmp" && mv -f "$tmp" "$LEDGER"
  echo "lifted: $id"
}

case "${1:-}" in
  add) shift; cmd_add "$@";; check) shift; cmd_check "$@";; list) cmd_list;; lift) shift; cmd_lift "$@";;
  *) sed -n '2,20p' "$0"; exit 64;;
esac
