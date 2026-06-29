#!/usr/bin/env bash
# plugs.sh — the session-plug status reader. Answers "what's plugged into my
# session, what's silenced, and what's the current state" by reading existing
# artifacts only (no new telemetry). The static catalog lives in
# features/session-plugs.md; this shows the LIVE picture on demand.
#
# Deliberately out of the hot context: this is run when asked, never injected —
# a catalog of plugs injected every session would be the exact noise it measures.
#
# Usage: plugs.sh            full status
#        plugs.sh --mutes    just the active mute files
# Always exits 0.

set -uo pipefail
GCC="$HOME/.claude"
SETTINGS="$GCC/settings.json"
have_jq=$(command -v jq >/dev/null 2>&1 && echo 1 || echo 0)

hr() { printf '─%.0s' $(seq 1 64); printf '\n'; }

# ── Active mutes ─────────────────────────────────────────────────────────────
# Muted plugs/guards silently linger (a known failure mode) — surface them first.
show_mutes() {
  echo "▸ Active mute files (silenced plugs/guards)"
  local found=0
  for f in "$GCC"/.no-* "$GCC"/.*-off "$GCC"/atone/.no-* "$GCC"/atone/.*-off; do
    [ -e "$f" ] || continue
    found=1
    printf '    %s  (since %s)\n' "${f#$GCC/}" "$(date -r "$f" '+%Y-%m-%d %H:%M' 2>/dev/null || echo '?')"
  done
  [ "$found" = 0 ] && echo "    (none — nothing is silenced)"
}

[ "${1:-}" = "--mutes" ] && { show_mutes; exit 0; }

echo "Session plugs — live status   ($(date '+%Y-%m-%d %H:%M'))"
echo "Full catalog: features/session-plugs.md"
hr

# ── Lifecycle map (what is actually registered right now) ────────────────────
echo "▸ Registered at each lifecycle point (from settings.json)"
if [ "$have_jq" = 1 ] && [ -f "$SETTINGS" ]; then
  for ev in SessionStart UserPromptSubmit PreCompact PostCompact Stop SessionEnd; do
    n=$(jq -r --arg e "$ev" '.hooks[$e] // [] | [.[].hooks[]] | length' "$SETTINGS" 2>/dev/null)
    printf '    %-18s %s hook(s)\n' "$ev" "${n:-0}"
  done
  laneN=$(rg -c '\.sh"' "$GCC/scripts/session-mgmt/sessionstart-inject.sh" 2>/dev/null || echo '?')
  printf '    %-18s %s injectors (via sessionstart-inject.sh)\n' "  └ start lane" "$laneN"
else
  echo "    (jq unavailable — see features/session-plugs.md)"
fi
hr

# ── Live signals (current state the plugs act on) ────────────────────────────
echo "▸ Live signals"

# Context fill (the ctx-pressure trigger): statusline persists % remaining per
# claude pid. From a script $PPID may not be the claude pid, so fall back to the
# most-recently-written ctx file (best-effort; the hook itself keys on its own pid).
ctxf="/tmp/claude-ctx-${PPID}"
note=""
if [ ! -f "$ctxf" ]; then
  ctxf=$(ls -t /tmp/claude-ctx-* 2>/dev/null | head -1)
  note="  (most-recent session; reader can't pin this one without session_id)"
fi
if [ -n "$ctxf" ] && [ -f "$ctxf" ]; then
  rem=$(tr -dc '0-9.' < "$ctxf" 2>/dev/null)
  used=$(awk -v r="${rem:-100}" 'BEGIN{printf "%d", 100-r}')
  printf '    context fill:        %s%% used  (ctx-pressure fires >=80%%)%s\n' "$used" "$note"
else
  printf '    context fill:        (no /tmp/claude-ctx file found)\n'
fi

# Open proposals (the backlog).
if [ "$have_jq" = 1 ] && [ -f "$GCC/proposals.jsonl" ]; then
  open=$(jq -rs '[.[]|select(.status=="open")]|length' "$GCC/proposals.jsonl" 2>/dev/null)
  printf '    open proposals:      %s\n' "${open:-?}"
fi

# Latest backlog triage (the surfacer source).
if [ "$have_jq" = 1 ] && [ -s "$GCC/.backlog-triage-latest.json" ]; then
  read -r d p w dr < <(jq -r '[.date,(.counts.PROMOTE//0),(.counts.WATCH//0),(.counts["DROP-REVIEW"]//0)]|@tsv' "$GCC/.backlog-triage-latest.json" 2>/dev/null)
  printf '    backlog triage:      %s — PROMOTE %s · WATCH %s · DROP-REVIEW %s\n' "$d" "$p" "$w" "$dr"
fi

# Last consolidate run.
if [ -f "$GCC/.backlog-consolidate-last-run" ]; then
  printf '    last consolidate:    %s\n' "$(head -1 "$GCC/.backlog-consolidate-last-run" 2>/dev/null)"
fi

# Dream last injection (the blanket injector — its volume is the noise watch).
if [ -f "$GCC/i-dream/injections.jsonl" ] && [ "$have_jq" = 1 ]; then
  last=$(tail -1 "$GCC/i-dream/injections.jsonl" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null)
  cnt=$(wc -l < "$GCC/i-dream/injections.jsonl" 2>/dev/null | tr -d ' ')
  printf '    dream injected:      %s total, last %s\n' "${cnt:-?}" "${last:-?}"
fi
hr

# ── Plug firings (the plug-events ledger — the FIRED side of efficacy) ───────
PE="${LEDGER_DIR:-$GCC/ledger}/plug-events.jsonl"
sidf="${CLAUDE_CODE_SESSION_ID:-}"
echo "▸ Plug firings  (ledger/plug-events.jsonl — frequency + token cost, ranked)"
if [ "$have_jq" = 1 ] && [ -s "$PE" ]; then
  src="$PE"; scope="all-time"
  if [ -n "$sidf" ]; then
    tmp="/tmp/.pe-filt.$$"
    jq -c --arg s "$sidf" 'select(.session_id==$s)' "$PE" 2>/dev/null > "$tmp"
    if [ -s "$tmp" ]; then src="$tmp"; scope="this session"; fi
  fi
  echo "    scope: $scope"
  jq -rs '
    group_by(.plug)
    | map({plug:.[0].plug, n:length, chars:(map(.chars//0)|add), last:(max_by(.ts).ts)})
    | sort_by(-.chars) | .[]
    | "      \(.plug): fired \(.n) · ~\(.chars) ch total · last \(.last[0:16])"
  ' "$src" 2>/dev/null
  rm -f "/tmp/.pe-filt.$$" 2>/dev/null || true
else
  echo "    (none recorded yet — plug-events.jsonl empty/absent)"
fi
hr
echo "Note: this is the FIRED side (how often + how many tokens each plug spends)."
echo "The ACTED side (was the injection used / the proposal promoted?) is not yet"
echo "recorded — it needs a feedback signal + a ledger detector (deferred)."
exit 0
