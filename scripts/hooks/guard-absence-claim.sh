#!/usr/bin/env bash
# guard-absence-claim.sh — Stop hook: a GROUNDING GATE for absence claims.
#
# The SECOND gate for the atone slug `infra-before-grep`. Its sibling
# guard-duplicate-symbol.sh (PreToolUse) catches the WRITE side — an edit that
# re-declares a symbol that already exists. This gate catches the sub-pattern that
# gate is structurally blind to: the agent ASSERTS in prose that something does
# NOT exist, off an inadequate search — then builds a plan/narrative on the false
# absence. The gate-efficacy baseline showed the slug REGRESSING (1.67→2.31 /30d)
# while dup-symbol fired 44× — because the recent recurrences (2026-07-02 ×2,
# 2026-07-03) are all reasoning-side absence claims the dup-symbol gate never sees.
#
# The two failure shapes in the recall set (bash ~/.claude/scripts/atone.sh
# search infra-before-grep), split ~evenly:
#   IGNORE-SCOPE miss — searched, but the tool silently excluded git-ignored /
#     hidden files. The founding 2026-07-03 event: `fd -H 'warn-events'` (hidden
#     only, NOT --no-ignore) found nothing → "warn-events.jsonl doesn't exist yet,
#     never fired". The file had 187 lines; it is git-ignored by the ~/.claude /*
#     whitelist, so fd excluded it. rules/shell.md documents --no-ignore/--hidden
#     for rg; the fd costume was not recognized.
#   NARROW-SCOPE miss — wrong dir / wrong term, or no search at all. screenshot-
#     sherpa "didn't exist" off a subdir-scoped grep (2026-06-15); a new admin
#     route proposed with no ls/grep (2026-05-19); RENDER_API_KEY named as a NEW
#     secret without grepping for the existing RENDER_API_TOKEN (2026-07-02).
#
# WHAT THIS GATE MECHANICALLY COVERS (the choice, stated): it fires on an absence
# claim whose grounding this turn is EITHER an ignore-respecting search (no
# --no-ignore/-u) OR no probe of the subject at all. It does NOT try to detect the
# "ignore-transparent search of the WRONG subdir" miss — that needs project-
# structure awareness the hook lacks, and guessing it would mostly false-CLEAR
# (the bad direction). So: the ignore-scope half is caught robustly; the narrow-
# scope half is caught only in its "no adequate probe ran" form.
#
# Philosophy (the user's, shared with guard-structural-claim): forced grounding is
# the value, not true-positive yield. "the extra time or tool calls are worthwhile
# for correctness even if nothing comes out of the procedure, because it's much
# worse when things are MISSED." A false FIRE that costs one cheap re-probe
# (rg --no-ignore / test -f) is ACCEPTABLE. A false CLEAR (letting a wrong-flag
# search silence the claim) is the expensive direction, so clears are scoped to
# the subject and bare --hidden is deliberately NOT a clear.
# Anti-paralysis is LOOP-SAFETY (block once per claim sentence, then step aside),
# not silencing.
#
# Detection pipeline (all must hold to fire):
#   ①  an ABSENCE claim sentence in the final assistant message that ALSO names a
#      filesystem-shaped subject (path / file.ext / snake_case / CamelCase /
#      ALLCAPS_VAR / backtick span) — a subject-less "there is no consensus" does
#      not match.
#   ②  no clearing carve-out in the message: a HEDGE ([UNVERIFIED] / "as far as I
#      searched" / "haven't checked") or META (about this gate / the atone slug /
#      the ignore flags themselves).
#   ③  this turn ran NEITHER an ignore-transparent search of the subject
#      (rg/fd with --no-ignore / -u/-uu / --unrestricted / fd -I; or plain grep
#      -r) NOR a direct existence probe of the subject (test -f/-e/-d, [ -f, stat,
#      ls, find -name; or a Read/Glob tool call of the subject). bare --hidden/-H
#      is NOT ignore-transparent (fd -H still honors .gitignore — the founding bug).
#
# Response (stakes-scaled, loop-safe on the MATCHED claim sentence):
#   - high-stakes repo  → decision:block once, then step aside
#   - low-stakes        → systemMessage (soft note)
# Mute: touch ~/.claude/.no-absence-claim-gate

