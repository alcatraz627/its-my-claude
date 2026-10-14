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
# Belt and braces, and currently UNREACHABLE: LAUNCH_RE anchors every alternate
# at start-of-string or after a separator, so a command beginning with `pm2`
# cannot match it, and seven pm2 forms give an identical verdict with this line
# removed (mutation M3, 2026-09-04). Kept because it costs nothing and would
# start mattering the moment LAUNCH_RE gains an unanchored alternate. Do not read
# the passing A-P9 test case as proof this line works; it does not isolate it.
printf '%s' "$CMD" | rg -q '^\s*pm2\s[^;&|]*$' 2>/dev/null && exit 0

# Launch detection — the common local dev-server spawners. Env-var prefixes
# (PORT=… NODE_ENV=…) before the launcher are part of the launch form.
# `\b` is the wrong boundary for a bare tool name, because a hyphen satisfies it:
# `vite\b` matched `vite-node` and `vite-plugin-inspect`, so a one-shot script
# runner read as a dev server (prop-20260825-215830-94). Bare names therefore end
# with `([^-\w]|$)`: a following hyphen or word character means this is a
# DIFFERENT tool whose name merely starts the same. Compound alternates such as
# `npm run dev` keep `\b`, because `npm run dev-server` really is a launch.
LAUNCH_RE='(^|[;&|(]\s*)([A-Za-z_]+=\S+\s+)*(npx\s+)?((npm|pnpm|yarn|bun)\s+(run\s+)?dev\b|vite([^-\w]|$)|next\s+(dev|start)\b|react-router\s+dev\b|remix\s+(vite:)?dev\b|astro\s+dev\b|nuxt\s+dev\b|webpack\s+serve\b|python3?\s+-m\s+http\.server\b|serve([^-\w]|$)|uvicorn([^-\w]|$)|flask\s+run\b)'
# Scan a quote-blanked copy: a dev-server name that only appears INSIDE a
# quoted grep/rg/ps/awk pattern (e.g. `ps … | rg 'next-server|next dev'`) is
# a read-only inspection, not a launch — but the `|`/`;`/`&` inside those
# quotes would otherwise read as a real command separator. Real launches are
# unquoted, so blanking quoted spans leaves them intact. Port extraction below
# still runs on the original command.
#
# One stage, not two. An earlier version built a heredoc-blanked copy into SCAN
# and then threw it away three lines later by re-reading $CMD, so the heredoc
# handling never ran once: a `git commit -F -` whose MESSAGE body began with
# `npm run dev` was blocked as a launch (prop-20260903-131552-b6).
#
# strip-payloads.py does both jobs in one pass. It blanks heredoc bodies AND
# quoted spans, and it knows command position, so a launcher counts only where a
# shell would actually run one. hook_cmd_skeleton is deliberately NOT used here:
# it states at hook-common.sh:166 that it does not parse heredoc bodies, and that
# is the half this guard needs most.
#
# A scanner failure falls back to the RAW command, which is the conservative
# direction for a safety gate: the guard keeps working as it did before the
# stripper existed, rather than silently disarming on a broken python.
STRIP="$HOME/.claude/scripts/hooks/strip-payloads.py"
SCAN="$CMD"
if [ -r "$STRIP" ]; then
  _stripped=$(printf '%s' "$CMD" | python3 "$STRIP" 2>/dev/null)
  [ -n "$_stripped" ] && SCAN="$_stripped"
fi
printf '%s' "$SCAN" | rg -q "$LAUNCH_RE" 2>/dev/null || exit 0
# A build, typecheck or lint subcommand binds no port. `vite build` tripped the
# gate in data-forge (prop-20260710-122025-76, six corroborations); only
# dev / preview / serve / start forms are launches. Owner batch 2026-09-18.
BUILD_RE='\b(vite|next|astro|nuxt|remix|react-router)\s+(build|typecheck|lint|optimize|check|generate|info)\b'
printf '%s' "$SCAN" | rg -q "$BUILD_RE" 2>/dev/null && exit 0

# `vite --help` and `--version` print and exit; no server starts. A bare `-h`
# counts only as the last token: for flask and uvicorn it means --host.
printf '%s' "$SCAN" | rg -q '\b(vite|next|astro|nuxt|remix|react-router|webpack|uvicorn|flask|serve)\b[^;&|]*\s((--help|--version)(\s|$)|-h\s*$)' 2>/dev/null && exit 0

CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

# `npm run dev:build` whose script is a build or a typecheck starts no server.
# Only a body that is plainly one of those is exempt: a body that calls another
# script, a shell, `concurrently` or `node` may launch one, so it still blocks.
# A missing file or script falls through to the launch verdict, as before.
SCRIPT_NAME=$(printf '%s' "$SCAN" | rg -o -r '$2' -e '(^|[;&|(]\s*)(?:[A-Za-z_]+=\S+\s+)*(?:npm|pnpm|yarn|bun)\s+(?:run\s+)?(dev[A-Za-z0-9:_-]+)(\s|$)' 2>/dev/null | head -1)
# A `cd` or `--prefix` first means the package.json in cwd is the wrong one.
if [ -n "$SCRIPT_NAME" ] && [ -n "$CWD" ] && [ -f "$CWD/package.json" ] \
  && ! printf '%s' "$SCAN" | rg -q '(^|[;&|(]\s*)(cd|pushd)\s|--prefix|-C\s|--cwd' 2>/dev/null; then
  BODY=$(jq -r --arg n "$SCRIPT_NAME" '.scripts[$n] // empty' "$CWD/package.json" 2>/dev/null)
  if [ -n "$BODY" ] \
    && printf '%s' "$BODY" | rg -q "^\s*(($BUILD_RE)|tsc|eslint|prettier|vitest run|jest)\b[^;&|]*$" 2>/dev/null; then
    exit 0
  fi
fi
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
