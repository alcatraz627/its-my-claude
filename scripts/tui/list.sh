#!/usr/bin/env bash
# list.sh — show what std::claude::tui provides, scanned live from the modules.
#
# It reads the `# tui_name … — description` doc-header above each public function
# (and each module's own header), so the catalog can't drift from the code the way
# a hand-written list does. Run it whenever you're about to build/touch a TUI:
#
#     bash ~/.claude/scripts/tui/list.sh
#
# This is the "what's available?" answer the handbook (§9) narrates in prose.
set -o pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/colors.sh" 2>/dev/null && tui_colors_init 2>/dev/null || true

printf '%sstd::claude::tui%s — reusable terminal-UI primitives  %s(source the module, call the fn)%s\n' \
  "${B:-}" "${R:-}" "${D:-}" "${R:-}"
printf '%sall input fns degrade fzf → gum → read and never hang headless%s\n\n' "${D:-}" "${R:-}"

for f in "$DIR"/*.sh; do
  base="$(basename "$f")"
  [ "$base" = "list.sh" ] && continue
  # public-function doc headers: lines beginning "# tui_<name>"
  hdrs="$(grep -E '^# tui_[a-z_]+' "$f" 2>/dev/null || true)"
  # file-preview is exec'd, not sourced — surface its contract from its usage line
  if [ -z "$hdrs" ] && [ "$base" = "file-preview.sh" ]; then
    hdrs="# file-preview.sh <path> — rich bounded preview (jq/bat/xlsx-sheets → head), always exits 0"
  fi
  [ -n "$hdrs" ] || continue
  printf '%s%s%s\n' "${C:-}" "$base" "${R:-}"
  printf '%s\n' "$hdrs" | sed 's/^# /  /'
  printf '\n'
done

printf '%sfull guide:%s ~/.claude/conventions/tui-handbook.md\n' "${D:-}" "${R:-}"
