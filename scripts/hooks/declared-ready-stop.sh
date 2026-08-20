#!/usr/bin/env bash
# declared-ready-stop.sh — Stop hook that catches a success claim ("done / works /
# fixed / passing / verified") the agent makes about edited source WITHOUT having
# exercised the path it changed this turn.
#
# This is the mechanical enforcement for the atone pattern
# `declared-ready-without-runtime-exercise` (S3, 5–6× recurrence across projects
# and models). Advisory text never bound it; only a Stop hook sees the completed
# turn and can refuse a premature "done".
#
# v2 — run-SUFFICIENCY, not run-EXISTENCE. Where v1 asked "did ANY allow-listed
# command appear", v2 runs a precedence pipeline that separates the honest hedge
# (self-disclosed gap → reinforce) from the silent over-claim (nothing exercised
# the change → block), and stops blocking cases that had nothing to exercise
# (comment-only diffs) or genuinely ran the change through a CLI the old
# allow-list missed (project-CLI run → soft note).
#
#   Gate0  source/test file edited this session
#   Det1a  the turn-final message ADVERTISES a localhost URL whose port no tool
#          touched this turn → block once (an advertised URL is an implicit
#          success claim; atone 2026-07-10 "user's first click failed on both")
#   Det1   the turn-final message makes a co-located OR opening success claim
#   ── pipeline (first branch decides) ──
#   B  comment/docs-only diff (added lines all comment/blank)  → SILENT
#   RAN  a real test/program ran (allow-list run OR pass/fail in tool_result) → SILENT
#   C  fresh coverage report + diff-cover installed → cover>0 SILENT / cover==0 BLOCK
#   A  self-disclosed gap (scoped "not verified" / trailing user-observation "?") → SOFT
#   W  a project-CLI / non-inspection command produced real output → SOFT
#   E/none  nothing exercised the change → BLOCK (RSC-specific reason for tsx-in-Next)
#
# DESIGN NOTE — hard-block recall on the *historical* true-positive set is LOW BY
# DESIGN, not a gap. The empirical corpus TPs all self-disclosed their gap ("verified
# X but NOT Y", "compile-only", "bash -n clean"), and a self-disclosed gap is the
# agent doing the RIGHT thing — Stage A demotes those to a reinforcement SOFT note,
# not a block. BLOCK is reserved for the UN-disclosed over-claim (e.g. "Done.
# Type-checks clean." on an interaction component, with no scoping clause). The count
# of *hard blocks* drops; the count of *correct* hard blocks (silent over-claims)
# stays. That is precision, not coverage loss.
#
# Contract (mirrors review-gate-stop.sh — a DIRECT settings.json Stop hook, NOT
# via the hook-orchestrator whose task stdout → /dev/null can't carry a decision):
#   - block:    {"decision":"block","reason":…}  → reason fed to agent, turn stays open
#   - surface:  {"systemMessage":…}              → non-blocking note
#   - silent:   exit 0
#
# Tuning posture: UNDER-fire, never over-fire. Loop-safe: blocks once per
# claim-signature, then demotes to a soft note. Mute: touch ~/.claude/.no-declared-ready-gate

set -uo pipefail
[ -f "$HOME/.claude/.no-declared-ready-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tp" ] && [ -f "$tp" ] || exit 0
sid8="${sid:0:8}"

WARN="$HOME/.claude/scripts/hooks/warn-log.sh"
soft_note() {  # $1 = message text
  jq -cn --arg m "$1" '{systemMessage:$m}' 2>/dev/null || true
  [ -x "$WARN" ] && bash "$WARN" --hook declared-ready --action soft --heeded unknown >/dev/null 2>&1 || true
  exit 0
}

# ── Gate 0: only turns that actually changed source/test files this session ──
# A "done" with no edits is almost always conversational ("done reading"). Reuse the
# session edit-list maintained by track-edits-session.sh.
#
# A no-source-edit turn is no longer a plain exit. It falls through to Stage P below,
# which handles the one completion claim that arrives WITHOUT an edit: a verdict about
# repo state. Everything between here and Stage P is inspection only, and Stage P
# exits before Det1a, so a no-edit turn can never reach the blocking pipeline.
EDITED="/tmp/claude-edited-files-${sid8}"
src_edited=0
if [ -s "$EDITED" ] && rg -qi '\.(py|ts|tsx|js|jsx|mjs|cjs|go|rs|swift|rb|java|kt|c|cc|cpp|h|hpp|sh|css|scss|sass|less|vue|svelte)$' "$EDITED" 2>/dev/null; then
  src_edited=1
fi

# A style-only turn (css/scss/vue/svelte and nothing else) used to exit above, which
# made the dark-AND-light reminder further down unreachable for exactly the surfaces
# it names. Those turns are admitted now, but they get a soft screenshot nudge rather
# than a block: this file class has no fire-rate history yet, and a colour-variable
# tweak does not deserve the same consequence as an unexercised code path.
style_only=0
if [ "$src_edited" = 1 ] \
   && ! rg -qi '\.(py|ts|tsx|js|jsx|mjs|cjs|go|rs|swift|rb|java|kt|c|cc|cpp|h|hpp|sh)$' "$EDITED" 2>/dev/null; then
  style_only=1
