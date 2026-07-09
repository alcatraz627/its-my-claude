#!/bin/bash
# decision-page.sh — interactive decision/feedback pages for a human, driven by agents.
#
# An agent that needs structured human feedback on many items (design reviews,
# migration plans, per-screen verdicts) creates a page instead of asking N
# questions: every item pre-answered with a recommendation, the human flips
# what's wrong and pastes ONE compact answer string back into chat.
#
# Registry: ~/.claude/assets/decision-pages/<slug>/  (index.html + config.json
# + any images). One pm2 static server ("decision-pages", port 5197) serves the
# whole registry; the registry ROOT is a hub page (index.html + pages.json)
# listing every page with live progress. Pages are temporary — prune freely.
#
# Agent contract: `new` scaffolds and prints the TODO; `check <slug>` is the one
# verification call (config parses, schema sane, images exist, page renders) and
# every failure proposes its fix. Never hand a human an unchecked page.
#
# Config schema + answer-string shape: ~/.claude/features/decision-pages.md

set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REG="$HOME/.claude/assets/decision-pages"
PORT=5197
NAME="decision-pages"
BASE="http://localhost:$PORT"

# TTY-gated palette (std::claude::tui) — vars are empty when piped, so callsites never branch.
if [ -f "$HOME/.claude/scripts/tui/colors.sh" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.claude/scripts/tui/colors.sh" && tui_colors_init
else
  B=''; Y=''; C=''; D=''; R=''; G=''; RED=''
fi

die() { printf '%serror:%s %s\n' "$RED" "$R" "$1" >&2; [ -n "${2:-}" ] && printf '%sfix:%s   %s\n' "$Y" "$R" "$2" >&2; exit 1; }

# ── manifest + hub ──────────────────────────────────────────────────────────
# pages.json is what the hub renders; regenerated on every mutating op so the
# hub is never stale. Atomic write (tmp+mv) — the server may be reading it.
regen_manifest() {
  mkdir -p "$REG"
  python3 - "$REG" <<'PY'
import json, os, sys, time
reg = sys.argv[1]
pages = []
for slug in sorted(os.listdir(reg)):
    d = os.path.join(reg, slug)
    cfg = os.path.join(d, "config.json")
    if not os.path.isdir(d) or not os.path.exists(cfg): continue
    entry = {"slug": slug, "title": slug, "storageKey": slug,
             "decisions": 0, "sections": 0, "mtime": int(os.path.getmtime(cfg))}
    try:
        c = json.load(open(cfg))
        entry["title"] = c.get("title") or slug
        entry["storageKey"] = c.get("storageKey") or c.get("title") or "default"
        entry["decisions"] = len(c.get("decisions") or [])
        entry["sections"] = len(c.get("sections") or [])
        entry["copyHeader"] = c.get("copyHeader") or ""
    except Exception as e:
        entry["broken"] = str(e)
    pages.append(entry)
tmp = os.path.join(reg, ".pages.json.tmp")
json.dump({"generated": int(time.time()), "pages": pages}, open(tmp, "w"), indent=1)
os.replace(tmp, os.path.join(reg, "pages.json"))
print(f"manifest: {len(pages)} page(s)")
PY
  # the hub template lives here; the copy in the registry root is disposable
  cp -f "$HERE/hub.html" "$REG/index.html"
}

ensure_server() {
  mkdir -p "$REG"
  if pm2 describe "$NAME" >/dev/null 2>&1; then
    printf 'server: up — %s%s/%s\n' "$C" "$BASE" "$R"
  else
    if lsof -nP -iTCP:$PORT -sTCP:LISTEN >/dev/null 2>&1; then
      die "port $PORT is taken by another process" "lsof -nP -iTCP:$PORT -sTCP:LISTEN   # see who; then free it or change PORT in $0"
    fi
    # python http.server (not `pm2 serve`): pm2's static server EISDIRs on
    # directory URLs instead of resolving index.html.
    pm2 start python3 --name "$NAME" -- -m http.server "$PORT" -d "$REG" >/dev/null
    printf 'server: started — %s%s/%s\n' "$C" "$BASE" "$R"
  fi
}

age_of() { # humanize mtime of a path
  python3 - "$1" <<'PY'
import os, sys, time
s = int(time.time() - os.path.getmtime(sys.argv[1]))
for div, unit in ((86400, "d"), (3600, "h"), (60, "m")):
    if s >= div: print(f"{s//div}{unit}"); break
else: print(f"{s}s")
PY
}

# ── commands ────────────────────────────────────────────────────────────────
cmd_new() {
  local slug="${1:-}"; shift || true
  local title=""
  while [ $# -gt 0 ]; do case "$1" in
    --title) title="${2:?--title needs a value}"; shift 2 ;;
    *) die "unknown flag for new: $1" "decision-page.sh new <slug> [--title \"…\"]" ;;
  esac; done
  [ -n "$slug" ] || die "new needs a slug" "decision-page.sh new <slug> [--title \"…\"]"
  printf '%s' "$slug" | grep -qE '^[a-z0-9][a-z0-9._-]*$' \
    || die "bad slug '$slug' (lowercase kebab: a-z 0-9 . _ -)" "try: $(printf '%s' "$slug" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9._-')"
  local dir="$REG/$slug"
  if [ -e "$dir" ]; then
    die "page '$slug' already exists ($(age_of "$dir") old)" \
        "inspect: decision-page.sh check $slug · open: decision-page.sh open $slug · replace: decision-page.sh rm $slug first"
  fi
  mkdir -p "$dir"
  cp -f "$HERE/template.html" "$dir/index.html"
  # NB: no ${title:-…} here — bash honors quotes INSIDE ${…} even under double
  # quotes, so an apostrophe in the default text breaks the parse of the file.
  [ -n "$title" ] || title="TITLE — every answer drafted; flip what needs changing"
  T="$title" SLUG="$slug" python3 - "$dir/config.json" <<'PY'
import json, os, sys
json.dump({
  "title": os.environ["T"], "storageKey": os.environ["SLUG"],
  "copyHeader": "feedback", "intro": "Everything is pre-answered with a recommendation. Untouched = agreed.",
  "decisions": [
    {"id": "D1", "question": "The big call?", "context": "why it matters",
     "options": [{"code": "a", "label": "recommended option", "rec": True},
                  {"code": "b", "label": "alternative"}]}],
  "sections": [
    {"id": "item-01", "group": "Group A", "title": "First item", "prio": "MUST",
     "read": "my read of it", "images": [],
     "slots": {"KEEP": "…", "CHANGE": "…"}}],
}, open(sys.argv[1], "w"), indent=2)
PY
  ensure_server; regen_manifest
  cat <<EOT

scaffolded: $dir
${B}agent TODO:${R}
  1. Write the real $dir/config.json  (schema: features/decision-pages.md)
  2. Drop referenced images into $dir/
  3. ${B}Verify:${R} decision-page.sh check $slug     ${D}(one call: schema + images + render)${R}
  4. Hand the human: ${C}$BASE/$slug/${R}   ${D}(hub: $BASE/)${R}
EOT
}

