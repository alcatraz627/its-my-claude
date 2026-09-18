#!/usr/bin/env bash
# guard-cd-relative-path.sh — PreToolUse[Bash], SYNCHRONOUS.
#
# Blocks a relative path that follows a `cd` in the SAME command, because the
# harness cannot statically resolve it and therefore asks the human. The dialog
# halts the lane until the owner walks over. Owner, 2026-09-04, verbatim: "THE
# ISSUE ISNT THHAT I ANSWER YES OR NO THE FUCKING ISSUE IS THAT IT FUCKING
# STALLS YOU".
#
# WHY THIS SHAPE AND NOT "ANY CHAIN". Two mechanisms were on record and a hook
# built against the wrong one catches the wrong thing. rules/shell.md says every
# segment of a compound must match an allow entry, so one unlisted segment
# prompts about the whole chain. The harness message forge-brains captured on
# 2026-09-04 (msg-33af190e195248fd) was narrower: rg on a relative path AFTER a
# cd cannot be statically resolved, so it cannot be checked against the deny
# rules. Both are real, and they overlap, which is why the 2026-09-03 sample was
# 93% chain-carrying while the harness quoted the path reason. This guard takes
# the INTERSECTION, which is the shape present in every reported instance:
#
#     cd /Users/…/speedway && rg -n '…' app/
#
# A relative path with no cd is left alone: the Bash tool's cwd persists between
# calls, so the harness can resolve it and no dialog fires. Matching every chain
# would be a far larger net for no extra catch, and a false block stalls the lane
# exactly like the dialog does.
#
# BLOCKING, NOT NUDGING, and the asymmetry is the whole argument. A nudge lets
# the command through and the dialog still halts the lane until a human arrives.
# A block returns in milliseconds carrying the rewritten absolute command, so the
# agent retries inside the same turn. Both outcomes interrupt; only one waits on
# a person.
#
# Mute: touch ~/.claude/.no-cd-relpath-guard   (machine-wide until removed)
set -uo pipefail
[ -f "$HOME/.claude/.no-cd-relpath-guard" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
[ "$tool_name" = "Bash" ] || exit 0
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$command" ] || exit 0

# Reduce to what the shell would execute. Heredoc bodies and quoted strings hold
# prose, so a path mentioned inside `--reason "see app/foo.ts"` is not a path the
# shell resolves. strip-payloads.py is the shared sanitiser (lifted from gcp's
# cmd-scan.py); if it is missing the guard opens rather than blocking blind.
STRIP="$HOME/.claude/scripts/hooks/strip-payloads.py"
if [ -x "$STRIP" ]; then
  scan=$(printf '%s' "$command" | "$STRIP" 2>/dev/null) || scan="$command"
  [ -n "$scan" ] || scan="$command"
else
  scan="$command"
fi

# A cd must appear at a COMMAND POSITION, so `--flag cd` or a word ending in cd
# does not arm the guard.
[[ "$scan" =~ (^|[\;\&\|][[:space:]]*|^[[:space:]]*)cd([[:space:]]|$) ]] || exit 0

# The cd target, for the rewrite offered below. First cd wins; a command with two
# cds gets the guard's generic advice instead of a wrong absolute path.
cd_target=""
cd_count=0
while IFS= read -r seg; do
  s="${seg#"${seg%%[![:space:]]*}"}"
  [[ "$s" =~ ^cd([[:space:]]+(.*))?$ ]] || continue
  cd_count=$((cd_count + 1))
  [ "$cd_count" = 1 ] && cd_target="${BASH_REMATCH[2]}"
done < <(printf '%s\n' "$scan" | tr ';|&' '\n')
cd_target="${cd_target%"${cd_target##*[![:space:]]}"}"
[ "$cd_count" -gt 1 ] && cd_target=""

# Commands whose arguments are paths the harness wants to resolve. A relative
# path handed to one of these after a cd is the reported shape.
PATHY='rg|grep|cat|sed|awk|head|tail|wc|ls|find|fd|diff|stat|file|du|jq|python3|python|node|bun|bash|sh|cp|mv|touch|chmod|open|code'

offender=""
while IFS= read -r seg; do
  s="${seg#"${seg%%[![:space:]]*}"}"
  [[ "$s" =~ ^($PATHY)([[:space:]]+(.*))?$ ]] || continue
  args="${BASH_REMATCH[3]}"
  for a in $args; do
    case "$a" in
      -*) continue ;;                 # a flag, not a path
      /*|'~'/*|'~'|\$*) continue ;;   # already absolute, or a variable we cannot judge
      '""'|"''") continue ;;          # a blanked quoted span: prose, not a path
    esac
    # Require a slash. A bare word is far more likely an rg PATTERN or a
    # subcommand than a path, and guessing wrong here costs a stalled lane.
    case "$a" in
      */*) offender="$a"; break ;;
    esac
  done
  [ -n "$offender" ] && break
done < <(printf '%s\n' "$scan" | tr ';|&' '\n')

[ -n "$offender" ] || exit 0

if [ -n "$cd_target" ]; then
  clean="${offender#./}"
  suggestion="  ${cd_target%/}/${clean}"
else
  suggestion="  <the absolute path this resolves to>"
fi

reason="⛔ A relative path after a cd cannot be statically resolved, so the harness asks the OWNER and your lane halts until they arrive.

Blocked command:
  ${command}

The unresolvable argument:
  ${offender}

Write it absolute and drop the cd. The Bash tool's working directory persists
between calls, so the cd was never needed:
${suggestion}

One command per Bash call. Ask the tool for less output instead of piping:
rg -m 5, sed -n '1,40p', git log -5. Full rule: rules/shell.md

Mute: touch ~/.claude/.no-cd-relpath-guard"

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-cd-relative-path --action block --heeded unknown >/dev/null 2>&1 || true
jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
exit 0
