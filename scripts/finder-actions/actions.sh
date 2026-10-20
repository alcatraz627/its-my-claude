#!/bin/bash
# The Finder quick actions that need more than one line. Each verb takes the
# files selected in Finder as arguments and reports back with a notification.
# Usage: actions.sh <verb> <files...>
#   contents | repo-path | github | sha | exec | reset-view | taildrop | csync
#   resize | copy-image | pdf <merge|shrink|images>
export PATH="/opt/homebrew/bin:$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
CSYNC="$HOME/Code/Claude/csync/bin/csync"
verb="$1"
shift

notify() { osascript -e "display notification \"$1\" with title \"Finder\"" >/dev/null; }

# The folder an action works on: a selected folder itself, or the one holding the file.
target_dir() { if [ -d "$1" ]; then echo "$1"; else dirname "$1"; fi; }

# Shows a list and prints the picked line, or nothing when cancelled.
pick() {
  prompt="$1"
  shift
  osascript - "$prompt" "$@" <<'AS'
on run argv
	set r to choose from list (rest of argv) with prompt (item 1 of argv)
	if r is false then return ""
	return item 1 of r
end run
AS
}

case "$verb" in
  contents)
    skipped=0
    out=""
    for f in "$@"; do
      if [ -d "$f" ] || [ "$(file -b --mime-encoding "$f")" = "binary" ]; then
        skipped=$((skipped + 1))
        continue
      fi
      if [ $# -gt 1 ]; then out+="==> $f <=="$'\n'; fi
      out+="$(cat "$f")"$'\n'
    done
    if [ -z "$out" ]; then notify "Nothing copied: not a text file"; exit 1; fi
    printf "%s" "${out%$'\n'}" | pbcopy
    if [ "$skipped" -gt 0 ]; then notify "Contents copied, $skipped non-text skipped"; else notify "Contents copied"; fi
    ;;

  repo-path)
    out=""
    for f in "$@"; do
      root=$(git -C "$(target_dir "$f")" rev-parse --show-toplevel 2>/dev/null)
      if [ -z "$root" ]; then notify "Not inside a git repo"; exit 1; fi
      rel="${f#"$root"}"
      rel="${rel#/}"
      out+="${rel:-.}"$'\n'
    done
    printf "%s" "${out%$'\n'}" | pbcopy
    notify "Repo path copied"
    ;;

  github)
    f="$1"
    dir=$(target_dir "$f")
    root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)
    if [ -z "$root" ]; then notify "Not inside a git repo"; exit 1; fi
    rel="${f#"$root"}"
    rel="${rel#/}"
    branch=$(git -C "$root" branch --show-current)
    cd "$root" || exit 1
    if ! err=$(gh browse ${rel:+"$rel"} ${branch:+--branch "$branch"} 2>&1); then
      notify "GitHub: ${err//\"/}"
      exit 1
    fi
    ;;

  sha)
    if [ $# -eq 1 ]; then
      shasum -a 256 "$1" | cut -d' ' -f1 | tr -d '\n' | pbcopy
    else
      shasum -a 256 "$@" | pbcopy
    fi
    notify "SHA-256 copied"
    ;;

  exec)
    chmod +x "$@" && notify "Made executable: $# file(s)"
    ;;

  reset-view)
    # Finder keeps a folder's view in memory and writes .DS_Store later, so
    # trashing the file alone changes nothing. Re-apply the default arrangement too.
    d=$(target_dir "$1")
    if [ -f "$d/.DS_Store" ]; then trash "$d/.DS_Store"; fi
    mode=$(/usr/libexec/PlistBuddy -c "Print :StandardViewSettings:IconViewSettings:arrangeBy" "$HOME/Library/Preferences/com.apple.finder.plist" 2>/dev/null)
    osascript "$(dirname "$0")/grid.applescript" "$d" "${mode:-none}" >/dev/null
    notify "View reset to the default (${mode:-none})"
    ;;

  taildrop)
    targets=()
    while IFS=$'\t' read -r _ name state; do
      [ -z "$state" ] && targets+=("$name")
    done < <(tailscale file cp --targets)
    if [ ${#targets[@]} -eq 0 ]; then notify "No Taildrop device is online"; exit 1; fi
    host=$(pick "Send with Taildrop to:" "${targets[@]}")
    [ -z "$host" ] && exit 0
    if err=$(tailscale file cp "$@" "$host:" 2>&1); then notify "Sent to $host"; else notify "Taildrop failed: ${err//\"/}"; exit 1; fi
    ;;

  csync)
    hosts=()
    while read -r h; do hosts+=("$h"); done < <("$CSYNC" --json ls | jq -r '.hosts | to_entries[] | select(.value.status == "online") | .key')
    if [ ${#hosts[@]} -eq 0 ]; then notify "No csync host is online"; exit 1; fi
    host=$(pick "Send with csync to (lands in Downloads/csync):" "${hosts[@]}")
    [ -z "$host" ] && exit 0
    # A person clicked this, but Finder gives it no terminal, which csync reads as an agent.
    if err=$(CSYNC_ACTOR=human "$CSYNC" push "$host" "$@" 2>&1); then notify "Sent to $host"; else notify "csync failed: ${err//\"/}"; exit 1; fi
    ;;

  resize)
    # Asks once for a width ("1200") or a scale ("50%"), keeps the aspect ratio,
    # and writes "name (resized).ext" beside each image.
    # RESIZE_TO skips the dialog, for running it from a terminal.
    answer="${RESIZE_TO:-$(osascript -e 'text returned of (display dialog "New width in pixels, or a percentage:" default answer "50%" with title "Resize Image")' 2>/dev/null)}"
    [ -z "$answer" ] && exit 0
    done_n=0
    for f in "$@"; do
      w=$(sips -g pixelWidth "$f" 2>/dev/null | awk '/pixelWidth/ {print $2}')
      [ -z "$w" ] && continue
      case "$answer" in
        *%) target=$(( w * ${answer%\%} / 100 )) ;;
        *) target="$answer" ;;
      esac
      stem="${f%.*}"
      ext="${f##*.}"
      out="$stem (resized).$ext"
      n=2
      while [ -e "$out" ]; do out="$stem (resized $n).$ext"; n=$((n + 1)); done
      sips --resampleWidth "$target" "$f" --out "$out" >/dev/null && done_n=$((done_n + 1))
    done
    notify "Resized $done_n image(s)"
    ;;

  copy-image)
    # Puts the picture itself on the clipboard, so it pastes into chats and docs as an image.
    osascript -l JavaScript -e 'ObjC.import("AppKit"); function run(a){ const img = $.NSImage.alloc.initWithContentsOfFile(a[0]); if (img.isNil()) return "no"; const pb = $.NSPasteboard.generalPasteboard; pb.clearContents; pb.writeObjects($([img])); return "ok"; }' "$1" | grep -q ok && notify "Image copied" || notify "Not an image"
    ;;

  pdf)
    job="$1"
    shift
    if out=$(osascript -l JavaScript "$(dirname "$0")/pdf.js" "$job" "$@" 2>&1); then
      open -R "$(printf "%s" "$out" | head -1)"
    else
      notify "PDF: ${out//\"/}"
      exit 1
    fi
    ;;

  *)
    echo "unknown verb: $verb" >&2
    exit 2
    ;;
esac
