#!/usr/bin/env bash
# sl-playground.sh — Start or open the statusline playground
# Usage: sl-playground.sh [--start | --stop | --status | --open]

SERVER_MJS="${HOME}/.claude/assets/static/statusline-server.mjs"
PLAYGROUND_HTML="${HOME}/.claude/assets/static/statusline-playground.html"
PORT=5081

bold=$'\033[1m'; dim=$'\033[2m'; rst=$'\033[0m'
grn=$'\033[32m'; ylw=$'\033[33m'; red=$'\033[31m'; cyn=$'\033[36m'

ACTION="${1:-status}"

is_running() {
  nc -z -G 1 localhost $PORT 2>/dev/null
}

case "$ACTION" in
  --start|start)
    if is_running; then
      printf "${grn}✓${rst}  Render server already running on ${bold}localhost:${PORT}${rst}\n"
      printf "   Open: ${cyn}file://%s${rst}\n" "$PLAYGROUND_HTML"
    else
      if [[ ! -f "$SERVER_MJS" ]]; then
        printf "${red}✗${rst}  Server file not found: %s\n" "$SERVER_MJS" >&2
        exit 1
      fi
      printf "${ylw}▶${rst}  Starting render server on port ${PORT} ...\n"
      printf "${dim}   node %s${rst}\n" "$SERVER_MJS"
      printf "${dim}   (run in background: node %s &)${rst}\n" "$SERVER_MJS"
      printf "\n${bold}To start in background and open playground:${rst}\n"
      printf "   ${cyn}node ~/.claude/assets/static/statusline-server.mjs &${rst}\n"
      printf "   ${cyn}open 'http://localhost:%d'${rst}\n" "$PORT"
    fi
    ;;

  --open|open)
    if is_running; then
      printf "${grn}✓${rst}  Server running — opening playground in browser\n"
      open "http://localhost:${PORT}" 2>/dev/null || \
        printf "${dim}   open http://localhost:%d${rst}\n" "$PORT"
    else
      printf "${ylw}⚠${rst}  Server not running. Opening static file instead.\n"
      if [[ -f "$PLAYGROUND_HTML" ]]; then
        open "$PLAYGROUND_HTML" 2>/dev/null || \
          printf "${dim}   open %s${rst}\n" "$PLAYGROUND_HTML"
      else
        printf "${red}✗${rst}  Playground HTML not found: %s\n" "$PLAYGROUND_HTML" >&2
        exit 1
      fi
    fi
    ;;

  --stop|stop)
    pid=$(lsof -ti tcp:$PORT 2>/dev/null | head -1)
    if [[ -n "$pid" ]]; then
      kill "$pid" 2>/dev/null && \
        printf "${grn}✓${rst}  Stopped process %s on port %d\n" "$pid" "$PORT" || \
        printf "${red}✗${rst}  Could not stop process %s\n" "$pid" >&2
    else
      printf "${dim}·${rst}  No process on port %d\n" "$PORT"
    fi
    ;;

  --status|status|"")
    echo ""
    printf "${bold}Statusline Playground${rst}\n"
    printf "${dim}Server: %s${rst}\n" "$SERVER_MJS"
    printf "${dim}HTML:   %s${rst}\n" "$PLAYGROUND_HTML"
    echo ""
    if is_running; then
      printf "  ${grn}✓${rst}  Server running on ${bold}localhost:${PORT}${rst}\n"
      printf "       Open: ${cyn}http://localhost:%d${rst}\n" "$PORT"
    else
      printf "  ${dim}·${rst}  Server ${dim}not running${rst}\n"
      printf "\n${bold}To start:${rst}\n"
      printf "  ${cyn}node ~/.claude/assets/static/statusline-server.mjs &${rst}\n"
      printf "  ${cyn}open http://localhost:%d${rst}\n" "$PORT"
      printf "\n${bold}Or open static playground directly:${rst}\n"
      printf "  ${cyn}open '%s'${rst}\n" "$PLAYGROUND_HTML"
    fi
    echo ""
    ;;

  *)
    echo "Usage: sl-playground.sh [start|stop|open|status]" >&2
    exit 1
    ;;
esac
