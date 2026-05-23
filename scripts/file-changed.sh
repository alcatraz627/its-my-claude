#!/usr/bin/env bash
# FileChanged hook: notify when watched files change externally
# Filters Claude's own edits (via edit-tracker.sh temp file)
# Per-file cooldown prevents notification storms
set -uo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.file_path // empty' 2>/dev/null) || true
file_name=$(echo "$input" | jq -r '.file_name // empty' 2>/dev/null) || true
session_id=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null) || true

[[ -z "$file_path" || -z "$session_id" ]] && exit 0

sid="${session_id:0:8}"
now=$(date +%s)

# ── Filter Claude's own edits ──
# edit-tracker.sh writes timestamp|path on each Edit/Write
EDITS_FILE="/tmp/claude-edits-${sid}"
if [[ -f "$EDITS_FILE" ]]; then
  while IFS='|' read -r ts fp; do
    age=$(( now - ${ts:-0} ))
    # If Claude edited this exact file within 5s, it's a self-edit — skip
    if [[ "$fp" == "$file_path" ]] && (( age < 5 )); then
      exit 0
    fi
  done < "$EDITS_FILE"
fi

# ── Per-file cooldown (30s) ──
COOLDOWN_DIR="/tmp/claude-fchg-cd-${sid}"
mkdir -p "$COOLDOWN_DIR" 2>/dev/null || true
# Use hash of file path as cooldown key (avoids slash issues in filenames)
cd_key=$(echo -n "$file_path" | md5 -q 2>/dev/null || echo -n "$file_path" | md5sum | cut -d' ' -f1)
cd_file="${COOLDOWN_DIR}/${cd_key}"
if [[ -f "$cd_file" ]]; then
  last_ts=$(cat "$cd_file" 2>/dev/null || echo 0)
  elapsed=$(( now - ${last_ts:-0} ))
  (( elapsed < 30 )) && exit 0
fi
echo "$now" > "$cd_file"

# ── Smart suggestion based on file type ──
suggestion=""
case "$file_name" in
  package.json)
    suggestion="dependencies may have changed — consider running npm install"
    ;;
  package-lock.json|yarn.lock|pnpm-lock.yaml|bun.lockb)
    suggestion="lockfile changed — dependencies were updated externally"
    ;;
  .envrc)
    suggestion="direnv config changed — may need 'direnv allow' to reload"
    ;;
  .env|.env.local|.env.development|.env.production)
    suggestion="environment variables changed — restart dev server if running"
    ;;
  tsconfig.json|tsconfig.*.json)
    suggestion="TypeScript config changed — IDE may need restart for full effect"
    ;;
  .gitignore)
    suggestion="gitignore updated — check if new patterns affect tracked files"
    ;;
  Dockerfile|docker-compose.yml|docker-compose.yaml)
    suggestion="container config changed — rebuild may be needed"
    ;;
  *)
    # Generic for any other watched file
    suggestion="file was modified externally"
    ;;
esac

# ── Output notification on stderr (async hook — stderr shows in terminal) ──
short_path="${file_path/#$HOME/~}"
cat >&2 <<EOF

  ┌─ External Change ──────────────────────────────┐
  │ ${short_path}
  │ ${suggestion}
  └────────────────────────────────────────────────┘

EOF

# ── Write pending notification for next sync hook to pick up ──
PENDING_FILE="/tmp/claude-fchg-pending-${sid}"
echo "${now}|${file_name}|${suggestion}" >> "$PENDING_FILE"
