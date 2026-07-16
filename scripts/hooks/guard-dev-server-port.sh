#!/usr/bin/env bash
# guard-dev-server-port.sh — PreToolUse(Bash): port discipline for dev servers.
#
# The failure this ends: one-off dev servers launched with no port land on
# framework defaults (5173, 3000, …), collide with the user's mature apps,
# stack orphans via Vite's silent auto-increment, and nobody can tell what is
# where. The three-tier policy lives in features/dev-servers.md; the ledger is
# scripts/dev-servers/ports.sh.
#
# Behavior (user decision 2026-07-10: BLOCK, not nudge — nudging didn't bind):
#   • launch on a blocklisted framework default        → block, corrected cmd
#   • launch on a port pinned to another project (T1)  → block
#   • launch on a port claimed by another service      → block
#   • launch with NO port at all                       → block, with a
#     pre-allocated tier-3 port so compliance is copy-paste
#   • pm2 commands are exempt (tier-2 lane; ports come from claims/ecosystem)
#
# Escapes: PORTS_OK=1 prefixed to the command (per-command, for projects whose
# config already pins a safe port) · touch ~/.claude/.no-dev-port-gate
# (machine-wide, ALL sessions until removed).
# False fire? That IS reviewable feedback: file
#   propose.sh add --category hooks --title "guard-dev-server-port false fire: …"
# — the hook-telemetry review reads both that and this hook's warn-log records.

set -uo pipefail
[ -f "$HOME/.claude/.no-dev-port-gate" ] && exit 0

INPUT=$(cat 2>/dev/null || echo '{}')
command -v jq >/dev/null 2>&1 || exit 0
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$CMD" ] || exit 0

# Per-command escape + pm2 exemption, before any heavier work. The exemption
# applies only when the WHOLE command is pm2 (tier-2 lane) — a pm2 prefix must
# not smuggle a raw launch past the gate (`pm2 ls; vite --port 5173` was a
# full bypass, review finding 8).
case "$CMD" in *PORTS_OK=1*) exit 0 ;; esac
printf '%s' "$CMD" | rg -q '^\s*pm2\s[^;&|]*$' 2>/dev/null && exit 0

# Launch detection — the common local dev-server spawners. Env-var prefixes
# (PORT=… NODE_ENV=…) before the launcher are part of the launch form.
LAUNCH_RE='(^|[;&|(]\s*)([A-Za-z_]+=\S+\s+)*(npx\s+)?((npm|pnpm|yarn|bun)\s+(run\s+)?dev\b|vite\b|next\s+(dev|start)\b|react-router\s+dev\b|remix\s+(vite:)?dev\b|astro\s+dev\b|nuxt\s+dev\b|webpack\s+serve\b|python3?\s+-m\s+http\.server\b|serve\b|uvicorn\b|flask\s+run\b)'
# Scan a quote-blanked copy: a dev-server name that only appears INSIDE a
# quoted grep/rg/ps/awk pattern (e.g. `ps … | rg 'next-server|next dev'`) is
# a read-only inspection, not a launch — but the `|`/`;`/`&` inside those
# quotes would otherwise read as a real command separator. Real launches are
# unquoted, so blanking quoted spans leaves them intact. Port extraction below
# still runs on the original command.
if command -v perl >/dev/null 2>&1; then
  SCAN=$(printf '%s' "$CMD" | perl -pe "s/'[^']*'//g; s/\"[^\"]*\"//g")
else
  SCAN="$CMD"
fi
printf '%s' "$SCAN" | rg -q "$LAUNCH_RE" 2>/dev/null || exit 0

CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
PORTS="$HOME/.claude/scripts/dev-servers/ports.sh"

# Port extraction: --port N / --port=N / -p N / PORT=N / http.server N.
PORT=$(printf '%s' "$CMD" | rg -o -r '$1' -e '--port[= ]([0-9]{2,5})' 2>/dev/null | head -1)
[ -n "$PORT" ] || PORT=$(printf '%s' "$CMD" | rg -o -r '$2' -e '(^|\s)-p[= ]([0-9]{2,5})' 2>/dev/null | head -1)
[ -n "$PORT" ] || PORT=$(printf '%s' "$CMD" | rg -o -r '$1' -e 'PORT=([0-9]{2,5})' 2>/dev/null | head -1)
[ -n "$PORT" ] || PORT=$(printf '%s' "$CMD" | rg -o -r '$1' -e 'http\.server\s+([0-9]{2,5})' 2>/dev/null | head -1)

block() { # block <reason>
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook dev-server-port --action block --heeded unknown >/dev/null 2>&1 || true
  jq -cn --arg r "$1" '{decision:"block", reason:$r}' 2>/dev/null || true
  exit 0
}

