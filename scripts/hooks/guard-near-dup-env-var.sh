#!/usr/bin/env bash
# guard-near-dup-env-var.sh — PreToolUse[Edit|Write|MultiEdit], SYNCHRONOUS.
#
# Catches a new environment-variable name that is a NEAR-DUPLICATE of one the
# project already defines — the RENDER_API_KEY-added-when-RENDER_API_TOKEN-exists
# slip (an infra-before-grep event). Near-duplicate env names cause silent config
# drift: two names for one secret, one of which is never populated.
#
# When the added content introduces an env var name (process.env.X,
# import.meta.env.X, os.getenv('X'), os.environ['X'], a .env line X=, or
# Deno.env.get('X')), it extracts X and greps the project (excluding
# node_modules/dist/.next/build/out/.git) for an existing DIFFERENT name that is
# a near-match of X: same base with a trailing-word swap among the synonym set
# {KEY, TOKEN, SECRET, PASSWORD, PASS, PWD, ID, URL, URI}, or the same words
# reordered. If a near-match exists AND X is not itself already defined → nudge.
#
# NUDGE, never a block — a genuinely-new var is legitimate and must not be
# hard-blocked. additionalContext reaches the agent (the only non-blocking
# channel any audience reads; the trailing directive relays it to the user).
#
# Mute: touch ~/.claude/.no-near-dup-env-gate

set -uo pipefail
[ -f "$HOME/.claude/.no-near-dup-env-gate" ] && exit 0
command -v rg >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v awk >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null || true)
[ -z "$INPUT" ] && exit 0
printf '%s' "$INPUT" | jq empty 2>/dev/null || exit 0

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
case "$TOOL" in Edit | Write | MultiEdit) ;; *) exit 0 ;; esac

file_path=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$file_path" ] && exit 0
case "$file_path" in /*) : ;; *) file_path="$PWD/$file_path" ;; esac

# File character decides which extractor to run against the added content.
kind=""
case "$file_path" in
  *.env | .env | *.env.* | */.env | */.env.*) kind=env ;;
  *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs | *.py | *.rb | *.go | *.rs) kind=code ;;
  *) exit 0 ;;
esac

