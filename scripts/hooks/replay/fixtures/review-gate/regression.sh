#!/usr/bin/env bash
# regression.sh — self-contained reproduce-then-fixed test for review-gate-stop.sh
# (Gate 2, export/API surface). This hook's verdict depends on git state +
# /tmp/claude-edited-files-<sid>, NOT on a transcript, so it cannot ride the
# shared JSONL replay harness (run_fixtures.py). This script builds its own
# throwaway git repo + edit-tracker + isolated HOME and asserts each verdict.
#
# Usage:  bash regression.sh            # runs against the live hook
#         bash regression.sh <hook>     # runs against a specific hook path
#
# Verdicts: BLOCK = {"decision":"block"} ; SILENT = no stdout.
set -uo pipefail

HOOK="${1:-$HOME/.claude/scripts/hooks/review-gate-stop.sh}"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/review-gate-regress.XXXXXX")
TH="$WORK/home"; REPO="$WORK/repo"
mkdir -p "$TH/.claude"
ln -s "$HOME/.claude/scripts" "$TH/.claude/scripts"
[ -d "$HOME/.claude/atone" ] && ln -s "$HOME/.claude/atone" "$TH/.claude/atone"
mkdir -p "$REPO/docs" "$REPO/src"
( cd "$REPO"
  git init -q; git config user.email t@t.com; git config user.name t
  printf 'export const existing = 1\n' > src/base.ts
  printf '# base\n' > docs/base.md
  git add -A && git commit -qm init )

pass=0; fail=0
run() {  # <sid8> ; prints BLOCK/REMIND/SILENT
  local sid8="$1"
  local sid; sid="${sid8}$(printf '%040d' 0)"
  local out; out=$(printf '{"session_id":"%s","hook_event_name":"Stop"}' "$sid" \
    | ( cd "$REPO" && HOME="$TH" bash "$HOOK" 2>/dev/null ))
  if   [ -z "$out" ]; then echo SILENT
  elif printf '%s' "$out" | rg -q '"decision":"block"'; then echo BLOCK
  else echo REMIND; fi
}
reset() {  # <sid8> — clean repo + clear this sid's markers
  ( cd "$REPO" && git checkout -q -- . && git clean -fdq )
  rm -f "/tmp/claude-edited-files-$1" "/tmp/claude-review-done-$1" \
        "/tmp/claude-review-gate-blocked-$1" "/tmp/claude-review-required-blocked-$1" 2>/dev/null || true
}
edited() { printf '%s\n' "$@" > "/tmp/claude-edited-files-$SID"; }
check() {  # <label> <want> <got>
  if [ "$2" = "$3" ]; then echo "  PASS  $1 → $3"; pass=$((pass+1))
  else echo "  FAIL  $1 → got $3, want $2"; fail=$((fail+1)); fi
}

# A: docs-only → SILENT (the reproduced false-positive class)
SID=a0a0a0a0; reset "$SID"
printf '# more\n' > "$REPO/docs/base.md"; printf '# new\n' > "$REPO/docs/new.md"
edited "$REPO/docs/base.md" "$REPO/docs/new.md"
check "docs-only" SILENT "$(run "$SID")"

# B: pure-docs .md containing an example export in a fence → SILENT
SID=b0b0b0b0; reset "$SID"
printf '# doc\n\n```ts\nexport function ex(){return 1}\n```\n' > "$REPO/docs/api.md"
edited "$REPO/docs/api.md"
check "docs+fence-export" SILENT "$(run "$SID")"

# C: real NEW .ts file adding an export → BLOCK (the reproduced false-negative)
SID=c0c0c0c0; reset "$SID"
printf 'export function newThing(x){return x+1}\n' > "$REPO/src/feature.ts"
edited "$REPO/src/feature.ts"
check "new-ts-export" BLOCK "$(run "$SID")"

# D: internal .ts change with NO export → SILENT (no risk signal)
SID=d0d0d0d0; reset "$SID"
printf 'const n = 42\nconsole.log(n)\n' > "$REPO/src/internal.ts"
edited "$REPO/src/internal.ts"
check "code-no-export" SILENT "$(run "$SID")"

# E: mixed — real code adds NO export, but a tracked .md fence has one → SILENT
SID=e0e0e0e0; reset "$SID"
printf 'export const existing = 1\nconsole.log("x")\n' > "$REPO/src/base.ts"
printf '# base\n\n```ts\nexport function widget(){return 1}\n```\n' > "$REPO/docs/base.md"
edited "$REPO/src/base.ts" "$REPO/docs/base.md"
check "mixed-md-fence-export" SILENT "$(run "$SID")"

# F: loop-safety — block once, then step aside (REMIND), no re-block as docs grow
SID=f0f0f0f0; reset "$SID"
printf 'export function api(){return 1}\n' > "$REPO/src/feat.ts"
edited "$REPO/src/feat.ts"
check "loop-turn1" BLOCK "$(run "$SID")"
check "loop-turn2-same" REMIND "$(run "$SID")"
printf '# grow\n' > "$REPO/docs/grow.md"; edited "$REPO/src/feat.ts" "$REPO/docs/grow.md"
check "loop-turn3-docs-grow" REMIND "$(run "$SID")"

# G: tracked .ts modified to ADD an export → BLOCK (original true positive kept)
SID=90909090; reset "$SID"
printf 'export const existing = 1\nexport function addedApi(){return 2}\n' > "$REPO/src/base.ts"
edited "$REPO/src/base.ts"
check "tracked-adds-export" BLOCK "$(run "$SID")"

# H: another session left an uncommitted export in a file WE also edit, and we
# add no export → SILENT. Before the snapshot branch this BLOCKED, because
# `git diff HEAD` attributed their line to us. Nine proposals' worth of false fire.
SID=70707070; reset "$SID"
rm -rf "/tmp/claude-presnap-$SID"
printf 'export const theirs = 1\n' > "$REPO/src/shared.ts"   # their uncommitted work
printf '{"session_id":"%s","tool_input":{"file_path":"%s"}}' \
  "${SID}$(printf '%040d' 0)" "$REPO/src/shared.ts" \
  | bash "$HOME/.claude/scripts/hooks/snapshot-pre-edit.sh"   # our session starts here
printf 'export const theirs = 1\nconst ours = 2\n' > "$REPO/src/shared.ts"
edited "$REPO/src/shared.ts"
check "cross-session-their-export" SILENT "$(run "$SID")"
rm -rf "/tmp/claude-presnap-$SID"

# I: same setup, but WE add the export → BLOCK. The positive control for H: a
# guard that only ever goes silent is not a guard.
SID=60606060; reset "$SID"
rm -rf "/tmp/claude-presnap-$SID"
printf 'const theirs = 1\n' > "$REPO/src/shared2.ts"
printf '{"session_id":"%s","tool_input":{"file_path":"%s"}}' \
  "${SID}$(printf '%040d' 0)" "$REPO/src/shared2.ts" \
  | bash "$HOME/.claude/scripts/hooks/snapshot-pre-edit.sh"
printf 'const theirs = 1\nexport const ours = 2\n' > "$REPO/src/shared2.ts"
edited "$REPO/src/shared2.ts"
check "cross-session-our-export" BLOCK "$(run "$SID")"
rm -rf "/tmp/claude-presnap-$SID"

echo "---- $pass passed, $fail failed ----"
rm -rf "$WORK"
[ "$fail" = 0 ]
