#!/bin/bash
# deployq worker — drains the spool one ticket at a time.
#
# Serialised on purpose: two applies to one Cloud Run service interleave badly
# and the loser is silent. FIFO removes that class of bug for free.
#
# It makes no judgements. It runs named steps, records what happened, writes a
# report, and answers over ipc. A failure ends THAT ticket and nothing else.
set -uo pipefail

Q="${DEPLOYQ_HOME:-$HOME/.claude/deployq}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGETS="$HERE/targets.tsv"
source "$HERE/checks.sh"
mkdir -p "$Q"/{pending,running,done,reports}
ONESHOT="${DEPLOYQ_ONCE:-0}"

now() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
log() { echo "[$(now)] $*"; }

notify() {  # never let a verdict die unheard
  local alias="$1" msg="$2"
  [ -n "$alias" ] && [ "$alias" != "null" ] || return 0
  command -v claude-ipc >/dev/null || return 0
  claude-ipc send --to "$alias" "$msg" >/dev/null 2>&1 || true
}

finish() {  # $1 file  $2 state  $3 verdict
  local f="$1" state="$2" verdict="$3"
  local id; id=$(jq -r .ticket "$f")
  jq --arg s "$state" --arg v "$verdict" --arg t "$(now)" \
     '. + {state:$s, verdict:$v, finished_at:$t}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  mv "$f" "$Q/done/$(basename "$f")"
  notify "$(jq -r '.notify // empty' "$Q/done/$(basename "$f")")" \
    "deployq $id: $state — $verdict. Report: $Q/reports/$id.md"
  log "$id -> $state ($verdict)"
}

