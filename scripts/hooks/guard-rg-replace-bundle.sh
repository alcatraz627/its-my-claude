#!/usr/bin/env bash
# guard-rg-replace-bundle.sh: PreToolUse[Bash], SYNCHRONOUS.
#
# Blocks the `rg -r` footgun. In ripgrep, `-r`/`--replace` is the REPLACEMENT
# flag: it consumes the next token as a replacement string and prints mangled,
# transformed output. It is NOT "recursive" (rg is recursive by default). Coming
# from grep, `-r` is muscle-memory for recursive, so `rg -r pattern path` or a
# bundle like `-rn` silently corrupts output: and the output looks plausible,
# so it poisons whatever consumes it (the `metadata`→`mnidata` incident,
# atone mist-20260612-110132-40 / prop-20260612-110331-da).
#
# Precise + low-false-positive: blocks the SHORT `-r` flag (standalone or bundled
# like -rn/-ri/-rl), but ALLOWS the long `--replace` form: so a genuine,
# deliberate replacement just spells it out. Mute: touch ~/.claude/.no-rg-replace-guard

set -euo pipefail
[ -f "$HOME/.claude/.no-rg-replace-guard" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
[ "$tool_name" = "Bash" ] || exit 0
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$command" ] || exit 0

# Scope the check to the rg invocation ONLY. A `-r` flag elsewhere in a compound
# command (`jq -r`, `sort -r`, `tail -r`, `ls -lr`) is not ripgrep's. Split the
# command into pipeline/sequence segments and inspect only segments that ARE an
# rg invocation.
#
# Blank quoted spans FIRST, because rg's own PATTERN is data, not flags. Two
# distinct over-fires come from skipping this, both verified: `rg "jq -r .cwd" f`
# read the pattern's -r as rg's, and a `|` inside a pattern split the segment and
# stranded that -r in what looked like rg's args. An earlier version of this
# comment claimed a mid-quote split could "at most cause an under-fire: the safe
# direction". It over-fired instead. Blanking keeps flag positions intact while
# emptying the pattern, so both directions are settled here rather than reasoned about.
# Blank quoted spans so a `-r` inside a search PATTERN is not read as rg's own
# flag. Delegates to the shared hook_cmd_skeleton, which handles backslash
# escapes the local sed version missed and preserves length so the segment
# splitting below keeps its offsets. Falls back to the sed form if hook-common
# is unreadable, which keeps the guard armed rather than open.
blank_quotes() {
  if [ -r "$HOME/.claude/scripts/hooks/hook-common.sh" ]; then
    . "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null || true
    if type hook_cmd_skeleton >/dev/null 2>&1; then
      printf '%s' "$1" | hook_cmd_skeleton
      return
    fi
  fi
  printf '%s' "$1" | sed "s/'[^']*'/''/g; s/\"[^\"]*\"/\"\"/g"
}
# A heredoc body is stdin, never rg's arguments: blank it before the quotes.
# Falls back to the unstripped command if the helper is missing or fails.
STRIP="$HOME/.claude/scripts/hooks/strip-payloads.py"
body_free="$command"
if [ -r "$STRIP" ]; then
  _h=$(printf '%s' "$command" | python3 "$STRIP" --heredocs-only 2>/dev/null) && [ -n "$_h" ] && body_free="$_h"
fi
scan=$(blank_quotes "$body_free")

# Blanking hides what a quoted replacement holds, and a '$1' replacement is the one
# valid use of -r. Put a marker back where the original had a $ inside a blanked
# span, so "is the next word a replacement" can be answered below. Skipped when the
# blanker changed the length (positions would no longer line up); then a quoted
# $1 reads as a plain word and the guard errs toward blocking.
MARK=$'\001'
if [[ "$body_free" == *'$'* ]] && [ "${#scan}" -eq "${#body_free}" ]; then
  marked=""
  for ((i = 0; i < ${#scan}; i++)); do
    if [ "${scan:i:1}" = " " ] && [ "${body_free:i:1}" = '$' ]; then marked+="$MARK"; else marked+="${scan:i:1}"; fi
  done
  scan="$marked"
fi

# Is the word at the start of $1 a replacement string for rg -r? True for an empty
# quote pair, a quoted word holding a $ (capture reference), or a bare word holding
# a $. A plain word such as a pattern or a path is not.
starts_with_replacement() {
  local rest="${1#"${1%%[![:space:]]*}"}" q body word
  [ -n "$rest" ] || return 1
  q="${rest:0:1}"
  if [ "$q" = "'" ] || [ "$q" = '"' ]; then
    body="${rest:1}"
    body="${body%%"$q"*}"
    [ -z "$body" ] && return 0
    [[ "$body" == *"$MARK"* ]] && return 0
    return 1
  fi
  word="${rest%%[[:space:]]*}"
  [[ "$word" == *'$'* ]] && return 0
  return 1
}

scan=${scan//\$\(/$'\n'}                                      # a substitution starts a new command
scan=${scan//\`/$'\n'}
footgun=0
while IFS= read -r seg; do
  s="${seg#"${seg%%[![:space:]]*}"}"                          # ltrim
  # rg is still rg inside `( … )`, `{ …; }` or after VAR=value prefixes.
  while [[ "$s" =~ ^(\(|\{[[:space:]]|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)(.*)$ ]]; do
    s="${BASH_REMATCH[2]}"
    s="${s#"${s%%[![:space:]]*}"}"
  done
  # Strip a leading runner/wrapper chain (xargs/time/env/…) AND its option
  # tokens, so we land on the real rg command and inspect only rg's OWN args.
  # This catches `xargs -I{} rg -r …` (a flag between xargs and rg) and avoids
  # mis-reading a wrapper's own -r (e.g. `xargs -r rg foo` = no-run-if-empty).
  while [[ "$s" =~ ^(xargs|time|env|sudo|nice|nohup|command|stdbuf|parallel)[[:space:]]+(.*)$ ]]; do
    s="${BASH_REMATCH[2]}"
    [[ "$s" =~ ^rg([[:space:]]|$) ]] && break                 # next word IS rg → stop
    [[ "$s" =~ ^[^[:space:]]+[[:space:]]+(.*)$ ]] && s="${BASH_REMATCH[1]}" || break
  done
  [[ "$s" =~ ^rg[[:space:]] ]] || continue                    # this segment isn't an rg command
  rgargs="${s#rg}"                                            # only the args that belong to rg
  [[ "$rgargs" =~ (--replace)([[:space:]=]|$) ]] && continue  # explicit intent → allow
  # Two shapes are the mistake. A bundle where r is followed by more letters
  # (-rn, -ri, -rl): r takes the rest of the bundle as its replacement, so the
  # letters never act as flags. And an r that ends a token (-r, -nr) whose next
  # word is not a replacement: that is "recursive" muscle memory, and rg then eats
  # the pattern. `-r '$1'`, `-r ''` and `-nor '$0'` are real replacements and pass.
  # The leading separator class forbids a double dash, so `--replace` never matches.
  if [[ "$rgargs" =~ (^|[[:space:]\(])-[A-Za-z]*r[A-Za-z]+([[:space:]=]|$) ]]; then
    footgun=1; break
  fi
  rest="$rgargs"
  while [[ "$rest" =~ (^|[[:space:]\(])-[A-Za-z]*r([[:space:]=]|$) ]]; do
    hit="${BASH_REMATCH[0]}"
    rest="${rest#*"$hit"}"
    [[ "$hit" == *= ]] && continue                            # -r=VALUE is explicit
    if ! starts_with_replacement "$rest"; then footgun=1; break; fi
  done
  [ "$footgun" = 1 ] && break
done < <(printf '%s\n' "$scan" | tr ';|&' '\n')

if [ "$footgun" = 1 ]; then
  reason="⚡ rg -r IS --replace, NOT recursive. In ripgrep, -r consumes the next token as a REPLACEMENT string and prints transformed output: it does NOT mean recursive (rg recurses by default). This silently mangles output that LOOKS plausible (the metadata→mnidata incident).

Blocked command:
  ${command}

Fix:
  • Recursive search is the DEFAULT: just drop -r:   rg \"PATTERN\" path/
  • Need hidden/ignored files too:                    rg --no-ignore --hidden \"PATTERN\" path/
  • You GENUINELY want substitution: spell it out with the long flag so intent is explicit:
                                                       rg \"PATTERN\" --replace \"REPL\" path/

Mute for this session: touch ~/.claude/.no-rg-replace-guard"
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-rg-replace-bundle --action block --heeded unknown >/dev/null 2>&1 || true
  jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
  exit 0
fi

exit 0
