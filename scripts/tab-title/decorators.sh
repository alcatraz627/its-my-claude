#!/usr/bin/env bash
# tab-title/decorators.sh — Icon decorators applied to the tab title.
#
# ░ HOW TO EXTEND ░
# 1. Pick a short name (lowercase, no spaces): e.g. `docker`, `tmux`, `gitdirty`.
# 2. Define a function `dec_<name>` that prints a single glyph if the
#    condition matches, or prints nothing otherwise.
# 3. Add the name to the TAB_DECORATORS array below. Order = display order.
#
# Glyphs: Nerd Font glyphs (PUA, e.g. ) render in Ghostty when the
# configured font is a Nerd Font. Emoji also work and don't require a NF.
# Test glyphs with `printf '\n'` before adding.
#
# Decorators run on every Stop hook. Keep them cheap (no network, no `find`).

# ── Active decorator list (edit to enable/reorder) ───────────────────────────
TAB_DECORATORS=(ssh perm agents cost)

# ── ssh: present when the session is over SSH ────────────────────────────────
# Glyph is configurable via:  tab-title.sh glyph ssh <name-or-emoji>
# See `tab-title.sh glyph ssh --options` for named choices.
dec_ssh() {
  [[ -n "${SSH_CONNECTION:-}${SSH_TTY:-}" ]] && printf '%s' "${GLYPH_SSH:-🌐}"
}

# ── perm: warn glyph for relaxed permission modes ────────────────────────────
# Stop hook + pre-tool hook both stash $permission_mode to /tmp/claude-tab-perm-<sid>.
# Shows 🔓 for bypassPermissions / acceptEdits. (Default / plan = no glyph.)
dec_perm() {
  local sid="${TAB_SESSION_ID:-}" path mode
  [[ -n "$sid" ]] || return 0
  path="/tmp/claude-tab-perm-${sid}"
  [[ -f "$path" ]] || return 0
  mode=$(cat "$path" 2>/dev/null || true)
  case "$mode" in
    bypassPermissions|acceptEdits) printf '%s' "${GLYPH_PERM:-🆓}" ;;
  esac
}
# Glyph is configurable via:  tab-title.sh glyph perm <name-or-emoji>
# See `tab-title.sh glyph perm --options` for named choices.

# ── agents: count of in-flight sub-agents in the last 5 minutes ──────────────
# Reads WAL events (agent_start - agent_done) from project WAL first, then
# global. Cheap: only inspects the last 200 lines.
dec_agents() {
  local sid="${TAB_SESSION_ID:-}" wal n
  [[ -n "$sid" ]] || return 0
  local cwd="${TAB_CWD:-$PWD}"
  local cutoff
  cutoff=$(( $(date +%s) - 300 ))
  n=0
  for wal in "${cwd}/.claude/wal.jsonl" "${HOME}/.claude/wal.jsonl"; do
    [[ -f "$wal" ]] || continue
    n=$(( n + $(
      tail -n 200 "$wal" 2>/dev/null \
      | jq -r --arg sid "$sid" --argjson cutoff "$cutoff" '
          select(.session_id == $sid)
          | select((.ts // 0) >= $cutoff)
          | select(.kind == "agent_start" or .kind == "agent_done")
          | if .kind == "agent_start" then 1 else -1 end
        ' 2>/dev/null \
      | awk '{s+=$1} END {print s+0}'
    ) ))
  done
  (( n > 0 )) && printf '⚙×%d' "$n"
}

# ── cost: spend tier indicator (SCAFFOLD — no integration wired yet) ─────────
# Reads /tmp/claude-spend-today (a single number in USD). Emits $/$$/$$$ above
# thresholds. Wire a producer by appending to that file from a UserPromptSubmit
# or Stop hook that has access to usage info (see ~/.claude/scripts/cost-alert.sh
# for an existing cost source). Returns nothing if file absent or unreadable —
# safe to leave enabled.
dec_cost() {
  local f="${CLAUDE_TAB_SPEND_FILE:-/tmp/claude-spend-today}"
  [[ -r "$f" ]] || return 0
  local spend
  spend=$(cat "$f" 2>/dev/null | tr -dc '0-9.' || true)
  [[ -n "$spend" ]] || return 0
  # awk handles float compare portably (bash can't)
  awk -v s="$spend" 'BEGIN {
    if (s+0 >= 20) print "$$$";
    else if (s+0 >= 5) print "$$";
    else if (s+0 >= 1) print "$";
  }'
}

# ── EXAMPLES (uncomment + add name to TAB_DECORATORS) ────────────────────────

# dec_docker() {
#   [[ -f /.dockerenv ]] && printf ''
# }
#
# dec_tmux() {
#   [[ -n "${TMUX:-}" ]] && printf ''
# }
#
# dec_root() {
#   [[ "$EUID" -eq 0 ]] && printf '#'
# }
#
# dec_gitdirty() {
#   # Cheap-ish: only checks porcelain, no fetch.
#   local cwd="${CLAUDE_CWD:-$PWD}"
#   git -C "$cwd" -c core.useBuiltinFSMonitor=false status --porcelain 2>/dev/null \
#     | grep -q . && printf '±'
# }
