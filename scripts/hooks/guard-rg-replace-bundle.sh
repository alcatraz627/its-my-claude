#!/usr/bin/env bash
# guard-rg-replace-bundle.sh — PreToolUse[Bash], SYNCHRONOUS.
#
# Blocks the `rg -r` footgun. In ripgrep, `-r`/`--replace` is the REPLACEMENT
# flag — it consumes the next token as a replacement string and prints mangled,
# transformed output. It is NOT "recursive" (rg is recursive by default). Coming
# from grep, `-r` is muscle-memory for recursive, so `rg -r pattern path` or a
# bundle like `-rn` silently corrupts output — and the output looks plausible,
# so it poisons whatever consumes it (the `metadata`→`mnidata` incident,
# atone mist-20260612-110132-40 / prop-20260612-110331-da).
#
# Precise + low-false-positive: blocks the SHORT `-r` flag (standalone or bundled
# like -rn/-ri/-rl), but ALLOWS the long `--replace` form — so a genuine,
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
# rg invocation. (A pattern containing a literal `|` may split mid-quote, at most
# causing an under-fire — the safe direction.)
footgun=0
while IFS= read -r seg; do
  s="${seg#"${seg%%[![:space:]]*}"}"                          # ltrim
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
  # SHORT flag token containing 'r' (single dash: -r, -rn, -ri, -nr, -rl). The
  # leading separator class forbids a double dash, so `--replace` never matches.
  if [[ "$rgargs" =~ (^|[[:space:]\(])-[A-Za-z]*r[A-Za-z]*([[:space:]=]|$) ]]; then
    footgun=1; break
  fi
done < <(printf '%s\n' "$command" | tr ';|&' '\n')

if [ "$footgun" = 1 ]; then
  reason="⚡ rg -r IS --replace, NOT recursive. In ripgrep, -r consumes the next token as a REPLACEMENT string and prints transformed output — it does NOT mean recursive (rg recurses by default). This silently mangles output that LOOKS plausible (the metadata→mnidata incident).

Blocked command:
  ${command}

Fix:
  • Recursive search is the DEFAULT — just drop -r:   rg \"PATTERN\" path/
  • Need hidden/ignored files too:                    rg --no-ignore --hidden \"PATTERN\" path/
  • You GENUINELY want substitution: spell it out with the long flag so intent is explicit:
                                                       rg \"PATTERN\" --replace \"REPL\" path/

Mute for this session: touch ~/.claude/.no-rg-replace-guard"
  jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
  exit 0
fi

exit 0
