#!/bin/bash
# Image-tool usage review — digests 3 weeks of image-read activity across every
# lane so the human can judge cost vs efficacy: Claude-native reads (token cost,
# from log-image-reads.sh), local `see` (free), `imagine`, and gemini once its
# wrapper logs. Writes a dated brief and opens it. Scheduled one-shot by
# gcc-schedule `image-tools-review` (2026-07-28T15:00); rerunnable by hand.
set -euo pipefail
LM=~/Code/local-models
OUT=~/.claude/logs/image-tools-review-$(date +%Y%m%d).md
CUTOFF="$(date -u -v-21d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '21 days ago' +%Y-%m-%dT%H:%M:%SZ)"

recent() { [ -f "$1" ] && jq -c --arg c "$CUTOFF" 'select(.ts >= $c)' "$1" 2>/dev/null || true; }
NATIVE=$(recent ~/.claude/logs/image-reads.jsonl)
SEE=$(recent "$LM/logs/see-history.jsonl")
IMAGINE=$(recent "$LM/outputs/imagine-history.jsonl")
GEM=$(recent "$LM/logs/gem-history.jsonl")

{
  echo "# Image-tool review — $(date +%Y-%m-%d) (last 21 days)"
  echo
  echo "Decide: is native-read token spend justified where see (free) or gemini (abundant)"
  echo "would do? Reference comparison notes: ~/Code/local-models/docs/08-vision-lenses-design.md"
  echo "§Outcome + .claude/output/20260625-vision-lenses/skeptic.md (fidelity-audit citations)."
  echo
  echo "## Claude-native image reads (paid tokens)"
  printf '%s\n' "$NATIVE" | jq -rs 'if length == 0 then "- none" else
    "- reads: \(length) · est tokens: \(map(.est_tokens) | add) · sessions: \(map(.session_id) | unique | length)",
    (group_by(.session_id) | sort_by(-length) | .[0:5][] |
     "  - \(.[0].session_id[0:8]): \(length) reads, \(map(.est_tokens) | add) est tok") end'
  echo
  echo "## Local see (free)"
  printf '%s\n' "$SEE" | jq -rs 'if length == 0 then "- none" else "- reads: \(length) · avg \((map(.ms) | add / length) | round)ms" end'
  echo
  echo "## imagine (free)"
  printf '%s\n' "$IMAGINE" | jq -rs '"- generations: \(length)"'
  echo
  echo "## gemini vision (via wrapper, once built)"
  printf '%s\n' "$GEM" | jq -rs 'if length == 0 then "- no gem-history yet (wrapper not built or unused)" else "- calls: \(length)" end'
  echo
  echo "## model dispatches (sub-agent tier telemetry, once guard-model-tier logs)"
  DISPATCH=$(recent ~/.claude/logs/model-dispatch.jsonl)
  printf '%s\n' "$DISPATCH" | jq -rs 'if length == 0 then "- no model-dispatch.jsonl yet (Phase A hook not built or no dispatches)" else
    "- dispatches: \(length)",
    (group_by(.model // "unpinned") | sort_by(-length) | .[] |
     "  - \(.[0].model // "UNPINNED"): \(length)") end'
  echo
  echo "## Suggested judgment frame"
  echo "- Native reads inside a conversation are fine (already in context, highest fidelity)."
  echo "- Standalone 'what does this image say' → see first (free), verify exact strings."
  echo "- If native est-token spend is large AND reads look shape-like (structural), shift to see."
  echo "- Devise the head-to-head test if the data is ambiguous (probe-style: N labeled images,"
  echo "  recall + fabrication + cost per lane) — see the model-tier proposal §vision."
} > "$OUT"

echo "review brief: $OUT"
command -v open >/dev/null && open "$OUT" || true
