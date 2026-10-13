#!/usr/bin/env bash
# gather.sh: one call before /core-dump writes, printing every fact the dump needs.
#
# The model copies these lines instead of recalling them. Each field degrades to
# "unknown (why)"; gathering never stops a dump. Logic lives in gather.py beside
# this file.
#
# usage: gather.sh [--session-id SID] [--uuid UUID] [--cwd DIR]
#   SID  the friendly session name used in the file name (default: the indexed
#        name for this uuid, else the first 8 characters of the uuid)
#   UUID defaults to $CLAUDE_CODE_SESSION_ID, then ~/.claude/.current-session-id
set -uo pipefail
export PYTHONDONTWRITEBYTECODE=1
exec python3 "$(cd "$(dirname "$0")" && pwd)/gather.py" "$@"
