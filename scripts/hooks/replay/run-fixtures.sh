#!/usr/bin/env bash
# run-fixtures.sh — regression gate for a Stop-hook change.
#
# Runs the pinned fixture set through the REAL hook and fails (non-zero) if any
# fixture's outcome no longer matches its manifest `expected`. Run this before
# shipping any change to a Stop hook. Logic lives in run_fixtures.py (shell stays
# thin — macOS bash is 3.2).
#
# Usage:
#   ./run-fixtures.sh <hook-script> [fixtures-subdir]
#   ./run-fixtures.sh                       # all fixtures, hook resolved per entry
#
# Examples:
#   ./run-fixtures.sh ~/.claude/scripts/hooks/declared-ready-stop.sh
#   ./run-fixtures.sh ~/.claude/scripts/hooks/declared-ready-stop.sh declared-ready
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$HERE/run_fixtures.py" "$@"