cmd_check() {
  local slug="${1:?usage: decision-page.sh check <slug>}"
  local dir="$REG/$slug"
  [ -d "$dir" ] || die "no page '$slug'" "existing pages: $(ls "$REG" 2>/dev/null | rg -v '^(index.html|pages.json)$' | tr '\n' ' ')— or scaffold: decision-page.sh new $slug"
  local fails=0
  # 1. config parses + schema-lite, with fix-proposing messages
  python3 - "$dir/config.json" <<'PY' || fails=1
import json, os, sys
p = sys.argv[1]
try:
    c = json.load(open(p))
except Exception as e:
    print(f"FAIL config.json does not parse: {e}")
    print(f"  fix: edit {p} — check trailing commas / quotes near the position above")
    sys.exit(1)
probs = []
if not c.get("title"): probs.append("missing 'title'")
if not (c.get("decisions") or c.get("sections")): probs.append("needs at least one of 'decisions' / 'sections'")
ids = set()
for d in c.get("decisions") or []:
    if not d.get("id"): probs.append("a decision has no 'id'"); continue
    if d["id"] in ids: probs.append(f"duplicate id '{d['id']}'")
    ids.add(d["id"])
    recs = [o for o in d.get("options") or [] if o.get("rec")]
    if not d.get("options"): probs.append(f"{d['id']}: no options")
    elif len(recs) != 1: probs.append(f"{d['id']}: needs exactly one option with rec:true (has {len(recs)})")
missing = []
for s in c.get("sections") or []:
    if not s.get("id"): probs.append("a section has no 'id'"); continue
    if s["id"] in ids: probs.append(f"duplicate id '{s['id']}'")
    ids.add(s["id"])
    for im in s.get("images") or []:
        if not os.path.exists(os.path.join(os.path.dirname(p), im)): missing.append(f"{s['id']}: {im}")
for m in probs: print(f"FAIL schema: {m}")
if missing:
    print("FAIL missing images: " + ", ".join(missing))
    print(f"  fix: drop the files into {os.path.dirname(p)}/ or remove them from 'images'")
if probs or missing: sys.exit(1)
d, s = len(c.get("decisions") or []), len(c.get("sections") or [])
print(f"ok  config: {d} decision(s), {s} section(s), title: {c['title'][:60]}")
PY
  # 2. serving + rendering
  ensure_server >/dev/null
  local code; code=$(curl -so /dev/null -w '%{http_code}' "$BASE/$slug/" 2>/dev/null || echo 000)
  if [ "$code" = "200" ]; then printf 'ok  renders: %s/%s/ (HTTP 200)\n' "$BASE" "$slug"
  else printf 'FAIL not serving (HTTP %s)\n  fix: decision-page.sh serve   # then re-check\n' "$code"; fails=1; fi
  regen_manifest >/dev/null
  if [ "$fails" = 0 ]; then
    printf '%sREADY%s — hand the human: %s%s/%s/%s\n' "$G" "$R" "$C" "$BASE" "$slug" "$R"
  else
    printf '%sNOT READY%s — fix the FAIL lines above, then: decision-page.sh check %s\n' "$RED" "$R" "$slug"; exit 1
  fi
}

