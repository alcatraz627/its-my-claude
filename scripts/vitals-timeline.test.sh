#!/usr/bin/env bash
# vitals-timeline.test.sh — checks for the timeline appender.
# Isolation: VITALS_TIMELINE + a stub GCC_VITALS_BIN so no live file is touched and
# the vitals computation is deterministic.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
VT="$HERE/vitals-timeline.sh"

OUT="$(mktemp "${TMPDIR:-/tmp}/vtl-XXXXXX")"; rm -f "$OUT"
STUB="$(mktemp "${TMPDIR:-/tmp}/vstub-XXXXXX.sh")"
cat > "$STUB" <<'EOF'
#!/usr/bin/env bash
echo '{"metabolic":{"metabolized_frac":0.72},"growth":{"rules":39}}'
EOF
chmod +x "$STUB"
export VITALS_TIMELINE="$OUT" GCC_VITALS_BIN="$STUB"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — got [$2] want [$3]"; fi; }

echo "── a reading appends one valid, dated line ──"
bash "$VT" >/dev/null 2>&1
ok "one line written"          "$(wc -l < "$OUT" | tr -d ' ')"                 1
ok "line is valid json"        "$(tail -1 "$OUT" | jq -e . >/dev/null 2>&1 && echo ok)"  ok
ok "carries a day"             "$(tail -1 "$OUT" | jq -e 'has("day")' >/dev/null && echo y)"  y
ok "carries the vitals body"   "$(tail -1 "$OUT" | jq -r '.growth.rules')"     39

echo "── idempotent per day: a second run the same day REPLACES, not appends ──"
bash "$VT" >/dev/null 2>&1
ok "still one line (not two)"  "$(wc -l < "$OUT" | tr -d ' ')"                 1

echo "── --force appends unconditionally ──"
bash "$VT" --force >/dev/null 2>&1
ok "force added a second line" "$(wc -l < "$OUT" | tr -d ' ')"                 2

echo "── a failing vitals bin is caught, not silently written ──"
BAD="$(mktemp "${TMPDIR:-/tmp}/vbad-XXXXXX.sh")"; echo 'echo "not json"' > "$BAD"; chmod +x "$BAD"
GCC_VITALS_BIN="$BAD" bash "$VT" >/dev/null 2>&1
ok "invalid vitals json -> nonzero exit" "$?" 1
rm -f "$BAD"

rm -f "$OUT" "$STUB"
echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ] || exit 1
exit 0
