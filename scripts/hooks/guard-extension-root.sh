#!/usr/bin/env bash
# guard-extension-root.sh: keep unpacked browser extensions loadable.
#
# Chrome refuses to load (or reload) an unpacked extension whose root folder
# holds any file or folder whose name starts with "_", apart from its own
# _locales and _metadata. One stray checkpoint (_20261020-bfb.claude.md) broke
# better-file-browser for the owner on 2026-10-20. This blocks any write that
# would put such a name next to a manifest.json that declares manifest_version.
#
# Scope: Write/Edit/NotebookEdit targets, and Bash commands that write through
# the common verbs (touch, cp, mv, ln, tee, install, rsync, redirects). A write
# hidden inside python3 -c "open(...)" is not caught.
#
# Tests: bash ~/.claude/scripts/hooks/guard-extension-root.test.sh

set -uo pipefail

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)
command_str=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] || cwd=$PWD

# True when $1 would be a reserved-name entry directly inside an extension root.
is_offender() {
  local p=$1 dir base
  case "$p" in /*) ;; "~/"*) p="$HOME/${p#\~/}" ;; *) p="$cwd/$p" ;; esac
  p=${p%/}
  base=${p##*/}
  dir=${p%/*}
  case "$base" in _locales|_metadata) return 1 ;; _*) ;; *) return 1 ;; esac
  [ -f "$dir/manifest.json" ] || return 1
  grep -q '"manifest_version"' "$dir/manifest.json" 2>/dev/null
}

offender=""
if [ -n "$file_path" ] && is_offender "$file_path"; then
  offender=$file_path
fi

if [ -z "$offender" ] && [ -n "$command_str" ]; then
  writes='(^|[;&|(]|&&|\|\|)[[:space:]]*(sudo[[:space:]]+)?(mkdir|touch|cp|mv|tee|install|ln|rsync)([[:space:]]|$)|>'
  if printf '%s' "$command_str" | grep -qE "$writes"; then
    words=$(printf '%s' "$command_str" | tr -d "\"'" | tr ';&|()' '     ')
    # mv, cp, ln, install and rsync write only their last word, so moving a
    # stray file OUT of the root stays allowed. Anything else (touch, mkdir,
    # tee, a redirect) may write any word.
    case "$words" in
      mv\ *|cp\ *|ln\ *|install\ *|rsync\ *|sudo\ *) candidates=${words##* } ;;
      *) candidates=$(printf '%s' "$words" | tr '>' ' ') ;;
    esac
    for tok in $candidates; do
      case "$tok" in -*) continue ;; esac
      if is_offender "$tok"; then offender=$tok; break; fi
    done
  fi
fi

[ -n "$offender" ] || exit 0

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-extension-root --action block --heeded unknown >/dev/null 2>&1 || true
cat >&2 <<EOF
BLOCKED: this would put a "_" file in a browser extension's root folder:
  $offender

Chrome will not load or reload an unpacked extension while its root holds a
name starting with "_" (only _locales and _metadata are allowed), so the
owner's extension stops working.

Write it under the project's .claude/ folder instead, for example
  ${offender%/*}/.claude/${offender##*/}
EOF
exit 2
