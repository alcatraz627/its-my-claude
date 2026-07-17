#!/usr/bin/env bash
# Dormancy report for the injected steering vocabulary — the decay half of
# "vocabulary is not grow-only." Reads the hinter's usage ledger and the hints
# table, and names the terms that earned no injections in the window so the
# weekly review can retire or pin them. Reports only; a human retires.
#
# Usage: glossary-decay.sh [--window-days 28]
# Data:  style/glossary-hit-log.tsv  (ts<TAB>term<TAB>session — hinter-appended)
#        style/glossary-hints.tsv    (col 4 "pin" exempts a term from dormancy)
# Wired into: thesaurus.sh review (weekly style triage).

set -uo pipefail

WINDOW=28
[ "${1:-}" = "--window-days" ] && WINDOW="${2:-28}"

HINTS="${GLOSSARY_HINTS:-$HOME/.claude/style/glossary-hints.tsv}"
HITLOG="${GLOSSARY_HITLOG:-$HOME/.claude/style/glossary-hit-log.tsv}"

[ -f "$HINTS" ] || { echo "no hints table at $HINTS"; exit 0; }
if [ ! -s "$HITLOG" ]; then
    echo "no usage telemetry yet (hit-log empty) — dormancy unjudgeable; skipping"
    exit 0
fi

# ISO-8601 UTC timestamps compare lexicographically — no date parsing needed.
CUTOFF=$(date -u -v-"${WINDOW}"d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
      || date -u -d "${WINDOW} days ago" +%Y-%m-%dT%H:%M:%SZ)
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
# min-scan, not head -1: the ledger is normally chronological but nothing
# enforces it, and future-dated entries (clock skew) must not count as usage.
OLDEST=$(cut -f1 "$HITLOG" | sort | head -1)

COVERED=1
if [[ "$OLDEST" > "$CUTOFF" ]]; then
    COVERED=0
    echo "note: telemetry starts $OLDEST (< ${WINDOW}d of coverage) — counts shown, dormancy verdicts withheld"
fi

awk -F'\t' -v hints="$HINTS" -v cutoff="$CUTOFF" -v now="$NOW" -v covered="$COVERED" '
BEGIN {
    n = 0
    while ((getline line < hints) > 0) {
        if (line ~ /^#/ || line == "") continue
        split(line, f, "\t")
        if (f[1] == "") continue
        # pin is hand-typed: trim + case-fold before matching, and warn on
        # any other non-empty value instead of silently treating it as auto.
        raw = f[4]; gsub(/^[ \t]+|[ \t]+$/, "", raw)
        n++; term[n] = f[1]; pin[n] = (tolower(raw) == "pin")
        if (raw != "" && !pin[n])
            printf "warning: unrecognized col-4 value %s on term %s (only \"pin\" pins; treated as auto)\n", raw, f[1] > "/dev/stderr"
    }
    close(hints)
}
$1 >= cutoff && $1 <= now { hits[$2]++; sess[$2 "\t" $3] = 1 }
END {
    for (k in sess) { split(k, kk, "\t"); nsess[kk[1]]++ }
    print "-- active (hits in window / distinct sessions) --"
    for (i = 1; i <= n; i++) if (hits[term[i]] > 0)
        printf "%4dx /%2d  %s%s\n", hits[term[i]], nsess[term[i]], term[i], (pin[i] ? "  [pin]" : "")
    if (covered) {
        print "-- dormant, unpinned (0 hits in window — retire or pin?) --"
        d = 0
        for (i = 1; i <= n; i++) if (!hits[term[i]] && !pin[i]) { print "     " term[i]; d++ }
        if (!d) print "     (none)"
        print "-- pinned + dormant (exempt, listed for awareness) --"
        pc = 0
        for (i = 1; i <= n; i++) if (!hits[term[i]] && pin[i]) { print "     " term[i]; pc++ }
        if (!pc) print "     (none)"
    }
}' "$HITLOG"
