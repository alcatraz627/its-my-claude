#!/usr/bin/env bash
# guard-duplicate-symbol.sh — PreToolUse[Write|Edit|MultiEdit], SYNCHRONOUS.
#
# The mechanical `infra-before-grep` / reinvent-the-wheel killer. When an edit
# introduces an exported function (JS/TS) or a module-level def/class (Python)
# whose name ALREADY has a definition elsewhere in the project tree, it blocks
# with the existing file:line — so the duplicate is never written.
#
# Deliberately conservative to avoid false positives:
#   - exported functions only (component-internal handlers aren't exported);
#   - skips const/type/interface (per-component `Props`, Next.js `export const
#     metadata`, etc. legitimately recur);
#   - stoplists generic names; requires name length >= 5.
# Mute: touch ~/.claude/.no-dup-symbol-guard

set -uo pipefail
[ -f "$HOME/.claude/.no-dup-symbol-guard" ] && exit 0
command -v rg >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null || true)
[ -z "$INPUT" ] && exit 0

file_path=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$file_path" ] && exit 0

# Resolve a relative path against the hook's CWD; bail if still not absolute.
case "$file_path" in /*) : ;; *) file_path="$PWD/$file_path" ;; esac

lang=""
case "$file_path" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) lang=js ;;
  *.py) lang=py ;;
  *) exit 0 ;;
esac

payload=$(printf '%s' "$INPUT" | jq -r '
  .tool_input.content
  // .tool_input.new_string
  // ((.tool_input.edits // []) | map(.new_string // "") | join("\n"))
  // empty' 2>/dev/null)
[ -z "$payload" ] && exit 0

# Find the project root: nearest ancestor with a project marker.
root=""; d=$(dirname "$file_path")
while [ "$d" != "/" ] && [ -n "$d" ]; do
  if [ -e "$d/package.json" ] || [ -d "$d/.git" ] || [ -f "$d/pyproject.toml" ] || [ -f "$d/go.mod" ]; then
    root="$d"; break
  fi
  d=$(dirname "$d")
done
[ -z "$root" ] && exit 0   # no project context → don't guess, don't block

# Generic names that legitimately recur across files.
is_generic() {
  case "$1" in
    run|main|setup|init|start|stop|handler|handle|default|index|render|create|update|build|parse|format|toString|valueOf) return 0 ;;
    *) return 1 ;;
  esac
}

# Extract newly-introduced symbol names by language.
if [ "$lang" = js ]; then
  names=$(printf '%s' "$payload" | rg -o --no-line-number 'export\s+(?:async\s+)?function\s+([A-Za-z_$][A-Za-z0-9_$]*)' -r '$1' 2>/dev/null | sort -u)
else
  names=$(printf '%s' "$payload" | rg -o --no-line-number '^(?:async\s+)?(?:def|class)\s+([A-Za-z_][A-Za-z0-9_]*)' -r '$1' 2>/dev/null | sort -u)
fi
[ -z "$names" ] && exit 0

# Globs to scope the existence search to the relevant language.
if [ "$lang" = js ]; then globs=(-g '*.ts' -g '*.tsx' -g '*.js' -g '*.jsx' -g '*.mjs' -g '*.cjs')
else globs=(-g '*.py'); fi

hits=""
while IFS= read -r name; do
  [ -z "$name" ] && continue
  [ "${#name}" -lt 5 ] && continue
  is_generic "$name" && continue
  case "$name" in *'$'*) continue ;; esac   # `$` would mis-anchor the rg regex below
  if [ "$lang" = js ]; then
    def_re="(export\s+)?(async\s+)?function\s+${name}\b|(export\s+)?(const|class)\s+${name}\b"
  else
    def_re="^\s*(async\s+)?(def|class)\s+${name}\b"
  fi
  # Existing definitions anywhere in the tree EXCEPT the file being edited.
  # Exclude the file being edited by EXACT path prefix (awk, not regex) — a path
  # with regex-meta chars like ( | [ would make an `rg -v "^path:"` anchor miss
  # and the file would flag itself as its own duplicate.
  found=$(rg -n --no-heading "${globs[@]}" "$def_re" "$root" 2>/dev/null | awk -v p="${file_path}:" 'substr($0,1,length(p)) != p' | head -3)
  [ -n "$found" ] && hits="${hits}▸ ${name} already defined:
$(printf '%s' "$found" | sed 's/^/    /')
"
done <<< "$names"

[ -z "$hits" ] && exit 0

reason="⚠ DUPLICATE SYMBOL — this edit to ${file_path} introduces a name that already exists in the project. Reuse or extend the existing one instead of reinventing it:
${hits}
If this is a genuinely distinct symbol (or a deliberate re-export), rename it or mute: touch ~/.claude/.no-dup-symbol-guard"
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-duplicate-symbol --heeded unknown >/dev/null 2>&1 &
jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
exit 0
