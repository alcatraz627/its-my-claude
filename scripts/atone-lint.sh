#!/usr/bin/env bash
# atone-lint.sh — scan code for recurring, already-flagged code smells.
#
# This is the single source of truth for the "convention-blind code" family
# (atone cluster E). It is run at TWO points so the pattern that flagged a
# smell a dozen times and the check that should have caught it in review are
# literally the same code:
#   1. write-time  — hooks/nudge-cluster-e-smells.sh nudges as code is written
#   2. review-time — hooks/review-gate-stop.sh refuses "done" while a smell survives
#
# Each rule cites the atone slug it descends from, so the message names the
# pattern the user has already seen go wrong.
#
# Usage:
#   atone-lint.sh --file <path>            lint a file that exists on disk
#   atone-lint.sh --path <hint> < payload  lint stdin (write-time; file may not exist yet)
#   atone-lint.sh --file <path> --block-only   emit only block-severity rules
#
# Output: one match per line, TAB-separated:
#   <severity>\t<rule>\t<slug>\t<message>
#   severity ∈ { block, warn }
# Always exits 0 — this is a reporter; callers decide what to do with matches.

set -uo pipefail

EVENTS="$HOME/.claude/atone/events.jsonl"

file=""
path_hint=""
block_only=0
while [ $# -gt 0 ]; do
  case "$1" in
    --file)       file="$2"; path_hint="$2"; shift 2 ;;
    --path)       path_hint="$2"; shift 2 ;;
    --block-only) block_only=1; shift ;;
    *) shift ;;
  esac
done

# Load the body to scan: a file on disk, or stdin payload.
if [ -n "$file" ] && [ -f "$file" ]; then
  body=$(cat "$file" 2>/dev/null || true)
else
  body=$(cat 2>/dev/null || true)   # stdin (write-time payload)
fi
[ -z "$body" ] && exit 0

# Recurrence count for a slug — names the "flagged N times" reality. Reading the
# raw log here is safe: this script runs inside a hook, not as a tool call, so
# the append-only protection hook does not gate it (it gates writes, not reads).
slug_count() {
  local s="$1" n=0
  [ -f "$EVENTS" ] && n=$(rg -c "\"slug\":\"$s\"" "$EVENTS" 2>/dev/null || echo 0)
  printf '%s' "${n:-0}"
}

emit() {  # severity rule slug message
  [ "$block_only" = "1" ] && [ "$1" != "block" ] && return 0
  local n; n=$(slug_count "$3")
  local seen=""; [ "${n:-0}" -gt 0 ] && seen=" — flagged ${n}× as \`$3\`"
  printf '%s\t%s\t%s\t%s%s\n' "$1" "$2" "$3" "$4" "$seen"
}

is_jsx=0
case "$path_hint" in
  *.tsx|*.jsx) is_jsx=1 ;;
esac

is_jsts=0
case "$path_hint" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) is_jsts=1 ;;
esac

is_py=0
case "$path_hint" in
  *.py) is_py=1 ;;
esac

is_md=0
case "$path_hint" in
  *.md|*.markdown) is_md=1 ;;
esac

# ── R1  iife-in-jsx  (BLOCK) ──────────────────────────────────────────────
# An immediately-invoked function expression wrapping JSX/derivation where a
# sibling inline pattern was almost certainly the right shape. Precise signal:
# both an arrow/function-expr open AND an immediate-invoke close are present.
# Slug: added-scope-without-checking-siblings (S3).
if [ "$is_jsx" = "1" ]; then
  if printf '%s' "$body" | rg -q '\(\(\s*\)\s*=>|\(async\s*\(\s*\)\s*=>|\(function' \
     && printf '%s' "$body" | rg -q '\}\)\(\)'; then
    emit block iife-in-jsx added-scope-without-checking-siblings \
      "IIFE / scope-wrapper in JSX. Scan the 10 lines around the insertion point: if a sibling uses an inline prop or a plain const, conform to it instead of wrapping a function."
  fi
fi

# ── R3  review-surface-without-precondition-guard  (WARN) ─────────────────
# A review/inspector/detail surface that exposes destructive actions. These
# must answer: what renders when the precondition is FALSE, and are the
# destructive buttons hidden (not just runtime-guarded) in that state?
# Slug: feature-built-without-precondition-guard (S3).
case "$path_hint" in
  *modal*|*review*|*inspect*|*viewer*|*detail*|*panel*)
    if printf '%s' "$body" | rg -qi '(revert|refund|delete|remove|destroy|drop)[^a-z]' \
       && printf '%s' "$body" | rg -q 'onClick|<[A-Za-z]*[Bb]utton'; then
      emit warn review-surface-without-guard feature-built-without-precondition-guard \
        "Review/inspector surface with destructive actions. Name the precondition: (1) what renders when it is FALSE? (2) are the destructive buttons HIDDEN (not just runtime-guarded) in that state? (3) does the trigger enforce it?"
    fi
    ;;
esac

