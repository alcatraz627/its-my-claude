#!/usr/bin/env bash
# validate-checkpoint.sh — refuse a checkpoint that breaks /catchup's parse contract.
#
# /catchup locates sections by EXACT headings. A dump that invents synonyms
# ("Resume prompt", "Done, and verified") reads fine to a human and parses as
# nothing, which is how the 2026-08-13 slack-automation catchup orphaned. This
# gate runs inside /core-dump after the file is written; the contract in prose
# alone is advisory to a running session.
#
# Two contracts, one per mode:
#   full  — exact H2 headings: Initial Goal · Agent Actions · Current
#           Expectation · Pending Items (Resume Contract and Session Insights
#           optional, noted when absent)
#   --mini — "# Mini Core Dump" H1 plus the bold labels Goal/Resume/Done/
#           Not Done/Next Steps (minis have NO H2 sections by design)
#
# usage: validate-checkpoint.sh <file> [--mini]
#   exit 0 contract satisfied · 1 contract broken · 2 usage/no file
set -uo pipefail

f="${1:-}"; mode="${2:-}"
[ -f "$f" ] || { echo "validate-checkpoint: no such file: $f" >&2; exit 2; }

if [ "$mode" = "--mini" ]; then
  missing=""
  rg -q "^# Mini Core Dump" "$f" || missing="${missing}
  # Mini Core Dump (H1)"
  for lbl in "Goal" "Resume" "Done" "Not Done" "Next Steps"; do
    rg -q "^\\*\\*${lbl}:\\*\\*" "$f" || missing="${missing}
  **${lbl}:**"
  done
  if [ -n "$missing" ]; then
    {
      echo "FAIL: $f breaks the mini-dump contract. Missing:${missing}"
      echo "Fix: use the Phase 2-mini template verbatim (core-dump SKILL.md); minis use bold labels, not H2 sections."
    } >&2
    exit 1
  fi
  echo "OK: mini contract satisfied: $f"
  exit 0
fi

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
[ -n "$optional_absent" ] && echo "note: optional heading(s) absent:${optional_absent} (normal on precompact/older dumps)"
echo "OK: parse contract satisfied: $f"
