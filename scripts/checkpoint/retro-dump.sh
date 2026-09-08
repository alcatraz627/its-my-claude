#!/usr/bin/env bash
# scripts/checkpoint/retro-dump.sh — Run /core-dump retroactively on ONE session.
#
# Spawns: claude -p --resume <uuid> --no-session-persistence
#         "/core-dump mini --no-prompt --name retroactive-<uuid8>"
#
# The --no-session-persistence flag prevents the retro run from creating a NEW
# transcript entry. The mini mode keeps cost bounded — we just want a structured
# summary, not a deep analysis.
#
# A run counts as done only when the checkpoint index gains an entry for it. The
# CLI exiting 0 with nothing indexed is a failure (rc 97), because the failure that
# actually happened was quieter than any crash: the csync session of 2026-09-07
# (26 MB transcript) sat in the queue behind 3,871 alphabetically earlier uuids,
# flushed three at a time, while another uuid's run died at the 120 s timeout and
# its orphaned turn was read as the csync one (ledger 5). So the queue now runs
# newest first, expires what is past the scan's age window without spending a
# call, and scales the timeout to the transcript.
#
# Usage:
#   retro-dump.sh --uuid UUID                 # run on a specific uuid
#   retro-dump.sh --queue                     # process the queue (--max-per-run cap)
#   retro-dump.sh --print-timeout UUID        # the timeout the transcript would get
#
# Args:
#   --max-per-run N         default 3 (per invocation; total budget cap)
#   --timeout-seconds N     fixed cap; default scales with transcript size
#   --max-age-days N        default 7; older queue entries move to expired/

set -uo pipefail

UUID=""
QUEUE_MODE=0
MAX_PER_RUN=3
TIMEOUT_S=""
MAX_AGE_DAYS=7
PRINT_TIMEOUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --uuid)            UUID="$2"; shift ;;
    --queue)           QUEUE_MODE=1 ;;
    --max-per-run)     MAX_PER_RUN="$2"; shift ;;
    --timeout-seconds) TIMEOUT_S="$2"; shift ;;
    --max-age-days)    MAX_AGE_DAYS="$2"; shift ;;
    --print-timeout)   PRINT_TIMEOUT="$2"; shift ;;
  esac
  shift
done

CLAUDE_BIN="${CLAUDE_BIN:-claude}"
QUEUE_DIR="${HOME}/.claude/checkpoints/retro-queue"
INDEX="${HOME}/.claude/checkpoints/index.jsonl"
PROJECTS_DIR="${HOME}/.claude/projects"
LOG="${HOME}/.claude/logs/retro-dump.log"
mkdir -p "$(dirname "$LOG")" "$QUEUE_DIR"

now_utc() { date -u "+%Y-%m-%dT%H:%M:%SZ"; }

