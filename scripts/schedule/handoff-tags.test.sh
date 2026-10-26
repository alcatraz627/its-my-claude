#!/usr/bin/env bash
# Tests handoff.sh tag, tags and close-tag in a throwaway directory, with a stub
# claude-ipc so no real mail is sent.
#   bash ~/.claude/scripts/schedule/handoff-tags.test.sh
set -uo pipefail
H="$HOME/.claude/scripts/schedule/handoff.sh"
T=$(mktemp -d); export HANDOFF_DIR="$T/h" HANDOFF_QUIET=1
mkdir -p "$T/bin"
printf '#!/bin/sh\necho "$@" >> "%s/ipc.log"\n' "$T" > "$T/bin/claude-ipc"; chmod +x "$T/bin/claude-ipc"
export PATH="$T/bin:$PATH"
pass=0; fail=0
eq() { if [ "$2" = "$3" ]; then pass=$((pass+1)); printf 'ok   %s\n' "$1"; else fail=$((fail+1)); printf 'FAIL %s\n     want %s, got %s\n' "$1" "$3" "$2"; fi; }
has() { case "$2" in *"$3"*) pass=$((pass+1)); printf 'ok   %s\n' "$1" ;; *) fail=$((fail+1)); printf 'FAIL %s\n     missing %s in %s\n' "$1" "$3" "$2" ;; esac; }

f=$(bash "$H" tag "Check the gate's numbers." --title "Review the gate" --kind review --times 2 --domain gcc --reply-to gcc-all --ref da15a00 | sed 's/^tagged: //')
body=$(cat "$f")
has "frontmatter opens the file" "$(head -n 1 "$f")" "---"
has "title is recorded" "$body" "title: Review the gate"
has "times is recorded" "$body" "times: 2"
has "reply-to is recorded" "$body" "reply-to: gcc-all"
has "refs are recorded" "$body" "refs: da15a00"
has "the note follows the frontmatter" "$body" "Check the gate's numbers."

bash "$H" tag "later" --after 2099-01-01 >/dev/null
out=$(bash "$H" tags)
has "tags shows a due tag as due" "$out" "due          review  x2"
has "tags shows a future tag with its date" "$out" "after 2099-01-01"

out=$(bash "$H" close-tag "$f" "gate kept as is")
has "closing a 2-times tag keeps it" "$out" "kept for 1 more session(s)"
has "it counts down" "$(cat "$f")" "times: 1"
has "it is re-dated a week out" "$(cat "$f")" "after: $(date -v+7d +%Y-%m-%d)"
has "the outcome is noted in the tag" "$(cat "$f")" "gate kept as is"
has "reply-to is told" "$(cat "$T/ipc.log")" "send --to gcc-all"
bash "$H" close-tag "$f" "final: keep" >/dev/null
[ -f "$f" ] && eq "the last session closes the tag" present gone || eq "the last session closes the tag" gone gone

bash "$H" tag "x" --kind maybe >/dev/null 2>&1; eq "an unknown kind is refused" "$?" "2"
bash "$H" tag "x" --after tomorrow >/dev/null 2>&1; eq "a non-date after is refused" "$?" "2"

trash "$T" >/dev/null 2>&1
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
