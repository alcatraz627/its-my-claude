#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# Lag-regression tests for ui-callouts-gate.sh: the done-claim is read from the
# Stop input's last_assistant_message, never the one-message-stale transcript tail.
set -uo pipefail
HOOK="${GATE_UNDER_TEST:-$(cd "$(dirname "$0")" && pwd)/ui-callouts-gate.sh}"
T=$(mktemp -d)
export WARN_LOG_STORE="$T/warn.jsonl"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
if [ -f "$HOME/.claude/.no-ui-callouts-gate" ]; then echo "mute file present, test would pass vacuously"; exit 2; fi

PROJ="$T/proj"
mkdir -p "$PROJ/.claude"
jq -nc '{id:"co-lag-1", ts:"2026-10-15T00:00:00Z", surface:"lagwidget", words:"the header is cramped", status:"open", rechecks:[]}' > "$PROJ/.claude/callouts.jsonl"

BAD_REPLY="Done, the lagwidget header is fixed."
CLEAN_REPLY="Still looking at the lagwidget header."

run() { # run <sid> <reply> <transcript-tail-reply>
  local tp="$T/$1.jsonl"
  { jq -nc '{type:"user", message:{role:"user", content:"fix the header"}}'
    jq -nc --arg t "$3" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; } > "$tp"
  printf '%s/lagwidget.css\n' "$PROJ" > "/tmp/claude-edited-files-${1:0:8}"
  jq -nc --arg s "$1" --arg m "$2" --arg tp "$tp" \
    '{session_id:$s, transcript_path:$tp, last_assistant_message:$m}' | bash "$HOOK" 2>/dev/null
}
blocks() { printf '%s' "$1" | jq -e '.decision == "block"' >/dev/null 2>&1; }
ids="lagco001 lagco002 lagco003"
cleanup() { for s in $ids; do rm -f /tmp/claude-edited-files-$s /tmp/claude-ui-callouts-gate-$s; done; }
cleanup

out=$(run lagco001 "$BAD_REPLY" "$CLEAN_REPLY")
blocks "$out" && ok "current reply claims done on an open surface, clean tail: blocks" || bad "current bad, clean tail ($out)"

out=$(run lagco002 "$CLEAN_REPLY" "$BAD_REPLY")
[ -z "$out" ] && ok "current reply clean, done-claiming tail: silent" || bad "current clean, bad tail ($out)"

tp="$T/lagco003.jsonl"
{ jq -nc '{type:"user", message:{role:"user", content:"x"}}'
  jq -nc --arg t "$BAD_REPLY" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; } > "$tp"
printf '%s/lagwidget.css\n' "$PROJ" > /tmp/claude-edited-files-lagco003
out=$(jq -nc --arg tp "$tp" '{session_id:"lagco003", transcript_path:$tp}' | bash "$HOOK" 2>/dev/null)
blocks "$out" && ok "no last_assistant_message: falls back to the transcript" || bad "fallback to transcript ($out)"

cleanup

# --- Misfires measured in the 2026-11-26 agent-behavior audit (F3) ---
# A reply that claims nothing, or says it claims nothing, must not trip the gate, and the
# gate must not re-fire on a surface it already blocked once.
jq -nc '{id:"co-nav-1", ts:"2026-10-15T00:00:00Z", surface:"navwidget", words:"the nav is off", status:"open", rechecks:[]}' >> "$PROJ/.claude/callouts.jsonl"

# runt <sid> <reply> <edited-file>...: like run, but the transcript shows this turn editing
# each named file, which is how the gate learns what the turn touched.
runt() {
  local sid="$1" reply="$2" tp="$T/$1.jsonl" f; shift 2
  { jq -nc '{type:"user", message:{role:"user", content:"go on"}}'
    for f in "$@"; do
      jq -nc --arg p "$PROJ/$f" '{type:"assistant", message:{content:[{type:"tool_use", name:"Edit", input:{file_path:$p}}]}}'
    done
    jq -nc --arg t "$reply" '{type:"assistant", message:{content:[{type:"text", text:$t}]}}'; } > "$tp"
  printf '%s/lagwidget.css\n' "$PROJ" > "/tmp/claude-edited-files-${sid:0:8}"
  jq -nc --arg s "$sid" --arg m "$reply" --arg tp "$tp" \
    '{session_id:$s, transcript_path:$tp, last_assistant_message:$m}' | bash "$HOOK" 2>/dev/null
}
ids="mis00001 mis00002 mis00003 mis00004 mis00005 mis00006 mis00007 mis00008"
cleanup

# Verbatim from transcript a0daccbc L2898, which the old gate blocked.
out=$(runt mis00001 "Nothing on those surfaces has been verified yet, and I'm not claiming otherwise. I'll recheck them on the emulator after the build lands. I'm waiting on the review rerun and the motion build." lagwidget.css)
[ -z "$out" ] && ok "a reply that says nothing is verified yet is silent (a0daccbc L2898)" || bad "disclaimer reply ($out)"

# The shape of d10042e8 L3059, with the surface named inside the disclaimers.
out=$(runt mis00002 "The gate fired on words in my last message, but I didn't claim the lagwidget surface fixed. All of them stay open, unverified: lagwidget needs a real device. Navwidget is not re-run either." lagwidget.css navwidget.css)
[ -z "$out" ] && ok "a reply that disclaims a fix on the named surfaces is silent (d10042e8 L3059)" || bad "disclaiming reply ($out)"

# The shape of d10042e8 L3044: "ready" about a page, a turn that edited no UI file.
out=$(runt mis00003 "Your six picks are ready on one page: file:///tmp/picks/. Flip only what is wrong and press Submit. Pills for the lagwidget and timer are one of the alternatives.")
[ -z "$out" ] && ok "a 'ready' about something else, in a turn with no UI edit, is silent (d10042e8 L3044)" || bad "no-edit ready ($out)"

# The opposite proof: the same wording after a UI edit this turn, and plain claims, still block.
out=$(runt mis00004 "Your six picks are ready on one page: file:///tmp/picks/." lagwidget.css)
blocks "$out" && ok "the same reply after editing a UI file this turn still blocks" || bad "ready after edit ($out)"
out=$(runt mis00005 "Fixed the header and didn't touch the footer." lagwidget.css)
blocks "$out" && ok "a claim followed by a disclaimer is still a claim" || bad "claim then disclaimer ($out)"
out=$(runt mis00006 "Fixed the header. The lagwidget row is still unverified, though." lagwidget.css)
blocks "$out" && ok "a plain done-claim beside a disclaimer on another clause still blocks" || bad "mixed reply ($out)"

# Once blocked on a set, a claim naming only some of it passes.
out=$(runt mis00007 "Done, both widgets are fixed." lagwidget.css navwidget.css)
blocks "$out" && ok "first claim over two open surfaces blocks" || bad "two-surface block ($out)"
out=$(runt mis00007 "Done, the lagwidget header is fixed." lagwidget.css)
[ -z "$(printf '%s' "$out" | jq -r 'select(.decision=="block")' 2>/dev/null)" ] && ok "a narrowed claim on a surface already blocked passes" || bad "subset re-block ($out)"
out=$(runt mis00008 "Done, the lagwidget header is fixed." lagwidget.css)
blocks "$out" && ok "an unblocked surface still blocks on its first claim" || bad "fresh surface ($out)"
ids="$ids mis00009"; cleanup
out=$(runt mis00009 "All done. The lagwidget header is updated.")
blocks "$out" && ok "a done-claim whose next sentence names the surface blocks even with no edit in view" || bad "next-clause name ($out)"

cleanup
echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
