#!/usr/bin/env bash
# ~/.claude/scripts/dev-servers/pm2-resurrect.sh
#
# Scan ~/Code for all ecosystem.config.cjs files and start any processes
# that aren't already running in pm2. Calls `pm2 save` at the end.
#
# Usage:
#   pm2-resurrect [--dry-run] [--dir <path>]
#
# Options:
#   --dry-run    Show what would be started without actually starting anything
#   --dir <path> Scan this directory instead of ~/Code (default: ~/Code)
#
# Excludes:
#   - node_modules/
#   - templates/ directories
#   - _scaffold-* directories

set -euo pipefail

PM2="${PM2:-$(command -v pm2 || echo /opt/homebrew/bin/pm2)}"
SCAN_DIR="$HOME/Code"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --dir)     SCAN_DIR="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: pm2-resurrect [--dry-run] [--dir <path>]"
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────

# shellcheck source=/dev/null
source ~/.claude/skills/shared/gum-tui.sh

hr()      { gum_divider; }
ok()      { gum_success "$*"; }
skip()    { gum_muted "  –  $*"; }
would()   { gum_info "$*"; }
fail()    { gum_error "$*"; }

# Get list of currently-running pm2 process names (one per line)
running_names() {
  "$PM2" jlist 2>/dev/null \
    | python3 -c "import sys,json; [print(p['name']) for p in json.load(sys.stdin)]" \
    2>/dev/null || true
}

# ── Main ──────────────────────────────────────────────────────────────────────

gum_header "pm2 resurrect — $SCAN_DIR"

# Find ecosystem files, excluding noise dirs
ECOSYSTEM_FILES=()
while IFS= read -r line; do
  ECOSYSTEM_FILES+=("$line")
done < <(
  find "$SCAN_DIR" -name "ecosystem.config.cjs" \
    -not -path "*/node_modules/*" \
    -not -path "*/templates/*" \
    -not -path "*/_scaffold-*" \
    2>/dev/null | sort
)

if [[ ${#ECOSYSTEM_FILES[@]} -eq 0 ]]; then
  echo "No ecosystem.config.cjs files found under $SCAN_DIR"
  exit 0
fi

echo "Found ${#ECOSYSTEM_FILES[@]} ecosystem files"
echo ""

# Snapshot of currently running names before we start anything
RUNNING=$(running_names)

started=0
skipped=0
failed=0
failed_list=()

for eco in "${ECOSYSTEM_FILES[@]}"; do
  dir=$(dirname "$eco")
  rel="${dir#"$HOME/"}"

  # Extract process names from the ecosystem file
  names=$(python3 - "$eco" <<'PYEOF' 2>/dev/null || true
import sys, re
with open(sys.argv[1]) as f:
    content = f.read()
# Match name: 'foo' or name: "foo"
names = re.findall(r"name\s*:\s*['\"]([^'\"]+)['\"]", content)
for n in names:
    print(n)
PYEOF
)

  if [[ -z "$names" ]]; then
    fail "~/$rel — could not parse process names, skipping"
    (( failed++ )) || true
    failed_list+=("~/$rel (parse error)")
    continue
  fi

  # Check if any named process is already running
  already_running=false
  for name in $names; do
    if echo "$RUNNING" | grep -qx "$name"; then
      already_running=true
      break
    fi
  done

  # Flatten names to comma-separated for display
  names_display=$(echo "$names" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')

  if $already_running; then
    skip "~/$rel  ($names_display)"
    (( skipped++ )) || true
    continue
  fi

  if $DRY_RUN; then
    would "~/$rel  →  would start: $names_display"
    (( started++ )) || true
  else
    if (cd "$dir" && "$PM2" start ecosystem.config.cjs --no-color 2>&1 | tail -1); then
      ok "~/$rel  →  started: $names_display"
      (( started++ )) || true
    else
      fail "~/$rel  →  pm2 start failed ($names_display)"
      (( failed++ )) || true
      failed_list+=("~/$rel")
    fi
  fi
done

echo ""
hr

if $DRY_RUN; then
  echo "Dry run summary: $started would start, $skipped already running, $failed errors"
else
  echo "Summary: $started started, $skipped already running, $failed errors"
  if [[ $started -gt 0 ]]; then
    echo ""
    echo "Saving process list..."
    "$PM2" save --no-color 2>&1 | grep -v "^$" | tail -2
    ok "dump.pm2 updated ($(date '+%Y-%m-%d %H:%M'))"
  fi
fi

if [[ ${#failed_list[@]} -gt 0 ]]; then
  echo ""
  echo "Failed:"
  for f in "${failed_list[@]}"; do
    echo "  • $f"
  done
fi

echo ""
