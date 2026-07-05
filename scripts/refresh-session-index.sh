#!/usr/bin/env bash
# refresh-session-index.sh
#
# Incremental, retention-safe refresh of the session-index SQLite DB
# (~/.claude/assets/scan-sessions/index.db) that powers cross-session usage
# aggregates/stats. Incremental (skips unchanged files) and NEVER prunes
# historical rows (prune_orphans defaults False in crawl.py), so the index keeps
# sessions whose JSONL Claude Code has since deleted — it's the durable archive.
#
# Schedule: daily (see the Automations calendar companion / launchd plist).

set -euo pipefail

LOG="$HOME/.claude/assets/scan-sessions/refresh.log"

python3 - >>"$LOG" 2>&1 <<'PY'
import sys, os, datetime
sys.path.insert(0, os.path.expanduser('~/.claude/skills/scan-sessions'))
from crawl import get_db, crawl
conn = get_db()
new, updated, skipped = crawl(conn)          # retention-safe by default
total = conn.execute("SELECT COUNT(*) FROM sessions").fetchone()[0]
conn.close()
print(f"{datetime.datetime.now():%Y-%m-%dT%H:%M:%S} refresh: "
      f"new={new} updated={updated} skipped={skipped} total_sessions={total}")
PY
