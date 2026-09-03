#!/bin/bash
# deployq — a non-blocking deploy queue for any agent with a GCP dependency.
#
# The caller submits a spec and gets a ticket id back immediately. One worker
# drains the spool in order, runs the named pre-checks, the named target, and
# the named post-checks, writes a report, and answers over ipc. Nobody waits.
#
# The safety property: a spec names a TARGET, never a command. Targets resolve
# against targets.tsv to a wrapper script that already lives in the repo, so a
# queue file cannot become a shell. Same for checks.
#
# Design: gcp/contract/v6/deploy-queue.md
set -uo pipefail

Q="${DEPLOYQ_HOME:-$HOME/.claude/deployq}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGETS="$HERE/targets.tsv"
CHECKS="$HERE/checks.sh"
mkdir -p "$Q"/{pending,running,done,reports}

die() { echo "deployq: $*" >&2; exit 1; }
now() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

ticket_id() { printf 'DQ-%s-%s' "$(date '+%H%M%S')" "$(head -c4 /dev/urandom | xxd -p)"; }

# --- resolve a named target to its wrapper, or refuse -----------------------
resolve_target() {
  local name="$1"
  [ -f "$TARGETS" ] || die "no target registry at $TARGETS"
  local row; row=$(awk -F'\t' -v n="$name" '$1==n && $0 !~ /^#/ {print; exit}' "$TARGETS")
  [ -n "$row" ] || return 1
  printf '%s' "$row"
}

cmd_targets() {
  printf '%-24s %-34s %s\n' TARGET REPO WRAPPER
  awk -F'\t' '!/^#/ && NF>=3 {printf "%-24s %-34s %s\n", $1, $2, $3}' "$TARGETS" 2>/dev/null
}

# --- submit: the whole point is that this returns at once -------------------
cmd_submit() {
  local spec="${1:-}"
  [ -n "$spec" ] && [ -f "$spec" ] || die "usage: deployq submit <spec.json>"
  command -v jq >/dev/null || die "jq is required"
  jq empty "$spec" 2>/dev/null || die "spec is not valid json: $spec"

  local target; target=$(jq -r '.target // empty' "$spec")
  [ -n "$target" ] || die "spec has no .target"
  if ! resolve_target "$target" >/dev/null; then
    echo "deployq: REFUSED — target '$target' is not in the registry." >&2
    echo "  A spec names a target, never a command. Register it in $TARGETS first," >&2
    echo "  pointing at a wrapper script that already lives in the repo." >&2
    echo "  Known targets:" >&2; cmd_targets >&2
    exit 2
  fi

  # A submission with no explicit dry_run WILL DEPLOY FOR REAL. Say so at the
  # moment of submitting, because the caller is usually an agent and the cost of
  # learning this afterwards is a live deploy nobody asked for.
  local dry; dry=$(jq -r '.dry_run // false' "$spec")
  [ "$dry" = "true" ] || echo "deployq: NOTE — no \"dry_run\": true in this spec, so this is a REAL deploy of '$target'." >&2

  # THE CONTENDED RESOURCE IS THE SERVICE, NOT THE CALLER'S STRING.
  # gcp-fable registered a second target deploying a branch worktree to the SAME
  # url as the main one, which is legitimate — but batch_key is caller-declared,
  # so two targets on one service could race and the last write would win in
  # silence. Default the batch key to the probe-url so the queue treats one
  # service as one resource whatever the caller called it.
  local purl; purl=$(awk -F'\t' -v n="$target" '$1==n && $0 !~ /^#/ {print $4; exit}' "$TARGETS")
  local shared; shared=$(awk -F'\t' -v u="$purl" '!/^#/ && NF>=4 && $4==u {print $1}' "$TARGETS" | tr '\n' ' ')
  case "$shared" in *" "*[!" "]*) echo "deployq: NOTE — targets [$shared] all deploy to $purl; the queue batches them as ONE service." >&2 ;; esac

  local id; id=$(ticket_id)
  local f="$Q/pending/$(date '+%Y%m%d-%H%M%S')-$id.json"
  jq --arg id "$id" --arg ts "$(now)" \
     --arg bk "$purl" \
     '. + {ticket:$id, submitted_at:$ts, state:"queued", batch_key:(.batch_key // $bk)}' "$spec" > "$f" || die "could not write ticket"
  echo "$id"                                  # the caller reads this and moves on
  echo "deployq: queued $id ($target) -> $f" >&2
}

cmd_status() {
  local id="${1:-}"; [ -n "$id" ] || die "usage: deployq status <ticket>"
  local f; f=$(ls -1 "$Q"/{pending,running,done}/*"$id"*.json 2>/dev/null | head -1)
  [ -n "$f" ] || die "no such ticket: $id"
  jq -r '"\(.ticket)  \(.state)  target=\(.target)  ref=\(.ref // "-")  \(.verdict // "")"' "$f"
  local r="$Q/reports/$id.md"; [ -f "$r" ] && echo "report: $r"
}

cmd_list() {
  printf '%-22s %-12s %-24s %s\n' TICKET STATE TARGET SUBMITTED
  for d in pending running done; do
    for f in "$Q/$d"/*.json; do
      [ -e "$f" ] || continue
      jq -r '[.ticket,.state,.target,.submitted_at]|@tsv' "$f" 2>/dev/null \
        | awk -F'\t' '{printf "%-22s %-12s %-24s %s\n",$1,$2,$3,$4}'
    done
  done
}

case "${1:-help}" in
  submit)  shift; cmd_submit "$@" ;;
  status)  shift; cmd_status "$@" ;;
  list)    shift; cmd_list "$@" ;;
  targets) shift; cmd_targets ;;
  home)    echo "$Q" ;;
  *) cat <<'USAGE'
deployq — non-blocking deploy queue. The caller never waits.

  deployq submit <spec.json>   queue a deploy; prints a TICKET id and returns
  deployq status <ticket>      one line of state, plus the report path
  deployq list                 every ticket, pending / running / done
  deployq targets              the registry: what may be deployed, and by which wrapper

A spec names a TARGET, never a command. Unknown targets are refused, because a
queue that runs arbitrary gcloud is a privilege escalation with a JSON door.

Spec keys: target (required), ref, notify (ipc alias), batch_key, after,
prechecks[], postchecks[], reason.  Design: gcp/contract/v6/deploy-queue.md
USAGE
  ;;
esac
