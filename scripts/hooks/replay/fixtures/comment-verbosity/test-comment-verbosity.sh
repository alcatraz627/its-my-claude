#!/usr/bin/env bash
# test-comment-verbosity.sh — synthetic acceptance suite for
# guard-comment-verbosity.sh. Synthesizes PostToolUse payloads (the hook reads the
# ADDED content, not the on-disk tree, so no project scaffolding is needed) and
# asserts fire/suppress. This is the AUTHORITATIVE gate; the corpus replay is only
# a rate sanity-check. Non-zero exit on any FAIL.
#
# Usage: bash test-comment-verbosity.sh
set -uo pipefail

HOOK="$HOME/.claude/scripts/hooks/guard-comment-verbosity.sh"
[ -f "$HOOK" ] || { echo "hook not found: $HOOK"; exit 2; }

PASS=0; FAIL=0
WARN="${TMPDIR:-/tmp}/cv-suite-warn-$$.jsonl"
cleanup() { trash "$WARN" 2>/dev/null || true; }
trap cleanup EXIT

# run <tool> <file_path> <content>  → hook stdout. Telemetry isolated to $WARN.
run() {
  local tool="$1" fp="$2" body="$3" payload key
  key="content"; [ "$tool" = "Edit" ] && key="new_string"
  payload=$(jq -nc --arg t "$tool" --arg fp "$fp" --arg b "$body" --arg k "$key" \
    '{tool_name:$t, tool_input:{file_path:$fp, ($k):$b}}')
  printf '%s' "$payload" | WARN_LOG_STORE="$WARN" bash "$HOOK" 2>/dev/null
}
fired() { case "$1" in *additionalContext*) return 0 ;; *) return 1 ;; esac; }
ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; [ -n "${2:-}" ] && printf '        got: %s\n' "${2:0:160}"; }
assert_fires()      { if fired "$2"; then ok "$1"; else bad "$1" "expected FIRE, got silence"; fi; }
assert_suppressed() { if fired "$2"; then bad "$1" "$2"; else ok "$1"; fi; }

