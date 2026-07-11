#!/bin/bash
# pending-proposals.sh — RETIRED (migration 0031, 2026-07-11). No longer wired.
#
# This was a SessionStart hook that injected the pending rows of
# ~/.claude/claudew/pending-config-proposals.jsonl into every session's context
# for review. It ran for weeks and produced zero decisions, for a structural
# reason: that file was a SECOND proposal store that nothing triaged. Its rows
# never entered proposals.jsonl, never accrued corroboration, never appeared in
# /backlog-triage, and the only lifecycle the injected text offered was "hand-edit
# the JSONL" — which no rule permits and no session did.
#
# The same five rules were therefore re-injected at every single SessionStart,
# indefinitely: an advisory surface with no conversion path, which is exactly the
# failure mode the account has already logged elsewhere (persona-suggest,
# 0/73 conversions).
#
# Dream insights now file onto the ONE backlog via propose-config-from-insights.sh
# (tagged link:dream:<id> + src:dream-consolidation) and are decided at
# /backlog-triage alongside every other proposal. They are surfaced by the same
# backlog surfacer as everything else — no bespoke channel.
#
# The old JSONL is kept as a read-only archive for history. Nothing writes it.
# This script is left in place, inert, so any stale settings.json reference
# degrades to a silent no-op rather than a hook error.
exit 0
