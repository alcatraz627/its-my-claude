#!/usr/bin/env bash
# validate-checkpoint.sh — refuse a checkpoint that breaks /catchup's parse contract.
#
# /catchup locates sections by EXACT headings. A dump that invents synonyms
# ("Resume prompt", "Done, and verified") reads fine to a human and parses as
# nothing, which is how the 2026-08-13 slack-automation catchup orphaned. This
# gate runs inside /core-dump after the file is written; the contract in prose
# alone is advisory to a running session.
#
# usage: validate-checkpoint.sh <file> [--mini]
#   exit 0 contract satisfied · 1 mandatory heading missing · 2 usage/no file
set -uo pipefail

f="${1:-}"; mode="${2:-}"
[ -f "$f" ] || { echo "validate-checkpoint: no such file: $f" >&2; exit 2; }

missing=""
for h in "Initial Goal" "Agent Actions" "Current Expectation" "Pending Items"; do
  rg -q "^## ${h}[[:space:]]*$" "$f" || missing="${missing}
  ## ${h}"
done

if [ -n "$missing" ]; then
  {
    echo "FAIL: $f breaks the /catchup parse contract. Missing exact heading(s):${missing}"
    echo "Fix: rename the file's sections to the contract headings (core-dump SKILL.md, 'Parse contract')."
    echo "Synonyms parse as nothing: 'Done, and verified' is not '## Agent Actions'."
  } >&2
  exit 1
fi

optional_absent=""
for h in "Resume Contract" "Session Insights"; do
  rg -q "^## ${h}[[:space:]]*$" "$f" || optional_absent="${optional_absent} '## ${h}'"
done
if [ -n "$optional_absent" ] && [ "$mode" != "--mini" ]; then
  echo "note: optional heading(s) absent:${optional_absent} (normal on mini/precompact dumps)"
fi
echo "OK: parse contract satisfied: $f"