payload=$(printf '%s' "$INPUT" | jq -r '
  .tool_input.content
  // .tool_input.new_string
  // ((.tool_input.edits // []) | map(.new_string // "") | join("\n"))
  // empty' 2>/dev/null)
[ -z "$payload" ] && exit 0

# Project root: nearest ancestor with a project marker. No root → don't guess.
root=""; d=$(dirname "$file_path")
while [ "$d" != "/" ] && [ -n "$d" ]; do
  if [ -e "$d/package.json" ] || [ -d "$d/.git" ] || [ -f "$d/pyproject.toml" ] || [ -f "$d/go.mod" ] || [ -d "$d/.claude" ]; then
    root="$d"; break
  fi
  d=$(dirname "$d")
done
[ -z "$root" ] && exit 0

# Env-var-name accessor patterns (single capture group each; NAME is UPPER_SNAKE).
P_DOT='(?:process\.env\.|import\.meta\.env\.)([A-Z][A-Z0-9_]*)'
P_BRK="(?:process\.env\[|Deno\.env\.get\(|os\.getenv\(|os\.environ\.get\(|os\.environ\[)\s*['\"]([A-Z][A-Z0-9_]*)"
P_ENV='^\s*(?:export\s+)?([A-Z][A-Z0-9_]*)='

# 1) Names newly introduced by THIS edit (from the added content only).
if [ "$kind" = env ]; then
  new_names=$(printf '%s' "$payload" | rg -o --no-line-number --replace '$1' "$P_ENV" 2>/dev/null | sort -u)
else
  new_names=$(printf '%s' "$payload" | rg -o --no-line-number --replace '$1' "$P_DOT" 2>/dev/null
              printf '%s' "$payload" | rg -o --no-line-number --replace '$1' "$P_BRK" 2>/dev/null)
  new_names=$(printf '%s\n' "$new_names" | sort -u)
fi
new_names=$(printf '%s\n' "$new_names" | sed '/^$/d')
[ -z "$new_names" ] && exit 0

# 2) All env var names already present in the project tree, WITH file:line, so a
#    near-match can point at where the sibling lives. Excludes build output; uses
#    --no-ignore --hidden so gitignored .env files are seen.
EXC=(-g '!**/node_modules/**' -g '!**/dist/**' -g '!**/.next/**' -g '!**/build/**' -g '!**/out/**' -g '!**/.git/**' -g '!**/vendor/**')
existing=$(
  rg -n -o --replace '$1' --no-ignore --hidden --no-messages "${EXC[@]}" "$P_DOT" "$root" 2>/dev/null
  rg -n -o --replace '$1' --no-ignore --hidden --no-messages "${EXC[@]}" "$P_BRK" "$root" 2>/dev/null
  rg -n -o --replace '$1' --no-ignore --hidden --no-messages "${EXC[@]}" -g '.env' -g '.env.*' -g '*.env' "$P_ENV" "$root" 2>/dev/null
)
[ -z "$existing" ] && exit 0

# Bare set of existing names (for the "X already defined" membership test).
existing_names=$(printf '%s\n' "$existing" | awk -F: 'NF{print $NF}' | sort -u)

SYN=" KEY TOKEN SECRET PASSWORD PASS PWD ID URL URI "

hits=""
while IFS= read -r X; do
  [ -z "$X" ] && continue
  [ "${#X}" -lt 5 ] && continue
  case "$X" in *_*) ;; *) continue ;; esac   # need >=2 tokens for any near-match

  # X already defined somewhere in the project → this is a normal reference, not
  # a newly-introduced name. Stay silent.
  printf '%s\n' "$existing_names" | rg -qxF "$X" 2>/dev/null && continue

  match=$(printf '%s\n' "$existing" | awk -F: -v X="$X" -v SYN="$SYN" '
    function insyn(t){ return index(SYN, " " t " ") > 0 }
    function sortsig(name,   a,n,i,j,t,o){ n=split(name,a,"_")
      for(i=1;i<=n;i++) for(j=i+1;j<=n;j++) if(a[j]<a[i]){t=a[i];a[i]=a[j];a[j]=t}
      o=""; for(i=1;i<=n;i++) o=o "|" a[i]; return o }
    function pref(name,   a,n,i,o){ n=split(name,a,"_"); if(n<2) return "\001"
      o=""; for(i=1;i<n;i++) o=o "_" a[i]; return o }
    function last(name,   a,n){ n=split(name,a,"_"); return a[n] }
    function ntok(name,   a){ return split(name,a,"_") }
    BEGIN{ xsig=sortsig(X); xpre=pref(X); xlast=last(X); xn=ntok(X) }
    {
      name=$NF
      loc=$0; sub(/:[^:]*$/,"",loc)
      if(name=="" || name==X) next
      if(seen[name]++) next
      if(xn>=2 && sortsig(name)==xsig){ print name "\t" loc "\t" "reordered"; exit }
      if(xn>=2 && ntok(name)>=2 && pref(name)==xpre && insyn(xlast) && insyn(last(name)) && last(name)!=xlast){
        print name "\t" loc "\t" "suffix-swap"; exit }
    }')

  [ -z "$match" ] && continue
  near=$(printf '%s' "$match" | cut -f1)
  loc=$(printf '%s' "$match" | cut -f2)
  loc="${loc#"$root"/}"
  hits="${hits}▸ referenced \`${X}\` but the project already defines \`${near}\` (at ${loc}). Did you mean \`${near}\`?
"
done <<< "$new_names"

[ -z "$hits" ] && exit 0

msg="[near-dup-env] this edit to $(basename "$file_path") introduces an env var name that near-duplicates an existing one:
${hits}Near-duplicate env names (KEY vs TOKEN, reordered words) cause silent config drift — two names for one secret, one never populated. Confirm you want a genuinely new var, or reuse the existing name. (mute: touch ~/.claude/.no-near-dup-env-gate)
→→ SURFACE this to the user in your reply as a bordered callout (rules/surface-hook-nudges-to-user.md)."

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook near-dup-env-var --action nudge --heeded unknown >/dev/null 2>&1 || true
jq -n --arg c "$msg" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $c}}' 2>/dev/null || true
exit 0
