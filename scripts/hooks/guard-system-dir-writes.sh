#!/usr/bin/env bash
# guard-system-dir-writes.sh — PreToolUse(Bash): block DESTRUCTIVE WRITES to
# system directories while allowing reads, arguments, and user-writable paths.
#
# Replaces 13 over-broad permissions.deny substring rules (Bash(* /etc*) etc.)
# that denied ANY command merely naming a system path — reads, flag values,
# even an echo comment. This matches only write FORMS (redirect / tee / dd /
# rm / chmod|chown -R) aimed at a protected root, so `cat /etc/hosts` and
# `foo --tty /dev/ttys010` pass, while `echo x > /etc/hosts` is blocked.
#
# Protected roots: classic system dirs that should never take an agent write.
# Deliberately NOT protected (legit writes happen there): /usr/local, /tmp,
# /private, /Volumes, /dev, and anything under $HOME. macOS SIP already blocks
# writes to /System, /bin, /usr/bin regardless — this is the human-error net.
#
# Override (rare): touch ~/.claude/.allow-system-writes

set -uo pipefail
[ -f "$HOME/.claude/.allow-system-writes" ] && exit 0

input=$(cat 2>/dev/null)
[ "$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)" = "Bash" ] || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$cmd" ] || exit 0

# Match against a de-quoted copy: a real redirect/rm target lives OUTSIDE quotes
# (`> /etc/hosts`), whereas a path named inside a string literal (a commit
# message, an echo, a comment) is data, not a write. Stripping single/double
# quoted spans first prevents false positives like `git commit -m "...tee /etc..."`.
scan=$(printf '%s' "$cmd" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g")

# Protected system roots (regex alternation). Each followed by / or word-end so
# "/etcetera" or "/booth" do NOT match — only the real dir.
ROOTS='etc|System|Library|bin|sbin|boot|root|sys|proc'
END='(/|[[:space:]]|$)'

block() {
  jq -cn --arg r "🛑 SYSTEM-DIR WRITE GUARD — refusing a destructive write to a system directory.

$1

Reads and arguments that name system paths are fine; this blocks ONLY writes
(> >> tee dd rm chmod/chown -R) to protected roots (/etc /System /Library /bin
/sbin /boot /root /sys /proc). If you truly intend this, run it yourself, or:
touch ~/.claude/.allow-system-writes" \
    '{decision:"block", reason:$r}' 2>/dev/null || true
  exit 0
}

# 1. redirect (>, >>, 2>, &>) into a protected root — zero-or-more spaces after op
printf '%s' "$scan" | rg -q ">>?[[:space:]]*/($ROOTS)$END" \
  && block "redirect into a system dir: $cmd"
# 2. tee (any flags) writing a protected root
printf '%s' "$scan" | rg -q "\btee\b[^|;&]*[[:space:]]/($ROOTS)$END" \
  && block "tee into a system dir: $cmd"
# 3. dd of= a protected root
printf '%s' "$scan" | rg -q "\bdd\b[^|;&]*of=/($ROOTS)$END" \
  && block "dd writing a system dir: $cmd"
# 4. rm targeting a protected root
printf '%s' "$scan" | rg -q "\brm\b[^|;&]*[[:space:]]/($ROOTS)$END" \
  && block "rm of a system path: $cmd"
# 5. recursive chmod/chown on a protected root
printf '%s' "$scan" | rg -q "\b(chmod|chown)\b[^|;&]*-R[^|;&]*[[:space:]]/($ROOTS)$END" \
  && block "recursive perm change on a system dir: $cmd"

exit 0
