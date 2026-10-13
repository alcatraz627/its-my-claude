#!/usr/bin/env bash
# finalize.sh: one call after /core-dump's Write. Formats, validates, flags what
# a successor could be misled by, indexes the pointer, and renders the sealed
# record as the last thing printed.
#
# Logic lives in finalize.py beside this file. Exit 1 means the contract is
# broken or the pointer write failed: read the FIX line, repair, run it again.
#
# usage: finalize.sh <checkpoint> [--name NAME] [--summary TEXT] [--headless] [--prev FILE]
#                    [--mini] [--session-id SID] [--uuid UUID] [--project-root DIR]
set -uo pipefail
export PYTHONDONTWRITEBYTECODE=1
exec python3 "$(cd "$(dirname "$0")" && pwd)/finalize.py" "$@"
