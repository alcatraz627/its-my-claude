#!/usr/bin/env bash
# ledger-prune.test.sh: proves pruning archives, never truncates in place, never deletes,
# and never touches a protected, sealed or unnamed ledger. Sandbox only, no live ledger is read.
#   bash ledger-prune.test.sh                 test the real tool
#   LEDGER_PRUNE_BIN=/path/mutant.py bash ledger-prune.test.sh    test a mutated copy (must fail)
set -uo pipefail

BIN="${LEDGER_PRUNE_BIN:-$(dirname "${BASH_SOURCE[0]}")/ledger-prune.py}"
SB="$(mktemp -d)"
NOW="2026-10-15T00:00:00Z"
pass=0 fail=0

ok()  { pass=$((pass + 1)); echo "  ok   $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL $1"; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (want '$3', got '$2')"; fi; }
ino() { stat -f %i "$1"; }

cleanup() {
  chflags -R nouappnd "$SB" 2>/dev/null
  trash "$SB" 2>/dev/null
}
trap cleanup EXIT

mkdir -p "$SB/root/logs" "$SB/root/vault" "$SB/root/misc" "$SB/arch"
mk() {  # mk <file> : 3 old rows, 2 new rows, 1 row with no timestamp
  printf '%s\n' \
    '{"ts":"2026-01-01T00:00:00Z","n":1}' \
    '{"ts":"2026-02-01T00:00:00Z","n":2}' \
    '{"ts":"2026-02-15T00:00:00Z","n":3}' \
    '{"ts":"2026-10-10T00:00:00Z","n":4}' \
    '{"ts":"2026-10-14T00:00:00Z","n":5}' \
    '{"n":6,"note":"no timestamp"}' > "$1"
}
mk "$SB/root/logs/rot.jsonl"
mk "$SB/root/vault/protected.jsonl"
mk "$SB/root/vault/sealed.jsonl"
mk "$SB/root/misc/unnamed.jsonl"
mk "$SB/root/logs/sizecap.jsonl"
chflags uappnd "$SB/root/vault/sealed.jsonl"

cat > "$SB/cfg.json" <<EOF
{"skip": [], "rules": [
  {"path": "$SB/root/vault/protected.jsonl", "protect": true, "max_age_days": 30, "why": "test"},
  {"path": "$SB/root/vault/sealed.jsonl", "max_age_days": 30},
  {"path": "$SB/root/logs/sizecap.jsonl", "max_mb": 0.00005},
  {"path": "$SB/root/logs/rot.jsonl", "max_age_days": 30}
]}
EOF

run() { python3 "$BIN" "$@" --config "$SB/cfg.json" --root "$SB/root" --archive-dir "$SB/arch" --now "$NOW"; }
sum() { shasum "$1" | cut -d' ' -f1; }

before_rot=$(sum "$SB/root/logs/rot.jsonl")
before_prot=$(sum "$SB/root/vault/protected.jsonl")
before_seal=$(sum "$SB/root/vault/sealed.jsonl")
before_unn=$(sum "$SB/root/misc/unnamed.jsonl")
ino_rot=$(ino "$SB/root/logs/rot.jsonl")

echo "dry run"
run plan > "$SB/plan.txt"
check "plan leaves the ledger byte-identical" "$(sum "$SB/root/logs/rot.jsonl")" "$before_rot"
check "plan creates no archive" "$(ls "$SB/arch" | wc -l | tr -d ' ')" "0"
check "bare invocation is the dry run" "$(python3 "$BIN" --config "$SB/cfg.json" --root "$SB/root" --archive-dir "$SB/arch" --now "$NOW" | rg -c 'rotate')" "$(rg -c '^rotate' "$SB/plan.txt")"
check "plan reports the 3 old rows" "$(run plan --json | jq '[.[] | select(.path|endswith("logs/rot.jsonl"))][0].would_archive')" "3"

echo "apply"
run apply > "$SB/apply.txt"
check "old rows leave the live ledger" "$(wc -l < "$SB/root/logs/rot.jsonl" | tr -d ' ')" "3"
check "live ledger keeps recent and untimestamped rows" "$(rg -c '"n":(4|5|6)' "$SB/root/logs/rot.jsonl")" "3"
check "live ledger was replaced, not truncated in place (new inode)" "$([ "$(ino "$SB/root/logs/rot.jsonl")" != "$ino_rot" ] && echo new || echo same)" "new"
arch_dir=$(ls -d "$SB"/arch/*rot.jsonl 2>/dev/null | head -1)
archived=$(gzip -dc "$arch_dir"/*.jsonl.gz | wc -l | tr -d ' ')
check "the 3 old rows are in the archive (nothing deleted)" "$archived" "3"
check "live plus archive equals the original 6 rows" "$(( archived + $(wc -l < "$SB/root/logs/rot.jsonl" | tr -d ' ') ))" "6"
check "archive holds the exact old rows" "$(gzip -dc "$arch_dir"/*.jsonl.gz | jq -s 'map(.n) | sort | join(",")' -r)" "1,2,3"
check "rows are filed by their month" "$(ls "$arch_dir" | tr '\n' ' ')" "2026-01.jsonl.gz 2026-02.jsonl.gz "

echo "exclusions"
check "protected ledger untouched" "$(sum "$SB/root/vault/protected.jsonl")" "$before_prot"
check "kernel-sealed ledger untouched even with an age rule" "$(sum "$SB/root/vault/sealed.jsonl")" "$before_seal"
check "ledger with no rule untouched" "$(sum "$SB/root/misc/unnamed.jsonl")" "$before_unn"
check "nothing archived for the excluded three" "$(ls "$SB/arch" | rg -c 'protected|sealed|unnamed' || echo 0)" "0"

echo "size cap"
sz_first=$(head -1 "$SB/root/logs/sizecap.jsonl" | jq -r '.n')
check "size cap keeps the newest rows (first kept row is not row 1)" "$([ "$sz_first" != "1" ] && echo yes || echo no)" "yes"

echo "idempotence"
run apply > "$SB/apply2.txt"
check "second apply moves nothing more from rot.jsonl" "$(gzip -dc "$arch_dir"/*.jsonl.gz | wc -l | tr -d ' ')" "3"

echo
echo "passed $pass, failed $fail"
[ "$fail" = 0 ]
