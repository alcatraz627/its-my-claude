#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# Tests for format-gate-stop.sh: every class gets a positive and a clean reply,
# the merged reason lists every blocking span on one line, and the loop guards
# (identical reply, three in a row, stop_hook_active) let the turn end.
# Blocking classes: emdash, terse-reply (125 percent of the cap), prose-smell.
# filename-dot and relpath only add a path note to systemMessage, never a block.
#
# The hook runs under a temp HOME whose scripts/hooks is a symlink to the real
# one, so mute files, snoozes and policy never touch the live machine.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="${FORMAT_GATE_HOOK:-$HERE/format-gate-stop.sh}"
T=$(mktemp -d)
H="$T/home"; mkdir -p "$H/.claude/scripts" "$H/proj"
ln -s "$HERE" "$H/.claude/scripts/hooks"
printf '#!/usr/bin/env bash\nexit 0\n' > "$T/pol-stub.sh"
export WARN_LOG_STORE="$T/warn.jsonl"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

D=$'\xe2\x80\x94'
# tx <file> <user text> [written file path ...]: a transcript with the owner's
# prompt, then one Write per path, then a stale assistant text.
tx() {
  local f="$1" u="$2"; shift 2
  jq -cn --arg u "$u" '{type:"user", message:{role:"user", content:$u}}' > "$f"
  local p
  for p in "$@"; do
    jq -cn --arg p "$p" '{type:"assistant", message:{role:"assistant", content:[{type:"tool_use", name:"Write", input:{file_path:$p}}]}}' >> "$f"
    jq -cn '{type:"user", message:{role:"user", content:[{type:"tool_result", content:"ok"}]}}' >> "$f"
  done
  jq -cn '{type:"assistant", message:{role:"assistant", content:[{type:"text", text:"stale"}]}}' >> "$f"
}
# run <sid8> <reply> [transcript] [active]
run() {
  jq -nc --arg s "$1" --arg m "$2" --arg tp "${3:-}" --argjson a "${4:-false}" --arg c "$H/proj" \
    '{session_id:$s, transcript_path:$tp, cwd:$c, stop_hook_active:$a, last_assistant_message:$m}' \
    | HOME="$H" POL_SH="$T/pol-stub.sh" bash "$HOOK" 2>/dev/null
}
blocks()  { printf '%s' "$1" | jq -e '.decision == "block"' >/dev/null 2>&1; }
reason()  { printf '%s' "$1" | jq -r '.reason // empty' 2>/dev/null; }
advises() { printf '%s' "$1" | jq -e '.systemMessage and (.decision | not)' >/dev/null 2>&1; }
silent()  { [ -z "$1" ]; }
msg()     { printf '%s' "$1" | jq -r '.systemMessage // empty' 2>/dev/null; }
nodec()   { printf '%s' "$1" | jq -e 'has("decision") | not' >/dev/null 2>&1; }
# note <out> <fixed text>: an advisory carrying that text and never a decision.
note()    { advises "$1" && nodec "$1" && msg "$1" | rg -qF -- "$2"; }
cleanup() {
  rm -f /tmp/claude-format-gate-fg* /tmp/claude-format-tripped-fg* /tmp/claude-format-reminded-fg*
  rm -rf /tmp/claude-dense-shapes-fg* /tmp/claude-snoozed-*-fg*
  rm -f /tmp/claude-heedkey-*-fg*
}
cleanup
EMPTY="$T/empty.jsonl"; tx "$EMPTY" "ok"
pad=$(printf 'filler sentence to reach the length floor. %.0s' $(seq 1 20))
sent='This sentence is plain prose that keeps going to make the reply long. '
# 70 chars a sentence; the cap is 2600 and the block line is 3250 (125 percent).
long=$(for i in $(seq 1 50); do printf '%s' "$sent"; done)

