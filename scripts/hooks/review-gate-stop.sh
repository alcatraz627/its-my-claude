#!/usr/bin/env bash
# review-gate-stop.sh — Stop hook with TWO gates that refuse to let the turn END:
#
#   Gate 1 (smell): a file edited this session still contains a BLOCK-level
#     recurring smell. The catalog that flags it (atone-lint.sh) is the SAME code
#     that gates 'done', so a known pattern cannot pass review silently. Loop-safe:
#     blocks once per smell-signature, then steps aside (non-blocking reminder) so
#     it can never trap. Mute: touch ~/.claude/.no-review-gate
#
#   Gate 2 (review-required): an unreviewed change carrying a concrete RISK
#     signal — a catalogued recurring smell in the source, OR new exported API
#     surface — should go through /skeptical-review before 'done'. NEVER fires
#     on edit volume alone (a big pile of low-risk edits stays silent; that
#     volume trigger nagged on report batches and was removed), and NEVER on a
#     docs-only change-set: the export/API scan is scoped to review-marker's
#     unreviewed CODE set (docs, reports, generated dirs already dropped), so a
#     `export` inside a markdown fence or a release-note snippet can never be
#     mistaken for real code surface. Hooks can't dispatch the reviewer
#     themselves, so this gates instead — persisting until the change-set is
#     reviewed (the skill writes the marker via review-marker.sh) or muted.
#     Mute: touch ~/.claude/.no-review-required
#
# Registered as a DIRECT settings.json Stop hook (not via the hook-orchestrator,
# whose task stdout goes to /dev/null and so cannot carry a decision back).

set -uo pipefail
[ -f "$HOME/.claude/.no-review-gate" ] && exit 0

LINT="$HOME/.claude/scripts/atone-lint.sh"
[ -x "$LINT" ] || exit 0

input=$(cat 2>/dev/null) || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
sid8="${sid:0:8}"
SID8="$sid8"   # exported for new_code_export's snapshot lookup
EDITED="/tmp/claude-edited-files-${sid8}"
MARK="/tmp/claude-review-gate-blocked-${sid8}"
[ -f "$EDITED" ] || exit 0

# Collect block-level findings across every file edited this session. The outer
# loop runs in the current shell (process substitution, not a pipe) so the
# accumulators survive the loop.
findings=""
findings_msg=""
while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  hits=$("$LINT" --file "$f" --block-only 2>/dev/null)
  [ -n "$hits" ] || continue
  while IFS=$'\t' read -r sev rule slug msg; do
    [ -n "$rule" ] || continue
    findings="${findings}${f}::${rule}"$'\n'
    findings_msg="${findings_msg}  - ${f}: ${msg}"$'\n'
  done <<< "$hits"
done < <(sort -u "$EDITED")

# ── Gate 1: surviving block-level smell (takes precedence) ──────────────────
if [ -n "$findings" ]; then
  sig=$(printf '%s' "$findings" | sort -u | shasum 2>/dev/null | awk '{print $1}')
  prev=""
  [ -f "$MARK" ] && prev=$(cat "$MARK" 2>/dev/null)
  if [ "$sig" = "$prev" ] && [ -n "$sig" ]; then
    # Same smell signature came back after a block → the prior block was not heeded.
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook review-gate --heed-of "review-gate:$sid8" --heeded false >/dev/null 2>&1 || true
    # Already blocked for this exact signature last Stop — step aside (the agent
    # saw it and chose to proceed, or it's a false positive) but stay visible.
    msg="⚠ review-gate (not re-blocking): these recurring smells are still present —
${findings_msg}Fix them or mute: touch ~/.claude/.no-review-gate"
    jq -cn --arg m "$msg" '{systemMessage:$m}' 2>/dev/null || true
    exit 0
  fi
  printf '%s' "$sig" > "$MARK" 2>/dev/null || true
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook review-gate --action block --heeded unknown >/dev/null 2>&1 || true
  reason="⚠ REVIEW GATE — about to declare done, but files you edited this session still contain a recurring smell you have corrected before:
${findings_msg}
Read the named insertion points and fix these before ending the turn. If this is a false positive, mute with: touch ~/.claude/.no-review-gate"
  jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
  exit 0
fi
# No smell now. A lingering block signature means the smell was fixed since the
# block → that block was heeded. Emit once, then clear the signature.
if [ -s "$MARK" ]; then
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook review-gate --heed-of "review-gate:$sid8" --heeded true >/dev/null 2>&1 || true
fi
: > "$MARK" 2>/dev/null || true   # no smell — clear the smell block-signature

# ── Gate 2: substantial unreviewed change → require /skeptical-review ────────
# Persists until the change-set is reviewed (skill writes the marker) or muted —
# that persistence IS the point. Keyed to the unreviewed DELTA, so one review
# covers later fixes to the same files; only NEW files re-trigger.
# Mute: touch ~/.claude/.no-review-required
[ -f "$HOME/.claude/.no-review-required" ] && exit 0
MARKER="$HOME/.claude/scripts/review-marker.sh"
[ -x "$MARKER" ] || exit 0

nunrev=$("$MARKER" count "$sid8" 2>/dev/null || echo 0)
[ "${nunrev:-0}" -gt 0 ] || exit 0

