#!/usr/bin/env bash
# Tests aggregate-votes.sh against a throwaway archive: anonymised ballots must
# be un-mapped through _anon-map.json before scoring.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
T=$(mktemp -d)
trap 'trash "$T" 2>/dev/null' EXIT
pass=0; fail=0
ok()  { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad() { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }

# Three voters; labels: voter-1 -> voter-B, voter-2 -> voter-C, voter-3 -> voter-A.
# Each voter scores itself 9 and the others 5, always through labels.
mk() { # dir
  mkdir -p "$1/04-voting"
  cat > "$1/04-voting/_anon-map.json" <<'EOF'
{"label_of":{"voter-1":"voter-B","voter-2":"voter-C","voter-3":"voter-A"},
 "true_of":{"voter-B":"voter-1","voter-C":"voter-2","voter-A":"voter-3"}}
EOF
  local v lab t
  for v in 1 2 3; do
    case $v in 1) lab=voter-B;; 2) lab=voter-C;; 3) lab=voter-A;; esac
    {
      printf '{"voter_id":"voter-%s","scores":{' "$v"
      local first=1
      for t in voter-A voter-B voter-C; do
        local s=5; [ "$t" = "$lab" ] && s=9
        [ $first = 1 ] || printf ','
        first=0
        printf '"%s":{"quality":%s,"scope_alignment":%s}' "$t" "$s" "$s"
      done
      printf '}}\n'
    } > "$1/04-voting/voter-$v-scores.json"
  done
}

echo "== anonymised ballots are un-mapped =="
mk "$T/anon"
out=$(bash "$HERE/aggregate-votes.sh" "$T/anon" 2>/dev/null)
dropped=$(printf '%s' "$out" | jq -r '.voters_dropped')
expected=$(printf '%s' "$out" | jq -r '.voters_expected')
[ "$dropped" = 0 ] && [ "$expected" = 3 ] && ok "no spurious drops (expected=3 dropped=0)" || bad "expected=$expected dropped=$dropped"
if rg -q '^\| voter-1 \| 9\.00 \| 5\.00 \| \+4\.00' "$T/anon/04-voting/bias-matrix.md"; then
  ok "Own->Self reads 9.00 for voter-1"
else
  bad "bias row for voter-1 wrong: $(rg 'voter-1' "$T/anon/04-voting/bias-matrix.md")"
fi

echo "== a missing map still works on true ids =="
mkdir -p "$T/plain/04-voting"
for v in 1 2; do
  printf '{"voter_id":"voter-%s","scores":{"voter-1":{"quality":7},"voter-2":{"quality":6}}}\n' "$v" > "$T/plain/04-voting/voter-$v-scores.json"
done
out=$(bash "$HERE/aggregate-votes.sh" "$T/plain" 2>/dev/null)
[ "$(printf '%s' "$out" | jq -r '.voters_dropped')" = 0 ] && ok "unanonymised archive unaffected" || bad "plain archive reported drops"

echo "---"
echo "pass=$pass fail=$fail"
[ "$fail" = 0 ]