FEEDBACK_LINE="False fire? Re-run prefixed with PORTS_OK=1 AND file: bash ~/.claude/scripts/propose.sh add --category hooks --title \"guard-dev-server-port false fire\" --body \"<the command>\" — the hook-telemetry review reads these."

# No port on the command line? The framework-recommended place to pin a port is
# the project CONFIG, and blocking that correct setup was the highest-frequency
# false fire (review finding 3). Sniff the cwd's config cheaply; a configured
# port is then judged like an explicit one.
if [ -z "$PORT" ] && [ -n "$CWD" ] && [ -d "$CWD" ]; then
  for f in vite.config.ts vite.config.js vite.config.mts vite.config.mjs \
           next.config.js next.config.ts next.config.mjs astro.config.mjs \
           nuxt.config.ts react-router.config.ts; do
    [ -f "$CWD/$f" ] || continue
    PORT=$(rg -o -r '$1' -e '\bport["'"'"'`]?\s*[:=]\s*([0-9]{2,5})' "$CWD/$f" 2>/dev/null | head -1)
    [ -n "$PORT" ] && break
  done
  [ -n "$PORT" ] || PORT=$(rg -o -r '$1' -e '^PORT=([0-9]{2,5})' "$CWD/.env" 2>/dev/null | head -1)
  [ -n "$PORT" ] || PORT=$(rg -o -r '$1' -e '--port[= ]([0-9]{2,5})' "$CWD/package.json" 2>/dev/null | head -1)
fi

if [ -z "$PORT" ]; then
  SUGG=$(bash "$PORTS" next --tier 3 2>/dev/null)
  block "⛔ DEV SERVER WITHOUT A PORT — no port on the command line AND none found in the project config (vite/next/astro/nuxt config, .env PORT, package.json scripts). A portless launch lands on a framework default (5173/3000/…), which collides with the user's mature apps and stacks orphans (rules: features/dev-servers.md, three-tier port policy).

Pick the right tier and relaunch with an explicit port:
  one-off/ephemeral (tier 3): port ${SUGG:-6200} is free — e.g. add: --port ${SUGG:-6200} --strictPort   (vite/react-router; next: PORT=${SUGG:-6200}; record it: bash ~/.claude/scripts/dev-servers/ports.sh claim <name> --tier 3 --port ${SUGG:-6200})
  persistent local service (tier 2): bash ~/.claude/scripts/dev-servers/ports.sh claim <name> --tier 2   (then run under pm2)
If this project's own config already pins a safe non-default port, re-run prefixed with PORTS_OK=1.
$FEEDBACK_LINE"
fi

VERDICT=$(bash "$PORTS" check "$PORT" "$CWD" 2>/dev/null || echo OK)
case "$VERDICT" in
  OK*) exit 0 ;;
  PINNED-UNSCOPED*)
    OWNER=${VERDICT#PINNED-UNSCOPED }
    block "⛔ PORT $PORT IS PINNED to '$OWNER' but the pin has NO owning directory, so the gate cannot tell owner from squatter. If this launch IS the pinned project: rescope the pin from its root — bash ~/.claude/scripts/dev-servers/ports.sh pin $PORT $OWNER --cwd <project-root> — then re-run (or one-off: PORTS_OK=1). If it is NOT yours, claim a 62xx port instead: ports.sh claim <name> --tier 3. Unsure whose it is? That is a USER call — PESTER the user explicitly; never stall silently.
$FEEDBACK_LINE" ;;
  PINNED*)
    OWNER=${VERDICT#PINNED }
    block "⛔ PORT $PORT IS PINNED to '$OWNER' (tier-1, user-owned — see ports.sh list) and this launch is from a DIFFERENT directory. Claude-launched servers may never squat a pinned port. Get your own: bash ~/.claude/scripts/dev-servers/ports.sh claim <name> --tier 3   (prints a free 62xx port). If you believe the pin itself must change, that is a USER decision — PESTER the user explicitly in your reply; do not stall silently or work around the gate.
$FEEDBACK_LINE" ;;
  CLAIMED*)
    block "⛔ PORT $PORT IS ALREADY CLAIMED (${VERDICT#CLAIMED }). Two services on one port means the second silently fails or auto-increments into a third service's port. Allocate your own: bash ~/.claude/scripts/dev-servers/ports.sh claim <name> --tier 3
$FEEDBACK_LINE" ;;
  BLOCKED*)
    SUGG=$(bash "$PORTS" next --tier 3 2>/dev/null)
    block "⛔ PORT $PORT IS A FRAMEWORK DEFAULT (blocklist: 3000 3001 4200 5000 5173-5179 8000 8080 8888) — defaults are exactly where agent servers collide with the user's apps. Use ${SUGG:-6200} instead (add --strictPort so nothing auto-increments), and record it: bash ~/.claude/scripts/dev-servers/ports.sh claim <name> --tier 3 --port ${SUGG:-6200}
$FEEDBACK_LINE" ;;
esac
exit 0
