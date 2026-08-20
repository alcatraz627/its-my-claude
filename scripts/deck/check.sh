#!/usr/bin/env bash
# check.sh — measure a rendered deck the way the room will see it: headless Chrome
# opens deck.html?check=1, the page measures every slide's real overflow and writes
# the report into the DOM, and this prints it. Then one screenshot per theme of the
# first over-budget slide (or slide 1) lands beside the deck for the agent to LOOK at.
# Usage: check.sh deck.html [--first]   (default: every slide, both themes; --first: slide 1 or the first over-budget slide only)
set -uo pipefail
DECK="${1:-}"; [ -f "$DECK" ] || { echo "check.sh: need a deck.html" >&2; exit 2; }
ALL=1; [ "${2:-}" = "--first" ] && ALL=0    # every slide by default (vb-fable: slide 1 only was not a visual pass); --first for speed
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[ -x "$CHROME" ] || CHROME=$(command -v google-chrome chromium 2>/dev/null | head -1)
[ -x "${CHROME:-}" ] || { echo "check.sh: no Chrome; render.py's estimate is the only overflow signal" >&2; exit 3; }
ABS=$(cd "$(dirname "$DECK")" && pwd)/$(basename "$DECK"); DIR=$(dirname "$ABS"); OUT="$DIR/check"; mkdir -p "$OUT"; printf "*\n" > "$OUT/.gitignore"   # screenshots are never committed; they are stale the moment a slide moves
rc=0
for size in 1440,900 1920,1080; do
  dom=$("$CHROME" --headless=new --disable-gpu --no-sandbox --window-size=$size --virtual-time-budget=1500 --dump-dom "file://$ABS?check=1" 2>/dev/null)
  rep=$(printf '%s' "$dom" | python3 -c '
import sys,re,html,json
m=re.search(r"<pre id=\"deck-check\">(.*?)</pre>",sys.stdin.read(),re.S)
print(html.unescape(m.group(1)) if m else "[]")')
  echo "== ${size} =="
  printf '%s' "$rep" | python3 -c '
import sys,json
r=json.load(sys.stdin); bad=[x for x in r if x["over"]]
for x in r:
    print("  %2d %s %4d/%-4d %s" % (x["slide"], "OVER " if x["over"] else "ok   ", x["scroll"], x["client"], x["title"]))
print("  %d over of %d" % (len(bad), len(r))); sys.exit(1 if bad else 0)' || rc=1
done
first=$(printf '%s' "$rep" | python3 -c 'import sys,json; r=json.load(sys.stdin); b=[x["slide"] for x in r if x["over"]]; print(b[0] if b else 1)')
shots=$( [ $ALL = 1 ] && printf '%s' "$rep" | python3 -c 'import sys,json; print(" ".join(str(x["slide"]) for x in json.load(sys.stdin)))' || echo "$first")
for s in $shots; do for theme in dark light; do
  q="s=$s"; [ $theme = light ] && q="$q&light=1"
  "$CHROME" --headless=new --disable-gpu --no-sandbox --window-size=1440,900 --virtual-time-budget=1500 --screenshot="$OUT/slide-$s-$theme.png" "file://$ABS?$q" >/dev/null 2>&1
done; done
echo "screenshots: $OUT/ ($(ls "$OUT" | wc -l | tr -d ' ') files); LOOK at them before calling the deck done"
exit $rc
