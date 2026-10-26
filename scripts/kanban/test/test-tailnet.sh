#!/usr/bin/env bash
# Checks the tailnet listener: decision pages reachable at this Mac's tailnet
# address, everything else 404, POSTs refused unless they come from a page this
# address served, loopback unchanged. Uses a scratch page it removes afterwards.
#   bash ~/.claude/scripts/kanban/test/test-tailnet.sh
set -uo pipefail

IP=$(tailscale ip -4 2>/dev/null | head -n 1)
[ -n "$IP" ] || { echo "SKIP: Tailscale has no address here, so there is no tailnet listener to test"; exit 0; }
T="http://$IP:5106"; L="http://127.0.0.1:5106"
REG="$HOME/.claude/assets/decision-pages"; SLUG="zz-tailnet-smoke"; PAGE="$REG/$SLUG"
pass=0; fail=0
code() { curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$@"; }
eq() { if [ "$2" = "$3" ]; then pass=$((pass+1)); printf 'ok   %s\n' "$1"; else fail=$((fail+1)); printf 'FAIL %s\n     want %s, got %s\n' "$1" "$3" "$2"; fi; }

[ -e "$PAGE" ] && { echo "refusing: $PAGE exists and this run did not make it" >&2; exit 2; }
mkdir -p "$PAGE"
printf '%s\n' '{"title":"Tailnet smoke","decisions":[{"id":"D1","options":[{"code":"a","rec":true}]}]}' > "$PAGE/config.json"
trap 'trash "$PAGE" >/dev/null 2>&1' EXIT

eq "tailnet: /dp/ lists pages"                    "$(code "$T/dp/")" 200
eq "tailnet: /dp lists pages, no redirect to /"   "$(code "$T/dp")" 200
eq "tailnet: a page loads"                        "$(code "$T/dp/$SLUG/")" 200
eq "tailnet: its config loads"                    "$(code "$T/dp/$SLUG/config.json")" 200
eq "tailnet: /dp/<slug> still adds its slash"     "$(code "$T/dp/$SLUG")" 301
case "$(curl -s --max-time 5 "$T/dp/")" in *"$T/dp/$SLUG/"*) eq "tailnet: listing links stay on the tailnet" 1 1 ;; *) eq "tailnet: listing links stay on the tailnet" 0 1 ;; esac

for p in / /doc /shared.css /shared.js /kinds.js /api/surfaces /b/x /api/boards /drafts; do
  eq "tailnet: $p is not served" "$(code "$T$p")" 404
done
eq "tailnet: POST /api/send is not served" "$(code -X POST "$T/api/send" -d '{}')" 404
eq "tailnet: POST /api/nudge is not served" "$(code -X POST "$T/api/nudge" -d '{}')" 404

eq "tailnet: POST with no Origin is refused"      "$(code -X POST "$T/api/dp-seen/$SLUG")" 403
eq "tailnet: POST from a foreign Origin is refused" "$(code -X POST -H 'Origin: http://evil.example' "$T/api/dp-seen/$SLUG")" 403
eq "tailnet: a refused submit is 403"             "$(code -X POST -H 'Origin: http://evil.example' -H 'content-type: application/json' -d '{"answer":"x"}' "$T/api/dp-submit/$SLUG")" 403
[ -f "$PAGE/.answer.json" ] && eq "tailnet: a refused submit wrote nothing" written none || eq "tailnet: a refused submit wrote nothing" none none
[ -f "$PAGE/.seen.json" ] && eq "tailnet: a refused seen wrote nothing" written none || eq "tailnet: a refused seen wrote nothing" none none
eq "tailnet: POST from the page's own origin works" "$(code -X POST -H "Origin: $T" "$T/api/dp-seen/$SLUG")" 200
eq "tailnet: compose from the page's own origin works" "$(code -X POST -H "Origin: $T" -H 'content-type: application/json' -d '{}' "$T/api/dp-compose/$SLUG")" 200

eq "loopback: / is still served"                  "$(code "$L/")" 200
eq "loopback: /dp/ still goes to the decisions view" "$(code "$L/dp/")" 302
eq "loopback: /api/surfaces still answers"        "$(code "$L/api/surfaces?previews=0")" 200

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
