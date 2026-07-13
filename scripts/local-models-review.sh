#!/usr/bin/env bash
# Did the July 2026 local-model additions actually get USED?
#
# Adoption beats correctness here: a capability nobody reaches for is a failure
# however green its tests are — and schnell in particular cost 31GB of disk on the
# promise that the imagegen convergence loop would be worth iterating on. This
# brief mines the histories (the suite's own API) and says, per capability, used
# or dead. Dead ones get a recommendation to drop, not to polish.
#
# Fired one-shot by gcc-schedule (local-models-review). Writes a brief and opens it.
set -uo pipefail
LM="$HOME/Code/local-models"
SINCE_DAYS="${1:-30}"
OUT="$HOME/.claude/assets/reports/$(date +%Y%m%d)-local-models-review.md"
mkdir -p "$(dirname "$OUT")"

# Count only usage AFTER the build wave. The session that built these things hammered
# them (25 compares, 9 schnell renders in one day) — counting that would report "USED"
# even if nobody ever touched them again, masking the exact failure this brief exists
# to catch. Adoption means someone reached for it when they weren't building it.
BUILD_END_EPOCH=$(date -j -f "%Y-%m-%d" "2026-07-14" +%s 2>/dev/null || date -d "2026-07-14" +%s)
since_epoch=$(date -v-"${SINCE_DAYS}"d +%s 2>/dev/null || date -d "-${SINCE_DAYS} days" +%s)
[ "$since_epoch" -lt "$BUILD_END_EPOCH" ] && since_epoch="$BUILD_END_EPOCH"
count_since() {  # <file> <ts-field>
  [ -f "$1" ] || { echo 0; return; }
  jq -r --argjson since "$since_epoch" \
    "select((.${2} // \"\") != \"\") | (.${2} | sub(\"Z$\";\"Z\") | fromdateiso8601? // 0) | select(. >= \$since)" \
    "$1" 2>/dev/null | wc -l | tr -d ' '
}

Q=$(count_since "$LM/logs/q-history.jsonl" ts)
SEE=$(count_since "$LM/logs/see-history.jsonl" ts)
CMP=$(count_since "$LM/logs/compare-history.jsonl" ts)
FLEET=$(count_since "$LM/logs/fleet-history.jsonl" ts)
IMG=$(count_since "$LM/outputs/imagine-history.jsonl" ts)
SCHNELL=$(jq -r --argjson since "$since_epoch" \
  'select(.model == "schnell") | select((.ts | fromdateiso8601? // 0) >= $since) | .ts' \
  "$LM/outputs/imagine-history.jsonl" 2>/dev/null | wc -l | tr -d ' ')
LOOPS=$(ls -d "$LM"/outputs/see/loops/*/ 2>/dev/null | wc -l | tr -d ' ')
# rounds added since the wave — a ledger built during the build doesn't prove adoption
ROUNDS=$(cat "$LM"/outputs/see/loops/*/ledger.json 2>/dev/null \
  | jq -s --argjson since "$since_epoch" \
    '[.[].rounds[]? | select((.ts | fromdateiso8601? // 0) >= $since)] | length' 2>/dev/null || echo 0)

verdict() {  # <count> <threshold> <name> <drop-advice>
  if [ "${1:-0}" -ge "$2" ]; then echo "**USED** ($1)"; else echo "**DEAD** ($1) — $4"; fi
}

{
  printf '# Local-models review — %s (last %s days)\n\n' "$(date +%Y-%m-%d)" "$SINCE_DAYS"
  printf 'The July 9-13 wave shipped a lot. The only question that matters now: is any of it\n'
  printf 'being reached for? A capability nobody uses is a failure however green its tests are.\n\n'

  printf '## The 2026-07-13 additions — used or dead?\n\n'
  printf '| Capability | Signal | Verdict |\n|---|---|---|\n'
  printf '| `see diff` / vis-compare | %s compare runs | %s |\n' "$CMP" "$(verdict "$CMP" 3 x 'nobody compared anything — the L1/L2 stack is unused; consider retiring the skill from the menu')"
  printf '| L3 convergence loop | %s loop dir(s), %s round(s) | %s |\n' "$LOOPS" "$ROUNDS" "$(verdict "$ROUNDS" 3 x 'the loop was never driven — its ledger + policy machinery is dead weight')"
  printf '| **schnell (31GB disk)** | %s schnell generation(s) | %s |\n' "$SCHNELL" "$(verdict "$SCHNELL" 3 x 'THE 31GB WAS WASTED. Drop it: trash ~/.cache/huggingface/hub/models--black-forest-labs--FLUX.1-schnell and restore the config.sh ruling (qwen-only). The preflight will refuse it cleanly.')"
  printf '| asset-verify | run it: `lib/asset-verify.py <src> <rungs...>` | check by hand — no history stream |\n'
  printf '| findings-gate (/bloop 4.0) | check bloop runtime-notes for pre-gate mentions | check by hand |\n'
  printf '| E8 web lane | check for e8-capture-*.json outside probe/fixtures | check by hand |\n\n'

  printf '## Baseline suite usage (context)\n\n'
  printf '| Lane | Runs (last %sd) |\n|---|---|\n' "$SINCE_DAYS"
  printf '| q | %s |\n| see | %s |\n| fleet | %s |\n| imagine (all models) | %s |\n\n' "$Q" "$SEE" "$FLEET" "$IMG"

  printf '## The decisions this brief exists to force\n\n'
  printf '1. **schnell**: used → keep. Unused → drop it and reclaim 31GB (the prior ruling in\n'
  printf '   `config.sh:25` said speed is not valued for images; only the convergence loop\n'
  printf '   justified re-pulling it).\n'
  printf '2. **The loop**: unused → the ledger/policy machinery is over-built for the real need;\n'
  printf '   say so honestly in docs/STATE.md rather than leaving it as aspiration.\n'
  printf '3. **Routing**: did the fleet/local-coder seat get real work? (STATE §DONE 2026-07-13\n'
  printf '   cleared it for scoped-worker-under-a-judge.) If it never ran again, the experiment\n'
  printf '   was interesting and unadopted — worth knowing.\n\n'
  printf 'Full context: `~/Code/local-models/docs/STATE.md` · `docs/10-visual-compare-design.md`\n'
  printf 'Verify the suite still passes: `bash ~/Code/local-models/scripts/verify.sh`\n'
} > "$OUT"

echo "wrote $OUT"
command -v open >/dev/null && open "$OUT" 2>/dev/null || true
