#!/usr/bin/env bash
# atone-juror-dispatch.sh — run the atone juror as a headless `claude -p` call
# and persist its verdict to disk. This takes the agent OUT of verdict
# composition: the agent prepares a case file; THIS script produces the verdict
# via a process the agent does not invoke and cannot interpose on.
#
# Why this exists (the backend-session pain, 2026-05-29):
#   Old flow: agent dispatches a juror sub-agent, the verdict comes back ONLY in
#   the sub-agent's return string, and the agent must re-type ~10 fields into
#   `atone.sh juror`. If that string is lost (compaction, fumble) the agent has
#   to RE-RUN the juror. That violates rules/sub-agent-outputs.md (material
#   sub-agent output must be persisted to disk). Here the verdict is written to
#   disk the moment it's produced, so a re-run is never needed.
#
# Design: the juror is a PURE FUNCTION (text in → JSON out, NO tools). This
# script gathers prior-pattern context (recent slugs + prior verdicts for this
# slug) and bakes it into the prompt, so the headless juror needs no Bash and
# the verdict is reproducible from the case file alone.
#
# Usage:
#   atone-juror-dispatch.sh --case-file <case.json> [--review-report <path>] [--out <verdict.json>]
#
# Case file (JSON): { user_callout, agent_did, agent_defense, context, slug,
#                     session_id? }
#
# Output: writes verdict JSON to --out (default atone/verdicts/<session>-<slug>-<ts>.json),
#         prints the verdict JSON to stdout, prints "VERDICT_PATH=<path>" to stderr.
# Exit:   0 = verdict produced + persisted; 3 = juror unavailable (caller should
#         record juror_unavailable:true); 2 = usage error.

set -uo pipefail

ATONE_DIR="${ATONE_DIR:-$HOME/.claude/atone}"
PERSONA="$HOME/.claude/personas/juror.md"
CLAUDE_BIN="${CLAUDE_BIN:-$HOME/.local/bin/claude}"

# The juror is a DIFFERENT model from the offender, by design: the same model
# that made the mistake, asked to grade itself, misses its own error far more
# often than an externally-attributed one (the self-correction illusion). So the
# juror defaults to Sonnet — independent of the Opus main loop and cheaper — with
# only the genuinely-hard 'ambiguous' verdicts escalated to Opus for a second
# opinion. This became viable once the headless prompt was made compact (the full
# persona made claude -p slow/parse-fragile → the June juror-unavailable events);
# verified end-to-end ~15s clean verdict at sonnet. Override with ATONE_JUROR_MODEL.
JUROR_MODEL="${ATONE_JUROR_MODEL:-sonnet}"
JUROR_ESCALATE_MODEL="${ATONE_JUROR_ESCALATE_MODEL:-opus}"

case_file=""; review_report=""; out=""
while [ $# -gt 0 ]; do
  case "$1" in
    --case-file)     case_file="$2"; shift 2 ;;
    --review-report) review_report="$2"; shift 2 ;;
    --out)           out="$2"; shift 2 ;;
    *) echo "atone-juror-dispatch: unknown flag: $1" >&2; exit 2 ;;
  esac
done
[ -f "$case_file" ] || { echo "atone-juror-dispatch: --case-file not found: $case_file" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "atone-juror-dispatch: jq required" >&2; exit 2; }
[ -x "$CLAUDE_BIN" ] || { echo "atone-juror-dispatch: claude not executable at $CLAUDE_BIN — juror unavailable" >&2; exit 3; }

slug=$(jq -r '.slug // ""' "$case_file")
session_id=$(jq -r '.session_id // ""' "$case_file")
[ -n "$session_id" ] || session_id="${CLAUDE_CODE_SESSION_ID:-nosession}"
[ -n "$slug" ] || { echo "atone-juror-dispatch: case file missing .slug" >&2; exit 2; }

# Prior-pattern context, baked in so the juror needs no tools.
prior_slugs=$(bash "$HOME/.claude/scripts/atone.sh" slugs 2>/dev/null | head -20 || true)
prior_verdicts=$(jq -rc --arg s "$slug" 'select((.related_atone_slugs // []) | any(. == $s)) | {verdict, confidence, ts: .ts[:10]}' \
  "$ATONE_DIR/judgments.jsonl" 2>/dev/null | tail -5 || true)

# Pull the case fields into vars FIRST (no command-substitution inside a heredoc —
# bash 3.2 mis-parses $()-containing-heredoc-containing-$(), which is what broke
# the first cut of this script).
uc=$(jq -r '.user_callout // ""'  "$case_file")
ad=$(jq -r '.agent_did // ""'     "$case_file")
adf=$(jq -r '.agent_defense // ""' "$case_file")
ctx=$(jq -r '.context // ""'      "$case_file")
[ -n "$prior_verdicts" ] || prior_verdicts="(none recorded yet)"

