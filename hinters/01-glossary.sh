#!/usr/bin/env bash
# 01-glossary.sh — steering-vocabulary hinter.
#
# When the user's prompt contains a User Shorthand term (efficacy, overindex,
# pragmatic, ...), inject its one-line canonical meaning so every session hears
# the word the way the user means it — the activation half of the vocabulary
# pipeline (the glossary bake is the storage half; see
# conventions/preference-graduation.md).
#
# Contract (hint-injector.sh): prompt on stdin, at most ONE hint line on stdout,
# empty output = no hint. Target <100ms: pure awk, no python.
# Data: ~/.claude/style/glossary-hints.tsv (term<TAB>meaning<TAB>pointer).
# Cap: 2 terms per prompt, first-listed wins ties. Rows sharing one meaning
# (a word cluster, or spelling variants of one phrase) inject at most once.

set -uo pipefail

HINTS="${GLOSSARY_HINTS:-$HOME/.claude/style/glossary-hints.tsv}"
[ -f "$HINTS" ] || exit 0

PROMPT=$(cat 2>/dev/null || echo "")
[ -z "$PROMPT" ] && exit 0

# awk emits "terms<TAB>hint" on match; bash splits so the hint alone reaches
# stdout and the terms feed the usage ledger (decay evidence, migration 0036).
RESULT=$(printf '%s' "$PROMPT" | awk -F'\t' -v hints="$HINTS" '
BEGIN {
    n = 0
    while ((getline line < hints) > 0) {
        if (line ~ /^#/ || line == "") continue
        split(line, f, "\t")
        if (f[1] != "" && f[2] != "") { n++; term[n] = f[1]; meaning[n] = f[2] }
    }
    close(hints)
}
{ prompt = prompt " " tolower($0) }
END {
    # trailing pad so a term at the very end of the prompt still has a boundary
    prompt = prompt " "
    # The ledger records every MATCHED term; the displayed hint stays capped at
    # 2 and cluster-deduped. Usage evidence must not be gated by display slots,
    # or cluster siblings and 3rd+ matches read as dormant while in active use.
    out = ""; hitterms = ""; count = 0
    for (i = 1; i <= n; i++) {
        t = tolower(term[i])
        # word-boundary-ish match: term surrounded by non-alphanumerics
        if (match(prompt, "[^a-z0-9]" t "[^a-z0-9]") || match(prompt, "^" t "[^a-z0-9]")) {
            hitterms = (hitterms == "" ? term[i] : hitterms "," term[i])
            if (count >= 2 || (meaning[i] in seen)) continue
            seen[meaning[i]] = 1
            entry = term[i] " = " meaning[i]
            out = (out == "" ? entry : out " · " entry)
            count++
        }
    }
    if (out != "") print hitterms "\t[glossary] " out
}')

[ -z "$RESULT" ] && exit 0
HITTERMS=${RESULT%%$'\t'*}
echo "${RESULT#*$'\t'}"

# usage ledger: one line per injected term (ts, term, session) — read by
# glossary-decay.sh for the dormancy review. Never let it break hinting.
{
    HITLOG="${GLOSSARY_HITLOG:-$HOME/.claude/style/glossary-hit-log.tsv}"
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    IFS=',' read -ra HT <<< "$HITTERMS"
    for t in "${HT[@]}"; do
        printf '%s\t%s\t%s\n' "$TS" "$t" "${CLAUDE_CODE_SESSION_ID:-}" >> "$HITLOG"
    done
} 2>/dev/null || true
