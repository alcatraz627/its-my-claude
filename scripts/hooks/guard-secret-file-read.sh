#!/usr/bin/env bash
# guard-secret-file-read.sh — PreToolUse[Bash|Read], SYNCHRONOUS.
#
# Blocks printing the CONTENTS of a secret-shaped file. The existing
# guard-anthropic-credentials.sh covers credential WRITES; nothing covered a
# read, by Bash or by the Read tool, which is how a GitHub App private key
# reached a transcript on 2026-08-17 (prop-20260817-112815-df).
#
# The leak is worth stating precisely, because it decides this guard's shape.
# The command was `sed -E 's/=.*/=<redacted>/' pr-board/.env`. That redactor is
# line-oriented and a PEM is multi-line: the KEY= line was redacted and every
# continuation line, carrying the private exponent, passed through untouched.
# The output LOOKED sanitised, so it went unnoticed for hours. A hand-written
# redaction is a guard, and an unverified guard is not protection.
#
# THE ALLOWLIST IS THE LOAD-BEARING HALF. A block with no sanctioned way to ask
# "is this var set" just gets routed around, and a guard people learn to evade
# is worse than none. Everything that reads NAMES, counts, hashes or existence
# is allowed through; only the verbs that emit VALUES are blocked.
#
# Mute: touch ~/.claude/.no-secret-read-guard  (machine-wide, all sessions)

set -uo pipefail
[ -f "$HOME/.claude/.no-secret-read-guard" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)

# Paths whose contents are secret by shape. Deliberately not "anything with the
# word secret in it": a name-based net that wide fires on docs and source and
# teaches people to mute the guard.
#
# TWO patterns, because the two callers hand us different shapes and one regex
# cannot be right about both. The Read tool gives a bare path, so it anchors on
# ^ and $. Bash gives a command line where the path sits between spaces, quotes
# and pipes, so anchoring on $ silently misses `cat .env` and `xxd k.key | head`.
# The first version of this guard used the path pattern for both and let five of
# its own tests through, which is the same defect it exists to catch.
SECRET_BASENAME='(\.env(\.[A-Za-z0-9_.-]+)?|\.netrc|\.npmrc|\.pgpass|\.?credentials)|[^ /"'"'"']+\.(pem|key|p12|pfx|jks|keystore)|id_(rsa|dsa|ecdsa|ed25519)(\.[A-Za-z0-9]+)?'
# path form: the whole basename must be the secret name
SECRET_PATH="(^|/)($SECRET_BASENAME)\$"
# command form: the same names, bounded by shell token edges instead of ^/\$
SECRET_TOKEN="(^|[[:space:]=<>|;&\"'/])($SECRET_BASENAME)([[:space:]|;&\")']|\$)"

