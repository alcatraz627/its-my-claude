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
PEND="$REG/.pending.txt"          # one slug per line = "handed off, awaiting the human"
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
  # server.py: static GET (index.html on dir URLs) + POST /_submit/<slug> so a page
  # can hand its answer straight back to the agent. Not `pm2 serve` (EISDIRs on dir
  # URLs), not `-m http.server` (GET-only, no submit endpoint).
  if pm2 describe "$NAME" >/dev/null 2>&1; then
    if pm2 describe "$NAME" 2>/dev/null | grep -q "server.py"; then
      # A pm2 entry is not a live server: svc-reap leaves the entry STOPPED,
      # and this branch once printed "up" while the port was dead (2026-08-14,
      # mid-triage). The port is the truth; revive through svc.sh so the idle
      # bookkeeping stays correct, pm2 restart only as the fallback.
      if lsof -nP -iTCP:$PORT -sTCP:LISTEN >/dev/null 2>&1; then
        printf 'server: up — %s%s/%s\n' "$C" "$BASE" "$R"; return
      fi
      bash "$HOME/.claude/scripts/dev-servers/svc.sh" up "$NAME" >/dev/null 2>&1 \
        || pm2 restart "$NAME" >/dev/null 2>&1
      local i
      for i in 1 2 3 4 5; do
        lsof -nP -iTCP:$PORT -sTCP:LISTEN >/dev/null 2>&1 \
          && { printf 'server: revived — %s%s/%s\n' "$C" "$BASE" "$R"; return; }
        sleep 1
      done
      die "pm2 entry exists but port $PORT never came up" "pm2 logs $NAME --lines 20   # why it dies"
    fi
    # an older static (http.server) instance is running — upgrade it in place
    pm2 delete "$NAME" >/dev/null 2>&1
  elif lsof -nP -iTCP:$PORT -sTCP:LISTEN >/dev/null 2>&1; then
    die "port $PORT is taken by another process" "lsof -nP -iTCP:$PORT -sTCP:LISTEN   # see who; then free it or change PORT in $0"
  fi
  DP_PORT="$PORT" pm2 start "$HERE/server.py" --name "$NAME" --interpreter python3 >/dev/null
  printf 'server: started — %s%s/%s\n' "$C" "$BASE" "$R"
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
  local title="" topic="" sess=""
  while [ $# -gt 0 ]; do case "$1" in
    --title)   title="${2:?--title needs a value}"; shift 2 ;;
    --topic)   topic="${2:?--topic needs a value}"; shift 2 ;;
    --session) sess="${2:?--session needs a value}"; shift 2 ;;
    *) die "unknown flag for new: $1" "decision-page.sh new <slug> [--title \"…\"] [--topic \"…\"] [--session <id>]" ;;
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
  T="$title" SLUG="$slug" TOPIC="$topic" SESS="${sess:-${CLAUDE_SESSION_ID:-}}" \
  PROJ="${PWD/#$HOME/~}" CREATED="$(date +%Y-%m-%d)" \
  python3 - "$dir/config.json" <<'PY'
import json, os, sys
# origin: which session/project/topic created this page — shown on the page + hub
origin = {k: v for k, v in {
  "session": os.environ.get("SESS", ""), "project": os.environ.get("PROJ", ""),
  "topic": os.environ.get("TOPIC", ""), "created": os.environ.get("CREATED", ""),
}.items() if v}
cfg = {
  "title": os.environ["T"], "storageKey": os.environ["SLUG"],
  "copyHeader": "feedback", "intro": "Everything is pre-answered with a recommendation. Untouched = agreed.",
}
if origin: cfg["origin"] = origin
cfg["decisions"] = [
    {"id": "D1", "question": "The big call?", "context": "why it matters",
     "options": [{"code": "a", "label": "recommended option", "rec": True},
                  {"code": "b", "label": "alternative"}]}]
cfg["sections"] = [
    {"id": "item-01", "group": "Group A", "title": "First item", "prio": "MUST",
     "read": "my read of it", "images": [],
     "slots": {"KEEP": "…", "CHANGE": "…"}}]
