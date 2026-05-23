#!/usr/bin/env bash
# sl-cli.sh — Statusline CLI dispatcher
# Usage: sl-cli.sh <config|explain|audit> [args...]
# This script is the 0-LLM entry point — no Claude involvement.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CMD="${1:-help}"
shift 2>/dev/null || true

bold=$'\033[1m'; dim=$'\033[2m'; rst=$'\033[0m'
cyn=$'\033[36m'; ylw=$'\033[33m'

case "$CMD" in
  config)
    bash "$SCRIPT_DIR/sl-config.sh" "$@"
    ;;
  explain)
    bash "$SCRIPT_DIR/sl-explain.sh" "$@"
    ;;
  audit)
    bash "$SCRIPT_DIR/sl-audit.sh" "$@"
    ;;
  playground|play)
    bash "$SCRIPT_DIR/sl-playground.sh" "$@"
    ;;
  open)
    bash "$SCRIPT_DIR/sl-open.sh" "$@"
    ;;
  help|--help|-h|"")
    echo ""
    printf "${bold}statusline${rst} — Statusline CLI\n"
    printf "${dim}Scripts: %s${rst}\n\n" "$SCRIPT_DIR"
    printf "  ${cyn}%-12s${rst}  %s\n" "config"     "Show active profile config (all segment on/off/auto values)"
    printf "  ${cyn}%-12s${rst}  %s\n" "explain"    "Explain each widget: what it shows, when it fires"
    printf "  ${cyn}%-12s${rst}  %s\n" "audit"      "Check for config issues, syntax errors, stale data"
    printf "  ${cyn}%-12s${rst}  %s\n" "playground" "Show playground server status; start/stop/open"
    printf "  ${cyn}%-12s${rst}  %s\n" "open"       "Open a statusline file in editor or browser"
    echo ""
    printf "${dim}Options:${rst}\n"
    printf "  ${dim}--profile <name>${rst}  Use a specific profile (default: \$STATUSLINE_PROFILE or 'custom')\n"
    printf "  ${dim}--claude${rst}          (audit only) Append structured output for Claude analysis\n"
    echo ""
    printf "${dim}Filter (explain):${rst}\n"
    printf "  ${dim}sl-cli.sh explain L2${rst}       Show only L2 widgets\n"
    printf "  ${dim}sl-cli.sh explain rate${rst}      Show only the 'rate' widget\n"
    echo ""
    printf "${dim}Playground:${rst}\n"
    printf "  ${dim}sl-cli.sh playground start${rst}  Start render server (port 5081)\n"
    printf "  ${dim}sl-cli.sh playground open${rst}   Open in browser (or static HTML if server down)\n"
    printf "  ${dim}sl-cli.sh playground stop${rst}   Stop render server\n"
    echo ""
    printf "${dim}Open targets:${rst}\n"
    printf "  ${dim}sh conf skill playground dev-guide widget-ref audit cli${rst}\n"
    echo ""
    printf "${dim}0-LLM shell alias (add to .zshrc):${rst}\n"
    printf "  ${ylw}statusline() { bash ~/.claude/scripts/statusline/sl-cli.sh \"\$@\"; }${rst}\n"
    echo ""
    ;;
  *)
    echo "Unknown command: $CMD  (try: config | explain | audit | help)" >&2
    exit 1
    ;;
esac
