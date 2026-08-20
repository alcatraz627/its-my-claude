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
# A third mode checks a different kind of breakage. Headings can all be present
# while the CONTENT quietly loses something, and rules/invariant-graduation.md
# names the specific loss: summarization drops constraints and caveats while task
# momentum survives, so a successor resumes with the work and not the debt. The
# doc-22 rebuild and the claude-ipc "8 commits, none independently reviewed"
# caveat were both lost exactly this way, in opposite directions, by one engine.
# --diff-caveats reads the previous dump's Standing caveats and reports any that
# do not appear in the new one. A caveat may legitimately retire; it may not
# retire SILENTLY.
#
# usage: validate-checkpoint.sh <file> [--mini]
#        validate-checkpoint.sh <file> --diff-caveats <previous-file>
#   exit 0 contract satisfied · 1 contract broken · 2 usage/no file
#        --diff-caveats: 0 nothing vanished · 3 one or more vanished
set -uo pipefail

f="${1:-}"; mode="${2:-}"
[ -f "$f" ] || { echo "validate-checkpoint: no such file: $f" >&2; exit 2; }

if [ "$mode" = "--diff-caveats" ]; then
  prev="${3:-}"
  [ -f "$prev" ] || { echo "validate-checkpoint: --diff-caveats needs a previous file" >&2; exit 2; }

  # Pull the Standing caveats line out of a Resume Contract and split it into the
  # numbered items the core-dump template uses: "(1) … (2) … (3) …".
  caveats() {
    rg -N '^\s*-\s*\*\*Standing caveats:\*\*' "$1" 2>/dev/null \
      | sed 's/^.*\*\*Standing caveats:\*\*[[:space:]]*//' \
      | perl -pe 's/\s*\((\d+[a-z]?)\)\s*/\n/g' \
      | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
      | rg -v '^$'
  }

  # Match on WORD OVERLAP, not on a prefix. A carried-forward caveat is normally
  # reworded rather than copied, and the edit can land anywhere in it: a counter
  # moves ("152 dirty files" to "156"), or a word is inserted ("committed" to
  # "committed, now"). Two earlier cuts both failed on real shapes — a 60-char
  # key with digits flagged the counter case, and a 30-char digit-stripped prefix
  # flagged an insertion that happened to fall inside the window. Overlap has no
  # window to fall inside of.
  #
  # A previous caveat counts as surviving when some new caveat contains at least
  # 60% of its words. Digits are dropped so counters never matter.
  vanished=$(
    python3 - "$f" "$prev" <<'PY' 2>/dev/null
import re, subprocess, sys

def caveats(path):
    txt = open(path, encoding="utf-8", errors="replace").read()
    m = re.search(r'^\s*-\s*\*\*Standing caveats:\*\*(.*)$', txt, re.M)
    if not m:
        return []
    parts = re.split(r'\(\d+[a-z]?\)', m.group(1))
    return [p.strip() for p in parts if p.strip()]

def words(s):
    return set(re.findall(r'[a-z]+', s.lower()))

new = [words(c) for c in caveats(sys.argv[1])]
gone = []
for c in caveats(sys.argv[2]):
    w = words(c)
    if not w:
        continue
    if any(len(w & n) / len(w) >= 0.6 for n in new):
        continue
    gone.append(c)
print("\n".join("  - " + g for g in gone))
PY
  )

  if [ -n "${vanished//[[:space:]]/}" ]; then
    {
      echo "CAVEATS VANISHED between dumps. Present in $prev, absent from $f:"
      printf '%s' "$vanished"
      echo "Each one either still applies (restore it verbatim) or was retired (say so"
      echo "in the new dump). Dropping it silently is the laundering rules/invariant-graduation.md exists to stop."
    } >&2
    exit 3
  fi
  echo "OK: no caveats vanished between $prev and $f"
  exit 0
fi

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
# Field-level check on the Resume Contract, WARN TIER (ruling D2a: a new gate
# ships warn-tier and is promoted on evidence). Headings can all be present while
# a contract FIELD the template specifies is simply absent, which is how the
# 2026-08-19 dump shipped without "Task list, glanced" — the prose specified the
# field, the emitted template did not carry it, and this validator returned OK.
# Missing fields are reported, never fatal: older dumps predate later fields.
if rg -q "^## Resume Contract[[:space:]]*$" "$f"; then
  # The field list is DERIVED from the core-dump template, not kept as a second
  # hand-maintained copy. Two lists that must agree are a drift guard that only
  # ever agrees with itself; this one reads the other side.
  _tmpl="$HOME/.claude/skills/core-dump/SKILL.md"
  _fields=$(rg --no-filename -o -- '^- \*\*[^*]+:\*\* <' "$_tmpl" 2>/dev/null \
            | sed 's/^- \*\*//; s/:\*\* <$//' | sort -u)
  [ -n "$_fields" ] || _fields=$(printf '%s\n' "Standing constraints" "Standing caveats" \
    "Next action" "Next action's requirements" "Blocked on" "Expired authorizations" \
    "Decaying prerequisites" "Verification state" "Live commitments" "Task list, glanced" \
    "Task store" "Key anchor")

  # Scoped to the Resume Contract SECTION, and a present-but-empty field counts as
  # absent: "- **Task store:**" with nothing after it satisfied the old presence
  # test while telling a resumed agent exactly nothing.
  _contract=$(python3 - "$f" <<'PYX'
import sys, re
t = open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r"^## Resume Contract[ \t]*$(.*?)(?=^## |\Z)", t, re.M | re.S)
print(m.group(1) if m else "")
PYX
)
  absent_fields=""; empty_fields=""
  while IFS= read -r lbl; do
    [ -n "$lbl" ] || continue
    _line=$(printf '%s\n' "$_contract" | rg -F "**${lbl}:**" | head -1)
    if [ -z "$_line" ]; then
      absent_fields="${absent_fields} '${lbl}'"
    else
      _val=${_line#*"**${lbl}:**"}
      case "$(printf '%s' "$_val" | tr -d '[:space:]')" in
        ""|"-"|"—") empty_fields="${empty_fields} '${lbl}'" ;;
      esac
    fi
  done <<< "$_fields"
  [ -n "$absent_fields" ] && echo "warn: Resume Contract field(s) absent:${absent_fields} (template: core-dump SKILL.md 2.6)"
  [ -n "$empty_fields" ] && echo "warn: Resume Contract field(s) present but EMPTY:${empty_fields} (write the value or 'none')"
fi

echo "OK: parse contract satisfied: $f"
