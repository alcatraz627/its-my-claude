#!/usr/bin/env bash
# cost-estimate.test.sh — an unmeasured magi run must never report itself as free.
#
# What this protects, in human terms: a full-mode magi run costs real money ($6-12).
# When voter usage never reaches the supervisor, every voter's token count is null,
# the sums treat null as zero, and the run prices itself at $0.00 — which reads as
# "this was free" rather than "nobody measured it". Both 2026-07-10 runs did exactly
# that (archives show total_tokens: 0, cost_usd_est: 0.0 for runs that were not
# free), and nothing in the output said so.
#
# Fixtures, not a live run: exercising this for real costs $6-12 per case. What the
# fixtures deliberately do NOT model: whether a voter actually EMITS usage under a
# given dispatch transport. They pin the reporting side only — given tokens present
# / absent / mixed, does the output tell the truth? The emit side needs a real run.
#
#   bash ~/.claude/scripts/magi/cost-estimate.test.sh

set -uo pipefail
CE="$(dirname "$0")/cost-estimate.sh"

PASS=0; FAIL=0
ok()  { printf '  \033[32mPASS\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }

# Build an archive whose voters have the given token values ("null" for unmeasured).
mk() {
  local dir; dir=$(mktemp -d)
  local voters="" first=1
  for t in "$@"; do
    [ $first -eq 1 ] || voters="$voters,"; first=0
    voters="$voters{\"id\":\"v$RANDOM\",\"model\":\"opus\",\"tokens\":{\"total_tokens\":$t}}"
  done
  printf '{"voters":[%s]}' "$voters" > "$dir/meta.json"
  printf '%s' "$dir"
}

run() { bash "$CE" "$1" 2>"$1/err.txt"; }

echo "== all voters measured =="
A=$(mk 62257 62222 66375)
OUT=$(run "$A")
cov=$(printf '%s' "$OUT" | jq -r '.coverage' 2>/dev/null)
usd=$(printf '%s' "$OUT" | jq -r '.total_usd' 2>/dev/null)
[ "$cov" = "complete" ] && ok "coverage=complete" || bad "coverage='$cov'"
awk -v u="$usd" 'BEGIN{exit !(u>0)}' && ok "priced above zero ($usd)" || bad "priced $usd"
[ -s "$A/err.txt" ] && bad "warned when nothing was wrong" || ok "no spurious warning"
rm -rf "$A"

echo
echo "== every voter unmeasured (the 2026-07-10 shape) =="
B=$(mk null null null null null)
OUT=$(run "$B")
cov=$(printf '%s' "$OUT" | jq -r '.coverage' 2>/dev/null)
un=$(printf '%s' "$OUT" | jq -r '.voters_unmeasured' 2>/dev/null)
case "$cov" in
  none*) ok "coverage says none ('$cov')" ;;
  *)     bad "coverage='$cov' — a \$0.00 run still looks free" ;;
esac
[ "$un" = "5" ] && ok "counts all 5 unmeasured" || bad "voters_unmeasured=$un"
if rg -q "not free" "$B/err.txt" 2>/dev/null; then ok "says out loud it was not free"; else bad "silent about a \$0.00 run"; fi
if rg -q "Agent tool" "$B/err.txt" 2>/dev/null; then ok "names the likely cause"; else bad "no cause named"; fi
rm -rf "$B"

echo
echo "== partial: some measured, some not =="
C=$(mk 62257 null 66375)
OUT=$(run "$C")
cov=$(printf '%s' "$OUT" | jq -r '.coverage' 2>/dev/null)
case "$cov" in
  partial*floor*) ok "coverage marks the cost a floor ('$cov')" ;;
  *)              bad "coverage='$cov' — a partial total reads as complete" ;;
esac
if rg -q "floor" "$C/err.txt" 2>/dev/null; then ok "warns on stderr"; else bad "no warning"; fi
rm -rf "$C"

echo
echo "== --io-split: the flag the spec documents =="
D=$(mk 62257 62222 66375)
bash "$CE" "$D" --io-split 50/50 >/dev/null 2>&1
[ "$(jq -r '.totals.io_split' "$D/meta.json")" = "50/50" ] && ok "--io-split A/B honored" || bad "flag ignored (it was documented but unparsed for months)"
bash "$CE" "$D" --io-split=60/40 >/dev/null 2>&1
[ "$(jq -r '.totals.io_split' "$D/meta.json")" = "60/40" ] && ok "--io-split=A/B honored" || bad "equals form ignored"
IO_SPLIT=50/50 bash "$CE" "$D" >/dev/null 2>&1
[ "$(jq -r '.totals.io_split' "$D/meta.json")" = "50/50" ] && ok "IO_SPLIT env still honored" || bad "env override broke"
# Capture, then match. Piping the script straight into rg looks equivalent but is
# not: `set -o pipefail` propagates the script's own exit 2 as the pipeline's
# status, so `&& ok` never fires and a correctly-rejecting script reads as broken.
ERR=$(bash "$CE" "$D" --io-split banana 2>&1 || true)
printf '%s' "$ERR" | rg -q "want two numbers" && ok "bad split value rejected" || bad "bad split value accepted"
ERR=$(bash "$CE" "$D" --nonsense 2>&1 || true)
printf '%s' "$ERR" | rg -q "unknown option" && ok "unknown option rejected, not ignored" || bad "unknown option silently ignored"

# A bare trailing --io-split used to spin forever: `shift 2` fails with one arg
# left and, absent `set -e`, the parse loop never advances. Cap it — a hang here
# would otherwise hang the whole Phase-11 finalize.
if perl -e 'my $p=fork; if($p==0){setpgrp(0,0); open(STDOUT,">/dev/null"); open(STDERR,">/dev/null"); exec(@ARGV) or exit 127}
            local $SIG{ALRM}=sub{kill "KILL",-$p; exit 9}; alarm 10; waitpid($p,0); exit($?>>8)' \
     bash "$CE" "$D" --io-split; [ $? -ne 9 ]; then
  ok "bare --io-split exits instead of hanging"
else
  bad "bare --io-split HANGS (shift 2 with no value never advances the loop)"
fi
rm -rf "$D"

echo
printf 'passed %d, failed %d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