# Build an N-prose-line comment block of a given flavor.
py_docstring() { local n="$1" i out='def f(x):
    """'; for i in $(seq 1 "$n"); do out+="
    Sentence number $i of the docstring body."; done; out+='
    """
    return x'; printf '%s' "$out"; }

py_hash_run() { local n="$1" i out='def g():'; for i in $(seq 1 "$n"); do out+="
    # comment line number $i explaining a step"; done; out+='
    return 1'; printf '%s' "$out"; }

js_block() { local n="$1" i out='function h() {
  /*'; for i in $(seq 1 "$n"); do out+="
   * Sentence number $i of the block comment."; done; out+='
   */
  return 1;
}'; printf '%s' "$out"; }

js_slash_run() { local n="$1" i out='function j() {'; for i in $(seq 1 "$n"); do out+="
  // slash comment line number $i doing work"; done; out+='
  return 1;
}'; printf '%s' "$out"; }

echo "=== guard-comment-verbosity.sh — synthetic acceptance suite ==="

# --- SHOULD FIRE (clear over-verbosity) ---
out=$(run Write /tmp/p/a.py "$(py_docstring 14)")
assert_fires "1  Python essay docstring (14 lines) FIRES" "$out"

out=$(run Write /tmp/p/b.py "$(py_hash_run 11)")
assert_fires "2  Python # comment run (11 lines) FIRES" "$out"

out=$(run Write /tmp/p/c.ts "$(js_block 13)")
assert_fires "3  JS block-comment essay (13 lines) FIRES" "$out"

out=$(run Write /tmp/p/d.ts "$(js_slash_run 11)")
assert_fires "4  JS // comment run (11 lines) FIRES" "$out"

# Fires through an Edit new_string too (not just Write).
out=$(run Edit /tmp/p/e.py "$(py_docstring 14)")
assert_fires "5  essay via Edit new_string FIRES" "$out"

# 20-line module docstring exceeds the module allowance (16) → FIRES
out=$(run Write /tmp/p/mod.py "$(printf '"""'; for i in $(seq 1 20); do printf '\nModule orientation sentence %s here.' "$i"; done; printf '\n"""\nimport os\n')")
assert_fires "6  oversize module docstring (20>16) FIRES" "$out"

# --- SHOULD STAY SILENT (precision guards) ---
out=$(run Write /tmp/p/f.py 'x = 1  # a single trailing note')
assert_suppressed "7  single-line comment SILENT" "$out"

out=$(run Write /tmp/p/g.py "$(py_docstring 3)")
assert_suppressed "8  normal 3-line docstring SILENT" "$out"

out=$(run Write /tmp/p/h.py "$(py_hash_run 5)")
assert_suppressed "9  short 5-line # run SILENT" "$out"

# A 9-line comment run (a genuinely-needed long explanation) must stay SILENT —
# the threshold was tightened to >10 so these no longer fire (corpus FP finding).
out=$(run Write /tmp/p/h9.py "$(py_hash_run 9)")
assert_suppressed "9b 9-line # run SILENT (tightened threshold)" "$out"
out=$(run Write /tmp/p/j9.ts "$(js_slash_run 9)")
assert_suppressed "9c 9-line // run SILENT (tightened threshold)" "$out"

# License header (10 lines) → SILENT
lic='# Copyright 2026 Acme Corp.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
import os'
out=$(run Write /tmp/p/i.py "$lic")
assert_suppressed "10 license header SILENT" "$out"

# JSDoc with @param/@returns (structured API doc, 11 lines) → SILENT
jsdoc='/**
 * Compute the discounted price for an order.
 * This applies tiered discounts and taxes.
 * It also handles currency conversion here.
 * And rounds to the nearest whole cent.
 * Edge cases for empty orders are covered.
 * @param order the order object to price
 * @param rate the discount rate to apply
 * @returns the final price in whole cents
 * @throws if the order has no line items
 */
export function price(order, rate) { return 0; }'
out=$(run Write /tmp/p/k.ts "$jsdoc")
assert_suppressed "11 JSDoc with @param SILENT" "$out"

# Decorative banner run (comment-hygiene owns it) → SILENT
banner='function b() {
  // ==========================================
  // ==========================================
  // ==========================================
  // ==========================================
  // ==========================================
  // ==========================================
  // ==========================================
  // ==========================================
  // ==========================================
  return 1;
}'
out=$(run Write /tmp/p/l.ts "$banner")
assert_suppressed "12 decorative banner SILENT (comment-hygiene owns)" "$out"

# eslint-disable pragma block (10 lines) → SILENT
pragma='function p() {
  /* eslint-disable no-console
   * disabling the following rules for this block
   * because we intentionally log a lot here
   * and the linter would otherwise complain
   * about every single console statement below
   * which is noise for this debug-only file
   * that never ships to production builds ever
   * so we accept the extra logging verbosity
   * for the duration of this investigation only
   */
  return 5;
}'
out=$(run Write /tmp/p/m.ts "$pragma")
assert_suppressed "13 eslint-disable pragma block SILENT" "$out"

# Python triple-quoted DATA assignment (12 lines) → SILENT (not a docstring)
data=$(printf 'SQL = """'; for i in $(seq 1 12); do printf '\nselect col_%s from t' "$i"; done; printf '\n"""\n')
out=$(run Write /tmp/p/n.py "$data")
assert_suppressed "14 triple-quoted data assignment SILENT" "$out"

# Non-source file → SILENT
out=$(run Write /tmp/p/o.md "$(py_hash_run 20)")
assert_suppressed "15 non-source .md SILENT" "$out"

# 12-line module docstring under the module allowance (16) → SILENT
out=$(run Write /tmp/p/mod2.py "$(printf '"""'; for i in $(seq 1 12); do printf '\nModule orientation sentence %s here.' "$i"; done; printf '\n"""\nimport os\n')")
assert_suppressed "16 module docstring (12<16) SILENT" "$out"

# Assignment-string CLOSE must not be read as a docstring opening that swallows
# code (the PartTypeClassifierAgent.py regression: `_P = """...\n"""` then a class).
assign_then_code='_SYSTEM_PROMPT = """
You are a classifier. Pick the best candidate.
Report confidence between 0 and 1.
Add one short note explaining the pick.
"""


class Result(BaseModel):
    guessed: str = Field(...)
    confidence: float = Field(...)
    notes: str = Field("")


class Agent:
    def __init__(self, model):
        self.model = model
        self.value = 1
        self.extra = 2
        self.more = 3
        self.done = 4'
out=$(run Write /tmp/p/agent.py "$assign_then_code")
assert_suppressed "18 assignment-string close not read as docstring (no code swallow)" "$out"

# Mute file honored on the first executable line
touch "$HOME/.claude/.no-comment-verbosity-gate"
out=$(run Write /tmp/p/p.py "$(py_docstring 14)")
if fired "$out"; then bad "17 mute file honored" "$out"; else ok "17 mute file honored (silent even on a fire case)"; fi
trash "$HOME/.claude/.no-comment-verbosity-gate" 2>/dev/null || true

echo "---------------------------------------------------------------"
echo "PASS=$PASS  FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && { echo "ALL PASS"; exit 0; } || { echo "SUITE FAILED"; exit 1; }
