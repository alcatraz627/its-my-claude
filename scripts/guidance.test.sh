#!/usr/bin/env bash
export HOOK_TEST=1  # keeps the ledger write in `relevant` out of the live hook log
# guidance.sh relevant: a note applies when one of its scope keywords appears in
# the prompt as a whole word or phrase, and `all` always applies.
set -uo pipefail
G="${GUIDANCE_SH:-$HOME/.claude/scripts/guidance.sh}"
T=$(mktemp -d)
export GUIDANCE_NOTES="$T/notes.md"

pass=0 fail=0
ok()   { pass=$((pass+1)); echo "ok   $1"; }
bad()  { fail=$((fail+1)); echo "FAIL $1"; }
# hit/miss call the matcher directly: prompt, scope list.
hit()  { ( GUIDANCE_SOURCE_ONLY=1 . "$G"; scope_matches "$2" "$3" ) && ok "$1" || bad "$1"; }
miss() { ( GUIDANCE_SOURCE_ONLY=1 . "$G"; scope_matches "$2" "$3" ) && bad "$1" || ok "$1"; }

PORT="port, ports, dev server, dev-server, next dev, http.server"
hit  "port alone fires"                      "what port is it on"        "$PORT"
hit  "port 5100 fires"                       "use port 5100 for it"      "$PORT"
miss "report does not fire port"             "write the report today"    "$PORT"
miss "import / support / transport do not"   "import support transport" "$PORT"
miss "a prefix of a word does not fire"      "portable and portal"       "$PORT"
hit  "port, with a comma fires"              "check the port, then go"   "$PORT"
hit  "(port) in parentheses fires"           "the dev (port) is busy"    "$PORT"
hit  "port at the start and end fires"       "port"                      "$PORT"
hit  "case is ignored"                       "What PORT is it"           "$PORT"
hit  "a phrase fires when it appears"        "run next dev now"          "$PORT"
miss "next alone does not fire next dev"     "do the next thing"         "next dev, vite"
miss "dev alone does not fire next dev"      "a dev build"               "next dev, vite"
miss "words in the wrong order do not fire"  "dev next to it"            "next dev"
hit  "a phrase survives extra whitespace"    "run next   dev"            "next dev"
hit  "a hyphenated scope matches itself"     "start the dev-server"      "dev-server"
miss "a hyphenated scope is not its halves"  "the dev team"              "dev-server"
hit  "a hyphen is a word edge"               "port-forward it"           "port"
miss "an underscore is not a word edge"      "my_port_var"               "port"
hit  "a dot in a scope is literal"           "run http.server here"      "http.server"
miss "a dot in a scope is not a wildcard"    "run httpxserver here"      "http.server"
hit  "all always applies"                    "anything at all"           "all"
hit  "all applies to the empty prompt"       ""                          "all"
miss "a keyword never matches the empty prompt" ""                       "$PORT"
hit  "scope spacing is trimmed"              "use vite"                  " vite ,  pm2 "

# End to end through `relevant`: only the matching note prints.
printf -- '- 2026-07-10 [port, next dev] PORT-NOTE\n- 2026-07-11 [all] ALL-NOTE\n- 2026-07-12 [css] CSS-NOTE\n' > "$T/notes.md"
out=$(bash "$G" relevant "the report is ready")
[[ "$out" == *ALL-NOTE* && "$out" != *PORT-NOTE* && "$out" != *CSS-NOTE* ]] && ok "relevant: report shows only the all note" || bad "relevant: report shows only the all note: $out"
out=$(bash "$G" relevant "which port, and css")
[[ "$out" == *ALL-NOTE* && "$out" == *PORT-NOTE* && "$out" == *CSS-NOTE* ]] && ok "relevant: port and css show their notes" || bad "relevant: port and css: $out"
out=$(bash "$G" relevant "")
[[ "$out" == *ALL-NOTE* && "$out" != *PORT-NOTE* ]] && ok "relevant: empty prompt shows the all note" || bad "relevant: empty prompt: $out"

trash "$T" >/dev/null 2>&1
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
