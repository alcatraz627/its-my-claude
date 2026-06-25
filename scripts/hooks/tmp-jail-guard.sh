#!/usr/bin/env bash
# tmp-jail-guard.sh — PreToolUse(Write|Edit|MultiEdit|NotebookEdit|Bash).
#
# A session-scoped "/tmp jail": when the CURRENT session has a marker at
# ~/.claude/run/tmpjail/<session_id>, writes are confined to /tmp (and its macOS
# real path /private/tmp). Reads are never touched. Other running sessions are
# unaffected — the marker is keyed by the session_id from the hook payload, so the
# global registration enforces per-session.
#
# Off-switch — HONEST SCOPE: this is a guardrail, not a security boundary. A hook
# cannot mechanically jail a Bash-enabled agent against its will. The agent is
# INSTRUCTED to ask the user to lift the jail (`tmp-jail off <session_id>`), and
# this gate blocks the common self-lift paths (the off command, marker delete via
# rm/trash/unlink/truncate/find-delete, settings edits). But a determined agent
# can still escape — via an interpreter write (`python -c open(...,'w')`), or a
# verb/vector not enumerated here — exactly like the Bash write leak below. The
# only airtight jail is an OS sandbox (sandbox-exec / container). No mute file
# (deliberate) so there is no single silent escape file.
#
# FAIL-OPEN for non-jailed sessions: any uncertainty (no session_id, no jq,
# malformed payload) → allow, so this never breaks a session that isn't jailed.
# FAIL-CLOSED on the jailed Bash path when rg is missing (can't verify → block).
#
# Reliability note: the Write/Edit/* gate is exact (resolve + normalize file_path).
# The Bash gate is BEST-EFFORT — see the scope note above.

set -uo pipefail

JAIL_DIR="$HOME/.claude/run/tmpjail"

input=$(cat 2>/dev/null) || exit 0
[ -n "$input" ] || exit 0

sid=$(printf '%s' "$input"  | jq -r '.session_id // empty' 2>/dev/null) || exit 0
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty'  2>/dev/null) || exit 0
cwd=$(printf '%s' "$input"  | jq -r '.cwd // empty'        2>/dev/null) || cwd=""