json.dump(cfg, open(sys.argv[1], "w"), indent=2)
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
if "notes" in c and not isinstance(c["notes"], bool):
    probs.append("'notes' must be true/false (omit for the default: notes available on-demand)")
if "accent" in c and not isinstance(c["accent"], str):
    probs.append("'accent' must be a CSS color string, e.g. \"#7c3aed\"")
if "origin" in c and not isinstance(c["origin"], dict):
    probs.append("'origin' must be an object {session,project,topic,created}")
if "groups" in c and not isinstance(c["groups"], dict):
    probs.append("'groups' must be an object of group-name -> {context,color}")
ids = set()
for d in c.get("decisions") or []:
    if not d.get("id"): probs.append("a decision has no 'id'"); continue
    if d["id"] in ids: probs.append(f"duplicate id '{d['id']}'")
    ids.add(d["id"])
    if "note" in d and not isinstance(d["note"], str): probs.append(f"{d['id']}: 'note' must be a string")
    recs = [o for o in d.get("options") or [] if o.get("rec")]
    if not d.get("options"): probs.append(f"{d['id']}: no options")
    elif len(recs) != 1: probs.append(f"{d['id']}: needs exactly one option with rec:true (has {len(recs)})")
missing = []
for s in c.get("sections") or []:
    if not s.get("id"): probs.append("a section has no 'id'"); continue
    if s["id"] in ids: probs.append(f"duplicate id '{s['id']}'")
    ids.add(s["id"])
    if "note" in s and not isinstance(s["note"], str): probs.append(f"{s['id']}: 'note' must be a string")
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
  local pend=0; [ -f "$PEND" ] && pend=$(grep -cv '^[[:space:]]*$' "$PEND" 2>/dev/null); pend=${pend:-0}
  if [ "$pend" -gt 0 ]; then
    printf 'await:  %s%s awaiting an answer%s — %s\n' "$Y" "$pend" "$R" "$(grep -v '^[[:space:]]*$' "$PEND" 2>/dev/null | tr '\n' ' ')"
  fi
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

# ── pending ledger ──────────────────────────────────────────────────────────
# "handed off, awaiting the human's answer" — the answered/unanswered state
# lives in the human's browser localStorage, which a shell can't read, so the
# agent maintains this ledger explicitly: `pending add <slug>` on handoff,
# `pending clear <slug>` once the answer is pasted back. The statusline reads
# the line count of $PEND directly (no server, no python) to show a waiting chip.
cmd_pending() {
  local sub="${1:-list}"; shift 2>/dev/null || true
  mkdir -p "$REG"; touch "$PEND"
  case "$sub" in
    add)   local slug="${1:?usage: decision-page.sh pending add <slug>}"
           grep -qxF "$slug" "$PEND" || printf '%s\n' "$slug" >> "$PEND"
           printf 'pending: %s%s%s — clear once answered: decision-page.sh pending clear %s\n' "$Y" "$slug" "$R" "$slug"
           printf '  ARM THE WAKE IN THIS TURN — run this exact Bash call with run_in_background: true\n'
           printf '    until [ -f "%s/%s/.answer.json" ]; do sleep 5; done; echo "decision page %s answered"\n' "$REG" "$slug" "$slug"
           printf '  (it exits on submit and re-invokes you; the server also ipcs the origin session as backup.\n'
           printf '   an unarmed handoff means next-session pickup — say so to the human if you deliberately defer.)\n' ;;
    clear) local slug="${1:?usage: decision-page.sh pending clear <slug>}"
           local tmp="$PEND.$$.tmp"
           grep -vxF "$slug" "$PEND" > "$tmp" 2>/dev/null; mv -f "$tmp" "$PEND"
           printf 'cleared: %s\n' "$slug" ;;
    list)  grep -v '^[[:space:]]*$' "$PEND" 2>/dev/null || printf 'no pages awaiting an answer\n' ;;
    count) local n; n=$(grep -cv '^[[:space:]]*$' "$PEND" 2>/dev/null); printf '%s\n' "${n:-0}" ;;
    *)     die "unknown pending subcommand: $sub" "decision-page.sh pending add|clear|list|count [slug]" ;;
  esac
}