# Build the prompt by appending pieces to a temp file — no nesting, no fragility.
prompt_file=$(mktemp "${TMPDIR:-/tmp}/atone-juror-prompt.XXXXXX")
trap 'rm -f "$prompt_file" 2>/dev/null' EXIT
{
  # COMPACT juror prompt (not the full persona). The 200-line persona.md makes
  # headless `claude -p` ruminate for minutes and frequently return no parseable
  # verdict (the juror-unavailable failures). A distilled prompt returns a clean
  # verdict in ~10s. persona.md ($PERSONA) remains the canonical spec/rationale;
  # this is its operational distillation — keep the two in sync when either moves.
  cat <<'JUROR_EOF'
You are a JUROR giving a fair second opinion on whether an agent's mistake was
real. You are the juror, not the judge — the USER is the judge and can overrule
you. You have NO tools; reason only from the context below and return ONE JSON
object. You exist to catch BOTH failure modes: the agent under-correcting AND the
agent over-capitulating (recording an atone when it was actually right).

Pick ONE verdict (lowercase, hyphenated):
- very-wrong: obvious slip; no constraint excuses it
- understandably-wrong: real slip, but a genuine constraint contributed (limited
  context, ambiguous input reasonably read, no cross-session memory)
- ambiguous: genuinely unclear who's right
- probably-right: agent has a substantive case; the correction is plausible but
  not clearly justified
- reasonably-right: agent was correct given the information it had

Calibration:
- Name the ONE checkable fact that decides it (a file:line absent, a skipped grep,
  no run signal, a carve-out the rule does not contain). A confirm with no
  nameable tell is weak — lean toward the agent.
- Clusters leaning CONFIRM: A = ungrounded assertion (claimed structure/authority
  without reading the code); B = declared done/passing with no run signal. A slip
  fitting NO cluster deserves more scrutiny before you confirm.
- Use the injected prior verdicts: a first-ever occurrence resists severity
  inflation; a 3rd+ occurrence of an A/B slug leans serious; a same-session repeat
  of structural-claim-without-reading-code is auto very-wrong.
- Anti-sycophancy (applies to YOU): do not drift toward "right" to please the
  agent, and do not rubber-stamp the user. Framing-only heat with no behavior
  regression, where the user did not ask for softer behavior, is reasonably-right.
  Use the full scale honestly.

IMPORTANT: You have NO tools. All context you need is below. Return ONLY the JSON
object specified at the end — no prose, no markdown fence.

JUROR_EOF
  printf 'PRIOR-PATTERN CONTEXT (already looked up for you):\nTop recurring slugs:\n%s\n\n' "$prior_slugs"
  printf 'Prior verdicts for this slug (%s):\n%s\n\n' "$slug" "$prior_verdicts"
  [ -n "$review_report" ] && [ -f "$review_report" ] && {
    printf 'SKEPTICAL-REVIEW REPORT (grounded findings for this change — weigh these):\n'
    cat "$review_report"; printf '\n\n'
  }
  printf 'CASE TO EVALUATE:\nuser_callout: %s\nagent_did: %s\nagent_defense: %s\ncontext: %s\ncandidate_slug: %s\n\n' \
    "$uc" "$ad" "$adf" "$ctx" "$slug"
  # Output schema LAST so it is the most recent instruction. related_atone_slugs
  # MUST include the candidate slug so the judgment links to its event. reasoning
  # is capped (length is hedging, and long prose is what slowed the old prompt).
  printf 'Return ONLY this JSON object — no prose, no fence, reasoning <=3 sentences:\n'
  printf '{"verdict":"very-wrong|understandably-wrong|ambiguous|probably-right|reasonably-right","confidence":"low|medium|high","mechanical_tell":"the one checkable fact deciding this, or none","cluster":"A|B|C|D|E|none","reasoning":"<=3 sentences, evidence-based, no flattery","slips_identified":[],"constraints_considered":[],"should_have_done":"one specific alternative","related_atone_slugs":["%s"],"scope_note":"this incident only"}\n' "$slug"
} > "$prompt_file"