fi

# ── Turn boundary: slice the tail at the LAST REAL USER MESSAGE, not a blind tail ──
# A real user message (type=="user" with a string body or a body carrying a text
# item) starts the current turn; a pure tool_result array is a mid-turn return. This
# mirrors the replay harness's turn model, so run/edit detection sees only THIS turn.
window=$(tail -n 1200 "$tp" 2>/dev/null) || exit 0
[ -n "$window" ] || exit 0
boundary=$(printf '%s\n' "$window" | jq -rc '
  select(.type=="user"
    and ( (.message.content|type=="string" and (.|length>0))
       or (.message.content|type=="array" and (any(.[]?; .type=="text"))) ))
  | input_line_number' 2>/dev/null | tail -n 1)
if [ -n "$boundary" ]; then
  turn_json=$(printf '%s\n' "$window" | tail -n +"$boundary")
else
  turn_json="$window"   # no user boundary in window (very long turn) → use whole tail
fi
[ -n "$turn_json" ] || exit 0

# ── Detection 1: does the FINAL assistant message claim success? ──────────────
last_asst=$(printf '%s\n' "$turn_json" | jq -rc 'select(.type=="assistant")' 2>/dev/null | tail -n 1)
[ -n "$last_asst" ] || exit 0
claim_text=$(printf '%s' "$last_asst" | jq -r '.message.content[]? | select(.type=="text") | .text' 2>/dev/null)
[ -n "$claim_text" ] || exit 0

# ── Stage P: a verdict about REPO STATE, asserted without re-reading it ───────
# The sibling failure to this hook's own. `declared-ready` asks whether you ran the
# code you changed. This asks whether you looked before describing state you did not
# change. Both are completion claims; only the first needs an edit to exist.
#
# Grounded in atone `status-verdict-from-stale-mental-model-no-re-check` (6 events,
# S3), whose first instance shipped a "READY TO COMMIT + PUSH" box with a stage-list
# for three commits the owner had already pushed hours earlier. Its recorded precheck
# is the rule enforced here, verbatim: a verdict block naming repo state must be
# immediately preceded by a fresh verification call, and a check from earlier in the
# session does not count.
#
# Scoped to REPO state on purpose. The register's other five instances are context
# pressure (already gated by ctx-claim-stop.sh), a doc's line count, and live process
# identity. Those need different evidence and get their own gates or none; a single
# regex spanning all of them would be the vocabulary sprawl this detector was
# measured out of. Corpus rate for this claim shape: 1.21% of assistant messages
# (132 of 10,934), and the git-read exemption removes the turns that did look.
#
# SOFT ONLY, per ruling D2a: a new gate ships warn-tier and is promoted on evidence.
if [ "$src_edited" = 0 ]; then
  REPO_CLAIM_RE='\b((is|are|remains?|stays?)[[:space:]]+(still[[:space:]]+)?(un)?committed|(nothing|everything|all|both)[[:space:]]+(is|are|was|were)[[:space:]]+(committed|pushed|staged)|working[[:space:]]+tree[[:space:]]+is[[:space:]]+clean|(already|now)[[:space:]]+(committed|pushed)|ready[[:space:]]+to[[:space:]]+(commit|push)|(has|have)[[:space:]]+been[[:space:]]+(committed|pushed))\b'
  # "commit" is three different words in English and only one of them is git's.
  # Measured false fires before this guard existed: "she is committed to the
  # redesign" (a promise), "the transaction is committed once the WAL flush
  # returns" and "the database transaction has been committed" (a DB commit),
  # "ready to commit to that design" (a promise again), and "everything is pushed
  # to the edge cache" (a deploy target that is not a remote). The disqualifier is
  # applied PER SENTENCE, so one such phrase elsewhere in a long message cannot
  # suppress a genuine verdict in another sentence, and vice versa.
  REPO_DISQUAL_RE='\b(commit(ted)?[[:space:]]+to[[:space:]]|transaction|database|[[:space:]]db[[:space:]]|pushed[[:space:]]+to[[:space:]]+(the[[:space:]]+)?(edge|cache|cdn|queue|client|browser|prod|production|staging))\b'
  # Quoted output is not a claim. A message showing `echo "everything is committed"`
  # in a fenced block, or citing a log line, is describing rather than asserting.
  # Same stripper prose-smell-stop.sh:59-61 uses, for the same reason.
  repo_prose=$(printf '%s\n' "$claim_text" \
    | awk 'BEGIN{f=0} /^[[:space:]]*```/{f=!f; next} !f{print}' \
    | sed -e 's/`[^`]*`//g' -e '/^[[:space:]]*>/d')
  repo_claim=0
  while IFS= read -r s; do
    printf '%s' "$s" | rg -qiP "$REPO_CLAIM_RE" 2>/dev/null || continue
    printf '%s' "$s" | rg -qiP "$REPO_DISQUAL_RE" 2>/dev/null && continue
    repo_claim=1; break
  done <<EOF
$(printf '%s' "$repo_prose" | rg -oP '[^.!?\n]+[.!?]?' 2>/dev/null)
EOF
  if [ "$repo_claim" = 1 ]; then
    # Evidence: any state-READING git/gh command this turn. A write (commit, push,
    # add) is not evidence — it changes state without reporting what is there, which
    # is how the original event happened: the work was done, the tree was never read.
    turn_bash=$(printf '%s\n' "$turn_json" \
      | jq -r 'select(.type=="assistant") | .message.content[]?
          | select(.type=="tool_use" and .name=="Bash") | .input.command // empty' 2>/dev/null)
    if ! printf '%s\n' "$turn_bash" | rg -qP '\bgit[[:space:]]+(status|log|diff|show|rev-parse|ls-files|branch)\b|\bgh[[:space:]]+(pr|repo)[[:space:]]+(view|list|status)\b' 2>/dev/null; then
      REPOMARK="/tmp/claude-declared-ready-repostate-${sid8}"
      if [ ! -f "$REPOMARK" ]; then
        : > "$REPOMARK" 2>/dev/null || true
        soft_note "✓ repo-state verdict (soft — nothing read the tree this turn): your message states what is committed, pushed, or clean, and no git status/log/diff ran this turn. State drifts under the user, hooks, sub-agents, and concurrent sessions, so a check from earlier in the session is not evidence for a verdict written now. The first time this happened the message listed three commits to stage that the owner had already pushed (atone status-verdict-from-stale-mental-model, S3, 6x). Cheap fix: git status + git log --oneline -3 immediately before the sentence. Mute: touch ~/.claude/.no-declared-ready-gate"
      fi
    fi
  fi
  exit 0
fi

# Defined here (not at the eligibility gate) because Det1a's weak-credit branch
# also consults SUCCESS_RE to stay out of the block pipeline's way.
SUCCESS_RE='\b(done|works|working|shipped|fixed|passing|passes|verified|complete|completed|good to go|all set|ready to (ship|go|commit))\b'
SUBJECT_RE='\b(the (fix|feature|change|bug|test|tests|build|code|implementation|patch|hook|script)|it|this|everything|all (the )?(tests|of it))\b'

# ── Detection 1a: localhost URL advertised → its port must have been exercised ─
# Handing the user a clickable localhost link asserts "this is up" even when no
# success word appears, so this branch runs BEFORE the success-word eligibility
# exits. Exempt when the message itself says the target is down/unverified/
# conditional. Exercise credit: the port token appears in ANY tool_use input or
# tool_result this turn (curl, lsof, browser navigation, server logs).
adv_urls=$(printf '%s' "$claim_text" | rg -o 'https?://(localhost|127\.0\.0\.1):[0-9]+' 2>/dev/null | sort -u || true)
if [ -n "$adv_urls" ] \
   && ! printf '%s' "$claim_text" | rg -qiP '\b(down|dead|stale|dormant|not (running|up|live|serving|reachable)|no (listener|server)|unreachable|not (yet )?(verified|checked|exercised|tested)|once (you|it|the)|after you|when you (start|run|launch)|relaunch|restart)\b' 2>/dev/null; then
  turn_tool_text=$(printf '%s\n' "$turn_json" | jq -r '
    (select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | (.input | tostring)),
    (select(.type=="user") | .message.content[]? | select(.type=="tool_result")
      | (.content // "") | if type=="array" then (map(.text? // "")|join("\n")) else . end)
  ' 2>/dev/null)
  bad_ports=""
  for p in $(printf '%s\n' "$adv_urls" | rg -o '[0-9]+$' 2>/dev/null | sort -u); do
    printf '%s' "$turn_tool_text" | rg -q "(:|%3A)${p}\b" 2>/dev/null || bad_ports="$bad_ports$p "
  done
  if [ -n "$bad_ports" ]; then
    URLMARK="/tmp/claude-declared-ready-url-${sid8}"
    usig=$(printf '%s' "$adv_urls" | shasum 2>/dev/null | awk '{print $1}')
    uprev=""; [ -f "$URLMARK" ] && uprev=$(cat "$URLMARK" 2>/dev/null)
    if [ "$usig" != "$uprev" ] && [ -n "$usig" ]; then
      printf '%s' "$usig" > "$URLMARK" 2>/dev/null || true
      reason="⚠ LOCALHOST URL ADVERTISED WITHOUT EXERCISING IT — your message hands the user localhost link(s) on port(s) ${bad_ports}but no tool activity this turn touched them. The last time this happened the user's first click failed on both links (atone 2026-07-10, S3, recurs 9×).

  Before advertising a localhost URL: navigate to it and exercise its primary action, and run 'lsof -nP -iTCP:<port> -sTCP:LISTEN' to confirm exactly ONE owner across IPv4+IPv6. If the server is deliberately not running, say that instead of linking it.

Loop-safe: won't re-fire for this URL set. Mute: touch ~/.claude/.no-declared-ready-gate"
      jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
      [ -x "$WARN" ] && bash "$WARN" --hook declared-ready --action block --heeded unknown --detail "url-ports:${bad_ports}" >/dev/null 2>&1 || true
      exit 0
    fi
    # Same URL set already blocked once → step aside; the success-word pipeline
    # below still gets its look.
    [ -x "$WARN" ] && bash "$WARN" --hook declared-ready --heed-of "declared-ready-url:$sid8" --heeded false >/dev/null 2>&1 || true
  fi
  # Weak-credit nudge (audit 2026-07-12 #4): every advertised port WAS touched,
  # but token-presence is weak evidence — the 2026-07-10 miss was a passing IPv4
  # curl while the user's browser hit an IPv6 squatter on the same port. If the
  # turn shows neither lsof nor a browser navigation, nudge once (soft). Gated on
  # NO success words so a real over-claim still reaches the block pipeline below
  # (soft_note exits, and a Stop hook emits one decision only).
  if [ -z "$bad_ports" ] \
     && ! printf '%s' "$claim_text" | rg -qiP "$SUCCESS_RE" 2>/dev/null \
     && ! printf '%s' "$turn_tool_text" | rg -qi 'lsof|browser_navigate|navigate_page|browser_snapshot|take_screenshot' 2>/dev/null; then
    URLSOFT="/tmp/claude-declared-ready-urlsoft-${sid8}"
    if [ ! -f "$URLSOFT" ]; then
      : > "$URLSOFT" 2>/dev/null || true
      soft_note "✓ localhost URL (soft — weak exercise credit): the advertised port(s) appear in this turn's tool activity, but no lsof and no browser navigation. A passing curl is not the user's access path (2026-07-10: IPv4 curl passed, the browser hit an IPv6 squatter). Cheap check before handing over the link: lsof -nP -iTCP:<port> -sTCP:LISTEN → exactly ONE owner across both stacks, and exercise the primary action in a browser. Mute: touch ~/.claude/.no-declared-ready-gate"
    fi
  fi
fi

# Eligibility base (v1 parity): a success word AND a self-referential subject
# somewhere in the message. Keeps "done reading the file" (no subject) out.
printf '%s' "$claim_text" | rg -qiP "$SUCCESS_RE" 2>/dev/null || exit 0
printf '%s' "$claim_text" | rg -qiP "$SUBJECT_RE" 2>/dev/null || exit 0

# Co-location filter (mitigation 5, 2-sentence window): success+subject must
# co-occur in the same OR an adjacent sentence — this rejects the audit-list FP
# where "## 1. X — done" is a per-item marker and the subject lives paragraphs away.
# Recovered exception: a message that OPENS with a terse success declaration
# ("Done. Type-checks clean.") is a completion claim even without a co-located
# subject word — the canonical un-disclosed over-claim.
sentences_file=$(mktemp 2>/dev/null) || sentences_file="/tmp/dr-sent-$$"
printf '%s' "$claim_text" | rg -oP '[^.!?\n]+[.!?]?' 2>/dev/null > "$sentences_file" || true
colocated=0
prev_line=""
while IFS= read -r s; do
  win="$prev_line $s"
  if printf '%s' "$win" | rg -qiP "$SUCCESS_RE" 2>/dev/null \
   && printf '%s' "$win" | rg -qiP "$SUBJECT_RE" 2>/dev/null; then
    colocated=1; break
  fi
  prev_line="$s"
done < "$sentences_file"
rm -f "$sentences_file" 2>/dev/null || true

opens_success=0
first_line=$(printf '%s' "$claim_text" | rg -v '^\s*$' 2>/dev/null | head -n 1)
first_clean=$(printf '%s' "$first_line" | sed -E 's/^[[:space:]>#*_-]+//' 2>/dev/null)
if [ "${#first_clean}" -lt 80 ] && printf '%s' "$first_clean" \
   | rg -qiP '^(done|fixed|complete|completed|shipped|all done|all set|all fixed|good to go)\b' 2>/dev/null; then
  opens_success=1
fi
[ "$colocated" = 1 ] || [ "$opens_success" = 1 ] || exit 0

# ─────────────────────────────────────────────────────────────────────────────
# Eligibility survived. Gather the turn's signals, then run the precedence pipeline.
# ─────────────────────────────────────────────────────────────────────────────

# Per-turn ADDED lines: for Edit/MultiEdit, new_string MINUS old_string (jq array
# subtraction removes exact-content lines, so unchanged context is dropped and only
# genuinely-added lines remain); for Write, the whole content.
added=$(printf '%s\n' "$turn_json" \
  | jq -r 'select(.type=="assistant") | .message.content[]?
      | select(.type=="tool_use" and (.name=="Edit" or .name=="MultiEdit" or .name=="Write"))
      | if .name=="Write" then ((.input.content // "") / "\n")
        elif .name=="Edit" then (((.input.new_string // "") / "\n") - ((.input.old_string // "") / "\n"))
        else ([.input.edits[]? | ((.new_string // "") / "\n") - ((.old_string // "") / "\n")] | add // [])
        end
      | .[]' 2>/dev/null)
added_nonblank=$(printf '%s\n' "$added" | rg -v '^\s*$' 2>/dev/null || true)

# Bash commands this turn, and the compile/lint/collect-stripped subset.
bash_cmds=$(printf '%s\n' "$turn_json" \
  | jq -r 'select(.type=="assistant") | .message.content[]?
      | select(.type=="tool_use" and .name=="Bash") | .input.command // empty' 2>/dev/null)
STRIP_RE='(--collect-only|--no-?emit|--dry-run|--list-tests|-fsyntax-only|--co\b|^[[:space:]]*(eslint|ruff|tsc|mypy|flake8|prettier|swiftc)\b|^[[:space:]]*npx[[:space:]]+(tsc|eslint|prettier)\b|^[[:space:]]*bash[[:space:]]+-n\b|^[[:space:]]*node[[:space:]]+--check\b|^[[:space:]]*python3?[[:space:]]+-m[[:space:]]+py_compile\b)'
stripped_cmds=""
[ -n "$bash_cmds" ] && stripped_cmds=$(printf '%s\n' "$bash_cmds" | rg -v -iP "$STRIP_RE" 2>/dev/null || true)

# tool_result texts this turn (for pass/fail scan + real-output detection).
tool_results=$(printf '%s\n' "$turn_json" \
  | jq -r 'select(.type=="user") | .message.content[]? | select(.type=="tool_result")
      | (.content // "") | if type=="array" then (map(.text? // "") | join("\n")) else . end' 2>/dev/null)

# ── signal: a real test/program RAN this turn (v1 parity) ────────────────────
ran=0
RUN_RE='(pytest|python3?[[:space:]]+[^|]*\.py|go[[:space:]]+test|cargo[[:space:]]+(test|run)|npm[[:space:]]+(test|run|start)|pnpm[[:space:]]+(test|run|dev|start)|yarn[[:space:]]+(test|dev|start)|node[[:space:]]+[^|]+|swift[[:space:]]+(test|run)|xcodebuild[[:space:]]+test|make[[:space:]]+(test|run|check)|\./[A-Za-z0-9._/-]+|bash[[:space:]]+[^|]*\.sh|curl[[:space:]]+[^|]*localhost|jest|vitest|playwright[[:space:]]+test)'
if [ -n "$stripped_cmds" ] && printf '%s\n' "$stripped_cmds" | rg -qiP "$RUN_RE" 2>/dev/null; then
  ran=1
fi
# A real pass/fail run-signal in tool outputs (machine output — ✓/✗ kept here, in
# tool_result scope only; assistant-text ✓ is deliberately NOT a run signal).
passfail=0
if [ -n "$tool_results" ] && printf '%s' "$tool_results" | rg -qiP \
   '([0-9]+[[:space:]]+(passed|failed|error|errors|xfailed)|\bPASS\b|\bFAIL\b|\bok\b[[:space:]]+[0-9]|tests? (passed|ran)|Test Suite.*(passed|failed)|[0-9]+[[:space:]]+(test|spec)s?[[:space:]]+(passed|ran)|✓|✗)' 2>/dev/null; then
  passfail=1
fi

# ── signal: self-disclosed gap (Stage A) ─────────────────────────────────────
DISCLOSE_RE='\b(not (yet )?(verified|exercised|tested|run|deployed)|have(n.?t| not) (verified|exercised|tested|run|deployed|clicked)|compile[- ]?(only|checked)|type[- ]?check(s|ed)? (only|but)|can.?t (click|run|test|exercise|verify|deploy)|(only )?bash -n|--collect-only|--no-?emit|awaiting (you|your)|did you (see|notice)|what did you see|(want|should|shall) I (run|drive|start|verify|deploy|test)|haven.?t (yet )?(run|exercised))\b'
disclosed=0
printf '%s' "$claim_text" | rg -qiP "$DISCLOSE_RE" 2>/dev/null && disclosed=1
if [ "$disclosed" = 0 ]; then
  # trailing user-observation question (the mid-test-await shape)
  last_ne=$(printf '%s' "$claim_text" | rg -v '^\s*$' 2>/dev/null | tail -n 1)
  printf '%s' "$last_ne" | rg -qP '\?[[:space:]]*$' 2>/dev/null && disclosed=1
fi

# ── signal: a non-inspection command produced real output (Stage W widening) ──
# A command counts as "ran something" when a top-level segment leads with a token
# that is NOT pure inspection/navigation/compile — this catches project CLIs
# (i-dream, a ./script, an installed binary, a "$VAR" invocation) the static run
# allow-list misses. Paired with real observed output → soft note, never silent.
HARMLESS_RE='^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=|\(|\{|cd|ls|ll|la|pwd|echo|printf|cat|bat|head|tail|wc|rg|grep|egrep|fgrep|ag|find|fd|mkdir|rmdir|trash|rm|cp|mv|ln|touch|chmod|chown|which|type|whereis|command|git|gh|jq|yq|sed|awk|sort|uniq|cut|tr|paste|tee|sleep|pgrep|pkill|kill|killall|export|unset|set|shift|read|wait|hash|source|\.|:|true|false|date|env|dirname|basename|realpath|readlink|stat|diff|comm|open|test|clear|tput|column|less|more|xargs|du|df|uname|hostname|whoami|id|groups|ps|defaults|osascript|tsc|ruff|mypy|eslint|prettier|flake8|swiftc|gcc|cc|clang|g\+\+)([[:space:]]|$|/)'
has_nonharmless=0
if [ -n "$stripped_cmds" ]; then
  # Split every command on compound separators (&&, ||, ;) and newlines — NOT a lone
  # `&` (so `2>&1` never becomes a bogus segment) and NOT a lone `|` (so a `|` inside
  # a quoted rg/grep pattern doesn't split the string; the run command is always the
  # leading token of a pipe segment anyway). Then test each segment's leading token.
  segs=$(printf '%s\n' "$stripped_cmds" | awk '{gsub(/&&|\|\|/,"\n"); gsub(/;/,"\n"); print}')
  while IFS= read -r seg; do
    [ -z "$(printf '%s' "$seg" | tr -d '[:space:]')" ] && continue
    if ! printf '%s' "$seg" | rg -qP "$HARMLESS_RE" 2>/dev/null; then
      has_nonharmless=1; break
    fi
  done <<EOF
$segs
EOF
fi
# real observed output: some tool_result that is not an edit/write confirmation,
# not the empty-output marker, and carries substantive text.
substantial=0
if [ -n "$tool_results" ]; then
  meaningful=$(printf '%s\n' "$tool_results" \
    | rg -v '^\(Bash completed with no output\)' 2>/dev/null \
    | rg -v 'has been updated successfully|File created successfully|file state is current' 2>/dev/null || true)
  [ "$(printf '%s' "$meaningful" | tr -d '[:space:]' | wc -c | tr -d ' ')" -gt 30 ] && substantial=1
fi

# ── signal: a changed *.tsx/*.jsx in a Next/RSC project (Stage E reason) ──────
is_tsx_next=0
first_tsx=$(rg -i '\.(tsx|jsx)$' "$EDITED" 2>/dev/null | head -n 1)
if [ -n "$first_tsx" ]; then
  d=$(dirname "$first_tsx")
  i=0
  while [ "$i" -lt 8 ] && [ "$d" != "/" ] && [ -n "$d" ]; do
    if [ -f "$d/package.json" ]; then
      if [ -f "$d/next.config.js" ] || [ -f "$d/next.config.mjs" ] || [ -f "$d/next.config.ts" ] \
         || rg -q '"next"' "$d/package.json" 2>/dev/null; then
        is_tsx_next=1
      fi
      break
    fi
    d=$(dirname "$d")
    i=$((i + 1))
  done
fi

# ── signal: comment/docs-only diff (Stage B) ─────────────────────────────────
# comment markers per design + amendment 3: //  #  /*  */  --  <!--  ;
# (bare * and quote markers dropped — a C `*ptr = x;` deref must never read as a
# comment). Empty-diff guard: if the reconstruction yielded NOTHING but Gate0 says
# source was edited (sub-agent edits / boundary miss), SKIP the shield — never
# vacuously silence.
comment_only=0
if [ -n "$added_nonblank" ]; then
  if ! printf '%s\n' "$added_nonblank" | rg -qvP '^[[:space:]]*(//|#|/\*|\*/|--|<!--|;)' 2>/dev/null; then
    comment_only=1
  fi
fi

# ── opportunistic diff-coverage (Stage C) — minimal, almost never engages here ─
# Engages ONLY when a FRESH coverage artifact already exists near the edited file
# AND diff-cover is installed. On this machine diff-cover is absent, so this always
# falls through. No hand-rolled coverage parsing (per design §7).
cov_decision=""
first_src=$(rg -i '\.(py|ts|tsx|js|jsx|mjs|cjs|go|rs|swift|rb|java|kt|c|cc|cpp|h|hpp)$' "$EDITED" 2>/dev/null | head -n 1)
if [ -n "$first_src" ] && command -v diff-cover >/dev/null 2>&1; then
  proj=$(dirname "$first_src"); j=0
  while [ "$j" -lt 8 ] && [ "$proj" != "/" ] && [ -n "$proj" ]; do
    [ -f "$proj/package.json" ] || [ -d "$proj/.git" ] || [ -f "$proj/pyproject.toml" ] && break
    proj=$(dirname "$proj"); j=$((j + 1))
  done
  cov=""
  for c in coverage.xml cobertura.xml coverage/cobertura-coverage.xml coverage/lcov.info lcov.info; do
    if [ -f "$proj/$c" ] && [ "$proj/$c" -nt "$EDITED" ]; then cov="$proj/$c"; break; fi
  done
  if [ -n "$cov" ]; then
    if diff-cover "$cov" --compare-branch=HEAD --fail-under=1 --src-roots "$proj" >/dev/null 2>&1; then
      cov_decision="covered"    # changed lines executed by a run → sufficient
    else
      cov_decision="uncovered"  # changed lines present but 0% covered → scope substitution
    fi
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# PRECEDENCE PIPELINE — the first branch that matches decides.
# ─────────────────────────────────────────────────────────────────────────────

# B) comment/docs-only diff → nothing executable changed → SILENT.
[ "$comment_only" = 1 ] && exit 0

# RAN) a real test/program ran this turn → trust the claim (v1 parity) → SILENT.
if [ "$ran" = 1 ] || [ "$passfail" = 1 ]; then
  # Heed: a prior block this session (MARK present) followed by a real run before the
  # next claim = that block was heeded. Emit once per session (HEED sentinel dedups).
  MARK="/tmp/claude-declared-ready-${sid8}"
  HEEDMARK="/tmp/claude-declared-ready-heeded-${sid8}"
  if [ -f "$MARK" ] && [ ! -f "$HEEDMARK" ]; then
    [ -x "$WARN" ] && bash "$WARN" --hook declared-ready --heed-of "declared-ready:$sid8" --heeded true >/dev/null 2>&1 || true
    : > "$HEEDMARK" 2>/dev/null || true
  fi
  # Multi-state surfaces (audit 2026-07-12 #4): a run existed, but run-existence
  # says nothing about STATE coverage. Both July theme misses (2026-07-02 ribbon,
  # 2026-07-07 v3 dashboard) were Swift surfaces that took exactly this silent
  # exit — the dark-AND-light reminder below only fires for tsx-in-Next. If the
  # edit touched a UI surface and the claim doesn't scope a state, remind once
  # per session (soft, never a block).
  if rg -qi '\.(swift|tsx|jsx|css|scss|vue|svelte)$' "$EDITED" 2>/dev/null \
     && ! printf '%s' "$claim_text" | rg -qiP '\b(dark|light)[- ](mode|theme|only)\b|\bboth themes\b|\beach (state|theme|mode)\b|\ball (states|themes|breakpoints)\b|\bverified in\b' 2>/dev/null; then
    STATEMARK="/tmp/claude-declared-ready-states-${sid8}"
    if [ ! -f "$STATEMARK" ]; then
      : > "$STATEMARK" 2>/dev/null || true
      soft_note "✓ declared-ready (soft — a run was observed, on a UI surface): if this surface has states — dark AND light theme, open/closed, breakpoints — exercise the changed surface in EACH state before the claim, or scope it explicitly ('verified in dark only'). Dark-only sign-offs shipped a broken light theme twice (2026-07-02, 2026-07-07). Mute: touch ~/.claude/.no-declared-ready-gate"
    fi
  fi
  # Mutation-test reminder (jegs 2026-07-15): a test RAN green, but a green test
  # never shown it CAN fail proves nothing — four such tests shipped as decoration
  # that session. Fires only when a TEST FILE was edited this session and the agent
  # didn't already say it mutation-tested; soft, once per session, never a block.
  if rg -qiP '(\.test\.|\.spec\.|_test\.|(^|/)test_)' "$EDITED" 2>/dev/null \
     && ! printf '%s' "$claim_text" | rg -qiP '\b(mutation[- ]?test|saw it (go )?red|watch(ed)? .{0,20}(fail|red)|revert(ed)? the (fix|guard|code)|broke the (fix|guard))\b' 2>/dev/null; then
    MUTMARK="/tmp/claude-declared-ready-mutation-${sid8}"
    if [ ! -f "$MUTMARK" ]; then
      : > "$MUTMARK" 2>/dev/null || true
      soft_note "✓ declared-ready (soft — a test ran, and you edited a test): a passing test proves nothing until you've seen it FAIL. Mutation-test the guard — revert the code it protects, confirm the test goes RED, restore. A test that stays green when the fix is reverted is the bug, not coverage (four shipped as decoration 2026-07-15). Mute: touch ~/.claude/.no-declared-ready-gate"
    fi
  fi
  exit 0
fi

# C) opportunistic diff-coverage verdict.
if [ "$cov_decision" = "covered" ]; then
  exit 0
elif [ "$cov_decision" = "uncovered" ]; then
  :  # fall through to the block tail with the scope-substitution reason
fi

# A) self-disclosed gap → reinforce the honest hedge → SOFT (never block).
if [ "$disclosed" = 1 ] && [ "$cov_decision" != "uncovered" ]; then
  soft_note "✓ declared-ready (soft — you scoped the gap yourself): you edited source and claimed success, and your message already discloses what you have NOT exercised (or asks me/you to verify). That is the correct hedge, not an over-claim — no block. If you can cheaply exercise the changed path (drive the dev server, run the CLI, click the toggle), do; otherwise this is fine. Mute: touch ~/.claude/.no-declared-ready-gate"
fi

# W) a project-CLI / non-inspection command produced real output → something ran
#    that the static allow-list missed; can't prove sufficiency → SOFT (not block).
if [ "$has_nonharmless" = 1 ] && [ "$substantial" = 1 ] && [ "$cov_decision" != "uncovered" ]; then
  soft_note "✓ declared-ready (soft — a run was observed): you edited source and claimed success, and a command that is not pure inspection produced output this turn (a project CLI / script the run allow-list doesn't name). Something ran, but I can't prove it exercised the exact lines you changed. If it did, carry on; if it was adjacent scope, exercise the change itself. Mute: touch ~/.claude/.no-declared-ready-gate"
fi

# S) style-only edit, nothing rendered it → SOFT (never block; see Gate 0 note).
if [ "$style_only" = 1 ]; then
  STYLEMARK="/tmp/claude-declared-ready-style-${sid8}"
  if [ ! -f "$STYLEMARK" ]; then
    : > "$STYLEMARK" 2>/dev/null || true
    soft_note "✓ declared-ready (soft — style-only edit): you changed only stylesheet/markup-style files and claimed success, and nothing rendered the surface this turn. CSS is the one change class you cannot read off the diff — a rule that looks right still collapses a layout. Take a screenshot and look at it (headless Chrome, or mcp__plugin_chrome-devtools__take_screenshot), in dark AND light if the surface has a theme. This is the 'shipping-css-ui-changes-without-visual-verification' pattern (S3, 3×). Mute: touch ~/.claude/.no-declared-ready-gate"
  fi
  exit 0
fi

# E / nothing) nothing exercised the change → BLOCK (loop-safe).
MARK="/tmp/claude-declared-ready-${sid8}"
sig=$(printf '%s' "$claim_text" | shasum 2>/dev/null | awk '{print $1}')
prev=""; [ -f "$MARK" ] && prev=$(cat "$MARK" 2>/dev/null)
if [ "$sig" = "$prev" ] && [ -n "$sig" ]; then
  # Same claim signature came back after a block → the prior block was not heeded.
  [ -x "$WARN" ] && bash "$WARN" --hook declared-ready --heed-of "declared-ready:$sid8" --heeded false >/dev/null 2>&1 || true
  # Already blocked for this exact claim last Stop — the agent saw it and chose to
  # proceed, or it's a false positive. Step aside (visible, non-blocking).
  soft_note "⚠ declared-ready (not re-blocking): you edited source/test files and declared success, but I saw nothing exercise the changed path this turn. If you verified out-of-band or this is a false positive, carry on. Mute: touch ~/.claude/.no-declared-ready-gate"
fi
printf '%s' "$sig" > "$MARK" 2>/dev/null || true

if [ "$is_tsx_next" = 1 ]; then
  reason="⚠ DECLARED READY WITHOUT EXERCISING IT (frontend) — you edited a .tsx/.jsx in a Next/RSC app and your message claims success, but the only checks this turn were type/unit-level (tsc/vitest/jest) — nothing rendered the page.

  Unit tests and tsc run RSC in Node; they structurally CANNOT see hydration mismatches, the client/server boundary, or a cursor/keyboard/toggle interaction. The value of this change is exactly what tsc can't see. Exercise it: 'next build' (catches RSC/hydration) or a dev-server page load + the actual interaction, and read the result before declaring done. And if the surface has states — dark AND light theme, open/closed, breakpoints — exercise EACH state you sign off on, or scope the claim to what you saw (dark-only sign-offs shipped a broken light theme twice: 2026-07-02, 2026-07-07).

This is the 'declared-ready-without-runtime-exercise' pattern (S3, recurs 5–6×). If you drove it out-of-band, or this is a false positive, say so and proceed — this won't block again for the same claim. Mute: touch ~/.claude/.no-declared-ready-gate"
elif [ "$cov_decision" = "uncovered" ]; then
  reason="⚠ DECLARED READY BUT THE RUN DIDN'T COVER YOUR CHANGE — you edited source and claimed success, and something ran, but diff-coverage shows 0% of the lines you changed this turn were executed by it. A green suite that never runs your changed lines is scope substitution, not verification.

  Run the path that hits the lines you edited and read the actual pass/fail line before declaring done.

This is the 'declared-ready-without-runtime-exercise' pattern (S3, recurs 5–6×). If you exercised it out-of-band, or this is a false positive, say so and proceed — this won't block again for the same claim. Mute: touch ~/.claude/.no-declared-ready-gate"
else
  reason="⚠ DECLARED READY WITHOUT RUNNING IT — you edited source/test files and your message claims success (done/works/fixed/passing), but nothing exercised the changed path this turn.

  collect ≠ run:  pytest --collect-only, tsc --noEmit, bash -n, node --check, an
  import-check, or a lint are NOT a run — none of them executes an assertion. Run
  the code path in the state that matters and read the actual pass/fail line
  before declaring done.

This is the 'declared-ready-without-runtime-exercise' pattern (S3, recurs 5–6×).
If you genuinely ran it out-of-band, or this is a false positive, say so and proceed — this won't block again for the same claim. Mute: touch ~/.claude/.no-declared-ready-gate"
fi
jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
[ -x "$WARN" ] && bash "$WARN" --hook declared-ready --action block --heeded unknown >/dev/null 2>&1 || true
exit 0