# Path is "under an allowed root". `..` components are rejected separately (a
# jailed write never legitimately needs traversal), so this stays lexical.
is_tmp() {
  case "$1" in
    */../*|*/..) return 1 ;;                                   # reject traversal
    /tmp|/tmp/*|/private/tmp|/private/tmp/*) return 0 ;;
    *) return 1 ;;
  esac
}
resolve_abs() {  # $1 path, $2 cwd → absolute (lexical)
  case "$1" in
    /*)       printf '%s' "$1" ;;
    "~"|"~/"*) printf '%s' "${1/#\~/$HOME}" ;;
    *)        printf '%s/%s' "${2:-$PWD}" "$1" ;;
  esac
}

# Command-position match for `tmp-jail on|off`: at start, after a separator, or
# path-qualified (/.../tmp-jail). NOT after a plain space, so `-m tmp-jail on`
# inside an arg does not false-trigger.
jail_verb() {  # $1 = on|off ; reads $scan
  printf '%s' "${scan:-}" | rg -qP "(?:^|[;&|]|/)[[:space:]]*tmp-jail[[:space:]]+$1\b" 2>/dev/null
}

# ── on-switch: `tmp-jail on` creates the marker for THIS session. The hook is the
#    only component that knows session_id, so it owns marker creation. ──
if [ "$tool" = "Bash" ]; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || cmd=""
  scan=$(printf '%s' "$cmd" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g" 2>/dev/null) || scan="$cmd"
  if jail_verb on; then
    [ -n "$sid" ] || exit 0
    mkdir -p "$JAIL_DIR" 2>/dev/null || true
    { printf 'jailed_at=%s\ncwd=%s\n' "$(date '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || echo '?')" "$cwd" > "$JAIL_DIR/$sid"; } 2>/dev/null || true
    jq -cn --arg r "✅ /tmp JAIL ENABLED for this session ($sid).
Writes are now confined to /tmp (and /private/tmp); reads are unaffected.
To work outside /tmp again, ask the USER to run:  tmp-jail off $sid
You should not try to lift it yourself — ask the user." \
      '{decision:"block", reason:$r}' 2>/dev/null || true
    exit 0
  fi
fi

# ── not jailed → allow everything (the fast no-op path) ──
[ -n "$sid" ] || exit 0
[ -e "$JAIL_DIR/$sid" ] || exit 0

# ════ from here: THIS session is jailed ════
block() {
  jq -cn --arg r "🔒 /tmp JAIL active for this session ($sid) — writes confined to /tmp.
Blocked: $1
To work outside /tmp, ASK THE USER to lift the jail with this exact instruction:
  → the user runs:  tmp-jail off $sid
Do not try to lift it yourself or work around the jail — ask the user." \
    '{decision:"block", reason:$r}' 2>/dev/null || true
  exit 0
}

# Block the agent's own off-attempt (incl. path-qualified `~/.local/bin/tmp-jail off`).
if [ "$tool" = "Bash" ] && jail_verb off; then
  block "tmp-jail off — the agent cannot lift the jail; the user must run it"
fi

case "$tool" in
  Write|Edit|MultiEdit|NotebookEdit)
    fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null) || exit 0
    [ -n "$fp" ] || exit 0
    abs=$(resolve_abs "$fp" "$cwd")
    is_tmp "$abs" && exit 0
    block "$tool to $fp (outside /tmp)"
    ;;
  Bash)
    [ -n "${cmd:-}" ] || exit 0
    : "${scan:=$cmd}"
    # Can't verify Bash write targets without rg → fail CLOSED while jailed.
    command -v rg >/dev/null 2>&1 || block "rg unavailable — cannot verify the write target while jailed"
    # Absolute path NOT under /tmp, or a ~ / $HOME path (PCRE negative lookahead).
    NONTMP='(/(?!tmp(/|$|[[:space:]])|private/tmp(/|$|[[:space:]]))[^[:space:]|;&)]+|~[^[:space:]|;&)]*|\$HOME[^[:space:]|;&)]*)'
    WVERB='cp|mv|tee|install|rsync|ln|mkdir|touch|trash|unlink|truncate|shred'
    # 0. ANY write form whose target contains a `..` component (traversal out of /tmp).
    printf '%s' "$scan" | rg -qP "(>>?[[:space:]]*|\b($WVERB|dd|sed|perl)\b[^|;&]*[[:space:]])[^[:space:]|;&]*\.\." 2>/dev/null && block "write target uses .. traversal: $cmd"
    # 1. redirect > >> into a non-/tmp target (path sits right after the operator)
    printf '%s' "$scan" | rg -qP ">>?[[:space:]]*$NONTMP" 2>/dev/null && block "redirect (>) outside /tmp: $cmd"
    # 2. dd of=<non-/tmp>
    printf '%s' "$scan" | rg -qP "\bdd\b[^|;&]*of=$NONTMP" 2>/dev/null && block "dd outside /tmp: $cmd"
    # 3. in-place edit (sed -i / perl -i) naming a non-/tmp path
    printf '%s' "$scan" | rg -qP "\b(sed|perl)\b[^|;&]*[[:space:]]-i\b[^|;&]*$NONTMP" 2>/dev/null && block "in-place edit outside /tmp: $cmd"
    # 4. write VERBS naming a non-/tmp path (coarse: a non-/tmp READ source also
    #    trips this — conservative; a false block just sends the agent to ask).
    printf '%s' "$scan" | rg -qP "\b($WVERB)\b[^|;&]*[[:space:]]$NONTMP" 2>/dev/null && block "write command naming a non-/tmp path: $cmd"
    # 5. find ... -delete / -exec rm — a marker-removal / out-of-tree delete vector
    printf '%s' "$scan" | rg -qP "\bfind\b[^|;&]*(-delete|-exec[^|;&]*\b(rm|trash|unlink)\b)" 2>/dev/null && block "find delete/exec while jailed: $cmd"
    # 6. relative-path redirect when cwd is NOT under /tmp (escapes via cwd)
    if [ -n "$cwd" ] && ! is_tmp "$cwd"; then
      printf '%s' "$scan" | rg -qP ">>?[[:space:]]*[^/[:space:]~\$][^[:space:]|;&)]*" 2>/dev/null && block "redirect to a relative path from non-/tmp cwd ($cwd): $cmd"
    fi
    exit 0
    ;;
  *)
    exit 0 ;;
esac
exit 0