block() {
  local what="$1" why="$2" instead="$3"
  jq -nc --arg r "$what
$why

$instead" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

SAFE_INSTEAD='Safe ways to inspect it without emitting values:
  rg -c "^[A-Z_]+=" FILE            how many vars are set
  rg -o "^[A-Z_]+" FILE             the NAMES only, never the values
  rg -q "^GITHUB_APP_KEY=" FILE     is one particular var present
  wc -l FILE · shasum -a 256 FILE   size / fingerprint
  openssl rsa -in K.pem -pubout     the PUBLIC half of a private key
  git check-ignore -v FILE          confirm it is ignored
If you genuinely must see a value, the human reads it: ask them to run it.'

# ── the Read tool ───────────────────────────────────────────────────────────
# Read emits the whole file by definition, so there is no safe-verb question:
# a secret-shaped path is blocked outright.
if [ "$tool_name" = "Read" ]; then
  fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
  [ -n "$fp" ] || exit 0
  printf '%s' "$fp" | rg -q "$SECRET_PATH" 2>/dev/null || exit 0
  block "⛔ SECRET FILE READ BLOCKED — $fp" \
    "The Read tool emits the whole file into the transcript, and this path is secret-shaped. A private key reached a transcript this way on 2026-08-17; the key had to be rotated." \
    "$SAFE_INSTEAD"
fi

[ "$tool_name" = "Bash" ] || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$cmd" ] || exit 0

# A secret-shaped path must actually appear. Quoted spans are NOT blanked here,
# unlike the rg guard: a path is data, and blanking it is exactly what would
# hide `cat "$HOME/.env"` from this check.
printf '%s' "$cmd" | rg -q "$SECRET_TOKEN" 2>/dev/null || exit 0

# The command is judged one SEGMENT at a time (split on ; && || |), each segment
# that names a secret-shaped path on its own. Judged whole, one benign verb
# anywhere cleared everything: `ls -la .env && cat .env` passed on the `ls`
# (independent review, 2026-08-18, finding I4). A segment naming no secret path
# is skipped, so `cat notes.md | rg KEY .env` is judged only on its second half.
verdict=allow
while IFS= read -r seg; do
  [ -n "$seg" ] || continue
  printf '%s' "$seg" | rg -q "$SECRET_TOKEN" 2>/dev/null || continue

# ── the allowlist, checked BEFORE the block ─────────────────────────────────
# Each entry reads names, counts, existence or a hash — never a value. Ordered
# first so a legitimate inspection never has to argue with the block.
# -o is NOT in this list, and that omission is the whole point. Flags that print
# a COUNT, a FILENAME or nothing (-c -l -L -q) are safe whatever the caller's
# pattern is. -o prints what the pattern MATCHED, and the pattern belongs to the
# caller, so `rg -o '.*' .env` emits the entire file through an entry meant to
# make the block unnecessary. Reported by automation with a live repro, 2026-08-17.
# -o is handled separately below, admitted only with a name-shaped pattern.
if printf '%s' "$seg" | rg -q \
  -e '\brg\s+(-[a-zA-Z]*[clqL][a-zA-Z]*\s|--count|--files-with-matches|--files-without-match|--quiet)' \
  -e '\bgrep\s+(-[a-zA-Z]*[clq][a-zA-Z]*\s|--count|--quiet)' \
  -e '\b(wc|shasum|sha256sum|md5|md5sum|stat|file|ls|du|basename|dirname|realpath|readlink)\b' \
  -e '\bgit\s+(check-ignore|ls-files)\b' \
  -e '\bopenssl\s+\w+.*-pubout\b' \
  -e '\btest\s+-[fers]\b|\[\s+-[fers]\s' \
  -e '\bssh-keygen\b.*-[yl]\b' \
  2>/dev/null; then
  continue
fi

# -o / --only-matching, admitted ONLY with a name-shaped pattern: anchored at ^
# and carrying no wildcard. `rg -o '^[A-Z_]+' .env` lists variable names and is
# the reason the flag is allowed at all. `rg -o '.*'` and `rg -o 'KEY=.*'` are
# emitters wearing the same flag, so they fall through to the block below.
# This BLOCKS with its own message rather than falling through, so the reader
# learns why -o specifically was refused; rg and grep are also in EMIT below
# (a bare `rg KEY .env` prints the value line, and was let through until the
# 2026-08-18 review), so falling through would block too, just less helpfully.
if printf '%s' "$seg" | rg -q -e '\b(rg|grep)\s+.*(-[a-zA-Z]*o[a-zA-Z]*[[:space:]]|--only-matching)' 2>/dev/null; then
  pat=$(printf '%s' "$seg" | rg -o -e "'[^']*'" -e '"[^"]*"' 2>/dev/null | head -1 | sed "s/^['\"]//;s/['\"]\$//")
  safe=no
  case "$pat" in
    # The wildcard is the risk, not the quantifier. `^[A-Z_]+` repeats a
    # restricted class and can only ever emit variable names; `.` and a negated
    # class can match anything, which is how the whole file gets out.
    '^'*) printf '%s' "$pat" | rg -q -e '\.' -e '\[\^' 2>/dev/null || safe=yes ;;
  esac
  [ "$safe" = yes ] && continue
  block "⛔ SECRET FILE READ BLOCKED — -o prints what your pattern matched" \
    "\`-o\` emits the matched text, and the pattern is yours to choose, so \`rg -o '.*'\` prints the whole file. It is allowed only with an anchored, wildcard-free pattern that can name variables without revealing them." \
    "$SAFE_INSTEAD"
fi

# ── the block: a content-emitting verb aimed at that path ───────────────────
# `sed`/`awk` are here BECAUSE of the incident: they are how people write the
# redaction that does not work. `rg`/`grep` without a name-only flag print
# matching LINES, values included, so they are emitters too.
# `env` and `printenv` are anchored to a command position, not left bare. A bare
# \benv\b matches inside the FILENAME .env at a word boundary, so for every .env
# target the verb check passed on the path alone and this list did nothing. It
# failed safe (blocking more, never less) but it made mutation testing lie:
# dropping sed still showed `sed ... .env` blocked, which reads as pinned and is
# not. Only a .pem target isolates the verb. Found by automation, 2026-08-17.
EMIT='\b(cat|bat|head|tail|less|more|nl|od|xxd|strings|base64|tee|cp|sed|awk|perl|python3?|jq|dotenv|rg|grep)\b|(^|[;&|]\s*)(env|printenv)\b|(^|[;&|]\s*)<\s*\S'
printf '%s' "$seg" | rg -q "$EMIT" 2>/dev/null || continue
verdict=block; break
done < <(printf '%s\n' "$cmd" | sed -E 's/(&&|\|\||;|\|)/\
/g')
[ "$verdict" = block ] || exit 0


extra=""
if printf '%s' "$cmd" | rg -q '\b(sed|awk|perl)\b.*(redact|REDACT|s/|sub\()' 2>/dev/null; then
  extra='
This looks like a hand-written redactor. That is the exact shape that leaked:
`sed -E "s/=.*/=<redacted>/"` is line-oriented, a PEM is multi-line, and its
continuation lines carry the key material past the substitution untouched. The
output looks sanitised, which is why nobody noticed for hours.'
fi

block "⛔ SECRET FILE READ BLOCKED" \
  "This command emits the contents of a secret-shaped file into the transcript. Once printed it cannot be unsent, and the credential has to be rotated.$extra" \
  "$SAFE_INSTEAD"