cmd_list() {
  ensure_server >/dev/null; regen_manifest >/dev/null
  local any=0
  for d in "$REG"/*/; do
    [ -d "$d" ] || continue
    local s; s="$(basename "$d")"
    local items; items=$(python3 -c 'import json,sys;c=json.load(open(sys.argv[1]));print(str(len(c.get("decisions") or []))+"d+"+str(len(c.get("sections") or []))+"s")' "$d/config.json" 2>/dev/null || echo "?")
    local title; title=$(python3 -c 'import json,sys;print((json.load(open(sys.argv[1])).get("title") or "")[:48])' "$d/config.json" 2>/dev/null || echo "(broken config)")
    printf '%s%-22s%s %-8s %-5s %s%s/%s/%s  %s%s%s\n' "$B" "$s" "$R" "$items" "$(age_of "$d")" "$C" "$BASE" "$s" "$R" "$D" "$title" "$R"
    any=1
  done
  [ "$any" = 1 ] || printf 'no pages yet — scaffold one: decision-page.sh new <slug>\n'
  printf '%shub:%s %s%s/%s\n' "$D" "$R" "$C" "$BASE" "$R"
}

cmd_status() {
  if pm2 describe "$NAME" >/dev/null 2>&1; then printf 'server: %sup%s (pm2 "%s", port %s)\n' "$G" "$R" "$NAME" "$PORT"
  else printf 'server: %sdown%s — start: decision-page.sh serve\n' "$RED" "$R"; fi
  local n; n=$(ls -d "$REG"/*/ 2>/dev/null | wc -l | tr -d ' ')
  printf 'pages:  %s  ·  hub: %s%s/%s\n' "$n" "$C" "$BASE" "$R"
}

cmd_prune() {
  local days=""
  while [ $# -gt 0 ]; do case "$1" in
    --older-than) days="${2:?--older-than needs days}"; shift 2 ;;
    *) die "unknown flag for prune: $1" "decision-page.sh prune --older-than <days>" ;;
  esac; done
  [ -n "$days" ] || die "prune needs --older-than <days>" "decision-page.sh prune --older-than 14"
  local victims; victims=$(find "$REG" -mindepth 1 -maxdepth 1 -type d -mtime "+$days" 2>/dev/null)
  [ -n "$victims" ] || { echo "nothing older than ${days}d — registry is clean"; exit 0; }
  printf 'would remove:\n%s\n' "$victims"
  if [ -t 0 ] && [ -f "$HOME/.claude/scripts/tui/pick.sh" ]; then
    . "$HOME/.claude/scripts/tui/pick.sh"
    tui_confirm "trash these $(echo "$victims" | wc -l | tr -d ' ') page(s)?" || { echo "aborted"; exit 1; }
  fi
  echo "$victims" | while IFS= read -r v; do trash "$v" && echo "trashed: $(basename "$v")"; done
  regen_manifest
}

usage() {
  cat <<EOT
${B}decision-page.sh${R} — pre-answered feedback pages a human can answer in one paste

${Y}commands${R}
  ${B}new${R} <slug> [--title "…"]   scaffold a page + print the agent TODO
  ${B}check${R} <slug>               verify: schema · images · renders  ${D}(run before handoff)${R}
  ${B}list${R}                       pages: slug · items · age · url · title
  ${B}open${R} [slug]                open the page (or the hub) in the browser
  ${B}status${R}                     server + page count
  ${B}serve${R}                      ensure the registry server (pm2, :$PORT)
  ${B}rm${R} <slug>                  trash a page
  ${B}prune${R} --older-than <days>  trash old pages (confirms on a TTY)

${Y}surfaces${R}
  hub   ${C}$BASE/${R}          every page + live progress + copy-from-hub
  page  ${C}$BASE/<slug>/${R}   keyboard-first: press ${B}?${R} on the page for shortcuts

${D}schema + answer-string shape: features/decision-pages.md${R}
EOT
}

case "${1:-help}" in
  new)    shift; cmd_new "$@" ;;
  check)  shift; cmd_check "$@" ;;
  serve)  ensure_server; regen_manifest ;;
  list)   cmd_list ;;
  status) cmd_status ;;
  open)   ensure_server >/dev/null; regen_manifest >/dev/null; open "$BASE/${2:+$2/}" ;;
  rm)     slug="${2:?usage: decision-page.sh rm <slug>}"
          trash "$REG/$slug" 2>/dev/null && echo "trashed: $slug" || echo "not found: $REG/$slug"
          regen_manifest ;;
  prune)  shift; cmd_prune "$@" ;;
  help|-h|--help) usage ;;
  *) die "unknown command: $1" "decision-page.sh help" ;;
esac
