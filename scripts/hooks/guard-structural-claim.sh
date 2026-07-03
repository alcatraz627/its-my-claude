#!/usr/bin/env bash
# guard-structural-claim.sh — Stop hook: a GROUNDING GATE, not an error detector.
#
# When the agent's final message asserts how a subsystem works — authority /
# source-of-truth / call-chain / an external tool's behavior / a dependency claim —
# and this turn shows NO grounding (no in-message cite AND no Read/Grep of the named
# subject), the gate fires. A fire forces the agent to SYNC WITH THE FILESYSTEM
# before proceeding.
#
# Philosophy (the user's, verbatim): "the extra time or tool calls are worthwhile
# for correctness even if nothing comes out of the procedure, because it's much
# worse when things are MISSED." So this gate's value is FORCED GROUNDING, not
# true-positive yield:
#   - A false FIRE (the claim was actually right) is ACCEPTABLE when a grounding
#     read was possible and simply wasn't done — the sync is the point.
#   - A fire is BAD only when grounding is IMPOSSIBLE (person/team owns; external
#     behavior already looked up) or ALREADY DONE (subject read/edited this turn,
#     a file:line cited, a run verified). Those are the carve-outs.
# Anti-paralysis comes from LOOP-SAFETY (block once per claim sentence, then step
# aside) — NOT from silencing. The block is kept because a nudge forces nothing.
#
# Backstop for atone `structural-claim-without-reading-code` (S3, #1 recurring).
#
# Detection pipeline (all must hold to fire):
#   ①  a claim-shape matches the final message (authority incl owns/mints; and the
#      ship-gated callchain/extmech/manifest shapes when enabled)
#   ②  no clearing carve-out in the message: file:line/[UNVERIFIED] (E1), a
#      verify-verb+runtime (E3), person/team-owns homograph (E5), or a meta-quote
#      of the pattern/hook itself (META)
#   ③  read-gate (this turn only):
#       - AUTHORING frame (ownership table / arrow-assignment / "should own" /
#         state-ownership map): cleared by ANY substantive code interaction this
#         turn (Read/Grep/Glob/Edit/Write of a code file). If the turn was pure
#         prose-from-memory → FIRE with an authoring-specific message (the value is
#         designing-WITH-grounding).
#       - else: E2 backtick-path cite clears; extmech cleared by a web lookup;
#         manifest cleared by a manifest-file read; otherwise the claim SUBJECT
#         must have been read/edited this turn, or it fires.
#
# Response (stakes-scaled, loop-safe on the MATCHED CLAIM SENTENCE):
#   - docs-only turn (no code edited)      → systemMessage (never a block, never
#                                            silent — grounding still valued in design)
#   - high-stakes repo + code edited       → decision:block once, then step aside
#   - low-stakes                           → systemMessage
# Mute: touch ~/.claude/.no-structural-claim-gate
#
# Shapes are gated by STRUCTCLAIM_SHAPES (comma list). Default ships only the
# shapes that passed a full-corpus groundable-fire replay; the rest are computed
# but default-off. See the SHIP-GATE RESULTS block below for the measured numbers.

set -uo pipefail
[ -f "$HOME/.claude/.no-structural-claim-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tp" ] && [ -f "$tp" ] || exit 0
sid8="${sid:0:8}"
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$cwd" ] && cwd="$PWD"

WARN="$HOME/.claude/scripts/hooks/warn-log.sh"

# ── SHIP-GATE RESULTS (full-corpus replay over 923 transcripts / 2958 turns,
# 2026-07-02; see assets/reports/20260702-hook-lanes/lane4-structural-claim.md).
# Baseline (old live hook): 31 fires (27 BLOCK / 4 SOFT), ~0 TP by error-detection.
#   authority : SHIP. Final corpus: 4 fires (0 BLOCK / 4 SOFT) — all 4 hand-read as
#               GROUNDABLE (0% pointless); the person/meta/verified/grounded subset
#               correctly drops, the design-from-memory authoring fires stay. The
#               owns/mints branch is KEPT (drives those valued authoring fires).
#               (BLOCK is reachable — proven by fixtures — but no high-stakes
#               blind-in-code turn exists in this corpus, consistent with the
#               empirical 0/48-TP finding.)
#   callchain : HOLD (default-off). Restricted (subject+verb+checkable object,
#               "calls" dropped as a noun homograph) it fires 0 MARGINAL times on
#               the corpus — its prior fires were all "tool calls"/"N calls" noun
#               matches. Nothing to validate; kept precise for opt-in. Enable:
#               STRUCTCLAIM_SHAPES=authority,callchain
#   extmech   : HOLD (default-off). 1 corpus fire — cannot validate a ≥10 sample;
#               adversarial flagged framework-behavior prose ("React renders").
#               -i bug fixed (matched case-sensitively). Enable to test.
#   manifest  : HOLD (default-off). 0 corpus fires; "dependency" homograph risk.
SHAPES_ENABLED="${STRUCTCLAIM_SHAPES:-authority}"
is_enabled() { case ",$SHAPES_ENABLED," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }

