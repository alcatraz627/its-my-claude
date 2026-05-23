#!/usr/bin/env bash
# validate-triggers.sh — Thin wrapper around validate-triggers.py.
# Delegates to Python because macOS ships bash 3.2 (no associative arrays).
exec python3 "${BASH_SOURCE%.sh}.py" "$@"
