#!/bin/bash
# codex-usage-gate.sh — may a Codex seat be dispatched right now?
#
# Sibling of usage-gate.sh with the same contract (VERDICT<TAB>detail; exit 0
# PASS / 1 GATED; UNKNOWN is a PASS that says so). The reading comes from Codex's
# own app-server RPC `account/rateLimits/read`; the logic lives in the adapter:
#   ~/.claude/adapters/codex/bin/codex-usage-gate.py
# Owner ruling 2026-09-11: stand down at 25% remaining (CODEX_GATE_PCT=75 used).
# Born from 2026-08-27, when parallel Claude lanes spent most of the Codex quota
# with nothing gating them. Mute (owner only): touch ~/.claude/.no-codex-usage-gate
exec python3 "$HOME/.claude/adapters/codex/bin/codex-usage-gate.py" "$@"
