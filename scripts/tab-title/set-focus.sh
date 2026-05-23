#!/usr/bin/env bash
# set-focus.sh — Back-compat shim. Forwards to `tab-title.sh focus`.
# Prefer `tab-title.sh` directly for new callers.
exec "${BASH_SOURCE%/*}/tab-title.sh" focus "$@"
