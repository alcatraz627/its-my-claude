#!/usr/bin/env bash
# check.sh — measure a rendered deck the way the room will see it: headless Chrome
# opens deck.html?check=1, the page measures every slide's real overflow and writes
# the report into the DOM, and this prints it. Then one screenshot per theme of the
# first over-budget slide (or slide 1) lands beside the deck for the agent to LOOK at.
# Usage: check.sh deck.html [--first]   (default: every slide, both themes; --first: slide 1 or the first over-budget slide only)
set -uo pipefail
# Hidden verb for the --first picker, so tests drive the exact code the run uses:
# earliest over-budget slide across the reports IN ORDER (1440 first), else 1.
if [ "${1:-}" = "--__first" ]; then shift
  python3 -c '
import sys,json
for r in sys.argv[1:]:
    try: b=[x["slide"] for x in json.loads(r) if x["over"]]
    except Exception: b=[]
    if b: print(b[0]); sys.exit(0)
print(1)' "$@"; exit $?
fi
DECK="${1:-}"; [ -f "$DECK" ] || { echo "check.sh: need a deck.html" >&2; exit 2; }
ALL=1; [ "${2:-}" = "--first" ] && ALL=0    # every slide by default (vb-fable: slide 1 only was not a visual pass); --first for speed
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[ -x "$CHROME" ] || CHROME=$(command -v google-chrome chromium 2>/dev/null | head -1)
[ -x "${CHROME:-}" ] || { echo "check.sh: no Chrome; render.py's estimate is the only overflow signal" >&2; exit 3; }
ABS=$(cd "$(dirname "$DECK")" && pwd)/$(basename "$DECK"); DIR=$(dirname "$ABS"); OUT="$DIR/check"; mkdir -p "$OUT"; printf "*\n" > "$OUT/.gitignore"   # screenshots are never committed; they are stale the moment a slide moves
rc=0
# The overflow gate is only a gate when it measured something. Source truth for
# the slide count comes from the deck markup itself.
srccount=$(grep -c '<section class="slide ' "$ABS" 2>/dev/null || echo 0)
rep1440=""
for size in 1440,900 1920,1080; do
  dom=$("$CHROME" --headless=new --disable-gpu --no-sandbox --window-size=$size --virtual-time-budget=1500 --dump-dom "file://$ABS?check=1" 2>/dev/null)
  rep=$(printf '%s' "$dom" | python3 -c '
import sys,re,html,json
m=re.search(r"<pre id=\"deck-check\">(.*?)</pre>",sys.stdin.read(),re.S)
print(html.unescape(m.group(1)) if m else "[]")')
  [ "$size" = "1440,900" ] && rep1440="$rep"
  echo "== ${size} =="
  measured=$(printf '%s' "$rep" | python3 -c 'import sys,json; print(len(json.load(sys.stdin)))' 2>/dev/null || echo 0)
  if [ "$measured" -eq 0 ] || [ "$measured" -ne "$srccount" ]; then
    echo "  GATE FAILURE: measured $measured slide(s), source has $srccount — the page never ran its check=1 measurement; a pass off nothing measured is a lie"
    rc=1
  fi
  printf '%s' "$rep" | python3 -c '
import sys,json
r=json.load(sys.stdin); bad=[x for x in r if x["over"]]
for x in r:
    print("  %2d %s %4d/%-4d %s" % (x["slide"], "OVER " if x["over"] else "ok   ", x["scroll"], x["client"], x["title"]))
print("  %d over of %d" % (len(bad), len(r))); sys.exit(1 if bad else 0)' || rc=1
done
# Screenshots land at 1440, so the 1440 report picks the slide; 1920 only as fallback.
first=$(bash "$0" --__first "$rep1440" "$rep")
shots=$( [ $ALL = 1 ] && printf '%s' "$rep" | python3 -c 'import sys,json; print(" ".join(str(x["slide"]) for x in json.load(sys.stdin)))' || echo "$first")
for s in $shots; do for theme in dark light; do
  q="s=$s"; [ $theme = light ] && q="$q&light=1"
  "$CHROME" --headless=new --disable-gpu --no-sandbox --window-size=1440,900 --virtual-time-budget=1500 --screenshot="$OUT/slide-$s-$theme.png" "file://$ABS?$q" >/dev/null 2>&1
done; done
echo "screenshots: $OUT/ ($(ls "$OUT" | wc -l | tr -d ' ') files); LOOK at them before calling the deck done"
exit $rc