# ── answer (submit-to-wake) ──────────────────────────────────────────────────
# The server writes <slug>/.answer.json when the human clicks Submit. After
# handoff the agent watches for that file (Monitor tool or a poll of this command)
# and reads the answer here — no copy-paste needed. Exits non-zero until submitted.
cmd_answer() {
  local slug="${1:?usage: decision-page.sh answer <slug> [--consume] [--notify]}"; shift 2>/dev/null || true
  local consume=0 notify=0
  while [ $# -gt 0 ]; do case "$1" in
    --consume) consume=1 ;;
    --notify)  notify=1 ;;   # macOS banner confirming the read (no-op off macOS)
    *) die "unknown flag for answer: $1" "decision-page.sh answer <slug> [--consume] [--notify]" ;;
  esac; shift; done
  local f="$REG/$slug/.answer.json"
  [ -f "$f" ] || { printf 'no answer yet for %s%s%s — the human has not hit Submit\n' "$Y" "$slug" "$R" >&2; exit 1; }
  python3 - "$f" "$consume" "$notify" <<'PY'
import json, os, platform, shutil, subprocess, sys
f, consume, notify = sys.argv[1], sys.argv[2] == "1", sys.argv[3] == "1"
ans = json.load(open(f)).get("answer", "")
# macOS notification: title = originating session, subtitle = "answers read",
# body = the page topic. Built-in osascript banner — temporary, auto-dismisses.
if notify and platform.system() == "Darwin" and shutil.which("osascript"):
    origin = {}
    try:
        origin = (json.load(open(os.path.join(os.path.dirname(f), "config.json"))) or {}).get("origin") or {}
    except (OSError, ValueError):
        pass
    slug = os.path.basename(os.path.dirname(f))
    topic, session = origin.get("topic") or "", origin.get("session") or ""
    # lead with the topic (the "which decision"); show the session for
    # multi-session disambiguation without repeating it in the title.
    title = topic or session or slug
    body = f"from {session}" if session and session != title else ""
    esc = lambda s: str(s).replace("\\", "\\\\").replace('"', '\\"')
    script = (f'display notification "{esc(body)}" with title "{esc(title)}" '
              f'subtitle "Claude read your answers"')
    try:
        subprocess.run(["osascript", "-e", script], timeout=5, check=False)
    except (OSError, subprocess.SubprocessError):
        pass
print(ans)
if consume:
    os.remove(f)   # read-once so a later Submit is detectable as a new file
PY
}

usage() {
  cat <<EOT
${B}decision-page.sh${R} — pre-answered feedback pages a human can answer in one paste

${Y}commands${R}
  ${B}new${R} <slug> [--title "…"]   scaffold a page + print the agent TODO
  ${B}check${R} <slug>               verify: schema · images · renders  ${D}(run before handoff)${R}
  ${B}list${R}                       pages: slug · items · age · url · title
  ${B}open${R} [slug]                open the page (or the hub) in the browser
  ${B}status${R}                     server + page count + pages awaiting an answer
  ${B}serve${R}                      ensure the registry server (pm2, :$PORT)
  ${B}pending${R} <add|clear|list|count> [slug]   mark/unmark "handed off, awaiting the human"
  ${B}answer${R} <slug> [--consume] [--notify]  print the answer the human Submitted (exits 1 until they do); --notify pops a macOS banner
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
  pending) shift; cmd_pending "$@" ;;
  answer) shift; cmd_answer "$@" ;;
  rm)     slug="${2:?usage: decision-page.sh rm <slug>}"
          trash "$REG/$slug" 2>/dev/null && echo "trashed: $slug" || echo "not found: $REG/$slug"
          [ -f "$PEND" ] && { grep -vxF "$slug" "$PEND" > "$PEND.$$.tmp" 2>/dev/null; mv -f "$PEND.$$.tmp" "$PEND"; }
          regen_manifest ;;
  prune)  shift; cmd_prune "$@" ;;
  help|-h|--help) usage ;;
  *) die "unknown command: $1" "decision-page.sh help" ;;
esac