transcript_of() { # transcript_of <uuid> → path or empty
  local p
  for p in "$PROJECTS_DIR"/*/"$1".jsonl; do
    [[ -f "$p" ]] && { printf '%s' "$p"; return 0; }
  done
  return 1
}

timeout_for() { # timeout_for <uuid> → seconds. 180 s base, +60 s per 4 MB, capped at 900.
  [[ -n "$TIMEOUT_S" ]] && { printf '%s' "$TIMEOUT_S"; return; }
  local tx bytes t
  tx=$(transcript_of "$1") || { printf '180'; return; }
  bytes=$(stat -f %z "$tx" 2>/dev/null || echo 0)
  t=$(( 180 + (bytes / 4194304) * 60 ))
  (( t > 900 )) && t=900
  printf '%s' "$t"
}

indexed_count() { # how many index lines already name this run
  [[ -f "$INDEX" ]] || { printf '0'; return; }
  rg -c "retroactive-${1:0:8}|$1" "$INDEX" 2>/dev/null || printf '0'
}

run_one() {
  local uuid="$1" queue_file="$2"
  local short="${uuid:0:8}"
  local t before after rc
  t=$(timeout_for "$uuid")
  before=$(indexed_count "$uuid")
  printf '[%s] start retro-dump %s (timeout %ss)\n' "$(now_utc)" "$uuid" "$t" >> "$LOG"

  local cmd=(
    "$CLAUDE_BIN"
    -p
    --resume "$uuid"
    --no-session-persistence
    "/core-dump mini --no-prompt --name retroactive-$short"
  )

  if command -v timeout >/dev/null 2>&1; then
    timeout "$t" "${cmd[@]}" >> "$LOG" 2>&1
    rc=$?
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$t" "${cmd[@]}" >> "$LOG" 2>&1
    rc=$?
  else
    "${cmd[@]}" >> "$LOG" 2>&1
    rc=$?
  fi

  # The exit code says the CLI returned; only the index says a checkpoint exists.
  after=$(indexed_count "$uuid")
  if (( rc == 0 )) && (( after <= before )); then
    rc=97
    printf '[%s] NO CHECKPOINT WRITTEN for %s: the CLI exited 0 but the index gained no entry\n' "$(now_utc)" "$uuid" >> "$LOG"
  fi
  printf '[%s] end retro-dump %s (rc=%d)\n' "$(now_utc)" "$uuid" "$rc" >> "$LOG"

  # Remove queue file regardless — if it failed, we don't keep retrying forever.
  # Add to a failed/ subdir for inspection.
  if [[ -n "$queue_file" && -f "$queue_file" ]]; then
    if (( rc == 0 )); then
      rm -f "$queue_file"
    else
      mkdir -p "$QUEUE_DIR/failed"
      mv "$queue_file" "$QUEUE_DIR/failed/$(basename "$queue_file").rc${rc}.$(date +%s)" 2>/dev/null || rm -f "$queue_file"
    fi
  fi

  return $rc
}

if [[ -n "$PRINT_TIMEOUT" ]]; then
  timeout_for "$PRINT_TIMEOUT"; printf '\n'
  exit 0
fi

if (( QUEUE_MODE )); then
  # Expire first, cheaply: a queue entry whose transcript is gone or older than the
  # scan window will never be worth an LLM call, and 3,871 of them in front of a
  # fresh death is how that death never got dumped.
  mkdir -p "$QUEUE_DIR/expired"
  expired=0
  ordered=$(python3 - "$QUEUE_DIR" "$PROJECTS_DIR" "$MAX_AGE_DAYS" "$INDEX" <<'PY'
import glob, json, os, sys, time, shutil
qdir, pdir, max_age, index = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4]
now = time.time()
try:
    index_text = open(index).read()
except Exception:
    index_text = ""
live = []
for qf in glob.glob(os.path.join(qdir, "*.queued")):
    uuid = os.path.basename(qf)[:-7]
    if uuid in index_text:
        # Someone already dumped it by hand (csync, 2026-09-07, via /revive);
        # a second LLM call would only produce a duplicate entry.
        shutil.move(qf, os.path.join(qdir, "expired", os.path.basename(qf)))
        print("INDEXED " + uuid)
        continue
    tx = ""
    try:
        with open(qf) as fp: tx = json.load(fp).get("transcript", "") or ""
    except Exception:
        tx = ""
    if not tx or not os.path.isfile(tx):
        hits = glob.glob(os.path.join(pdir, "*", uuid + ".jsonl"))
        tx = hits[0] if hits else ""
    if not tx or (now - os.path.getmtime(tx)) / 86400 > max_age:
        shutil.move(qf, os.path.join(qdir, "expired", os.path.basename(qf)))
        print("EXPIRED " + uuid)
        continue
    live.append((os.path.getmtime(tx), uuid, qf))
live.sort(reverse=True)          # newest transcript first
for m, uuid, qf in live:
    print("RUN " + uuid + " " + qf)
PY
)
  count=0
  while IFS= read -r ln; do
    [[ -n "$ln" ]] || continue
    case "$ln" in
      EXPIRED\ *|INDEXED\ *) expired=$((expired + 1)); continue ;;
      RUN\ *) ;;
      *) continue ;;
    esac
    (( count >= MAX_PER_RUN )) && break
    uuid=${ln#RUN }; uuid=${uuid%% *}
    qf=${ln#RUN * }
    run_one "$uuid" "$qf"
    count=$((count + 1))
  done <<< "$ordered"
  printf 'processed %d queued retro-dumps (cap=%d), expired %d\n' "$count" "$MAX_PER_RUN" "$expired"
elif [[ -n "$UUID" ]]; then
  run_one "$UUID" ""
else
  printf 'usage: %s --uuid UUID  |  %s --queue  |  %s --print-timeout UUID\n' "$0" "$0" "$0" >&2
  exit 2
fi