set -uo pipefail
[ -f "$HOME/.claude/.no-absence-claim-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
HOOK_COMMON="$HOME/.claude/scripts/hooks/hook-common.sh"
[ -r "$HOOK_COMMON" ] || exit 0
. "$HOOK_COMMON"
command -v rg >/dev/null 2>&1 || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tp" ] && [ -f "$tp" ] || exit 0
sid8=$(hook_sid8 "$sid")
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$cwd" ] && cwd="$PWD"

WARN="$HOME/.claude/scripts/hooks/warn-log.sh"

# ── SHIP-GATE RESULTS (full-corpus replay via replay-corpus.py, 2026-07-03 —
# 948 transcripts / 3043 turns; see assets/reports/20260703-absence-claim-guard/).
#   fires      : 20  (18 BLOCK / 2 SOFT)  = 0.66% of turns  (target ≤20 — at ceiling)
#   groundable : 17/20 named-artifact-absence claims (11 clear + 6 defensible-vague);
#                3/20 = 15% pointless (a code-comment string, 2 eval-rubric items)
#                — under the 30% ship threshold.
# The founding 2026-07-03 turn (session 69aeb3ea, turn 56) fires BLOCK; the meta
# turns in the same session that merely DISCUSS the incident clear via META.
# A first cut (broad "there's no"/"not wired" predicate, any subject) fired ~100×
# at ~85% pointless — split into strong/weak paths + subject-scoped clears to land
# here. Regression fixtures: fixtures/absence-claim/ (seed-absence-claim.py).

# ── Turn boundary: slice at the LAST REAL USER MESSAGE so the probe-gate sees only
# THIS turn's tool calls (same method as declared-ready-stop / structural-claim).
window=$(tail -n 800 "$tp" 2>/dev/null) || exit 0
[ -n "$window" ] || exit 0
boundary=$(printf '%s\n' "$window" | jq -rc '
  select(.type=="user"
    and ( (.message.content|type=="string" and (.|length>0))
       or (.message.content|type=="array" and (any(.[]?; .type=="text"))) ))
  | input_line_number' 2>/dev/null | tail -n 1)
if [ -n "$boundary" ]; then
  turn_json=$(printf '%s\n' "$window" | tail -n +"$boundary")
else
  turn_json="$window"
fi
[ -n "$turn_json" ] || exit 0

# ── Final assistant message text — the claim lives here.
last_asst=$(printf '%s\n' "$turn_json" | jq -rc 'select(.type=="assistant")' 2>/dev/null | tail -n 1)
[ -n "$last_asst" ] || exit 0
text=$(printf '%s' "$last_asst" | jq -r '.message.content[]? | select(.type=="text") | .text' 2>/dev/null)
[ -n "$text" ] || exit 0

# ── Regexes — TWO paths, tuned on a corpus replay (see ship-gate note) ────────
# The corpus is thick with prose that says "there's no X" / "not wired" / "the
# redirect never fired" in ordinary design/status/postmortem writing — matching
# those floods the gate (a first cut fired ~100×/corpus, ~85% pointless). So the
# predicate is split by strength, and each path pairs with a subject of matching
# strength:
#
#   PATH B — WEAK predicate ("<X> does not exist / never fired"). "does not exist"
#     attaches to anything (a DB row, a runtime redirect, a cut design), so Path B
#     REQUIRES a STRONG filesystem subject nearby: a path with a slash, a filename
#     with a code extension, or a backtick span containing one. `worker_info`
#     (bare snake in backticks) does NOT qualify; `page-modules.spec.ts` does.
#   PATH A — STRONG predicate ("no such / no existing / there's no <artifact-noun>",
#     "no <x> <artifact> exists"). The artifact noun (module/helper/script/route…)
#     is the discriminator, so a weaker identifier subject is allowed.
#
# EXIST_RX — Path B predicate (weak; strong subject required).
EXIST_RX="\\b(does(n'?t| not)( even| yet)? exist|did not exist|doesn'?t (yet )?exist|never existed|no longer exists?|never (fired|been (created|written|run|logged)))\\b"
# ARTIFACT_RX — Path A predicate (strong; artifact noun embedded). The optional
# groups pull in an ADJACENT identifier (before or after the noun) so the matched
# snippet carries the subject, e.g. "no existing helper `parse_widget`" or "there's
# no build_payload module". A plain-word subject ("no sherpa script") matches the
# predicate but yields no extractable identifier → the line is skipped (documented
# recall gap; the ignore-scope half is what this gate must catch).
ARTIFACT_RX="\\b(no such|no existing|there(?:'?s| is) no)\\s+(\`[^\`]+\`\\s+|[a-z]+\\s+)?(file|module|function|helper|script|command|hook|route|endpoint|method|class|migration|implementation|component|package)\\b([[:space:]]+(for|named|called|to|at)?[[:space:]:=]*(\`[^\`]+\`|[A-Za-z_][A-Za-z0-9_./-]{3,}))?|\\bno\\s+(\`[^\`]+\`\\s+|[a-z]+\\s+)?(file|module|function|helper|script|hook|route|endpoint|migration|implementation)\\s+(exists?|found|present)\\b"
# STRONG_RX — a real filesystem token (path / filename-with-ext / backtick-with-one).
STRONG_RX='`[^`]*(/[^`]*|\.(py|ts|tsx|js|jsx|mjs|cjs|go|rs|swift|rb|sh|json|jsonl|toml|ya?ml|md|txt|env|cfg|conf|ini|sql|sqlite|db))[^`]*`|\b[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+\b|\b[A-Za-z0-9_-]+\.(py|ts|tsx|js|jsx|mjs|cjs|go|rs|swift|rb|sh|json|jsonl|toml|ya?ml|md|txt|env|cfg|conf|ini|sql|sqlite|db)\b'

# ② HEDGE — the claim is already flagged as unconfirmed / bounded search.
HEDGE_RX="\\[UN(VERIFIED|CONFIRMED)\\]|as far as I (can tell|could (tell|find)|searched|know)|to my knowledge|I (could|may|might) be wrong|haven'?t (fully |yet )?(searched|checked|confirmed|verified|grepped|looked)|may not have (searched|found|checked)|if it exists|pending (a )?(wider|fuller|deeper) (search|grep|check)|I did not (grep|search) (the )?(full|whole|entire)"
# ② META — the message is ABOUT this gate / the ignore machinery, not a live
# claim. Keyed to MACHINERY NAMES (never present in a real absence claim) so THIS
# build-session's turns that quote "does not exist" as examples stay silent, while
# the genuine founding claim (turn 56, which predates the hook and names none of
# these) still fires. A bare "atone" mention is deliberately NOT here — turn 56
# mentions it incidentally and must still fire.
META_RX='guard-absence|absence-claim|infra-before-grep|grep-scope-before|ignore-scope|ignore-transparent|the (gate|hook) (fires|would fire|should fire) (on|when)|this (grounding )?(gate|hook) (fires|would fire|blocks)|--no-ignore --hidden'

# ── Subject extraction helper — most-specific token first; empty if the snippet
# carries only plain words (no filesystem/identifier token to scope a probe on).
_extract_subject() {
  local s="$1" out=""
  out=$(printf '%s' "$s" | rg -oP -m1 "$STRONG_RX" 2>/dev/null | tr -d '`' | rg -oP -m1 '[A-Za-z0-9_./-]+' 2>/dev/null || true)
  [ -z "$out" ] && out=$(printf '%s' "$s" | rg -oP -m1 '`[^`]+`' 2>/dev/null | tr -d '`' | rg -oP -m1 '[A-Za-z0-9_./-]+' 2>/dev/null || true)
  [ -z "$out" ] && out=$(printf '%s' "$s" | rg -oP -m1 '\b[a-z][a-z0-9]*(_[a-z0-9]+)+\b' 2>/dev/null || true)
  [ -z "$out" ] && out=$(printf '%s' "$s" | rg -oP -m1 '\b[A-Z][A-Z0-9]{1,}(_[A-Z0-9]+)+\b' 2>/dev/null || true)
  [ -z "$out" ] && out=$(printf '%s' "$s" | rg -oP -m1 '\b[A-Z][a-z]+[A-Z][A-Za-z]+\b' 2>/dev/null || true)
  printf '%s' "$out"
}

# ── This turn's probe signals, gathered ONCE (per-turn, not per-claim) ────────
# Read/Glob tool targets (ignore-blind filesystem ops — Glob does not consult
# .gitignore, verified 2026-07-03; the Grep TOOL is ripgrep-default and DOES honor
# .gitignore, so it is NOT counted as a clear).
tool_targets=$(printf '%s\n' "$turn_json" \
  | jq -r 'select(.type=="assistant")|.message.content[]?
      | select(.type=="tool_use")
      | if   .name=="Read"  then (.input.file_path // empty)
        elif .name=="Glob"  then ((.input.pattern // "") + " " + (.input.path // ""))
        else empty end' 2>/dev/null)
# Bash commands, JSON-encoded (one per line) so multi-line commands stay one line.
bash_lines=$(printf '%s\n' "$turn_json" \
  | jq -c 'select(.type=="assistant")|.message.content[]?|select(.type=="tool_use" and .name=="Bash")|.input.command // empty' 2>/dev/null)

# _grounded STEM → 0 if THIS turn adequately probed STEM (ignore-transparent
# search of it, or a direct existence probe of it), 1 otherwise. A Bash tool call
# is usually a MULTI-LINE script, so it is split into sub-commands (newlines, ;,
# &&, ||, |) and the subject-reference + probe must co-occur in the SAME
# sub-command — else an unrelated `ls other/dir` in the same script would falsely
# ground a claim whose subject is merely echoed elsewhere in it (the founding bug).
_grounded() {
  local st="$1" cmd sub subcmds
  [ -n "$tool_targets" ] && printf '%s\n' "$tool_targets" | rg -qiF -- "$st" 2>/dev/null && return 0
  [ -z "$bash_lines" ] && return 1
  while IFS= read -r jline; do
    [ -z "$jline" ] && continue
    cmd=$(printf '%s' "$jline" | jq -r '.' 2>/dev/null)
    [ -z "$cmd" ] && continue
    subcmds=$(printf '%s' "$cmd" | awk '{gsub(/&&|\|\||[;|]/,"\n"); print}')
    while IFS= read -r sub; do
      [ -z "$sub" ] && continue
      printf '%s' "$sub" | rg -qiF -- "$st" 2>/dev/null || continue   # subject in THIS sub-command
      if printf '%s' "$sub" | rg -qP '\b(rg|fd)\b' 2>/dev/null; then
        printf '%s' "$sub" | rg -qP '(--no-ignore|--unrestricted|(^|[[:space:]])-[A-Za-z]*u[A-Za-z]*([[:space:]]|$))' 2>/dev/null && return 0
        printf '%s' "$sub" | rg -qP '\bfd\b' 2>/dev/null && printf '%s' "$sub" | rg -qP '(^|[[:space:]])-[A-Za-z]*I([[:space:]]|$)' 2>/dev/null && return 0
      fi
      # plain `grep -r/-R` (NOT `git grep`) has no gitignore awareness → transparent.
      if printf '%s' "$sub" | rg -qP '(^|[[:space:]])grep\b' 2>/dev/null \
         && ! printf '%s' "$sub" | rg -qP '\bgit[[:space:]]+grep\b' 2>/dev/null \
         && printf '%s' "$sub" | rg -qP '(^|[[:space:]])-[A-Za-z]*[rR]([A-Za-z]*)?([[:space:]]|$)' 2>/dev/null; then return 0; fi
      # Direct existence probe of the subject.
      printf '%s' "$sub" | rg -qP '(\btest[[:space:]]+-[fedFED]\b|(\[|\[\[)[[:space:]]+-[fed][[:space:]]|\bstat[[:space:]]|(^|[[:space:]])ls([[:space:]]|$)|\bfind\b[^|]*-i?name\b)' 2>/dev/null && return 0
    done <<SUBEOF
$subcmds
SUBEOF
  done <<EOF
$bash_lines
EOF
  return 1
}

# ── Stage ① — scan only CANDIDATE lines (those carrying a predicate keyword), so
# the expensive per-line matching runs a handful of times, not once per line. For
# each candidate: match Path B (strong subject within ~80 chars of a weak exist
# predicate, either order) or Path A (artifact-noun predicate + adjacent id),
# require an extractable subject, THEN check its probe-gate. Fire on the FIRST
# UNGROUNDED claim — a grounded earlier claim (a file this turn Read) must not
# shadow an ungrounded later one, and a subject-less line (plain word / non-file
# thing) is skipped, not fired.
PREFILTER_RX="does(n'?t| not)( even| yet)? exist|did not exist|doesn'?t (yet )?exist|never existed|no longer exists?|never (fired|been) |no such |no existing |there(?:'?s| is) no |\\bno (file|module|function|helper|script|hook|route|endpoint|migration|implementation) "
cand=$(printf '%s\n' "$text" | rg -iP "$PREFILTER_RX" 2>/dev/null)
[ -n "$cand" ] || exit 0

# ── Stage ② — whole-message clearing carve-outs (silent, cheap, global) ───────
printf '%s' "$text" | rg -qiP "$HEDGE_RX" 2>/dev/null && exit 0
printf '%s' "$text" | rg -qiP "$META_RX"  2>/dev/null && exit 0

claim_sentence=""; subject=""; stem=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  # Gap forbids sentence punctuation (. ! ?) so a strong subject binds only to a
  # predicate in the SAME clause — stops "`a.md` does X. `b.py` does not exist"
  # from capturing the grounded `a.md` and shadowing the ungrounded `b.py`.
  snippet=$(printf '%s' "$line" | rg -oP -m1 "(?:${STRONG_RX})[^.!?\n]{0,80}?(?:${EXIST_RX})|(?:${EXIST_RX})[^.!?\n]{0,80}?(?:${STRONG_RX})" 2>/dev/null | head -1)
  [ -z "$snippet" ] && snippet=$(printf '%s' "$line" | rg -oP -m1 "$ARTIFACT_RX" 2>/dev/null | head -1)
  [ -z "$snippet" ] && continue
  subj=$(_extract_subject "$snippet")
  [ -z "$subj" ] && continue
  # STEM for the probe-match: a grounding search for `ensure_indexes.py` runs as
  # `rg 'ensure_indexes'` (symbol, no ext) — strip dir + trailing ext; fall back
  # to the full subject when the stem collapses too short to discriminate.
  st=$(basename -- "$subj" 2>/dev/null || printf '%s' "$subj")
  st="${st%.*}"
  [ "${#st}" -lt 4 ] && st="$subj"
  _grounded "$st" && continue           # this claim IS grounded → keep scanning
  claim_sentence="$snippet"; subject="$subj"; stem="$st"; break   # first UNGROUNDED claim
done <<EOF
$cand
EOF
[ -n "$subject" ] || exit 0             # every candidate claim was grounded / subject-less

# ── Survived → FIRE. Stakes-scaled, loop-safe on the claim sentence. ─────────
stakes=$(bash "$HOME/.claude/scripts/stakes-tier.sh" "$cwd" 2>/dev/null || echo low)
[ "$stakes" = "high" ] && base="block" || base="soft"

subj_disp="${subject:0:60}"
body="your message asserts '${subj_disp}' does not exist / never fired, but this turn ran no ignore-transparent search of it (rg/fd --no-ignore / -u / -uu) and no direct existence probe (test -f / ls / stat). A default rg/fd — or fd -H — silently skips .gitignored + hidden files, which is exactly how this absence claim recurs (infra-before-grep). Re-probe: rg --no-ignore --hidden '${subj_disp}' <root>  OR  test -f <path>. Already confirmed absent out-of-band, or this is a non-file claim? Say so — this won't re-block the same sentence. Mute: touch ~/.claude/.no-absence-claim-gate"

emit_soft() { jq -cn --arg m "⚠ absence-claim (grounding gate) — $body" '{systemMessage:$m}' 2>/dev/null || true
  [ -x "$WARN" ] && bash "$WARN" --hook absence-claim --action soft --heeded unknown >/dev/null 2>&1 || true; }
emit_block() { jq -cn --arg r "⛔ absence-claim (grounding gate) — $body" '{decision:"block", reason:$r}' 2>/dev/null || true
  [ -x "$WARN" ] && bash "$WARN" --hook absence-claim --action block --heeded unknown >/dev/null 2>&1 || true; }

MARK="/tmp/claude-absence-claim-${sid8}"
if ! hook_loop_check "$MARK" "$claim_sentence"; then
  # Same claim sentence as the last Stop — step aside (never trap).
  [ "$base" = "block" ] && emit_soft   # a would-be block demotes to a visible note
  exit 0                                # a would-be soft goes silent on repeat
fi

if [ "$base" = "block" ]; then emit_block; else emit_soft; fi
exit 0