# ── Turn boundary: slice the tail at the LAST REAL USER MESSAGE (steal from
# declared-ready-stop.sh) so the read-gate sees only THIS turn's tool calls.
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

# ── Regexes ──────────────────────────────────────────────────────────────────
# ①a AUTHORITY — present-tense authority predicates. owns/mints KEPT (drives the
#    authoring fires the philosophy values). E5 PERSON_RX + the authoring read-gate
#    are what tame the owns/mints homograph, not deletion of the branch.
AUTHORITY_RX='\bis the (authority|source of truth|final (check|word|authority|arbiter)|only (writer|owner|source)|hot path|canonical (source|owner)|single source of truth)\b|\b(owns|mints|minted|is the only thing that writes) the\b|\bis the only (writer|owner|authority) (of|for|on)\b|\b(is|are)\s+(just|merely|only)\s+a\s+(jwt|cookie|cache( hit| lookup)?|single (function|call|query)|thin wrapper|getter|setter|no-?op)\b'

# ①b CALLCHAIN — SUBJECT + flow verb + a CHECKABLE object (backtick span /
#    snake_case / path / file.ext). Two restrictions vs the design draft, both from
#    the adversarial review: (a) the object must be read-gate-matchable (no generic
#    "the handler"); (b) a SUBJECT (pronoun / `the <noun>` / Name / backtick) must
#    precede the verb, so noun usages ("tool calls", "six calls", "2-3 calls") do
#    NOT match. Default-OFF (see ship-gate results) — kept precise anyway.
# "calls" is deliberately dropped from the verb list — it is the dominant noun
# homograph ("tool calls", "six calls", "2-3 calls") and even a capitalized-noun
# subject anchor ("Tool calls collapse") slips past. The remaining verbs are rarely
# nouns. Subject prefix still required.
CALLCHAIN_RX='\b(it|this|which|that|the [a-z][a-zA-Z]+|[A-Z][a-zA-Z0-9]+|`[^`]+`)\s+(hits|consumes|invokes|reads from|writes to|routes? (to|through)|goes through|feeds into|is consumed by|dispatched to|delegates to|proxies to)\b[^.\n]{0,40}?(`[^`]+`|\b[a-z][a-z0-9]*(_[a-z0-9]+)+\b|\b[A-Za-z0-9_]+/[A-Za-z0-9_./-]+\b|\b[a-zA-Z0-9_-]+\.(py|ts|tsx|js|jsx|go|rs|swift|rb|sh)\b)'

# ①c EXTERNAL-MECHANISM — Capitalized service token + behavior verb. Run
#    CASE-SENSITIVELY (the capital is the ONLY anchor; the -i bug that defeated it
#    is fixed by matching this shape with `rg -P`, no -i).
EXTMECH_RX='\b([A-Z][a-zA-Z0-9]{2,}(\.[a-z]+)?) (renders?|supports?|returns?|handles?|interprets?|strips?|escapes?|parses?|accepts?|serializes?|validates?)\b'

# ①d DEPENDENCY-MANIFEST — dependency / manifest-membership claims.
MANIFEST_RX='\bis (a |an )?(direct |transitive |dev )?(dependency|dep)\b|\bis (already |still )?(installed|in (package\.json|Cargo\.toml|go\.mod|requirements\.txt|pyproject\.toml|Gemfile|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|go\.sum))\b|\bnpm (un)?install\b'