# ── R4  comment-essay  (WARN) ─────────────────────────────────────────────
# A multi-line block / JSDoc comment opened on its own line — proxy for the
# "dumped my working context into a comment" smell. The qualitative call
# (restates-code vs explains-why, jargon-flexing) is left to the review LLM
# pass; this only flags the shape. Slug: source-comment-hygiene (S3).
if [ "$is_jsts" = "1" ] && printf '%s' "$body" | rg -q '^\s*/\*\*?\s*$'; then
  emit warn comment-essay source-comment-hygiene \
    "Multi-line block comment. Comments are for humans first: first sentence code-agnostic, WHY not WHAT, ≤8 lines, no jargon-flexing or code-restating (rules/comments.md). Trim to the qualitative point."
fi

# ── R5  raw-process-env  (WARN) ───────────────────────────────────────────
# Reading process.env directly instead of the project's config/flag layer.
# Skip genuine config/env modules where direct reads are expected.
case "$path_hint" in
  *config*|*env*|*.config.*|*settings*) : ;;
  *)
    if [ "$is_jsts" = "1" ] && printf '%s' "$body" | rg -q 'process\.env\.'; then
      emit warn raw-process-env raw-process-env-instead-of-project-flag \
        "Raw process.env read outside the config layer. Check the project's existing config/flag module first instead of reading env directly here."
    fi
    ;;
esac

# ── R6  inline-import-without-justification  (WARN) ───────────────────────
# An import that is indented (inside a function/block) or a require() mid-body.
# Per the user's standing rule (feedback_no_defensive_imports.md): an inline
# import must carry a one-line comment above it explaining why inline. Advisory.
# Scoped to the JS "defensive import" the rule actually names — an indented
# require()/dynamic import() mid-body. Deliberately NOT plain indented `import`
# (false-fires on py try/except-ImportError fallbacks, TYPE_CHECKING blocks, and
# TS `import type` in namespaces — all idiomatic, all noise).
if [ "$is_jsts" = "1" ]; then
  if printf '%s' "$body" | rg -q '^[ \t]+(const [A-Za-z0-9_{}, ]+ = require\(|[A-Za-z0-9_]+ = require\(|await import\()'; then
    emit warn inline-import-without-justification inline-import-without-justification \
      "Inline require()/dynamic import() detected. Your rule (feedback_no_defensive_imports.md): a defensive/lazy import needs a one-line comment above it stating WHY (lazy-load, cycle-break). Hoist it, or add the justification."
  fi
fi

# ── R7  markdown-table-health  (WARN) ─────────────────────────────────────
# Catches the table corruptions prettier can't fix: a row whose pipe-count ≠
# the header's (usually an unescaped `|` inside a cell), `…` inside a table row
# (TTY-rendered output saved as source), and an unclosed code fence. Skips
# fenced code blocks. Universal — fires for any agent/scope writing .md.
if [ "$is_md" = "1" ]; then
  md_msgs=$(printf '%s' "$body" | python3 -c '
import sys, re
t = sys.stdin.read()
lines = t.split("\n")
msgs = []
if t.count("```") % 2 != 0:
    msgs.append("Unclosed code fence (odd number of ``` ) — everything after it renders as a code block.")
# A real GFM table is a header row FOLLOWED BY a separator row (|---|---|).
# Only after that do we compare data-row column counts. Escaped pipes (\|) are
# stripped before counting — a correctly-escaped cell must not be flagged.
intable = False; hdr = 0; in_fence = False; cand = None
for i, l in enumerate(lines):
    s = l.strip()
    if s.startswith("```"):
        in_fence = not in_fence; intable = False; cand = None; continue
    if in_fence:
        continue
    is_row = re.match(r"^\s*\|.*\|\s*$", l)
    if is_row:
        n = l.replace("\\|", "").count("|")          # ignore escaped pipes
        is_sep = bool(re.match(r"^\s*\|[\s:|-]+\|\s*$", l))
        if intable:
            if not is_sep and n != hdr:
                msgs.append(f"Table row at line {i+1} has a different pipe-count than its header (likely an unescaped | inside a cell). Escape as \\| or use md-table.sh.")
                intable = False
        elif cand is not None:
            if is_sep:                                # header + separator = real table
                intable = True; hdr = cand
            cand = None
        elif not is_sep:
            cand = n                                  # candidate header; needs a separator next
    else:
        intable = False; cand = None
    if chr(0x2026) in l and "|" in l:
        msgs.append(f"Ellipsis inside a table row at line {i+1} — a TTY-rendered/truncated table saved as source. Write source markdown, not rendered output.")
seen = set()
for m in msgs:
    if m not in seen:
        seen.add(m); print(m)
' 2>/dev/null)
  if [ -n "$md_msgs" ]; then
    while IFS= read -r m; do
      [ -n "$m" ] && emit warn markdown-table-health ascii-art-tables-instead-of-gum-tools \
        "$m For tables with code/long cells, use ~/.claude/scripts/md/md-table.sh."
    done <<< "$md_msgs"
  fi
fi

exit 0
