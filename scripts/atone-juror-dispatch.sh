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
  cat "$PERSONA"
  printf '\n\n---\n\nIMPORTANT: You have NO tools in this dispatch. All context you need is below.\n'
  printf 'Return ONLY the JSON verdict object specified above — no prose, no markdown fence.\n\n'
  printf 'PRIOR-PATTERN CONTEXT (already looked up for you):\nTop recurring slugs:\n%s\n\n' "$prior_slugs"
  printf 'Prior verdicts for this slug (%s):\n%s\n\n' "$slug" "$prior_verdicts"
  [ -n "$review_report" ] && [ -f "$review_report" ] && {
    printf 'SKEPTICAL-REVIEW REPORT (grounded findings for this change — weigh these):\n'
    cat "$review_report"; printf '\n\n'
  }
  printf 'CASE TO EVALUATE:\nuser_callout: %s\nagent_did: %s\nagent_defense: %s\ncontext: %s\ncandidate_slug: %s\n' \
    "$uc" "$ad" "$adf" "$ctx" "$slug"
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
        d = json.loads(o)
        if isinstance(d, dict) and "verdict" in d:
            print(json.dumps(d, separators=(",", ":"))); break
    except Exception:
        pass
' 2>/dev/null
}
verdict=""
for attempt in 1 2; do
  raw=$("$CLAUDE_BIN" -p < "$prompt_file" 2>>"${ATONE_JUROR_ERRLOG:-/dev/null}")
  rc=$?
  verdict=$(extract_verdict "$raw")
  [ -n "$verdict" ] && break
  [ "$attempt" = "1" ] && echo "atone-juror-dispatch: empty/unparseable verdict (rc=$rc) — retrying once…" >&2
done

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