# ② clearing carve-outs (silent — grounding present or impossible)
CITE_RX='[A-Za-z0-9_./-]+\.[A-Za-z0-9]+:[0-9]+|\[UN(VERIFIED|CONFIRMED)\]'
VERIFY_RX='\b(confirmed|verified|verifications? (pass|passed)|all (checks|verifications) pass|checks pass|i (ran|read|grepped|opened|checked|traced|inspected)|read all [0-9]+|read [0-9]+ (files|hunks)|after reading|tests? (pass|passed|green)|built (and|,) tested|tested (it|live|and|against)|ran it|launchctl|\bPID [0-9]+|exit[- ]status [0-9]|:build\b|eslint green|ts:build|built, tested|code[- ]truth)\b'
# E5 person/team/ROLE ownership — "owns" here is responsibility, not a code
# mechanism, so grounding is impossible. PERSON_RX is the adjacency form; PERSON2_RX
# catches a Claude/human ROLE within 50 chars of "owns" (non-adjacent), added after a
# pointless BLOCK on a tool-less juror: "the supervising agent that dispatched this
# juror call and owns the atone event pipeline". Code entities (worker/daemon/
# service) are deliberately NOT roles — "the worker owns the queue" is a groundable
# code claim, not responsibility.
# "owner" is deliberately NOT a role here — in a state-ownership DESIGN "the owner"
# is a code module, and clearing on it silences the exact authoring fire we want.
PERSON_RX='\b(whoever|the (team|person|dev|developer|maintainer)|someone) (that |who )?owns\b'
PERSON2_RX='\b(agent|juror|supervisor|parent|caller|sub-process|the team|the person|maintainer|developer|whoever|someone)\b[^.\n]{0,50}\bowns\b'
# "owned by <Name>/@handle" — human/team attribution. Matched CASE-SENSITIVELY (the
# capital IS the anchor; -i makes it match "owned by the output-data hook", a code
# entity — the same -i-defeats-capital bug the extmech shape had).
OWNEDBY_RX='\bowned by (@|[A-Z][a-z])'
# META must be genuinely about THIS pattern/gate. A bare "this hook" is dropped — it
# matches React hooks in ordinary design prose ("this hook holds a map …").
META_RX='structural-claim|AUTHORITY_RX|CALLCHAIN_RX|EXTMECH_RX|MANIFEST_RX|atone pattern|the atone|guard-structural|this (structural-claim|grounding)[- ](gate|hook)|(gate|hook) (would )?fire on the (pattern|claim|authority)'

# E2 backtick-path (clears NON-authoring only)
BTPATH_RX='`[^`]*[A-Za-z0-9_-]+/[A-Za-z0-9_./-]+\.[A-Za-z0-9]+[^`]*`'

# E4 authoring frame (ownership table row / arrow-assignment / prescriptive own /
#    state-ownership map). Detected on the whole message.
# Box-drawing arrows (──►/─►) are always ownership/dataflow diagrams → authoring.
# A plain prose arrow "→" is authoring ONLY when it sits within 50 chars of an
# ownership word ("owns X → Y"), never on its own — the bare "→" appears in
# ordinary prose ("changed → unchanged") and mis-routed non-authoring claims into
# the authoring branch (skipping the E2 clear).
AUTHORING_RX='\|[^|]*\b(owner|owns|authority|writer|owned)\b[^|]*\||──►|──?►|─►|->[[:space:]]*(hook|owns)|\bowns?\b[^\n]{0,50}→|→[^\n]{0,50}\bowns?\b|\b(should|will|would|propose[ds]?|plan(ned)? to|let'\''s have|going to) (own|be the (owner|authority|source)|act as)\b|state[- ]ownership map|ownership[- ]first|owns? its (data|state|shape|wiring)'

CODE_RE='\.(py|ts|tsx|js|jsx|mjs|cjs|go|rs|swift|rb|java|kt|c|cc|cpp|h|hpp|sh|sql|vue|svelte|scala|php|lua)([^a-zA-Z0-9]|$)'
MAN_RE='(package\.json|Cargo\.toml|go\.mod|requirements\.txt|pyproject\.toml|Gemfile|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|go\.sum)'

# ── Stage ① — first matching sentence of the first enabled shape ─────────────
segs_file=$(mktemp 2>/dev/null) || segs_file="/tmp/sc-segs-$$"
printf '%s' "$text" | rg -oP '[^.!?\n]+[.!?]?' > "$segs_file" 2>/dev/null || true

klass=""; claim_sentence=""
for shape in authority callchain extmech manifest; do
  is_enabled "$shape" || continue
  case "$shape" in
    authority) s=$(rg -m1 -iP "$AUTHORITY_RX" "$segs_file" 2>/dev/null || true) ;;
    callchain) s=$(rg -m1 -iP "$CALLCHAIN_RX" "$segs_file" 2>/dev/null || true) ;;
    extmech)   s=$(rg -m1 -P  "$EXTMECH_RX"  "$segs_file" 2>/dev/null || true) ;;  # case-sensitive
    manifest)  s=$(rg -m1 -iP "$MANIFEST_RX" "$segs_file" 2>/dev/null || true) ;;
    *) s="" ;;
  esac
  if [ -n "$s" ]; then klass="$shape"; claim_sentence="$s"; break; fi
