#!/usr/bin/env bash
# Run the nine alignment checks and print one line each. Exit code = red count.
#
# Usage: run.sh [check-name ...]   ·   run.sh --list
# Read ~/.claude/scripts/alignment-checks/checks.py for what each one measures.
exec python3 "$HOME/.claude/scripts/alignment-checks/checks.py" "$@"
