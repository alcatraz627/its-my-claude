#!/usr/bin/env bash
# queue-run.sh: work a goal's rows one after another, with a budget per row.
# The logic lives in queue_run.py beside this file; run with --help for usage.
exec python3 "$(dirname "$0")/queue_run.py" "$@"