done
rm -f "$segs_file" 2>/dev/null || true
[ -n "$klass" ] || exit 0

# ── Stage ② — clearing carve-outs on the whole message (silent) ──────────────
for rx in "$CITE_RX" "$VERIFY_RX" "$PERSON_RX" "$PERSON2_RX" "$META_RX"; do
  printf '%s' "$text" | rg -qiP "$rx" 2>/dev/null && exit 0
done
# case-sensitive "owned by <Name>" (capital anchor must survive)
printf '%s' "$text" | rg -qP "$OWNEDBY_RX" 2>/dev/null && exit 0

# ── Gather this turn's tool signals (from turn_json) ─────────────────────────
read_targets=$(printf '%s\n' "$turn_json" \
  | jq -r 'select(.type=="assistant") | .message.content[]?
      | select(.type=="tool_use")
      | if   .name=="Read"  then (.input.file_path // empty)
        elif .name=="Grep"  then ((.input.pattern // "") + " " + (.input.path // ""))
        elif .name=="Glob"  then (.input.pattern // "")
        elif (.name=="Edit" or .name=="MultiEdit" or .name=="Write") then (.input.file_path // empty)
        elif .name=="Bash"  then (.input.command // empty)
        else empty end' 2>/dev/null)

# substantive code interaction this turn → grounds an authoring design
code_touch=0
if printf '%s\n' "$turn_json" | jq -e 'select(.type=="assistant")|.message.content[]?|select(.type=="tool_use" and (.name=="Grep" or .name=="Glob"))' >/dev/null 2>&1; then
  code_touch=1
fi
if [ "$code_touch" = 0 ] && printf '%s\n' "$read_targets" | rg -qiP "$CODE_RE" 2>/dev/null; then
  code_touch=1
fi

# files edited this turn → drives the docs-only demotion (M11).
edited_paths=$(printf '%s\n' "$turn_json" \
  | jq -r 'select(.type=="assistant")|.message.content[]?|select(.type=="tool_use" and (.name=="Edit" or .name=="MultiEdit" or .name=="Write"))|.input.file_path//empty' 2>/dev/null)
edited_any=0; [ -n "$edited_paths" ] && edited_any=1
edited_code=0
[ "$edited_any" = 1 ] && printf '%s\n' "$edited_paths" | rg -qiP "$CODE_RE" 2>/dev/null && edited_code=1

# web lookup (clears extmech)
web_lookup=0
if printf '%s\n' "$turn_json" | jq -e 'select(.type=="assistant")|.message.content[]?|select(.type=="tool_use" and (.name=="WebSearch" or .name=="WebFetch"))' >/dev/null 2>&1; then
  web_lookup=1
fi
[ "$web_lookup" = 0 ] && printf '%s\n' "$read_targets" | rg -qiP '\b(curl|wget)\b' 2>/dev/null && web_lookup=1

# manifest file read (clears manifest)
manifest_read=0
printf '%s\n' "$read_targets" | rg -qiP "$MAN_RE" 2>/dev/null && manifest_read=1

# ── Stage ③ — read-gate ──────────────────────────────────────────────────────
authoring=0
printf '%s' "$text" | rg -qiP "$AUTHORING_RX" 2>/dev/null && authoring=1

fire_kind=""
if [ "$authoring" = 1 ]; then
  # designing ownership: cleared by ANY substantive code interaction this turn.
  if [ "$code_touch" = 1 ]; then
    exit 0
  fi
  fire_kind="authoring"
else
  # non-authoring read-gate
  printf '%s' "$text" | rg -qP "$BTPATH_RX" 2>/dev/null && exit 0          # E2
  [ "$klass" = extmech ]  && [ "$web_lookup" = 1 ]    && exit 0            # M9
  [ "$klass" = manifest ] && [ "$manifest_read" = 1 ] && exit 0           # manifest-file read
  # subject extraction from the matched sentence
  subject=$(printf '%s' "$claim_sentence" | rg -oP -m1 '`[^`]+`' 2>/dev/null | tr -d '`')
  [ -z "$subject" ] && subject=$(printf '%s' "$claim_sentence" | rg -oP -m1 '\b[a-z][a-zA-Z0-9]*(_[a-zA-Z0-9]+)+\b' 2>/dev/null || true)
  [ -z "$subject" ] && subject=$(printf '%s' "$claim_sentence" | rg -oP -m1 '\b[A-Za-z0-9_]+/[A-Za-z0-9_./-]+\b' 2>/dev/null || true)
  [ -z "$subject" ] && subject=$(printf '%s' "$claim_sentence" | rg -oP -m1 '\b[a-zA-Z0-9_-]+\.(py|ts|tsx|js|jsx|go|rs|swift|rb|sh|json|md)\b' 2>/dev/null || true)
  [ "$klass" = extmech ] && subject=$(printf '%s' "$claim_sentence" | rg -oP -m1 '\b[A-Z][a-zA-Z0-9]{2,}' 2>/dev/null || true)
  # subject read/edited this turn → grounding done → silent
  if [ -n "$subject" ] && printf '%s' "$read_targets" | rg -qiF -- "$subject" 2>/dev/null; then
    exit 0
  fi
  fire_kind="blind"
fi

# ── Survived → FIRE. Stakes-scaled, docs-only demoted, loop-safe on the SENTENCE.
# Response policy:
#   authoring fire                       → SOFT always (design nudge; a hard block
#                                          mid-design is heavier than the value; the
#                                          block is reserved for blind claims about
#                                          EXISTING code, the canonical S3).
#   blind fire, edited only docs/config  → SOFT (M11 docs-only demotion)
#   blind fire, high-stakes (code edited
#     OR nothing edited — a bare analysis
#     turn asserting architecture blind)  → BLOCK (the forcing sync)
#   blind fire, low-stakes               → SOFT
stakes=$(bash "$HOME/.claude/scripts/stakes-tier.sh" "$cwd" 2>/dev/null || echo low)
docs_only=0
[ "$edited_any" = 1 ] && [ "$edited_code" = 0 ] && docs_only=1

if [ "$fire_kind" = "authoring" ]; then base="soft"
elif [ "$docs_only" = 1 ]; then base="soft"
elif [ "$stakes" = "high" ]; then base="block"
else base="soft"; fi

MARK="/tmp/claude-structural-claim-${sid8}"
sig=$(printf '%s' "$claim_sentence" | shasum 2>/dev/null | awk '{print $1}')
prev=""; [ -f "$MARK" ] && prev=$(cat "$MARK" 2>/dev/null)

if [ "$fire_kind" = "authoring" ]; then
  body="you're assigning ownership/authority in a design ($klass shape) but this turn shows no Read/Grep/Edit of any code file — designing over code from memory is exactly how structural-claim (S3) recurs. Ground the design: read the modules you're designing over, then state the ownership. False positive (you read code / verified out-of-band)? Say so and proceed — this won't re-block the same claim. Mute: touch ~/.claude/.no-structural-claim-gate"
else
  body="your message states how '${subject:-a subsystem}' works ($klass) but this turn shows no Read/Grep of it and no in-message file:line/backtick-path cite. Pattern-matching is not evidence. Read ${subject:-the subject} (or name its file:line), or tag it [UNVERIFIED]. False positive (you read it / verified out-of-band)? Say so — this won't re-block the same claim. Mute: touch ~/.claude/.no-structural-claim-gate"
fi

emit_soft() { jq -cn --arg m "⚠ structural-claim (grounding gate) — $body" '{systemMessage:$m}' 2>/dev/null || true
  [ -x "$WARN" ] && bash "$WARN" --hook structural-claim --action soft --heeded unknown >/dev/null 2>&1 || true; }
emit_block() { jq -cn --arg r "⛔ structural-claim (grounding gate) — $body" '{decision:"block", reason:$r}' 2>/dev/null || true
  [ -x "$WARN" ] && bash "$WARN" --hook structural-claim --action block --heeded unknown >/dev/null 2>&1 || true; }

if [ "$sig" = "$prev" ] && [ -n "$sig" ]; then
  # Same claim sentence as the last Stop — step aside (never trap).
  [ "$base" = "block" ] && emit_soft   # a would-be block demotes to a visible note
  exit 0                                # a would-be soft goes silent on repeat
fi
printf '%s' "$sig" > "$MARK" 2>/dev/null || true

if [ "$base" = "block" ]; then emit_block; else emit_soft; fi
exit 0