run_ticket() {
  local f="$1"
  local id target ref notify_to
  id=$(jq -r .ticket "$f"); target=$(jq -r .target "$f")
  ref=$(jq -r '.ref // ""' "$f"); notify_to=$(jq -r '.notify // ""' "$f")
  local rpt="$Q/reports/$id.md"
  # Mark it RUNNING on disk. It used to sit in pending/ for the whole deploy, so
  # `status` said "queued" while a Cloud Build was in flight — I misread that
  # myself, and gcp-fable hit it too. The running/ directory existed and was
  # never used.
  jq '. + {state:"running"}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  local rf="$Q/running/$(basename "$f")"; mv "$f" "$rf"; f="$rf"

  {
    echo "# deployq $id"; echo
    echo "- target: \`$target\`"; echo "- ref requested: \`${ref:-HEAD}\`"
    echo "- submitted: $(jq -r .submitted_at "$f")"
    echo "- reason: $(jq -r '.reason // "-"' "$f")"; echo
  } > "$rpt"

  # --- chaining: hold until the predecessor is done ------------------------
  local after; after=$(jq -r '.after // ""' "$f")
  if [ -n "$after" ]; then
    local pf; pf=$(ls -1 "$Q"/done/*"$after"*.json 2>/dev/null | head -1)
    if [ -z "$pf" ]; then log "$id waits on $after"; return 3; fi
    if [ "$(jq -r .state "$pf")" != "done" ]; then
      echo "## Held" >> "$rpt"
      echo "Predecessor \`$after\` did not succeed, so this was not run." >> "$rpt"
      finish "$f" "failed:predecessor" "predecessor $after did not succeed"; return 0
    fi
  fi

  # --- resolve the target; refuse anything not registered ------------------
  local row repo wrapper
  row=$(awk -F'\t' -v n="$target" '$1==n && $0 !~ /^#/ {print; exit}' "$TARGETS")
  if [ -z "$row" ]; then
    echo "## Refused" >> "$rpt"; echo "Target \`$target\` is not registered." >> "$rpt"
    finish "$f" "failed:unregistered-target" "target not in registry"; return 0
  fi
  repo=$(echo "$row" | cut -f2); wrapper=$(echo "$row" | cut -f3)

  # --- prechecks -----------------------------------------------------------
  echo "## Pre-checks" >> "$rpt"
  local c out rc
  for c in $(jq -r '(.prechecks // [])[]' "$f"); do
    out=$(run_check "$c" "$repo" "$ref" "$target" 2>&1); rc=$?
    printf -- '- `%s` -> %s\n' "$c" "$([ $rc -eq 0 ] && echo pass || echo FAIL)" >> "$rpt"
    [ -n "$out" ] && printf '      %s\n' "$out" >> "$rpt"
    if [ $rc -ne 0 ]; then
      finish "$f" "failed:precheck" "precheck $c failed"; return 0
    fi
  done
  [ "$(jq -r '(.prechecks // [])|length' "$f")" = "0" ] && echo "- none declared" >> "$rpt"

  # --- deploy --------------------------------------------------------------
  echo >> "$rpt"; echo "## Deploy" >> "$rpt"
  # Dry run is a property of the TICKET, not of the worker's environment.
  # It lived in the env first and that was a real defect: a test submission and
  # a live one were indistinguishable to the worker, so testing the queue
  # deployed for real. Found by doing exactly that. The env var still works for
  # a one-shot drain, but the spec is what a caller controls.
  local dry; dry=$(jq -r '.dry_run // false' "$f")
  if [ "$dry" = "true" ] || [ "${DEPLOYQ_DRYRUN:-0}" = "1" ]; then
    echo "- DRY RUN: would run \`$wrapper\` in \`$repo\`" >> "$rpt"
    rc=0; out="dry run"
  else
    out=$(cd "$repo" 2>/dev/null && eval "$wrapper" 2>&1 | tail -40); rc=$?
  fi
  printf -- '- wrapper: `%s`\n- exit: %s\n' "$wrapper" "$rc" >> "$rpt"
  [ -n "$out" ] && { echo '```'; echo "$out"; echo '```'; } >> "$rpt"
  if [ $rc -ne 0 ]; then finish "$f" "failed:deploy" "wrapper exited $rc"; return 0; fi

  # --- postchecks ----------------------------------------------------------
  echo >> "$rpt"; echo "## Post-checks" >> "$rpt"
  # A DRY RUN DEPLOYED NOTHING, so post-checking the live service reports on the
  # OLD revision and calls it "deployed but not trusted", which is simply false.
  # gcp-fable caught this on the first dry ticket. Skip them and say why.
  if [ "$dry" = "true" ] || [ "${DEPLOYQ_DRYRUN:-0}" = "1" ]; then
    echo "- SKIPPED: this was a dry run, so nothing was deployed and the live" >> "$rpt"
    echo "  service still serves the previous revision. Post-checking it would" >> "$rpt"
    echo "  report on something this ticket did not do." >> "$rpt"
    finish "$f" "done" "dry run: prechecks passed, nothing deployed"; return 0
  fi
  local bad=0
  for c in $(jq -r '(.postchecks // [])[]' "$f"); do
    out=$(run_check "$c" "$repo" "$ref" "$target" 2>&1); rc=$?
    printf -- '- `%s` -> %s\n' "$c" "$([ $rc -eq 0 ] && echo pass || echo FAIL)" >> "$rpt"
    [ -n "$out" ] && printf '      %s\n' "$out" >> "$rpt"
    [ $rc -ne 0 ] && bad=1
  done
  [ "$(jq -r '(.postchecks // [])|length' "$f")" = "0" ] && echo "- none declared" >> "$rpt"

  if [ $bad -ne 0 ]; then
    # deployed but not trusted: its own state, because those are different claims
    finish "$f" "failed:postcheck" "DEPLOYED BUT NOT TRUSTED — a post-check failed"
  else
    finish "$f" "done" "deployed and post-checked"
  fi
}

# --- batching: same key + neither started = collapse to the newest ----------
collapse_batch() {
  local f="$1" key; key=$(jq -r '.batch_key // ""' "$f")
  [ -n "$key" ] || return 0
  # A ticket that declares `after` has stated an ORDERING INTENT, and collapsing
  # it would discard a step the caller deliberately sequenced. Batching is for
  # callers who did not say they cared about order.
  [ "$(jq -r '.after // ""' "$f")" = "" ] || { log "$(jq -r .ticket "$f") not collapsible: it declares after"; return 0; }
  local mine; mine=$(basename "$f")
  local other
  for other in "$Q"/pending/*.json; do
    [ -e "$other" ] || continue
    [ "$(basename "$other")" = "$mine" ] && continue
    [ "$(jq -r '.batch_key // ""' "$other")" = "$key" ] || continue
    # the newer file wins; this one is superseded and its caller is told why
    if [[ "$(basename "$other")" > "$mine" ]]; then
      local id nid; id=$(jq -r .ticket "$f"); nid=$(jq -r .ticket "$other")
      jq --arg n "$nid" --arg t "$(now)" \
        '. + {state:"superseded", verdict:("batched into " + $n), finished_at:$t}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
      mv "$f" "$Q/done/$(basename "$f")"
      notify "$(jq -r '.notify // empty' "$Q/done/$(basename "$f")")" \
        "deployq $id: SUPERSEDED — batched into $nid on key '$key'. Not dropped; $nid deploys the newer ref."
      log "$id superseded by $nid (batch $key)"
      return 1
    fi
  done
  return 0
}

# A ticket found in running/ at startup was INTERRUPTED — this worker died or was
# restarted mid-deploy. Its state is genuinely UNKNOWN: the wrapper may have
# submitted a build that is still landing server-side. Re-running it blindly
# races two deploys onto one service, which is the exact failure this queue
# exists to prevent, caused by the queue. Unknown is not "retry", so it is
# surfaced for a decision instead. (Found by restarting mid-deploy and watching
# the worker start a second build.)
shopt -s nullglob
for orphan in "$Q"/running/*.json; do
  oid=$(jq -r .ticket "$orphan")
  jq --arg t "$(now)" '. + {state:"failed:interrupted", verdict:"the worker restarted mid-deploy; whether the build landed is UNKNOWN — check the service before resubmitting", finished_at:$t}' \
    "$orphan" > "$orphan.tmp" && mv "$orphan.tmp" "$orphan"
  mv "$orphan" "$Q/done/$(basename "$orphan")"
  notify "$(jq -r '.notify // empty' "$Q/done/$(basename "$orphan")")" \
    "deployq $oid: FAILED:INTERRUPTED — the worker restarted mid-deploy. Whether the build landed is UNKNOWN. Check the live service before resubmitting; do NOT assume it failed."
  log "$oid recovered as failed:interrupted (worker restarted mid-deploy)"
done
shopt -u nullglob

log "deployq worker up (spool $Q)"
while :; do
  shopt -s nullglob
  for f in "$Q"/pending/*.json; do
    collapse_batch "$f" || continue
    run_ticket "$f" || true
  done
  shopt -u nullglob
  [ "$ONESHOT" = "1" ] && { log "one-shot drain complete"; exit 0; }
  sleep 5
done