# Dispatch headless. Plain output (one JSON object). Retry once on empty/parse
# failure before giving up (A1: transient claude -p hiccups are common; a single
# retry converts most "unavailable" events into real verdicts).
# Extract the LAST balanced top-level {...} that parses as a dict with "verdict"
# (A7: robust to a ```json fence, prose-before-the-object, pretty-print, and
# trailing prose — the old sed-from-first-brace broke on a stray prose brace).
extract_verdict() {
  printf '%s' "$1" | python3 -c '
import sys, json
t = sys.stdin.read()
objs = []; depth = 0; start = -1
for i, c in enumerate(t):
    if c == "{":
        if depth == 0: start = i
        depth += 1
    elif c == "}":
        if depth > 0:
            depth -= 1
            if depth == 0 and start >= 0:
                objs.append(t[start:i+1]); start = -1
for o in reversed(objs):
    try:
        # strict=False permits literal control chars (newlines/tabs) inside
        # string values — the juror reasoning field is multi-paragraph, so the
        # model routinely emits raw newlines there; strict parsing rejected them
        # ("control characters U+0000-U+001F must be escaped") and dropped every
        # verdict, which is the juror-unavailable-with-rc=0 failure.
        d = json.loads(o, strict=False)
        if isinstance(d, dict) and "verdict" in d:
            print(json.dumps(d, separators=(",", ":"))); break
    except Exception:
        pass
' 2>/dev/null
}
# Run the juror at a given model; retry once on empty/parse failure. Called
# DIRECTLY (not via $()) so the exit code and the verdict both propagate to the
# parent — a command-substitution subshell would strip both. Outputs: global
# `rc` (claude's exit code) and global `JUROR_VERDICT` (verdict JSON, "" on fail).
run_juror() {
  local model="$1" attempt raw
  JUROR_VERDICT=""
  for attempt in 1 2; do
    raw=$("$CLAUDE_BIN" -p --model "$model" < "$prompt_file" 2>>"${ATONE_JUROR_ERRLOG:-/dev/null}")
    rc=$?
    JUROR_VERDICT=$(extract_verdict "$raw")
    [ -n "$JUROR_VERDICT" ] && break
    [ "$attempt" = "1" ] && echo "atone-juror-dispatch: empty/unparseable verdict (rc=$rc, model=$model) — retrying once…" >&2
  done
}

rc=0
run_juror "$JUROR_MODEL"
verdict="$JUROR_VERDICT"
# Escalate only the genuinely-hard 'ambiguous' verdicts to the stronger model.
if [ -n "$verdict" ] && [ "$JUROR_MODEL" != "$JUROR_ESCALATE_MODEL" ]; then
  if [ "$(printf '%s' "$verdict" | jq -r '.verdict // ""' 2>/dev/null)" = "ambiguous" ]; then
    echo "atone-juror-dispatch: ambiguous on $JUROR_MODEL — escalating to $JUROR_ESCALATE_MODEL…" >&2
    run_juror "$JUROR_ESCALATE_MODEL"
    [ -n "$JUROR_VERDICT" ] && verdict="$JUROR_VERDICT"
  fi
fi

if [ "$rc" -ne 0 ] || [ -z "$verdict" ]; then
  echo "atone-juror-dispatch: claude -p produced no parseable verdict (rc=$rc) — juror unavailable" >&2
  exit 3
fi

# Validate the verdict enum.
v=$(printf '%s' "$verdict" | jq -r '.verdict // ""')
case "$v" in
  very-wrong|understandably-wrong|ambiguous|probably-right|reasonably-right) ;;
  *) echo "atone-juror-dispatch: verdict not in enum: '$v' — juror unavailable" >&2; exit 3 ;;
esac

# Persist to disk (discoverable by session + slug).
[ -n "$out" ] || {
  mkdir -p "$ATONE_DIR/verdicts"
  out="$ATONE_DIR/verdicts/${session_id}-${slug}-$(date -u '+%Y%m%dT%H%M%SZ').json"
}
printf '%s\n' "$verdict" > "$out"
echo "VERDICT_PATH=$out" >&2

# Persona usage residue — best-effort. MUST NOT write to stdout (the verdict is the
# only thing on stdout, parsed by the caller); errors are swallowed so a logging
# failure can never break the gate. outcome is 'unknown' because whether the verdict
# is later overruled is a downstream signal this script doesn't see.
if [ -x "$HOME/.claude/scripts/persona-log.sh" ]; then
  _vc=$(printf '%s' "$verdict" | jq -r '.confidence // ""' 2>/dev/null)
  "$HOME/.claude/scripts/persona-log.sh" record juror --mode dispatched \
    --session "$session_id" --task "atone:${slug}" --outcome unknown \
    --note "verdict=${v}${_vc:+ conf=${_vc}}" >/dev/null 2>&1 || true
fi

printf '%s\n' "$verdict"