# Fire ONLY on a concrete RISK signal — never on volume, never on docs. The
# user's reality is large aggregations of mostly-harmless unpushed edits + general
# trust in the agent; gating on count would nag on exactly those. So a big pile of
# edits with no risk signal = SILENT, and a docs-only change-set = SILENT (the
# unreviewed set below is CODE-only). We gate only on: a catalogued recurring
# block-level smell in unreviewed source, OR genuinely NEW exported/public code
# surface. Everything else trusts the agent.
#
# new_code_export <file> <git-root-or-empty> → exit 0 when the file introduces
# real exported/public API surface. Scoped per-file to a CODE file: a brand-new
# (untracked) file counts its whole body as added; a tracked file counts only its
# added ('+') lines vs HEAD, so a pre-existing export is not re-flagged and a
# removed one is ignored. This is what keeps a `export` inside a markdown fence
# (never in the code-only unreviewed set) from being read as code surface, and
# what makes a brand-new .ts/.py file's exports actually register (a whole-tree
# `git diff` misses untracked files — the false-negative this replaces).
new_code_export() {
  local f="$1" groot="$2" added="" snap=""
  # Prefer this session's own pre-edit snapshot over `git diff HEAD`. HEAD is a
  # shared baseline: on a tree several sessions are editing, its diff attributes
  # their uncommitted lines to you, and the gate then demands review of work you
  # never wrote. snapshot-pre-edit.sh keeps one copy per file per session, taken
  # before the first edit, which is the only baseline that answers "what did THIS
  # session add?". Falls back to HEAD when no snapshot exists (a file edited
  # before the snapshotter was wired, or a resumed session).
  if [ -n "${SID8:-}" ]; then
    local fr; fr=$(cd "$(dirname "$f")" 2>/dev/null && printf '%s/%s' "$(pwd -P)" "$(basename "$f")") || fr="$f"
    snap="/tmp/claude-presnap-${SID8}/$(printf '%s' "$fr" | shasum 2>/dev/null | awk '{print $1}')"
  fi
  if [ -n "$snap" ] && [ -f "$snap" ]; then
    added=$(diff "$snap" "$f" 2>/dev/null | rg '^> ' 2>/dev/null | sed 's/^> //')
  elif [ -n "$groot" ] && git -C "$groot" ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
    added=$(git -C "$groot" diff -U0 HEAD -- "$f" 2>/dev/null | rg '^\+[^+]' 2>/dev/null)
  else
    added=$(cat "$f" 2>/dev/null)   # untracked / non-git → whole body is new
  fi
  [ -n "$added" ] || return 1
  case "$f" in
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs)
      printf '%s' "$added" | rg -q '(^|\+)\s*export\b' ;;
    *.py)
      printf '%s' "$added" | rg -q '(^|\+)(def |class |__all__\b)' ;;
    *.go)
      printf '%s' "$added" | rg -q '(^|\+)\s*func\s+[A-Z]|(^|\+)\s*type\s+[A-Z]' ;;
    *.rs)
      printf '%s' "$added" | rg -q '(^|\+)\s*pub\s+(fn|struct|enum|trait|mod|const)\b' ;;
    *) return 1 ;;
  esac
}

substantial=0
trigger=""
groot=""
git rev-parse --show-toplevel >/dev/null 2>&1 && groot=$(git rev-parse --show-toplevel 2>/dev/null)
while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  if [ -n "$("$LINT" --file "$f" --block-only 2>/dev/null)" ]; then
    substantial=1; trigger="a recurring block-level smell in $f"; break
  fi
  if new_code_export "$f" "$groot"; then
    substantial=1; trigger="new exported API surface"; break
  fi
done < <("$MARKER" unreviewed "$sid8" 2>/dev/null)
[ "$substantial" = 1 ] || exit 0

# Step-aside: block ONCE per unreviewed-set signature, then drop to a
# non-blocking reminder. This is what stops the per-turn nagging that gets the
# whole gate muted (guard dilution). Same pattern as Gate 1. The signature is the
# unreviewed CODE-file set, so a docs-only growth of the change-set never flips
# it — the gate cannot re-fire as unrelated docs pile up.
MARK2="/tmp/claude-review-required-blocked-${sid8}"
sig2=$("$MARKER" unreviewed "$sid8" 2>/dev/null | sort -u | shasum 2>/dev/null | awk '{print $1}')
prev2=""; [ -f "$MARK2" ] && prev2=$(cat "$MARK2" 2>/dev/null)
if [ "$sig2" = "$prev2" ] && [ -n "$sig2" ]; then
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook review-gate --heed-of "review-gate:$sid8" --heeded false >/dev/null 2>&1 || true
  msg="ℹ review-gate (reminder, not blocking): ${nunrev} unreviewed source file(s) from this session. /skeptical-review when convenient, or mute: touch ~/.claude/.no-review-required"
  jq -cn --arg m "$msg" '{systemMessage:$m}' 2>/dev/null || true
  exit 0
fi
printf '%s' "$sig2" > "$MARK2" 2>/dev/null || true
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook review-gate --action block --heeded unknown >/dev/null 2>&1 || true

reason="⚠ REVIEW SUGGESTED — this session has an unreviewed substantial change (${trigger}). Worth a /skeptical-review (forks a fresh adversarial reviewer) before declaring done — the last few caught real bugs. Not harmful? This won't block again for this change-set. Mute for the session: touch ~/.claude/.no-review-required"
jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
exit 0
