#!/usr/bin/env bash
# Regression test for backlog-consolidate.py content-similarity clustering.
#
# The thresholds in that file (PHRASE_SUPPORT_MIN, MIN_TOKENS, BOILERPLATE_DF) were
# set from measurements, and both directions of failure have already shipped once:
#   over-merge  — templated [atone] proposals scored 0.81 against each other and
#                 would have fused every atone slug into one cluster;
#   no-op       — a "rare = appears in <=1 proposal" cutoff made an edge impossible,
#                 so the feature silently did nothing.
# This pins both. Run it after touching any threshold.
#
#   bash ~/.claude/scripts/tests/test-content-edges.sh
set -uo pipefail

BC="$HOME/.claude/scripts/backlog-consolidate.py"
FX=$(mktemp -d)
trap 'rm -rf "$FX"' EXIT
STORE="$FX/store.jsonl"
fail=0

ok()   { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; fail=1; }

# Two proposals that ARE the same bug (the real task-sync pair, filed a day apart
# by different sessions, which the link-graph could never connect).
cat > "$STORE" <<'EOF'
{"id":"dup-a","ts":"2026-07-09T23:34:44Z","title":"task-sync nudge should detect sessions where the Task tool is absent and stay silent","body":"The task-sync UserPromptSubmit nudge fired ~10x across one session instructing TaskCreate/TaskUpdate, but the session toolset had no Task tools. The agent can never comply; the nudge is pure noise and burns attention. The hook should check tool availability before nagging.","category":"hooks","effort":"small","status":"open","tags":["src:session-contrib"]}
{"id":"dup-b","ts":"2026-07-10T13:18:07Z","title":"task-sync hook: detect harnesses where the Task tool is absent and stop nagging","body":"TaskCreate/TaskUpdate were absent from the harness, so todos were hand-maintained in the session workspace doc, but the task-sync hook nagged ~10 times across the session. The hook should probe whether the session tool surface actually has TaskCreate and downgrade to silent.","category":"hooks","effort":"small","status":"open","tags":["src:session-contrib"]}
{"id":"far-a","ts":"2026-05-15T12:45:17Z","title":"Drifting systems follow-up review","body":"Review the drifting systems identified earlier and decide what to do about each one.","category":"docs","effort":"medium","status":"open","tags":["src:session-contrib"]}
{"id":"far-b","ts":"2026-05-17T17:44:53Z","title":"[follow-up] Migrate 98 ref-points from old symlink paths","body":"Ninety-eight references still point at the pre-migration symlink paths and must be rewritten before the back-compat symlinks can be removed.","category":"scripts","effort":"medium","status":"open","tags":["src:session-contrib"]}
{"id":"tmpl-a","ts":"2026-05-31T08:59:25Z","title":"[atone] rules/batched-past-explicit-stop-checkpoints.md entry","body":"Auto-drafted from atone pattern. Suggested target: ~/.claude/rules/batched-past-explicit-stop-checkpoints.md (or merge into an existing rules file). Body (expand from precheck/what-not-to-do): precheck empty - read latest event for context.","category":"hooks","effort":"small","status":"open","tags":["link:atone:batched-past-explicit-stop-checkpoints","src:atone-graduation"]}
{"id":"tmpl-b","ts":"2026-05-31T08:59:26Z","title":"[atone] rules/over-corrected-tuning-request-into-disable.md entry","body":"Auto-drafted from atone pattern. Suggested target: ~/.claude/rules/over-corrected-tuning-request-into-disable.md (or merge into an existing rules file). Body (expand from precheck/what-not-to-do): precheck empty - read latest event for context.","category":"hooks","effort":"small","status":"open","tags":["link:atone:over-corrected-tuning-request-into-disable","src:atone-graduation"]}
EOF

edges=$(PROPOSE_STORE="$STORE" python3 "$BC" --read-only --explain --force 2>&1 >/dev/null | grep -c "content-edge" || true)
report=$(PROPOSE_STORE="$STORE" python3 "$BC" --read-only --force 2>/dev/null)

echo "content-edge regression:"

# 1. The real duplicate pair merges.
if echo "$report" | grep -q "dup-a, dup-b"; then
  ok "true duplicate merged into one cluster (task-sync pair)"
else
  bad "true duplicate NOT merged — the feature is a no-op again"
fi

# 2. and that merge produces real corroboration (this is what clears the gate).
if echo "$report" | grep "dup-a, dup-b" -B1 | grep -q "corroboration=2"; then
  ok "merged duplicate reports corroboration=2"
else
  bad "merged duplicate did not reach corroboration=2"
fi

# 3. A shared common word ("follow-up") must NOT merge unrelated proposals.
if echo "$report" | grep -q "far-a, far-b"; then
  bad "unrelated proposals merged on a shared common word (over-merge)"
else
  ok "unrelated proposals sharing 'follow-up' stayed separate"
fi

# 4. Templated auto-filed proposals must NEVER be content-merged: they carry a
#    precise link:atone:<slug> identity and their bodies are one template.
if echo "$report" | grep -q "tmpl-a, tmpl-b"; then
  bad "templated [atone] proposals fused (the 0.81-boilerplate over-merge is back)"
else
  ok "templated [atone] proposals stayed separate (link-identified, not fuzzy-matched)"
fi

# 5. Exactly one edge on this corpus — no silent extras.
if [ "$edges" = "1" ]; then
  ok "exactly 1 content edge drawn"
else
  bad "expected 1 content edge, drew $edges"
fi

# 6. The escape hatch still disables the whole path.
none=$(PROPOSE_STORE="$STORE" python3 "$BC" --read-only --no-content --explain --force 2>&1 >/dev/null | grep -c "content-edge" || true)
if [ "$none" = "0" ]; then
  ok "--no-content disables content edges"
else
  bad "--no-content still drew $none edges"
fi

echo
[ "$fail" = "0" ] && echo "all passed" || echo "FAILURES — do not ship"
exit "$fail"
