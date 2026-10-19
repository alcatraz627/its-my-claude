#!/usr/bin/env bash
# Tests for format-reminder-ups.sh: silent for a clean session, one line naming
# only the tripped classes for the next two prompts after a trip, silent after.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="${FORMAT_REMINDER_HOOK:-$HERE/format-reminder-ups.sh}"
GATE="$HERE/format-gate-stop.sh"
T=$(mktemp -d)
H="$T/home"; mkdir -p "$H/.claude/scripts" "$H/proj"
ln -s "$HERE" "$H/.claude/scripts/hooks"
printf '#!/usr/bin/env bash\nexit 0\n' > "$T/pol-stub.sh"
export WARN_LOG_STORE="$T/warn.jsonl"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
cleanup() { rm -f /tmp/claude-format-gate-fgu* /tmp/claude-format-tripped-fgu* /tmp/claude-format-reminded-fgu*; }
cleanup
ups() { jq -nc --arg s "$1" '{session_id:$s, hook_event_name:"UserPromptSubmit", prompt:"next"}' | HOME="$H" bash "$HOOK" 2>/dev/null; }
trip() { # trip <sid8> <reply>: run the real gate so the tripped file is the real shape
  local tp="$T/$1.jsonl"
  jq -cn '{type:"user", message:{role:"user", content:"ok"}}' > "$tp"
  jq -nc --arg s "$1" --arg m "$2" --arg tp "$tp" '{session_id:$s, transcript_path:$tp, stop_hook_active:false, last_assistant_message:$m}' \
    | HOME="$H" POL_SH="$T/pol-stub.sh" bash "$GATE" 2>/dev/null
}
one_line_ctx() { printf '%s' "$1" | jq -e '.hookSpecificOutput.hookEventName == "UserPromptSubmit" and (.hookSpecificOutput.additionalContext | type == "string" and (contains("\n") | not))' >/dev/null 2>&1; }
ctx() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty'; }
long=$(printf 'This sentence is plain prose that keeps going to make the reply long. %.0s' $(seq 1 45))
D='—'

echo "== clean session =="
out=$(ups fgu00001); [ -z "$out" ] && ok "no trip, zero output" || bad "no trip, zero output: $out"

echo "== a trip reminds the next two prompts, naming only what tripped =="
trip fgu00002 "Small $D change." >/dev/null
out=$(ups fgu00002)
one_line_ctx "$out" && ok "first prompt after a trip emits one additionalContext line" || bad "first reminder: $out"
ctx "$out" | rg -q 'no em-dashes' && ok "names the em-dash class" || bad "names the em-dash class"
ctx "$out" | rg -qi 'period right after a file path|prose cap|absolute path' && bad "names a class that did not trip: $(ctx "$out")" || ok "names only the class that tripped"
out=$(ups fgu00002); one_line_ctx "$out" && ok "second prompt still reminds" || bad "second reminder"
out=$(ups fgu00002); [ -z "$out" ] && ok "third prompt is silent" || bad "third prompt must be silent: $out"

echo "== the cap is worded as the gate words it =="
gate_out=$(trip fgu00003 "$long")
out=$(ups fgu00003)
ctx "$out" | rg -q 'prose cap 2600 chars' && ok "terse reminder carries 'prose cap 2600 chars'" || bad "terse reminder: $(ctx "$out")"
printf '%s' "$gate_out" | jq -r '.reason // empty' | rg -q 'prose cap 2600 chars' \
  && ok "the gate's own reason uses the identical phrase" || bad "gate reason phrase: $gate_out"

echo "== several classes =="
trip fgu00004 "Small $D change, see ~/foo/bar.md." >/dev/null
out=$(ups fgu00004)
ctx "$out" | rg -q 'no em-dashes' && ctx "$out" | rg -q 'period right after a file path' && ok "lists both tripped classes" || bad "both classes: $(ctx "$out")"

echo "== a newer trip restarts the count =="
trip fgu00005 "Small $D change." >/dev/null
ups fgu00005 >/dev/null; ups fgu00005 >/dev/null
sleep 1
rm -f /tmp/claude-format-gate-fgu00005
trip fgu00005 "Another $D change." >/dev/null
out=$(ups fgu00005); one_line_ctx "$out" && ok "a new trip is reminded again after the old count ran out" || bad "new trip not reminded"

echo "== mutes and degenerate input =="
trip fgu00006 "Small $D change." >/dev/null
touch "$H/.claude/.no-format-gate"
out=$(ups fgu00006); [ -z "$out" ] && ok "the merged mute silences the reminder" || bad "mute ignored"
rm -f "$H/.claude/.no-format-gate"
out=$(printf '{}' | HOME="$H" bash "$HOOK" 2>/dev/null); [ -z "$out" ] && ok "no session id, zero output" || bad "no session id: $out"
printf 'ts=\nclasses=\n' > /tmp/claude-format-tripped-fgu00007
out=$(ups fgu00007); [ -z "$out" ] && ok "a malformed tripped file is silent" || bad "malformed tripped file: $out"
printf 'ts=1\nclasses=nonsense\ncap=2600\n' > /tmp/claude-format-tripped-fgu00008
out=$(ups fgu00008); [ -z "$out" ] && ok "an unknown class alone is silent" || bad "unknown class: $out"

cleanup
echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
