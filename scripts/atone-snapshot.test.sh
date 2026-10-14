#!/usr/bin/env bash
# atone-snapshot.test.sh: runs the snapshot job against a fake atone dir in a sandbox.
# Never touches ~/.claude/atone or ~/.claude/atone-snapshots.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SB="$(mktemp -d)"
pass=0 fail=0
ok()  { pass=$((pass + 1)); echo "  ok   $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL $1"; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (want '$3', got '$2')"; fi; }
cleanup() { chflags -R nouappnd "$SB" 2>/dev/null; trash "$SB" 2>/dev/null; }
trap cleanup EXIT

SRC="$SB/atone"
ROOT="$SB/snaps"
mkdir -p "$SRC" "$ROOT/2026-05-26" "$ROOT/2026-01-02"
printf '{"id":"a"}\n' > "$SRC/events.jsonl"
printf 'stable\n' > "$SRC/config.json"
cp "$SRC/events.jsonl" "$SRC/config.json" "$ROOT/2026-05-26/"
touch -t 202601020000 "$ROOT/2026-01-02"
printf '{"id":"a"}\n{"id":"b"}\n' > "$SRC/events.jsonl"

BIN="${ATONE_SNAPSHOT_BIN:-$HERE/atone-snapshot.sh}"
run() { ATONE_SNAPSHOT_SRC="$SRC" ATONE_SNAPSHOT_ROOT="$ROOT" bash "$BIN"; }

echo "first run, after a long gap"
run
today="$ROOT/$(date +%Y-%m-%d)"
check "today's snapshot has the current ledger" "$(wc -l < "$today/events.jsonl" | tr -d ' ')" "2"
check "unchanged file is hardlinked to the last snapshot, not the gap day" "$([ "$(stat -f %i "$today/config.json")" = "$(stat -f %i "$ROOT/2026-05-26/config.json")" ] && echo linked || echo copied)" "linked"
check "snapshot files are sealed append-only" "$(stat -f %Sf "$today/events.jsonl")" "uappnd"
check "a snapshot past 30 days moves to _archive" "$([ -d "$ROOT/_archive/2026-01-02" ] && echo moved || echo stayed)" "moved"
check "it is not deleted from the machine" "$([ ! -d "$ROOT/2026-01-02" ] && ls "$ROOT/_archive" | rg -c 2026-01-02 || echo 0)" "1"
check "log says ok" "$(rg -c 'snapshot ok' "$ROOT/_log.txt")" "1"

echo "second run the same day"
run
check "rerun keeps today's snapshot" "$(wc -l < "$today/events.jsonl" | tr -d ' ')" "2"
check "rerun exits cleanly and logs the skip" "$(rg -c 'already taken' "$ROOT/_log.txt")" "1"
check "rerun does not log a second ok" "$(rg -c 'snapshot ok' "$ROOT/_log.txt")" "1"

echo
echo "passed $pass, failed $fail"
[ "$fail" = 0 ]
