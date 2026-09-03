#!/usr/bin/env bash
# ~/.claude/scripts/ntfsutil/ntfsutil.sh
#
# Mount/unmount external NTFS drives with read-write support, via a
# self-built ntfs-3g running on the already-installed FUSE-T. macOS's own
# NTFS driver is read-only; this exists to get write access without an
# App-Store/paid tool.
#
# Usage:
#   ntfsutil scan   [--json]
#   ntfsutil status [<identifier>] [--json]
#   ntfsutil mount   <identifier> [mountpoint] [--rw|--ro] [-f]
#   ntfsutil unmount <identifier|mountpoint> [-f]
#
# Every mount/unmount either confirms interactively or refuses outright —
# pass -f to skip the confirm and proceed past any detected warning. A few
# checks (internal disk, non-NTFS filesystem, missing driver) always refuse;
# -f cannot override those. See `ntfsutil -h` for the full picture.

set -euo pipefail

# Resolve through the zcmd PATH symlink to this script's real location —
# BSD readlink has no -f, so walk the link chain by hand (bash 3.2 safe).
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" && pwd)"
  _src="$(readlink "$_src")"
  [[ "$_src" != /* ]] && _src="$_dir/$_src"
done
SELF_DIR="$(cd -P "$(dirname "$_src")" && pwd)"
VENDOR_BIN="$SELF_DIR/vendor/bin"
DISKLIB="$SELF_DIR/disklib.py"
STATE_FILE="$SELF_DIR/state/mounts.json"

# shellcheck source=/dev/null
source ~/.claude/scripts/tui/colors.sh 2>/dev/null || true
# shellcheck source=/dev/null
source ~/.claude/scripts/tui/pick.sh 2>/dev/null || true
if declare -f tui_colors_init >/dev/null 2>&1; then tui_colors_init; fi

C_RED="${RED:-}"; C_YEL="${YEL:-}"; C_GRN="${GRN:-}"; C_CYA="${CYN:-}"; C_DIM="${DIM:-}"; C_RST="${RST:-}"

die()  { printf '%s✗ %s%s\n' "$C_RED" "$*" "$C_RST" >&2; exit 1; }
warn() { printf '%s  ! %s%s\n' "$C_YEL" "$*" "$C_RST" >&2; }
ok()   { printf '%s✓ %s%s\n' "$C_GRN" "$*" "$C_RST"; }
note() { printf '%s%s%s\n' "$C_DIM" "$*" "$C_RST"; }

require_deps() {
  command -v python3 >/dev/null || die "python3 is required and not on PATH."
  command -v jq >/dev/null || die "jq is required and not on PATH (brew install jq)."
}

# ── state file (tracks mounts THIS tool made, so unmount/status can find them) ──
#
# state_lock/state_unlock guard every read-modify-write with a mkdir-based
# lock (mkdir is atomic on POSIX; macOS ships no `flock` CLI). The temp file
# for the atomic replace is written IN the state dir, not $TMPDIR, so the
# final `mv` is a same-filesystem rename, not a cross-volume copy+unlink.

STATE_LOCK_DIR="$SELF_DIR/state/.lock"

state_lock() {
  local tries=0
  while ! mkdir "$STATE_LOCK_DIR" 2>/dev/null; do
    tries=$((tries + 1))
    [ "$tries" -gt 50 ] && die "Could not acquire the state lock after 5s — stale lock at $STATE_LOCK_DIR? Remove it by hand if no ntfsutil process is running."
    sleep 0.1
  done
  # A trap, not just the plain rmdir below — mktemp or mv failing between
  # lock and unlock aborts under set -e and would otherwise skip the
  # release, leaving a lock only a human could clear.
  trap 'rmdir "$STATE_LOCK_DIR" 2>/dev/null || true' EXIT
}
state_unlock() {
  rmdir "$STATE_LOCK_DIR" 2>/dev/null || true
  trap - EXIT
}

state_init() { [ -f "$STATE_FILE" ] || { mkdir -p "$(dirname "$STATE_FILE")"; echo '{}' > "$STATE_FILE"; }; }
state_get_mountpoint() { jq -r --arg id "$1" '.[$id].mountpoint // empty' "$STATE_FILE"; }
state_get_mode()       { jq -r --arg id "$1" '.[$id].mode // empty' "$STATE_FILE"; }
state_set() {
  local id="$1" mp="$2" mode="$3" tmp
  state_lock
  tmp="$(mktemp "$(dirname "$STATE_FILE")/.mounts.XXXXXX")"
  jq --arg id "$id" --arg mp "$mp" --arg mode "$mode" --arg ts "$(date -u +%FT%TZ)" \
    '.[$id] = {mountpoint:$mp, mode:$mode, ts:$ts}' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  state_unlock
}
state_remove_by_mountpoint() {
  local mp="$1" tmp
  state_lock
  tmp="$(mktemp "$(dirname "$STATE_FILE")/.mounts.XXXXXX")"
  jq --arg mp "$mp" 'with_entries(select(.value.mountpoint != $mp))' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  state_unlock
}

# ── disk facts ────────────────────────────────────────────────────────────

disk_info_json() { python3 "$DISKLIB" info "$1"; }
ntfs_list_json()  { python3 "$DISKLIB" list-ntfs; }

human_size() { numfmt --to=iec-i --suffix=B "$1" 2>/dev/null || echo "$1"; }

# Is $1 (a mount point path) currently a live mount, per `mount`?
is_live_mount() { local p="${1%/}"; mount | grep -qF " on $p "; }

# ── confirm gate: -f skips both the prompt and any detected warning ────────

confirm_or_refuse() {
  local prompt="$1" force="$2"
  shift 2
  local warnings=("$@")
  if [ ${#warnings[@]} -gt 0 ]; then
    for w in "${warnings[@]}"; do warn "$w"; done
    [ "$force" = "true" ] || die "Refused — re-run with -f to proceed despite the warning(s) above."
    return 0
  fi
  [ "$force" = "true" ] && return 0
  if declare -f tui_confirm >/dev/null 2>&1; then
    tui_confirm "$prompt" || die "Cancelled."
  else
    die "No confirmation UI available and no -f given — refusing. Re-run with -f."
  fi
}

# ── scan ─────────────────────────────────────────────────────────────────

cmd_scan() {
  local json=false
  [ "${1:-}" = "--json" ] && json=true
  local list; list="$(ntfs_list_json)"
  if [ "$json" = true ]; then echo "$list"; return; fi

  local count; count="$(echo "$list" | jq 'length')"
  if [ "$count" -eq 0 ]; then
    note "No NTFS partitions found. (Is the drive connected? Try 'diskutil list'.)"
    return
  fi
  printf "%-10s %-20s %8s  %-9s  %s\n" "DISK" "VOLUME" "SIZE" "MOUNTED" "MOUNT POINT"
  echo "$list" | jq -c '.[]' | while IFS= read -r row; do
    local id name size mp mounted
    id="$(echo "$row" | jq -r '.identifier')"
    name="$(echo "$row" | jq -r '.volume_name')"
    size="$(human_size "$(echo "$row" | jq -r '.size_bytes')")"
    mp="$(echo "$row" | jq -r '.mount_point')"
    mounted="no"; [ -n "$mp" ] && mounted="yes"
    printf "%-10s %-20s %8s  %-9s  %s\n" "$id" "$name" "$size" "$mounted" "${mp:--}"
  done
}

# ── status ───────────────────────────────────────────────────────────────

status_one() {
  local id="$1" json="$2"
  local info; info="$(disk_info_json "$id")"
  if [ "$info" = "null" ]; then
    # Degrade gracefully rather than die — this runs inside a multi-disk
    # loop where one vanished disk (unplugged between scan and here)
    # shouldn't kill the status of every other disk still connected.
    if [ "$json" = true ]; then
      jq -n --arg id "$id" '{identifier:$id, error:"no such disk identifier (disconnected?)"}'
    else
      echo "identifier:   $id"
      echo "error:        no such disk identifier (disconnected?)"
    fi
    return 0
  fi

  local native_mp; native_mp="$(echo "$info" | jq -r '.mount_point')"
  local state_mp; state_mp="$(state_get_mountpoint "$id")"
  local state_mode; state_mode="$(state_get_mode "$id")"

  local driver="not mounted" mountpoint="" mode=""
  if [ -n "$native_mp" ]; then
    driver="macOS native (read-only)"; mountpoint="$native_mp"; mode="ro"
  elif [ -n "$state_mp" ] && is_live_mount "$state_mp"; then
    driver="ntfs-3g via FUSE-T"; mountpoint="$state_mp"; mode="$state_mode"
  elif [ -n "$state_mp" ]; then
    # state says mounted but `mount` disagrees — it was unmounted outside ntfsutil
    state_remove_by_mountpoint "$state_mp"
  fi

  if [ "$json" = true ]; then
    echo "$info" | jq --arg driver "$driver" --arg mp "$mountpoint" --arg mode "$mode" \
      '. + {driver:$driver, active_mount_point:$mp, active_mode:$mode}'
    return
  fi

  local name; name="$(echo "$info" | jq -r '.volume_name')"
  local size; size="$(human_size "$(echo "$info" | jq -r '.size_bytes')")"
  local internal; internal="$(echo "$info" | jq -r '.internal')"
  echo "identifier:   $id"
  echo "volume:       $name  ($size)"
  echo "internal:     $internal"
  echo "driver:       $driver"
  if [ -n "$mountpoint" ]; then
    echo "mount point:  $mountpoint  (${mode})"
  fi
  return 0
}

cmd_status() {
  local id="" json=false
  for a in "$@"; do
    case "$a" in
      --json) json=true ;;
      *) id="$a" ;;
    esac
  done
  if [ -n "$id" ]; then
    # An explicit, user-named id gets a loud failure on a bad identifier;
    # status_one's own null-handling is for the enumerate-then-status loop
    # below, where one vanished disk shouldn't abort the rest.
    local explicit_check; explicit_check="$(disk_info_json "$id")"
    [ "$explicit_check" != "null" ] || die "No such disk identifier: $id"
    status_one "$id" "$json"
    return
  fi
  local list; list="$(ntfs_list_json)"
  local ids; ids="$(echo "$list" | jq -r '.[].identifier')"
  if [ -z "$ids" ]; then
    if [ "$json" = true ]; then echo "[]"; else note "No NTFS partitions found."; fi
    return
  fi
  if [ "$json" = true ]; then
    echo "$ids" | while IFS= read -r id; do status_one "$id" true; done | jq -s '.'
  else
    local first=true
    echo "$ids" | while IFS= read -r id; do
      [ "$first" = true ] || echo "---"
      first=false
      status_one "$id" false
    done
  fi
}

# ── mount ────────────────────────────────────────────────────────────────

cmd_mount() {
  local id="" mountpoint="" mode="ro" force=false
  local positional=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --rw) mode="rw" ;;
      --ro) mode="ro" ;;
      -f|--force) force=true ;;
      -h|--help) usage_mount; exit 0 ;;
      -*) die "Unknown option: $1" ;;
      *) positional+=("$1") ;;
    esac
    shift
  done
  id="${positional[0]:-}"; mountpoint="${positional[1]:-}"
  [ -n "$id" ] || { usage_mount; exit 1; }
  id="${id#/dev/}"

  local info; info="$(disk_info_json "$id")"
  [ "$info" != "null" ] || die "No such disk identifier: $id (run 'ntfsutil scan')"

  local is_ntfs internal vol_name native_mp fs_name
  is_ntfs="$(echo "$info" | jq -r '.is_ntfs')"
  internal="$(echo "$info" | jq -r '.internal')"
  vol_name="$(echo "$info" | jq -r '.volume_name')"
  native_mp="$(echo "$info" | jq -r '.mount_point')"
  fs_name="$(echo "$info" | jq -r '.filesystem_name')"

  # Hard refusals — no -f override, ever. A second live driver on the same
  # block device (this tool re-mounting a disk it already has mounted) has
  # no legitimate use case, so it sits here rather than in the warnings.
  [ "$internal" = "true" ] && die "REFUSED: $id is an internal disk. ntfsutil only touches external drives — no override exists for this check."
  [ "$is_ntfs" = "true" ] || die "REFUSED: $id is not NTFS (detected: ${fs_name:-unknown}). Wrong filesystem — no override."
  [ -x "$VENDOR_BIN/ntfs-3g" ] || die "REFUSED: driver binary missing at $VENDOR_BIN/ntfs-3g — rebuild it (see $SELF_DIR/README.md)."
  local existing_state_mp; existing_state_mp="$(state_get_mountpoint "$id")"
  if [ -n "$existing_state_mp" ] && is_live_mount "$existing_state_mp"; then
    die "REFUSED: $id is already mounted by ntfsutil at $existing_state_mp — two ntfs-3g instances on one device risks corruption. Unmount it first ('ntfsutil unmount $id'); no override exists for this check."
  fi

  local writable_media; writable_media="$(echo "$info" | jq -r '.writable_media')"

  local safe_name; safe_name="$(printf '%s' "${vol_name:-$id}" | tr -c 'A-Za-z0-9._- ' '_' | sed 's/^\.*//')"
  [ -n "$safe_name" ] || safe_name="$id"
  [ -n "$mountpoint" ] || mountpoint="$HOME/ntfs-${safe_name}"
  mountpoint="${mountpoint/#\~/$HOME}"

  # A mount point that exists as a non-directory can never be fixed by -f
  # (mkdir -p on a file always fails), so this is a hard refusal too.
  if [ -e "$mountpoint" ] && [ ! -d "$mountpoint" ]; then
    die "REFUSED: '$mountpoint' exists and is not a directory — choose a different mount point."
  fi

  # Soft warnings — need -f (or interactive confirm if none apply).
  local warnings=()
  [ -n "$native_mp" ] && warnings+=("Already mounted read-only by macOS at $native_mp — that mount will be unmounted first.")
  # Every real-device mount elevates to root (ntfs-3g's own check on a real
  # block device, ro or rw alike) to run a self-built, ad-hoc-signed binary —
  # that risk applies regardless of mode, not just --rw's corruption risk.
  warnings+=("This runs a self-built, ad-hoc-signed ntfs-3g as root via sudo (not Apple-reviewed).")
  if [ "$mode" = "rw" ]; then
    warnings+=("--rw uses a self-built, unsigned NTFS driver (not Apple-supported). Write bugs can corrupt data on '$vol_name'.")
    if [ "$writable_media" = "false" ]; then
      warnings+=("diskutil reports this media as write-protected — a --rw mount will likely fail at the driver level.")
    fi
  fi
  if [ -e "$mountpoint" ] && [ -n "$(ls -A "$mountpoint" 2>/dev/null)" ]; then
    warnings+=("Mount point $mountpoint already exists and is not empty.")
  fi

  if [ ${#warnings[@]} -gt 0 ]; then
    confirm_or_refuse "Mount '$vol_name' ($id) $mode at $mountpoint?" "$force" "${warnings[@]}"
  else
    confirm_or_refuse "Mount '$vol_name' ($id) $mode at $mountpoint?" "$force"
  fi

  if [ -n "$native_mp" ]; then
    diskutil umount "$id" >/dev/null 2>&1 || true
    local recheck_mp; recheck_mp="$(disk_info_json "$id" | jq -r '.mount_point // empty')"
    if [ -n "$recheck_mp" ]; then
      die "REFUSED: could not unmount the existing macOS mount at $recheck_mp first — mounting ntfs-3g on top would run two drivers against the same block device. Unmount it manually and retry."
    fi
  fi
  mkdir -p "$mountpoint"

  local opts="local"
  [ "$mode" = "ro" ] && opts="$opts,ro"

  # ntfs-3g refuses to mount a real block device as non-root (its own check,
  # src/ntfs-3g.c: `if (getuid() && ctx->blkdev)`) — a loopback image file is
  # exempt, but every real /dev/diskN mount needs root. sudo prompts here.
  note "Mounting a real device needs root — sudo will prompt for your password."
  sudo "$VENDOR_BIN/ntfs-3g" "/dev/$id" "$mountpoint" -o "$opts" \
    || die "Mount command failed (see the sudo/ntfs-3g output above for the reason — wrong password, or a genuine driver error)."

  # Poll rather than a fixed sleep — a cold/spun-down external drive can take
  # longer than a blind 1s to register the mount.
  local waited=0
  until is_live_mount "$mountpoint" || [ "$waited" -ge 100 ]; do
    sleep 0.1
    waited=$((waited + 1))
  done
  is_live_mount "$mountpoint" || die "Mount command returned but '$mountpoint' isn't live after 10s — check for an error above."

  state_set "$id" "$mountpoint" "$mode"
  ok "Mounted $vol_name ($id) $mode at $mountpoint"
}

# ── unmount ──────────────────────────────────────────────────────────────

cmd_unmount() {
  local target="" force=false all=false
  while [ $# -gt 0 ]; do
    case "$1" in
      --all) all=true ;;
      -f|--force) force=true ;;
      -h|--help) usage_unmount; exit 0 ;;
      -*) die "Unknown option: $1" ;;
      *) target="$1" ;;
    esac
    shift
  done
  if [ "$all" = true ]; then
    unmount_all "$force"
    return
  fi
  [ -n "$target" ] || { usage_unmount; exit 1; }

  local mp="$target"
  # Allow nested identifier shapes (diskNsMsK etc, seen on some
  # disk-image-within-container / nested-APFS setups), not just diskN/diskNsM.
  if [[ "$target" =~ ^/dev/disk[0-9]+(s[0-9]+)*$ || "$target" =~ ^disk[0-9]+(s[0-9]+)*$ ]]; then
    local id="${target#/dev/}"
    local info; info="$(disk_info_json "$id")"
    [ "$info" != "null" ] || die "No such disk identifier: $id"
    # Same hard refusal as mount — no -f override, ever.
    local internal; internal="$(echo "$info" | jq -r '.internal')"
    [ "$internal" = "true" ] && die "REFUSED: $id is an internal disk. ntfsutil only touches external drives — no override exists for this check."
    mp="$(echo "$info" | jq -r '.mount_point // empty')"
    [ -n "$mp" ] || mp="$(state_get_mountpoint "$id")"
    [ -n "$mp" ] || die "'$id' is not currently mounted — nothing to do."
  fi
  mp="${mp/#\~/$HOME}"

  # A target given as a raw mount-point path skips the identifier branch
  # above entirely, so the internal-disk check never ran for it — diskutil
  # accepts a mount point as a lookup target directly (confirmed: `diskutil
  # info /` resolves to the booted disk), so reverse-check it the same way.
  if [[ ! "$target" =~ ^/dev/disk[0-9]+(s[0-9]+)*$ && ! "$target" =~ ^disk[0-9]+(s[0-9]+)*$ ]]; then
    local path_info; path_info="$(disk_info_json "$mp")"
    if [ "$path_info" != "null" ]; then
      local path_internal; path_internal="$(echo "$path_info" | jq -r '.internal')"
      [ "$path_internal" = "true" ] && die "REFUSED: '$mp' is on an internal disk. ntfsutil only touches external drives — no override exists for this check."
    fi
  fi

  # A path diskutil doesn't recognize at all (e.g. not diskutil-managed) has
  # no disk to check — the hardcoded system-path literals are the fallback.
  case "$mp" in
    /|/System|/System/*|/Volumes) die "REFUSED: '$mp' is a system mount point — no override exists for this check." ;;
  esac

  is_live_mount "$mp" || die "'$mp' is not currently mounted — nothing to do."

  # A timed-out lsof (large/slow tree) is NOT the same as "confirmed no open
  # handles" — under pipefail, timeout's 124 survives as the pipeline's exit
  # status even though tail exits 0, so distinguish it explicitly.
  local lsof_rc=0 lsof_raw
  lsof_raw="$(timeout 5 lsof +D "$mp" 2>/dev/null)" || lsof_rc=$?
  local warnings=()
  if [ "$lsof_rc" -eq 124 ]; then
    warnings+=("Open-file check timed out after 5s (large/slow mount) — handle status is unknown, not confirmed clean.")
  else
    local busy; busy="$(echo "$lsof_raw" | tail -n +2)"
    if [ -n "$busy" ]; then
      local n; n="$(echo "$busy" | wc -l | tr -d ' ')"
      warnings+=("$n open file handle(s) under $mp — closing them without -f is safer.")
    fi
  fi
  if [ ${#warnings[@]} -gt 0 ]; then
    confirm_or_refuse "Unmount $mp?" "$force" "${warnings[@]}"
  else
    confirm_or_refuse "Unmount $mp?" "$force"
  fi

  local umount_args=("$mp")
  [ "$force" = true ] && umount_args=(force "$mp")
  # A root-owned ntfs-3g mount can refuse a non-root diskutil umount. diskutil
  # gives no structured error code for "needs root" vs any other failure, so
  # rather than sniff its message text, just retry once with sudo on any
  # failure — a harmless no-op if sudo wasn't the actual fix.
  if ! diskutil umount "${umount_args[@]}"; then
    note "Plain unmount failed — retrying with sudo (will prompt for your password)."
    sudo diskutil umount "${umount_args[@]}" \
      || die "Unmount failed even with sudo (see the sudo/diskutil output above for the reason — wrong password, or a genuine unmount problem)."
  fi
  state_remove_by_mountpoint "$mp"
  ok "Unmounted $mp"
}

# Unmount every currently-mounted NTFS partition ntfsutil knows about
# (native macOS mounts included). One failure doesn't stop the rest.
unmount_all() {
  local force="$1"
  local ids; ids="$(ntfs_list_json | jq -r '.[].identifier')"
  local any=false id
  for id in $ids; do
    local mp; mp="$(disk_info_json "$id" | jq -r '.mount_point // empty')"
    [ -n "$mp" ] || mp="$(state_get_mountpoint "$id")"
    if [ -n "$mp" ] && is_live_mount "$mp"; then
      any=true
      # cmd_unmount refuses via die(), which is `exit`, not `return` — that
      # would kill this whole process before `|| warn` ever ran. A subshell
      # contains the exit to just that one disk's attempt.
      if [ "$force" = true ]; then
        ( cmd_unmount "$id" -f ) || warn "Failed to unmount $id — continuing with the rest."
      else
        ( cmd_unmount "$id" ) || warn "Failed to unmount $id — continuing with the rest."
      fi
    fi
  done
  [ "$any" = true ] || note "Nothing mounted to unmount."
}

# ── help ─────────────────────────────────────────────────────────────────

usage_mount()   { echo "Usage: ntfsutil mount <identifier> [mountpoint] [--ro|--rw] [-f]"; }
usage_unmount() { echo "Usage: ntfsutil unmount <identifier|mountpoint>|--all [-f]"; }

usage() {
  cat <<EOF
${C_CYA}ntfsutil${C_RST} — mount external NTFS drives read-write (via a local ntfs-3g + FUSE-T build)

${C_YEL}USAGE${C_RST}
  ntfsutil scan   [--json]
  ntfsutil status [<identifier>] [--json]
  ntfsutil mount   <identifier> [mountpoint] [--ro|--rw] [-f]
  ntfsutil unmount <identifier|mountpoint>|--all [-f]

${C_YEL}EXAMPLES${C_RST}
  ntfsutil scan                        # list connected NTFS partitions
  ntfsutil status disk4s1              # is it mounted, by what, where
  ntfsutil mount disk4s1 -f            # mount read-only (default), skip warnings
  ntfsutil mount disk4s1 --rw -f       # mount read-write, skip warnings
  ntfsutil mount disk4s1 ~/win --rw -f # mount rw at a chosen path, skip warnings
  ntfsutil unmount disk4s1             # unmount by disk identifier
  ntfsutil unmount ~/ntfs-Elements     # unmount by mount point path
  ntfsutil unmount --all -f            # unmount every NTFS drive ntfsutil sees

${C_YEL}OPTIONS${C_RST}
  --ro, --rw       Mount mode for 'mount' (default: ro)
  -f, --force      Skip the confirm prompt and proceed past detected warnings
  --json           Machine-readable output for 'scan'/'status'

${C_YEL}SAFETY MODEL${C_RST}
  Two tiers. HARD refusals never have an override: internal disk (both mount
  and unmount), filesystem isn't NTFS, driver binary missing. SOFT warnings
  print and refuse unless -f is given — every real-device mount always
  carries at least one (it elevates to root regardless of --ro/--rw), and
  --rw adds a data-corruption warning on top. With zero warnings (the common
  case for unmount), 'mount'/'unmount' still ask for interactive confirmation
  unless -f is given.

${C_YEL}NOTES${C_RST}
  --rw runs a self-built, unsigned ntfs-3g — not Apple-supported. Prefer --ro
  (default) unless you actually need to write.
  Mounting a real drive always needs root (ntfs-3g's own rule for external
  FUSE, ro or rw alike) — 'mount' and, sometimes, 'unmount' will prompt for
  your sudo password.
EOF
}

# ── entry ────────────────────────────────────────────────────────────────

main() {
  require_deps
  state_init
  local cmd="${1:-}"
  [ $# -gt 0 ] && shift || true
  case "$cmd" in
    scan)    cmd_scan "$@" ;;
    status)  cmd_status "$@" ;;
    mount)   cmd_mount "$@" ;;
    unmount) cmd_unmount "$@" ;;
    -h|--help|"") usage ;;
    *) die "Unknown command: $cmd (see 'ntfsutil -h')" ;;
  esac
}

main "$@"
