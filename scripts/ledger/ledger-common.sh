#!/usr/bin/env bash
# ledger-common.sh — the one sanctioned writer for gcc event-ledgers.
#
# A ledger is a durable, append-only JSONL stream of low-volume, human-meaningful
# events a subsystem records about its own work (a mistake, an affirmation, a
# proposal). Until now every ledger CLI re-implemented the same plumbing —
# id-stamping, timestamping, flock-serialized append, idempotent git commit,
# kernel seal — by copy-paste. This file holds that plumbing once, extracted
# byte-for-byte from the real callers (atone.sh, affirm.sh, propose.sh), so there
# is one place to fix it and new ledgers inherit it for free.
#
# This is "Layer 1": the primitives. A new single-shape ledger may later also use
# a schema-driven CLI engine ("Layer 2", deferred until a real second caller).
#
# Contract + envelope spec: ~/.claude/skills/shared/ledger-format.md
#
# Source it directly, or get it transitively (atone-common.sh sources it):
#     source "$(dirname "${BASH_SOURCE[0]}")/ledger/ledger-common.sh"

# Guard against double-sourcing.
[ "${__LEDGER_COMMON_LOADED:-0}" = "1" ] && return 0
__LEDGER_COMMON_LOADED=1

# ─── id + timestamp ──────────────────────────────────────────────

# A UTC timestamp in the one format every ledger line uses. Byte-identical to the
# inlined `_ts()` it replaces in atone/affirm/propose.
ledger_ts() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

# A new event id of the form  <prefix>-YYYYMMDD-HHMMSS-<2hex>  — prefixed (unique
# across a cross-domain union), time-sortable, and citable as a deep-link anchor.
# `ledger_id mist` reproduces atone's old `_new_id` exactly; the prefix is the
# only thing that varies between ledgers (mist / aff / prop / puse / pin / alert).
ledger_id() {
  local prefix="$1" hex
  hex=$(printf '%02x' $((RANDOM % 256)))
  printf '%s-%s-%s\n' "$prefix" "$(date -u '+%Y%m%d-%H%M%S')" "$hex"
}

# ─── append + commit ─────────────────────────────────────────────

# Append one JSONL line to a store, serialized against concurrent writers by a
# flock on a separate lock file. The lock is best-effort: a missing flock never
# blocks the write (matches every existing ledger writer). Append works even when
# the store is kernel-sealed with `chflags uappnd` — that is the whole point of
# the append-only seal.
#   ledger_append <store-path> <lock-path> <line>
ledger_append() {
  local store="$1" lock="$2" line="$3"
  (
    flock -x 9 2>/dev/null || true
    printf '%s\n' "$line" >> "$store"
  ) 9>>"$lock"
}

# Commit a ledger's files to its repo, but only if something actually changed —
# safe to call after every write without spamming empty commits. Silent on
# failure (a ledger outside a repo, a detached HEAD) so a write is never blocked
# by git. Byte-identical to atone/affirm's inlined `_git_commit`.
#   ledger_commit <dir> <message> <file>...
ledger_commit() {
  local dir="$1" msg="$2"
  shift 2
  ( cd "$dir" && git add "$@" 2>/dev/null && \
    if ! git diff --cached --quiet 2>/dev/null; then
      git commit -q -m "$msg" 2>/dev/null
    fi ) || true
}

# ─── protection (opt-in, never a side effect of append) ──────────

# Make a ledger file append-only at the kernel level (new lines allowed, edits and
# deletes blocked). Opt-in: a writer calls this from its own `lock` command, never
# as a side effect of `ledger_append`. A ledger that mutates in place (proposals,
# whose status changes via `mv`) must NOT seal.
#   ledger_seal_append <file>...
ledger_seal_append() {
  local f
  for f in "$@"; do
    [ -e "$f" ] && chflags uappnd "$f" 2>/dev/null || true
  done
}

# Freeze a file completely — immutable + read-only (for finished RCA documents).
#   ledger_seal_immutable <file>...
ledger_seal_immutable() {
  local f
  for f in "$@"; do
    if [ -e "$f" ]; then
      chflags uchg "$f" 2>/dev/null || true
      chmod 0444 "$f" 2>/dev/null || true
    fi
  done
}

# ─── jq helpers ──────────────────────────────────────────────────

# Drop empty/null fields from a jq object so sparse ledger lines stay compact.
# Append it to the end of a `jq -cn '{...}'` pipe:
#     jq -cn ... "{ ... } | $LEDGER_STRIP_EMPTY"
# Matches the inlined idiom in propose.sh / emit-event.sh / wal.sh.
LEDGER_STRIP_EMPTY='with_entries(select(.value != "" and .value != null))'

# Turn a separator-delimited string into a JSON array (empties dropped), the way
# every ledger turns a "--tags a b c" string into a tags array.
#   ledger_split_array <sep> <raw>
ledger_split_array() {
  jq -cn --arg s "$1" --arg raw "$2" '$raw | split($s) | map(select(length > 0))'
}
