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

printf '%s' "$PROMPT" | awk -F'\t' -v hints="$HINTS" '
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
    out = ""; count = 0
    for (i = 1; i <= n && count < 2; i++) {
        t = tolower(term[i])
        # word-boundary-ish match: term surrounded by non-alphanumerics
        if (match(prompt, "[^a-z0-9]" t "[^a-z0-9]") || match(prompt, "^" t "[^a-z0-9]")) {
            if (meaning[i] in seen) continue
            seen[meaning[i]] = 1
            entry = term[i] " = " meaning[i]
            out = (out == "" ? entry : out " · " entry)
            count++
        }
    }
    if (out != "") print "[glossary] " out
}'
