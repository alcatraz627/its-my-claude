#!/usr/bin/env bash
# File a MINOR technical issue to this repo's GitHub Issues, with a human gate.
#
# What this is for: the small technical cleanups an agent surfaces while working —
# a missing enum entry, dead code, config sprawl, a stale flag. NOT for anything
# with product or business value; that belongs in Linear and is the team's call,
# not an agent's.
#
# Safety model: default is DRY-RUN. It renders the issue and prints the exact
# `gh issue create` command, and files nothing. Pass --confirm to file — and even
# then the repo's cli-gating hook prompts for approval on the `gh` write, so a
# human signs off on the outward action regardless.
#
# Usage:
#   file-github-issue.sh --title "<title>" --body-file <path.md> [--label <l>]... [--confirm]
#   file-github-issue.sh --title "<title>" --body "<inline>"     [--label <l>]... [--confirm]
#
# Defaults: --label agent-filed --label tech-debt  (add more with repeated --label)

set -euo pipefail

TITLE="" BODY="" BODY_FILE="" CONFIRM=0
LABELS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --title) TITLE="${2:-}"; shift 2 ;;
    --body) BODY="${2:-}"; shift 2 ;;
    --body-file) BODY_FILE="${2:-}"; shift 2 ;;
    --label) LABELS+=("${2:-}"); shift 2 ;;
    --confirm) CONFIRM=1; shift ;;
    -h | --help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "ERROR: unknown flag '$1' (try --help)" >&2; exit 2 ;;
  esac
done

[ -n "$TITLE" ] || { echo "ERROR: --title is required" >&2; exit 2; }
if [ -n "$BODY_FILE" ]; then
  [ -f "$BODY_FILE" ] || { echo "ERROR: --body-file '$BODY_FILE' not found" >&2; exit 2; }
  BODY="$(cat "$BODY_FILE")"
fi
[ -n "$BODY" ] || { echo "ERROR: provide --body or --body-file" >&2; exit 2; }
[ "${#LABELS[@]}" -gt 0 ] || LABELS=(agent-filed tech-debt)

command -v gh >/dev/null || { echo "ERROR: gh CLI not found (brew install gh)" >&2; exit 3; }

# Footer stamps provenance so agent-filed issues stay auditable.
SHA="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
FOOTER=$'\n\n---\n_Filed via `file-github-issue.sh` (minor technical scope). Grounded against '"$SHA"$'._'
FULL_BODY="${BODY}${FOOTER}"

LABEL_ARGS=()
for l in "${LABELS[@]}"; do LABEL_ARGS+=(--label "$l"); done

echo "──────────────────────────────────────────"
echo "  Title:  $TITLE"
echo "  Labels: ${LABELS[*]}"
echo "  Body:   ${#FULL_BODY} chars"
echo "──────────────────────────────────────────"
printf '%s\n' "$FULL_BODY"
echo "──────────────────────────────────────────"

if [ "$CONFIRM" -eq 0 ]; then
  echo "DRY-RUN — nothing filed. To file: re-run with --confirm (the gh write is still approval-gated)."
  exit 0
fi

TMP="$(mktemp)"
printf '%s' "$FULL_BODY" >"$TMP"
gh issue create --title "$TITLE" "${LABEL_ARGS[@]}" --body-file "$TMP"
rm -f "$TMP"
