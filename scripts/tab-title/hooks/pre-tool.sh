#!/usr/bin/env bash
# tab-title/hooks/pre-tool.sh — PreToolUse hook (async).
# Sets a TRANSIENT_FOCUS that shows what tool is running so a tab parked while
# something long is in flight self-documents. Cleared by post-tool.sh on return.
# Manual focus set via set-focus.sh is preserved underneath (transient wins
# only while a tool is in-flight; restored automatically when depth hits 0).

set -uo pipefail
command -v jq &>/dev/null || exit 0
source "${HOME}/.claude/scripts/tab-title/lib.sh"

input=$(cat)
sid=$(echo "$input" | jq -r '.session_id // empty')
tool=$(echo "$input" | jq -r '.tool_name // empty')
[[ -n "$sid" && -n "$tool" ]] || exit 0

# Stash permission_mode for the perm decorator (best-effort).
mode=$(echo "$input" | jq -r '.permission_mode // empty')
[[ -n "$mode" ]] && printf '%s' "$mode" > "/tmp/claude-tab-perm-${sid}"

# Build a short label for the focus line.
case "$tool" in
  Bash)
    desc=$(echo "$input" | jq -r '.tool_input.description // empty')
    label="${desc:-bash}"
    label="${label:0:30}"
    label="bash: $label"
    ;;
  Agent)
    sub=$(echo "$input" | jq -r '.tool_input.subagent_type // .tool_input.description // "agent"')
    label="agent: ${sub:0:24}"
    ;;
  Task*) label=$(printf '%s' "$tool" | tr '[:upper:]' '[:lower:]') ;;
  *)     label="$tool" ;;
esac

tab_load_state "$sid" || exit 0
TRANSIENT_FOCUS="$label"
TRANSIENT_DEPTH=$(( ${TRANSIENT_DEPTH:-0} + 1 ))

# Auto-derive MODE from the tool + its inputs. Manual `tab-title.sh mode <x>`
# is set sticky until the next auto-derivation, so explicit overrides last
# only until the next tool call (per intended UX — auto-mode tracks reality).
auto_mode=""
case "$tool" in
  Read)               auto_mode="read" ;;
  Write|Edit)         auto_mode="edit" ;;
  Glob|Grep)          auto_mode="search" ;;
  Agent)              auto_mode="think" ;;
  TodoWrite)          auto_mode="target" ;;
  Bash)
    cmd=$(echo "$input" | jq -r '.tool_input.command // empty')
    case "$cmd" in
      *"npm test"*|*"pytest"*|*"go test"*|*"cargo test"*|*"vitest"*|*"jest"*)
                                                  auto_mode="test" ;;
      *"npm run build"*|*"npm run dev"*|*"make"*|*"cargo build"*|*"go build"*|*"tsc"*|*"webpack"*|*"vite build"*)
                                                  auto_mode="build" ;;
      *"git commit"*|*"git push"*|*"git tag"*)    auto_mode="save" ;;
      *"git pull"*|*"git fetch"*|*"git merge"*|*"git rebase"*)
                                                  auto_mode="sync" ;;
      *"curl "*|*"wget "*|*"ssh "*|*"http "*|*"httpie"*)
                                                  auto_mode="network" ;;
      *"rg "*|*"grep "*|*"find "*|*"fd "*|*"locate "*)
                                                  auto_mode="search" ;;
      *"docker "*|*"kubectl "*|*"helm "*)         auto_mode="deploy" ;;
      *"npm install"*|*"pip install"*|*"cargo add"*|*"go get"*)
                                                  auto_mode="package" ;;
      *"trash"*|*"rm "*|*"clean"*)                auto_mode="clean" ;;
      # No match: leave MODE unchanged.
    esac
    ;;
esac
[[ -n "$auto_mode" ]] && MODE="$auto_mode"

tab_save_state "$sid"
# No tab_emit here: PreToolUse hooks run under a stdio arrangement where
# /dev/tty does NOT reach the visible terminal in this Claude Code build.
# Writes silently no-op. State still updates so `get` reflects truth and
# the next Stop hook firing renders the latest compose.