echo "== filename-dot: only a path with a slash is noted, and never blocks =="
out=$(run fgt00001 'The notes are at ~/foo/bar.md.' "$EMPTY")
note "$out" "paths, clickable: ~/foo/bar.md" && ok "~/foo/bar.md. is noted, no decision" || bad "~/foo/bar.md. noted: $out"
blocks "$out" && bad "filename-dot must not block" || ok "the note names the span and the class never blocks"
jq -e 'select(.hook_id=="filename-dot" and .action=="soft")' "$WARN_LOG_STORE" >/dev/null 2>&1 \
  && ok "the note logs filename-dot as soft" || bad "filename-dot soft row missing"
jq -e 'select(.hook_id=="filename-dot" and .action=="block")' "$WARN_LOG_STORE" >/dev/null 2>&1 \
  && bad "filename-dot logged a block" || ok "filename-dot never logs a block"
out=$(run fgt00002 'See docs/foo.md. Then go.' "$EMPTY")
note "$out" "paths, clickable: docs/foo.md" && ok "bare relative docs/foo.md. is noted" || bad "bare relative docs/foo.md. noted: $out"
out=$(run fgt00003 'The failure is at `src/app.ts:42`.' "$EMPTY")
note "$out" "paths, clickable:" && ok "backticked path with :line then period is noted" || bad "backticked path with :line then period noted: $out"
out=$(run fgt00004 'The brief is at `docs/foo.md`. Hand it off.' "$EMPTY")
note "$out" "paths, clickable:" && ok "backticked slash path then period is noted" || bad "backticked slash path then period noted: $out"
out=$(run fgt00005 'I changed settings.json. Everything else is the same.' "$EMPTY")
silent "$out" && ok "bare filename then period passes" || bad "bare filename then period passes: $out"
out=$(run fgt00006 'I changed `settings.json`. Nothing else moved.' "$EMPTY")
silent "$out" && ok "backticked bare filename then period passes" || bad "backticked bare filename then period passes: $out"
out=$(run fgt00007 'The brief is at `src/foo.md`, ready to hand off.' "$EMPTY")
silent "$out" && ok "path followed by a comma passes" || bad "path followed by a comma passes: $out"
out=$(run fgt00008 'Run this:
```
cat docs/foo.md.
```
Done, nothing else.' "$EMPTY")
silent "$out" && ok "path inside a fenced block passes" || bad "path inside a fenced block passes: $out"

echo "== emdash =="
out=$(run fgt00009 "The fix is small $D one line in the hook." "$EMPTY")
blocks "$out" && ok "em-dash in prose blocks" || bad "em-dash in prose blocks"
printf '%s' "$out" | rg -q 'disgrace' && ok "em-dash block carries the owner's wording" || bad "owner wording: $out"
printf '%s' "$out" | rg -q 're-send as is' && ok "em-dash block says how to insist" || bad "insist escape: $out"
out=$(run fgt00010 "The fix is small, one line in the hook." "$EMPTY")
silent "$out" && ok "clean prose passes" || bad "clean prose passes: $out"
out=$(run fgt00040 "Pages 3–5 cover backlog-triage-1019 and the pre-commit hook - see guard-absence-claim for the rest" "$EMPTY")
silent "$out" && ok "hyphens, en-dashes and slugs pass" || bad "hyphens, en-dashes and slugs pass: $out"
out=$(run fgt00011 "The regex is \`a${D}b\` and nothing else." "$EMPTY")
silent "$out" && ok "em-dash inside inline code passes" || bad "em-dash inside inline code passes: $out"
out=$(run fgt00012 "Quote:
> keep it short $D no filler
and that is the rule." "$EMPTY")
silent "$out" && ok "em-dash inside a blockquote passes" || bad "em-dash inside a blockquote passes: $out"
out=$(run fgt00013 "Output:
\`\`\`
build $D ok
\`\`\`
Fine." "$EMPTY")
silent "$out" && ok "em-dash inside a fenced block passes" || bad "em-dash inside a fenced block passes: $out"

echo "== terse-reply =="
out=$(run fgt00014 "$long" "$EMPTY")
blocks "$out" && ok "prose well past the cap blocks" || bad "prose well past the cap blocks"
reason "$out" | rg -q 'prose cap 2600 chars' && ok "reason states the cap in the shared words" || bad "reason states the cap"
# Between the cap and 125 percent of it the reply is advisory; the line is 3250.
over10=$(printf '%s' "${long:0:2860}")
out=$(run fgt00070 "$over10" "$EMPTY")
note "$out" "terse-reply WARN" && ok "10 percent over the cap is advisory" || bad "10 percent over: $out"
over30=$(printf '%s' "${long:0:3380}")
out=$(run fgt00071 "$over30" "$EMPTY")
blocks "$out" && ok "30 percent over the cap blocks" || bad "30 percent over: $out"
under=$(printf '%s' "${long:0:3200}")
out=$(run fgt00072 "$under" "$EMPTY")
note "$out" "terse-reply WARN" && ok "just under 125 percent (3200) is still advisory" || bad "3200 chars: $out"
# Lines other hooks require are not counted: a long box or /goal line adds nothing.
boxrows=$(for i in $(seq 1 50); do printf '│ %s\n' "${long:0:68}"; done)
out=$(run fgt00073 "Short answer first.
┌─ plan
$boxrows
└─" "$EMPTY")
[ -z "$(printf '%s' "$out" | jq -r '.decision // empty')" ] && ok "a long box does not block" || bad "long box blocked: $out"
essay=$(printf '│ This line is prose dressed up as a box so that it escapes the length cap entirely, and it goes on.\n%.0s' $(seq 1 60))
out=$(run fgt00078 "Short answer first.
$essay" "$EMPTY")
[ "$(printf '%s' "$out" | jq -r '.decision // empty')" = block ] && ok "an essay in box lines still blocks" || bad "box essay passed: $out"
out=$(run fgt00074 "Short answer first.
/goal ${long}" "$EMPTY")
[ -z "$(printf '%s' "$out" | jq -r '.decision // empty')" ] && ok "a long /goal line does not block" || bad "long /goal blocked: $out"
out=$(run fgt00075 "Short answer first.
Secret-scan note: ${long}" "$EMPTY")
silent "$out" && bad "a secret-scan line counted as prose should block" || ok "control: the same text on a plain line is still prose"
out=$(run fgt00076 "Short answer first.
secret-scan: ${long}" "$EMPTY")
[ -z "$(printf '%s' "$out" | jq -r '.decision // empty')" ] && ok "a line naming secret-scan does not block" || bad "secret-scan blocked: $out"
out=$(run fgt00077 "Short answer first.
/core-dump: ${long}" "$EMPTY")
[ -z "$(printf '%s' "$out" | jq -r '.decision // empty')" ] && ok "a line naming /core-dump does not block" || bad "core-dump blocked: $out"
out=$(run fgt00078 "Short answer first.
${long}" "$EMPTY")
blocks "$out" && ok "control: the same long text on plain lines blocks" || bad "control long text: $out"
out=$(run fgt00015 "Short answer, one thing to do." "$EMPTY")
silent "$out" && ok "a short reply passes" || bad "a short reply passes: $out"
ASKED="$T/asked.jsonl"; tx "$ASKED" "write a detailed report on this"
out=$(run fgt00016 "$long" "$ASKED")
blocks "$out" && bad "an owner who asked for length is not blocked" || ok "an owner who asked for length is not blocked"
mid=$(printf 'Plain filler sentence to land in the warn tier only. %.0s' $(seq 1 30))
out=$(run fgt00017 "$mid" "$EMPTY")
advises "$out" && printf '%s' "$out" | rg -q 'terse-reply WARN' && ok "between warn and cap is advisory, not a block" || bad "warn tier advisory: $out"

rows=$(printf '| column one | column two | column three |\n%.0s' $(seq 1 80))
out=$(run fgt00060 "Short answer.
$rows" "$EMPTY")
silent "$out" && ok "a long markdown table does not count as prose" || bad "table rows counted as prose: $out"

echo "== relpath: a file named by a partial path, never given in full, is noted and never blocks =="
NOTES=/Users/alcatraz627/.claude/assets/reports/x/notes.md
W="$T/w.jsonl"; tx "$W" "write the plan" "$NOTES"
out=$(run fgt00018 "I wrote x/notes.md and it covers the plan." "$W")
note "$out" "full paths: x/notes.md" && ok "x/notes.md named, never absolute, is noted" || bad "x/notes.md named, never absolute: $out"
msg "$out" | rg -qF "$NOTES" && bad "a file outside the project is not suggested" || ok "a file outside the project and scratchpad gets no suggested path"
msg "$out" | rg -q 'its absolute path' && ok "an unsuggested item still says its absolute path" || bad "no-suggestion wording: $(msg "$out")"
jq -e 'select(.hook_id=="relpath" and .action=="soft")' "$WARN_LOG_STORE" >/dev/null 2>&1 \
  && ok "the note logs relpath as soft" || bad "relpath soft row missing"
jq -e 'select(.hook_id=="relpath" and .action=="block")' "$WARN_LOG_STORE" >/dev/null 2>&1 \
  && bad "relpath logged a block" || ok "relpath never logs a block"
out=$(run fgt00062 "I wrote notes.md and it covers the plan." "$W")
silent "$out" && ok "a bare filename of a written file passes" || bad "bare filename of a written file: $out"
PN="$H/proj/notes.md"; WP="$T/wp.jsonl"; tx "$WP" "write the plan" "$PN"
out=$(run fgt00063 "I wrote proj/notes.md and it covers the plan." "$WP")
note "$out" "proj/notes.md -> ~/proj/notes.md" && ok "a file inside the project is given by its full path" || bad "in-project suggestion: $out"
SPN="/private/tmp/claude-501/-x/fgt00064/scratchpad/draft/out.md"; WS="$T/ws.jsonl"; tx "$WS" "write the plan" "$SPN"
out=$(run fgt00064 "I wrote draft/out.md and it covers the plan." "$WS")
note "$out" "$SPN" && ok "a file in the session's scratchpad is given by its full path" || bad "scratchpad suggestion: $out"
OTH="/private/tmp/claude-501/-x/other-session/wt/docs/structure.md"; WO="$T/wo.jsonl"; tx "$WO" "write the plan" "$OTH"
out=$(run fgt00065 "I wrote docs/structure.md and it covers the plan." "$WO")
note "$out" "full paths: docs/structure.md" && ! msg "$out" | rg -q 'private/tmp' && ok "another session's worktree is never suggested" || bad "other worktree leaked: $out"
out=$(run fgt00019 "I wrote $NOTES and it covers the plan." "$W")
silent "$out" && ok "absolute path given passes" || bad "absolute path given passes: $out"
out=$(run fgt00020 "I wrote x/notes.md, at $NOTES, and it covers the plan." "$W")
silent "$out" && ok "relative mention plus an absolute one passes" || bad "relative plus absolute passes: $out"
out=$(run fgt00021 "The plan is written and it covers everything." "$W")
silent "$out" && ok "file not mentioned at all passes" || bad "file not mentioned passes: $out"
HW="$T/hw.jsonl"; tx "$HW" "write the plan" "$H/proj/notes.md"
out=$(run fgt00022 'Plan is in ~/proj/notes.md, one thing to check.' "$HW")
silent "$out" && ok "tilde form of the written path passes" || bad "tilde form passes: $out"
out=$(run fgt00023 'The plan is at `proj/notes.md` for you.' "$HW")
note "$out" "full paths: proj/notes.md" && ok "backticked partial path of a written file is noted" || bad "backticked partial path noted: $out"
out=$(run fgt00066 'The plan is at `notes.md` for you.' "$HW")
silent "$out" && ok "backticked bare name of a written file passes" || bad "backticked bare name passes: $out"
out=$(run fgt00024 'Wrote the plan, see:
```
notes.md
```
Done.' "$W")
silent "$out" && ok "mention only inside a fence is not a mention" || bad "fence-only mention: $out"
OLD="$T/old.jsonl"
{ jq -cn '{type:"user", message:{role:"user", content:"first ask"}}'
  jq -cn --arg p "$NOTES" '{type:"assistant", message:{role:"assistant", content:[{type:"tool_use", name:"Write", input:{file_path:$p}}]}}'
  jq -cn '{type:"user", message:{role:"user", content:[{type:"tool_result", content:"ok"}]}}'
  jq -cn '{type:"user", message:{role:"user", content:"second ask"}}'
} > "$OLD"
out=$(run fgt00025 "Yes, notes.md came from the earlier turn." "$OLD")
silent "$out" && ok "a file written in an earlier turn is not this turn's" || bad "earlier-turn file counted: $out"
out=$(run fgt00026 'Findings are in assets/reports/20261019-x/report.md for review.' "$EMPTY")
note "$out" "full paths: assets/reports/20261019-x/report.md" && ok "deliverable-root relative path is noted" || bad "deliverable-root relative path noted: $out"
out=$(run fgt00027 'Findings are in /Users/alcatraz627/.claude/assets/reports/20261019-x/report.md for review.' "$EMPTY")
silent "$out" && ok "deliverable-root absolute path passes" || bad "deliverable-root absolute passes: $out"
out=$(run fgt00061 'Wrote /Users/alcatraz627/.claude/docs/architecture/overview.md, and docs/architecture/overview.md holds the flow.' "$EMPTY")
silent "$out" && ok "relative mention is exempt when its absolute form is in the reply" || bad "absolute form present exempt: $out"
out=$(run fgt00028 'Run cat docs/architecture/overview.md to see the flow.' "$EMPTY")
silent "$out" && ok "command position is exempt" || bad "command position exempt: $out"
out=$(run fgt00029 'The guard lives at docs/notes/design.md:42 if you want the rationale.' "$EMPTY")
silent "$out" && ok "file:line reference is exempt" || bad "file:line exempt: $out"
out=$(run fgt00030 'The change is in scripts/hooks/format-gate-stop.sh and its suite.' "$EMPTY")
silent "$out" && ok "ordinary repo talk outside the roots passes" || bad "repo talk passes: $out"

echo "== merged block: one pass, every blocking class, one line =="
# run_pol <sid8> <reply> <policy stub> [env flag] is defined below; the merged
# case needs prose-smell enforced, so the stub is made first.
printf '#!/usr/bin/env bash\n[ "$2" = gates.prose_smell ] && echo enforce\nexit 0\n' > "$T/pol-ps-enforce.sh"
printf '#!/usr/bin/env bash\n[ "$2" = gates.prose_smell ] && echo warn\nexit 0\n' > "$T/pol-ps-warn.sh"
run_pol() {
  jq -nc --arg s "$1" --arg m "$2" --arg tp "$EMPTY" --arg c "$H/proj" \
    '{session_id:$s, transcript_path:$tp, cwd:$c, stop_hook_active:false, last_assistant_message:$m}' \
    | env PROSE_SMELL_ENFORCE="${4:-0}" HOME="$H" POL_SH="$3" bash "$HOOK" 2>/dev/null
}
smelly="Great question. **one** **two** **three** **four** **five** **six**"
out=$(run_pol fgt00031 "$smelly I wrote x/notes.md $D see ~/foo/bar.md. $long" "$T/pol-ps-enforce.sh")
blocks "$out" && ok "three blocking classes at once is one block" || bad "merged block: $out"
r=$(reason "$out")
for c in emdash terse-reply prose-smell; do
  printf '%s' "$r" | rg -q "$c" && ok "the one reason lists $c" || bad "the one reason lists $c: $r"
done
printf '%s' "$r" | rg -q 'filename-dot|relpath' && bad "a path class leaked into the block reason: $r" || ok "the block reason carries no path class"
[ "$(printf '%s' "$r" | wc -l | tr -d ' ')" = "0" ] && [ "${#r}" -le 500 ] && ok "reason is one line within 500 chars (${#r})" || bad "reason shape (${#r} chars)"
[ -f /tmp/claude-format-tripped-fgt00031 ] && rg -q 'classes=.*emdash' /tmp/claude-format-tripped-fgt00031 && rg -q 'classes=.*terse-reply' /tmp/claude-format-tripped-fgt00031 && rg -q 'cap=2600' /tmp/claude-format-tripped-fgt00031 \
  && ok "the tripped file records classes and cap" || bad "the tripped file records classes and cap"
rg -q 'filename-dot|relpath' /tmp/claude-format-tripped-fgt00031 && bad "the tripped file lists a path class" || ok "the tripped file lists no path class"
jq -e 'select(.hook_id=="emdash" and .action=="block")' "$WARN_LOG_STORE" >/dev/null 2>&1 \
  && jq -e 'select(.hook_id=="terse-reply" and .action=="block")' "$WARN_LOG_STORE" >/dev/null 2>&1 \
  && jq -e 'select(.hook_id=="prose-smell" and .action=="block")' "$WARN_LOG_STORE" >/dev/null 2>&1 \
  && jq -e 'select(.hook_id=="format-gate" and .action=="block")' "$WARN_LOG_STORE" >/dev/null 2>&1 \
  && ok "per-class rows and a format-gate row are logged" || bad "per-class rows and a format-gate row are logged"
# A path found in the same reply as a block goes to the owner in the same output.
PN="$H/proj/notes.md"; WP="$T/wp.jsonl"; tx "$WP" "write the plan" "$PN"
out=$(run fgt00032 "I wrote proj/notes.md $D and it covers the plan." "$WP")
blocks "$out" && reason "$out" | rg -q 'emdash' && ok "an em-dash reply with a partial path blocks on the em-dash" || bad "em-dash plus path: $out"
reason "$out" | rg -q 'relpath|full paths' && bad "the block reason carries the path note" || ok "the block reason has the em-dash fragment and no path class"
msg "$out" | rg -qF "proj/notes.md -> ~/proj/notes.md" && ok "the same output's systemMessage carries the path to paste" || bad "path missing from the block output: $out"
many="I wrote proj/notes.md $D and also x/x.py. See \`docs/aaaaaaaaaaaaaaaaaaaaaaaaaaaa/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.md\`. Then ~/zzzzzzzzzzzzzzzzzzzzzzzzzzz/qqqqqqqqqqqqqqqqqqqqqqqqqq.md. $D $long"
W2="$T/w2.jsonl"; tx "$W2" "write the plan" "$PN" "/Users/alcatraz627/.claude/assets/reports/x/second-file.py" "/Users/alcatraz627/.claude/assets/reports/x/x.py"
out=$(run fgt00033 "$many" "$W2")
r=$(reason "$out")
[ "${#r}" -le 500 ] && [ "$(printf '%s' "$r" | wc -l | tr -d ' ')" = "0" ] && blocks "$out" && ok "a worst-case reason stays one line within 500 chars (${#r})" || bad "worst-case reason (${#r} chars)"
printf '%s' "$r" | rg -q 'emdash' && ok "the em-dash fragment survives the 500-char clip" || bad "em-dash fragment clipped: $r"
msg "$out" | rg -qF "~/proj/notes.md" && ok "the path to paste is in systemMessage, outside the clip" || bad "the path to paste is missing from systemMessage: $out"
# A path note alone never carries a decision, whatever the path form.
for pr in 'See docs/foo.md. Then go.' 'The notes are at ~/foo/bar.md.' 'Findings are in assets/reports/20261019-x/report.md for review.'; do
  out=$(run fgt00080 "$pr" "$EMPTY")
  nodec "$out" && [ -n "$out" ] && ok "a path note has no decision: ${pr:0:30}" || bad "path note decision: $out"
  rm -f /tmp/claude-format-gate-fgt00080
done

echo "== advisory classes never block =="
bold="**one** **two** **three** **four** **five** **six** $pad"
out=$(run fgt00033 "$bold" "$EMPTY")
advises "$out" && printf '%s' "$out" | rg -q 'prose-smell' && ok "bold-spam is a prose-smell advisory, not a block" || bad "prose-smell advisory: $out"
# The owner's policy gates.prose_smell=enforce keeps the old rule: two block-tier tells block.
two="Great question. **one** **two** **three** **four** **five** **six** $pad"
out=$(run_pol fgtps001 "$two" "$T/pol-ps-enforce.sh")
blocks "$out" && reason "$out" | rg -q 'prose-smell' && ok "policy enforce: two block-tier tells block" || bad "policy enforce did not block: $out"
out=$(run_pol fgtps002 "$bold" "$T/pol-ps-enforce.sh")
advises "$out" && ok "policy enforce: one tell stays advisory" || bad "policy enforce, one tell: $out"
out=$(run_pol fgtps003 "$two" "$T/pol-ps-warn.sh" 1)
advises "$out" && printf '%s' "$out" | rg -q 'prose-smell' && ok "policy warn: two tells advise, the policy beats the env flag" || bad "policy warn: $out"
tx "$T/dense.jsonl" "Fix the export. Make sure the spreadsheet keeps the leading zeros in the identifier column."
out=$(run fgt00034 "The export is fixed and the suite is green. $pad" "$T/dense.jsonl")
# The python verdict reads the transcript's own last assistant text, so seed it.
jq -cn --arg a "Done. The export is fixed and the suite is green. $pad" '{type:"assistant", message:{role:"assistant", content:[{type:"text", text:$a}]}}' >> "$T/dense.jsonl"
out=$(run fgt00035 "Done. The export is fixed and the suite is green. $pad" "$T/dense.jsonl")
printf '%s' "$out" | rg -q 'dense-briefing' && bad "dense-briefing is retired but still advised: $out" || ok "dense-briefing is retired: the same reply draws no advisory"

echo "== loop safety =="
run fgt00040 "Small $D change." "$EMPTY" >/dev/null
out=$(run fgt00040 "Small $D change." "$EMPTY")
blocks "$out" && bad "identical re-emit must not block again" || ok "identical re-emit steps aside"
printf '%s' "$out" | jq -e '.systemMessage' >/dev/null 2>&1 && ok "the step-aside leaves a note" || bad "the step-aside leaves a note"
jq -e 'select(.kind=="heed" and .heeded=="false" and .hook_id=="emdash")' "$WARN_LOG_STORE" >/dev/null 2>&1 \
  && ok "an ignored block records heeded false for its class" || bad "heeded false row for an ignored block"
run fgt00041 "First $D try." "$EMPTY" >/dev/null
out=$(run fgt00041 "Second $D try, reworded." "$EMPTY")
blocks "$out" && ok "a reworded reply that still has one blocks again" || bad "reworded reply blocks again"
run fgt00042 "Try $D one." "$EMPTY" >/dev/null
run fgt00042 "Try $D two." "$EMPTY" >/dev/null
run fgt00042 "Try $D three." "$EMPTY" >/dev/null
out=$(run fgt00042 "Try $D four." "$EMPTY")
blocks "$out" && bad "the fourth consecutive block must step aside" || ok "three blocks in a row end the loop"
out=$(run fgt00043 "Bad $D reply." "$EMPTY" true)
blocks "$out" && bad "stop_hook_active must let the turn end" || ok "stop_hook_active lets the turn end"
printf '%s' "$out" | jq -e '.systemMessage' >/dev/null 2>&1 && ok "stop_hook_active still leaves a note" || bad "stop_hook_active note"
run fgt00044 "Bad $D reply." "$EMPTY" >/dev/null
run fgt00044 "Good, reply." "$EMPTY" >/dev/null
[ ! -f /tmp/claude-format-gate-fgt00044 ] && jq -e 'select(.kind=="heed" and .heeded=="true" and .hook_id=="emdash")' "$WARN_LOG_STORE" >/dev/null 2>&1 \
  && ok "a clean reply after a block records heeded true and clears the marker" || bad "heed true on a clean reply"
run fgt00045 "Bad $D reply. $long" "$EMPTY" >/dev/null
run fgt00045 "Good, reply, see ~/a/b.md, ok." "$EMPTY" >/dev/null
n=$(jq -c 'select(.kind=="heed" and .heeded=="true" and (.ref // "" | test("fgt00045")))' "$WARN_LOG_STORE" 2>/dev/null | wc -l | tr -d ' ')
[ "$n" = "2" ] && ok "heed is recorded once per class that was open (emdash and terse-reply)" || bad "per-class heed rows (got $n)"
out=$(run fgt00046 "The stale transcript says clean." "$EMPTY")
silent "$out" && ok "a clean reply with no marker is silent" || bad "clean reply silent: $out"

echo "== mutes and policy =="
for pair in "filename-dot:The notes are at ~/foo/bar.md." "emdash:Small $D change." "relpath:Findings are in assets/reports/20261019-x/report.md for review."; do
  c="${pair%%:*}"; msg="${pair#*:}"
  touch "$H/.claude/.no-$c-gate"
  out=$(run "fgm${c:0:5}0" "$msg" "$EMPTY")
  silent "$out" && ok "mute file silences $c" || bad "mute file silences $c: $out"
  rm -f "$H/.claude/.no-$c-gate"
done
touch "$H/.claude/.no-terse-reply-gate"
out=$(run fgmterse0 "$long" "$EMPTY")
blocks "$out" && bad "terse mute file ignored" || ok "mute file silences terse-reply"
rm -f "$H/.claude/.no-terse-reply-gate"
touch "$H/.claude/.no-format-gate"
out=$(run fgmall00 "Small $D change." "$EMPTY")
silent "$out" && ok "the merged mute silences everything" || bad "merged mute: $out"
rm -f "$H/.claude/.no-format-gate"
out=$(FORMAT_GATE_OFF=1 run fgmoff00 "Small $D change." "$EMPTY")
silent "$out" && ok "FORMAT_GATE_OFF=1 silences everything" || bad "FORMAT_GATE_OFF"
out=$(EMDASH_OFF=1 run fgmenv00 "Small $D change." "$EMPTY")
silent "$out" && ok "EMDASH_OFF=1 still honoured" || bad "EMDASH_OFF"
printf '#!/usr/bin/env bash\n[ "$2" = gates.terse_reply ] && echo off\nexit 0\n' > "$T/pol-off.sh"
out=$(jq -nc --arg m "$long" --arg tp "$EMPTY" '{session_id:"fgmpol00", transcript_path:$tp, stop_hook_active:false, last_assistant_message:$m}' | HOME="$H" POL_SH="$T/pol-off.sh" bash "$HOOK" 2>/dev/null)
silent "$out" && ok "policy gates.terse_reply=off silences terse-reply" || bad "policy off: $out"
printf '#!/usr/bin/env bash\n[ "$2" = gates.terse_reply ] && echo warn\nexit 0\n' > "$T/pol-warn.sh"
out=$(jq -nc --arg m "$long" --arg tp "$EMPTY" '{session_id:"fgmpol01", transcript_path:$tp, stop_hook_active:false, last_assistant_message:$m}' | HOME="$H" POL_SH="$T/pol-warn.sh" bash "$HOOK" 2>/dev/null)
blocks "$out" && bad "policy warn must not block" || ok "policy gates.terse_reply=warn downgrades to advisory"

echo "== the transcript tail lags; the Stop input is judged =="
STALE="$T/stale.jsonl"; tx "$STALE" "ok"
jq -cn --arg a "Stale $D reply." '{type:"assistant", message:{role:"assistant", content:[{type:"text", text:$a}]}}' >> "$STALE"
out=$(run fgt00050 "Current clean reply." "$STALE")
silent "$out" && ok "a stale em-dash in the transcript does not block a clean reply" || bad "stale transcript: $out"

cleanup
echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
